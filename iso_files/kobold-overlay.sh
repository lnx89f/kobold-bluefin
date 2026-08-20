#!/usr/bin/env bash
set -euo pipefail

# This runs after Bluefin's pinned Stable ISO hook. Keep it limited to
# human-facing Live-session presentation; compatibility and installer policy
# remain owned by the upstream hook.
kobold_icon=/usr/share/icons/hicolor/256x256/apps/kobold.png
anaconda_icon=/usr/share/anaconda/pixmaps/kobold.png

test -s "${kobold_icon}"
install -D -m 0644 "${kobold_icon}" "${anaconda_icon}"

sed -i 's/Bluefin/Kobold/g' /etc/system-release
for presentation_file in \
  /usr/share/anaconda/gnome/fedora-welcome \
  /usr/share/anaconda/gnome/org.fedoraproject.welcome-screen.desktop; do
  [[ ! -f "${presentation_file}" ]] || sed -i 's/Bluefin/Kobold/g' "${presentation_file}"
done
if [[ -f /usr/share/applications/liveinst.desktop ]]; then
  sed -i "s|^Icon=.*|Icon=${anaconda_icon}|" /usr/share/applications/liveinst.desktop
fi

cat >/usr/share/glib-2.0/schemas/zz4-kobold-live.gschema.override <<'EOF'
[org.gnome.shell]
favorite-apps = ['anaconda.desktop', 'io.github.kolunmi.Bazaar.desktop', 'org.mozilla.firefox.desktop', 'org.gnome.Nautilus.desktop']
EOF

glib-compile-schemas /usr/share/glib-2.0/schemas
