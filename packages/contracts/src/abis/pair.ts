import { parseAbi } from "viem";

export const pairAbi = parseAbi([
  "function claimQuoteTax(address to)",
  "function taxCollector() view returns (address)",
  "function buyTaxBps() view returns (uint16)",
  "function sellTaxBps() view returns (uint16)",
  "function quoteToken() view returns (address)",
  "function accumulatedQuoteTax() view returns (uint96)"
]);
