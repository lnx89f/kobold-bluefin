#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

while IFS= read -r -d '' f; do
  bash -n "$f"
done < <(find "${ROOT}/build_files" "${ROOT}/tests" -type f -name '*.sh' -print0)
divination="${ROOT}/system_files/usr/bin/divination"
bash -n "${divination}"

expected_base='ghcr.io/ublue-os/bluefin:stable@sha256:856082ff05edf994977d2adf040a159b5490218deb8e124cc6bd6df2a0aae530'
grep -Fqx "FROM ${expected_base}" "${ROOT}/Containerfile"
grep -Fqx "BASE_IMAGE=${expected_base}" "${ROOT}/.base-image.lock"
! grep -Eq '^FROM[[:space:]]+ghcr\.io/ublue-os/bluefin:stable([[:space:]]|$)' "${ROOT}/Containerfile"
grep -Fq 'bootc container lint --fatal-warnings' "${ROOT}/Containerfile"
grep -Fqx 'COPY --from=ctx /system_files/etc/hostname /etc/hostname' "${ROOT}/Containerfile"

grep -Fq 'state="$(systemctl is-enabled "$1" 2>/dev/null || true)"' "${divination}"
if grep -Fq 'systemctl is-enabled "$1" 2>/dev/null || printf' "${divination}"; then
  printf 'divination unit_state still appends a fallback to systemctl output\n' >&2
  exit 1
fi
grep -Fq "info 'bootc status requires root; run: sudo bootc status'" "${divination}"
if grep -Eq '(^|[;&|])[[:space:]]*(sudo|pkexec)[[:space:]]' "${divination}"; then
  printf 'divination must not invoke sudo or pkexec\n' >&2
  exit 1
fi

grep -Fqx 'kobold' "${ROOT}/system_files/etc/hostname"
grep -Fqx 'ExecCondition=/usr/sbin/mcelog --is-cpu-supported' \
  "${ROOT}/system_files/etc/systemd/system/mcelog.service.d/10-kobold-supported-cpu.conf"

flatpak="${ROOT}/system_files/etc/flatpak/preinstall.d/50-kobold.preinstall"
[[ -f "${flatpak}" ]]
grep -Fq '[Flatpak Preinstall org.mozilla.firefox]' "${flatpak}"
! grep -Eq 'Smile|DistroShelf|MissionCenter|Gradia|Thunderbird' "${flatpak}"

# Niri configuration is deliberately mutable/chezmoi-owned.
[[ ! -e "${ROOT}/niri" ]]
! find "${ROOT}/system_files" -type f -path '*/niri/*' -print -quit | grep -q .

# Do not reintroduce discarded Kobold architecture.
[[ ! -d "${ROOT}/iso" ]]
! find "${ROOT}/system_files" -type f \
  \( -path '*/NetworkManager/conf.d/*kobold*' -o -path '*/systemd/resolved.conf.d/*kobold*' \) \
  -print -quit | grep -q .
! grep -RIEq 'rpmfusion|docker-compose|podman-compose|cloudflare.*fallback|quad9.*fallback' \
  "${ROOT}/build_files/kobold" "${ROOT}/system_files" 2>/dev/null

# The migrated image embeds the exact validated golden artwork.
printf '%s  %s\n' \
  '2b5bf2211ac87330582aa65433a711b94dd2b36961cf68b647de5b3f27ddf8c0' \
  "${ROOT}/system_files/usr/share/backgrounds/kobold/kobold-wallpaper.png" | sha256sum -c -
printf '%s  %s\n' \
  '5d94298c365bc768144cfcf30155a96250cd89909b3baab1c857ac383e3967a5' \
  "${ROOT}/system_files/usr/share/kobold/branding/kobold-gdm-logo.png" | sha256sum -c -
printf '%s  %s\n' \
  'b9298c8c0e360cfe30c488f2fe3b1062bdbc10113564d60c44ad8d6fc811c14c' \
  "${ROOT}/system_files/usr/share/icons/hicolor/256x256/apps/kobold.png" | sha256sum -c -

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck \
    "${ROOT}/build_files/build.sh" "${ROOT}"/build_files/kobold/*.sh \
    "${ROOT}"/tests/*.sh "${ROOT}/system_files/usr/bin/divination"
fi

printf 'static checks: OK\n'
