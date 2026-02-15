import { erc20Abi, routerAbi, type AddressHex } from "@nadswap/contracts";
import { useMemo, useState } from "react";
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
import { formatBps, formatTokenAmount, shortAddress } from "../lib/format";
import { ConfigErrorPanel } from "./ConfigErrorPanel";

const DEFAULT_SLIPPAGE_BPS = 50;

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

  const primaryButtonClass = "rounded-lg bg-cyan-700 px-3 py-2 text-sm font-semibold text-white disabled:opacity-60";
  const secondaryButtonClass =
    "rounded-lg border border-slate-300 px-3 py-2 text-sm font-medium text-slate-700 disabled:opacity-60";

  return (
    <>
      <section className="rounded-2xl border border-slate-300 bg-white/85 p-4 shadow-sm">
        <h2 className="text-sm font-semibold text-slate-900">Pair Overview</h2>
        {view ? (
          <div className="mt-3 grid gap-2 text-sm text-slate-700 sm:grid-cols-2">
            <p>Pair: {shortAddress(view.staticData.pair)}</p>
            <p>Token0: {shortAddress(view.staticData.token0)}</p>
            <p>Token1: {shortAddress(view.staticData.token1)}</p>
            <p>Quote: {shortAddress(view.staticData.quoteToken)}</p>
            <p>Base: {shortAddress(view.staticData.baseToken)}</p>
            <p>Accounting OK: {view.dynamicData.accountingOk ? "Yes" : "No"}</p>
            <p>Buy Tax: {formatBps(view.staticData.buyTaxBps)}</p>
            <p>Sell Tax: {formatBps(view.staticData.sellTaxBps)}</p>
            <p>LP Fee: {formatBps(view.staticData.lpFeeBps)}</p>
            <p>Tax Collector: {shortAddress(view.staticData.taxCollector)}</p>
            <p>
              Accumulated Quote Tax: {formatTokenAmount(view.dynamicData.accumulatedQuoteTax, quoteMeta?.decimals ?? 18)}{" "}
              {quoteMeta?.symbol ?? "QUOTE"}
            </p>
          </div>
        ) : (
          <p className="mt-3 text-sm text-slate-600">Lens pair view is loading or unavailable.</p>
        )}
      </section>

      <section className="rounded-2xl border border-slate-300 bg-white/85 p-4 shadow-sm">
        <h2 className="text-sm font-semibold text-slate-900">Reserves / Effective / Dust</h2>
        {view ? (
          <div className="mt-3 grid gap-2 text-sm text-slate-700">
            <p>
              reserve0/reserve1: {formatTokenAmount(view.dynamicData.reserve0, token0Meta?.decimals ?? defaultTokenMeta.decimals)}{" "}
              {token0Meta?.symbol ?? defaultTokenMeta.symbol} /{" "}
              {formatTokenAmount(view.dynamicData.reserve1, token1Meta?.decimals ?? defaultTokenMeta.decimals)}{" "}
              {token1Meta?.symbol ?? defaultTokenMeta.symbol}
            </p>
            <p>
              effective0/effective1:{" "}
              {formatTokenAmount(view.dynamicData.effective0, token0Meta?.decimals ?? defaultTokenMeta.decimals)}{" "}
              {token0Meta?.symbol ?? defaultTokenMeta.symbol} /{" "}
              {formatTokenAmount(view.dynamicData.effective1, token1Meta?.decimals ?? defaultTokenMeta.decimals)}{" "}
              {token1Meta?.symbol ?? defaultTokenMeta.symbol}
            </p>
            <p>
              raw0/raw1: {formatTokenAmount(view.dynamicData.raw0, token0Meta?.decimals ?? defaultTokenMeta.decimals)}{" "}
              {token0Meta?.symbol ?? defaultTokenMeta.symbol} /{" "}
              {formatTokenAmount(view.dynamicData.raw1, token1Meta?.decimals ?? defaultTokenMeta.decimals)}{" "}
              {token1Meta?.symbol ?? defaultTokenMeta.symbol}
            </p>
            <p>
              dust0/dust1: {formatTokenAmount(view.dynamicData.dust0, token0Meta?.decimals ?? defaultTokenMeta.decimals)}{" "}
              {token0Meta?.symbol ?? defaultTokenMeta.symbol} /{" "}
              {formatTokenAmount(view.dynamicData.dust1, token1Meta?.decimals ?? defaultTokenMeta.decimals)}{" "}
              {token1Meta?.symbol ?? defaultTokenMeta.symbol}
            </p>
          </div>
        ) : (
          <p className="mt-3 text-sm text-slate-600">No reserve snapshot yet.</p>
        )}
      </section>

      <section className="rounded-2xl border border-slate-300 bg-white/85 p-4 shadow-sm">
        <h2 className="text-sm font-semibold text-slate-900">Add Liquidity</h2>
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
            Balance: {formatTokenAmount(usdtBalance, usdtDecimals)} {usdtSymbol} / {formatTokenAmount(nadBalance, nadDecimals)} {nadSymbol}
          </p>
          <p>
            Allowance: {formatTokenAmount(usdtAllowance, usdtDecimals)} {usdtSymbol} /{" "}
            {formatTokenAmount(nadAllowance, nadDecimals)} {nadSymbol}
          </p>
          <p>
            amountMin (0.5%): {formatTokenAmount(addAmountMinUsdt, usdtDecimals)} {usdtSymbol} /{" "}
            {formatTokenAmount(addAmountMinNad, nadDecimals)} {nadSymbol}
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
        <h2 className="text-sm font-semibold text-slate-900">Remove Liquidity</h2>
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
          <p>
            amountMin (0.5%): {formatTokenAmount(removeAmountMinUsdt, usdtDecimals)} {usdtSymbol} /{" "}
            {formatTokenAmount(removeAmountMinNad, nadDecimals)} {nadSymbol}
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

      <section className="rounded-2xl border border-slate-300 bg-white/85 p-4 shadow-sm">
        <h2 className="text-sm font-semibold text-slate-900">User Balances / Allowances</h2>
        {!address && <p className="mt-3 text-sm text-slate-600">Connect wallet to view user-specific balances and allowances.</p>}
        {view && (
          <div className="mt-3 grid gap-2 text-sm text-slate-700 sm:grid-cols-2">
            <p>
              balance0: {formatTokenAmount(view.userData.balance0, token0Meta?.decimals ?? defaultTokenMeta.decimals)}{" "}
              {token0Meta?.symbol ?? defaultTokenMeta.symbol}
            </p>
            <p>
              balance1: {formatTokenAmount(view.userData.balance1, token1Meta?.decimals ?? defaultTokenMeta.decimals)}{" "}
              {token1Meta?.symbol ?? defaultTokenMeta.symbol}
            </p>
            <p>
              allowance0: {formatTokenAmount(view.userData.allowance0, token0Meta?.decimals ?? defaultTokenMeta.decimals)}{" "}
              {token0Meta?.symbol ?? defaultTokenMeta.symbol}
            </p>
            <p>
              allowance1: {formatTokenAmount(view.userData.allowance1, token1Meta?.decimals ?? defaultTokenMeta.decimals)}{" "}
              {token1Meta?.symbol ?? defaultTokenMeta.symbol}
            </p>
          </div>
        )}
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
