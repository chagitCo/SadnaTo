#!/usr/bin/env bash
# Tests for .claude/hooks/guard-command.sh. Run: bash .claude/hooks/tests/guard-command.test.sh
# Each case: expected decision (deny|ask|allow) | tool | command
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUARD="$HERE/../guard-command.sh"
# shellcheck source=../lib/json.sh
. "$HERE/../lib/json.sh"

# A throwaway git repo on branch main, to test "push without refspec while on main".
TMP="$(mktemp -d)"
trap 'rm -r -- "$TMP"' EXIT
git -C "$TMP" init -q -b main 2>/dev/null || { git -C "$TMP" init -q && git -C "$TMP" checkout -q -b main; }
FEAT="$(mktemp -d)"
trap 'rm -r -- "$TMP" "$FEAT"' EXIT
git -C "$FEAT" init -q -b feat/x 2>/dev/null || { git -C "$FEAT" init -q && git -C "$FEAT" checkout -q -b feat/x; }

pass=0; fail=0
run_case() { # expected tool cwd command
  local expected="$1" tool="$2" cwd="$3" command="$4" out got
  out="$(printf '{"session_id":"t","cwd":"%s","hook_event_name":"PreToolUse","tool_name":"%s","tool_input":{"command":"%s","description":"test"}}' \
        "$(json_escape "$cwd")" "$tool" "$(json_escape "$command")" | bash "$GUARD")"
  case "$out" in
    *'"permissionDecision":"deny"'*) got=deny ;;
    *'"permissionDecision":"ask"'*)  got=ask ;;
    "") got=allow ;;
    *) got="unexpected:$out" ;;
  esac
  if [ "$got" = "$expected" ]; then pass=$((pass+1)); else fail=$((fail+1)); printf 'FAIL expected=%-5s got=%-5s %s: %s\n' "$expected" "$got" "$tool" "$command"; fi
}

while IFS='|' read -r expected tool where command; do
  case "$expected" in ''|\#*) continue ;; esac
  case "$where" in main) cwd="$TMP" ;; feat) cwd="$FEAT" ;; *) cwd="$FEAT" ;; esac
  run_case "$expected" "$tool" "$cwd" "$command"
