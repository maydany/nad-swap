import type { AddressHex } from "@nadswap/contracts";
import { useAccount } from "wagmi";

import { nadswapChain } from "../config/chains";
import { LensStatusPanel } from "../features/lens/LensStatusPanel";
import { useLensPairView } from "../features/lens/useLensPairView";
import { SwapCard } from "../features/trade/SwapCard";
import { WalletPanel } from "../features/wallet/WalletPanel";
import { appEnv, envErrorMessage } from "../lib/env";

export const SwapPage = () => {
  const { address } = useAccount();

  if (!appEnv) {
    return (
      <main className="mx-auto max-w-3xl p-6">
        <section className="rounded-2xl border border-rose-300 bg-rose-50 p-5 text-sm text-rose-900">
          <h1 className="text-lg font-semibold">NadSwap config error</h1>
          <p className="mt-2">{envErrorMessage}</p>
          <p className="mt-2">Run `pnpm env:sync:nadswap` after local deploy.</p>
        </section>
      </main>
    );
  }

  const lensState = useLensPairView({
    lensAddress: appEnv.contracts.lens,
    pairAddress: appEnv.contracts.pairs.usdtNad,
    userAddress: address as AddressHex | undefined
  });

  return (
    <main className="mx-auto flex min-h-screen w-full max-w-3xl flex-col gap-4 p-6">
      <header className="rounded-2xl border border-slate-300 bg-white/85 p-5 shadow-sm">
        <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">NadSwap Main dApp</p>
        <h1 className="mt-1 text-2xl font-semibold text-slate-900">USDT/NAD Trade Console</h1>
        <p className="mt-2 text-sm text-slate-600">
          Chain {nadswapChain.id} · Router {appEnv.router.slice(0, 10)}... · Lens {appEnv.lens.slice(0, 10)}...
        </p>
      </header>

      <WalletPanel targetChainId={appEnv.chainId} />

      <LensStatusPanel state={lensState} />

      <SwapCard
        expectedChainId={appEnv.chainId}
        routerAddress={appEnv.router}
        usdtAddress={appEnv.usdt}
        nadAddress={appEnv.nad}
        lensStatus={lensState.overallStatus}
      />
    </main>
  );
};
