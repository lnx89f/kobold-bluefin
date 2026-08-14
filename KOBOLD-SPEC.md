# Kobold vNext specification

## Purpose

Kobold is a curated personal workstation image, not a new Linux distribution. Bluefin Standard owns the operating-system integration; Kobold owns only the explicit downstream policy described here.

## Invariants

1. **Base** — `ghcr.io/ublue-os/bluefin:stable`, resolved to an immutable digest before build. Never rebuild or recopy `projectbluefin/common` on top of Bluefin.
2. **Upstream ownership** — kernel, firmware/hardware integration, bootc, TuneD/PPD, ZRAM, OOM behavior and normal Fedora/Bluefin networking remain upstream unless a measured defect requires a documented exception.
3. **Desktop** — GNOME/Wayland is primary. Niri is installed as a second session but the image ships no Niri user config.
4. **Mutable preferences** — `chezmoi` is installed for dotfiles such as Niri, Waybar, Fuzzel, shell, Git and terminal configuration. Those files do not belong in this image repository.
5. **GNOME extensions** — Bluefin-added system GNOME Shell extensions are removed. Kobold does not pre-bake personal extensions. User-installed extensions remain mutable.
6. **Apps** — native small system utilities may remain RPMs. Bazaar is inherited from Bluefin. Firefox is the only Kobold Flatpak preinstall in v0.1.
7. **Containers** — Podman is rootless-first. Rootful `podman.socket` is masked. Docker, Docker Compose, `podman-docker` and Podman Compose are not part of the image. Distrobox is preferred; Toolbx is removed when safe.
8. **Virtualization, Common** — GNOME Boxes is installed for normal distro testing, development and organizational isolation where clipboard/shares/USB convenience is acceptable.
9. **Virtualization, Quarantine** — virt-manager is provided through a dedicated Quarantine launcher connected to `qemu:///system`. SELinux/sVirt confinement is mandatory for system-QEMU guests. No Quarantine VM should intentionally use host filesystem sharing, USB/PCI passthrough or SPICE clipboard channels without an explicit threat-model exception.
10. **Security** — SELinux must remain Enforcing. No custom SELinux policy in v0.1. A small sysctl delta is permitted; it must not disable user namespaces, IPv6, Flatpak, rootless containers or normal virtualization.
11. **Host exposure** — firewalld remains active with a `drop` default zone. OpenSSH server is absent. Tailscale is installed but disabled until explicitly enabled.
12. **Unused runtime services** — Avahi/mDNS and ModemManager are removed. CUPS and Input Remapper packages may remain but their activation units are disabled. `containerd.service`, if present, is disabled rather than masked in v0.1.
13. **Samba** — Samba/Winbind and SMB GVFS backend are removed when the dependency transaction remains safe. The build must fail rather than sacrifice protected desktop foundations.
14. **Bluetooth** — BlueZ remains functional but the controller defaults off; the GNOME toggle must still enable it normally.
15. **Brew** — the Bluefin/Homebrew payload and `brew-setup.service` remain. `brew-update.timer` and `brew-upgrade.timer` are masked to eliminate periodic background activity.
16. **Updates** — preserve the Bluefin update architecture, including `uupd`, for v0.1. Do not invent a separate updater. Image publication cadence is a later repository/CI policy.
17. **Branding** — Kobold owns wallpaper, GDM logo, OS human-facing name, generic distributor/start-here icons and Fastfetch presentation. Bluefin Plymouth is intentionally inherited. Technical Bluefin/Fedora identifiers are preserved where changing them could affect compatibility.
18. **Diagnostics** — `divination` is read-only. It reports effective security and health, not whether arbitrary convenience applications are installed.
19. **Build discipline** — no floating base is accepted by the build wrapper. Run strict shell/static checks and `bootc container lint --fatal-warnings` before accepting an OCI.
20. **First milestone** — OCI and QCOW2 only. No custom ISO, Anaconda, Titanoboa, installer wrapper or bootc-switch conversion path in v0.1.

## First release Definition of Done

A candidate passes only if:

- base lock contains a digest-pinned Bluefin Standard reference;
- OCI builds without dependency-protection violations;
- `bootc container lint --fatal-warnings` passes;
- SELinux is Enforcing when booted;
- GDM, GNOME and Niri sessions start;
- networking/DNS remain functional without Kobold DNS overrides;
- Bluetooth starts off and remains togglable;
- Podman works rootless and rootful socket is not exposed;
- Distrobox works;
- Boxes creates/runs an ordinary VM;
- virt-manager Quarantine connects to `qemu:///system` and system VMs report SELinux security labels;
- no Bluefin-added GNOME extensions remain in the system extension directory;
- Samba, Avahi and ModemManager are absent;
- CUPS, Input Remapper, Tailscale and containerd daemon (if installed) are not enabled by default;
- Bazaar and Firefox are available as intended on a fresh first boot;
- `divination` completes without a critical finding;
- idle CPU/RAM/temperature/power are measured against unmodified Bluefin on the same hardware before claiming an optimization.
