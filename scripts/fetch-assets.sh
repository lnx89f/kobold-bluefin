#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OLD_COMMIT="9a0e6a22484a032d2e8246a6493584bf4f48f55f"
RAW="https://raw.githubusercontent.com/lnx89f/kobold-silverblue/${OLD_COMMIT}"

fetch() {
  local rel="$1" dst="$2" expected="$3"
  mkdir -p "$(dirname "${ROOT}/${dst}")"
  if [[ -f "${ROOT}/${dst}" ]] && echo "${expected}  ${ROOT}/${dst}" | sha256sum -c - >/dev/null 2>&1; then
    printf 'asset ok: %s\n' "${dst}"
    return
  fi
  printf 'fetching: %s\n' "${rel}"
  curl --fail --location --proto '=https' --tlsv1.2 \
    "${RAW}/${rel}" -o "${ROOT}/${dst}.tmp"
  echo "${expected}  ${ROOT}/${dst}.tmp" | sha256sum -c -
  mv "${ROOT}/${dst}.tmp" "${ROOT}/${dst}"
}

fetch "kobold-logo.png" \
  "assets/source/kobold-logo.png" \
  "4418e4263e1d95524533a1a4bd4c8be3c1be0b317e5cf763fdb47df079e11903"

fetch "kobold-wallpaper.png" \
  "files/usr/share/backgrounds/kobold/kobold-wallpaper.png" \
  "2b5bf2211ac87330582aa65433a711b94dd2b36961cf68b647de5b3f27ddf8c0"

fetch "files/usr/share/kobold/branding/kobold-gdm-logo.png" \
  "files/usr/share/kobold/branding/kobold-gdm-logo.png" \
  "5d94298c365bc768144cfcf30155a96250cd89909b3baab1c857ac383e3967a5"

while read -r size sum; do
  fetch "files/usr/share/icons/hicolor/${size}x${size}/apps/kobold.png" \
    "files/usr/share/icons/hicolor/${size}x${size}/apps/kobold.png" \
    "${sum}"
done <<'EOF'
16 d50c66497e2292662383fbb7617a276440e22197c9c5ed98c52824af81997fd6
22 8cc1e9f8c3c23e188d011d89626666199b841ff3f7b04fbe900dff3bbf95d54d
24 3671fe53b7f4f8c142644a83e2290bced1ecd0fe09737bc32246b5674e8076f7
32 d30a3e7a42a723de8d355cd4a4cb6713df1ef6496c14e041284658b77cee275b
48 0218032c17068b1c53e69bf607e3b80f3e6865f6b95d1577bf3d149a1bd6b820
64 6d2307981b250a96f8d391895fb53e38d0f9dbf39e1dc1cad12a3ea46ce92cbf
128 64ea122051d41e9e060561489d48d79b5837201b17e1fde8e799dcf09c65be2e
256 b9298c8c0e360cfe30c488f2fe3b1062bdbc10113564d60c44ad8d6fc811c14c
512 9cf73395a4b63549b3b79ff0e41f439fb6a56ec635c97766bf1a07d1c75966c9
EOF

printf 'Kobold artwork prepared from %s\n' "${OLD_COMMIT}"
