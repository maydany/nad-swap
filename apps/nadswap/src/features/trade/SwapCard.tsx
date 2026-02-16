import { erc20Abi, pairAbi, routerAbi, type AddressHex } from "@nadswap/contracts";
import { useMemo, useState } from "react";
import { HiOutlineArrowDown } from "react-icons/hi2";
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

const DEFAULT_SLIPPAGE_BPS = 0;

type SwapCardProps = {
  expectedChainId: number;
  routerAddress: AddressHex;
  pairAddress: AddressHex;
  usdtAddress: AddressHex;
  nadAddress: AddressHex;
  lensStatus: LensStatus | null;
  pairHealth: PairHealthViewModel | null;
  refetchPairHealth?: () => Promise<unknown>;
};

const formatAmount = (value: bigint | null, decimals: number): string => {
  if (value === null) {
    return "-";
  }

  return Number(formatUnits(value, decimals)).toLocaleString(undefined, {
    maximumFractionDigits: 12
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
        className="inline-flex h-5 w-5 items-center justify-center rounded-full border border-cyan-300 bg-cyan-50 text-[11px] font-bold text-cyan-700"
        aria-label="수수료 및 세금 계산식 보기"
      >
        i
      </button>
      <div
        role="tooltip"
        className="pointer-events-none absolute right-0 top-7 z-20 hidden w-[26rem] max-w-[calc(100vw-2rem)] rounded-lg border border-slate-200 bg-white p-3 text-[11px] leading-5 text-slate-700 shadow-lg group-hover:block group-focus-within:block"
      >
        <p className="font-semibold text-slate-900">현재 계산식 ({isQuoteToBase ? "NAD 매수" : "NAD 매도"})</p>
        <p className="mt-1">
          LP 수수료: {lpFeeBps} bps ({formatBps(lpFeeBps)}), 현재 적용 세율: {currentTaxBps} bps (
          {formatBps(currentTaxBps)})
        </p>
        <p className="mt-2 text-slate-600">기호 정의: amountIn=사용자 입력 수량, reserveIn/out=풀의 입력/출력 토큰 준비금, 10000 bps=100%</p>
        <p className="text-slate-600">모든 나눗셈은 온체인 정수 연산으로 처리되며, floor는 소수점 이하를 버립니다.</p>
        {isQuoteToBase ? (
          <>
            <p className="mt-2">1) taxIn = floor(amountIn x buyTaxBps / 10000)</p>
            <p className="text-slate-600">매수(Quote→Base)에서는 입력 Quote에서 세금을 먼저 공제합니다.</p>
            <p>2) effectiveIn = amountIn - taxIn</p>
            <p className="text-slate-600">실제 스왑 수학에 들어가는 입력은 effectiveIn입니다.</p>
            <p>3) amountInWithFee = effectiveIn x (10000 - lpFeeBps)</p>
            <p className="text-slate-600">LP 수수료를 반영한 유효 입력으로 x*y=k 공식에 투입됩니다.</p>
            <p>4) grossOut = floor((amountInWithFee x reserveOut) / (reserveIn x 10000 + amountInWithFee))</p>
            <p className="text-slate-600">정수 나눗셈 버림으로 인해 소수 부분은 출력에서 제외됩니다.</p>
            <p>5) netOut = grossOut</p>
            <p className="text-slate-600">매수 경로는 출력 측 추가 세금이 없어 grossOut과 netOut이 동일합니다.</p>
          </>
        ) : (
          <>
            <p className="mt-2">1) amountInWithFee = amountIn x (10000 - lpFeeBps)</p>
            <p className="text-slate-600">매도(Base→Quote)에서는 먼저 LP 수수료를 반영해 gross 출력 기반을 계산합니다.</p>
            <p>2) grossOut = floor((amountInWithFee x reserveOut) / (reserveIn x 10000 + amountInWithFee))</p>
            <p className="text-slate-600">이 값은 세금 공제 전 Quote 총출력(Gross Output)입니다.</p>
            <p>3) taxOut = floor(grossOut x sellTaxBps / 10000)</p>
            <p className="text-slate-600">매도세는 출력 Quote에서 계산되며, 버림 처리로 1 wei 단위 오차가 발생할 수 있습니다.</p>
            <p>4) netOut = grossOut - taxOut</p>
            <p className="text-slate-600">사용자 실수령(Expected Receive)은 netOut이며, 카드의 Sell Tax Paid는 (grossOut-netOut)입니다.</p>
          </>
        )}
        <p className="mt-2 text-slate-500">
          카드의 수치는 포맷팅 전 wei 정수 기준 온체인 연산 결과를 따릅니다. 따라서 UI 표시값 간 합/차에서 소수점 반올림 차이가 보일 수 있습니다.
        </p>
      </div>
    </div>
  );
};

