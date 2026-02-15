import type { AddressHex } from "@nadswap/contracts";
import { useAccount } from "wagmi";

import { statusBadgeClass, toStatusLabel } from "../features/lens/status";
import { useLensPairView } from "../features/lens/useLensPairView";
import { SwapCard } from "../features/trade/SwapCard";
import { WalletPanel } from "../features/wallet/WalletPanel";
import { shortAddress } from "../lib/format";
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
      <section className="rounded-2xl border border-slate-300 bg-white/85 p-4 shadow-sm">
        <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">Pair Snapshot</p>
        <div className="mt-3 flex flex-wrap items-center justify-between gap-3">
          <p className="text-sm text-slate-700">
            USDT/NAD Pair: <span className="font-semibold text-slate-900">{shortAddress(appEnv.pairUsdtNad)}</span>
          </p>
          <span className={`rounded-full border px-3 py-1 text-xs font-semibold ${statusBadgeClass(lensState.overallStatus)}`}>
            Lens Overall: {toStatusLabel(lensState.overallStatus)}
          </span>
        </div>
      </section>

      <WalletPanel targetChainId={appEnv.chainId} />

      <SwapCard
        expectedChainId={appEnv.chainId}
        routerAddress={appEnv.router}
        usdtAddress={appEnv.usdt}
        nadAddress={appEnv.nad}
        lensStatus={lensState.overallStatus}
        pairHealth={lensState.viewModel}
      />
    </>
  );
};
