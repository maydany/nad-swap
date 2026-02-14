#!/usr/bin/env python3
"""
Traceability completeness gate.

Checks:
1) Every requirement ID exists in the trace matrix.
2) Every requirement-row matrix entry has a verification command.
3) Test/invariant identifiers referenced by requirement rows exist in protocol/test (unless Tests=N/A).
4) Every spec Section 16 `test_*` name exists in protocol/test.
5) Every spec Section 16 `test_*`/`invariant_*` name is mapped in the trace matrix coverage table.
"""

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
REQ_PATH = ROOT / "docs" / "traceability" / "NADSWAP_V2_REQUIREMENTS.yaml"
MATRIX_PATH = ROOT / "docs" / "traceability" / "NADSWAP_V2_TRACE_MATRIX.md"
SPEC_PATH = ROOT / "docs" / "NADSWAP_V2_IMPL_SPEC_EN.md"

REQ_ID_RE = re.compile(r"^\s*-\s*id:\s*([A-Z]+-\d+)\s*$")
ROW_ID_RE = re.compile(r"^[A-Z]+-\d+$")
TEST_NAME_RE = re.compile(r"test[A-Za-z0-9_]+")
SPEC_TEST_RE = re.compile(r"`(test_[A-Za-z0-9_]+)`")
NAME_RE = re.compile(r"(?:test|invariant)[A-Za-z0-9_]+")
SPEC_INVARIANT_RE = re.compile(r"`(invariant_[A-Za-z0-9_]+)`")


def fail(msg):
    print(f"[FAIL] {msg}")
    sys.exit(1)


def parse_requirements(path: Path):
    ids = []
    for line in path.read_text().splitlines():
        m = REQ_ID_RE.match(line)
        if m:
            ids.append(m.group(1))
    return ids


def parse_matrix(path: Path):
    def norm(cell: str) -> str:
        c = cell.strip()
        if c.startswith("`") and c.endswith("`"):
            c = c[1:-1].strip()
        return c

    rows = {}
    for raw in path.read_text().splitlines():
        line = raw.strip()
        if not line.startswith("|"):
            continue
        cols = [c.strip() for c in line.strip("|").split("|")]
        if len(cols) < 6:
            continue
        row_id = norm(cols[0])
        if not ROW_ID_RE.match(row_id):
            continue
        rows[row_id] = {
            "spec": norm(cols[1]),
            "code": norm(cols[2]),
            "tests": norm(cols[3]),
            "cmd": norm(cols[4]),
            "status": norm(cols[5]),
        }
    return rows


def parse_spec_tests(path: Path):
    if not path.exists():
        fail(f"Missing spec file: {path}")

    tests = []
    seen = set()
    for name in SPEC_TEST_RE.findall(path.read_text()):
        if name not in seen:
            seen.add(name)
            tests.append(name)
    return tests


def parse_spec_invariants(path: Path):
    if not path.exists():
        fail(f"Missing spec file: {path}")

    names = []
    seen = set()
    for name in SPEC_INVARIANT_RE.findall(path.read_text()):
        if name not in seen:
            seen.add(name)
            names.append(name)
    return names


def parse_coverage_rows(path: Path):
    def norm(cell: str) -> str:
        c = cell.strip()
        if c.startswith("`") and c.endswith("`"):
            c = c[1:-1].strip()
        return c

    rows = {}
    for raw in path.read_text().splitlines():
        line = raw.strip()
        if not line.startswith("|"):
            continue
        cols = [c.strip() for c in line.strip("|").split("|")]
        if len(cols) < 4:
            continue
        test_name = norm(cols[0])
        if not re.match(r"^(test|invariant)_[A-Za-z0-9_]+$", test_name):
            continue
        rows[test_name] = {
            "code": norm(cols[1]),
            "cmd": norm(cols[2]),
            "status": norm(cols[3]),
        }
    return rows


