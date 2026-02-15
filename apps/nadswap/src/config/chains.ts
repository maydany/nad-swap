import { defineChain } from "viem";

import { appEnv } from "../lib/env";

const chainId = appEnv?.chainId ?? 31337;
const rpcUrl = appEnv?.rpcUrl ?? "http://127.0.0.1:8545";

export const nadswapChain = defineChain({
  id: chainId,
  name: "NadSwap Local",
  nativeCurrency: {
    name: "Ether",
    symbol: "ETH",
    decimals: 18
  },
  rpcUrls: {
    default: {
      http: [rpcUrl]
    },
    public: {
      http: [rpcUrl]
    }
  }
});

export const nadswapRpcUrl = rpcUrl;
