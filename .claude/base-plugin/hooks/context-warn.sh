#!/usr/bin/env bash
# UserPromptSubmit: warn when the session context passes BASE_CONTEXT_WARN (default 150000).
# Reads only the last 200 transcript lines. Fails open (exit 0, no output).
set -u
command -v jq >/dev/null 2>&1 || exit 0

input="$(cat)"
tp="$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)" || exit 0
[ -n "$tp" ] && [ -f "$tp" ] || exit 0

limit="${BASE_CONTEXT_WARN:-150000}"
case "$limit" in ''|*[!0-9]*) limit=150000 ;; esac

# Each line is parsed on its own so a malformed line is skipped, not fatal.
used="$(tail -n 200 "$tp" 2>/dev/null | jq -R -r '
  (try fromjson catch empty)
  | (.message | objects | .usage | objects)
  | (.input_tokens // 0) + (.cache_read_input_tokens // 0) + (.cache_creation_input_tokens // 0)
' 2>/dev/null | tail -n 1)"
case "$used" in ''|*[!0-9]*) exit 0 ;; esac
[ "$used" -ge "$limit" ] || exit 0

jq -n --argjson n "$((used / 1000))" '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:("Context is at ~" + ($n|tostring) + "k tokens. Finish the current step, then rewrite .claude/STATUS.md so a fresh session can resume without asking: Done (what is finished), In progress (exact step, files, half-done state), Next (numbered concrete steps, who does each; copy the FULL plan here or save it to a file and put its path here), Open questions (every unanswered question with its A/B options and your recommendation). Chat text is lost on /clear, so anything only said in chat must be written first. Then tell the user (in Uzbek, one line) to run /clear.")}}'
exit 0
