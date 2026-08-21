# Decisions

This file records decisions already made so future work does not reopen them without new evidence.

## Keep from Bluefin

- Bluefin Standard as the real base image.
- Bluefin/Fedora kernel, hardware integration, TuneD/PPD, ZRAM, bootc and normal network/DNS behavior.
- `ujust` intact, including upstream recipe names.
- Homebrew payload/setup for `ujust` compatibility.
- Bazaar and its upstream preinstall/integration.
- Fish, Zsh and `bluefin-cli` as mandatory inherited payload, without downstream reinstall or automatic shell greeting/banner activation.
- Tailscale package, disabled by default.
- Printing stack, disabled rather than removed.
- Input Remapper package, disabled rather than removed.
- Bluefin Plymouth artwork as the only intentionally visible upstream branding exception.

## Remove or avoid

- Docker, Compose, `podman-docker`, Podman Compose.
- VS Code from the immutable image. Codex CLI does not require it for model quality.
- Trivy from the host. Use it on demand from a container/Distrobox when needed.
- Toolbx when removal is dependency-safe; Distrobox is the host-supported container UX.
- Samba/Winbind/SMB backend.
- iPhone/iOS userspace integration.
- Avahi/mDNS daemon/tools.
- ModemManager.
- old Akatsuki/Kobold custom DNS/DoT/fallback-resolver policy.
- custom kernel, ZRAM, power stack or USB autosuspend policy.
- all Bluefin-added immutable GNOME Shell extensions.
- automatic terminal welcome/banner branding.
- custom ISO/installer work in v0.1.

## Virtualization

- **Common:** GNOME Boxes, designed for normal distro testing/dev and convenience integration.
- **Quarantine:** native virt-manager + `qemu:///system`; SELinux/sVirt is required.
- The two profiles intentionally use different interfaces to reduce operator mistakes.
- Quarantine VMs are audited for risky integration devices by `divination`; enforcement beyond sVirt is added only after a tested threat-model change.

## Mutable configuration

- Niri itself is immutable/system-installed; its configuration is not.
- `chezmoi` + Git is the preferred dotfile layer across reinstalls.
- Personal GNOME extensions, Niri config, Waybar/Fuzzel/Mako config, shell configuration and similar preferences must live outside the bootc image.

## Flatpak

- Keep Bluefin Bazaar exactly as upstream intends.
- Add only `org.mozilla.firefox` as a Kobold preinstall in v0.1.
- Do not execute the large optional Bluefin system-Flatpak bundle automatically.
- Additional Flatpaks are mutable/user-selected and can be added to the Kobold preinstall later if they become true first-boot requirements.

## Branding

- Reuse the exact logo, icon sizes, GDM logo and wallpaper from the previous `kobold-silverblue` repository.
- Fetch them from a pinned old commit and verify SHA-256 rather than duplicating opaque, unverified downloads.
- Human-facing identity is Kobold; technical base identity remains compatible with Bluefin/Fedora.

## Update model

- Kobold tracks stable upstream channels. Bluefin `stable` is resolved at the start of each release or rebuild cycle, and the resulting digest identifies the parent of that candidate or validated build.
- `.base-image.lock` records that resolved parent; it does not permanently freeze Bluefin.
- Fedora RPMs use the stable versions available at build time, and stable Flatpak branches are used without permanent commit pins. Applications and libraries are not arbitrarily version-pinned.
- Rebuilds are expected approximately every 15 days, or earlier for a relevant CVE, critical update or upstream fix.
- Promotion occurs only after the required Kobold validation gates pass.
- The v0.1.0-rc.1 ISO is the baseline for physical validation. Subsequent functional changes proceed through OCI/bootc and do not require rebuilding the ISO each time.
- A new ISO is required only when a new installation baseline for RC2 or Final is deliberately chosen.
