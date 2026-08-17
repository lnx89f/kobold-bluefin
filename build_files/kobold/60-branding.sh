#!/usr/bin/env bash
set -euo pipefail

# Assets are copied into the image from system_files after their golden
# checksums are verified by tests/static.sh.
test -s /usr/share/backgrounds/kobold/kobold-wallpaper.png
test -s /usr/share/kobold/branding/kobold-gdm-logo.png
test -s /usr/share/icons/hicolor/256x256/apps/kobold.png

# Remove Bluefin wallpaper/branding files where they are purely presentation.
rm -rf /usr/share/backgrounds/bluefin
find /usr/share/gnome-background-properties -maxdepth 1 -type f -iname '*bluefin*' -delete 2>/dev/null || true
find /usr/share/pixmaps -maxdepth 1 -type f -iname '*bluefin*' -delete 2>/dev/null || true
find /usr/share/icons/hicolor -type f -iname '*bluefin*' -delete 2>/dev/null || true

# Replace generic distributor/start-here raster icons with Kobold at each size.
for dir in /usr/share/icons/hicolor/*x*/apps; do
  [[ -d "$dir" && -f "$dir/kobold.png" ]] || continue
  rm -f "$dir/distributor-logo.png" "$dir/start-here.png"
  ln -s kobold.png "$dir/distributor-logo.png"
  ln -s kobold.png "$dir/start-here.png"
done

# Avoid scalable generic Bluefin artwork taking precedence over the Kobold PNGs.
rm -f \
  /usr/share/icons/hicolor/scalable/apps/distributor-logo.svg \
  /usr/share/icons/hicolor/scalable/apps/start-here.svg \
  /usr/share/icons/hicolor/scalable/places/distributor-logo.svg \
  /usr/share/icons/hicolor/scalable/places/distributor-logo-symbolic.svg \
  /usr/share/icons/hicolor/scalable/places/start-here.svg 2>/dev/null || true

mkdir -p /usr/share/pixmaps
for name in system-logo.png fedora-logo.png fedora-logo-small.png fedora_logo_med.png fedora-logo-sprite.png; do
  rm -f "/usr/share/pixmaps/${name}"
  ln -s ../icons/hicolor/256x256/apps/kobold.png "/usr/share/pixmaps/${name}"
done

# Human-facing identity only. Preserve ID/ID_LIKE/VARIANT_ID/CPE and EFI-related
# compatibility identifiers inherited from Bluefin/Fedora.
os_release=/usr/lib/os-release
set_os_release() {
  local key="$1" value="$2"
  if grep -q "^${key}=" "$os_release"; then
    sed -i "s|^${key}=.*|${key}=${value}|" "$os_release"
  else
    printf '%s=%s\n' "$key" "$value" >>"$os_release"
  fi
}
set_os_release NAME '"Kobold"'
set_os_release PRETTY_NAME '"Kobold"'
set_os_release VARIANT '"Kobold"'
set_os_release LOGO 'kobold'
set_os_release DEFAULT_HOSTNAME '"kobold"'

# image-info is operational metadata used by ujust. It must identify the actual
# downstream image while retaining inherited base/fedora fields.
image_info=/usr/share/ublue-os/image-info.json
if [[ -f "$image_info" ]]; then
  tmp="$(mktemp)"
  jq \
    --arg name "${KOBOLD_IMAGE_NAME}" \
    --arg vendor "${KOBOLD_IMAGE_VENDOR}" \
    --arg ref "ostree-image-signed:docker://${KOBOLD_IMAGE_REGISTRY}/${KOBOLD_IMAGE_VENDOR}/${KOBOLD_IMAGE_NAME}" \
    --arg tag "${KOBOLD_IMAGE_TAG}" \
    '."image-name"=$name | ."image-vendor"=$vendor | ."image-ref"=$ref | ."image-tag"=$tag' \
    "$image_info" >"$tmp"
  install -m0644 "$tmp" "$image_info"
  rm -f "$tmp"
fi

# Rebuild presentation databases after Kobold assets/overrides are final.
glib-compile-schemas --strict /usr/share/glib-2.0/schemas
dconf update
gtk-update-icon-cache -f /usr/share/icons/hicolor >/dev/null 2>&1 || true
