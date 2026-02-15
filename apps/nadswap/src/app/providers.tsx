import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import type { PropsWithChildren } from "react";
import { WagmiProvider, createConfig, http } from "wagmi";
import { injected } from "wagmi/connectors";

import { nadswapChain, nadswapRpcUrl } from "../config/chains";

const wagmiConfig = createConfig({
  chains: [nadswapChain],
  connectors: [injected()],
  transports: {
    [nadswapChain.id]: http(nadswapRpcUrl)
  }
});

const queryClient = new QueryClient();

export const AppProviders = ({ children }: PropsWithChildren) => {
  return (
    <WagmiProvider config={wagmiConfig}>
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    </WagmiProvider>
  );
};
