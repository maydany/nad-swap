import { factoryAbi, pairAbi, type AddressHex } from "@nadswap/contracts";
import { type ReactNode, useEffect, useMemo, useState } from "react";
import { useAccount, useChainId, usePublicClient, useReadContract, useSwitchChain, useWriteContract } from "wagmi";

import { statusBadgeClass, toStatusLabel } from "../features/lens/status";
import { useLensPairView } from "../features/lens/useLensPairView";
import { appEnv } from "../lib/env";
import { formatBps, shortAddress } from "../lib/format";
import { ConfigErrorPanel } from "./ConfigErrorPanel";

const addressSchema = /^0x[a-fA-F0-9]{40}$/;

const normalizeAddress = (value: string | undefined) => value?.toLowerCase();

const normalizeError = (error: unknown): string => {
  if (error instanceof Error) {
    return error.message;
  }
  return "Unknown transaction error";
};

const toBpsInput = (value: string, fallback: number): number | null => {
  const normalized = value.trim();
  if (normalized === "") {
    return fallback;
  }
  if (!/^\d+$/.test(normalized)) {
    return null;
  }
  const parsed = Number(normalized);
  if (!Number.isInteger(parsed)) {
    return null;
  }
  return parsed;
};

type TooltipLabelProps = {
  label: string;
  tooltip: ReactNode;
};

const TooltipLabel = ({ label, tooltip }: TooltipLabelProps) => (
  <span className="group relative inline-flex items-center gap-1">
    <span>{label}</span>
    <button
      type="button"
      className="inline-flex h-4 w-4 items-center justify-center rounded-full border border-slate-300 bg-slate-100 text-[10px] font-bold text-slate-600"
      aria-label={`${label} 도움말`}
    >
      i
    </button>
    <span
      role="tooltip"
      className="pointer-events-none absolute left-0 top-6 z-20 hidden w-80 rounded-lg border border-slate-200 bg-white p-2 text-[11px] leading-5 text-slate-700 shadow-lg group-hover:block group-focus-within:block"
    >
      {tooltip}
    </span>
  </span>
);

