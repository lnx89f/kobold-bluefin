#!/usr/bin/env bash
set -euo pipefail

for f in /tmp/kobold-build/*.sh /tmp/kobold-tests/*.sh /usr/bin/divination; do
  bash -n "$f"
done

/tmp/kobold-tests/image-invariants.sh
