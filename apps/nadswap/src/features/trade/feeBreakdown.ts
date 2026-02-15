const BPS_DENOMINATOR = 10_000n;

export type SwapDirection = "quoteToBase" | "baseToQuote";

type BreakdownParams = {
  direction: SwapDirection;
  amountIn: bigint | null;
  quotedOut: bigint | null;
  reserveIn: bigint | null;
  reserveOut: bigint | null;
  buyTaxBps: number;
  sellTaxBps: number;
  lpFeeBps: number;
};

export type SwapFeeBreakdown = {
  lpFeeBps: number;
  taxBps: number;
  inputAmount: bigint | null;
  effectiveSwapInput: bigint | null;
  lpFeeAmount: bigint | null;
  taxAmountIn: bigint | null;
  taxAmountOut: bigint | null;
  grossOutput: bigint | null;
  netOutput: bigint | null;
};

const ceilDiv = (a: bigint, b: bigint): bigint => (a + b - 1n) / b;

const amountOutWithFee = (amountIn: bigint, reserveIn: bigint, reserveOut: bigint, lpFeeBps: number): bigint => {
  if (amountIn <= 0n || reserveIn <= 0n || reserveOut <= 0n) {
    return 0n;
  }

  const feeFactor = BPS_DENOMINATOR - BigInt(lpFeeBps);
  const amountInWithFee = amountIn * feeFactor;
  const numerator = amountInWithFee * reserveOut;
  const denominator = reserveIn * BPS_DENOMINATOR + amountInWithFee;
  if (denominator <= 0n) {
    return 0n;
  }
  return numerator / denominator;
};

export const getSwapFeeBreakdown = ({
  direction,
  amountIn,
  quotedOut,
  reserveIn,
  reserveOut,
  buyTaxBps,
  sellTaxBps,
  lpFeeBps
}: BreakdownParams): SwapFeeBreakdown => {
  if (amountIn === null) {
    return {
      lpFeeBps,
      taxBps: direction === "quoteToBase" ? buyTaxBps : sellTaxBps,
      inputAmount: null,
      effectiveSwapInput: null,
      lpFeeAmount: null,
      taxAmountIn: null,
      taxAmountOut: null,
      grossOutput: null,
      netOutput: quotedOut
    };
  }

  if (direction === "quoteToBase") {
    const taxAmountIn = (amountIn * BigInt(buyTaxBps)) / BPS_DENOMINATOR;
    const effectiveSwapInput = amountIn - taxAmountIn;
    const lpFeeAmount = (effectiveSwapInput * BigInt(lpFeeBps)) / BPS_DENOMINATOR;
    const grossOutput =
      reserveIn !== null && reserveOut !== null
        ? amountOutWithFee(effectiveSwapInput, reserveIn, reserveOut, lpFeeBps)
        : quotedOut;

    return {
      lpFeeBps,
      taxBps: buyTaxBps,
      inputAmount: amountIn,
      effectiveSwapInput,
      lpFeeAmount,
      taxAmountIn,
      taxAmountOut: 0n,
      grossOutput,
      netOutput: quotedOut ?? grossOutput
    };
  }

  const lpFeeAmount = (amountIn * BigInt(lpFeeBps)) / BPS_DENOMINATOR;
  const grossOutputFromReserve =
    reserveIn !== null && reserveOut !== null ? amountOutWithFee(amountIn, reserveIn, reserveOut, lpFeeBps) : null;
  const grossOutputFromQuote =
    quotedOut !== null && sellTaxBps < Number(BPS_DENOMINATOR)
      ? ceilDiv(quotedOut * BPS_DENOMINATOR, BPS_DENOMINATOR - BigInt(sellTaxBps))
      : null;

  const grossOutput = grossOutputFromReserve ?? grossOutputFromQuote;
  const netOutput =
    quotedOut ??
    (grossOutput !== null ? (grossOutput * (BPS_DENOMINATOR - BigInt(sellTaxBps))) / BPS_DENOMINATOR : null);
  const taxAmountOut = grossOutput !== null && netOutput !== null ? grossOutput - netOutput : null;

  return {
    lpFeeBps,
    taxBps: sellTaxBps,
    inputAmount: amountIn,
    effectiveSwapInput: amountIn,
    lpFeeAmount,
    taxAmountIn: 0n,
    taxAmountOut,
    grossOutput,
    netOutput
  };
};
