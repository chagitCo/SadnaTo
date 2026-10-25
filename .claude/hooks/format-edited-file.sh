#!/usr/bin/env bash
# PostToolUse formatter for Edit/Write.
# Why: keeps formatting consistent without spending review time on whitespace (BE-01 analyzers and
# Prettier settings stay the single source of style). Formats only the edited file, only with a
# formatter that is already installed for that project, and never fails the tool call.
# Contract: reads hook JSON on stdin; exit 0 = done/skipped; exit 1 = formatter error (non-blocking notice).
set -u

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/json.sh
. "$HOOK_DIR/lib/json.sh"

input="$(cat)"
file="$(printf '%s' "$input" | json_get_string file_path)"
[ -z "$file" ] && exit 0

# Windows paths arrive with backslashes; convert when running under Git Bash.
if command -v cygpath >/dev/null 2>&1; then file="$(cygpath -u "$file")"; fi
root="${CLAUDE_PROJECT_DIR:-$(printf '%s' "$input" | json_get_string cwd)}"
if [ -n "$root" ] && command -v cygpath >/dev/null 2>&1; then root="$(cygpath -u "$root")"; fi

# Only files inside the project, no traversal, file must exist.
case "$file" in *"/../"*|*"/.."|"../"*) exit 0 ;; esac
case "$file" in "$root"/*) ;; *) exit 0 ;; esac
[ -f "$file" ] || exit 0

# Walk up from the file's directory (not above the project root) looking for a marker.
find_up() { # $1 = start dir, $2 = glob or path to test
  local d="$1"
  while [ -n "$d" ] && [ "$d" != "/" ]; do
    # shellcheck disable=SC2086
    for m in $d/$2; do [ -e "$m" ] && { printf '%s' "$m"; return 0; }; done
    [ "$d" = "$root" ] && break
    d="$(dirname "$d")"
  done
  return 1
}

dir="$(dirname "$file")"
case "$file" in
  *.cs|*.csproj|*.props|*.targets)
    command -v dotnet >/dev/null 2>&1 || exit 0
    proj="$(find_up "$dir" '*.csproj')" || exit 0
    projdir="$(dirname "$proj")"
    rel="${file#"$projdir"/}"
    if ! (cd "$projdir" && dotnet format whitespace "$(basename "$proj")" --include "$rel" --verbosity quiet) >/dev/null 2>&1; then
      echo "dotnet format failed for $rel (non-blocking); run 'dotnet format' in $projdir" >&2
      exit 1
    fi
    ;;
  *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.json|*.css|*.scss|*.html|*.yml|*.yaml|*.md)
    prettier="$(find_up "$dir" 'node_modules/.bin/prettier')" || exit 0
    if ! "$prettier" --write --log-level warn "$file" >/dev/null 2>&1; then
      echo "prettier failed for $file (non-blocking)" >&2
      exit 1
    fi
    ;;
esac
exit 0
