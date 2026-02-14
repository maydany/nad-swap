#!/usr/bin/env python3
"""
NadSwap V2 Slither static-analysis gate.

Fails CI when Slither reports findings at or above the configured severity.
Default severity threshold is "medium".
"""

import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROTOCOL_DIR = ROOT / "protocol"
LOCAL_SLITHER = ROOT / ".venv-slither" / "bin" / "slither"
DEFAULT_FAIL_LEVEL = "medium"
ALLOWED_FAIL_LEVELS = {"pedantic", "low", "medium", "high"}
DEFAULT_FILTER_PATHS = "test|script|lib|node_modules|cache|out|upstream"
DEFAULT_EXCLUDE_DETECTORS = ""


def fail(msg):
    print(f"[FAIL] {msg}")
    sys.exit(1)


def main():
    if not PROTOCOL_DIR.exists():
        fail(f"Missing protocol dir: {PROTOCOL_DIR}")

    slither_bin = shutil.which("slither")
    if slither_bin is None and LOCAL_SLITHER.exists():
        slither_bin = str(LOCAL_SLITHER)
    if slither_bin is None:
        fail(
            "slither not found in PATH and local .venv-slither missing. "
            "Run ./install_all_deps.sh first."
        )

    fail_level = os.getenv("SLITHER_FAIL_LEVEL", DEFAULT_FAIL_LEVEL).strip().lower()
    if fail_level not in ALLOWED_FAIL_LEVELS:
        fail(
            f"Invalid SLITHER_FAIL_LEVEL={fail_level}. "
            f"Allowed: {', '.join(sorted(ALLOWED_FAIL_LEVELS))}"
        )

    filter_paths = os.getenv("SLITHER_FILTER_PATHS", DEFAULT_FILTER_PATHS).strip()
    exclude_detectors = os.getenv(
        "SLITHER_EXCLUDE_DETECTORS",
        DEFAULT_EXCLUDE_DETECTORS,
    ).strip()
    cmd = [
        slither_bin,
        ".",
        "--exclude-dependencies",
        f"--fail-{fail_level}",
    ]
    if filter_paths:
        cmd += ["--filter-paths", filter_paths]
    if exclude_detectors:
        cmd += ["--exclude", exclude_detectors]

    print("[INFO] Running Slither gate command:")
    print(f"[INFO] Using slither binary: {slither_bin}")
    print(f"[INFO] {' '.join(cmd)}")

    try:
        subprocess.check_call(cmd, cwd=PROTOCOL_DIR)
    except subprocess.CalledProcessError as exc:
        fail(f"Slither gate failed with exit code {exc.returncode} (level={fail_level}).")

    print(f"[PASS] Slither gate passed (fail level: {fail_level}).")


if __name__ == "__main__":
    main()
