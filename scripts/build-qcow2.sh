#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${KOBOLD_IMAGE:-localhost/kobold:local}"
OUTPUT="${ROOT}/output/qcow2"

command -v image-builder >/dev/null 2>&1 || {
  cat >&2 <<'EOF'
The unified osbuild `image-builder` CLI is required for this helper.
Build the OCI first; install/use image-builder according to current osbuild docs,
then rerun this command. Kobold intentionally does not vendor an installer stack.
EOF
  exit 1
}

mkdir -p "${OUTPUT}"

# image-builder consumes the root user's container storage when run through sudo.
# Copy the already built digest into rootful storage under the same local tag.
tmp_archive="$(mktemp --suffix=.tar)"
trap 'rm -f "${tmp_archive}"' EXIT
podman save --format oci-archive -o "${tmp_archive}" "${IMAGE}"
sudo podman load -i "${tmp_archive}" >/dev/null

sudo image-builder build \
  --bootc-ref "${IMAGE}" \
  --bootc-default-fs btrfs \
  --output-dir "${OUTPUT}" \
  qcow2

printf 'QCOW2 output: %s\n' "${OUTPUT}"
