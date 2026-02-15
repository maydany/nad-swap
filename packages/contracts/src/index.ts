export { erc20Abi } from "./abis/erc20";
export { lensAbi } from "./abis/lens";
export { routerAbi } from "./abis/router";

export type AddressHex = `0x${string}`;

export type AppAddresses = {
  chainId: number;
  rpcUrl: string;
  factory: AddressHex;
  router: AddressHex;
  lens: AddressHex;
  weth: AddressHex;
  usdt: AddressHex;
  nad: AddressHex;
  pairUsdtNad: AddressHex;
};

export type AppContracts = {
  factory: AddressHex;
  router: AddressHex;
  lens: AddressHex;
  tokens: {
    weth: AddressHex;
    usdt: AddressHex;
    nad: AddressHex;
  };
  pairs: {
    usdtNad: AddressHex;
  };
};

export const toAppContracts = (addresses: AppAddresses): AppContracts => ({
  factory: addresses.factory,
  router: addresses.router,
  lens: addresses.lens,
  tokens: {
    weth: addresses.weth,
    usdt: addresses.usdt,
    nad: addresses.nad
  },
  pairs: {
    usdtNad: addresses.pairUsdtNad
  }
});
