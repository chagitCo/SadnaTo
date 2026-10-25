#!/usr/bin/env bash
# Self-tests for scripts/validate-dlc. Copies the repository (without .git) to a temp dir, checks
# that the clean copy passes, then injects one fault at a time and checks the expected FAIL appears.
# Run: bash scripts/tests/validate-dlc.test.sh
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -r -- "$TMP"' EXIT
(cd "$REPO" && tar --exclude=./.git -cf - .) | (cd "$TMP" && tar -xf -)
V="$TMP/scripts/validate-dlc"
export VALIDATE_DLC_SKIP_JSON=1   # JSON syntax is covered once below; keeps the loop fast

pass=0; fail=0
expect() { # name, expected-exit (0|1), grep pattern ("" = none)
  local name="$1" want="$2" pat="$3" out rc
  out="$(bash "$V" --root "$TMP" 2>&1)"; rc=$?
  if [ "$rc" -ne "$want" ]; then fail=$((fail+1)); echo "FAIL $name: exit $rc, expected $want"; echo "$out" | grep -E '^(FAIL|WARN)' | head -5; return; fi
  if [ -n "$pat" ] && ! printf '%s\n' "$out" | grep -Eq -- "$pat"; then fail=$((fail+1)); echo "FAIL $name: output lacks /$pat/"; echo "$out" | grep -E '^(FAIL|WARN)' | head -5; return; fi
  pass=$((pass+1))
}
mutate() { cp "$TMP/$1" "$TMP/$1.bak"; }
restore() { mv "$TMP/$1.bak" "$TMP/$1"; }

expect "clean copy passes" 0 'validate-dlc: 0 failure'

f=src/backend/CLAUDE.md; mutate $f
for i in $(seq 1 130); do echo "padding line $i" >> "$TMP/$f"; done
expect "line budget exceeded" 1 'FAIL \[budgets\] src/backend/CLAUDE.md has [0-9]+ lines \(budget 120\)'
restore $f

f=db/CLAUDE.md; mutate $f
# DB-05 restated (without its ID) in a folder CLAUDE.md
cat >> "$TMP/$f" <<'EOF'
- Every tenant table has `ENABLE` and `FORCE ROW LEVEL SECURITY` with a policy on `current_setting('app.tenant_id', true)::uuid`, and each routine sets `app.tenant_id` transaction-locally before touching data.
EOF
expect "duplicate rule text" 1 'FAIL \[duplicates\] same rule text'
restore $f

f=docs/standards/frontend-react.md; mutate $f
echo "- **FE-99** Browser code stores tokens in \`localStorage\`, \`sessionStorage\`, IndexedDB or JavaScript-readable cookies; the BFF session cookie is \`__Host-\`, \`Secure\`, \`HttpOnly\`, \`SameSite=Strict\`." >> "$TMP/$f"
expect "contradictory rules (opposite polarity)" 1 'FAIL \[conflicts\] opposite rules'
restore $f

f=docs/standards/backend-csharp.md; mutate $f
echo "- **BE-99** Use EF Core migrations for schema changes in small services." >> "$TMP/$f"
expect "locked-decision conflict phrase" 1 'FAIL \[conflicts\] .*BE-02'
restore $f

f=docs/standards/testing.md; mutate $f
echo "See [missing](does-not-exist.md)." >> "$TMP/$f"
expect "broken link" 1 'FAIL \[links\] docs/standards/testing.md:[0-9]+ -> does-not-exist.md'
restore $f

f=docs/standards/security.md; mutate $f
echo "- **TEST-01** Duplicate definition in the wrong file." >> "$TMP/$f"
expect "duplicate ID definition / wrong home" 1 'FAIL \[rule-ids\] TEST-01 defined (twice|in docs/standards/security.md)'
restore $f

f=checklists/code-review.md; mutate $f
echo "- [ ] Check SEC-77 compliance" >> "$TMP/$f"
expect "unknown rule reference" 1 'FAIL \[rule-ids\] SEC-77 referenced'
restore $f

f=.claude/skills/new-adr/SKILL.md; mutate $f
sed -i 's/^## Checks to run/## Verification/' "$TMP/$f"
expect "skill missing required section" 1 "FAIL \[skills\] .*new-adr/SKILL.md: missing section '## Checks to run'"
restore $f

f=.claude/skills/release/SKILL.md; mutate $f
sed -i 's/^name: release$/name: ship-it/' "$TMP/$f"
expect "skill name differs from folder" 1 "FAIL \[skills\] .*name 'ship-it' must equal folder 'release'"
restore $f

f=.claude/agents/db-reviewer.md; mutate $f
sed -i 's/^tools: Read, Grep, Glob$/tools: Read, Grep, Glob, Edit/' "$TMP/$f"
expect "reviewer with write tool" 1 "FAIL \[agents\] .*db-reviewer.md: reviewer has non-read-only tool 'Edit'"
restore $f

mv "$TMP/.claude/agents/test-reviewer.md" "$TMP/test-reviewer.md.bak"
expect "required subagent missing" 1 'FAIL \[agents\] required subagent missing: .claude/agents/test-reviewer.md'
mv "$TMP/test-reviewer.md.bak" "$TMP/.claude/agents/test-reviewer.md"

f=.claude/settings.json; mutate $f
sed -i '/"Bash(git push --force\*)",/d' "$TMP/$f"
expect "required deny rule missing" 1 'FAIL \[settings\] required deny rule missing: Bash\(git push --force\*\)'
restore $f

f=docs/ai-dlc/VERSION; mutate $f
echo "v1" > "$TMP/$f"
expect "invalid DLC version" 1 "FAIL \[version\] docs/ai-dlc/VERSION 'v1' is not SemVer"
restore $f

mkdir -p "$TMP/db/demo/migrations"
printf 'CREATE FUNCTION api.x() RETURNS int LANGUAGE sql SECURITY DEFINER AS $$ SELECT 1 $$;\n' > "$TMP/db/demo/migrations/R__api.x.sql"
expect "SQL lint: definer without search_path" 1 'FAIL \[sql\] .*SECURITY DEFINER without SET search_path'
rm -r -- "$TMP/db/demo"

mkdir -p "$TMP/src/backend/services/ghost"
expect "service folder not in catalog / no .dlc/version" 1 "FAIL \[catalog\] service 'ghost'"
rmdir "$TMP/src/backend/services/ghost" "$TMP/src/backend/services"

f=docs/adr/0002-data-access-postgresql-functions.md; mutate $f
sed -i 's/^status: Accepted$/status: Maybe/' "$TMP/$f"
expect "invalid ADR status" 1 "FAIL \[adrs\] .*0002-.*invalid or missing status 'Maybe'"
restore $f

# JSON syntax check (runs only when a parser is available).
unset VALIDATE_DLC_SKIP_JSON
f=.claude/settings.json; mutate $f
printf '{ "permissions": { "deny": [ "Read(.env*)", ] }\n' > "$TMP/$f"
out="$(bash "$V" --root "$TMP" 2>&1)"
if printf '%s\n' "$out" | grep -q 'WARN \[settings\] no JSON parser'; then
  echo "SKIP invalid JSON detection (no JSON parser on this machine)"
elif printf '%s\n' "$out" | grep -q 'FAIL \[settings\] .claude/settings.json is not valid JSON'; then
  pass=$((pass+1))
else
  fail=$((fail+1)); echo "FAIL invalid JSON not detected"
fi
restore $f

echo "validate-dlc self-tests: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
