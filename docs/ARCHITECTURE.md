# Architecture

## Layering

```text
Bluefin Standard stable (resolved by digest)
        |
        +-- Fedora/Bluefin kernel + hardware + firmware
        +-- bootc + update integration + ujust
        +-- TuneD/PPD + ZRAM + normal network/DNS
        |
        v
Kobold downstream delta
        +-- package/service cleanup
        +-- GNOME system-extension removal
        +-- Niri package only (no user config)
        +-- chezmoi for mutable dotfiles
        +-- rootless Podman + Distrobox policy
        +-- Boxes Common virtualization
        +-- system-libvirt Quarantine virtualization
        +-- small security delta
        +-- Kobold branding
        +-- Firefox Flatpak preinstall
        +-- divination
```

Kobold does not copy Bluefin `common`, rebuild Bluefin kernel/hardware stages, or run a partial package upgrade against the inherited base. A Bluefin update enters the project by resolving a new `stable` digest, rebuilding, and re-running acceptance tests.

## Immutable vs mutable ownership

The OCI owns machine policy: packages, services, hardening, system virtualization plumbing and branding.

HOME owns personal workflow. `chezmoi` is the intended source of truth for Niri, Waybar, Fuzzel, Mako, shell, Git, terminal, editor and other user configuration. Flatpaks and Distroboxes remain independently mutable.

## Runtime-first optimization

Kobold optimizes resident daemons, timers, sockets, wakeups and unnecessary background integration before it optimizes package count. An inert package is not removed merely to produce a smaller `rpm -qa` result.

This is why CUPS, Input Remapper, Tailscale and containerd may remain installed but inactive, while Avahi, ModemManager and Samba are removed because their functionality is outside the workstation policy.

## Branding boundary

Kobold replaces user-facing OS presentation where doing so is low-risk: wallpaper, GDM logo, generic distribution icons, `NAME/PRETTY_NAME`, Fastfetch and GNOME defaults. Bluefin technical compatibility identifiers are retained in v0.1. Plymouth remains deliberately upstream.

`ujust` is also intentionally not rebranded: its recipe names are upstream API/UX, not Kobold identity files.
