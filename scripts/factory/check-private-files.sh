#!/usr/bin/env bash
# Fails if a tracked file is one that must never reach this public
# repository: local agent context under .claude/ outside the committed
# allowlist, git bundles, archives, or session handoff notes.
#
# Why it exists: .gitignore keeps these out of a normal `git add`, but not
# out of `git add -f` or a loosened pattern. A git bundle can carry a
# repository's whole history, so one slip is not undoable once pushed.
# Run it before pushing; CI runs it on every pull request as a backstop.
#
# Usage: scripts/factory/check-private-files.sh   (from anywhere in the repo)
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

# The only .claude/ paths that may be committed. Keep in step with .gitignore.
allowed_claude='^\.claude/(settings\.json|skills/.+|agents/.+)$'

# Files that are never committed anywhere in the tree.
forbidden='(\.bundle|\.tar|\.tar\.gz|\.tgz|\.zip|\.7z)$|(^|/)handoffs/'

bad=0
while IFS= read -r -d '' path; do
  reason=""
  if [[ "$path" == .claude/* ]] && ! [[ "$path" =~ $allowed_claude ]]; then
    reason="under .claude/ but not in the allowlist (settings.json, skills/, agents/)"
  elif [[ "$path" =~ $forbidden ]]; then
    reason="archive, bundle or handoff note"
  fi
  if [[ -n "$reason" ]]; then
    echo "::error file=$path::$path is tracked: $reason. Remove it with 'git rm --cached' and keep it outside the repository."
    bad=1
  fi
done < <(git ls-files -z)

if [[ "$bad" -ne 0 ]]; then
  echo "Private files are tracked; see the errors above." >&2
  exit 1
fi
echo "check-private-files: no private files tracked."
