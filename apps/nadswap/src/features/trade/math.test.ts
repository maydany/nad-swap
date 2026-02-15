import { describe, expect, it } from "vitest";

import { applySlippageBps } from "./math";

describe("applySlippageBps", () => {
  it("applies 0.5% slippage by floor", () => {
    expect(applySlippageBps(1_000_000n, 50)).toBe(995_000n);
  });

  it("returns original amount when slippage is zero", () => {
    expect(applySlippageBps(1234n, 0)).toBe(1234n);
  });
});
