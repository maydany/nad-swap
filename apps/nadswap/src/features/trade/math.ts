export const BPS_DENOMINATOR = 10_000n;

export const applySlippageBps = (amount: bigint, slippageBps: number): bigint => {
  if (amount < 0n) {
    throw new Error("amount must be non-negative");
  }
  if (slippageBps < 0 || slippageBps > Number(BPS_DENOMINATOR)) {
    throw new Error("slippageBps must be between 0 and 10000");
  }

  return (amount * BigInt(Number(BPS_DENOMINATOR) - slippageBps)) / BPS_DENOMINATOR;
};
