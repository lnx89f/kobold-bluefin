#!/usr/bin/env bash
set -euo pipefail

for f in /ctx/kobold/*.sh /ctx/tests/*.sh /usr/bin/divination; do
  bash -n "$f"
done

/ctx/tests/image-invariants.sh
