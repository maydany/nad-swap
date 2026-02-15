import type { AddressHex } from "@nadswap/contracts";
import { useAccount } from "wagmi";

import { useLensPairView } from "../features/lens/useLensPairView";
import { SwapCard } from "../features/trade/SwapCard";
import { appEnv } from "../lib/env";
import { ConfigErrorPanel } from "./ConfigErrorPanel";

export const SwapPage = () => {
  const { address } = useAccount();

  if (!appEnv) {
    return <ConfigErrorPanel />;
  }

  const lensState = useLensPairView({
    lensAddress: appEnv.contracts.lens,
    pairAddress: appEnv.contracts.pairs.usdtNad,
    userAddress: address as AddressHex | undefined
  });

  return (
    <>
      <SwapCard
        expectedChainId={appEnv.chainId}
        routerAddress={appEnv.router}
        pairAddress={appEnv.contracts.pairs.usdtNad}
        usdtAddress={appEnv.usdt}
        nadAddress={appEnv.nad}
        lensStatus={lensState.overallStatus}
        pairHealth={lensState.viewModel}
        refetchPairHealth={lensState.refetch}
      />
    </>
  );
};
