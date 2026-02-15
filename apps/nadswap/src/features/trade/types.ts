import type { AddressHex } from "@nadswap/contracts";

export type TradeFormState = {
  amountIn: string;
  slippageBps: number;
};

export type SwapExecutionParams = {
  amountIn: bigint;
  amountOutMin: bigint;
  deadline: bigint;
  path: readonly [AddressHex, AddressHex];
  recipient: AddressHex;
};
