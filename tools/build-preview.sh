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
#   -j N                concurrency (default: nproc)
#   --template-dir DIR where the template payload lives: "template" for a
#                       course repo (default), "." for this repo itself
#
# Only these 4 driver files are generated (not the full 60-file option x
# theme matrix -- see gen-main.sh), into build/.tex/ rather than main/, and
# they're removed again once the build finishes, so this doesn't leave
# anything behind.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
TEMPLATE_DIR="template"
OUT="build"
GEN_DIR="build/.tex"
JOBS="$(nproc 2>/dev/null || echo 4)"

while [ $# -gt 0 ]; do
  case "$1" in
    -o) OUT="$2"; shift 2 ;;
    -j) JOBS="$2"; shift 2 ;;
    --template-dir) TEMPLATE_DIR="$2"; shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

FILES=(
  presentation_noaufraeumen_mtg.tex
  presentation_noaufraeumen-bright_mtg.tex
  print_students-cover_mtg.tex
  print_solution-cover_mtg.tex
)

cleanup() {
  rm -rf "$GEN_DIR"
}
trap cleanup EXIT

bash "$SCRIPT_DIR/gen-main.sh" "$GEN_DIR" "${FILES[@]}"
mkdir -p "$OUT"

printf '%s\n' "${FILES[@]}" | xargs -P "$JOBS" -I{} \
  tectonic -Z search-path=. -Z "search-path=$TEMPLATE_DIR" -Z "search-path=$TEMPLATE_DIR/sty/moloch" \
    -Z continue-on-errors -o "$OUT" "$GEN_DIR/{}"
