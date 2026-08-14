#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCK="${ROOT}/.base-image.lock"
IMAGE="${KOBOLD_IMAGE:-localhost/kobold:local}"

[[ -f "${LOCK}" ]] || {
  echo '.base-image.lock is missing; run ./scripts/resolve-base.sh first.' >&2
  exit 1
}
# shellcheck disable=SC1090
source "${LOCK}"
[[ "${BASE_IMAGE:-}" =~ ^ghcr\.io/ublue-os/bluefin:stable@sha256:[0-9a-f]{64}$ ]] || {
  printf 'Base lock is not an immutable Bluefin stable reference: %s\n' "${BASE_IMAGE:-unset}" >&2
  exit 1
}

for required in \
  files/usr/share/backgrounds/kobold/kobold-wallpaper.png \
  files/usr/share/kobold/branding/kobold-gdm-logo.png \
  files/usr/share/icons/hicolor/256x256/apps/kobold.png; do
  [[ -s "${ROOT}/${required}" ]] || {
    echo "Missing branding asset: ${required}; run ./scripts/fetch-assets.sh" >&2
    exit 1
  }
done

podman build \
  --pull=always \
  --build-arg "BASE_IMAGE=${BASE_IMAGE}" \
  --build-arg "KOBOLD_IMAGE_REGISTRY=${KOBOLD_IMAGE_REGISTRY:-ghcr.io}" \
  --build-arg "KOBOLD_IMAGE_VENDOR=${KOBOLD_IMAGE_VENDOR:-lnx89f}" \
  --build-arg "KOBOLD_IMAGE_NAME=${KOBOLD_IMAGE_NAME:-kobold}" \
  --build-arg "KOBOLD_IMAGE_TAG=${KOBOLD_IMAGE_TAG:-local}" \
  --tag "${IMAGE}" \
  "${ROOT}"

printf 'Built %s from %s\n' "${IMAGE}" "${BASE_IMAGE}"
