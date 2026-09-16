#!/bin/bash
# One-time setup for a course repo that consumes this template as a
# submodule at ./template. Run once after cloning (or after `git submodule
# add`). Defuses the two git-submodule footguns for a workflow where the
# template is edited live from inside a course repo:
#
#  1. Detached HEAD: `git submodule update --remote` alone checks out a
#     commit, not a branch. A fix committed there is an orphaned commit
#     that `git push` from inside template/ won't publish anywhere.
#     `submodule.<name>.update merge` keeps `--remote` landing ON the
#     configured branch instead.
#
#  2. Push order: pushing the course repo before the submodule leaves its
#     pinned commit unfetchable for everyone else. `push.recurseSubmodules
#     on-demand` makes git push the submodule first, automatically.
#
# Usage: template/tools/init-course.sh   (run from the course repo root)
set -euo pipefail

git config submodule.template.update merge
git config push.recurseSubmodules on-demand
git config submodule.recurse true
git config status.submodulesummary 1

echo "Configured. The template submodule now:"
echo "  - stays on its tracking branch after 'git submodule update --remote'"
echo "  - is pushed automatically before the course repo, in the right order"
echo "  - updates automatically on 'git pull' in the course repo"
