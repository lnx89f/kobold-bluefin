#!/usr/bin/env bash
set -euo pipefail

# The pinned Titanoboa recipe builds the initramfs before the Bluefin
# post-rootfs hook installs Anaconda. Install only Anaconda's dracut module
# here and explicitly select it (the module declares itself optional) so
# inst.ks is fetched into /run/install/ks.cfg during unattended boots.
dnf5 install --assumeyes anaconda-dracut
install -d -m 0755 /etc/dracut.conf.d
printf '%s\n' 'add_dracutmodules+=" anaconda "' >/etc/dracut.conf.d/90-kobold-anaconda.conf
