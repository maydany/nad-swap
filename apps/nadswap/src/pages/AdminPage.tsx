import { factoryAbi, pairAbi, type AddressHex } from "@nadswap/contracts";
import { useEffect, useMemo, useState } from "react";
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

  return (
    <>
      <section className="rounded-2xl border border-slate-300 bg-white/85 p-4 shadow-sm">
        <h2 className="text-sm font-semibold text-slate-900">Admin Access</h2>
        <div className="mt-3 grid gap-2 text-sm text-slate-700 sm:grid-cols-2">
          <p>Connected wallet: {shortAddress(address)}</p>
          <p>Factory pairAdmin: {shortAddress(pairAdmin)}</p>
          <p>
            Env allowlist:{" "}
            <span className={isEnvAuthorized ? "font-semibold text-emerald-700" : "font-semibold text-slate-600"}>
              {isEnvAuthorized ? "Authorized" : "Locked"}
            </span>
          </p>
          <p>
            Wallet is pairAdmin:{" "}
            <span className={isPairAdmin ? "font-semibold text-emerald-700" : "font-semibold text-slate-600"}>
              {isPairAdmin ? "Yes" : "No"}
            </span>
          </p>
          <p>Current taxCollector: {shortAddress(taxCollector)}</p>
          <p>
            Wallet is taxCollector:{" "}
            <span className={isTaxCollector ? "font-semibold text-emerald-700" : "font-semibold text-slate-600"}>
              {isTaxCollector ? "Yes" : "No"}
            </span>
          </p>
        </div>
        {!isEnvAuthorized && (
          <p className="mt-3 rounded-lg bg-slate-100 px-3 py-2 text-sm text-slate-700">
            Wallet is not in VITE_ADMIN_ADDRESSES, so admin write actions remain locked.
          </p>
        )}
      </section>

      <section className="rounded-2xl border border-slate-300 bg-white/85 p-4 shadow-sm">
        <h2 className="text-sm font-semibold text-slate-900">Current Settings Snapshot</h2>
        {lensState.viewModel ? (
          <div className="mt-3 grid gap-2 text-sm text-slate-700 sm:grid-cols-2">
            <p>
              Overall Status:{" "}
              <span className={`rounded-md border px-2 py-0.5 text-xs ${statusBadgeClass(lensState.viewModel.statuses.overallStatus)}`}>
                {toStatusLabel(lensState.viewModel.statuses.overallStatus)}
              </span>
            </p>
            <p>Quote Token: {shortAddress(lensState.viewModel.staticData.quoteToken)}</p>
            <p>Tax Collector: {shortAddress(lensState.viewModel.staticData.taxCollector)}</p>
            <p>Buy Tax: {formatBps(lensState.viewModel.staticData.buyTaxBps)}</p>
            <p>Sell Tax: {formatBps(lensState.viewModel.staticData.sellTaxBps)}</p>
            <p>LP Fee: {formatBps(lensState.viewModel.staticData.lpFeeBps)}</p>
            <p>Accumulated Quote Tax: {lensState.viewModel.dynamicData.accumulatedQuoteTax.toString()}</p>
            <p>Accounting OK: {lensState.viewModel.dynamicData.accountingOk ? "Yes" : "No"}</p>
          </div>
        ) : (
          <p className="mt-3 text-sm text-slate-600">No admin snapshot loaded yet.</p>
        )}
      </section>

      <section className="rounded-2xl border border-slate-300 bg-white/85 p-4 shadow-sm">
        <h2 className="text-sm font-semibold text-slate-900">Update Tax Config</h2>
        <div className="mt-3 grid gap-3 sm:grid-cols-3">
          <label className="grid gap-1 text-sm">
            <span className="text-xs font-semibold uppercase tracking-wide text-slate-500">Buy Tax BPS</span>
            <input
              value={buyTaxInput}
              onChange={(event) => setBuyTaxInput(event.target.value)}
              inputMode="numeric"
              placeholder={String(lensState.viewModel?.staticData.buyTaxBps ?? 0)}
              className="rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-cyan-500"
            />
          </label>
          <label className="grid gap-1 text-sm">
            <span className="text-xs font-semibold uppercase tracking-wide text-slate-500">Sell Tax BPS</span>
            <input
              value={sellTaxInput}
              onChange={(event) => setSellTaxInput(event.target.value)}
              inputMode="numeric"
              placeholder={String(lensState.viewModel?.staticData.sellTaxBps ?? 0)}
              className="rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-cyan-500"
            />
          </label>
          <label className="grid gap-1 text-sm">
            <span className="text-xs font-semibold uppercase tracking-wide text-slate-500">Tax Collector</span>
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
        <h2 className="text-sm font-semibold text-slate-900">Claim Quote Tax</h2>
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
        <section className="rounded-2xl border border-rose-300 bg-rose-50 p-4 text-sm text-rose-900">{actionError}</section>
      )}
      {actionMessage && (
        <section className="rounded-2xl border border-emerald-300 bg-emerald-50 p-4 text-sm text-emerald-900">{actionMessage}</section>
      )}
    </>
  );
};
