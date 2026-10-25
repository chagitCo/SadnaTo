# Claude Code hooks and permissions

Configured in [`.claude/settings.json`](../settings.json) (committed, shared by the team).
Personal overrides go in `.claude/settings.local.json` (gitignored). Conventions verified against
https://code.claude.com/docs/en/hooks, /settings and /permissions on 2026-10-25.

**Why both deny rules and hooks?** Permission rules match the literal command text, so
`cd infra && terraform apply` or `git -C . push --force` are not caught by `Bash(terraform apply*)`
or `Bash(git push --force*)` in every form (Claude Code docs, "what a Bash rule doesn't match").
Deny rules stop the common forms instantly; the PreToolUse guard parses the whole command.
Neither is a security boundary against a determined human; they stop accidental AI actions.

## Hooks

| Event | Script | Why it exists | Behavior | Speed |
|---|---|---|---|---|
| `PreToolUse` (Bash, PowerShell) | [guard-command.sh](guard-command.sh) | Enforce CORE-06 (no apply/destroy, AWS writes, push to main, force-push, `rm -rf`, non-local DB clients), CORE-07 (secret files) and CORE-13 (no `--no-verify`) | Prints a `deny` or `ask` decision with the reason; prints nothing otherwise. `onFailure: block` makes it fail closed if the script errors or times out | ~90 ms per call (measured on Windows/Git Bash) |
| `PostToolUse` (Edit, Write, MultiEdit) | [format-edited-file.sh](format-edited-file.sh) | Consistent formatting without review noise | Formats only the edited file: `.cs` via `dotnet format whitespace` for the nearest project, web files via the project's own Prettier. Skips silently if the formatter isn't installed, the file is outside the project or the path has `..`. Never blocks | No-op when tools are absent; formatter time otherwise |
| `Stop` | [stop-state-reminder.sh](stop-state-reminder.sh) | CORE-02: the next session resumes from `state.md` | If files changed (working tree or branch vs `origin/main`) and `docs/ai-dlc/state.md` didn't, returns non-blocking `additionalContext` asking Claude to update it or say why not. Silent when `stop_hook_active` is true | < 200 ms |
| `SessionStart` | [session-start.sh](session-start.sh) | process.md §5: start every session from the recorded position | Prints the first 25 lines of `state.md` into context | < 50 ms |

All scripts are bash, read the hook JSON from stdin without requiring `jq` (it's used if present)
and make no network calls. On Windows they run in Git Bash, which Claude Code uses for hooks
by default when it is installed.

### What the guard decides

| Decision | Commands |
|---|---|
| deny | `terraform`/`tofu`/`terragrunt` `apply`, `destroy`, `import`, `taint`, `state rm/mv/push`; `aws` mutating verbs (`create-*`, `delete-*`, `put-*`, `update-*`, `run-*`, `invoke`, `publish`, `deploy`, `s3 cp/mv/rm/sync`, …); `git push` with `--force*`, `-f`, `+refspec`, `--mirror`, `--all`, to `main`/`master`, or with no refspec while on `main`; `--no-verify`, `--no-gpg-sign`, `commit.gpgsign=false`; `rm`/`Remove-Item` with recursive + force; `psql`/`pg_*` with a host other than localhost/127.0.0.1/::1/socket; `gh repo delete/edit`, `gh api -X DELETE`, `gh secret/variable set`; any command mentioning `.env*`, `secrets/`, `*.pem`, `*.key`, `*.pfx`, `*.p12`, SSH private keys |
| ask | `git reset --hard`, `git clean -f`, deleting `main`; `gh pr merge`; `gh release create/delete` |

Known false positives (by design, conservative): a shell command that merely *mentions* `.env`
(for example `grep -r ".env" docs`). Use the Grep tool or the Edit tool instead.

## Permission rules (summary)

| List | Purpose |
|---|---|
| `deny` | Read of `.env*`, `**/secrets/**`, `*.pem`, `*.key`, `*.pfx`, `*.p12` (a Read deny also blocks Edit/Write of those paths); common literal forms of the guarded commands for Bash and PowerShell |
| `ask` | `git push` (outward-facing) and `gh pr merge` |
| `allow` | Validation scripts and tests, `dotnet build/test/format`, `npm run lint/typecheck`, `npm test`, `terraform fmt/validate`, `tflint` (project `allow` rules apply after workspace trust) |

## Tests

```bash
bash .claude/hooks/tests/guard-command.test.sh   # 94 cases: deny/ask/allow per command
bash .claude/hooks/tests/other-hooks.test.sh     # stop reminder, session start, formatter skips
```

`scripts/validate-dlc` checks that `settings.json` is valid JSON (when a JSON parser is available)
and that every hook script it references exists.

## Changing a hook

Keep hooks fast (< 1 s), deterministic and offline. Update this README and the tests in the same
PR, and add a line to `docs/ai-dlc/CHANGELOG.md`. Changes to `.claude/**` need a DLC maintainer's
approval (CR-05).
