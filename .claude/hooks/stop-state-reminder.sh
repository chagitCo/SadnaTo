#!/usr/bin/env bash
# Stop hook: reminds Claude to update docs/ai-dlc/state.md (CORE-02).
# Why: state.md is how the next session resumes; forgetting it is the most common process slip.
# Behavior: if the working tree or the current branch (vs origin/main) changed files but state.md is
# untouched, return additionalContext (non-blocking) so Claude updates it or explains why not.
# Never fires twice in a row (stop_hook_active) and is silent outside a git repository.
set -u

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/json.sh
. "$HOOK_DIR/lib/json.sh"

input="$(cat)"
[ "$(printf '%s' "$input" | json_get_bool stop_hook_active)" = "true" ] && exit 0

root="${CLAUDE_PROJECT_DIR:-$(printf '%s' "$input" | json_get_string cwd)}"
[ -n "$root" ] || exit 0
git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

changed="$(
  {
    git -C "$root" diff --name-only HEAD 2>/dev/null
    git -C "$root" ls-files --others --exclude-standard 2>/dev/null
    base="$(git -C "$root" merge-base HEAD origin/main 2>/dev/null)" && git -C "$root" diff --name-only "$base" HEAD 2>/dev/null
  } | sort -u
)"
[ -z "$changed" ] && exit 0
printf '%s\n' "$changed" | grep -qx 'docs/ai-dlc/state.md' && exit 0

count="$(printf '%s\n' "$changed" | wc -l | tr -d ' ')"
msg="Reminder (CORE-02): ${count} file(s) changed on this branch/working tree but docs/ai-dlc/state.md was not updated. If this work completes a stage or phase, overwrite state.md and append a row to docs/ai-dlc/audit.md; otherwise say why it is not needed yet."
printf '{"hookSpecificOutput":{"hookEventName":"Stop","additionalContext":"%s"}}\n' "$(json_escape "$msg")"
exit 0
