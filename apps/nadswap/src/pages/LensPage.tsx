import type { AddressHex } from "@nadswap/contracts";
import { useState } from "react";
import { useAccount } from "wagmi";

import { statusBadgeClass, toStatusLabel } from "../features/lens/status";
import { useLensPairView } from "../features/lens/useLensPairView";
import { appEnv } from "../lib/env";
import { formatBps } from "../lib/format";
import { ConfigErrorPanel } from "./ConfigErrorPanel";

export const LensPage = () => {
  const { address } = useAccount();
  const [copiedAddressKey, setCopiedAddressKey] = useState<string | null>(null);
  const [copyError, setCopyError] = useState<string | null>(null);

  if (!appEnv) {
    return <ConfigErrorPanel />;
  }

  const lensState = useLensPairView({
    lensAddress: appEnv.contracts.lens,
    pairAddress: appEnv.contracts.pairs.usdtNad,
    userAddress: address as AddressHex | undefined
  });
  const view = lensState.viewModel;
  const statuses = lensState.statuses;
  const cardTitleClass = "text-sm font-semibold uppercase tracking-[0.12em] text-slate-600";
  const statusChipClassName = `rounded-lg border px-2.5 py-1 text-xs font-semibold ${statusBadgeClass(
    statuses?.overallStatus ?? null
  )}`;
  const onCopyAddress = async (key: string, value: string) => {
    if (typeof navigator === "undefined" || !navigator.clipboard?.writeText) {
      setCopyError("Clipboard API is not available in this browser.");
      return;
    }

    try {
      await navigator.clipboard.writeText(value);
      setCopyError(null);
      setCopiedAddressKey(key);
      window.setTimeout(() => {
        setCopiedAddressKey((current) => (current === key ? null : current));
      }, 1400);
    } catch (error) {
      console.error(error);
      setCopyError("Failed to copy address.");
    }
  };

  return (
    <>
      <section className="rounded-2xl border border-slate-300 bg-white/85 p-4 shadow-sm">
        <div className="flex items-center justify-between gap-3">
          <h2 className={cardTitleClass}>Lens Health</h2>
          <button
            type="button"
            onClick={() => void lensState.refetch()}
            disabled={!lensState.canQuery}
            className="rounded-lg border border-slate-300 px-3 py-1.5 text-xs font-medium text-slate-700 disabled:opacity-50"
          >
            {lensState.isFetching ? "Refreshing..." : "Refetch"}
          </button>
        </div>

        {lensState.isLoading && !statuses && <p className="mt-3 text-sm text-slate-600">Loading Lens status...</p>}

        {statuses && (
          <>
            <div className="mt-3">
              <span className={statusChipClassName}>Overall: {toStatusLabel(statuses.overallStatus)}</span>
            </div>
            <div className="mt-3 grid grid-cols-[minmax(0,1fr)_auto] items-baseline gap-x-3 gap-y-1.5 text-sm">
              <span className="text-slate-500">Static status (s.status)</span>
              <span className="text-right font-semibold text-slate-900">{toStatusLabel(statuses.staticStatus)}</span>
              <span className="text-slate-500">Dynamic status (d.status)</span>
              <span className="text-right font-semibold text-slate-900">{toStatusLabel(statuses.dynamicStatus)}</span>
              <span className="text-slate-500">User status (u.status)</span>
              <span className="text-right font-semibold text-slate-900">{toStatusLabel(statuses.userStatus)}</span>
              <span className="text-slate-500">Can query</span>
              <span className="text-right font-semibold text-slate-900">{lensState.canQuery ? "Yes" : "No"}</span>
            </div>
          </>
        )}

        {!lensState.hasUserAddress && (
          <p className="mt-3 rounded-lg bg-slate-100 px-3 py-2 text-sm text-slate-700">
            Wallet is not connected. User branch values use zero-address defaults.
          </p>
        )}

        {lensState.error && (
          <p className="mt-3 rounded-lg bg-rose-100 px-3 py-2 text-sm text-rose-900 whitespace-pre-wrap break-all">{lensState.error}</p>
        )}

        {statuses?.overallStatus === 2 && (
          <p className="mt-3 rounded-lg bg-amber-100 px-3 py-2 text-sm text-amber-900">
            Degraded mode detected. Trade actions should remain blocked until status returns to OK.
          </p>
        )}

        {statuses?.overallStatus === 1 && (
          <p className="mt-3 rounded-lg bg-rose-100 px-3 py-2 text-sm text-rose-900 whitespace-pre-wrap break-all">
            Invalid pair reported by Lens. Verify configured pair address before proceeding.
          </p>
        )}
      </section>

      <section className="rounded-2xl border border-slate-300 bg-white/85 p-4 shadow-sm">
        <h2 className={cardTitleClass}>Pair Static</h2>
        {view ? (
          <div className="mt-3 grid grid-cols-[minmax(0,1fr)_minmax(0,2fr)] items-start gap-x-3 gap-y-1.5 text-sm">
            <span className="text-slate-500">Pair</span>
            <span className="text-right font-semibold text-slate-900">
              <span className="inline-flex max-w-full items-start justify-end gap-2">
                <span className="break-all font-mono text-[12px] leading-5">{view.staticData.pair ?? "-"}</span>
                <button
                  type="button"
                  onClick={() => void onCopyAddress("pair", view.staticData.pair ?? "")}
                  disabled={!view.staticData.pair}
                  className="shrink-0 rounded border border-slate-300 px-1.5 py-0.5 text-[11px] font-semibold text-slate-700 hover:bg-slate-100 disabled:cursor-not-allowed disabled:opacity-50"
                >
                  {copiedAddressKey === "pair" ? "Copied" : "Copy"}
                </button>
              </span>
            </span>
            <span className="text-slate-500">Token0</span>
            <span className="text-right font-semibold text-slate-900">
              <span className="inline-flex max-w-full items-start justify-end gap-2">
                <span className="break-all font-mono text-[12px] leading-5">{view.staticData.token0 ?? "-"}</span>
                <button
                  type="button"
                  onClick={() => void onCopyAddress("token0", view.staticData.token0 ?? "")}
                  disabled={!view.staticData.token0}
                  className="shrink-0 rounded border border-slate-300 px-1.5 py-0.5 text-[11px] font-semibold text-slate-700 hover:bg-slate-100 disabled:cursor-not-allowed disabled:opacity-50"
                >
                  {copiedAddressKey === "token0" ? "Copied" : "Copy"}
                </button>
              </span>
            </span>
            <span className="text-slate-500">Token1</span>
            <span className="text-right font-semibold text-slate-900">
              <span className="inline-flex max-w-full items-start justify-end gap-2">
                <span className="break-all font-mono text-[12px] leading-5">{view.staticData.token1 ?? "-"}</span>
                <button
                  type="button"
                  onClick={() => void onCopyAddress("token1", view.staticData.token1 ?? "")}
                  disabled={!view.staticData.token1}
                  className="shrink-0 rounded border border-slate-300 px-1.5 py-0.5 text-[11px] font-semibold text-slate-700 hover:bg-slate-100 disabled:cursor-not-allowed disabled:opacity-50"
                >
                  {copiedAddressKey === "token1" ? "Copied" : "Copy"}
                </button>
              </span>
            </span>
            <span className="text-slate-500">Quote token</span>
            <span className="text-right font-semibold text-slate-900">
              <span className="inline-flex max-w-full items-start justify-end gap-2">
                <span className="break-all font-mono text-[12px] leading-5">{view.staticData.quoteToken ?? "-"}</span>
                <button
                  type="button"
                  onClick={() => void onCopyAddress("quoteToken", view.staticData.quoteToken ?? "")}
                  disabled={!view.staticData.quoteToken}
                  className="shrink-0 rounded border border-slate-300 px-1.5 py-0.5 text-[11px] font-semibold text-slate-700 hover:bg-slate-100 disabled:cursor-not-allowed disabled:opacity-50"
                >
                  {copiedAddressKey === "quoteToken" ? "Copied" : "Copy"}
                </button>
              </span>
            </span>
            <span className="text-slate-500">Base token</span>
            <span className="text-right font-semibold text-slate-900">
              <span className="inline-flex max-w-full items-start justify-end gap-2">
                <span className="break-all font-mono text-[12px] leading-5">{view.staticData.baseToken ?? "-"}</span>
                <button
                  type="button"
                  onClick={() => void onCopyAddress("baseToken", view.staticData.baseToken ?? "")}
                  disabled={!view.staticData.baseToken}
                  className="shrink-0 rounded border border-slate-300 px-1.5 py-0.5 text-[11px] font-semibold text-slate-700 hover:bg-slate-100 disabled:cursor-not-allowed disabled:opacity-50"
                >
                  {copiedAddressKey === "baseToken" ? "Copied" : "Copy"}
                </button>
              </span>
            </span>
            <span className="text-slate-500">Quote is token0</span>
            <span className="text-right font-semibold text-slate-900">{view.staticData.isQuote0 ? "Yes" : "No"}</span>
            <span className="text-slate-500">Quote supported</span>
            <span className="text-right font-semibold text-slate-900">{view.staticData.supportsTax ? "Yes" : "No"}</span>
            <span className="text-slate-500">Buy tax</span>
            <span className="text-right font-semibold text-slate-900">{formatBps(view.staticData.buyTaxBps)}</span>
            <span className="text-slate-500">Sell tax</span>
            <span className="text-right font-semibold text-slate-900">{formatBps(view.staticData.sellTaxBps)}</span>
            <span className="text-slate-500">LP fee</span>
            <span className="text-right font-semibold text-slate-900">{formatBps(view.staticData.lpFeeBps)}</span>
            <span className="text-slate-500">Tax collector</span>
            <span className="text-right font-semibold text-slate-900">
              <span className="inline-flex max-w-full items-start justify-end gap-2">
                <span className="break-all font-mono text-[12px] leading-5">{view.staticData.taxCollector ?? "-"}</span>
                <button
                  type="button"
                  onClick={() => void onCopyAddress("taxCollector", view.staticData.taxCollector ?? "")}
                  disabled={!view.staticData.taxCollector}
                  className="shrink-0 rounded border border-slate-300 px-1.5 py-0.5 text-[11px] font-semibold text-slate-700 hover:bg-slate-100 disabled:cursor-not-allowed disabled:opacity-50"
                >
                  {copiedAddressKey === "taxCollector" ? "Copied" : "Copy"}
                </button>
              </span>
            </span>
          </div>
        ) : (
          <p className="mt-3 text-sm text-slate-600">No static pair data loaded.</p>
        )}
        {copyError && <p className="mt-3 rounded-lg bg-rose-100 px-3 py-2 text-sm text-rose-900 whitespace-pre-wrap break-all">{copyError}</p>}
      </section>

      <section className="rounded-2xl border border-slate-300 bg-white/85 p-4 shadow-sm">
        <h2 className={cardTitleClass}>Pair Dynamic Snapshot</h2>
        {view ? (
          <div className="mt-3 grid grid-cols-[minmax(0,1fr)_auto] items-baseline gap-x-3 gap-y-1.5 text-sm">
            <span className="text-slate-500">Reserve0 / Reserve1</span>
            <span className="text-right font-semibold text-slate-900 tabular-nums">
              {view.dynamicData.reserve0.toString()} / {view.dynamicData.reserve1.toString()}
            </span>
            <span className="text-slate-500">Raw0 / Raw1</span>
            <span className="text-right font-semibold text-slate-900 tabular-nums">
              {view.dynamicData.raw0.toString()} / {view.dynamicData.raw1.toString()}
            </span>
            <span className="text-slate-500">Effective0 / Effective1</span>
            <span className="text-right font-semibold text-slate-900 tabular-nums">
              {view.dynamicData.effective0.toString()} / {view.dynamicData.effective1.toString()}
            </span>
            <span className="text-slate-500">ExpectedRaw0 / ExpectedRaw1</span>
            <span className="text-right font-semibold text-slate-900 tabular-nums">
              {view.dynamicData.expectedRaw0.toString()} / {view.dynamicData.expectedRaw1.toString()}
            </span>
            <span className="text-slate-500">Dust0 / Dust1</span>
            <span className="text-right font-semibold text-slate-900 tabular-nums">
              {view.dynamicData.dust0.toString()} / {view.dynamicData.dust1.toString()}
            </span>
            <span className="text-slate-500">Accumulated quote tax</span>
            <span className="text-right font-semibold text-slate-900 tabular-nums">
              {view.dynamicData.accumulatedQuoteTax.toString()}
            </span>
            <span className="text-slate-500">Block timestamp last</span>
            <span className="text-right font-semibold text-slate-900 tabular-nums">
              {view.dynamicData.blockTimestampLast.toString()}
            </span>
            <span className="text-slate-500">Accounting OK</span>
            <span className="text-right font-semibold text-slate-900">{view.dynamicData.accountingOk ? "Yes" : "No"}</span>
          </div>
        ) : (
          <p className="mt-3 text-sm text-slate-600">No dynamic snapshot loaded.</p>
        )}
      </section>

      <section className="rounded-2xl border border-slate-300 bg-white/85 p-4 shadow-sm">
        <h2 className={cardTitleClass}>Status Guide</h2>
        <div className="mt-3 grid gap-2 text-sm sm:grid-cols-3">
          <div className={`rounded-lg border px-3 py-2 ${statusBadgeClass(0)}`}>OK: Lens read path is healthy.</div>
          <div className={`rounded-lg border px-3 py-2 ${statusBadgeClass(1)}`}>INVALID_PAIR: pair or config is invalid.</div>
          <div className={`rounded-lg border px-3 py-2 ${statusBadgeClass(2)}`}>DEGRADED: partial read failure/guard state.</div>
        </div>
      </section>
    </>
  );
};
