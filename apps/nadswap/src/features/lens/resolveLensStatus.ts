import type { LensPairViewStatuses, LensStatus } from "./types";

const toLensStatus = (value: unknown): LensStatus => {
  const normalized = Number(value);
  if (normalized === 1) {
    return 1;
  }
  if (normalized === 2) {
    return 2;
  }
  return 0;
};

const readSegmentStatus = (segment: unknown): LensStatus => {
  if (Array.isArray(segment)) {
    return toLensStatus(segment[0]);
  }

  if (segment && typeof segment === "object" && "status" in segment) {
    return toLensStatus((segment as { status: unknown }).status);
  }

  return 0;
};

export const resolveLensStatus = (statuses: readonly number[]): LensStatus => {
  if (statuses.some((status) => status === 1)) {
    return 1;
  }
  if (statuses.some((status) => status === 2)) {
    return 2;
  }
  return 0;
};

export const mapPairViewStatuses = (pairViewData: unknown): LensPairViewStatuses | null => {
  let segments: [unknown, unknown, unknown] | null = null;

  if (Array.isArray(pairViewData) && pairViewData.length >= 3) {
    segments = [pairViewData[0], pairViewData[1], pairViewData[2]];
  }

  if (!segments && pairViewData && typeof pairViewData === "object") {
    const candidate = pairViewData as { s?: unknown; d?: unknown; u?: unknown };
    if (candidate.s !== undefined && candidate.d !== undefined && candidate.u !== undefined) {
      segments = [candidate.s, candidate.d, candidate.u];
    }
  }

  if (!segments) {
    return null;
  }

  const staticStatus = readSegmentStatus(segments[0]);
  const dynamicStatus = readSegmentStatus(segments[1]);
  const userStatus = readSegmentStatus(segments[2]);

  return {
    staticStatus,
    dynamicStatus,
    userStatus,
    overallStatus: resolveLensStatus([staticStatus, dynamicStatus, userStatus])
  };
};