type TokenPillProps = {
  symbol: string;
  tone: "sell" | "buy";
};

const TokenPill = ({ symbol, tone }: TokenPillProps) => {
  const normalizedSymbol = symbol.toUpperCase();
  const tokenImageSrc =
    normalizedSymbol === "USDT" ? "/tokens/usdt.png" : normalizedSymbol === "NAD" ? "/tokens/nad.png" : null;
  const [hasImageError, setHasImageError] = useState(false);
  const badgeToneClassName = tone === "sell" ? "bg-blue-100 text-blue-700" : "bg-emerald-100 text-emerald-700";

  return (
    <div className="inline-flex h-10 items-center gap-1.5 rounded-full border border-slate-300 bg-white px-2.5">
      {tokenImageSrc && !hasImageError ? (
        <img
          src={tokenImageSrc}
          alt={normalizedSymbol}
          className="h-6 w-6 rounded-full"
          onError={() => setHasImageError(true)}
        />
      ) : (
        <span
          className={`inline-flex h-6 w-6 items-center justify-center rounded-full text-xs font-semibold leading-none ${badgeToneClassName}`}
        >
          {normalizedSymbol.charAt(0)}
        </span>
      )}
      <span className="inline-flex h-6 items-center text-sm font-semibold leading-none text-slate-800">{normalizedSymbol}</span>
    </div>
  );
};

