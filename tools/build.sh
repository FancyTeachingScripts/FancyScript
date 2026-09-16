#!/bin/bash
# Build a single .tex file (default: main.tex) with the shared template
# mounted as a submodule at ./template. Run from a course repo's root.
#
# Usage: template/tools/build.sh [file.tex] [outdir] [--draft]
#
#   --draft   single TeX pass: measured ~19s instead of ~57s on a 314-page
#             deck. Cross-references, TOC and beamer navigation are NOT
#             converged (page count can be off by one), so use it while
#             iterating on content, not for anything you publish.
#
# Build time is dominated by (passes x pages), at roughly 65ms per page per
# pass; the preamble and all the fonts together cost only ~1.2s. So the
# fastest way to iterate is to build the *variant you are actually working
# on*: presentation_minimal is 129 pages / ~20s, while presentation_full is
# 315 pages / ~70s -- mostly because the timer feature emits one overlay
# page per minute, which roughly doubles the page count on its own.
set -euo pipefail

FILE="main.tex"
OUT="build"
REPASS=""
args=()
for a in "$@"; do
  case "$a" in
    --draft) REPASS="-r 0" ;;
    *) args+=("$a") ;;
  esac
done
[ "${#args[@]}" -ge 1 ] && FILE="${args[0]}"
[ "${#args[@]}" -ge 2 ] && OUT="${args[1]}"

mkdir -p "$OUT"
tectonic -Z search-path=. -Z search-path=template -Z search-path=template/sty/moloch \
  -Z continue-on-errors $REPASS -o "$OUT" "$FILE"
