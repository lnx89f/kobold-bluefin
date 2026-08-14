#!/usr/bin/env bash
set -euo pipefail

# Bluefin currently composes these extensions into the system image. Remove the
# exact UUID directories only; never wildcard-delete the GNOME extension tree.
extensions=(
  appindicatorsupport@rgcjonas.gmail.com
  bazaar-integration@kolunmi.github.io
  caffeine@patapon.info
  blur-my-shell@aunetx
  custom-command-list@storageb.github.com
  dash-to-dock@micxgx.gmail.com
  gradia-integration@alexandervanhee.github.io
  gsconnect@andyholmes.github.io
  logomenu@aryan_k
  search-light@icedman.github.com
)
for uuid in "${extensions[@]}"; do
  rm -rf "/usr/share/gnome-shell/extensions/${uuid}"
done

# Helpers installed solely for Bluefin's Logo Menu extension.
rm -f /usr/bin/distroshelf-helper /usr/bin/missioncenter-helper

# Return GNOME defaults to upstream rather than carrying Bluefin's extension,
# wallpaper, dock and favorite-app defaults. Kobold's later override owns only
# the few defaults it intentionally needs.
rm -f /usr/share/glib-2.0/schemas/zz0-bluefin-modifications.gschema.override

# The automatic Bluefin terminal welcome was a recurring source of visual noise.
# Keep uwelcome/ujust binaries available, but do not inject them into every shell.
rm -f /etc/profile.d/uwelcome.sh
rm -f /usr/share/fish/vendor_conf.d/fish_greeting.fish

# Fedora's inherited screensaver override still sets picture-uri-dark, which is
# not a key in the current org.gnome.desktop.screensaver schema.
sed -i "/^picture-uri-dark=/d" /usr/share/glib-2.0/schemas/10_org.gnome.desktop.screensaver.fedora.gschema.override

# Niri is a system capability; its user configuration belongs to chezmoi.
rm -rf /etc/niri /usr/share/kobold/niri 2>/dev/null || true

rm -f /usr/share/glib-2.0/schemas/gschemas.compiled
glib-compile-schemas --strict /usr/share/glib-2.0/schemas
dconf update
