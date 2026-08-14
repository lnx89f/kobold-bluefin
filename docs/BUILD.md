# Build workflow

## Prerequisites

For the OCI build: Podman, `skopeo` (or Podman for digest resolution), curl, sha256sum and Just.

The Bluefin workstation already provides most of these; the project does not require Docker.

## 1. Source checks

```bash
just check
```

If ShellCheck is installed, the static gate uses it; otherwise Bash syntax and project-policy checks still run.

## 2. Prepare external inputs

```bash
just prepare
```

This fetches the exact artwork from the pinned previous Kobold commit and resolves `bluefin:stable` into `.base-image.lock`:

After the first successful resolution, commit `.base-image.lock`. Renovate is configured to propose digest refreshes while preserving the `stable` channel.

```text
BASE_IMAGE=ghcr.io/ublue-os/bluefin:stable@sha256:...
```

The Containerfile has no default `BASE_IMAGE`, so direct floating-tag builds fail by construction.

## 3. Build OCI

```bash
just build
```

`just build` intentionally does **not** refresh the Bluefin digest. Retries use the
existing `.base-image.lock`, which keeps the build reproducible and preserves Podman
layer cache. Run `just refresh-base` only when intentionally accepting a newer
`bluefin:stable` digest.

The Containerfile keeps each numbered Kobold stage in a separate `RUN` layer. If a
later validation fails, the error identifies the exact stage and already-successful
stages can remain cached.

Override the local output name if desired:

```bash
KOBOLD_IMAGE=localhost/kobold:test ./scripts/build-image.sh
```

The build runs all numbered stages, image invariants and `bootc container lint --fatal-warnings` before completing.

## 4. Build QCOW2

Kobold uses the current unified osbuild `image-builder` direction rather than adding a new custom installer pipeline.

Install the current host-side image builder according to osbuild documentation, then:

```bash
just qcow2
```

The helper copies the locally built image into rootful Podman storage because `image-builder` commonly requires root for loop/mount operations, then runs a bootc-based QCOW2 build with Btrfs selected as the default filesystem.

If the installed `image-builder` version changes CLI flags, update only `scripts/build-qcow2.sh` after consulting current osbuild documentation; do not resurrect the old custom ISO stack.

References:

- https://osbuild.org/docs/developer-guide/projects/image-builder/usage/
- https://osbuild.org/docs/bootc/deprecation-notice/
