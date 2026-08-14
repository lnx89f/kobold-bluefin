# Security model

## Strong invariants

- SELinux Enforcing.
- firewalld active with default host zone `drop`.
- no OpenSSH server in the base image.
- rootful `podman.socket` masked.
- Docker compatibility packages absent.
- Quarantine system-QEMU requires SELinux confinement.
- no custom DNS stack.
- no custom SELinux policy in v0.1.

## Sysctl delta

`/etc/sysctl.d/60-kobold-security.conf` intentionally contains only a small set of workstation controls:

- `kptr_restrict=2` and `dmesg_restrict=1`: reduce unprivileged kernel-information disclosure;
- `ptrace_scope=1`: blocks arbitrary same-user process attachment while retaining normal parent/child debugger workflows;
- protected hardlink/symlink/FIFO/regular-file controls: mitigate common unsafe shared-directory patterns;
- redirect/source-route rejection for IPv4/IPv6.

The previous Kobold values for `kexec_load_disabled`, `perf_event_paranoid`, custom VM/ZRAM tuning and similar high-friction controls are intentionally not carried into v0.1. They can be reintroduced only with a concrete threat and measured developer impact.

## Service policy

Removed: Samba/Winbind, Avahi/mDNS, ModemManager, iPhone integration and SSH server.

Installed but inactive: CUPS, Input Remapper, Tailscale and containerd daemon (if the Bluefin base retains it).

Homebrew setup remains for upstream tooling, but update/upgrade timers are masked. Bluefin's `uupd` update integration remains enabled.

## Quarantine scope

KVM provides the hardware virtualization boundary; libvirt system mode plus sVirt adds mandatory-access-control labeling around QEMU and its resources. `divination` additionally reports integration devices that weaken isolation.

This does not make arbitrary untrusted code risk-free. Kernel/QEMU/libvirt vulnerabilities and intentionally shared devices remain part of the threat model. Quarantine is designed to minimize host coupling, not to promise perfect containment.
