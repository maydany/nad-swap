#!/usr/bin/env python3
"""Render GENERATED blocks in verification reports from metrics JSON."""

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
METRICS_DEFAULT = ROOT / "docs" / "reports" / "NADSWAP_V2_VERIFICATION_METRICS.json"
CONFORMANCE_REPORT = ROOT / "docs" / "reports" / "NADSWAP_V2_SPEC_CONFORMANCE_REPORT.md"
VERIFICATION_REPORT = ROOT / "docs" / "reports" / "NADSWAP_V2_VERIFICATION_REPORT.md"

START = "<!-- GENERATED:START -->"
END = "<!-- GENERATED:END -->"


def load_metrics(path: Path):
    if not path.exists():
        raise FileNotFoundError(f"missing metrics file: {path}")
    return json.loads(path.read_text())


def metric_line(metrics, key, label):
    status = metrics.get("status", {}).get(key, "ERROR")
    value = metrics.get(key)
    detail = metrics.get("details", {}).get(key, {}).get("detail", "")

    if status == "PASS" and isinstance(value, int):
        return f"- {label}: **PASS** (`{value}/{value}`)"
    if status == "BASELINE" and isinstance(value, int):
        line = f"- {label}: **BASELINE** (`{value}/{value}`)"
        if detail:
            line += f" — {detail}"
        return line
    if status == "SKIP":
        return f"- {label}: **SKIP** (`n/a`)"

    value_str = "n/a" if value is None else str(value)
    line = f"- {label}: **ERROR** (`{value_str}`)"
    if detail:
        line += f" — {detail}"
    return line


def build_generated_lines(metrics, metrics_path: Path):
    try:
        metrics_ref = metrics_path.relative_to(ROOT).as_posix()
    except ValueError:
        metrics_ref = metrics_path.as_posix()

    lines = [
        f"- Metrics source: `{metrics_ref}`",
        f"- Generated at: `{metrics.get('generated_at', 'UNKNOWN')}`",
        f"- Git SHA: `{metrics.get('git_sha', 'UNKNOWN')}`",
    ]

    baseline_source = metrics.get("baseline_source", "")
    if baseline_source:
        lines.append(f"- Baseline source: `{baseline_source}`")

    if metrics.get("tag"):
        lines.append(f"- Provenance tag: `{metrics['tag']}`")

    lines.extend(
        [
            metric_line(metrics, "non_fork_strict", "Foundry tests (non-fork strict)"),
            metric_line(metrics, "fork_suite_total", "Foundry tests (fork suites)"),
            metric_line(metrics, "non_fork_all", "Foundry tests (non-fork all)"),
            metric_line(metrics, "requirements_count", "Traceability requirements"),
            metric_line(metrics, "spec_test_count", "Spec Section 16 named tests"),
            metric_line(metrics, "spec_invariant_count", "Spec Section 16 named invariants"),
            metric_line(metrics, "math_consistency_total", "Math consistency vectors"),
            metric_line(metrics, "migration_items_total", "Migration checklist items"),
        ]
    )
    return lines


def replace_generated_block(text: str, lines):
    start_idx = text.find(START)
    end_idx = text.find(END)
    if start_idx == -1 or end_idx == -1 or end_idx < start_idx:
        raise ValueError("missing or invalid GENERATED markers")

    end_tail = end_idx + len(END)
    block = START + "\n" + "\n".join(lines) + "\n" + END
    return text[:start_idx] + block + text[end_tail:]


def render_file(path: Path, lines, check_only: bool):
    original = path.read_text()
    updated = replace_generated_block(original, lines)
    if check_only:
        return original == updated

    if original != updated:
        path.write_text(updated)
    return True


def main():
    parser = argparse.ArgumentParser(description="Render GENERATED blocks in reports")
    parser.add_argument("--metrics", default=str(METRICS_DEFAULT), help="Metrics JSON path")
    parser.add_argument("--check", action="store_true", help="Check-only mode (no writes)")
    args = parser.parse_args()

    metrics_path = Path(args.metrics)
    if not metrics_path.is_absolute():
        metrics_path = ROOT / metrics_path

    metrics = load_metrics(metrics_path)
    lines = build_generated_lines(metrics, metrics_path)

    targets = [CONFORMANCE_REPORT, VERIFICATION_REPORT]
    failures = []
    for target in targets:
        ok = render_file(target, lines, args.check)
        if args.check and not ok:
            failures.append(str(target))

    if failures:
        print("[FAIL] GENERATED blocks out of sync:")
        for f in failures:
            print(f"  - {f}")
        sys.exit(1)

    if args.check:
        print("[PASS] report GENERATED blocks are up to date")
    else:
        print("[PASS] report GENERATED blocks updated")


if __name__ == "__main__":
    main()
