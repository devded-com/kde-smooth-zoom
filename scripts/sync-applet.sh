#!/usr/bin/env bash
#
# Copy the single source-of-truth CLI into the applet package so a built
# .plasmoid is self-contained (plasmashell's PATH does not include ~/.local/bin).
#
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"
install -m 755 "$ROOT/bin/smooth-zoom" "$ROOT/plasma/applet/contents/code/smooth-zoom"
printf 'synced bin/smooth-zoom -> plasma/applet/contents/code/smooth-zoom\n'