done <<'CASES'
# --- terraform (CORE-06)
deny|Bash|feat|terraform apply
deny|Bash|feat|terraform apply -auto-approve tfplan
deny|Bash|feat|cd infra/live/dev/network && terraform destroy
deny|Bash|feat|terraform -chdir=infra/live/dev apply
deny|Bash|feat|TF_LOG=debug terraform apply
deny|Bash|feat|terraform state rm aws_s3_bucket.x
deny|Bash|feat|/usr/local/bin/terraform import aws_vpc.main vpc-123
deny|PowerShell|feat|terraform.exe apply
deny|Bash|feat|'terraform' apply
deny|Bash|feat|git 'push' origin main
deny|Bash|feat|"rm" -rf build
allow|Bash|feat|terraform plan -out=tfplan
allow|Bash|feat|terraform fmt -recursive -check
allow|Bash|feat|terraform validate
allow|Bash|feat|terraform init -backend=false
# --- aws (CORE-06)
deny|Bash|feat|aws s3 rm s3://bucket/key
deny|Bash|feat|aws s3 sync ./dist s3://bucket
deny|Bash|feat|aws ec2 terminate-instances --instance-ids i-123
deny|Bash|feat|aws ecs update-service --cluster c --service s --force-new-deployment
deny|Bash|feat|aws lambda invoke --function-name f out.json
deny|Bash|feat|aws sns publish --topic-arn arn:x --message hi
deny|Bash|feat|aws cloudformation deploy --stack-name s --template-file t.yml
deny|Bash|feat|AWS_PROFILE=prod aws iam create-user --user-name x
deny|PowerShell|feat|aws rds delete-db-instance --db-instance-identifier db1
allow|Bash|feat|aws sts get-caller-identity
allow|Bash|feat|aws ec2 describe-vpcs --region eu-central-1
allow|Bash|feat|aws s3 ls s3://bucket
allow|Bash|feat|aws logs tail /ecs/projects --since 1h
allow|Bash|feat|aws cloudwatch get-metric-data --start-time 2026-10-25T00:00:00Z --end-time 2026-10-25T01:00:00Z --metric-data-queries file://q.json
# --- git push (CORE-06)
deny|Bash|feat|git push --force
deny|Bash|feat|git push -f origin feat/x
deny|Bash|feat|git push origin feat/x --force-with-lease
deny|Bash|feat|git push -uf origin feat/x
deny|Bash|feat|git push origin +feat/x
deny|Bash|feat|git push origin main
deny|Bash|feat|git push -u origin main
deny|Bash|feat|git push origin HEAD:main
deny|Bash|feat|git push origin feat/x:refs/heads/main
deny|Bash|feat|git -C . push origin main
deny|Bash|feat|git push --mirror
deny|Bash|feat|git add . && git commit -m wip && git push origin master
deny|Bash|main|git push
deny|Bash|main|git push origin
allow|Bash|feat|git push
allow|Bash|feat|git push -u origin feat/ai-dlc-phase-2
allow|Bash|feat|git push origin feat/maintenance
allow|Bash|feat|git push --follow-tags origin feat/x
# --- hooks/signing bypass (CORE-13)
deny|Bash|feat|git commit --no-verify -m x
deny|Bash|feat|git -c commit.gpgsign=false commit -m x
deny|Bash|feat|git push --no-verify origin feat/x
allow|Bash|feat|git commit -m "feat(projects): assign task"
# --- risky local git (ask)
ask|Bash|feat|git reset --hard HEAD~1
ask|Bash|feat|git clean -fdx
allow|Bash|feat|git reset --soft HEAD~1
allow|Bash|feat|git status --short
# --- rm -rf (CORE-06)
deny|Bash|feat|rm -rf build
deny|Bash|feat|rm -fr /tmp/x
deny|Bash|feat|rm -r -f node_modules
deny|Bash|feat|rm --recursive --force dist
deny|Bash|feat|cd src && rm -Rf *
deny|Bash|feat|sudo rm -rf /
deny|PowerShell|feat|Remove-Item -Recurse -Force .\dist
deny|PowerShell|feat|rm -Recurse -Force C:\temp\x
allow|Bash|feat|rm -f out.txt
allow|Bash|feat|rm build.log
allow|PowerShell|feat|Remove-Item .\out.txt
# --- database clients against non-local hosts
deny|Bash|feat|psql -h prod-db.abc123.eu-central-1.rds.amazonaws.com -U app projects
deny|Bash|feat|psql --host=10.0.1.5 -U postgres
deny|Bash|feat|psql "host=db.internal dbname=projects user=x"
deny|Bash|feat|psql postgresql://app@db.example.com:5432/projects
deny|Bash|feat|PGHOST=db.example.com psql -U x
deny|Bash|feat|pg_dump -h staging-db.internal projects
allow|Bash|feat|psql -h localhost -U postgres -d projects
allow|Bash|feat|psql -h 127.0.0.1 -U postgres -c "select 1"
allow|Bash|feat|psql postgresql://postgres@localhost:5432/projects
allow|Bash|feat|pg_prove -h localhost -U postgres -d projects db/projects/tests/tasks.test.sql
allow|Bash|feat|psql -U postgres -d projects
# --- secrets (CORE-07)
deny|Bash|feat|cat .env
deny|Bash|feat|cat src/backend/.env.local
deny|Bash|feat|grep PASSWORD config/.env.production
deny|Bash|feat|cat infra/secrets/db.txt
deny|Bash|feat|openssl x509 -in cert.pem -noout
deny|PowerShell|feat|Get-Content .\.env
deny|PowerShell|feat|type C:\keys\server.key
allow|Bash|feat|echo $HOME
allow|PowerShell|feat|Write-Output $env:PATH
allow|Bash|feat|node -e "console.log(process.env.NODE_ENV)"
# --- gh
deny|Bash|feat|gh repo delete chagitCo/SadnaTo --yes
deny|Bash|feat|gh api -X DELETE repos/chagitCo/SadnaTo/branches/main/protection
deny|Bash|feat|gh secret set AWS_KEY --body x
ask|Bash|feat|gh pr merge 3 --squash
allow|Bash|feat|gh pr create --base main --head feat/x --title t --body b
allow|Bash|feat|gh pr view 2 --json state
# --- unrelated tools and harmless commands
allow|Bash|feat|ls -la
allow|Bash|feat|dotnet test --filter Category!=Integration
allow|Bash|feat|npm run build
CASES

# Non-shell tools are ignored entirely.
out="$(printf '{"tool_name":"Write","tool_input":{"file_path":"/x/.env","content":"terraform apply"}}' | bash "$GUARD")"
if [ -z "$out" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL Write tool should be ignored: $out"; fi

echo "guard-command tests: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
