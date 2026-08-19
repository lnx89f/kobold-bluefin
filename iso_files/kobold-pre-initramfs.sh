#!/usr/bin/env bash
set -euo pipefail

# The pinned Titanoboa recipe builds the initramfs before the Bluefin
# post-rootfs hook installs Anaconda. Install only Anaconda's dracut module
# here so inst.ks is fetched into /run/install/ks.cfg during unattended boots.
dnf5 install --assumeyes anaconda-dracut
