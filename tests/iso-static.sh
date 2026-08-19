#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
WORKFLOW="${ROOT}/.github/workflows/build-iso.yml"
OVERLAY="${ROOT}/iso_files/kobold-overlay.sh"
PRE_INITRAMFS="${ROOT}/iso_files/kobold-pre-initramfs.sh"
FLATPAKS="${ROOT}/iso_files/flatpaks.list"
E2E_PATCH="${ROOT}/tests/iso-e2e-harness.patch"
BLUEFIN_ISO_PIN='d34ce2b7727422cb0d89ebdd2bda4fc0fe40523a'
TITANOBOA_PIN='840217d97bd0bc9a52466508c54d8dda5c5ba2fd'

fail() {
  printf 'iso static check failed: %s\n' "$*" >&2
  exit 1
}

for script in "${OVERLAY}" "${PRE_INITRAMFS}" "${ROOT}/tests/iso-static.sh"; do
  bash -n "${script}"
done

mapfile -t flatpaks < <(grep -Ev '^[[:space:]]*(#|$)' "${FLATPAKS}")
[[ "${#flatpaks[@]}" -eq 2 ]] || fail 'ISO Flatpak list must contain exactly two entries'
[[ "${flatpaks[0]}" == 'org.mozilla.firefox' ]] || fail 'Firefox must be the first ISO Flatpak'
[[ "${flatpaks[1]}" == 'io.github.kolunmi.Bazaar' ]] || fail 'Bazaar must be the second ISO Flatpak'

[[ ! -e "${ROOT}/disk_config/iso-gnome.toml" ]] || fail 'obsolete GNOME ISO TOML still exists'
[[ ! -e "${ROOT}/disk_config/iso-kde.toml" ]] || fail 'obsolete KDE ISO TOML still exists'
[[ -s "${ROOT}/disk_config/disk.toml" ]] || fail 'validated QCOW2 disk config is missing'

if grep -RIEq 'anaconda-live|dracut-live|livesys-scripts' \
  "${ROOT}/Containerfile" "${ROOT}/build_files" "${ROOT}/system_files"; then
  fail 'Live ISO dependencies leaked into the normal OCI build'
fi

grep -Eq '^ID=bluefin\$|\^ID="bluefin"\$' "${ROOT}/tests/image-invariants.sh" \
  || fail 'runtime invariant for ID=bluefin is missing'
grep -Fq 'KOBOLD_IMAGE_NAME=kobold-bluefin' "${ROOT}/Containerfile" \
  || fail 'Kobold image name metadata is missing'
grep -Fq ".\"image-name\"=\$name" "${ROOT}/build_files/kobold/60-branding.sh" \
  || fail 'Kobold image-info rewrite is missing'
if grep -Eq 'set_os_release[[:space:]]+ID([[:space:]]|$)' "${ROOT}/build_files/kobold/60-branding.sh"; then
  fail 'human-facing branding must not change the Bluefin OS ID'
fi

for forbidden in \
  secureboot sb_pubkey mokutil akmods profile_id os_id efi_dir btrfs \
  containers-storage 'bootc switch' cosign; do
  if grep -Fiq "${forbidden}" "${OVERLAY}"; then
    fail "overlay contains forbidden installer/security token: ${forbidden}"
  fi
done
if grep -Eq '\b(dnf5?|rpm|curl|git|systemctl)\b' "${OVERLAY}"; then
  fail 'overlay must not install packages, fetch content, or change services'
fi

mapfile -t pre_initramfs_commands < <(
  grep -Ev '^[[:space:]]*(#|$)|^#!/' "${PRE_INITRAMFS}"
)
[[ "${#pre_initramfs_commands[@]}" -eq 2 ]] \
  || fail 'pre-initramfs hook must contain only strict mode and the Anaconda dracut install'
[[ "${pre_initramfs_commands[0]}" == 'set -euo pipefail' ]] \
  || fail 'pre-initramfs hook must enable strict shell mode'
[[ "${pre_initramfs_commands[1]}" == 'dnf5 install --assumeyes anaconda-dracut' ]] \
  || fail 'pre-initramfs hook may install only anaconda-dracut'
if grep -Eiq 'secureboot|sb_pubkey|mokutil|akmods|cosign|profile_id|os_id|efi_dir|btrfs|containers-storage|bootc switch' "${PRE_INITRAMFS}"; then
  fail 'pre-initramfs hook must not alter installer or Secure Boot policy'
fi

grep -Fq "BLUEFIN_ISO_PIN: \"${BLUEFIN_ISO_PIN}\"" "${WORKFLOW}" \
  || fail 'projectbluefin/iso pin is missing or changed'
grep -Fq "TITANOBOA_PIN: \"${TITANOBOA_PIN}\"" "${WORKFLOW}" \
  || fail 'Titanoboa pin is missing or changed'
grep -Fq 'git clone --filter=blob:none --no-checkout https://github.com/projectbluefin/iso.git' "${WORKFLOW}" \
  || fail 'workflow must obtain the upstream ISO hook and harnesses from the pinned repository'
grep -Fq 'git clone --filter=blob:none --no-checkout https://github.com/ublue-os/titanoboa.git' "${WORKFLOW}" \
  || fail 'workflow must clone Titanoboa directly'
