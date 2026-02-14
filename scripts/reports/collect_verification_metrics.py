#!/usr/bin/env python3
"""Collect reproducible docs verification metrics into JSON."""

import argparse
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROTOCOL_DIR = ROOT / "protocol"
DOCS_DIR = ROOT / "docs"
REPORTS_DIR = DOCS_DIR / "reports"
REQUIREMENTS_PATH = DOCS_DIR / "traceability" / "NADSWAP_V2_REQUIREMENTS.yaml"
SPEC_PATH = DOCS_DIR / "NADSWAP_V2_IMPL_SPEC_EN.md"
MIGRATION_PATH = REPORTS_DIR / "NADSWAP_V2_MIGRATION_SIGNOFF.md"
MATH_GATE_PATH = ROOT / "scripts" / "gates" / "check_math_consistency.py"
DEFAULT_OUTPUT = REPORTS_DIR / "NADSWAP_V2_VERIFICATION_METRICS.json"
DEFAULT_BASELINE = REPORTS_DIR / "NADSWAP_V2_VERIFICATION_BASELINE.json"

REQUIREMENT_RE = re.compile(r"^\s*-\s*id:\s*[A-Z]+-\d+\s*$")
SPEC_TEST_RE = re.compile(r"`(test_[A-Za-z0-9_]+)`")
SPEC_INVARIANT_RE = re.compile(r"`(invariant_[A-Za-z0-9_]+)`")
MIGRATION_ROW_RE = re.compile(r"^\|\s*(\d+)\s*\|")
TEST_COUNT_RE = re.compile(r"(\d+) total tests\)")
MATH_TOTAL_RE = re.compile(r"Results:\s*(\d+)\s*tests,\s*(\d+)\s*passed,\s*(\d+)\s*failed")


METRIC_KEYS = [
    "non_fork_all",
    "non_fork_strict",
    "fork_suite_total",
    "requirements_count",
    "spec_test_count",
    "spec_invariant_count",
    "math_consistency_total",
    "migration_items_total",
]


def fail(msg: str) -> None:
    print(f"[FAIL] {msg}")
    sys.exit(1)


def set_metric(payload, key, status, value=None, detail="", source=""):
    payload[key] = value
    payload["status"][key] = status
    payload["details"][key] = {
        "detail": detail,
        "source": source,
    }


def run_command(cmd, cwd=None, env=None):
    proc = subprocess.run(cmd, cwd=cwd, env=env, text=True, capture_output=True)
    out = proc.stdout + ("\n" + proc.stderr if proc.stderr else "")
    return proc.returncode, out


def load_baseline(path: Path):
    if not path.exists():
        return {}
    try:
        data = json.loads(path.read_text())
    except json.JSONDecodeError as exc:
        fail(f"invalid baseline JSON ({path}): {exc}")

    out = {}
    for key, value in data.items():
        if isinstance(value, int):
            out[key] = value
    return out


def with_baseline_if_error(key, status, value, detail, source, baseline):
    if status != "ERROR":
        return status, value, detail, source
    if key in baseline:
        fallback = baseline[key]
        msg = detail or "reference unavailable"
        msg = f"{msg} | fallback baseline={fallback}"
        return "BASELINE", fallback, msg, "baseline"
    return status, value, detail, source


def collect_forge_total(cmd):
    env = os.environ.copy()
    env.setdefault("FOUNDRY_OFFLINE", "true")
    code, out = run_command(cmd, cwd=PROTOCOL_DIR, env=env)
    if code != 0:
        tail = "\n".join(out.strip().splitlines()[-25:])
        return "ERROR", None, f"forge command failed (exit={code})\n{tail}", "command"

    totals = TEST_COUNT_RE.findall(out)
    if not totals:
        return "ERROR", None, "unable to parse forge total test count", "command"

    return "PASS", int(totals[-1]), "", "command"


def collect_fork_total_from_logs(log_dir: Path):
    parts = ["20-core.log", "30-periphery.log", "40-fuzz-lite.log"]
    totals = []
    missing = []

    for name in parts:
        p = log_dir / name
        if not p.exists():
            missing.append(name)
            continue
        text = p.read_text()
        matches = TEST_COUNT_RE.findall(text)
        if not matches:
            return "ERROR", None, f"no total test count in {name}", "fork-logs"
        totals.append(int(matches[-1]))

    if missing:
        return "ERROR", None, f"missing fork logs: {', '.join(missing)}", "fork-logs"

    return "PASS", sum(totals), "", "fork-logs"


def parse_requirements_count():
    if not REQUIREMENTS_PATH.exists():
        return "ERROR", None, f"missing requirements file: {REQUIREMENTS_PATH}", "parse"

    count = 0
    for line in REQUIREMENTS_PATH.read_text().splitlines():
        if REQUIREMENT_RE.match(line):
            count += 1
    if count == 0:
        return "ERROR", None, "no requirement IDs found", "parse"

    return "PASS", count, "", "parse"


def parse_spec_name_count(regex):
    if not SPEC_PATH.exists():
        return "ERROR", None, f"missing spec file: {SPEC_PATH}", "parse"

    found = []
    seen = set()
    for name in regex.findall(SPEC_PATH.read_text()):
        if name not in seen:
            seen.add(name)
            found.append(name)

    if not found:
        return "ERROR", None, "no spec names found for regex", "parse"

    return "PASS", len(found), "", "parse"


