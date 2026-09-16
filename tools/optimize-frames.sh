#!/bin/bash
# Downscale the "Aufräumen" animation frames (sty/frames/frame-000..125.png).
#
# Why: those 126 frames are 1920x1080 and total 20 MB. They are shown by
# \animategraphics at width=\paperwidth on a 21cm-wide slide, so 1920px is far
# more resolution than is ever displayed, and every frame is embedded into the
# PDF. Measured on presentation_full:
#
#   frames 1920px (as shipped)  ->  PDF 20 MB, build 70.6s
#   frames  960px (PNG8)        ->  PDF  8.0 MB, build 65.8s   (same 315 pages)
#
# So it is a ~60% cut in the published PDF for no visible difference on a
# projector -- which matters because these PDFs get committed to the website
# repo on every release. The build-time gain (~5s) is a bonus.
#
# NOTE: -resize alone makes the files BIGGER, because ImageMagick promotes the
# indexed-palette originals to truecolour. The PNG8: prefix is what keeps them
# palette. (Re-compressing at full 1920px only reaches 18 MB -- the win comes
# from resolution, not compression.)
#
# Usage: template/tools/optimize-frames.sh [width]   (default 960)
#        Run it from the template repo root, then commit sty/frames/.
set -euo pipefail

WIDTH="${1:-960}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
FRAMES="$SCRIPT_DIR/../sty/frames"

command -v magick >/dev/null || { echo "needs ImageMagick (magick)" >&2; exit 1; }
[ -d "$FRAMES" ] || { echo "no frames dir at $FRAMES" >&2; exit 1; }

before=$(du -sh "$FRAMES" | cut -f1)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

for f in "$FRAMES"/frame-*.png; do
  magick "$f" -resize "${WIDTH}x" -strip PNG8:"$tmp/$(basename "$f")"
done
mv "$tmp"/frame-*.png "$FRAMES"/

echo "frames: $before -> $(du -sh "$FRAMES" | cut -f1) (width ${WIDTH}px, palette preserved)"
echo "Rebuild a presentation_full variant and eyeball the final animation before committing."
