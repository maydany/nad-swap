import type { LensStatus } from "./types";

const statusLabelMap: Record<LensStatus, string> = {
  0: "OK",
  1: "INVALID_PAIR",
  2: "DEGRADED"
};

export const toStatusLabel = (status: LensStatus | null): string => {
  if (status === null) {
    return "UNKNOWN";
  }
  return statusLabelMap[status];
};

export const statusBadgeClass = (status: LensStatus | null): string => {
  if (status === 1) {
    return "border-rose-300 bg-rose-100 text-rose-900";
  }
  if (status === 2) {
    return "border-amber-300 bg-amber-100 text-amber-900";
  }
  if (status === 0) {
    return "border-emerald-300 bg-emerald-100 text-emerald-900";
  }
  return "border-slate-300 bg-slate-100 text-slate-700";
};
