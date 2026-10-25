#!/usr/bin/env bash
# SessionStart hook: prints the top of docs/ai-dlc/state.md so every session starts from the
# recorded position (process.md §5), even if the "Start of every session" steps in CLAUDE.md are skipped.
# Plain stdout from SessionStart is added to Claude's context. Silent if state.md is missing.
set -u
root="${CLAUDE_PROJECT_DIR:-.}"
state="$root/docs/ai-dlc/state.md"
[ -f "$state" ] || exit 0
echo "AI-DLC state (first 25 lines of docs/ai-dlc/state.md):"
head -n 25 "$state"
exit 0