def existing_tests():
    out = subprocess.check_output(["rg", "-n", "(test|invariant)[A-Za-z0-9_]+", "protocol/test"], cwd=ROOT, text=True)
    found = set(NAME_RE.findall(out))
    return found


def parse_code_paths(cell: str):
    if not cell or cell == "N/A":
        return []
    return [part.strip() for part in cell.split(",") if part.strip()]


def verify_matrix_code_paths(row_label: str, cell: str):
    code_paths = parse_code_paths(cell)
    if not code_paths:
        fail(f"Trace matrix code path missing for {row_label}")
    for code_path in code_paths:
        target = ROOT / code_path
        if not target.exists():
            fail(f"Trace matrix code path not found for {row_label}: {code_path}")


def main():
    if not REQ_PATH.exists() or not MATRIX_PATH.exists() or not SPEC_PATH.exists():
        fail("Traceability input files are missing")

    req_ids = parse_requirements(REQ_PATH)
    if not req_ids:
        fail("No requirement IDs found in requirements file")
    spec_tests = parse_spec_tests(SPEC_PATH)
    if not spec_tests:
        fail("No spec test names found in Section 16")
    spec_invariants = parse_spec_invariants(SPEC_PATH)
    if not spec_invariants:
        fail("No spec invariant names found in Section 16")
    spec_named = spec_tests + spec_invariants

    rows = parse_matrix(MATRIX_PATH)
    missing = [rid for rid in req_ids if rid not in rows]
    if missing:
        fail(f"Missing matrix rows for requirement IDs: {', '.join(missing)}")

    coverage_rows = parse_coverage_rows(MATRIX_PATH)
    test_set = existing_tests()

    for rid in req_ids:
        row = rows[rid]
        verify_matrix_code_paths(rid, row["code"])
        if not row["cmd"] or row["cmd"] == "N/A":
            fail(f"Missing verification command for {rid}")

        tests = row["tests"]
        if tests != "N/A":
            names = NAME_RE.findall(tests)
            if not names:
                fail(f"No test IDs referenced in matrix row {rid}")
            for name in names:
                if name not in test_set:
                    fail(f"Matrix references unknown test `{name}` in {rid}")

            # If a requirement row uses a test-level command, require at least one referenced
            # test name to be present in the command so mapping drift is caught early.
            cmd = row["cmd"]
            if "--match-contract" not in cmd and "--match-path" not in cmd:
                if not any(name in cmd for name in names):
                    fail(
                        f"Requirement row {rid} uses test-level verification command "
                        f"but none of its referenced tests appear in the command"
                    )

    spec_missing_in_code = [name for name in spec_named if name not in test_set]
    if spec_missing_in_code:
        fail(f"Spec checks missing in protocol/test: {', '.join(spec_missing_in_code)}")

    spec_missing_in_matrix = [name for name in spec_named if name not in coverage_rows]
    if spec_missing_in_matrix:
        fail(f"Spec checks missing in trace matrix coverage table: {', '.join(spec_missing_in_matrix)}")

    spec_set = set(spec_named)
    extra_matrix_tests = sorted([name for name in coverage_rows if name not in spec_set])
    if extra_matrix_tests:
        fail(f"Trace matrix contains non-spec check rows: {', '.join(extra_matrix_tests)}")

    for name in spec_named:
        row = coverage_rows[name]
        if not row["code"] or row["code"] == "N/A":
            fail(f"Coverage row missing code file for {name}")
        verify_matrix_code_paths(name, row["code"])
        if not row["cmd"] or row["cmd"] == "N/A":
            fail(f"Coverage row missing verification command for {name}")
        if name not in row["cmd"]:
            fail(f"Coverage command must include test name `{name}`")

    print(f"[PASS] Traceability gate passed for {len(req_ids)} requirements.")
    print(f"[PASS] Spec test coverage passed for {len(spec_tests)}/{len(spec_tests)} test names.")
    print(
        f"[PASS] Spec invariant coverage passed for "
        f"{len(spec_invariants)}/{len(spec_invariants)} invariant names."
    )


if __name__ == "__main__":
    main()
