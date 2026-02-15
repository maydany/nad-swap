import { erc20Abi, routerAbi, type AddressHex } from "@nadswap/contracts";
import { useMemo, useState } from "react";
import { formatUnits, parseUnits } from "viem";
import {
  useAccount,
  useChainId,
  usePublicClient,
  useReadContract,
  useSwitchChain,
  useWriteContract
} from "wagmi";

import type { PairHealthViewModel } from "../lens/pairHealthView";
import type { LensStatus } from "../lens/types";
import { TradeActionButton } from "./TradeActionButton";
import { getSwapFeeBreakdown, type SwapDirection } from "./feeBreakdown";
import { applySlippageBps } from "./math";

const DEFAULT_SLIPPAGE_BPS = 50;

type SwapCardProps = {
  expectedChainId: number;
  routerAddress: AddressHex;
  usdtAddress: AddressHex;
  nadAddress: AddressHex;
  lensStatus: LensStatus | null;
  pairHealth: PairHealthViewModel | null;
};

const formatAmount = (value: bigint | null, decimals: number): string => {
  if (value === null) {
    return "-";
  }

  return Number(formatUnits(value, decimals)).toLocaleString(undefined, {
    maximumFractionDigits: 6
  });
};

const formatBps = (value: number): string => `${(value / 100).toFixed(2)}%`;

const normalizeError = (error: unknown): string => {
  if (error instanceof Error) {
    return error.message;
  }
  return "Unknown transaction error";
};

const normalizeAddress = (value: AddressHex | null | undefined): string => (value ?? "").toLowerCase();

type FeeFormulaTooltipProps = {
  isQuoteToBase: boolean;
  buyTaxBps: number;
  sellTaxBps: number;
  lpFeeBps: number;
};

const FeeFormulaTooltip = ({ isQuoteToBase, buyTaxBps, sellTaxBps, lpFeeBps }: FeeFormulaTooltipProps) => {
  const currentTaxBps = isQuoteToBase ? buyTaxBps : sellTaxBps;

  return (
    <div className="group relative inline-flex items-center">
      <button
        type="button"
        className="inline-flex h-5 w-5 items-center justify-center rounded-full border border-cyan-300 bg-white text-[11px] font-bold text-cyan-700"
        aria-label="Show fee and tax formula"
      >
        i
      </button>
      <div
        role="tooltip"
        className="pointer-events-none absolute right-0 top-7 z-20 hidden w-[21rem] rounded-lg border border-slate-200 bg-white p-3 text-[11px] leading-5 text-slate-700 shadow-lg group-hover:block group-focus-within:block"
      >
        <p className="font-semibold text-slate-900">Current formula ({isQuoteToBase ? "Buy NAD" : "Sell NAD"})</p>
        <p className="mt-1">LP fee: {lpFeeBps} bps, Tax: {currentTaxBps} bps</p>
        {isQuoteToBase ? (
          <>
            <p className="mt-2">1) taxIn = floor(amountIn x buyTaxBps / 10000)</p>
            <p>2) effectiveIn = amountIn - taxIn</p>
            <p>3) amountInWithFee = effectiveIn x (10000 - lpFeeBps)</p>
            <p>4) grossOut = floor((amountInWithFee x reserveOut) / (reserveIn x 10000 + amountInWithFee))</p>
            <p>5) netOut = grossOut</p>
          </>
        ) : (
          <>
            <p className="mt-2">1) amountInWithFee = amountIn x (10000 - lpFeeBps)</p>
            <p>2) grossOut = floor((amountInWithFee x reserveOut) / (reserveIn x 10000 + amountInWithFee))</p>
            <p>3) taxOut = floor(grossOut x sellTaxBps / 10000)</p>
            <p>4) netOut = grossOut - taxOut</p>
          </>
        )}
        <p className="mt-2 text-slate-500">Displayed values follow on-chain integer math (wei units) before formatting.</p>
      </div>
    </div>
  );
};

