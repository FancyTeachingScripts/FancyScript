#!/bin/bash
# Regenerates main/*.tex from tools/options.conf.
#
# Each course repo runs this (via tools/build.sh, or directly) to produce
# its 39 option x theme driver files. They are NOT checked in -- add
# main/ to the course repo's .gitignore. Regenerating instead of hand-editing
# is what makes the typo drift the old checked-in copies had (IMPROTIEREN,
# LUALATEX, ...) structurally impossible: fix it once here, every course
# gets it on its next build.
#
# Usage: tools/gen-main.sh [output-dir] [filename...]
#   (output-dir default: main/, relative to CWD)
# With filenames given (e.g. presentation_full.tex), only those driver
# files are (re)generated instead of the full option x theme matrix --
# for callers that only need a handful, like build-preview.sh.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
CONF="$SCRIPT_DIR/options.conf"
OUT="${1:-main}"
shift || true

declare -A WANT=()
for f in "$@"; do WANT["$f"]=1; done

mkdir -p "$OUT"

# Read option lines (before the "[themes]" marker) and theme lines (after).
mapfile -t OPTION_LINES < <(sed -n '/^\[themes\]/q;/^#/d;/^$/d;p' "$CONF")
mapfile -t THEMES < <(sed -n '/^\[themes\]/,$p' "$CONF" | sed '1d;/^#/d;/^$/d')

gen_one() {
  local opt_id="$1" theme="$2" outfile="$3"
  local theme_line
  if [ "$theme" = "default" ]; then
    theme_line="%\\SetTheme{mtg}"
  else
    theme_line="\\SetTheme{${theme}}"
  fi

  {
    echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
    echo '% Optionen festlegen '
    echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
    echo '\RequirePackage['
    for line in "${OPTION_LINES[@]}"; do
      local id="${line%%|*}"
      local desc="${line#*|}"
      if [ "$id" = "$opt_id" ]; then
        printf '     %-34s %% %s\n' "$id" "$desc"
      else
        printf '    %% %-32s %% %s\n' "$id" "$desc"
      fi
    done
    echo ']{sty/MainPackage}'
    echo
    echo "$theme_line"
    echo
    echo
    echo
    echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
    echo '% HIER DIE INHALTE EINFÜGEN ODER IMPORTIEREN (empfohlen)'
    echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
    echo
    echo '\input{selected}'
    echo
    echo
    echo '%%%%%%%%%%%%%%%%%%%%%%'
    echo '% Hier nichts ändern !'
    echo '%%%%%%%%%%%%%%%%%%%%%%'
    echo '\begin{document}'
    echo '\end{document}'
    echo
    echo
    echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
    echo '% !!! IMMER MIT TECTONIC (XELATEX) KOMPILIEREN !!!'
    printf '%s' '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
  } > "$OUT/$outfile"
}

count=0
for line in "${OPTION_LINES[@]}"; do
  opt_id="${line%%|*}"
  for theme in "${THEMES[@]}"; do
    # main/<prefix>_<option-without-first-segment>[_theme].tex naming:
    # presentation-full -> presentation_full ; print-students-cover -> print_students-cover
    prefix="${opt_id%%-*}"
    rest="${opt_id#*-}"
    base="${prefix}_${rest}"
    if [ "$theme" = "default" ]; then
      outfile="${base}.tex"
    else
      outfile="${base}_${theme}.tex"
    fi
    if [ "${#WANT[@]}" -gt 0 ] && [ -z "${WANT[$outfile]:-}" ]; then
      continue
    fi
    gen_one "$opt_id" "$theme" "$outfile"
    count=$((count+1))
  done
done
echo "gen-main.sh: wrote $count files to $OUT/"
