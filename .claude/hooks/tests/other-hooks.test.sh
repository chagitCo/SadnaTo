#!/usr/bin/env bash
# Tests for stop-state-reminder.sh, session-start.sh and format-edited-file.sh.
# Run: bash .claude/hooks/tests/other-hooks.test.sh
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS="$HERE/.."
pass=0; fail=0
check() { # name, condition-result (0 = ok), detail
  if [ "$2" -eq 0 ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL $1: $3"; fi
}

REPO="$(mktemp -d)"
trap 'rm -r -- "$REPO"' EXIT
git -C "$REPO" init -q -b main 2>/dev/null || { git -C "$REPO" init -q && git -C "$REPO" checkout -q -b main; }
git -C "$REPO" config user.email t@example.invalid; git -C "$REPO" config user.name t
mkdir -p "$REPO/docs/ai-dlc"; printf '# AI-DLC State\n- Current phase: test\n' > "$REPO/docs/ai-dlc/state.md"
git -C "$REPO" add -A; git -C "$REPO" commit -q -m init

stop() { printf '{"hook_event_name":"Stop","stop_hook_active":%s,"cwd":"%s"}' "$1" "$REPO" | CLAUDE_PROJECT_DIR="$REPO" bash "$HOOKS/stop-state-reminder.sh"; }

out="$(stop false)"; [ -z "$out" ]; check "stop: clean tree is silent" $? "$out"
echo "x" > "$REPO/code.txt"
out="$(stop false)"; [[ "$out" == *'"additionalContext"'*'state.md'* ]]; check "stop: change without state.md reminds" $? "$out"
out="$(stop true)"; [ -z "$out" ]; check "stop: stop_hook_active suppresses" $? "$out"
echo "- updated" >> "$REPO/docs/ai-dlc/state.md"
out="$(stop false)"; [ -z "$out" ]; check "stop: state.md changed is silent" $? "$out"

out="$(CLAUDE_PROJECT_DIR="$REPO" bash "$HOOKS/session-start.sh" < /dev/null)"
[[ "$out" == *"Current phase: test"* ]]; check "session-start prints state header" $? "$out"
out="$(CLAUDE_PROJECT_DIR="$REPO/missing" bash "$HOOKS/session-start.sh" < /dev/null)"
[ -z "$out" ]; check "session-start silent without state.md" $? "$out"

fmt() { printf '{"hook_event_name":"PostToolUse","tool_name":"Write","cwd":"%s","tool_input":{"file_path":"%s"}}' "$REPO" "$1" | CLAUDE_PROJECT_DIR="$REPO" bash "$HOOKS/format-edited-file.sh"; }
echo 'class A{}' > "$REPO/A.cs"
fmt "$REPO/A.cs"; rc=$?; [ "$rc" -eq 0 ]; check "format: .cs without project/SDK is a no-op" $? "rc=$rc"
fmt "$REPO/../outside.ts"; rc=$?; [ "$rc" -eq 0 ]; check "format: path traversal ignored" $? "rc=$rc"
fmt "/etc/hosts"; rc=$?; [ "$rc" -eq 0 ]; check "format: file outside project ignored" $? "rc=$rc"
fmt "$REPO/nope.md"; rc=$?; [ "$rc" -eq 0 ]; check "format: missing file ignored" $? "rc=$rc"

echo "other hook tests: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
