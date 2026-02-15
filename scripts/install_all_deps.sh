#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHECK_ONLY=0
APT_UPDATED=0

if [[ "${1-}" == "--" ]]; then
  shift
fi

declare -a INSTALLED
declare -a SKIPPED
declare -a FAILED

usage() {
  cat <<'EOF'
Usage: ./scripts/install_all_deps.sh [options]

Installs all local prerequisites for NadSwap repo execution and tests.
If already installed, each dependency is skipped.

Options:
  --check-only   Verify only (no installation).
  -h, --help     Show this help.
EOF
}

log() {
  printf '[%s] %s\n' "$(date +'%H:%M:%S')" "$*"
}

record_installed() {
  INSTALLED+=("$1")
}

record_skipped() {
  SKIPPED+=("$1")
}

record_failed() {
  FAILED+=("$1")
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

run_or_skip() {
  if [[ "${CHECK_ONLY}" -eq 1 ]]; then
    log "CHECK-ONLY: $*"
    return 0
  fi
  "$@"
}

ensure_sudo() {
  if [[ "${EUID}" -eq 0 ]]; then
    return 0
  fi
  if ! has_cmd sudo; then
    return 1
  fi
  return 0
}

apt_install() {
  local pkg="$1"
  if ! ensure_sudo; then
    return 1
  fi
  if [[ "${APT_UPDATED}" -eq 0 ]]; then
    if [[ "${CHECK_ONLY}" -eq 1 ]]; then
      log "CHECK-ONLY: sudo apt-get update -y"
    else
      sudo apt-get update -y
    fi
    APT_UPDATED=1
  fi
  if [[ "${CHECK_ONLY}" -eq 1 ]]; then
    log "CHECK-ONLY: sudo apt-get install -y ${pkg}"
  else
    sudo apt-get install -y "${pkg}"
  fi
}

dnf_install() {
  local pkg="$1"
  if ! ensure_sudo; then
    return 1
  fi
  if [[ "${CHECK_ONLY}" -eq 1 ]]; then
    log "CHECK-ONLY: sudo dnf install -y ${pkg}"
  else
    sudo dnf install -y "${pkg}"
  fi
}

brew_install() {
  local pkg="$1"
  if [[ "${CHECK_ONLY}" -eq 1 ]]; then
    log "CHECK-ONLY: brew install ${pkg}"
    return 0
  fi
  brew install "${pkg}"
}

install_os_package() {
  local logical_name="$1"
  local brew_pkg="$2"
  local apt_pkg="$3"
  local dnf_pkg="$4"

  if has_cmd "${logical_name}"; then
    log "SKIP ${logical_name}: already installed"
    record_skipped "${logical_name}"
    return 0
  fi

  log "INSTALL ${logical_name}"
  if has_cmd brew; then
    if brew_install "${brew_pkg}"; then
      record_installed "${logical_name}"
      return 0
    fi
  fi

  if has_cmd apt-get; then
    if apt_install "${apt_pkg}"; then
      record_installed "${logical_name}"
      return 0
    fi
  fi

  if has_cmd dnf; then
    if dnf_install "${dnf_pkg}"; then
      record_installed "${logical_name}"
      return 0
    fi
  fi

  log "FAIL ${logical_name}: unsupported package manager or missing privileges"
  record_failed "${logical_name}"
  return 1
}

ensure_base_tool() {
  local cmd="$1"
  local brew_pkg="$2"
  local apt_pkg="$3"
  local dnf_pkg="$4"
  install_os_package "${cmd}" "${brew_pkg}" "${apt_pkg}" "${dnf_pkg}"
}

ensure_foundry() {
  export PATH="${HOME}/.foundry/bin:${PATH}"

  if has_cmd forge && has_cmd cast && has_cmd anvil; then
    log "SKIP foundry: forge/cast/anvil already installed"
    record_skipped "foundry"
    return 0
  fi

  log "INSTALL foundry (forge/cast/anvil)"
  if ! has_cmd curl; then
    log "FAIL foundry: curl is required"
    record_failed "foundry"
    return 1
  fi

  if [[ "${CHECK_ONLY}" -eq 1 ]]; then
    log "CHECK-ONLY: curl -L https://foundry.paradigm.xyz | bash"
    log "CHECK-ONLY: ${HOME}/.foundry/bin/foundryup"
    record_installed "foundry (planned)"
    return 0
  fi

  curl -L https://foundry.paradigm.xyz | bash
  export PATH="${HOME}/.foundry/bin:${PATH}"
  if ! has_cmd foundryup; then
    log "FAIL foundry: foundryup not found after install"
    record_failed "foundry"
    return 1
  fi

  foundryup
  if has_cmd forge && has_cmd cast && has_cmd anvil; then
    record_installed "foundry"
    return 0
  fi

  log "FAIL foundry: forge/cast/anvil unavailable after foundryup"
  record_failed "foundry"
  return 1
}

ensure_slither() {
  local venv_dir="${ROOT}/.venv-slither"
  local local_slither="${venv_dir}/bin/slither"

  if has_cmd slither; then
    log "SKIP slither: global slither already installed ($(command -v slither))"
    record_skipped "slither(global)"
    return 0
  fi

  if [[ -x "${local_slither}" ]]; then
    log "SKIP slither: local venv slither already installed (${local_slither})"
    record_skipped "slither(local)"
    return 0
  fi

  log "INSTALL slither in local venv (.venv-slither)"
  if [[ "${CHECK_ONLY}" -eq 1 ]]; then
    log "CHECK-ONLY: python3 -m venv ${venv_dir}"
    log "CHECK-ONLY: ${venv_dir}/bin/pip install --upgrade pip"
    log "CHECK-ONLY: ${venv_dir}/bin/pip install slither-analyzer"
    record_installed "slither(local planned)"
    return 0
  fi

  python3 -m venv "${venv_dir}"
  "${venv_dir}/bin/pip" install --upgrade pip
  "${venv_dir}/bin/pip" install slither-analyzer

  if [[ -x "${local_slither}" ]]; then
    record_installed "slither(local)"
    return 0
  fi

  log "FAIL slither: local venv install did not provide slither binary"
  record_failed "slither"
  return 1
}

print_summary() {
  echo
  echo "=============================="
  echo " NadSwap Dependency Summary"
  echo "=============================="
  echo "Installed: ${#INSTALLED[@]}"
  for item in "${INSTALLED[@]:-}"; do
    [[ -n "${item}" ]] && echo "  + ${item}"
  done
  echo "Skipped:   ${#SKIPPED[@]}"
  for item in "${SKIPPED[@]:-}"; do
    [[ -n "${item}" ]] && echo "  - ${item}"
  done
  echo "Failed:    ${#FAILED[@]}"
  for item in "${FAILED[@]:-}"; do
    [[ -n "${item}" ]] && echo "  x ${item}"
  done
  echo
}

print_success_art() {
  cat <<'EOF'
 _   _           _  ____  __        ___    ____  
| \ | | __ _  __| |/ ___| \ \      / / \  |  _ \ 
|  \| |/ _` |/ _` |\___ \  \ \ /\ / / _ \ | |_) |
| |\  | (_| | (_| | ___) |  \ V  V / ___ \|  __/ 
|_| \_|\__,_|\__,_||____/    \_/\_/_/   \_\_|    

  INSTALL COMPLETE - ALL REQUIRED DEPENDENCIES READY
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check-only)
      CHECK_ONLY=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[FAIL] Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

log "Repo root: ${ROOT}"
log "Mode: $([[ "${CHECK_ONLY}" -eq 1 ]] && echo "check-only" || echo "install")"

ensure_base_tool git git git git
ensure_base_tool curl curl curl curl
ensure_base_tool python3 python python3 python3
ensure_base_tool pip3 python python3-pip python3-pip
ensure_base_tool rg ripgrep ripgrep ripgrep

ensure_foundry
ensure_slither

print_summary

if [[ "${#FAILED[@]}" -gt 0 ]]; then
  exit 1
fi

print_success_art
echo
echo "Tip:"
echo "  - Local slither path: ${ROOT}/.venv-slither/bin/slither"
echo "  - Full gate run: ${ROOT}/scripts/runners/run_local_gates.sh"
