#!/usr/bin/env bash
# PreToolUse guard for the Bash and PowerShell tools.
# Why: permission deny rules match literal command text only (a `cd x && terraform apply` or
# `git -C . push --force` slips past them). This script inspects the whole command and denies the
# actions behind CORE-06, CORE-07 and CORE-13; it asks for confirmation on a few risky-but-legitimate ones.
# Contract: reads hook JSON on stdin; prints a PreToolUse decision JSON or nothing (= no opinion);
# always exits 0. Deterministic, no network. Uses bash builtins (one awk call for JSON) because
# process creation is slow under Git Bash on Windows. Documented in .claude/hooks/README.md.
set -u
set -f   # never glob-expand tokens of the inspected command (e.g. `rm -rf *`)
shopt -s extglob

HOOK_DIR="${BASH_SOURCE[0]%/*}"
# shellcheck source=lib/json.sh
. "$HOOK_DIR/lib/json.sh"

US=$'\037'
fields="$(json_fields tool_name command cwd)"
tool="${fields%%"$US"*}"; rest="${fields#*"$US"}"
raw="${rest%%"$US"*}";   cwd="${rest#*"$US"}"
case "$tool" in Bash|PowerShell) ;; *) exit 0 ;; esac
[ -z "$raw" ] && exit 0

# Normalize: lowercase, whitespace -> single spaces, PowerShell backticks removed.
cmd="${raw,,}"
cmd="${cmd//[$'\n\t\r']/ }"
cmd="${cmd//\`/}"
cmd="${cmd//+( )/ }"

json_str() { local s="${1//\\/\\\\}"; s="${s//\"/\\\"}"; printf '%s' "$s"; }
decide() { # $1 = deny|ask, $2 = reason
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":"%s"}}\n' \
    "$1" "$(json_str "$2")"
  exit 0
}
deny() { decide deny "Blocked by .claude/hooks/guard-command.sh: $1"; }
ask()  { decide ask "Needs human confirmation (guard-command.sh): $1"; }

# --- Secret material referenced anywhere in the command (CORE-07) --------------------------------
re_secret='(^|[ /\\"'"'"'=<:(])\.env([.][^ "'"'"']*)?([ "'"'"')>;|&]|$)|(^|[ /\\"'"'"'])secrets[/\\]|\.(pem|key|pfx|p12)([ "'"'"')>;|&]|$)|id_rsa|id_ed25519'
if [[ " $cmd " =~ $re_secret ]]; then
  deny "command touches secret files (.env*, secrets/, *.pem, *.key, *.pfx, *.p12, SSH keys). CORE-07."
fi

# --- Per simple command ----------------------------------------------------------------------------
split="${cmd//&&/$'\n'}"; split="${split//||/$'\n'}"; split="${split//[;&|]/$'\n'}"
mapfile -t segs <<< "$split"

re_tf=' (apply|destroy|import|taint|untaint|force-unlock) | state (rm|mv|push|replace-provider) '
re_aws_verb=' (create|delete|put|update|modify|terminate|run|start|stop|attach|detach|associate|disassociate|register|deregister|remove|add|tag|untag|reboot|restore|revoke|authorize|set|enable|disable|import|reset|cancel|execute|copy|invoke|publish|send|deploy|rotate|replace|accept|reject|purge|batch|subscribe|unsubscribe|upload|complete|abort|change|request|allocate|release|apply|schedule|admin|initiate|lock|unlock|merge|promote|failover|switchover)(-[a-z0-9-]+)? '
re_aws_other=' s3 (cp|mv|rm|sync|mb|rb) | configure (set|import) '
re_bypass=' --no-verify | --no-gpg-sign | commit\.gpgsign=false '
re_force=' --force(-with-lease[^ ]*|-if-includes)? | -[a-z]*f[a-z]* | \+[^ ]+ | --mirror | --all '
re_main=' (main|master|refs/heads/(main|master)) |:(refs/heads/)?(main|master) '
re_git_ask='^ reset .*--hard | clean (-[a-z]*f|--force)| branch .*-d[a-z]* .*(main|master) '
re_gh_deny=' repo (delete|archive|edit) | (-x|--method) +delete | secret (set|delete) | variable (set|delete) | ruleset '
re_gh_ask=' pr merge | release (create|delete) '
re_host=' -h ?([^ ]+)| --host[= ]([^ ]+)|host=([^ "'"'"']+)|pghost=([^ ]+)|postgres(ql)?://([^/@ ]*@)?([^/:? ]+)'

