#!/usr/bin/env python3
"""Validate docs command-level symbol references against real Solidity contracts."""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DOCS_DIR = ROOT / "docs"
SRC_DIR = ROOT / "protocol" / "src"
EXCLUDED_DOCS = {"NADSWAP_V2_IMPL_SPEC.md"}

CONTRACT_RE = re.compile(r"\b(?:contract|interface|library)\s+([A-Za-z_][A-Za-z0-9_]*)\b")
FORGE_INSPECT_RE = re.compile(r"forge\s+inspect\s+([^\s`]+)\s+storageLayout")


def fail(msg):
    print(f"[FAIL] {msg}")
    sys.exit(1)


def collect_contract_names():
    names = set()
    for path in SRC_DIR.rglob("*.sol"):
        text = path.read_text()
        for m in CONTRACT_RE.finditer(text):
            names.add(m.group(1))
    if not names:
        fail("No contract/interface/library names found under protocol/src")
    return names


def resolve_path(path_part: str):
    if path_part.startswith("protocol/"):
        candidate = ROOT / path_part
    elif path_part.startswith("upstream/"):
        candidate = ROOT / path_part
    else:
        candidate = ROOT / "protocol" / path_part
    return candidate


def main():
    contract_names = collect_contract_names()
    problems = []

    for doc_path in DOCS_DIR.rglob("*.md"):
        if doc_path.name in EXCLUDED_DOCS:
            continue
        for lineno, line in enumerate(doc_path.read_text().splitlines(), start=1):
            for m in FORGE_INSPECT_RE.finditer(line):
                target = m.group(1)

                if target.startswith("Nad"):
                    problems.append(f"{doc_path}:{lineno}: forge inspect target uses alias `{target}`")
                    continue

                if ":" in target:
                    path_part, contract_name = target.split(":", 1)
                    if path_part.endswith(".sol"):
                        candidate = resolve_path(path_part)
                        if not candidate.exists():
                            problems.append(
                                f"{doc_path}:{lineno}: forge inspect path not found `{path_part}`"
                            )
                    if contract_name not in contract_names:
                        problems.append(
                            f"{doc_path}:{lineno}: unknown contract in forge inspect target `{contract_name}`"
                        )
                else:
                    contract_name = target
                    if contract_name not in contract_names:
                        problems.append(
                            f"{doc_path}:{lineno}: unknown forge inspect contract `{contract_name}`"
                        )

    if problems:
        print("[FAIL] Docs symbol refs check failed:")
        for p in problems:
            print(f"  - {p}")
        sys.exit(1)

    print("[PASS] Docs symbol refs check passed.")


if __name__ == "__main__":
    main()
