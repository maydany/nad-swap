#!/usr/bin/env python3
"""Monad fork preflight checks for NadSwap protocol fork suites.

Current fork tests deploy mock quote/base tokens after creating a Monad chain fork,
so only RPC/chain/block validation is required.
"""

import argparse
import json
import os
import sys
import urllib.error
import urllib.request


DEFAULT_RPC = "https://testnet-rpc.monad.xyz"
DEFAULT_CHAIN_ID = 10143


def fail(msg: str) -> None:
    print(f"[FAIL] {msg}")
    sys.exit(1)


def parse_int(name: str, default: int = 0) -> int:
    raw = os.getenv(name, str(default)).strip()
    try:
        return int(raw, 0)
    except ValueError:
        fail(f"{name} is not a valid integer: {raw}")
    return default


def rpc_call(url: str, method: str, params):
    payload = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(
        url,
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            body = json.loads(resp.read().decode())
    except urllib.error.URLError as exc:
        fail(f"RPC call failed ({method}): {exc}")
    if "error" in body:
        fail(f"RPC error ({method}): {body['error']}")
    return body["result"]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--write-env", dest="write_env", default="")
    args = parser.parse_args()

    rpc_url = os.getenv("MONAD_RPC_URL", DEFAULT_RPC).strip() or DEFAULT_RPC
    fork_block = parse_int("MONAD_FORK_BLOCK", 0)
    expected_chain_id = parse_int("MONAD_CHAIN_ID", DEFAULT_CHAIN_ID)
    fuzz_runs = parse_int("MONAD_FORK_FUZZ_RUNS", 64)

    chain_id = int(rpc_call(rpc_url, "eth_chainId", []), 16)
    latest_block = int(rpc_call(rpc_url, "eth_blockNumber", []), 16)

    print(f"[OK] RPC reachable: {rpc_url}")
    print(f"[OK] chainId={chain_id} latestBlock={latest_block}")

    if expected_chain_id > 0 and chain_id != expected_chain_id:
        fail(f"Unexpected chainId: expected={expected_chain_id}, got={chain_id}")

    if fork_block > 0 and fork_block > latest_block:
        fail(f"MONAD_FORK_BLOCK ({fork_block}) > latest block ({latest_block})")

    if fork_block > 0:
        resolved_fork_block = fork_block
        print(f"[OK] fork block fixed at {resolved_fork_block}")
    else:
        resolved_fork_block = latest_block
        print(f"[OK] fork block auto-pinned to latest block: {resolved_fork_block}")

    if args.write_env:
        with open(args.write_env, "w") as f:
            f.write("export MONAD_FORK_ENABLED=1\n")
            f.write(f"export MONAD_RPC_URL={rpc_url}\n")
            f.write(f"export MONAD_CHAIN_ID={expected_chain_id if expected_chain_id > 0 else chain_id}\n")
            f.write(f"export MONAD_FORK_BLOCK={resolved_fork_block}\n")
            f.write(f"export MONAD_FORK_FUZZ_RUNS={fuzz_runs}\n")
        print(f"[OK] wrote resolved env to {args.write_env}")

    print("[PASS] Monad fork preflight complete")


if __name__ == "__main__":
    main()