export const SwapCard = ({
  expectedChainId,
  routerAddress,
  pairAddress,
  usdtAddress,
  nadAddress,
  lensStatus,
  pairHealth,
  refetchPairHealth
}: SwapCardProps) => {
  const { address, isConnected } = useAccount();
  const chainId = useChainId();
  const { switchChainAsync } = useSwitchChain();
  const { writeContractAsync } = useWriteContract();
  const publicClient = usePublicClient({ chainId: expectedChainId });

  const [direction, setDirection] = useState<SwapDirection>("quoteToBase");
  const [amountIn, setAmountIn] = useState("");
  const [actionMessage, setActionMessage] = useState<string | null>(null);
  const [claimMessage, setClaimMessage] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);

  const [isSwitching, setIsSwitching] = useState(false);
  const [isApproving, setIsApproving] = useState(false);
  const [isSwapping, setIsSwapping] = useState(false);
  const [isClaiming, setIsClaiming] = useState(false);

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
  const quoteSymbol = usdtSymbol;
  const baseSymbol = nadSymbol;
  const quoteDecimals = usdtDecimals;
  const baseDecimals = nadDecimals;

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
  const quoteBalance = isQuoteToBase ? balanceIn : balanceOut;
  const baseBalance = isQuoteToBase ? balanceOut : balanceIn;

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

  const quotedOut =
    parsedAmountIn !== null && Array.isArray(amountsOut) && amountsOut.length > 0 ? amountsOut[amountsOut.length - 1] : null;
  const amountOutMin = quotedOut !== null ? applySlippageBps(quotedOut, DEFAULT_SLIPPAGE_BPS) : null;
  const needsApproval = Boolean(parsedAmountIn && allowance < parsedAmountIn);
  const isAmountOverBalance = Boolean(isConnected && parsedAmountIn !== null && parsedAmountIn > balanceIn);
  const quotedOutLabel = isQuoteFetching ? "Fetching..." : formatAmount(quotedOut, outDecimals);
  const accumulatedQuoteTax = pairHealth?.dynamicData.accumulatedQuoteTax ?? null;
  const taxCollectorAddress = pairHealth?.staticData.taxCollector ?? null;
  const isTaxCollector = Boolean(
    address &&
      taxCollectorAddress &&
      normalizeAddress(address as AddressHex) === normalizeAddress(taxCollectorAddress as AddressHex)
  );
  const canClaimQuoteTax = Boolean(
    isConnected &&
      !wrongNetwork &&
      address &&
      isTaxCollector &&
      accumulatedQuoteTax !== null &&
      accumulatedQuoteTax > 0n
  );

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
    setClaimMessage(null);

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
    setClaimMessage(null);
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
    setClaimMessage(null);
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
      await Promise.all([
        refetchAllowance(),
        refetchBalanceIn(),
        refetchBalanceOut(),
        parsedAmountIn ? refetchQuote() : Promise.resolve(),
        refetchPairHealth ? refetchPairHealth() : Promise.resolve()
      ]);
      setActionMessage("Swap transaction confirmed.");
      setAmountIn("");
    } catch (error) {
      console.error(error);
      setActionError(normalizeError(error));
    } finally {
      setIsSwapping(false);
    }
  };

  const onClaimQuoteTax = async () => {
    if (!address) {
      return;
    }

    setActionError(null);
    setActionMessage(null);
    setClaimMessage(null);
    setIsClaiming(true);

    try {
      if (!publicClient) {
        throw new Error("Public client is not ready.");
      }

      const txHash = await writeContractAsync({
        address: pairAddress,
        abi: pairAbi,
        functionName: "claimQuoteTax",
        args: [address]
      });

      await publicClient.waitForTransactionReceipt({ hash: txHash });
      await Promise.all([
        refetchBalanceIn(),
        refetchBalanceOut(),
        parsedAmountIn ? refetchQuote() : Promise.resolve(),
        refetchPairHealth ? refetchPairHealth() : Promise.resolve()
      ]);
      setClaimMessage("Quote tax claim transaction confirmed.");
    } catch (error) {
      console.error(error);
      setActionError(normalizeError(error));
    } finally {
      setIsClaiming(false);
    }
  };

  return (
    <div className="grid items-start gap-4 xl:grid-cols-[minmax(20rem,0.95fr)_minmax(0,1.45fr)]">
      <aside className="grid gap-4">
        <section className="rounded-2xl border border-slate-200 bg-white/90 p-4 shadow-sm">
          <h3 className="text-sm font-semibold uppercase tracking-[0.12em] text-slate-600">Wallet Balance</h3>
          <div className="mt-3 grid grid-cols-[minmax(0,1fr)_auto] items-baseline gap-x-3 gap-y-2 text-sm">
            <span className="text-slate-500">{quoteSymbol} (Quote)</span>
            <span className="text-right font-semibold text-slate-900 tabular-nums">
              {formatAmount(quoteBalance, quoteDecimals)} {quoteSymbol}
            </span>
            <span className="text-slate-500">{baseSymbol} (Base)</span>
            <span className="text-right font-semibold text-slate-900 tabular-nums">
              {formatAmount(baseBalance, baseDecimals)} {baseSymbol}
            </span>
          </div>
        </section>

        <section className="rounded-2xl border border-slate-200 bg-white/90 p-4 shadow-sm">
          <div className="flex items-center justify-between gap-2">
            <h3 className="text-sm font-semibold uppercase tracking-[0.12em] text-slate-600">Fee & Tax Breakdown</h3>
            <FeeFormulaTooltip isQuoteToBase={isQuoteToBase} buyTaxBps={buyTaxBps} sellTaxBps={sellTaxBps} lpFeeBps={lpFeeBps} />
          </div>
          <div className="mt-3 grid grid-cols-[minmax(0,1fr)_auto] items-baseline gap-x-3 gap-y-1.5 text-sm">
            <span className="text-slate-500">LP Fee</span>
            <span className="text-right font-semibold text-slate-900 tabular-nums">
              {formatBps(feeBreakdown.lpFeeBps)} ({feeBreakdown.lpFeeBps} bps)
            </span>
            <span className="text-slate-500">Buy Tax</span>
            <span className="text-right font-semibold text-slate-900 tabular-nums">
              {formatBps(buyTaxBps)} ({buyTaxBps} bps)
            </span>
            <span className="text-slate-500">Sell Tax</span>
            <span className="text-right font-semibold text-slate-900 tabular-nums">
              {formatBps(sellTaxBps)} ({sellTaxBps} bps)
            </span>
            <span className="text-slate-500">Applied Tax ({isQuoteToBase ? "Buy" : "Sell"})</span>
            <span className="text-right font-semibold text-slate-900 tabular-nums">
              {formatBps(feeBreakdown.taxBps)} ({feeBreakdown.taxBps} bps)
            </span>
            <span className="text-slate-500">Input Amount</span>
            <span className="text-right font-semibold text-slate-900 tabular-nums">
              {formatAmount(feeBreakdown.inputAmount, inDecimals)} {inSymbol}
            </span>
            {isQuoteToBase ? (
              <>
                <span className="text-slate-500">Buy Tax Paid</span>
                <span className="text-right font-semibold text-slate-900 tabular-nums">
                  {formatAmount(feeBreakdown.taxAmountIn, inDecimals)} {inSymbol}
                </span>
                <span className="text-slate-500">Effective Input</span>
                <span className="text-right font-semibold text-slate-900 tabular-nums">
                  {formatAmount(feeBreakdown.effectiveSwapInput, inDecimals)} {inSymbol}
                </span>
                <span className="text-slate-500">LP Fee Paid</span>
                <span className="text-right font-semibold text-slate-900 tabular-nums">
                  {formatAmount(feeBreakdown.lpFeeAmount, inDecimals)} {inSymbol}
                </span>
                <span className="text-slate-500">Expected Receive</span>
                <span className="text-right font-semibold text-slate-900 tabular-nums">
                  {formatAmount(feeBreakdown.netOutput, outDecimals)} {outSymbol}
                </span>
              </>
            ) : (
              <>
                <span className="text-slate-500">LP Fee Paid</span>
                <span className="text-right font-semibold text-slate-900 tabular-nums">
                  {formatAmount(feeBreakdown.lpFeeAmount, inDecimals)} {inSymbol}
                </span>
                <span className="text-slate-500">Gross Output</span>
                <span className="text-right font-semibold text-slate-900 tabular-nums">
                  {formatAmount(feeBreakdown.grossOutput, outDecimals)} {outSymbol}
                </span>
                <span className="text-slate-500">Sell Tax Paid</span>
                <span className="text-right font-semibold text-slate-900 tabular-nums">
                  {formatAmount(feeBreakdown.taxAmountOut, outDecimals)} {outSymbol}
                </span>
                <span className="text-slate-500">Expected Receive</span>
                <span className="text-right font-semibold text-slate-900 tabular-nums">
                  {formatAmount(feeBreakdown.netOutput, outDecimals)} {outSymbol}
                </span>
              </>
            )}
          </div>
        </section>

        <section className="rounded-2xl border border-slate-200 bg-white/90 p-4 shadow-sm">
          <h3 className="text-sm font-semibold uppercase tracking-[0.12em] text-slate-600">Accumulated Quote Tax</h3>
          <div className="mt-3 grid grid-cols-[minmax(0,1fr)_auto] items-baseline gap-x-3 text-sm">
            <span className="text-slate-500">Total</span>
            <span className="text-right font-semibold text-slate-900 tabular-nums">
              {formatAmount(accumulatedQuoteTax, usdtDecimals)} {usdtSymbol}
            </span>
          </div>
          {claimMessage && (
            <p className="mt-3 rounded-lg bg-emerald-100 px-3 py-2 text-sm text-emerald-900">{claimMessage}</p>
          )}
          <div className={claimMessage ? "mt-2" : "mt-3"}>
            {wrongNetwork ? (
              <button
                type="button"
                onClick={() => void onSwitch()}
                disabled={isSwitching}
                className="w-full rounded-lg bg-cyan-700 px-3 py-2 text-sm font-semibold text-white disabled:opacity-60"
              >
                {isSwitching ? "Switching..." : `Switch to chain ${expectedChainId}`}
              </button>
            ) : (
              <button
                type="button"
                onClick={() => void onClaimQuoteTax()}
                disabled={!canClaimQuoteTax || isClaiming}
                className="w-full rounded-lg bg-cyan-700 px-3 py-2 text-sm font-semibold text-white disabled:opacity-60"
              >
                {isClaiming ? "Claiming..." : "Claim"}
              </button>
            )}
          </div>
        </section>
      </aside>

      <section className="min-w-0 rounded-2xl border border-slate-200 bg-white/90 p-4 shadow-sm">
        <p className="text-sm font-semibold uppercase tracking-[0.12em] text-slate-600">Swap</p>

        <div className="mt-3 rounded-[1.4rem] border border-slate-200 bg-slate-50 px-4 py-2.5">
          <div className="flex items-center justify-between gap-3">
            <p className="text-sm font-semibold uppercase tracking-[0.12em] text-slate-600">Sell</p>
            <TokenPill symbol={inSymbol} tone="sell" />
          </div>

          <label htmlFor="amount-in" className="sr-only">
            Sell amount ({inSymbol})
          </label>
          <input
            id="amount-in"
            value={amountIn}
            onChange={(event) => setAmountIn(event.target.value)}
            className={`mt-4 w-full bg-transparent text-2xl font-semibold outline-none placeholder:text-slate-400 md:text-3xl ${
              isAmountOverBalance ? "text-rose-500" : "text-slate-900"
            }`}
            placeholder="0"
            inputMode="decimal"
          />

          <div className="mt-2 flex items-center justify-end">
            <p className="text-sm text-slate-500">
              Balance {formatAmount(balanceIn, inDecimals)} {inSymbol}
            </p>
          </div>
          {isAmountOverBalance && <p className="mt-2 text-sm text-rose-600">Input amount exceeds wallet balance.</p>}
        </div>

        <div className="relative z-10 -my-3 flex justify-center">
          <button
            type="button"
            onClick={() => setDirection((current) => (current === "quoteToBase" ? "baseToQuote" : "quoteToBase"))}
            className="inline-flex h-8 w-8 items-center justify-center rounded-lg border border-slate-300 bg-white text-slate-700 shadow-sm hover:bg-slate-50"
            aria-label="Swap direction"
          >
            <HiOutlineArrowDown className="h-4 w-4" aria-hidden="true" />
          </button>
        </div>

        <div className="rounded-[1.4rem] border border-slate-200 bg-slate-100 px-4 pt-3 pb-2.5">
          <div className="flex items-center justify-between gap-3">
            <p className="text-sm font-semibold uppercase tracking-[0.12em] text-slate-600">Buy</p>
            <TokenPill symbol={outSymbol} tone="buy" />
          </div>

          <p className="mt-4 break-all text-2xl font-semibold text-slate-900 md:text-3xl">{quotedOutLabel}</p>

        </div>

        {lensBlocksTrade && (
          <p className="mt-4 rounded-lg bg-amber-100 px-3 py-2 text-sm text-amber-900">
            Lens status is not OK. Trade is temporarily blocked.
          </p>
        )}

        {parsedAmountIn !== null && quoteError && (
          <p className="mt-4 rounded-lg bg-rose-100 px-3 py-2 text-sm text-rose-900 whitespace-pre-wrap break-all">
            Quote error: {quoteError.message}
          </p>
        )}

        {allowanceError && (
          <p className="mt-4 rounded-lg bg-rose-100 px-3 py-2 text-sm text-rose-900 whitespace-pre-wrap break-all">
            Allowance read error: {allowanceError.message}
          </p>
        )}

        {actionError && (
          <p className="mt-4 rounded-lg bg-rose-100 px-3 py-2 text-sm text-rose-900 whitespace-pre-wrap break-all">{actionError}</p>
        )}

        {actionMessage && (
          <p className="mt-4 rounded-lg bg-emerald-100 px-3 py-2 text-sm text-emerald-900">
            {actionMessage}
          </p>
        )}

        <div className="mt-5">
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
            swapLabel={`Swap ${inSymbol} to ${outSymbol}`}
          />
        </div>
      </section>
    </div>
  );
};