def collect_math_consistency_total():
    if not MATH_GATE_PATH.exists():
        return "ERROR", None, f"missing math gate script: {MATH_GATE_PATH}", "command"

    code, out = run_command([sys.executable, str(MATH_GATE_PATH)], cwd=ROOT)
    if code != 0:
        tail = "\n".join(out.strip().splitlines()[-30:])
        return "ERROR", None, f"math consistency gate failed (exit={code})\n{tail}", "command"

    m = MATH_TOTAL_RE.search(out)
    if not m:
        return "ERROR", None, "unable to parse math consistency totals", "command"

    total = int(m.group(1))
    passed = int(m.group(2))
    failed = int(m.group(3))
    if failed != 0 or passed != total:
        return "ERROR", total, "math consistency reported non-zero failures", "command"

    return "PASS", total, "", "command"


def parse_migration_items_count():
    if not MIGRATION_PATH.exists():
        return "ERROR", None, f"missing migration file: {MIGRATION_PATH}", "parse"

    rows = []
    for line in MIGRATION_PATH.read_text().splitlines():
        m = MIGRATION_ROW_RE.match(line.strip())
        if m:
            rows.append(int(m.group(1)))

    if not rows:
        return "ERROR", None, "no migration checklist rows found", "parse"

    return "PASS", len(rows), "", "parse"


def git_sha():
    code, out = run_command(["git", "rev-parse", "HEAD"], cwd=ROOT)
    if code != 0:
        return "UNKNOWN"
    return out.strip()


def main():
    parser = argparse.ArgumentParser(description="Collect docs verification metrics.")
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT), help="Output JSON path")
    parser.add_argument(
        "--baseline",
        default=str(DEFAULT_BASELINE),
        help="Baseline JSON path for fallback metric values",
    )
    parser.add_argument(
        "--fork-log-dir",
        default=str(ROOT / "fork-logs"),
        help="Directory containing fork runner logs",
    )
    parser.add_argument(
        "--skip-forge-tests",
        action="store_true",
        help="Do not run forge commands for non-fork totals",
    )
    parser.add_argument(
        "--skip-math-consistency",
        action="store_true",
        help="Do not run math consistency gate",
    )
    parser.add_argument(
        "--tag",
        default="",
        help="Optional provenance tag to record in output",
    )
    args = parser.parse_args()
    baseline_path = Path(args.baseline)
    if not baseline_path.is_absolute():
        baseline_path = ROOT / baseline_path
    baseline = load_baseline(baseline_path)

    baseline_ref = ""
    if baseline:
        try:
            baseline_ref = str(baseline_path.relative_to(ROOT))
        except ValueError:
            baseline_ref = str(baseline_path)

    payload = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "git_sha": git_sha(),
        "tag": args.tag,
        "baseline_source": baseline_ref,
        "non_fork_all": None,
        "non_fork_strict": None,
        "fork_suite_total": None,
        "requirements_count": None,
        "spec_test_count": None,
        "spec_invariant_count": None,
        "math_consistency_total": None,
        "migration_items_total": None,
        "status": {},
        "details": {},
    }

    if args.skip_forge_tests:
        set_metric(payload, "non_fork_all", "SKIP", None, "skipped by option", "command")
        set_metric(payload, "non_fork_strict", "SKIP", None, "skipped by option", "command")
    else:
        status, value, detail, source = collect_forge_total(["forge", "test", "--no-match-path", "test/fork/**"])
        status, value, detail, source = with_baseline_if_error(
            "non_fork_all", status, value, detail, source, baseline
        )
        set_metric(payload, "non_fork_all", status, value, detail, source)

        status, value, detail, source = collect_forge_total(
            ["forge", "test", "--no-match-path", "test/{fork,invariant}/**"]
        )
        status, value, detail, source = with_baseline_if_error(
            "non_fork_strict", status, value, detail, source, baseline
        )
        set_metric(payload, "non_fork_strict", status, value, detail, source)

    status, value, detail, source = collect_fork_total_from_logs(Path(args.fork_log_dir))
    status, value, detail, source = with_baseline_if_error(
        "fork_suite_total", status, value, detail, source, baseline
    )
    set_metric(payload, "fork_suite_total", status, value, detail, source)

    status, value, detail, source = parse_requirements_count()
    set_metric(payload, "requirements_count", status, value, detail, source)

    status, value, detail, source = parse_spec_name_count(SPEC_TEST_RE)
    set_metric(payload, "spec_test_count", status, value, detail, source)

    status, value, detail, source = parse_spec_name_count(SPEC_INVARIANT_RE)
    set_metric(payload, "spec_invariant_count", status, value, detail, source)

    if args.skip_math_consistency:
        set_metric(payload, "math_consistency_total", "SKIP", None, "skipped by option", "command")
    else:
        status, value, detail, source = collect_math_consistency_total()
        status, value, detail, source = with_baseline_if_error(
            "math_consistency_total", status, value, detail, source, baseline
        )
        set_metric(payload, "math_consistency_total", status, value, detail, source)

    status, value, detail, source = parse_migration_items_count()
    set_metric(payload, "migration_items_total", status, value, detail, source)

    out_path = Path(args.output)
    if not out_path.is_absolute():
        out_path = ROOT / out_path
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(payload, indent=2) + "\n")

    print(f"[PASS] wrote metrics: {out_path}")
    for key in METRIC_KEYS:
        st = payload["status"].get(key, "UNKNOWN")
        val = payload.get(key)
        print(f"[INFO] {key}: status={st} value={val}")


if __name__ == "__main__":
    main()