grep -Fq 'bluefin_iso_dir}/iso_files/configure_iso_anaconda.sh' "${WORKFLOW}" \
  || fail 'workflow must use the pinned Stable Anaconda hook'
grep -Fq "sed -i '1a set lists'" "${WORKFLOW}" \
  || fail 'Titanoboa Justfile list support is missing'
upstream_hook_line="$(grep -nF 'bash /app/bluefin-configure-iso-anaconda.sh' "${WORKFLOW}" | cut -d: -f1)"
overlay_hook_line="$(grep -nF 'bash /app/kobold-overlay.sh' "${WORKFLOW}" | cut -d: -f1)"
[[ -n "${upstream_hook_line}" && -n "${overlay_hook_line}" && "${overlay_hook_line}" -gt "${upstream_hook_line}" ]] \
  || fail 'Kobold overlay must execute after the upstream hook'
grep -Fq 'TITANOBOA_BUILDER_DISTRO=fedora' "${WORKFLOW}" \
  || fail 'ISO builder distro must be Fedora'
grep -Fq "HOOK_pre_initramfs=\"\${GITHUB_WORKSPACE}/iso_files/kobold-pre-initramfs.sh\"" "${WORKFLOW}" \
  || fail 'Anaconda dracut integration must be available before Titanoboa builds the initramfs'
grep -Fq "squashfs NONE \"\${OCI_REF}\" 1" "${WORKFLOW}" \
  || fail 'Titanoboa build arguments must use livesys, squashfs, and the same embedded OCI'
grep -Fq "mv \"\${TITANOBOA_DIR}/output.iso\" output.iso" "${WORKFLOW}" \
  || fail 'workflow must consume Titanoboa output.iso directly'
if grep -Fq 'steps.build.outputs.iso-dest' "${WORKFLOW}"; then
  fail 'workflow contains the obsolete Bluefin iso-dest output bug'
fi
if grep -Eq 'ublue-os/titanoboa@|titanoboa[^[:space:]]*@main' "${WORKFLOW}"; then
  fail 'workflow must not consume the floating Titanoboa Action'
fi

grep -Fq 'cosign verify --key cosign.pub' "${WORKFLOW}" \
  || fail 'OCI signature verification is missing'
grep -Fq 'for package in anaconda-live dracut-live livesys-scripts' "${WORKFLOW}" \
  || fail 'normal OCI runtime check for Live dependencies is missing'
grep -Fq '/usr/share/ublue-os/image-info.json' "${WORKFLOW}" \
  || fail 'normal OCI runtime check for Kobold image-info is missing'
grep -Fq "alias_tag=\"latest-\${GITHUB_SHA::7}\"" "${WORKFLOW}" \
  || fail 'source-SHA alias verification is missing'
grep -Fq 'final_digest' "${WORKFLOW}" \
  || fail 'final latest digest verification is missing'
grep -Fq 'candidate-status.json' "${WORKFLOW}" \
  || fail 'digest drift must explicitly invalidate the candidate'

for field in source_repo_sha oci_ref oci_tag oci_digest projectbluefin_iso_pin titanoboa_pin architecture filename; do
  grep -Fq -- "--arg ${field}" "${WORKFLOW}" \
    || fail "manifest field is missing: ${field}"
done

grep -Fq 'IMAGE_REF: ghcr.io/lnx89f/kobold-bluefin' "${WORKFLOW}" \
  || fail 'E2E harness image ref is not Kobold'
grep -Fq 'IMAGE_TAG: latest' "${WORKFLOW}" \
  || fail 'E2E harness image tag is not latest'
grep -Fq 'tests/iso/smoke.sh' "${WORKFLOW}" \
  || fail 'pinned upstream smoke harness is not used'
grep -Fq 'tests/iso/e2e.sh' "${WORKFLOW}" \
  || fail 'pinned upstream E2E harness is not used'
grep -Fq 'tests/iso-e2e-harness.patch' "${WORKFLOW}" \
  || fail 'pinned E2E harness compatibility patch is not applied'
grep -Fq 'systemd.unit=anaconda.target' "${E2E_PATCH}" \
  || fail 'E2E harness must boot the unattended Anaconda target'
grep -Fq 'Using kernel args from ISO' "${E2E_PATCH}" \
  || fail 'E2E harness must use the ISO kernel arguments'
if grep -Eiq 'secureboot|sb_pubkey|mokutil|akmods|cosign|profile_id|os_id|efi_dir|btrfs|containers-storage|bootc switch' "${E2E_PATCH}"; then
  fail 'E2E compatibility patch must not alter installer or Secure Boot policy'
fi

python3 - "${ROOT}" <<'PY'
import pathlib
import subprocess
import sys

import yaml

root = pathlib.Path(sys.argv[1])
for path in sorted((root / ".github" / "workflows").glob("*.yml")):
    with path.open(encoding="utf-8") as stream:
        workflow = yaml.safe_load(stream)
    for job in workflow.get("jobs", {}).values():
        for step in job.get("steps", []):
            script = step.get("run")
            if script:
                subprocess.run(["bash", "-n"], input=script, text=True, check=True)
PY

printf 'iso static checks: OK\n'
