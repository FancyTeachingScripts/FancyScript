#!/bin/bash
# Compiles the same fixed PDF set that .github/workflows/pr-preview.yml
# builds on every PR, for local review before pushing. Run from a course
# repo's root (template mounted at ./template).
#
# Keep FILES below in sync with the `texfile` matrix in
# .github/workflows/pr-preview.yml -- it is intentionally duplicated rather
# than shared, since GitHub Actions matrices can't source from a shell
# script without a separate job.
#
#   -o DIR             output directory for the compiled PDFs (default: build)
#   --template-dir DIR where the template payload lives: "template" for a
#                       course repo (default), "." for this repo itself
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
TEMPLATE_DIR="template"
OUT="build"

while [ $# -gt 0 ]; do
  case "$1" in
    -o) OUT="$2"; shift 2 ;;
    --template-dir) TEMPLATE_DIR="$2"; shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

FILES=(
  presentation_noaufraeumen.tex
  presentation_noaufraeumen-bright.tex
  print_students-cover.tex
  print_solution-cover.tex
)

bash "$SCRIPT_DIR/gen-main.sh" main
mkdir -p "$OUT"

for f in "${FILES[@]}"; do
  echo "==> $f"
  tectonic -Z search-path=. -Z "search-path=$TEMPLATE_DIR" -Z "search-path=$TEMPLATE_DIR/sty/moloch" \
    -Z continue-on-errors -o "$OUT" "main/$f"
done
