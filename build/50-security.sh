#!/usr/bin/env bash
set -euo pipefail

# SELinux is a release invariant. Do not install custom local policy in v0.1.
if [[ -f /etc/selinux/config ]]; then
  sed -ri 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
fi

# A restrictive host zone is enough for v0.1; do not invent a parallel firewall
# framework. libvirt manages its own virtual-network rules/zones.
if command -v firewall-offline-cmd >/dev/null 2>&1; then
  firewall-offline-cmd --set-default-zone=drop
fi

# Validate project sysctl syntax only. Applying it inside the container build
# would alter/check the build host kernel, not the future booted system.
awk '
  /^[[:space:]]*($|#)/ { next }
  /^[[:space:]]*[A-Za-z0-9_.]+[[:space:]]*=[[:space:]]*-?[0-9]+[[:space:]]*$/ { next }
  { print "Invalid sysctl line: " $0 > "/dev/stderr"; bad=1 }
  END { exit bad ? 1 : 0 }
' /etc/sysctl.d/60-kobold-security.conf

# Reusable images must not contain host/user secrets.
! find /root /home /etc/NetworkManager/system-connections -xdev -type f \
  \( -name authorized_keys -o -name 'id_*' -o -name '*.nmconnection' -o -name auth.json \) \
  -print -quit 2>/dev/null | grep -q .
