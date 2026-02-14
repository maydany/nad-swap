#!/usr/bin/env python3
"""
NadSwap V2 storage layout gate.

Compares V2 baseline (UpstreamUniswapV2Pair) with current UniswapV2Pair and enforces:
1) V2 original fields keep identical slot/offset/type.
2) NadSwap fields are append-only after V2 originals.
"""

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROTOCOL_DIR = ROOT / "protocol"
UPSTREAM_CORE_DIR = ROOT / "upstream" / "v2-core"
UPSTREAM_PERIPHERY_DIR = ROOT / "upstream" / "v2-periphery"
UPSTREAM_PROVENANCE_PATH = ROOT / "docs" / "layout" / "upstream-provenance.txt"

EXPECTED_CORE_SHA = "ee547b17853e71ed4e0101ccfd52e70d5acded58"
EXPECTED_PERIPHERY_SHA = "0335e8f7e1bd1e8d8329fd300aea2ef2f36dd19f"

V2_FIELDS = [
    "reserve0",
    "reserve1",
    "blockTimestampLast",
    "price0CumulativeLast",
    "price1CumulativeLast",
    "kLast",
    "unlocked",
]
NAD_FIELDS = [
    "quoteToken",
    "buyTaxBps",
    "sellTaxBps",
    "initialized",
    "feeCollector",
    "accumulatedQuoteFees",
]


def run(cmd, cwd):
    out = subprocess.check_output(cmd, cwd=cwd, text=True)
    return out


def to_map(layout):
    return {item["label"]: item for item in layout["storage"]}


def fail(msg):
    print(f"[FAIL] {msg}")
    sys.exit(1)


def get_git_head(path: Path):
    return run(["git", "rev-parse", "HEAD"], cwd=path).strip()


def parse_pinned_shas(path: Path):
    if not path.exists():
        fail(f"Missing provenance file: {path}")

    items = {}
    for line in path.read_text().splitlines():
        parts = line.split()
        if len(parts) == 2:
            items[parts[0].strip()] = parts[1].strip()
    return items


def main():
    if not UPSTREAM_CORE_DIR.exists():
        fail(f"Missing upstream core dir: {UPSTREAM_CORE_DIR}")
    if not UPSTREAM_PERIPHERY_DIR.exists():
        fail(f"Missing upstream periphery dir: {UPSTREAM_PERIPHERY_DIR}")

    pinned = parse_pinned_shas(UPSTREAM_PROVENANCE_PATH)
    if pinned.get("v2-core") != EXPECTED_CORE_SHA:
        fail(
            f"Provenance mismatch for v2-core. expected={EXPECTED_CORE_SHA} found={pinned.get('v2-core')}"
        )
    if pinned.get("v2-periphery") != EXPECTED_PERIPHERY_SHA:
        fail(
            f"Provenance mismatch for v2-periphery. expected={EXPECTED_PERIPHERY_SHA} found={pinned.get('v2-periphery')}"
        )

    actual_core = get_git_head(UPSTREAM_CORE_DIR)
    if actual_core != EXPECTED_CORE_SHA:
        fail(f"Upstream v2-core HEAD mismatch. expected={EXPECTED_CORE_SHA} actual={actual_core}")
    actual_periphery = get_git_head(UPSTREAM_PERIPHERY_DIR)
    if actual_periphery != EXPECTED_PERIPHERY_SHA:
        fail(
            f"Upstream v2-periphery HEAD mismatch. expected={EXPECTED_PERIPHERY_SHA} actual={actual_periphery}"
        )

    baseline_raw = run(
        ["forge", "inspect", "contracts/UniswapV2Pair.sol:UniswapV2Pair", "storageLayout", "--json"],
        cwd=UPSTREAM_CORE_DIR,
    )
    baseline = json.loads(baseline_raw)

    current_raw = run(
        [
            "forge",
            "inspect",
            "src/core/NadSwapV2Pair.sol:UniswapV2Pair",
            "storageLayout",
            "--json",
        ]
        ,
        cwd=PROTOCOL_DIR,
    )
    current = json.loads(current_raw)

    base_map = to_map(baseline)
    cur_map = to_map(current)

    for field in V2_FIELDS:
        if field not in base_map:
            fail(f"Baseline missing field: {field}")
        if field not in cur_map:
            fail(f"Current layout missing V2 field: {field}")

        b = base_map[field]
        c = cur_map[field]
        for k in ("slot", "offset", "type"):
            if str(b[k]) != str(c[k]):
                fail(
                    f"V2 field drift: {field}.{k} baseline={b[k]} current={c[k]}"
                )

    max_v2_slot = max(int(base_map[f]["slot"]) for f in V2_FIELDS)
    for field in NAD_FIELDS:
        if field not in cur_map:
            fail(f"Missing NadSwap append field: {field}")
        slot = int(cur_map[field]["slot"])
        if slot <= max_v2_slot:
            fail(f"NadSwap field not append-only: {field} at slot {slot} <= {max_v2_slot}")

    print("[PASS] Storage layout gate passed.")
    print("[PASS] Upstream commit pinned and V2 fields preserved with append-only NadSwap fields.")


if __name__ == "__main__":
    main()
