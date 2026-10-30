#!/usr/bin/env bash
# Stop: if the reply asks the user a numbered question with lettered options but STATUS.md
# "Open questions" is empty, block once so the model saves it first (chat is lost on /clear).
# Connects to session-start.sh, which injects that section so a bare "1A" has something to match.
# Fails open (exit 0, no output) on any problem; never blocks twice in a row.
set -u
command -v jq >/dev/null 2>&1 || exit 0
command -v git >/dev/null 2>&1 || exit 0

input="$(cat)"
[ "$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null)" = "true" ] && exit 0
msg="$(printf '%s' "$input" | jq -r '.last_assistant_message // empty' 2>/dev/null)" || exit 0
[ -n "$msg" ] || exit 0

# A question = a numbered line ending in "?" plus a lettered option line (A/B/C).
printf '%s\n' "$msg" | grep -Eq '^[[:space:]]*[0-9]+\.[[:space:]].*\?[[:space:]*]*$' || exit 0
printf '%s\n' "$msg" | grep -Eq '^[[:space:]]*([-*][[:space:]]+)?\**[A-C]\**[[:space:]]*([(:)]|\.[[:space:]])' || exit 0

dir="${CLAUDE_PROJECT_DIR:-$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)}"
[ -n "$dir" ] && [ -d "$dir" ] || exit 0
top="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)" || exit 0
f="$top/.claude/STATUS.md"
[ -f "$f" ] && [ ! -L "$f" ] || exit 0

oq="$(awk '/^## Open questions/{s=1;next} /^## /{s=0} s' "$f" | grep -v '^[[:space:]]*$' | grep -v '^(none)' | grep -v '^(decisions waiting for the user)')"
[ -z "$oq" ] || exit 0

jq -n '{decision:"block",reason:"You asked the user a numbered question with lettered options, but .claude/STATUS.md \"Open questions\" is empty. Chat is lost on /clear, so write every question there now with the same numbers, options and your recommendation, then repeat the question to the user."}'
exit 0
