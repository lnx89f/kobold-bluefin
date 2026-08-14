set shell := ["bash", "-euo", "pipefail", "-c"]

image := env_var_or_default("KOBOLD_IMAGE", "localhost/kobold:local")

# One-time/external-input preparation: fetch pinned Kobold artwork and resolve
# bluefin:stable into an immutable digest lock. Do not run this automatically on
# every retry, or a moving stable tag could invalidate reproducibility and cache.
prepare:
    ./scripts/fetch-assets.sh
    ./scripts/resolve-base.sh

# Refresh only the Bluefin base lock when intentionally accepting a newer stable.
refresh-base:
    ./scripts/resolve-base.sh

# Static checks that do not require building the OCI.
check:
    ./tests/static.sh

# Build exactly the digest already recorded in .base-image.lock.
build:
    ./tests/static.sh
    KOBOLD_IMAGE={{image}} ./scripts/build-image.sh

# Produce a QCOW2 using the unified osbuild image-builder CLI.
# Requires image-builder on the host and a rootful container image visible to root.
qcow2: build
    KOBOLD_IMAGE={{image}} ./scripts/build-qcow2.sh

# Show the resolved base lock.
base:
    cat .base-image.lock
