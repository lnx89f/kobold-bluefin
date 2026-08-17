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

## v0.1 image/QCOW2 Definition of Done

A candidate passes the base image gate only if:

- the base lock contains a digest-pinned Bluefin Standard parent;
- the OCI build succeeds;
- static checks succeed;
- Kobold image invariants succeed;
- `bootc container lint --fatal-warnings` succeeds;
- a fresh QCOW2 boots;
- SELinux is Enforcing;
- GDM works;
- GNOME works;
- the Niri session exists and starts;
- the effective hostname is `kobold`;
- there are zero unexplained failed systemd units;
- Podman works rootless;
- rootful `podman.socket` is masked;
- Distrobox works;
- chezmoi works;
- the Bazaar and Firefox fresh-install policy works;
- unwanted Bluefin extensions and applications are absent as defined by the invariants;
- ModemManager is absent;
- Avahi is absent;
- CUPS is inactive;
- Tailscale is inactive;
- Input Remapper is inactive;
- recurring Brew update timers are masked;
- virt-manager is present;
- `qemu:///system` is reachable;
- the Quarantine SELinux confinement configuration is valid;
- `divination` completes without critical findings.

## Separate Quarantine runtime validation

This is not required to accept the base image, but is required before claiming that the Quarantine workflow has been fully exercised:

- create a disposable VM under `qemu:///system`;
- confirm the running QEMU guest has an SELinux/sVirt label;
- confirm risky integrations are absent or warned about by `divination`.

## Separate physical hardware validation

These checks are not required to accept QCOW2:

- Bluetooth starts off and is togglable;
- Wi-Fi;
- fingerprint;
- suspend/resume;
- audio;
- brightness;
- physical AMD GPU path;
- battery behavior;
- thermals;
- idle power.

## Separate performance comparison

Before claiming Kobold is measurably lighter, cooler or more efficient than Bluefin:

- compare unmodified Bluefin with Kobold;
- use the same T495;
- use the same power mode;
- use an equivalent session state;
- record idle RAM;
- record sustained idle CPU;
- record temperature after a fixed idle period;
- record battery discharge/power draw;
- record active services, timers and sockets.

Do not claim package removal alone improved performance.
