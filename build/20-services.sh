#!/usr/bin/env bash
set -euo pipefail

unit_exists() {
  systemctl list-unit-files "$1" --no-legend 2>/dev/null | grep -q "^$1"
}

disable_if_exists() {
  local u
  for u in "$@"; do
    if unit_exists "$u"; then
      systemctl disable "$u" >/dev/null 2>&1 || true
    fi
  done
}

mask_if_exists() {
  local u
  for u in "$@"; do
    if unit_exists "$u"; then
      systemctl mask "$u" >/dev/null
    fi
  done
}

enable_if_exists() {
  local u
  for u in "$@"; do
    if unit_exists "$u"; then
      systemctl enable "$u" >/dev/null
    fi
  done
}

# Host security baseline.
enable_if_exists firewalld.service
mask_if_exists podman.socket

# Available, but deliberately not resident/auto-activated by default.
disable_if_exists \
  cups.service cups.socket cups.path cups-browsed.service \
  input-remapper.service \
  tailscaled.service \
  containerd.service

# Homebrew remains for ujust compatibility; periodic background work does not.
# brew-setup.service is intentionally preserved.
mask_if_exists brew-update.timer brew-upgrade.timer

# Privacy/noise: do not periodically report rpm-ostree count-me from Kobold.
mask_if_exists rpm-ostree-countme.timer rpm-ostree-countme.service

# Preserve Bluefin update integration. Never mask uupd here.
if unit_exists uupd.timer; then
  systemctl unmask uupd.timer >/dev/null 2>&1 || true
  systemctl enable uupd.timer >/dev/null 2>&1 || true
fi
