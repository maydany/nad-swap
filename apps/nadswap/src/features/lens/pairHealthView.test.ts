import { describe, expect, it } from "vitest";

import { mapPairHealthView } from "./pairHealthView";

describe("mapPairHealthView", () => {
  it("maps object-like getPairView output", () => {
    const mapped = mapPairHealthView({
      s: {
        status: 0,
        pair: "0x1000000000000000000000000000000000000001",
        token0: "0x1000000000000000000000000000000000000002",
        token1: "0x1000000000000000000000000000000000000003",
        quoteToken: "0x1000000000000000000000000000000000000002",
        baseToken: "0x1000000000000000000000000000000000000003",
        isQuote0: true,
        supportsTax: true,
        buyTaxBps: 300,
        sellTaxBps: 500,
        taxCollector: "0x1000000000000000000000000000000000000004",
        lpFeeBps: 20
      },
      d: {
        status: 0,
        pair: "0x1000000000000000000000000000000000000001",
        reserve0: 1000n,
        reserve1: 2000n,
        blockTimestampLast: 123456,
        raw0: 1020n,
        raw1: 2020n,
        accumulatedQuoteTax: 10n,
        effective0: 1010n,
        effective1: 2000n,
        expectedRaw0: 1010n,
        expectedRaw1: 2000n,
        dust0: 10n,
        dust1: 20n,
        accountingOk: true
      },
      u: {
        status: 0,
        pair: "0x1000000000000000000000000000000000000001",
        user: "0x1000000000000000000000000000000000000005",
        token0: "0x1000000000000000000000000000000000000002",
        token1: "0x1000000000000000000000000000000000000003",
        balance0: 11n,
        balance1: 22n,
        allowance0: 33n,
        allowance1: 44n,
        quoteBalance: 55n,
        baseBalance: 66n
      }
    });

    expect(mapped).not.toBeNull();
    expect(mapped?.statuses.overallStatus).toBe(0);
    expect(mapped?.staticData.buyTaxBps).toBe(300);
    expect(mapped?.dynamicData.accountingOk).toBe(true);
    expect(mapped?.userData.allowance1).toBe(44n);
  });

  it("returns null on malformed payload", () => {
    expect(mapPairHealthView({ s: { status: 0 } })).toBeNull();
  });
});