export const AdminPage = () => {
  const { address, isConnected } = useAccount();
  const chainId = useChainId();
  const { switchChainAsync } = useSwitchChain();
  const { writeContractAsync } = useWriteContract();

  if (!appEnv) {
    return <ConfigErrorPanel />;
  }
  const env = appEnv;
  const publicClient = usePublicClient({ chainId: env.chainId });

  const wrongNetwork = isConnected && chainId !== env.chainId;

  const [buyTaxInput, setBuyTaxInput] = useState("");
  const [sellTaxInput, setSellTaxInput] = useState("");
  const [collectorInput, setCollectorInput] = useState("");
  const [claimToInput, setClaimToInput] = useState("");

  const [actionError, setActionError] = useState<string | null>(null);
  const [actionMessage, setActionMessage] = useState<string | null>(null);

  const [isSwitching, setIsSwitching] = useState(false);
  const [isUpdatingTax, setIsUpdatingTax] = useState(false);
  const [isClaiming, setIsClaiming] = useState(false);

  const { data: pairAdmin } = useReadContract({
    address: env.factory,
    abi: factoryAbi,
    functionName: "pairAdmin"
  });

  const lensState = useLensPairView({
    lensAddress: env.contracts.lens,
    pairAddress: env.contracts.pairs.usdtNad,
    userAddress: address as AddressHex | undefined
  });

  useEffect(() => {
    if (!claimToInput && address) {
      setClaimToInput(address);
    }
  }, [address, claimToInput]);

  const isEnvAuthorized = useMemo(() => {
    const normalized = normalizeAddress(address);
    if (!normalized) {
      return false;
    }
    return env.adminAddresses.some((candidate) => candidate.toLowerCase() === normalized);
  }, [address, env.adminAddresses]);

  const isPairAdmin = useMemo(() => {
    if (!address || !pairAdmin) {
      return false;
    }
    return address.toLowerCase() === pairAdmin.toLowerCase();
  }, [address, pairAdmin]);

  const taxCollector = lensState.viewModel?.staticData.taxCollector ?? null;
  const isTaxCollector = useMemo(() => {
    if (!address || !taxCollector) {
      return false;
    }
    return address.toLowerCase() === taxCollector.toLowerCase();
  }, [address, taxCollector]);
  const view = lensState.viewModel;
  const statuses = lensState.statuses;

  const canUpdateTax = isConnected && !wrongNetwork && isEnvAuthorized && isPairAdmin;
  const canClaimTax = isConnected && !wrongNetwork && isTaxCollector;

  const clearActionNotice = () => {
    setActionError(null);
    setActionMessage(null);
  };

  const onSwitchNetwork = async () => {
    clearActionNotice();
    if (!switchChainAsync) {
      setActionError("Wallet connector does not support programmatic chain switch.");
      return;
    }
    setIsSwitching(true);
    try {
      await switchChainAsync({ chainId: env.chainId });
      setActionMessage("Network switched.");
    } catch (error) {
      console.error(error);
      setActionError(normalizeError(error));
    } finally {
      setIsSwitching(false);
    }
  };

  const onUpdateTaxConfig = async () => {
    clearActionNotice();
    if (!canUpdateTax) {
      setActionError("Update Tax Config is locked. Check env authorization, pairAdmin role, wallet connection, and network.");
      return;
    }
    if (!publicClient) {
      setActionError("Public client is not ready.");
      return;
    }

    const currentBuy = lensState.viewModel?.staticData.buyTaxBps ?? 0;
    const currentSell = lensState.viewModel?.staticData.sellTaxBps ?? 0;
    const currentCollector = lensState.viewModel?.staticData.taxCollector ?? "";

    const buyTaxBps = toBpsInput(buyTaxInput, currentBuy);
    const sellTaxBps = toBpsInput(sellTaxInput, currentSell);
    const taxCollectorInput = collectorInput.trim() === "" ? currentCollector : collectorInput.trim();

    if (buyTaxBps === null || sellTaxBps === null) {
      setActionError("Tax BPS must be integer values.");
      return;
    }
    if (buyTaxBps < 0 || buyTaxBps > 2000 || sellTaxBps < 0 || sellTaxBps > 2000) {
      setActionError("Tax BPS must be within 0 to 2000.");
      return;
    }
    if (!addressSchema.test(taxCollectorInput)) {
      setActionError("Collector must be a valid address.");
      return;
    }

    setIsUpdatingTax(true);
    try {
      const txHash = await writeContractAsync({
        address: env.factory,
        abi: factoryAbi,
        functionName: "setTaxConfig",
        args: [env.pairUsdtNad, buyTaxBps, sellTaxBps, taxCollectorInput as AddressHex]
      });

      await publicClient.waitForTransactionReceipt({ hash: txHash });
      await lensState.refetch();
      setActionMessage("Tax config update transaction confirmed.");
    } catch (error) {
      console.error(error);
      setActionError(normalizeError(error));
    } finally {
      setIsUpdatingTax(false);
    }
  };

  const onClaimQuoteTax = async () => {
    clearActionNotice();
    if (!canClaimTax) {
      setActionError("Claim Quote Tax is locked. Connected wallet must match current taxCollector.");
      return;
    }
    if (!publicClient) {
      setActionError("Public client is not ready.");
      return;
    }

    const claimTo = claimToInput.trim() === "" ? address ?? "" : claimToInput.trim();
    if (!addressSchema.test(claimTo)) {
      setActionError("Claim target must be a valid address.");
      return;
    }

    setIsClaiming(true);
    try {
      const txHash = await writeContractAsync({
        address: env.pairUsdtNad,
        abi: pairAbi,
        functionName: "claimQuoteTax",
        args: [claimTo as AddressHex]
      });

      await publicClient.waitForTransactionReceipt({ hash: txHash });
      await lensState.refetch();
      setActionMessage("Quote tax claim transaction confirmed.");
    } catch (error) {
      console.error(error);
      setActionError(normalizeError(error));
    } finally {
      setIsClaiming(false);
    }
  };

  const primaryButtonClass = "rounded-lg bg-cyan-700 px-4 py-2 text-sm font-semibold text-white disabled:opacity-60";
  const secondaryButtonClass =
    "rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 disabled:opacity-60";
  const cardTitleClass = "text-sm font-semibold uppercase tracking-[0.12em] text-slate-600";
  const accessChipClass = (enabled: boolean) =>
    `rounded-lg border px-3 py-2 ${enabled ? "border-emerald-200 bg-emerald-50 text-emerald-800" : "border-slate-200 bg-slate-100 text-slate-600"}`;
  const lensStatusChipClassName = `rounded-lg border px-2.5 py-1 text-xs font-semibold ${statusBadgeClass(
    statuses?.overallStatus ?? null
  )}`;

  return (
    <>
      <section className="rounded-2xl border border-slate-300 bg-white/85 p-4 shadow-sm">
        <div className="flex items-center justify-between gap-3">
          <h2 className={cardTitleClass}>Admin Access</h2>
          <button
            type="button"
            onClick={() => void lensState.refetch()}
            disabled={!lensState.canQuery}
            className="rounded-lg border border-slate-300 px-3 py-1.5 text-xs font-medium text-slate-700 disabled:opacity-50"
          >
            {lensState.isFetching ? "Refreshing..." : "Refetch"}
          </button>
        </div>

        <p className="mt-2 text-sm text-slate-600">
          Tax config updates require `Env allowlist + pairAdmin + correct network`. Quote tax claim requires `taxCollector`.
        </p>

        {statuses && (
          <div className="mt-3">
            <span className={lensStatusChipClassName}>Lens Overall: {toStatusLabel(statuses.overallStatus)}</span>
          </div>
        )}

        <div className="mt-3 grid grid-cols-[minmax(0,1fr)_auto] items-baseline gap-x-3 gap-y-1.5 text-sm">
          <span className="text-slate-500">Connected wallet</span>
          <span className="text-right font-semibold text-slate-900">{shortAddress(address)}</span>
          <span className="text-slate-500">
            <TooltipLabel
              label="Factory pairAdmin"
              tooltip="Factory의 pairAdmin은 setTaxConfig 실행 권한을 가진 온체인 관리자 주소입니다."
            />
          </span>
          <span className="text-right font-semibold text-slate-900">{shortAddress(pairAdmin)}</span>
          <span className="text-slate-500">
            <TooltipLabel
              label="Current taxCollector"
              tooltip="Tax collector는 pair에 누적된 quote tax를 claim할 수 있는 주소입니다."
            />
          </span>
          <span className="text-right font-semibold text-slate-900">{shortAddress(taxCollector)}</span>
          <span className="text-slate-500">
            <TooltipLabel
              label="Target network"
              tooltip="Admin write 트랜잭션은 설정된 체인에서만 허용됩니다. 지갑 네트워크가 다르면 버튼이 잠깁니다."
            />
          </span>
          <span className="text-right font-semibold text-slate-900">Chain {env.chainId}</span>
        </div>

        <div className="mt-3 grid gap-2 text-sm sm:grid-cols-3">
          <div className={accessChipClass(isEnvAuthorized)}>Env allowlist: {isEnvAuthorized ? "Authorized" : "Locked"}</div>
          <div className={accessChipClass(isPairAdmin)}>Wallet is pairAdmin: {isPairAdmin ? "Yes" : "No"}</div>
          <div className={accessChipClass(isTaxCollector)}>Wallet is taxCollector: {isTaxCollector ? "Yes" : "No"}</div>
        </div>

        {lensState.error && (
          <p className="mt-3 rounded-lg bg-rose-100 px-3 py-2 text-sm text-rose-900 whitespace-pre-wrap break-all">{lensState.error}</p>
        )}

        {!isConnected && (
          <p className="mt-3 rounded-lg bg-slate-100 px-3 py-2 text-sm text-slate-700">
            Connect wallet to evaluate admin roles and execute write actions.
          </p>
        )}

        {wrongNetwork && (
          <p className="mt-3 rounded-lg bg-amber-100 px-3 py-2 text-sm text-amber-900">
            Wallet is on a different network. Switch to chain {env.chainId} before admin writes.
          </p>
        )}

        {!isEnvAuthorized && (
          <p className="mt-3 rounded-lg bg-slate-100 px-3 py-2 text-sm text-slate-700">
            Wallet is not in VITE_ADMIN_ADDRESSES, so admin write actions remain locked.
          </p>
        )}
      </section>

      <section className="rounded-2xl border border-slate-300 bg-white/85 p-4 shadow-sm">
        <h2 className={cardTitleClass}>Pair Config Snapshot</h2>
        <p className="mt-2 text-sm text-slate-600">Latest Lens read for policy and accounting state.</p>
        {view ? (
          <div className="mt-3 grid grid-cols-[minmax(0,1fr)_auto] items-baseline gap-x-3 gap-y-1.5 text-sm">
            <span className="text-slate-500">
              <TooltipLabel
                label="Overall status"
                tooltip={
                  <>
                    0 = OK (정상), 1 = INVALID_PAIR (설정/페어 오류), 2 = DEGRADED (부분 실패/가드 상태).
                  </>
                }
              />
            </span>
            <span className="text-right">
              <span className={`rounded-md border px-2 py-0.5 text-xs font-semibold ${statusBadgeClass(view.statuses.overallStatus)}`}>
                {toStatusLabel(view.statuses.overallStatus)}
              </span>
            </span>
            <span className="text-slate-500">Quote token</span>
            <span className="text-right font-semibold text-slate-900">{shortAddress(view.staticData.quoteToken)}</span>
            <span className="text-slate-500">Tax collector</span>
            <span className="text-right font-semibold text-slate-900">{shortAddress(view.staticData.taxCollector)}</span>
            <span className="text-slate-500">Buy tax</span>
            <span className="text-right font-semibold text-slate-900">{formatBps(view.staticData.buyTaxBps)}</span>
            <span className="text-slate-500">Sell tax</span>
            <span className="text-right font-semibold text-slate-900">{formatBps(view.staticData.sellTaxBps)}</span>
            <span className="text-slate-500">LP fee</span>
            <span className="text-right font-semibold text-slate-900">{formatBps(view.staticData.lpFeeBps)}</span>
            <span className="text-slate-500">
              <TooltipLabel
                label="Accumulated quote tax"
                tooltip="Claim 전까지 pair에 누적된 quote token 기준 세금 잔고입니다."
              />
            </span>
            <span className="text-right font-semibold text-slate-900 tabular-nums">{view.dynamicData.accumulatedQuoteTax.toString()}</span>
            <span className="text-slate-500">
              <TooltipLabel
                label="Accounting OK"
                tooltip="Yes면 reserve/raw/effective/quote-vault 회계 관계가 정상 범위입니다. No면 sync/skim 또는 설정 점검이 필요할 수 있습니다."
              />
            </span>
            <span className="text-right font-semibold text-slate-900">{view.dynamicData.accountingOk ? "Yes" : "No"}</span>
          </div>
        ) : (
          <p className="mt-3 text-sm text-slate-600">No admin snapshot loaded yet.</p>
        )}
      </section>

      <section className="rounded-2xl border border-slate-300 bg-white/85 p-4 shadow-sm">
        <h2 className={cardTitleClass}>Update Tax Config</h2>
        <p className="mt-2 text-sm text-slate-600">Set buy/sell tax BPS and tax collector address for the configured pair.</p>
        <div className="mt-3 grid gap-3 sm:grid-cols-3">
          <label className="grid gap-1 text-sm">
            <span className="text-xs font-semibold uppercase tracking-wide text-slate-500">
              <TooltipLabel label="Buy Tax BPS" tooltip="사용자가 Quote -> Base로 스왑할 때 입력 금액에 적용되는 세율(bps)입니다." />
            </span>
            <input
              value={buyTaxInput}
              onChange={(event) => setBuyTaxInput(event.target.value)}
              inputMode="numeric"
              placeholder={String(lensState.viewModel?.staticData.buyTaxBps ?? 0)}
              className="rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-cyan-500"
            />
          </label>
          <label className="grid gap-1 text-sm">
            <span className="text-xs font-semibold uppercase tracking-wide text-slate-500">
              <TooltipLabel label="Sell Tax BPS" tooltip="사용자가 Base -> Quote로 스왑할 때 출력 금액에 적용되는 세율(bps)입니다." />
            </span>
            <input
              value={sellTaxInput}
              onChange={(event) => setSellTaxInput(event.target.value)}
              inputMode="numeric"
              placeholder={String(lensState.viewModel?.staticData.sellTaxBps ?? 0)}
              className="rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-cyan-500"
            />
          </label>
          <label className="grid gap-1 text-sm">
            <span className="text-xs font-semibold uppercase tracking-wide text-slate-500">
              <TooltipLabel label="Tax Collector" tooltip="누적 quote tax를 claim할 권한을 가지는 수령 주소입니다." />
            </span>
            <input
              value={collectorInput}
              onChange={(event) => setCollectorInput(event.target.value)}
              placeholder={lensState.viewModel?.staticData.taxCollector ?? ""}
              className="rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-cyan-500"
            />
          </label>
        </div>

        <div className="mt-4 flex flex-wrap gap-2">
          {wrongNetwork ? (
            <button type="button" onClick={() => void onSwitchNetwork()} disabled={isSwitching} className={secondaryButtonClass}>
              {isSwitching ? "Switching..." : `Switch to chain ${env.chainId}`}
            </button>
          ) : (
            <button type="button" onClick={() => void onUpdateTaxConfig()} disabled={!canUpdateTax || isUpdatingTax} className={primaryButtonClass}>
              {isUpdatingTax ? "Updating tax config..." : "Update Tax Config"}
            </button>
          )}
        </div>
      </section>

      <section className="rounded-2xl border border-slate-300 bg-white/85 p-4 shadow-sm">
        <h2 className={cardTitleClass}>Claim Quote Tax</h2>
        <p className="mt-2 text-sm text-slate-600">Callable only by the current tax collector on the target network.</p>
        <label className="mt-3 grid gap-1 text-sm">
          <span className="text-xs font-semibold uppercase tracking-wide text-slate-500">Claim To Address</span>
          <input
            value={claimToInput}
            onChange={(event) => setClaimToInput(event.target.value)}
            placeholder={address ?? ""}
            className="rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-cyan-500"
          />
        </label>

        <div className="mt-4 flex flex-wrap gap-2">
          {wrongNetwork ? (
            <button type="button" onClick={() => void onSwitchNetwork()} disabled={isSwitching} className={secondaryButtonClass}>
              {isSwitching ? "Switching..." : `Switch to chain ${env.chainId}`}
            </button>
          ) : (
            <button type="button" onClick={() => void onClaimQuoteTax()} disabled={!canClaimTax || isClaiming} className={primaryButtonClass}>
              {isClaiming ? "Claiming quote tax..." : "Claim Quote Tax"}
            </button>
          )}
        </div>
      </section>

      {actionError && (
        <section className="rounded-2xl border border-rose-300 bg-rose-50 p-4 text-sm text-rose-900 whitespace-pre-wrap break-all">{actionError}</section>
      )}
      {actionMessage && (
        <section className="rounded-2xl border border-emerald-300 bg-emerald-50 p-4 text-sm text-emerald-900">{actionMessage}</section>
      )}
    </>
  );
};
