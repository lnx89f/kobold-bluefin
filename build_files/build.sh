#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

for stage in \
  10-packages.sh \
  20-services.sh \
  30-desktop.sh \
  40-virtualization.sh \
  50-security.sh \
  60-branding.sh \
  90-validate.sh; do
  echo "=== Kobold stage ${stage%.sh} ==="
  "/ctx/kobold/${stage}"
done
