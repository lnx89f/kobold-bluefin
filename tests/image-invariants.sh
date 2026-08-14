#!/usr/bin/env bash
set -euo pipefail

required=(
  gdm gnome-shell gnome-session gnome-control-center NetworkManager systemd
  nautilus ptyxis gnome-text-editor loupe gnome-calculator gnome-disk-utility
  niri xwayland-satellite
  podman buildah skopeo distrobox
  chezmoi lynis
  gnome-boxes qemu-kvm libvirt-client libvirt-daemon-kvm virt-manager
  firewalld cups tailscale input-remapper
)
rpm -q "${required[@]}" >/dev/null

for forbidden in \
  docker docker-cli docker-compose docker-ce docker-ce-cli moby-engine \
  podman-docker podman-compose \
  toolbox trivy openssh-server \
  ModemManager avahi avahi-tools \
  ifuse usbmuxd gvfs-afc libimobiledevice-utils \
  samba samba-client samba-winbind gvfs-smb; do
  if rpm -q "$forbidden" >/dev/null 2>&1; then
    printf 'forbidden package present: %s\n' "$forbidden" >&2
    exit 1
  fi
done

# All Bluefin-composed GNOME extensions selected for removal must be physically absent.
for uuid in \
  appindicatorsupport@rgcjonas.gmail.com \
  bazaar-integration@kolunmi.github.io \
  caffeine@patapon.info \
  blur-my-shell@aunetx \
  custom-command-list@storageb.github.com \
  dash-to-dock@micxgx.gmail.com \
  gradia-integration@alexandervanhee.github.io \
  gsconnect@andyholmes.github.io \
  logomenu@aryan_k \
  search-light@icedman.github.com; do
  [[ ! -e "/usr/share/gnome-shell/extensions/$uuid" ]] || {
    printf 'Bluefin GNOME extension remains: %s\n' "$uuid" >&2
    exit 1
  }
done
[[ ! -e /usr/share/glib-2.0/schemas/zz0-bluefin-modifications.gschema.override ]]
grep -Fq 'enabled-extensions=[]' /usr/share/glib-2.0/schemas/zz99-kobold.gschema.override

# Immutable user config is deliberately absent.
[[ ! -e /etc/niri ]]
[[ ! -e /usr/share/kobold/niri ]]

# Branding is Kobold except Plymouth, which is intentionally inherited upstream.
test -s /usr/share/backgrounds/kobold/kobold-wallpaper.png
test -s /usr/share/kobold/branding/kobold-gdm-logo.png
grep -Fqx 'NAME="Kobold"' /usr/lib/os-release
grep -Fqx 'LOGO=kobold' /usr/lib/os-release
# Preserve technical base identity for compatibility.
grep -Eq '^ID=bluefin$|^ID="bluefin"$' /usr/lib/os-release
[[ ! -d /usr/share/backgrounds/bluefin ]]

# Flatpak policy: Bazaar upstream + Firefox local. Do not mask the preinstall engine.
[[ -s /usr/share/flatpak/preinstall.d/bazaar.preinstall ]]
[[ -s /etc/flatpak/preinstall.d/50-kobold.preinstall ]]
grep -Fq '[Flatpak Preinstall org.mozilla.firefox]' /etc/flatpak/preinstall.d/50-kobold.preinstall
if systemctl is-enabled --quiet flatpak-preinstall.service 2>/dev/null; then :; else
  state="$(systemctl is-enabled flatpak-preinstall.service 2>/dev/null || true)"
  [[ "$state" != masked ]] || { echo 'flatpak-preinstall.service must not be masked' >&2; exit 1; }
fi

# Service/runtime intent.
[[ "$(systemctl is-enabled podman.socket 2>/dev/null || true)" == masked ]]
[[ "$(systemctl is-enabled brew-update.timer 2>/dev/null || true)" == masked || \
   "$(systemctl is-enabled brew-update.timer 2>/dev/null || true)" == "" ]]
[[ "$(systemctl is-enabled brew-upgrade.timer 2>/dev/null || true)" == masked || \
   "$(systemctl is-enabled brew-upgrade.timer 2>/dev/null || true)" == "" ]]
for unit in tailscaled.service input-remapper.service cups.socket cups.service containerd.service; do
  state="$(systemctl is-enabled "$unit" 2>/dev/null || true)"
  case "$state" in
    enabled) printf '%s must not be enabled\n' "$unit" >&2; exit 1 ;;
  esac
done
[[ "$(systemctl is-enabled uupd.timer 2>/dev/null || true)" != masked ]]
[[ "$(systemctl is-enabled brew-setup.service 2>/dev/null || true)" != masked ]]

# Quarantine must require MAC confinement on system libvirt.
grep -Fq 'security_driver = "selinux"' /etc/libvirt/qemu.conf
grep -Fq 'security_default_confined = 1' /etc/libvirt/qemu.conf
grep -Fq 'security_require_confined = 1' /etc/libvirt/qemu.conf
[[ -s /usr/share/applications/kobold-quarantine.desktop ]]
grep -Fq 'qemu:///system' /usr/share/applications/kobold-quarantine.desktop

# No old custom DNS architecture.
[[ ! -e /etc/systemd/resolved.conf.d/60-kobold.conf ]]
[[ ! -e /etc/NetworkManager/conf.d/20-kobold-privacy.conf ]]

# SELinux desired boot configuration.
grep -Eq '^SELINUX=enforcing$' /etc/selinux/config

command -v divination >/dev/null
printf 'image invariants: OK\n'
