import { describe, expect, it } from "vitest";

import { mapPairViewStatuses, resolveLensStatus } from "./resolveLensStatus";

describe("resolveLensStatus", () => {
  it("prioritizes INVALID_PAIR over DEGRADED", () => {
    expect(resolveLensStatus([0, 2, 1])).toBe(1);
  });

  it("returns DEGRADED when any status is 2 and none are 1", () => {
    expect(resolveLensStatus([0, 2, 0])).toBe(2);
  });

  it("maps getPairView tuple-like data", () => {
    const mapped = mapPairViewStatuses([{ status: 0 }, { status: 2 }, { status: 0 }]);
    expect(mapped).not.toBeNull();
    expect(mapped?.overallStatus).toBe(2);
  });
});
