import { parseAbi } from "viem";

export const lensAbi = parseAbi([
  "function getPair(address tokenA, address tokenB) view returns (address pair, bool isValidPair)",
  "function getPairView(address pair, address user) view returns ((uint8 status,address pair,address token0,address token1,address quoteToken,address baseToken,bool isQuote0,bool supportsTax,uint16 buyTaxBps,uint16 sellTaxBps,address taxCollector,uint16 lpFeeBps) s,(uint8 status,address pair,uint112 reserve0,uint112 reserve1,uint32 blockTimestampLast,uint256 raw0,uint256 raw1,uint96 accumulatedQuoteTax,uint256 effective0,uint256 effective1,uint256 expectedRaw0,uint256 expectedRaw1,uint256 dust0,uint256 dust1,bool accountingOk) d,(uint8 status,address pair,address user,address token0,address token1,uint256 balance0,uint256 balance1,uint256 allowance0,uint256 allowance1,uint256 quoteBalance,uint256 baseBalance) u)"
]);
