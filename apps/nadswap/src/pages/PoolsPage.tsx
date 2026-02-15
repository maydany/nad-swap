import { erc20Abi, pairAbi, routerAbi, type AddressHex } from "@nadswap/contracts";
import { Fragment, useMemo, useState } from "react";
import { parseUnits } from "viem";
import {
  useAccount,
  useChainId,
  usePublicClient,
  useReadContract,
  useSwitchChain,
  useWriteContract
} from "wagmi";

import { useLensPairView } from "../features/lens/useLensPairView";
import { applySlippageBps } from "../features/trade/math";
import { appEnv } from "../lib/env";
import { formatBps, formatTokenAmount } from "../lib/format";
import { ConfigErrorPanel } from "./ConfigErrorPanel";

const DEFAULT_SLIPPAGE_BPS = 0;

type TokenMeta = {
  symbol: string;
  decimals: number;
};

const normalizeAddress = (value: string | null | undefined) => value?.toLowerCase();

const defaultTokenMeta: TokenMeta = { symbol: "TOKEN", decimals: 18 };

const parseTokenInput = (value: string, decimals: number): bigint | null => {
  const normalized = value.trim();
  if (normalized === "") {
    return null;
  }
  try {
    const parsed = parseUnits(normalized, decimals);
    return parsed > 0n ? parsed : null;
  } catch {
    return null;
  }
};

const normalizeError = (error: unknown): string => {
  if (error instanceof Error) {
    return error.message;
  }
  return "Unknown transaction error";
};

