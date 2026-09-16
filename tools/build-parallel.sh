#!/bin/bash
# Regenerate main/*.tex from the template's option matrix, then build all
# of them. Run from a course repo's root (template mounted at ./template).
#
# Concurrency is bounded to the core count. Launching all 39 builds at once
# (the previous behaviour) oversubscribes a 16-core box by ~2.4x and measured
# ~12% SLOWER end-to-end (198s vs 174s for the full matrix), with a ~9 GB
# peak memory spike (each build peaks around 240 MB RSS).
#
#   -j N      concurrency (default: nproc)
#   --draft   single TeX pass per file: ~3x faster, but cross-references,
#             the table of contents and beamer navigation are NOT converged
#             (page counts can be off by one). Use for a quick look, never
#             for anything you hand out or publish.
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
OUT="main/pdfs"
JOBS="$(nproc 2>/dev/null || echo 4)"
REPASS=""

while [ $# -gt 0 ]; do
  case "$1" in
    -j) JOBS="$2"; shift 2 ;;
    --draft) REPASS="-r 0"; shift ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

bash "$SCRIPT_DIR/gen-main.sh" main
mkdir -p "$OUT"

ls main/*.tex | xargs -P "$JOBS" -I{} \
  tectonic -Z search-path=. -Z search-path=template -Z search-path=template/sty/moloch \
    -Z continue-on-errors $REPASS -o "$OUT" {}
rc=$?

# Clean up TeX aux/log droppings left across the repo.
find . -type f \( -name "*.aux" -o -name "*.log" -o -name "*.nav" -o -name "*.out" \
  -o -name "*.snm" -o -name "*.toc" -o -name "*.atfi" -o -name "*.fls" \
  -o -name "*.fdb_latexmk" -o -name "*.synctex.gz" -o -name "*.bbl" -o -name "*.blg" \) -delete

exit "$rc"
