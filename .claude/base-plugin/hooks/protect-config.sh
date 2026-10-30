#!/usr/bin/env bash
# PreToolUse(Edit|Write|MultiEdit): ask before touching lint/format/test configs.
# Fails open (exit 0, no output) on missing jq or bad input.
set -u
command -v jq >/dev/null 2>&1 || exit 0

input="$(cat)"
fp="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)" || exit 0
[ -n "$fp" ] || exit 0

base="${fp##*/}"
rest="${fp%/*}"
parent="${rest##*/}"

hit=0
case "$base" in
  .eslintrc*|eslint.config.*|.prettierrc*|prettier.config.*|biome.json*|jest.config.*|vitest.config.*) hit=1 ;;
  ruff.toml|.ruff.toml|.flake8|mypy.ini|.pylintrc|pytest.ini) hit=1 ;;
  .golangci.y*ml|rustfmt.toml|.rustfmt.toml|clippy.toml) hit=1 ;;
  .pre-commit-config.yaml|lefthook.y*ml) hit=1 ;;
esac
[ "$hit" = 0 ] && [ "$parent" = ".husky" ] && hit=1
[ "$hit" = 1 ] || exit 0

jq -n '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:"Editing a lint/format/test config. Only proceed if the user asked for it — never to make a failing check pass."}}'
exit 0
