#!/usr/bin/env bash
# PreToolUse(Bash) guard: blocks a git commit / gh pr command whose text carries a Claude signature
# (Co-Authored-By: Claude ... <noreply@anthropic.com>, "Generated with Claude Code", claude.ai/code/session link).
# why: the `attribution` setting is ignored by cloud sessions and some versions, so the user's no-signature rule is enforced here
# too. Runs on the raw command (heredoc bodies included, since commit messages usually live there). Fails open without jq.
# Connects to: hooks.json (registered next to guard-bash/guard-git), cloud-sync.sh (copied into projects).
set -u
command -v jq >/dev/null 2>&1 || exit 0
CMD="$(jq -er '.tool_input.command // empty' 2>/dev/null)" || exit 0
[ -n "$CMD" ] || exit 0

printf '%s\n' "$CMD" | grep -Eq '(^|[^[:alnum:]_-])(git[[:space:]].*commit|gh[[:space:]]+pr[[:space:]]+(create|edit))' || exit 0
if printf '%s\n' "$CMD" | grep -Eiq 'co-authored-by:[^\n]*(claude|anthropic)|noreply@anthropic\.com|generated with[^\n]*claude|claude\.ai/code/session'; then
  echo "no-coauthor: blocked. Remove the Claude signature (Co-Authored-By: Claude, 'Generated with Claude Code', session link) from the commit/PR text and run it again." >&2
  exit 2
fi
exit 0
