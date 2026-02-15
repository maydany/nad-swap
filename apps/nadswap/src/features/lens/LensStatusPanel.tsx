import type { LensPairViewState } from "./useLensPairView";
import { statusBadgeClass, toStatusLabel } from "./status";

type LensStatusPanelProps = {
  state: LensPairViewState;
};

export const LensStatusPanel = ({ state }: LensStatusPanelProps) => {
  return (
    <section className="rounded-2xl border border-slate-300 bg-white/85 p-4 shadow-sm">
      <div className="flex items-center justify-between gap-3">
        <h2 className="text-sm font-semibold text-slate-900">Lens Pair Status</h2>
        <button
          type="button"
          onClick={() => void state.refetch()}
          disabled={!state.canQuery}
          className="rounded-lg border border-slate-300 px-3 py-1.5 text-xs font-medium text-slate-700 disabled:opacity-50"
        >
          {state.isFetching ? "Refreshing..." : "Refetch"}
        </button>
      </div>

      {!state.hasUserAddress && (
        <p className="mt-3 rounded-lg bg-slate-100 px-3 py-2 text-sm text-slate-700">
          Wallet is not connected. User branch values are shown as zero-address defaults.
        </p>
      )}

      {state.error && (
        <p className="mt-3 rounded-lg bg-rose-100 px-3 py-2 text-sm text-rose-900 whitespace-pre-wrap break-all">{state.error}</p>
      )}

      {state.canQuery && state.statuses && (
        <div className="mt-3 grid gap-2 text-sm sm:grid-cols-4">
          <div className={`rounded-lg border px-3 py-2 ${statusBadgeClass(state.statuses.staticStatus)}`}>
            s.status: {toStatusLabel(state.statuses.staticStatus)}
          </div>
          <div className={`rounded-lg border px-3 py-2 ${statusBadgeClass(state.statuses.dynamicStatus)}`}>
            d.status: {toStatusLabel(state.statuses.dynamicStatus)}
          </div>
          <div className={`rounded-lg border px-3 py-2 ${statusBadgeClass(state.statuses.userStatus)}`}>
            u.status: {toStatusLabel(state.statuses.userStatus)}
          </div>
          <div className={`rounded-lg border px-3 py-2 font-semibold ${statusBadgeClass(state.statuses.overallStatus)}`}>
            overall: {toStatusLabel(state.statuses.overallStatus)}
          </div>
        </div>
      )}

      {state.canQuery && state.statuses?.overallStatus === 2 && (
        <p className="mt-3 rounded-lg bg-amber-100 px-3 py-2 text-sm text-amber-900">
          Degraded mode detected. Trade actions are blocked until status returns to OK.
        </p>
      )}

      {state.canQuery && state.statuses?.overallStatus === 1 && (
        <p className="mt-3 rounded-lg bg-rose-100 px-3 py-2 text-sm text-rose-900 whitespace-pre-wrap break-all">
          Invalid pair reported by Lens. Trade actions are blocked.
        </p>
      )}

      {state.canQuery && state.isLoading && !state.statuses && (
        <p className="mt-3 text-sm text-slate-600">Loading Lens status...</p>
      )}
    </section>
  );
};
