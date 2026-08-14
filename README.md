# Kobold

Kobold is a personal bootc workstation image built as a **small downstream layer on Bluefin Standard**. It is not an independent Linux distribution and deliberately does not rebuild Bluefin internals.

The project keeps Bluefin's Fedora/bootc kernel, hardware enablement, TuneD/PPD, ZRAM, update integration and `ujust`, then applies a narrow Kobold policy:

- GNOME remains primary, with Bluefin-added GNOME Shell extensions removed from the immutable image.
- Niri is installed **without user configuration**; dotfiles belong to `chezmoi`.
- Podman is rootless-first; Docker/Compose and `podman-docker` are absent.
- Distrobox is kept; Toolbx is removed when dependency-safe.
- GNOME Boxes is the friendly interface for ordinary/dev/test VMs.
- virt-manager opens `qemu:///system` for Quarantine workloads, with SELinux/sVirt required.
- Bazaar remains the Bluefin Flatpak; Firefox is the only Kobold Flatpak preinstall.
- Samba, iPhone integration, Avahi/mDNS and ModemManager are removed.
- Printing, Input Remapper and Tailscale remain available but disabled by default.
- Homebrew remains available for upstream `ujust` compatibility; periodic Brew update/upgrade timers are masked.
- The visual identity is Kobold except for the intentionally inherited Bluefin Plymouth.
- `divination` is a read-only security/health diagnostic.

## First build

```bash
unzip kobold-bluefin-project.zip
cd kobold-bluefin-project
just check
just prepare
just build
```

`just prepare` does two reproducibility tasks before the build:

1. downloads the exact logo/wallpaper/icon assets from the previous `lnx89f/kobold-silverblue` commit and verifies SHA-256;
2. resolves `ghcr.io/ublue-os/bluefin:stable` to an immutable registry digest and writes `.base-image.lock`.

The Containerfile has no fallback base: building without a resolved digest is intentionally unsupported.

## Scope of v0.1

The first target is OCI -> `bootc container lint` -> QCOW2 -> GDM -> GNOME/Niri. **ISO/Anaconda work is intentionally out of scope** until the system image is stable.

See `KOBOLD-SPEC.md`, `DECISIONS.md`, `docs/ARCHITECTURE.md`, `docs/VIRTUALIZATION.md` and `docs/VALIDATION.md` before expanding the project.
