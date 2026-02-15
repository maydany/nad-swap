import type { AddressHex } from "@nadswap/contracts";

import { mapPairViewStatuses } from "./resolveLensStatus";
import type { LensPairViewStatuses } from "./types";

type SegmentData = readonly unknown[] | Record<string, unknown>;

type LensStaticView = {
  pair: AddressHex | null;
  token0: AddressHex | null;
  token1: AddressHex | null;
  quoteToken: AddressHex | null;
  baseToken: AddressHex | null;
  isQuote0: boolean;
  supportsTax: boolean;
  buyTaxBps: number;
  sellTaxBps: number;
  taxCollector: AddressHex | null;
  lpFeeBps: number;
};

type LensDynamicView = {
  pair: AddressHex | null;
  reserve0: bigint;
  reserve1: bigint;
  blockTimestampLast: number;
  raw0: bigint;
  raw1: bigint;
  accumulatedQuoteTax: bigint;
  effective0: bigint;
  effective1: bigint;
  expectedRaw0: bigint;
  expectedRaw1: bigint;
  dust0: bigint;
  dust1: bigint;
  accountingOk: boolean;
};

type LensUserView = {
  pair: AddressHex | null;
  user: AddressHex | null;
  token0: AddressHex | null;
  token1: AddressHex | null;
  balance0: bigint;
  balance1: bigint;
  allowance0: bigint;
  allowance1: bigint;
  quoteBalance: bigint;
  baseBalance: bigint;
};

export type PairHealthViewModel = {
  statuses: LensPairViewStatuses;
  staticData: LensStaticView;
  dynamicData: LensDynamicView;
  userData: LensUserView;
};

const isRecord = (value: unknown): value is Record<string, unknown> => value !== null && typeof value === "object";

const toSegment = (value: unknown): SegmentData | null => {
  if (Array.isArray(value)) {
    return value;
  }
  if (isRecord(value)) {
    return value;
  }
  return null;
};

const readField = (segment: SegmentData, key: string, index: number): unknown => {
  if (Array.isArray(segment)) {
    return segment[index];
  }
  return (segment as Record<string, unknown>)[key];
};

const toAddress = (value: unknown): AddressHex | null => {
  if (typeof value !== "string") {
    return null;
  }
  const normalized = value.trim();
  if (!/^0x[a-fA-F0-9]{40}$/.test(normalized)) {
    return null;
  }
  return normalized as AddressHex;
};

const toBoolean = (value: unknown): boolean => {
  if (typeof value === "boolean") {
    return value;
  }
  if (typeof value === "number") {
    return value !== 0;
  }
  if (typeof value === "bigint") {
    return value !== 0n;
  }
  if (typeof value === "string") {
    const normalized = value.trim().toLowerCase();
    return normalized === "true" || normalized === "1";
  }
  return false;
};

const toNumber = (value: unknown): number => {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === "bigint") {
    return Number(value);
  }
  if (typeof value === "string") {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) {
      return parsed;
    }
  }
  return 0;
};

const toBigIntValue = (value: unknown): bigint => {
  if (typeof value === "bigint") {
    return value;
  }
  if (typeof value === "number" && Number.isFinite(value)) {
    return BigInt(Math.trunc(value));
  }
  if (typeof value === "string" && value.trim() !== "") {
    try {
      return BigInt(value);
    } catch {
      return 0n;
    }
  }
  return 0n;
};

export const mapPairHealthView = (pairViewData: unknown): PairHealthViewModel | null => {
  const statuses = mapPairViewStatuses(pairViewData);
  if (!statuses) {
    return null;
  }

  const segments = Array.isArray(pairViewData)
    ? pairViewData
    : isRecord(pairViewData)
      ? [pairViewData.s, pairViewData.d, pairViewData.u]
      : [];

  if (!Array.isArray(segments) || segments.length < 3) {
    return null;
  }

  const staticSegment = toSegment(segments[0]);
  const dynamicSegment = toSegment(segments[1]);
  const userSegment = toSegment(segments[2]);
  if (!staticSegment || !dynamicSegment || !userSegment) {
    return null;
  }

  return {
    statuses,
    staticData: {
      pair: toAddress(readField(staticSegment, "pair", 1)),
      token0: toAddress(readField(staticSegment, "token0", 2)),
      token1: toAddress(readField(staticSegment, "token1", 3)),
      quoteToken: toAddress(readField(staticSegment, "quoteToken", 4)),
      baseToken: toAddress(readField(staticSegment, "baseToken", 5)),
      isQuote0: toBoolean(readField(staticSegment, "isQuote0", 6)),
      supportsTax: toBoolean(readField(staticSegment, "supportsTax", 7)),
      buyTaxBps: toNumber(readField(staticSegment, "buyTaxBps", 8)),
      sellTaxBps: toNumber(readField(staticSegment, "sellTaxBps", 9)),
      taxCollector: toAddress(readField(staticSegment, "taxCollector", 10)),
      lpFeeBps: toNumber(readField(staticSegment, "lpFeeBps", 11))
    },
    dynamicData: {
      pair: toAddress(readField(dynamicSegment, "pair", 1)),
      reserve0: toBigIntValue(readField(dynamicSegment, "reserve0", 2)),
      reserve1: toBigIntValue(readField(dynamicSegment, "reserve1", 3)),
      blockTimestampLast: toNumber(readField(dynamicSegment, "blockTimestampLast", 4)),
      raw0: toBigIntValue(readField(dynamicSegment, "raw0", 5)),
      raw1: toBigIntValue(readField(dynamicSegment, "raw1", 6)),
      accumulatedQuoteTax: toBigIntValue(readField(dynamicSegment, "accumulatedQuoteTax", 7)),
      effective0: toBigIntValue(readField(dynamicSegment, "effective0", 8)),
      effective1: toBigIntValue(readField(dynamicSegment, "effective1", 9)),
      expectedRaw0: toBigIntValue(readField(dynamicSegment, "expectedRaw0", 10)),
      expectedRaw1: toBigIntValue(readField(dynamicSegment, "expectedRaw1", 11)),
      dust0: toBigIntValue(readField(dynamicSegment, "dust0", 12)),
      dust1: toBigIntValue(readField(dynamicSegment, "dust1", 13)),
      accountingOk: toBoolean(readField(dynamicSegment, "accountingOk", 14))
    },
    userData: {
      pair: toAddress(readField(userSegment, "pair", 1)),
      user: toAddress(readField(userSegment, "user", 2)),
      token0: toAddress(readField(userSegment, "token0", 3)),
      token1: toAddress(readField(userSegment, "token1", 4)),
      balance0: toBigIntValue(readField(userSegment, "balance0", 5)),
      balance1: toBigIntValue(readField(userSegment, "balance1", 6)),
      allowance0: toBigIntValue(readField(userSegment, "allowance0", 7)),
      allowance1: toBigIntValue(readField(userSegment, "allowance1", 8)),
      quoteBalance: toBigIntValue(readField(userSegment, "quoteBalance", 9)),
      baseBalance: toBigIntValue(readField(userSegment, "baseBalance", 10))
    }
  };
};
