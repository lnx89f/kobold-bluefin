# Upstream notes used by Kobold v0.1

These observations explain why specific downstream actions exist. They should be rechecked when Bluefin changes materially.

## Bluefin package delta

Current Bluefin Standard explicitly adds, among many other packages, `containerd`, `input-remapper`, Tailscale, Samba/Winbind, iPhone integration, printing drivers and workstation CLI tools. Kobold removes only the functions outside its policy or disables their runtime activation when future opt-in is desired.

Source: `ublue-os/bluefin/build_files/base/04-packages.sh`.

## GNOME extensions

Current Bluefin builds/composes AppIndicator, Bazaar Integration, Caffeine, Blur My Shell, Dash to Dock, Gradia Integration, GSConnect, Logo Menu, Search Light and a custom-command extension. Kobold removes these exact immutable UUID directories and restores a no-system-extension default.

Source: `ublue-os/bluefin/build_files/shared/build-gnome-extensions.sh` and `projectbluefin/common/.../zz0-bluefin-modifications.gschema.override`.

## Bazaar

Bluefin's Bazaar preinstall file is preserved exactly upstream. Kobold does not blacklist or override Bazaar.

Source: `projectbluefin/common/system_files/bluefin/usr/share/flatpak/preinstall.d/bazaar.preinstall`.

## Homebrew

Kobold preserves the Brew setup/payload needed by upstream Bluefin tooling but masks only recurring update/upgrade timers. Do not delete `/home/linuxbrew` payload machinery or patch `ujust` recipes.

## VM convenience recipe

Bluefin's current `ujust setup-vms` is optimized for convenient session virtualization. Kobold intentionally uses a different arrangement because hostile agents require system-libvirt/sVirt, while Boxes supplies the convenient VM experience.
