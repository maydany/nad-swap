import { parseAbi } from "viem";

export const factoryAbi = parseAbi([
  "function pairAdmin() view returns (address)",
  "function setTaxConfig(address pair, uint16 buyTaxBps, uint16 sellTaxBps, address taxCollector)"
]);
