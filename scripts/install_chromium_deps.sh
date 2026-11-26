#!/usr/bin/env bash
# Installs the shared libraries Playwright's chrome-headless-shell needs, via
# apt (Ubuntu 24.04 t64 package names). Idempotent — safe to re-run (on
# install, and on every reconcile pass after workspace recreation).
set -euo pipefail

PKGS=(
  libglib2.0-0t64 libnss3 libnspr4 libatk1.0-0t64 libatk-bridge2.0-0t64
  libatspi2.0-0t64 libdbus-1-3 libx11-6 libxcb1 libxcomposite1 libxdamage1
  libxext6 libxfixes3 libxrandr2 libgbm1 libxkbcommon0 libasound2t64
)

PW_GLOB="${AW_PLAYWRIGHT_DIR:-/opt/aw-workspace/.aw-workspace/ms-playwright}/chromium_headless_shell-*/chrome-headless-shell-linux64/chrome-headless-shell"

# Idempotency: when the browser binary exists, ldd is authoritative (no
# "not found"). Otherwise fall back to dpkg -s on every package.
deps_ok() {
  local bin found=0
  # shellcheck disable=SC2086
  for bin in $PW_GLOB; do
    [ -f "$bin" ] || continue
    found=1
    local ldd_output
    if ! ldd_output=$(ldd "$bin" 2>&1) || [[ "$ldd_output" == *"not found"* ]]; then
      return 1
    fi
  done
  [ "$found" -eq 1 ] && return 0
  local p
  for p in "${PKGS[@]}"; do
    [ "$(dpkg-query -W -f='${Status}' "$p" 2>/dev/null)" = "install ok installed" ] || return 1
  done
}

if deps_ok; then
  echo "chromium deps already installed"
  exit 0
fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo "install_chromium_deps.sh: no apt-get on this system — unsupported base image" >&2
  exit 1
fi

# The container's default user (ubuntu) is non-root — apt-get needs root, so
# re-exec ourselves under sudo. -E keeps $HOME etc. pointed at ubuntu's, not
# root's.
if [ "$(id -u)" -ne 0 ]; then
  exec sudo -E bash "$0" "$@"
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y --no-install-recommends "${PKGS[@]}"

deps_ok
echo "chromium deps installed"
