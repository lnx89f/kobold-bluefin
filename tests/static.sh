#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# When called inside the container build, syntax checks are run directly by
# 90-validate.sh. This script is primarily the repository/source gate.
if [[ -d "${ROOT}/build" ]]; then
  while IFS= read -r -d '' f; do
    bash -n "$f"
  done < <(find "${ROOT}/build" "${ROOT}/scripts" "${ROOT}/tests" -type f -name '*.sh' -print0)
  bash -n "${ROOT}/files/usr/bin/divination"
fi

[[ -f "${ROOT}/Containerfile" ]]
grep -Fqx 'ARG BASE_IMAGE' "${ROOT}/Containerfile"
grep -Fq 'FROM ${BASE_IMAGE}' "${ROOT}/Containerfile"
! grep -Eq '^FROM[[:space:]]+ghcr\.io/ublue-os/bluefin:stable([[:space:]]|$)' "${ROOT}/Containerfile"

[[ -f "${ROOT}/custom/flatpaks/50-kobold.preinstall" ]]
grep -Fq '[Flatpak Preinstall org.mozilla.firefox]' "${ROOT}/custom/flatpaks/50-kobold.preinstall"
! grep -Eq 'Smile|DistroShelf|MissionCenter|Gradia|Thunderbird' "${ROOT}/custom/flatpaks/50-kobold.preinstall"

# Niri configuration is deliberately mutable/chezmoi-owned.
[[ ! -e "${ROOT}/niri" ]]
! find "${ROOT}/files" -type f -path '*/niri/*' -print -quit | grep -q .

# Do not reintroduce discarded architecture.
[[ ! -d "${ROOT}/iso" ]]
! find "${ROOT}/files" -type f \
  \( -path '*/NetworkManager/conf.d/*kobold*' -o -path '*/systemd/resolved.conf.d/*kobold*' \) \
  -print -quit | grep -q .
! grep -RIEq 'rpmfusion|docker-compose|podman-compose|cloudflare.*fallback|quad9.*fallback' \
  "${ROOT}/build" "${ROOT}/files" "${ROOT}/custom" 2>/dev/null

# Artwork source is immutable and checksum-verified.
grep -Fq '9a0e6a22484a032d2e8246a6493584bf4f48f55f' "${ROOT}/scripts/fetch-assets.sh"
grep -Fq '2b5bf2211ac87330582aa65433a711b94dd2b36961cf68b647de5b3f27ddf8c0' "${ROOT}/scripts/fetch-assets.sh"
grep -Fq '4418e4263e1d95524533a1a4bd4c8be3c1be0b317e5cf763fdb47df079e11903' "${ROOT}/scripts/fetch-assets.sh"

if command -v shellcheck >/dev/null 2>&1 && [[ -d "${ROOT}/build" ]]; then
  # SC1090 is intentional for the generated base lock sourced by build-image.sh.
  shellcheck -e SC1090 \
    "${ROOT}"/build/*.sh "${ROOT}"/scripts/*.sh "${ROOT}"/tests/*.sh \
    "${ROOT}/files/usr/bin/divination"
fi

printf 'static checks: OK\n'
