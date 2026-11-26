#!/usr/bin/env bash
# Reverses every install_*.sh in this repo — apt-installed networking/utils
# (telnet/ping/curl/nc/perl/python/vim/docker), Terraform, the Node.js
# toolkit (nvm/node/npm/npx/yarn/pnpm), Go, and Homebrew. Called on app uninstall
# (journal replay per the ADR's Decision 7 — this script IS the revert action
# for every commands:install journal entry from this app).
set -euo pipefail

# apt-get and removing symlinks from /usr/local/bin both need root — the
# container's default user (ubuntu) is non-root, so re-exec ourselves under
# sudo. -E keeps $HOME etc. pointed at ubuntu's, not root's.
if [ "$(id -u)" -ne 0 ]; then
  exec sudo -E bash "$0" "$@"
fi

export DEBIAN_FRONTEND=noninteractive
apt-get remove -y --purge telnet iputils-ping curl netcat-openbsd perl python-is-python3 python3 vim jq sqlite3 docker-ce-cli docker-compose-plugin || true
# Chromium/Playwright libs: only the browser-specific ones. libglib/libdbus/
# libx11/libxcb are base-system deps of far more than chrome — never removed.
apt-get remove -y --purge libnss3 libnspr4 libatk1.0-0t64 libatk-bridge2.0-0t64 libatspi2.0-0t64 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 libgbm1 libxkbcommon0 libasound2t64 || true
apt-get autoremove -y || true
apt-get update -qq || true

AW_BIN_DIR="${AW_BIN_DIR:-/usr/local/bin}"

# Terraform
rm -f "$AW_BIN_DIR/terraform"

# Go
rm -f "$AW_BIN_DIR"/{go,gofmt}
rm -rf "${AW_GO_ROOT:-$HOME/.go}"

# Node.js toolkit (nvm/node/npm/npx/corepack/yarn/pnpm)
rm -f "$AW_BIN_DIR"/{node,npm,npx,corepack,yarn,yarnpkg,pnpm,pnpx}
rm -rf "${NVM_DIR:-$HOME/.nvm}"
for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
  [ -f "$rc" ] && sed -i '/NVM_DIR/d' "$rc" || true
done

# Homebrew (Linuxbrew)
rm -f "$AW_BIN_DIR/brew"
rm -rf "${AW_HOMEBREW_DIR:-$HOME/.homebrew}"