export const SwapCard = ({
  expectedChainId,
  routerAddress,
  usdtAddress,
  nadAddress,
  lensStatus,
  pairHealth
}: SwapCardProps) => {
  const { address, isConnected } = useAccount();
  const chainId = useChainId();
  const { switchChainAsync } = useSwitchChain();
  const { writeContractAsync } = useWriteContract();
  const publicClient = usePublicClient({ chainId: expectedChainId });

  const [direction, setDirection] = useState<SwapDirection>("quoteToBase");
  const [amountIn, setAmountIn] = useState("0");
  const [actionMessage, setActionMessage] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);

  const [isSwitching, setIsSwitching] = useState(false);
  const [isApproving, setIsApproving] = useState(false);
  const [isSwapping, setIsSwapping] = useState(false);

  const isQuoteToBase = direction === "quoteToBase";
  const wrongNetwork = isConnected && chainId !== expectedChainId;
  const lensBlocksTrade = lensStatus !== null && lensStatus !== 0;

  const inputTokenAddress = isQuoteToBase ? usdtAddress : nadAddress;
  const outputTokenAddress = isQuoteToBase ? nadAddress : usdtAddress;
  const path = useMemo(() => [inputTokenAddress, outputTokenAddress] as const, [inputTokenAddress, outputTokenAddress]);

  const { data: usdtSymbol = "USDT" } = useReadContract({
    address: usdtAddress,
    abi: erc20Abi,
    functionName: "symbol"
  });
  const { data: nadSymbol = "NAD" } = useReadContract({
    address: nadAddress,
    abi: erc20Abi,
    functionName: "symbol"
  });
  const { data: usdtDecimals = 18 } = useReadContract({
    address: usdtAddress,
    abi: erc20Abi,
    functionName: "decimals"
  });
  const { data: nadDecimals = 18 } = useReadContract({
    address: nadAddress,
    abi: erc20Abi,
    functionName: "decimals"
  });

  const inSymbol = isQuoteToBase ? usdtSymbol : nadSymbol;
  const outSymbol = isQuoteToBase ? nadSymbol : usdtSymbol;
  const inDecimals = isQuoteToBase ? usdtDecimals : nadDecimals;
  const outDecimals = isQuoteToBase ? nadDecimals : usdtDecimals;

  const parsedAmountIn = useMemo(() => {
    const normalized = amountIn.trim();
    if (normalized === "") {
      return null;
    }

    try {
      const parsed = parseUnits(normalized, inDecimals);
      return parsed > 0n ? parsed : null;
    } catch {
      return null;
    }
  }, [amountIn, inDecimals]);

  const ownerAddress = (address ?? "0x0000000000000000000000000000000000000000") as AddressHex;

  const {
    data: allowance = 0n,
    refetch: refetchAllowance,
    error: allowanceError
  } = useReadContract({
    address: inputTokenAddress,
    abi: erc20Abi,
    functionName: "allowance",
    args: [ownerAddress, routerAddress],
    query: {
      enabled: isConnected
    }
  });

  const { data: balanceIn = 0n, refetch: refetchBalanceIn } = useReadContract({
    address: inputTokenAddress,
    abi: erc20Abi,
    functionName: "balanceOf",
    args: [ownerAddress],
    query: {
      enabled: isConnected
    }
  });

  const { data: balanceOut = 0n, refetch: refetchBalanceOut } = useReadContract({
    address: outputTokenAddress,
    abi: erc20Abi,
    functionName: "balanceOf",
    args: [ownerAddress],
    query: {
      enabled: isConnected
    }
  });

  const quoteEnabled = Boolean(isConnected && parsedAmountIn && !wrongNetwork);

  const {
    data: amountsOut,
    error: quoteError,
    isFetching: isQuoteFetching,
    refetch: refetchQuote
  } = useReadContract({
    address: routerAddress,
    abi: routerAbi,
    functionName: "getAmountsOut",
    args: [parsedAmountIn ?? 0n, path],
    query: {
      enabled: quoteEnabled
    }
  });

  const quotedOut = Array.isArray(amountsOut) && amountsOut.length > 0 ? amountsOut[amountsOut.length - 1] : null;
  const amountOutMin = quotedOut !== null ? applySlippageBps(quotedOut, DEFAULT_SLIPPAGE_BPS) : null;
  const needsApproval = Boolean(parsedAmountIn && allowance < parsedAmountIn);

  const reserveIn = useMemo(() => {
    if (!pairHealth) {
      return null;
    }
    const token0 = normalizeAddress(pairHealth.staticData.token0);
    const token1 = normalizeAddress(pairHealth.staticData.token1);
    const inToken = normalizeAddress(inputTokenAddress);
    if (inToken === token0) {
      return pairHealth.dynamicData.reserve0;
    }
    if (inToken === token1) {
      return pairHealth.dynamicData.reserve1;
    }
    return null;
  }, [inputTokenAddress, pairHealth]);

  const reserveOut = useMemo(() => {
    if (!pairHealth) {
      return null;
    }
    const token0 = normalizeAddress(pairHealth.staticData.token0);
    const token1 = normalizeAddress(pairHealth.staticData.token1);
    const outToken = normalizeAddress(outputTokenAddress);
    if (outToken === token0) {
      return pairHealth.dynamicData.reserve0;
    }
    if (outToken === token1) {
      return pairHealth.dynamicData.reserve1;
    }
    return null;
  }, [outputTokenAddress, pairHealth]);

  const lpFeeBps = pairHealth?.staticData.lpFeeBps ?? 20;
  const buyTaxBps = pairHealth?.staticData.buyTaxBps ?? 0;
  const sellTaxBps = pairHealth?.staticData.sellTaxBps ?? 0;

  const feeBreakdown = useMemo(
    () =>
      getSwapFeeBreakdown({
        direction,
        amountIn: parsedAmountIn,
        quotedOut,
        reserveIn,
        reserveOut,
        buyTaxBps,
        sellTaxBps,
        lpFeeBps
      }),
    [direction, parsedAmountIn, quotedOut, reserveIn, reserveOut, buyTaxBps, sellTaxBps, lpFeeBps]
  );

  const canSwap =
    isConnected &&
    !wrongNetwork &&
    !needsApproval &&
    !lensBlocksTrade &&
    parsedAmountIn !== null &&
    amountOutMin !== null;

  const onSwitch = async () => {
    setActionError(null);
    setActionMessage(null);

    if (!switchChainAsync) {
      setActionError("Wallet connector does not support programmatic chain switch.");
      return;
    }

    setIsSwitching(true);
    try {
      await switchChainAsync({ chainId: expectedChainId });
      setActionMessage("Network switched.");
    } catch (error) {
      console.error(error);
      setActionError(normalizeError(error));
    } finally {
      setIsSwitching(false);
    }
  };

  const onApprove = async () => {
    if (!parsedAmountIn) {
      return;
    }

    setActionError(null);
    setActionMessage(null);
    setIsApproving(true);

    try {
      if (!publicClient) {
        throw new Error("Public client is not ready.");
      }

      const txHash = await writeContractAsync({
        address: inputTokenAddress,
        abi: erc20Abi,
        functionName: "approve",
        args: [routerAddress, parsedAmountIn]
      });

      await publicClient.waitForTransactionReceipt({ hash: txHash });
      await refetchAllowance();
      setActionMessage(`${inSymbol} approve transaction confirmed.`);
    } catch (error) {
      console.error(error);
      setActionError(normalizeError(error));
    } finally {
      setIsApproving(false);
    }
  };

  const onSwap = async () => {
    if (!address || !parsedAmountIn || amountOutMin === null) {
      return;
    }

    setActionError(null);
    setActionMessage(null);
    setIsSwapping(true);

    try {
      if (!publicClient) {
        throw new Error("Public client is not ready.");
      }

      const deadline = BigInt(Math.floor(Date.now() / 1000) + 600);
      const txHash = await writeContractAsync({
        address: routerAddress,
        abi: routerAbi,
        functionName: "swapExactTokensForTokens",
        args: [parsedAmountIn, amountOutMin, path, address, deadline]
      });

      await publicClient.waitForTransactionReceipt({ hash: txHash });
      await Promise.all([refetchAllowance(), refetchBalanceIn(), refetchBalanceOut(), refetchQuote()]);
      setActionMessage("Swap transaction confirmed.");
    } catch (error) {
      console.error(error);
      setActionError(normalizeError(error));
    } finally {
      setIsSwapping(false);
    }
  };

  return (
    <section className="rounded-2xl border border-slate-300 bg-white/85 p-4 shadow-sm">
      <h2 className="text-sm font-semibold text-slate-900">USDT/NAD Swap</h2>

      <div className="mt-3 grid gap-2 sm:grid-cols-2">
        <button
          type="button"
          onClick={() => setDirection("quoteToBase")}
          className={`rounded-lg border px-3 py-2 text-sm font-semibold ${
            isQuoteToBase ? "border-cyan-600 bg-cyan-100 text-cyan-900" : "border-slate-300 bg-white text-slate-700"
          }`}
        >
          Buy NAD (USDT → NAD)
        </button>
        <button
          type="button"
          onClick={() => setDirection("baseToQuote")}
          className={`rounded-lg border px-3 py-2 text-sm font-semibold ${
            !isQuoteToBase ? "border-cyan-600 bg-cyan-100 text-cyan-900" : "border-slate-300 bg-white text-slate-700"
          }`}
        >
          Sell NAD (NAD → USDT)
        </button>
      </div>

      <div className="mt-4 grid gap-2">
        <label htmlFor="amount-in" className="text-xs font-semibold uppercase tracking-wide text-slate-500">
          Amount In ({inSymbol})
        </label>
        <input
          id="amount-in"
          value={amountIn}
          onChange={(event) => setAmountIn(event.target.value)}
          className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-cyan-500"
          placeholder="0.0"
          inputMode="decimal"
        />
      </div>

      <div className="mt-4 grid gap-2 rounded-lg bg-slate-100 p-3 text-sm text-slate-700">
        <p>Quote ({outSymbol}): {isQuoteFetching ? "Fetching..." : formatAmount(quotedOut, outDecimals)}</p>
        <p>amountOutMin (0.5% slippage): {formatAmount(amountOutMin, outDecimals)}</p>
        <p>
          Allowance: {formatAmount(allowance, inDecimals)} {inSymbol}
        </p>
        <p>
          Balance: {formatAmount(balanceIn, inDecimals)} {inSymbol} / {formatAmount(balanceOut, outDecimals)} {outSymbol}
        </p>
      </div>

      <div className="mt-4 grid gap-2 rounded-lg border border-cyan-200 bg-cyan-50 p-3 text-sm text-slate-800">
        <div className="flex items-center justify-between gap-2">
          <p className="font-semibold text-slate-900">Fee & Tax Breakdown</p>
          <FeeFormulaTooltip isQuoteToBase={isQuoteToBase} buyTaxBps={buyTaxBps} sellTaxBps={sellTaxBps} lpFeeBps={lpFeeBps} />
        </div>
        <p>
          LP Fee (current): {formatBps(feeBreakdown.lpFeeBps)} ({feeBreakdown.lpFeeBps} bps)
        </p>
        <p>
          {isQuoteToBase ? "Buy Tax (current)" : "Sell Tax (current)"}: {formatBps(feeBreakdown.taxBps)} ({feeBreakdown.taxBps} bps)
        </p>
        <p>
          Input Amount: {formatAmount(feeBreakdown.inputAmount, inDecimals)} {inSymbol}
        </p>
        {isQuoteToBase ? (
          <>
            <p>
              Buy Tax Paid: {formatAmount(feeBreakdown.taxAmountIn, inDecimals)} {inSymbol}
            </p>
            <p>
              Effective Input After Buy Tax: {formatAmount(feeBreakdown.effectiveSwapInput, inDecimals)} {inSymbol}
            </p>
            <p>
              LP Fee Paid: {formatAmount(feeBreakdown.lpFeeAmount, inDecimals)} {inSymbol}
            </p>
            <p>
              Expected Receive (Net): {formatAmount(feeBreakdown.netOutput, outDecimals)} {outSymbol}
            </p>
          </>
        ) : (
          <>
            <p>
              LP Fee Paid: {formatAmount(feeBreakdown.lpFeeAmount, inDecimals)} {inSymbol}
            </p>
            <p>
              Gross Output Before Sell Tax: {formatAmount(feeBreakdown.grossOutput, outDecimals)} {outSymbol}
            </p>
            <p>
              Sell Tax Paid: {formatAmount(feeBreakdown.taxAmountOut, outDecimals)} {outSymbol}
            </p>
            <p>
              Expected Receive (Net): {formatAmount(feeBreakdown.netOutput, outDecimals)} {outSymbol}
            </p>
          </>
        )}
      </div>

      {lensBlocksTrade && (
        <p className="mt-4 rounded-lg bg-amber-100 px-3 py-2 text-sm text-amber-900">
          Lens status is not OK. Trade is temporarily blocked.
        </p>
      )}

      {quoteError && (
        <p className="mt-4 rounded-lg bg-rose-100 px-3 py-2 text-sm text-rose-900">Quote error: {quoteError.message}</p>
      )}

      {allowanceError && (
        <p className="mt-4 rounded-lg bg-rose-100 px-3 py-2 text-sm text-rose-900">
          Allowance read error: {allowanceError.message}
        </p>
      )}

      {actionError && (
        <p className="mt-4 rounded-lg bg-rose-100 px-3 py-2 text-sm text-rose-900">{actionError}</p>
      )}

      {actionMessage && (
        <p className="mt-4 rounded-lg bg-emerald-100 px-3 py-2 text-sm text-emerald-900">{actionMessage}</p>
      )}

      <div className="mt-4">
        <TradeActionButton
          isConnected={isConnected}
          wrongNetwork={wrongNetwork}
          needsApproval={needsApproval}
          canSwap={canSwap}
          isSwitching={isSwitching}
          isApproving={isApproving}
          isSwapping={isSwapping}
          onSwitch={() => void onSwitch()}
          onApprove={() => void onApprove()}
          onSwap={() => void onSwap()}
          approveLabel={`Approve ${inSymbol}`}
          swapLabel={`Swap ${inSymbol} -> ${outSymbol}`}
        />
      </div>
    </section>
  );
};
