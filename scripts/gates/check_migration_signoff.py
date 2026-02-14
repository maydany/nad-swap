#!/usr/bin/env python3
"""Checks migration signoff table completeness (13 checklist rows)."""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PATH = ROOT / "docs" / "reports" / "NADSWAP_V2_MIGRATION_SIGNOFF.md"


def fail(msg):
    print(f"[FAIL] {msg}")
    sys.exit(1)


def main():
    if not PATH.exists():
        fail(f"Missing file: {PATH}")

    lines = PATH.read_text().splitlines()
    rows = []
    for line in lines:
        m = re.match(r"^\|\s*(\d+)\s*\|", line.strip())
        if m:
            rows.append(int(m.group(1)))

    expected = list(range(1, 14))
    if rows != expected:
        fail(f"Expected migration checklist rows {expected}, got {rows}")

    print("[PASS] Migration signoff gate passed (13 checklist items present).")


if __name__ == "__main__":
    main()
