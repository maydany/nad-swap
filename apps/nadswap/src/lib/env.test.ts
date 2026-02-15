import { describe, expect, it } from "vitest";

import { parseAppEnv } from "./env";

const valid = {
  VITE_FACTORY: "0x1111111111111111111111111111111111111111",
  VITE_ROUTER: "0x2222222222222222222222222222222222222222",
  VITE_LENS_ADDRESS: "0x3333333333333333333333333333333333333333",
  VITE_WETH: "0x4444444444444444444444444444444444444444",
  VITE_USDT: "0x5555555555555555555555555555555555555555",
  VITE_NAD: "0x6666666666666666666666666666666666666666",
  VITE_PAIR_USDT_NAD: "0x7777777777777777777777777777777777777777",
  VITE_CHAIN_ID: "31337",
  VITE_RPC_URL: "http://127.0.0.1:8545"
};

describe("parseAppEnv", () => {
  it("fails with missing keys", () => {
    const result = parseAppEnv({});

    expect(result.ok).toBe(false);
    if (!result.ok) {
      expect(result.missingKeys).toContain("VITE_FACTORY");
    }
  });

  it("parses valid input", () => {
    const result = parseAppEnv(valid);

    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.value.chainId).toBe(31337);
      expect(result.value.contracts.router).toBe(valid.VITE_ROUTER);
      expect(result.value.adminAddresses).toEqual([]);
    }
  });

  it("parses admin addresses from optional env", () => {
    const result = parseAppEnv({
      ...valid,
      VITE_ADMIN_ADDRESSES: "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa,0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
    });

    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.value.adminAddresses).toEqual([
        "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
      ]);
    }
  });

  it("fails for malformed admin addresses", () => {
    const result = parseAppEnv({
      ...valid,
      VITE_ADMIN_ADDRESSES: "not-an-address"
    });

    expect(result.ok).toBe(false);
    if (!result.ok) {
      expect(result.message).toContain("Invalid VITE_ADMIN_ADDRESSES");
    }
  });
});
