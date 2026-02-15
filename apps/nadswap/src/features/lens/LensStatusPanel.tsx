import type { LensPairViewState } from "./useLensPairView";

const statusLabel: Record<number, string> = {
  0: "OK",
  1: "INVALID_PAIR",
  2: "DEGRADED"
};

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
          disabled={!state.canQuery || state.isFetching}
          className="rounded-lg border border-slate-300 px-3 py-1.5 text-xs font-medium text-slate-700 disabled:opacity-50"
        >
          {state.isFetching ? "Refreshing..." : "Refetch"}
        </button>
      </div>

      {!state.canQuery && (
        <p className="mt-3 rounded-lg bg-slate-100 px-3 py-2 text-sm text-slate-700">
          Connect wallet to query `getPairView` user branch.
        </p>
      )}

      {state.error && (
        <p className="mt-3 rounded-lg bg-rose-100 px-3 py-2 text-sm text-rose-900">{state.error}</p>
      )}

      {state.canQuery && state.statuses && (
        <div className="mt-3 grid gap-2 text-sm sm:grid-cols-4">
          <div className="rounded-lg border border-slate-200 px-3 py-2">s.status: {statusLabel[state.statuses.staticStatus]}</div>
          <div className="rounded-lg border border-slate-200 px-3 py-2">d.status: {statusLabel[state.statuses.dynamicStatus]}</div>
          <div className="rounded-lg border border-slate-200 px-3 py-2">u.status: {statusLabel[state.statuses.userStatus]}</div>
          <div className="rounded-lg border border-slate-200 px-3 py-2 font-semibold">
            overall: {statusLabel[state.statuses.overallStatus]}
          </div>
        </div>
      )}

      {state.canQuery && state.statuses?.overallStatus === 2 && (
        <p className="mt-3 rounded-lg bg-amber-100 px-3 py-2 text-sm text-amber-900">
          Degraded mode detected. Trade actions are blocked until status returns to OK.
        </p>
      )}

      {state.canQuery && state.statuses?.overallStatus === 1 && (
        <p className="mt-3 rounded-lg bg-rose-100 px-3 py-2 text-sm text-rose-900">
          Invalid pair reported by Lens. Trade actions are blocked.
        </p>
      )}

      {state.canQuery && state.isLoading && !state.statuses && (
        <p className="mt-3 text-sm text-slate-600">Loading Lens status...</p>
      )}
    </section>
  );
};