export const PoolsPage = () => {
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

  const [addUsdtInput, setAddUsdtInput] = useState("");
  const [addNadInput, setAddNadInput] = useState("");
  const [removeLpInput, setRemoveLpInput] = useState("");

  const [actionMessage, setActionMessage] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);

  const [isSwitching, setIsSwitching] = useState(false);
  const [isApprovingUsdt, setIsApprovingUsdt] = useState(false);
  const [isApprovingNad, setIsApprovingNad] = useState(false);
  const [isAddingLiquidity, setIsAddingLiquidity] = useState(false);
  const [isApprovingLp, setIsApprovingLp] = useState(false);
  const [isRemovingLiquidity, setIsRemovingLiquidity] = useState(false);
  const [isSyncingReserves, setIsSyncingReserves] = useState(false);
  const [isSkimmingExcess, setIsSkimmingExcess] = useState(false);
  const [copiedAddressKey, setCopiedAddressKey] = useState<string | null>(null);

  const lensState = useLensPairView({
    lensAddress: env.contracts.lens,
    pairAddress: env.contracts.pairs.usdtNad,
    userAddress: address as AddressHex | undefined
  });

  const { data: usdtSymbol = "USDT" } = useReadContract({
    address: env.usdt,
    abi: erc20Abi,
    functionName: "symbol"
  });
  const { data: nadSymbol = "NAD" } = useReadContract({
    address: env.nad,
    abi: erc20Abi,
    functionName: "symbol"
  });
  const { data: usdtDecimals = 18 } = useReadContract({
    address: env.usdt,
    abi: erc20Abi,
    functionName: "decimals"
  });
  const { data: nadDecimals = 18 } = useReadContract({
    address: env.nad,
    abi: erc20Abi,
    functionName: "decimals"
  });
  const { data: lpSymbol = "USDT-NAD LP" } = useReadContract({
    address: env.pairUsdtNad,
    abi: erc20Abi,
    functionName: "symbol"
  });
  const { data: lpDecimals = 18 } = useReadContract({
    address: env.pairUsdtNad,
    abi: erc20Abi,
    functionName: "decimals"
  });
  const { data: lpTotalSupply = 0n } = useReadContract({
    address: env.pairUsdtNad,
    abi: erc20Abi,
    functionName: "totalSupply"
  });

  const addressOrZero = (address ?? "0x0000000000000000000000000000000000000000") as AddressHex;

  const { data: usdtBalance = 0n, refetch: refetchUsdtBalance } = useReadContract({
    address: env.usdt,
    abi: erc20Abi,
    functionName: "balanceOf",
    args: [addressOrZero],
    query: { enabled: isConnected }
  });
  const { data: nadBalance = 0n, refetch: refetchNadBalance } = useReadContract({
    address: env.nad,
    abi: erc20Abi,
    functionName: "balanceOf",
    args: [addressOrZero],
    query: { enabled: isConnected }
  });
  const { data: lpBalance = 0n, refetch: refetchLpBalance } = useReadContract({
    address: env.pairUsdtNad,
    abi: erc20Abi,
    functionName: "balanceOf",
    args: [addressOrZero],
    query: { enabled: isConnected }
  });

  const {
    data: usdtAllowance = 0n,
    refetch: refetchUsdtAllowance
  } = useReadContract({
    address: env.usdt,
    abi: erc20Abi,
    functionName: "allowance",
    args: [addressOrZero, env.router],
    query: { enabled: isConnected }
  });
  const {
    data: nadAllowance = 0n,
    refetch: refetchNadAllowance
  } = useReadContract({
    address: env.nad,
    abi: erc20Abi,
    functionName: "allowance",
    args: [addressOrZero, env.router],
    query: { enabled: isConnected }
  });
  const {
    data: lpAllowance = 0n,
    refetch: refetchLpAllowance
  } = useReadContract({
    address: env.pairUsdtNad,
    abi: erc20Abi,
    functionName: "allowance",
    args: [addressOrZero, env.router],
    query: { enabled: isConnected }
  });

  const tokenMetaByAddress = useMemo<Record<string, TokenMeta>>(
    () => ({
      [env.usdt.toLowerCase()]: { symbol: usdtSymbol, decimals: usdtDecimals },
      [env.nad.toLowerCase()]: { symbol: nadSymbol, decimals: nadDecimals }
    }),
    [env.nad, env.usdt, nadDecimals, nadSymbol, usdtDecimals, usdtSymbol]
  );

  const view = lensState.viewModel;

  const token0Meta = view?.staticData.token0 ? tokenMetaByAddress[normalizeAddress(view.staticData.token0) ?? ""] : undefined;
  const token1Meta = view?.staticData.token1 ? tokenMetaByAddress[normalizeAddress(view.staticData.token1) ?? ""] : undefined;
  const quoteMeta = view?.staticData.quoteToken ? tokenMetaByAddress[normalizeAddress(view.staticData.quoteToken) ?? ""] : undefined;
  const mergedTokenAddressRows = useMemo(() => {
    if (!view) {
      return [];
    }

    const roleEntries: Array<{ role: string; address: AddressHex | null }> = [
      { role: "Token0", address: view.staticData.token0 },
      { role: "Token1", address: view.staticData.token1 },
      { role: "Quote", address: view.staticData.quoteToken },
      { role: "Base", address: view.staticData.baseToken }
    ];

    const groupedByAddress = new Map<string, { key: string; address: AddressHex | null; roles: string[] }>();
    roleEntries.forEach(({ role, address }, index) => {
      const groupKey = address ? address.toLowerCase() : `null-${index}`;
      const current = groupedByAddress.get(groupKey);
      if (current) {
        current.roles.push(role);
        return;
      }
      groupedByAddress.set(groupKey, { key: groupKey, address, roles: [role] });
    });

    return Array.from(groupedByAddress.values()).map((group) => {
      const normalized = normalizeAddress(group.address);
      const tokenAlias =
        normalized === env.usdt.toLowerCase() ? usdtSymbol : normalized === env.nad.toLowerCase() ? nadSymbol : null;
      const label = tokenAlias ? `${tokenAlias} (${group.roles.join(", ")})` : group.roles.join(", ");
      return { ...group, label };
    });
  }, [env.nad, env.usdt, nadSymbol, usdtSymbol, view]);

  const parsedAddUsdt = parseTokenInput(addUsdtInput, usdtDecimals);
  const parsedAddNad = parseTokenInput(addNadInput, nadDecimals);
  const parsedRemoveLp = parseTokenInput(removeLpInput, lpDecimals);

  const addAmountMinUsdt = parsedAddUsdt ? applySlippageBps(parsedAddUsdt, DEFAULT_SLIPPAGE_BPS) : null;
  const addAmountMinNad = parsedAddNad ? applySlippageBps(parsedAddNad, DEFAULT_SLIPPAGE_BPS) : null;

  const reserveUsdt = useMemo(() => {
    if (!view) {
      return null;
    }
    const token0 = normalizeAddress(view.staticData.token0);
    if (token0 === env.usdt.toLowerCase()) {
      return view.dynamicData.reserve0;
    }
    return view.dynamicData.reserve1;
  }, [env.usdt, view]);

  const reserveNad = useMemo(() => {
    if (!view) {
      return null;
    }
    const token0 = normalizeAddress(view.staticData.token0);
    if (token0 === env.nad.toLowerCase()) {
      return view.dynamicData.reserve0;
    }
    return view.dynamicData.reserve1;
  }, [env.nad, view]);

  const estimatedRemoveUsdt =
    parsedRemoveLp && lpTotalSupply > 0n && reserveUsdt !== null ? (parsedRemoveLp * reserveUsdt) / lpTotalSupply : null;
  const estimatedRemoveNad =
    parsedRemoveLp && lpTotalSupply > 0n && reserveNad !== null ? (parsedRemoveLp * reserveNad) / lpTotalSupply : null;

  const removeAmountMinUsdt = estimatedRemoveUsdt ? applySlippageBps(estimatedRemoveUsdt, DEFAULT_SLIPPAGE_BPS) : 0n;
  const removeAmountMinNad = estimatedRemoveNad ? applySlippageBps(estimatedRemoveNad, DEFAULT_SLIPPAGE_BPS) : 0n;

  const needsUsdtApproval = Boolean(parsedAddUsdt && usdtAllowance < parsedAddUsdt);
  const needsNadApproval = Boolean(parsedAddNad && nadAllowance < parsedAddNad);
  const needsLpApproval = Boolean(parsedRemoveLp && lpAllowance < parsedRemoveLp);

  const canAddLiquidity = Boolean(
    isConnected && !wrongNetwork && parsedAddUsdt && parsedAddNad && !needsUsdtApproval && !needsNadApproval
  );
  const canRemoveLiquidity = Boolean(isConnected && !wrongNetwork && parsedRemoveLp && !needsLpApproval);

  const clearActionNotice = () => {
    setActionError(null);
    setActionMessage(null);
  };

  const onCopyAddress = async (key: string, value: string) => {
    if (typeof navigator === "undefined" || !navigator.clipboard?.writeText) {
      setActionError("Clipboard API is not available in this browser.");
      return;
    }

    try {
      await navigator.clipboard.writeText(value);
      setCopiedAddressKey(key);
      window.setTimeout(() => {
        setCopiedAddressKey((current) => (current === key ? null : current));
      }, 1400);
    } catch (error) {
      console.error(error);
      setActionError("Failed to copy address.");
    }
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

  const approveToken = async (token: AddressHex, amount: bigint, kind: "USDT" | "NAD" | "LP") => {
    if (!publicClient) {
      throw new Error("Public client is not ready.");
    }

    const txHash = await writeContractAsync({
      address: token,
      abi: erc20Abi,
      functionName: "approve",
      args: [env.router, amount]
    });
    await publicClient.waitForTransactionReceipt({ hash: txHash });

    if (kind === "USDT") {
      await refetchUsdtAllowance();
    } else if (kind === "NAD") {
      await refetchNadAllowance();
    } else {
      await refetchLpAllowance();
    }
  };

  const onApproveUsdt = async () => {
    if (!parsedAddUsdt) {
      return;
    }
    clearActionNotice();
    setIsApprovingUsdt(true);
    try {
      await approveToken(env.usdt, parsedAddUsdt, "USDT");
      setActionMessage("USDT approval confirmed.");
    } catch (error) {
      console.error(error);
      setActionError(normalizeError(error));
    } finally {
      setIsApprovingUsdt(false);
    }
  };

  const onApproveNad = async () => {
    if (!parsedAddNad) {
      return;
    }
    clearActionNotice();
    setIsApprovingNad(true);
    try {
      await approveToken(env.nad, parsedAddNad, "NAD");
      setActionMessage("NAD approval confirmed.");
    } catch (error) {
      console.error(error);
      setActionError(normalizeError(error));
    } finally {
      setIsApprovingNad(false);
    }
  };

  const onAddLiquidity = async () => {
    if (!address || !parsedAddUsdt || !parsedAddNad) {
      return;
    }
    clearActionNotice();
    setIsAddingLiquidity(true);

    try {
      if (!publicClient) {
        throw new Error("Public client is not ready.");
      }
      const deadline = BigInt(Math.floor(Date.now() / 1000) + 600);
      const txHash = await writeContractAsync({
        address: env.router,
        abi: routerAbi,
        functionName: "addLiquidity",
        args: [
          env.usdt,
          env.nad,
          parsedAddUsdt,
          parsedAddNad,
          addAmountMinUsdt ?? 0n,
          addAmountMinNad ?? 0n,
          address,
          deadline
        ]
      });

      await publicClient.waitForTransactionReceipt({ hash: txHash });
      await Promise.all([
        refetchUsdtAllowance(),
        refetchNadAllowance(),
        refetchUsdtBalance(),
        refetchNadBalance(),
        refetchLpBalance(),
        lensState.refetch()
      ]);
      setActionMessage("Add liquidity transaction confirmed.");
    } catch (error) {
      console.error(error);
      setActionError(normalizeError(error));
    } finally {
      setIsAddingLiquidity(false);
    }
  };

  const onApproveLp = async () => {
    if (!parsedRemoveLp) {
      return;
    }
    clearActionNotice();
    setIsApprovingLp(true);
    try {
      await approveToken(env.pairUsdtNad, parsedRemoveLp, "LP");
      setActionMessage("LP token approval confirmed.");
    } catch (error) {
      console.error(error);
      setActionError(normalizeError(error));
    } finally {
      setIsApprovingLp(false);
    }
  };

  const onRemoveLiquidity = async () => {
    if (!address || !parsedRemoveLp) {
      return;
    }
    clearActionNotice();
    setIsRemovingLiquidity(true);

    try {
      if (!publicClient) {
        throw new Error("Public client is not ready.");
      }
      const deadline = BigInt(Math.floor(Date.now() / 1000) + 600);
      const txHash = await writeContractAsync({
        address: env.router,
        abi: routerAbi,
        functionName: "removeLiquidity",
        args: [env.usdt, env.nad, parsedRemoveLp, removeAmountMinUsdt, removeAmountMinNad, address, deadline]
      });

      await publicClient.waitForTransactionReceipt({ hash: txHash });
      await Promise.all([
        refetchLpAllowance(),
        refetchUsdtBalance(),
        refetchNadBalance(),
        refetchLpBalance(),
        lensState.refetch()
      ]);
      setActionMessage("Remove liquidity transaction confirmed.");
    } catch (error) {
      console.error(error);
      setActionError(normalizeError(error));
    } finally {
      setIsRemovingLiquidity(false);
    }
  };

  const onSyncReserves = async () => {
    clearActionNotice();
    setIsSyncingReserves(true);

    try {
      if (!publicClient) {
        throw new Error("Public client is not ready.");
      }

      const txHash = await writeContractAsync({
        address: env.pairUsdtNad,
        abi: pairAbi,
        functionName: "sync"
      });

      await publicClient.waitForTransactionReceipt({ hash: txHash });
      await Promise.all([lensState.refetch(), refetchUsdtBalance(), refetchNadBalance()]);
      setActionMessage("Pair sync transaction confirmed.");
    } catch (error) {
      console.error(error);
      setActionError(normalizeError(error));
    } finally {
      setIsSyncingReserves(false);
    }
  };

  const onSkimExcess = async () => {
    if (!address) {
      return;
    }

    clearActionNotice();
    setIsSkimmingExcess(true);

    try {
      if (!publicClient) {
        throw new Error("Public client is not ready.");
      }

      const txHash = await writeContractAsync({
        address: env.pairUsdtNad,
        abi: pairAbi,
        functionName: "skim",
        args: [address]
      });

      await publicClient.waitForTransactionReceipt({ hash: txHash });
      await Promise.all([lensState.refetch(), refetchUsdtBalance(), refetchNadBalance()]);
      setActionMessage("Skim transaction confirmed.");
    } catch (error) {
      console.error(error);
      setActionError(normalizeError(error));
    } finally {
      setIsSkimmingExcess(false);
    }
  };

  const primaryButtonClass = "rounded-lg bg-cyan-700 px-3 py-2 text-sm font-semibold text-white disabled:opacity-60";
  const secondaryButtonClass =
    "rounded-lg border border-slate-300 px-3 py-2 text-sm font-medium text-slate-700 disabled:opacity-60";
  const cardTitleClass = "text-sm font-semibold uppercase tracking-[0.12em] text-slate-600";

  return (
    <>
      <section className="rounded-2xl border border-slate-300 bg-white/85 p-4 shadow-sm">
        <h2 className={cardTitleClass}>Pair Overview</h2>
        {view ? (
          <div className="mt-3 grid grid-cols-[minmax(0,1fr)_minmax(0,2fr)] items-start gap-x-3 gap-y-1.5 text-sm">
            <span className="text-slate-500">Pair</span>
            <span className="text-right font-semibold text-slate-900">
              <span className="inline-flex max-w-full items-start justify-end gap-2">
                <span className="break-all font-mono text-[12px] leading-5">{view.staticData.pair ?? "-"}</span>
                <button
                  type="button"
                  onClick={() => void onCopyAddress("pair", view.staticData.pair ?? "")}
                  disabled={!view.staticData.pair}
                  className="shrink-0 rounded border border-slate-300 px-1.5 py-0.5 text-[11px] font-semibold text-slate-700 hover:bg-slate-100 disabled:cursor-not-allowed disabled:opacity-50"
                >
                  {copiedAddressKey === "pair" ? "Copied" : "Copy"}
                </button>
              </span>
            </span>
            {mergedTokenAddressRows.map((row) => (
              <Fragment key={row.key}>
                <span className="text-slate-500">{row.label}</span>
                <span className="text-right font-semibold text-slate-900">
                  <span className="inline-flex max-w-full items-start justify-end gap-2">
                    <span className="break-all font-mono text-[12px] leading-5">{row.address ?? "-"}</span>
                    <button
                      type="button"
                      onClick={() => void onCopyAddress(`token-role-${row.key}`, row.address ?? "")}
                      disabled={!row.address}
                      className="shrink-0 rounded border border-slate-300 px-1.5 py-0.5 text-[11px] font-semibold text-slate-700 hover:bg-slate-100 disabled:cursor-not-allowed disabled:opacity-50"
                    >
                      {copiedAddressKey === `token-role-${row.key}` ? "Copied" : "Copy"}
                    </button>
                  </span>
                </span>
              </Fragment>
            ))}
            <span className="text-slate-500">
              <span className="group relative inline-flex items-center gap-1">
                <span>Accounting OK</span>
                <button
                  type="button"
                  className="inline-flex h-4 w-4 items-center justify-center rounded-full border border-slate-300 bg-slate-100 text-[10px] font-bold text-slate-600"
                  aria-label="Accounting OK 의미 보기"
                >
                  i
                </button>
                <span
                  role="tooltip"
                  className="pointer-events-none absolute left-0 top-6 z-20 hidden w-80 rounded-lg border border-slate-200 bg-white p-2 text-[11px] leading-5 text-slate-700 shadow-lg group-hover:block group-focus-within:block"
                >
                  Yes: 현재 raw, reserve(stored), effective(current), quote vault 사이 회계 관계가 정상 범위라는 뜻입니다.
                  <br />
                  No: vault drift 또는 회계 불일치 가능성이 감지된 상태입니다.
                  <br />
                  원인 예시: dust 누적, sync 미실행, 비정상 토큰 동작(FOT/rebase 등).
                  <br />
                  권장: 상태 갱신 후 필요하면 Sync/Skim 실행 뒤 다시 확인하세요.
                </span>
              </span>
            </span>
            <span className="text-right font-semibold text-slate-900">{view.dynamicData.accountingOk ? "Yes" : "No"}</span>
            <span className="text-slate-500">Buy Tax</span>
            <span className="text-right font-semibold text-slate-900">{formatBps(view.staticData.buyTaxBps)}</span>
            <span className="text-slate-500">Sell Tax</span>
            <span className="text-right font-semibold text-slate-900">{formatBps(view.staticData.sellTaxBps)}</span>
            <span className="text-slate-500">LP Fee</span>
            <span className="text-right font-semibold text-slate-900">{formatBps(view.staticData.lpFeeBps)}</span>
            <span className="text-slate-500">Tax Collector</span>
            <span className="text-right font-semibold text-slate-900">
              <span className="inline-flex max-w-full items-start justify-end gap-2">
                <span className="break-all font-mono text-[12px] leading-5">{view.staticData.taxCollector ?? "-"}</span>
                <button
                  type="button"
                  onClick={() => void onCopyAddress("taxCollector", view.staticData.taxCollector ?? "")}
                  disabled={!view.staticData.taxCollector}
                  className="shrink-0 rounded border border-slate-300 px-1.5 py-0.5 text-[11px] font-semibold text-slate-700 hover:bg-slate-100 disabled:cursor-not-allowed disabled:opacity-50"
                >
                  {copiedAddressKey === "taxCollector" ? "Copied" : "Copy"}
                </button>
              </span>
            </span>
            <span className="text-slate-500">Accumulated Quote Tax</span>
            <span className="text-right font-semibold text-slate-900 tabular-nums">
              {formatTokenAmount(view.dynamicData.accumulatedQuoteTax, quoteMeta?.decimals ?? 18)} {quoteMeta?.symbol ?? "QUOTE"}
            </span>
          </div>
        ) : (
          <p className="mt-3 text-sm text-slate-600">Lens pair view is loading or unavailable.</p>
        )}
      </section>

      <section className="rounded-2xl border border-slate-300 bg-white/85 p-4 shadow-sm">
        <h2 className={cardTitleClass}>Reserve / Effective / Raw / Dust</h2>
        <div className="mt-2 grid gap-1 rounded-lg border border-slate-200 bg-slate-50 p-3 text-xs text-slate-600">
          <p>
            <span className="font-semibold text-slate-700">Reserve:</span> pair <code>getReserves</code> 기준 저장 잔고
            (AMM 기준값)
          </p>
          <p>
            <span className="font-semibold text-slate-700">Effective:</span> raw에서 quote vault를 반영해 계산한 현재 유효 잔고
            (dust가 있으면 Reserve와 달라질 수 있음)
          </p>
          <p>
            <span className="font-semibold text-slate-700">Raw:</span> pair가 실제로 보유 중인 ERC-20 잔고
          </p>
          <p>
            <span className="font-semibold text-slate-700">Dust:</span> 기대 raw 대비 초과분(초과 없으면 0, 정리 대상 잔여량)
          </p>
        </div>
        {view ? (
          <div className="mt-3 grid grid-cols-[minmax(0,1fr)_auto] items-baseline gap-x-3 gap-y-1.5 text-sm">
            <span className="text-slate-500">Reserve0 / Reserve1 (stored)</span>
            <span className="text-right font-semibold text-slate-900 tabular-nums">
              {formatTokenAmount(view.dynamicData.reserve0, token0Meta?.decimals ?? defaultTokenMeta.decimals)}{" "}
              {token0Meta?.symbol ?? defaultTokenMeta.symbol} /{" "}
              {formatTokenAmount(view.dynamicData.reserve1, token1Meta?.decimals ?? defaultTokenMeta.decimals)}{" "}
              {token1Meta?.symbol ?? defaultTokenMeta.symbol}
            </span>
            <span className="text-slate-500">Effective0 / Effective1 (current)</span>
            <span className="text-right font-semibold text-slate-900 tabular-nums">
              {formatTokenAmount(view.dynamicData.effective0, token0Meta?.decimals ?? defaultTokenMeta.decimals)}{" "}
              {token0Meta?.symbol ?? defaultTokenMeta.symbol} /{" "}
              {formatTokenAmount(view.dynamicData.effective1, token1Meta?.decimals ?? defaultTokenMeta.decimals)}{" "}
              {token1Meta?.symbol ?? defaultTokenMeta.symbol}
            </span>
            <span className="text-slate-500">Raw0 / Raw1</span>
            <span className="text-right font-semibold text-slate-900 tabular-nums">
              {formatTokenAmount(view.dynamicData.raw0, token0Meta?.decimals ?? defaultTokenMeta.decimals)}{" "}
              {token0Meta?.symbol ?? defaultTokenMeta.symbol} /{" "}
              {formatTokenAmount(view.dynamicData.raw1, token1Meta?.decimals ?? defaultTokenMeta.decimals)}{" "}
              {token1Meta?.symbol ?? defaultTokenMeta.symbol}
            </span>
            <span className="text-slate-500">Dust0 / Dust1</span>
            <span className="text-right font-semibold text-slate-900 tabular-nums">
              {formatTokenAmount(view.dynamicData.dust0, token0Meta?.decimals ?? defaultTokenMeta.decimals)}{" "}
              {token0Meta?.symbol ?? defaultTokenMeta.symbol} /{" "}
              {formatTokenAmount(view.dynamicData.dust1, token1Meta?.decimals ?? defaultTokenMeta.decimals)}{" "}
              {token1Meta?.symbol ?? defaultTokenMeta.symbol}
            </span>
          </div>
        ) : (
          <p className="mt-3 text-sm text-slate-600">No reserve snapshot yet.</p>
        )}
        {!isConnected && (
          <p className="mt-3 text-sm text-slate-600">Connect wallet to execute sync/skim maintenance actions.</p>
        )}
        <div className="mt-3 flex flex-wrap gap-2">
          {wrongNetwork ? (
            <button type="button" onClick={() => void onSwitchNetwork()} disabled={isSwitching} className={primaryButtonClass}>
              {isSwitching ? "Switching..." : `Switch to chain ${env.chainId}`}
            </button>
          ) : (
            <>
              <button
                type="button"
                onClick={() => void onSyncReserves()}
                disabled={!isConnected || isSyncingReserves || isSkimmingExcess}
                className={primaryButtonClass}
              >
                {isSyncingReserves ? "Syncing..." : "Sync"}
              </button>
              <button
                type="button"
                onClick={() => void onSkimExcess()}
                disabled={!isConnected || !address || isSkimmingExcess || isSyncingReserves}
                className={primaryButtonClass}
              >
                {isSkimmingExcess ? "Skimming..." : "Skim"}
              </button>
            </>
          )}
        </div>
      </section>

      <section className="rounded-2xl border border-slate-300 bg-white/85 p-4 shadow-sm">
        <h2 className={cardTitleClass}>Add Liquidity</h2>
        {!isConnected && <p className="mt-3 text-sm text-slate-600">Connect wallet to approve and add liquidity.</p>}

        <div className="mt-3 grid gap-3 sm:grid-cols-2">
          <label className="grid gap-1 text-sm">
            <span className="text-xs font-semibold uppercase tracking-wide text-slate-500">{usdtSymbol} amount</span>
            <input
              value={addUsdtInput}
              onChange={(event) => setAddUsdtInput(event.target.value)}
              inputMode="decimal"
              placeholder="0.0"
              className="rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-cyan-500"
            />
          </label>
          <label className="grid gap-1 text-sm">
            <span className="text-xs font-semibold uppercase tracking-wide text-slate-500">{nadSymbol} amount</span>
            <input
              value={addNadInput}
              onChange={(event) => setAddNadInput(event.target.value)}
              inputMode="decimal"
              placeholder="0.0"
              className="rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-cyan-500"
            />
          </label>
        </div>

        <div className="mt-3 grid gap-1 rounded-lg bg-slate-100 p-3 text-sm text-slate-700">
          <p>
            Wallet Balance: {formatTokenAmount(usdtBalance, usdtDecimals)} {usdtSymbol} /{" "}
            {formatTokenAmount(nadBalance, nadDecimals)} {nadSymbol}
          </p>
          <p>
            Allowance: {formatTokenAmount(usdtAllowance, usdtDecimals)} {usdtSymbol} /{" "}
            {formatTokenAmount(nadAllowance, nadDecimals)} {nadSymbol}
          </p>
        </div>

        <div className="mt-3 flex flex-wrap gap-2">
          {wrongNetwork ? (
            <button type="button" onClick={() => void onSwitchNetwork()} disabled={isSwitching} className={primaryButtonClass}>
              {isSwitching ? "Switching..." : `Switch to chain ${env.chainId}`}
            </button>
          ) : (
            <>
              {needsUsdtApproval && (
                <button
                  type="button"
                  onClick={() => void onApproveUsdt()}
                  disabled={isApprovingUsdt || !isConnected}
                  className={secondaryButtonClass}
                >
                  {isApprovingUsdt ? `Approving ${usdtSymbol}...` : `Approve ${usdtSymbol}`}
                </button>
              )}
              {needsNadApproval && (
                <button
                  type="button"
                  onClick={() => void onApproveNad()}
                  disabled={isApprovingNad || !isConnected}
                  className={secondaryButtonClass}
                >
                  {isApprovingNad ? `Approving ${nadSymbol}...` : `Approve ${nadSymbol}`}
                </button>
              )}
              <button
                type="button"
                onClick={() => void onAddLiquidity()}
                disabled={!canAddLiquidity || isAddingLiquidity}
                className={primaryButtonClass}
              >
                {isAddingLiquidity ? "Adding liquidity..." : "Add Liquidity"}
              </button>
            </>
          )}
        </div>
      </section>

      <section className="rounded-2xl border border-slate-300 bg-white/85 p-4 shadow-sm">
        <h2 className={cardTitleClass}>Remove Liquidity</h2>
        {!isConnected && <p className="mt-3 text-sm text-slate-600">Connect wallet to approve LP and remove liquidity.</p>}

        <div className="mt-3 grid gap-3 sm:grid-cols-2">
          <label className="grid gap-1 text-sm">
            <span className="text-xs font-semibold uppercase tracking-wide text-slate-500">{lpSymbol} amount</span>
            <input
              value={removeLpInput}
              onChange={(event) => setRemoveLpInput(event.target.value)}
              inputMode="decimal"
              placeholder="0.0"
              className="rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-cyan-500"
            />
          </label>
        </div>

        <div className="mt-3 grid gap-1 rounded-lg bg-slate-100 p-3 text-sm text-slate-700">
          <p>
            LP Balance: {formatTokenAmount(lpBalance, lpDecimals)} {lpSymbol}
          </p>
          <p>
            LP Allowance: {formatTokenAmount(lpAllowance, lpDecimals)} {lpSymbol}
          </p>
          <p>
            Estimated out: {formatTokenAmount(estimatedRemoveUsdt, usdtDecimals)} {usdtSymbol} /{" "}
            {formatTokenAmount(estimatedRemoveNad, nadDecimals)} {nadSymbol}
          </p>
        </div>

        <div className="mt-3 flex flex-wrap gap-2">
          {wrongNetwork ? (
            <button type="button" onClick={() => void onSwitchNetwork()} disabled={isSwitching} className={primaryButtonClass}>
              {isSwitching ? "Switching..." : `Switch to chain ${env.chainId}`}
            </button>
          ) : (
            <>
              {needsLpApproval && (
                <button
                  type="button"
                  onClick={() => void onApproveLp()}
                  disabled={isApprovingLp || !isConnected}
                  className={secondaryButtonClass}
                >
                  {isApprovingLp ? "Approving LP..." : "Approve LP"}
                </button>
              )}
              <button
                type="button"
                onClick={() => void onRemoveLiquidity()}
                disabled={!canRemoveLiquidity || isRemovingLiquidity}
                className={primaryButtonClass}
              >
                {isRemovingLiquidity ? "Removing liquidity..." : "Remove Liquidity"}
              </button>
            </>
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
