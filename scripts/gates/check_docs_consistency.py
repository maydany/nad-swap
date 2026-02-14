#!/usr/bin/env python3
"""Strict docs consistency checks against metrics and source-of-truth parsers."""

import re
import subprocess
import sys
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
METRICS_PATH = ROOT / "docs" / "reports" / "NADSWAP_V2_VERIFICATION_METRICS.json"
REQUIREMENTS_PATH = ROOT / "docs" / "traceability" / "NADSWAP_V2_REQUIREMENTS.yaml"
SPEC_PATH = ROOT / "docs" / "NADSWAP_V2_IMPL_SPEC_EN.md"
SPEC_KR_PATH = ROOT / "docs" / "NADSWAP_V2_IMPL_SPEC_KR.md"
TRACE_MATRIX_PATH = ROOT / "docs" / "traceability" / "NADSWAP_V2_TRACE_MATRIX.md"
MIGRATION_PATH = ROOT / "docs" / "reports" / "NADSWAP_V2_MIGRATION_SIGNOFF.md"
FORK_DOC_PATH = ROOT / "docs" / "testing" / "FORK_TESTING_MONAD.md"
RENDER_SCRIPT = ROOT / "scripts" / "reports" / "render_verification_reports.py"

REQ_ID_RE = re.compile(r"^\s*-\s*id:\s*[A-Z]+-\d+\s*$")
SPEC_TEST_RE = re.compile(r"`(test_[A-Za-z0-9_]+)`")
SPEC_INVARIANT_RE = re.compile(r"`(invariant_[A-Za-z0-9_]+)`")
MIG_ROW_RE = re.compile(r"^\|\s*(\d+)\s*\|")


REQUIRED_METRIC_KEYS = [
    "non_fork_all",
    "non_fork_strict",
    "fork_suite_total",
    "requirements_count",
    "spec_test_count",
    "spec_invariant_count",
    "math_consistency_total",
    "migration_items_total",
]

TAX_TERMINOLOGY_DOCS = [SPEC_PATH, SPEC_KR_PATH, REQUIREMENTS_PATH, TRACE_MATRIX_PATH]
FORBIDDEN_TAX_PATTERNS = [
    (re.compile(r"\bcollector\b"), "standalone `collector`"),
    (re.compile(r"claimed quote fees"), "`claimed quote fees`"),
    (re.compile(r"ClaimFeesAdvanced"), "`ClaimFeesAdvanced`"),
]


def fail(msg):
    print(f"[FAIL] {msg}")
    sys.exit(1)


def load_metrics():
    if not METRICS_PATH.exists():
        fail(f"Missing metrics file: {METRICS_PATH}")
    data = json.loads(METRICS_PATH.read_text())
    for key in REQUIRED_METRIC_KEYS:
        if key not in data:
            fail(f"Missing metric key: {key}")
    if "status" not in data or "details" not in data:
        fail("Metrics file missing status/details maps")
    return data


def count_requirements():
    return sum(1 for line in REQUIREMENTS_PATH.read_text().splitlines() if REQ_ID_RE.match(line))


def count_unique_names(path: Path, regex):
    names = []
    seen = set()
    for name in regex.findall(path.read_text()):
        if name not in seen:
            seen.add(name)
            names.append(name)
    return len(names)


def migration_rows_count():
    rows = []
    for line in MIGRATION_PATH.read_text().splitlines():
        m = MIG_ROW_RE.match(line.strip())
        if m:
            rows.append(int(m.group(1)))
    return len(rows)


def count_test_functions(extra_globs):
    cmd = [
        "rg",
        "-n",
        r"function (test|testFuzz|testInvariant|invariant)_?[A-Za-z0-9_]*\(",
        "protocol/test",
        "-g",
        "*.sol",
    ] + extra_globs
    out = subprocess.check_output(cmd, cwd=ROOT, text=True)
    lines = [line for line in out.splitlines() if line.strip()]
    return len(lines)


def verify_metrics_against_source(metrics):
    expected = {
        "non_fork_all": count_test_functions(["-g", "!protocol/test/fork/**"]),
        "non_fork_strict": count_test_functions(["-g", "!protocol/test/fork/**", "-g", "!protocol/test/invariant/**"]),
        "requirements_count": count_requirements(),
        "spec_test_count": count_unique_names(SPEC_PATH, SPEC_TEST_RE),
        "spec_invariant_count": count_unique_names(SPEC_PATH, SPEC_INVARIANT_RE),
        "migration_items_total": migration_rows_count(),
    }

    for key, expected_value in expected.items():
        actual = metrics.get(key)
        status = metrics.get("status", {}).get(key)
        if actual != expected_value:
            fail(f"Metrics drift for {key}: expected={expected_value}, metrics={actual}")
        if status not in {"PASS", "BASELINE"}:
            fail(f"Metrics status must be PASS/BASELINE for {key}, got {status}")


def verify_claim_semantics_doc():
    text = SPEC_PATH.read_text()

    if "Effective reserve unchanged after claim" in text:
        fail("Spec still contains outdated claim invariant wording: 'unchanged after claim'")

    required_snippets = [
        "claim sets `vault=0` and re-syncs reserves to raw balances",
        "quote-side dust may be absorbed into reserves",
        "`test_claim_vaultReset_reserveSync`",
        "`test_sync_afterClaim`",
    ]
    for snippet in required_snippets:
        if snippet not in text:
            fail(f"Spec missing required claim semantics snippet: {snippet}")


def verify_fork_doc_modes():
    text = FORK_DOC_PATH.read_text()
    required = [
        "### Mode A — Runner (`scripts/runners/run_fork_tests.sh`)",
        "### Mode B — Direct `forge test`",
        "`MONAD_FORK_ENABLED` | Auto-exported by runner | Required (`1`)",
    ]
    for snippet in required:
        if snippet not in text:
            fail(f"Fork testing doc missing mode-split snippet: {snippet}")


def verify_generated_blocks_up_to_date():
    cmd = [sys.executable, str(RENDER_SCRIPT), "--check", "--metrics", str(METRICS_PATH)]
    proc = subprocess.run(cmd, cwd=ROOT, text=True, capture_output=True)
    if proc.returncode != 0:
        output = (proc.stdout + "\n" + proc.stderr).strip()
        fail(f"Report GENERATED blocks out of sync\n{output}")


def verify_tax_terminology_doc():
    for path in TAX_TERMINOLOGY_DOCS:
        text = path.read_text()
        for pattern, label in FORBIDDEN_TAX_PATTERNS:
            match = pattern.search(text)
            if not match:
                continue
            line = text.count("\n", 0, match.start()) + 1
            fail(f"Tax terminology drift in {path}: found {label} at line {line}")


def main():
    metrics = load_metrics()
    verify_metrics_against_source(metrics)
    verify_claim_semantics_doc()
    verify_tax_terminology_doc()
    verify_fork_doc_modes()
    verify_generated_blocks_up_to_date()
    print("[PASS] Docs consistency gate passed.")


if __name__ == "__main__":
    main()
