import { describe, expect, it } from "vitest";

import { getSwapFeeBreakdown } from "./feeBreakdown";

describe("getSwapFeeBreakdown", () => {
  it("computes buy-side tax and lp fee on effective input", () => {
    const breakdown = getSwapFeeBreakdown({
      direction: "quoteToBase",
      amountIn: 100_000n,
      quotedOut: 50_000n,
      reserveIn: 1_000_000n,
      reserveOut: 1_000_000n,
      buyTaxBps: 300,
      sellTaxBps: 500,
      lpFeeBps: 20
    });

    expect(breakdown.taxAmountIn).toBe(3_000n);
    expect(breakdown.effectiveSwapInput).toBe(97_000n);
    expect(breakdown.lpFeeAmount).toBe(194n);
    expect(breakdown.taxAmountOut).toBe(0n);
    expect(breakdown.netOutput).not.toBeNull();
  });

  it("computes sell-side output tax from gross output", () => {
    const breakdown = getSwapFeeBreakdown({
      direction: "baseToQuote",
      amountIn: 100_000n,
      quotedOut: 90_000n,
      reserveIn: null,
      reserveOut: null,
      buyTaxBps: 300,
      sellTaxBps: 500,
      lpFeeBps: 20
    });

    expect(breakdown.taxAmountIn).toBe(0n);
    expect(breakdown.lpFeeAmount).toBe(200n);
    expect(breakdown.grossOutput).toBe(94_737n);
    expect(breakdown.taxAmountOut).toBe(4_737n);
  });
});
