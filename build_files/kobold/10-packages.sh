#!/usr/bin/env bash
set -euo pipefail

remove_if_installed() {
  local installed=() p
  for p in "$@"; do
    rpm -q "$p" >/dev/null 2>&1 && installed+=("$p")
  done
  if ((${#installed[@]})); then
    dnf5 -y --setopt=clean_requirements_on_remove=False remove "${installed[@]}"
  fi
}

# Runtime/dependency foundations that must survive all cleanup transactions.
protected=(
  systemd NetworkManager gdm gnome-shell gnome-session gnome-control-center
  gnome-settings-daemon mutter nautilus gnome-keyring
  xdg-desktop-portal xdg-desktop-portal-gnome xdg-desktop-portal-gtk
  podman flatpak
)

# Old Kobold preferences, corrected to avoid Akatsuki's over-pruning of language,
# accessibility and hardware support. Remove leaf apps/services, not locale coverage.
remove_if_installed \
  gnome-tour gnome-connections gnome-contacts gnome-maps gnome-weather \
  gnome-calendar gnome-clocks gnome-characters gnome-logs gnome-font-viewer \
  gnome-extensions-app gnome-console gnome-tweaks \
  snapshot simple-scan cheese rhythmbox totem epiphany geary yelp papers evince \
  gnome-remote-desktop gnome-user-share rygel \
  malcontent-control malcontent-pam \
  nautilus-gsconnect \
  openssh-server \
  ModemManager avahi avahi-tools \
  ifuse usbmuxd libimobiledevice-utils \
  adcli krb5-workstation oddjob-mkhomedir sssd-nfs-idmap \
  toolbox trivy \
  samba samba-client samba-common-tools samba-dcerpc \
  samba-ldb-ldap-modules samba-winbind samba-winbind-clients samba-winbind-modules \
  samba-common-libs gvfs-smb

# Explicit host policy. Do not add SDK/toolchain stacks here.
dnf5 -y --setopt=install_weak_deps=False install \
  ca-certificates gnupg2 openssh-clients \
  git git-lfs gh curl jq rsync ripgrep fd-find bat fzf btop chezmoi \
  smartmontools nvme-cli ethtool lm_sensors pciutils usbutils powerstat powertop \
  flatpak \
  podman buildah skopeo distrobox podlet passt slirp4netns fuse-overlayfs shadow-utils-subid \
  lynis \
  ptyxis nautilus gnome-text-editor loupe gnome-calculator gnome-disk-utility \
  gnome-keyring xdg-desktop-portal xdg-desktop-portal-gnome xdg-desktop-portal-gtk \
  niri xwayland-satellite waybar fuzzel mako swaylock swayidle swaybg mate-polkit \
  brightnessctl playerctl wl-clipboard \
  gnome-boxes \
  qemu-kvm libvirt-client libvirt-daemon-kvm libvirt-daemon-config-network \
  virt-manager virt-install virt-viewer edk2-ovmf swtpm swtpm-tools dnsmasq \
  firewalld cups \
  fwupd fprintd udisks2 upower bluez

require_installed() {
  local missing=() p
  for p in "$@"; do
    if rpm -q "$p" >/dev/null 2>&1; then
      continue
    fi
    if [[ "$p" == bluefin-cli ]] \
      && [[ -d /usr/share/ublue-os/bluefin-cli ]] \
      && grep -Eq '^bluefin-cli:' /usr/share/ublue-os/just/system.just; then
      continue
    fi
    missing+=("$p")
  done
  if ((${#missing[@]})); then
    printf 'Required inherited payload missing after package transaction:' >&2
    printf ' %s' "${missing[@]}" >&2
    printf '\n' >&2
    return 1
  fi
}

# Critical base/desktop foundations must remain after pruning. Query each package
# independently so a failure identifies the actual package instead of propagating
# rpm's opaque aggregate query status.
require_installed "${protected[@]}"

# We intentionally rely on the Bluefin-supplied Tailscale/Input Remapper payload.
# Fail loudly if an upstream change removes either before policy is revisited.
require_installed tailscale input-remapper

# Fish, Zsh and the Bluefin CLI are mandatory inherited payload. Keep them out of
# the downstream install transaction and fail if the parent image drops them.
require_installed fish zsh bluefin-cli

# No partial inherited-package upgrade here. A new Bluefin digest updates the base.
dnf5 clean all

# Bluefin cleans mutable build state before its own lint. Our downstream RPM
# transaction runs later, so remove only the state that transaction recreated.
rm -rf \
  /run/dnf \
  /run/gluster \
  /run/selinux-policy \
  /var/lib/dnf/repos \
  /var/lib/rpm-state
rm -f \
  /var/lib/authselect/checksum \
  /var/lib/dnf/system-repo.lock
