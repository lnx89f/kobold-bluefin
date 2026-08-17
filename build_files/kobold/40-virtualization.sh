#!/usr/bin/env bash
set -euo pipefail

# Common VMs are owned by GNOME Boxes and its per-user state. Do not force a
# global libvirt URI that would make Boxes share the Quarantine system daemon.

# Quarantine runs through qemu:///system. Force libvirt QEMU guests to remain
# SELinux confined; a domain explicitly requesting an unconfined label must fail.
qemu_conf=/etc/libvirt/qemu.conf
mkdir -p "$(dirname "$qemu_conf")"
touch "$qemu_conf"
# Remove a previous Kobold block if this script is re-run, then remove any
# active vendor values for the same keys. This prevents duplicate libvirt
# configuration from weakening or ambiguously overriding Quarantine policy.
sed -i '/^# BEGIN KOBOLD QUARANTINE$/,/^# END KOBOLD QUARANTINE$/d' "$qemu_conf"
sed -Ei '/^[[:space:]]*security_driver[[:space:]]*=/d; /^[[:space:]]*security_default_confined[[:space:]]*=/d; /^[[:space:]]*security_require_confined[[:space:]]*=/d' "$qemu_conf"
cat >>"$qemu_conf" <<'EOF'
# BEGIN KOBOLD QUARANTINE
security_driver = "selinux"
security_default_confined = 1
security_require_confined = 1
# END KOBOLD QUARANTINE
EOF

# Fedora uses modular libvirt daemons. Enable socket activation where available,
# without forcing a permanently resident monolithic daemon.
for unit in \
  virtqemud.socket virtnetworkd.socket virtstoraged.socket \
  virtsecretd.socket virtnodedevd.socket virtnwfilterd.socket; do
  if systemctl list-unit-files "$unit" --no-legend 2>/dev/null | grep -q "^$unit"; then
    systemctl enable "$unit" >/dev/null
  fi
done

# Hide the generic virt-manager launcher when possible; the Kobold launcher is
# explicit about its security role and always passes qemu:///system.
if [[ -f /usr/share/applications/virt-manager.desktop ]] && \
   ! grep -q '^NoDisplay=true$' /usr/share/applications/virt-manager.desktop; then
  sed -i '/^\[Desktop Entry\]$/a NoDisplay=true' /usr/share/applications/virt-manager.desktop
fi
