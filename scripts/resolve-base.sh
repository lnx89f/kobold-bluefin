#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE_TAG="${KOBOLD_BASE_TAG:-ghcr.io/ublue-os/bluefin:stable}"
LOCK="${ROOT}/.base-image.lock"

[[ "${BASE_TAG}" == "ghcr.io/ublue-os/bluefin:stable" ]] || {
  printf 'Refusing unexpected base tag: %s\n' "${BASE_TAG}" >&2
  exit 1
}

if command -v skopeo >/dev/null 2>&1; then
  digest="$(skopeo inspect --format '{{.Digest}}' "docker://${BASE_TAG}")"
elif command -v podman >/dev/null 2>&1; then
  podman pull "${BASE_TAG}" >/dev/null
  digest_ref="$(podman image inspect --format '{{index .RepoDigests 0}}' "${BASE_TAG}" 2>/dev/null || true)"
  digest="${digest_ref##*@}"
else
  echo 'Need skopeo or podman to resolve the Bluefin digest.' >&2
  exit 1
fi

[[ "${digest}" =~ ^sha256:[0-9a-f]{64}$ ]] || {
  printf 'Invalid registry digest: %s\n' "${digest}" >&2
  exit 1
}

printf 'BASE_IMAGE=%s@%s\n' "${BASE_TAG}" "${digest}" >"${LOCK}.tmp"
mv "${LOCK}.tmp" "${LOCK}"
printf 'Locked base: %s@%s\n' "${BASE_TAG}" "${digest}"
