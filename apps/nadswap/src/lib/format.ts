import { formatUnits } from "viem";

export const shortAddress = (value: string | null | undefined): string => {
  if (!value) {
    return "-";
  }
  return `${value.slice(0, 6)}...${value.slice(-4)}`;
};

export const formatTokenAmount = (value: bigint | null | undefined, decimals = 18): string => {
  if (value === null || value === undefined) {
    return "-";
  }
  return Number(formatUnits(value, decimals)).toLocaleString(undefined, {
    maximumFractionDigits: 6
  });
};

export const formatBps = (value: number): string => `${(value / 100).toFixed(2)}% (${value} bps)`;