for seg in "${segs[@]}"; do
  seg="${seg##+( )}"; seg="${seg%%+( )}"
  [ -z "$seg" ] && continue
  s="${seg//[\"\']/}"   # quoting does not change what runs: 'terraform' apply == terraform apply
  # Strip wrappers that do not change meaning: sudo/env/..., VAR=value prefixes, "& " (PowerShell call), "(".
  while :; do
    case "$s" in
      sudo\ *|env\ *|command\ *|exec\ *|time\ *|nohup\ *|xargs\ *) s="${s#* }"; while [[ "$s" == -* ]]; do s="${s#* }"; done ;;
      [a-z_]*([a-z0-9_])=*\ *) s="${s#* }" ;;
      "& "*|"("*) s="${s#?}"; s="${s##+( )}" ;;
      *) break ;;
    esac
  done
  first="${s%% *}"; first="${first##*/}"; first="${first##*\\}"; first="${first%.exe}"

  case "$first" in
    terraform|tofu|terragrunt)
      [[ " $s " =~ $re_tf ]] && deny "terraform state-changing command (apply/destroy/import/state rm...). CORE-06: prepare the plan; a human applies via the GitHub environment."
      ;;
    aws)
      if [[ " $s " =~ $re_aws_verb ]] || [[ " $s " =~ $re_aws_other ]]; then
        deny "AWS write/mutating command. CORE-06: Claude may only run read-only AWS commands (describe/list/get)."
      fi
      ;;
    git)
      [[ " $s " =~ $re_bypass ]] && deny "bypassing git hooks or signing (CORE-13)."
      # Skip global options before the subcommand: git -C dir -c k=v --no-pager push ...
      # (cmd is lowercased, so -C and -c both appear as "-c <arg>").
      sub="${s#git }"
      while [[ "$sub" == -* ]]; do
        case "$sub" in
          "-c "*) sub="${sub#-c }"; sub="${sub#* }" ;;
          *) sub="${sub#* }" ;;
        esac
      done
      verb="${sub%% *}"
      if [ "$verb" = "push" ]; then
        args=" ${sub#push} "
        [[ "$args" =~ $re_force ]] && deny "force-push / mirror / --all push (CORE-06)."
        [[ "$args" =~ $re_main ]] && deny "push to the protected main branch (CORE-06, GIT-01). Push a feature branch and open a PR."
        nonflag=0
        for tok in $args; do [[ "$tok" == -* ]] || nonflag=$((nonflag+1)); done
        if [ "$nonflag" -le 1 ]; then  # no explicit refspec: pushes the current branch
          branch="$(git -C "${cwd:-.}" symbolic-ref --short -q HEAD 2>/dev/null)"
          case "$branch" in main|master) deny "push while on '$branch' without a refspec would update main (CORE-06)." ;; esac
        fi
      fi
      [[ " $sub " =~ $re_git_ask ]] && ask "destructive local git operation (reset --hard / clean -f / delete main)."
      ;;
    rm|remove-item|ri|del|erase|rd|rmdir)
      has_r=0; has_f=0
      for tok in $s; do
        case "$tok" in
          --recursive|-recurse) has_r=1 ;;
          --force|-force) has_f=1 ;;
          --*) ;;
          -*) [[ "$tok" == *r* ]] && has_r=1; [[ "$tok" == *f* ]] && has_f=1 ;;
        esac
      done
      [ "$has_r" = 1 ] && [ "$has_f" = 1 ] && deny "recursive forced delete (rm -rf / Remove-Item -Recurse -Force). CORE-06: ask the human to delete."
      ;;
    psql|pg_prove|pg_dump|pg_dumpall|pg_restore|pgcli|createdb|dropdb)
      rest=" $seg "
      while [[ "$rest" =~ $re_host ]]; do
        h="${BASH_REMATCH[1]}${BASH_REMATCH[2]}${BASH_REMATCH[3]}${BASH_REMATCH[4]}${BASH_REMATCH[7]}"
        h="${h//[\"\']/}"
        case "$h" in
          localhost|127.0.0.1|::1|"[::1]"|/*|"") ;;
          *) deny "database client against non-local host '$h'. Only localhost is allowed for Claude." ;;
        esac
        rest="${rest#*"${BASH_REMATCH[0]}"}"
      done
      ;;
    gh)
      [[ " $s " =~ $re_gh_deny ]] && deny "GitHub repository/settings change via gh. A human changes repository settings."
      [[ " $s " =~ $re_gh_ask ]] && ask "merging a PR or publishing a release."
      ;;
  esac
done

exit 0
