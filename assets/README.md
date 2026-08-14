# Artwork provenance

Kobold vNext intentionally reuses the exact visual identity from the previous `lnx89f/kobold-silverblue` project.

The project intentionally keeps artwork provenance separate from new source files. `scripts/fetch-assets.sh` downloads the exact binaries from the pinned old commit:

`9a0e6a22484a032d2e8246a6493584bf4f48f55f`

Every downloaded asset has a hard-coded SHA-256 taken from the previous repository's `SOURCE-SHA256SUMS`. A checksum mismatch is fatal.

Fetched assets:

- original `kobold-logo.png` source;
- `kobold-wallpaper.png` installed as `/usr/share/backgrounds/kobold/kobold-wallpaper.png`;
- existing Kobold GDM logo;
- existing hicolor PNG icon sizes from 16 through 512 px.

This preserves the exact previous artwork while keeping the new project tree clean and auditable.
