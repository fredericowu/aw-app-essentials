#!/usr/bin/env bash
# Installs sqlite3 into the workspace via apt. Idempotent — safe to re-run
# (on install, and on every reconcile pass after workspace recreation).
set -euo pipefail

if command -v sqlite3 >/dev/null 2>&1; then
  echo "sqlite3 already installed: $(sqlite3 --version)"
  exit 0
fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo "install_sqlite3.sh: no apt-get on this system — unsupported base image" >&2
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
apt-get install -y --no-install-recommends sqlite3

sqlite3 --version
