import type { AddressHex } from "@nadswap/contracts";
import { useAccount } from "wagmi";

import { LensStatusPanel } from "../features/lens/LensStatusPanel";
import { statusBadgeClass, toStatusLabel } from "../features/lens/status";
import { useLensPairView } from "../features/lens/useLensPairView";
import { appEnv } from "../lib/env";
import { shortAddress } from "../lib/format";
import { ConfigErrorPanel } from "./ConfigErrorPanel";

export const LensPage = () => {
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
      <LensStatusPanel state={lensState} />

      <section className="rounded-2xl border border-slate-300 bg-white/85 p-4 shadow-sm">
        <h2 className="text-sm font-semibold text-slate-900">Status Guide</h2>
        <div className="mt-3 grid gap-2 text-sm sm:grid-cols-3">
          <div className={`rounded-lg border px-3 py-2 ${statusBadgeClass(0)}`}>OK: trade path healthy.</div>
          <div className={`rounded-lg border px-3 py-2 ${statusBadgeClass(1)}`}>INVALID_PAIR: trading blocked.</div>
          <div className={`rounded-lg border px-3 py-2 ${statusBadgeClass(2)}`}>DEGRADED: temporary guard state.</div>
        </div>
      </section>

      <section className="rounded-2xl border border-slate-300 bg-white/85 p-4 shadow-sm">
        <h2 className="text-sm font-semibold text-slate-900">Raw Debug Snapshot</h2>
        {lensState.viewModel ? (
          <div className="mt-3 grid gap-2 text-sm text-slate-700 sm:grid-cols-2">
            <p>Overall: {toStatusLabel(lensState.viewModel.statuses.overallStatus)}</p>
            <p>Pair: {shortAddress(lensState.viewModel.staticData.pair)}</p>
            <p>Token0: {shortAddress(lensState.viewModel.staticData.token0)}</p>
            <p>Token1: {shortAddress(lensState.viewModel.staticData.token1)}</p>
            <p>raw0: {lensState.viewModel.dynamicData.raw0.toString()}</p>
            <p>raw1: {lensState.viewModel.dynamicData.raw1.toString()}</p>
            <p>effective0: {lensState.viewModel.dynamicData.effective0.toString()}</p>
            <p>effective1: {lensState.viewModel.dynamicData.effective1.toString()}</p>
            <p>expectedRaw0: {lensState.viewModel.dynamicData.expectedRaw0.toString()}</p>
            <p>expectedRaw1: {lensState.viewModel.dynamicData.expectedRaw1.toString()}</p>
            <p>dust0: {lensState.viewModel.dynamicData.dust0.toString()}</p>
            <p>dust1: {lensState.viewModel.dynamicData.dust1.toString()}</p>
            <p>blockTimestampLast: {lensState.viewModel.dynamicData.blockTimestampLast}</p>
            <p>accountingOk: {lensState.viewModel.dynamicData.accountingOk ? "true" : "false"}</p>
          </div>
        ) : (
          <p className="mt-3 text-sm text-slate-600">No debug data loaded.</p>
        )}
      </section>
    </>
  );
};
