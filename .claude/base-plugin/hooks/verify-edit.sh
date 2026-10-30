#!/usr/bin/env bash
# PostToolUse(Edit|Write|MultiEdit): fast local syntax-only check of the edited file, chosen by extension
# (sh/bash, json, py, js/mjs/cjs, go, rs, dart; go/rs/dart only when gofmt/rustfmt/dart exist). On failure exits 2 with the error on stderr: per code.claude.com/docs/en/hooks,
# PostToolUse exit 2 "shows stderr to Claude; the tool already ran". Fails open (exit 0, silent) on missing jq,
# interpreter, file, bad input or a path outside the project dir. A failed tool call fires PostToolUseFailure, not
# PostToolUse, and tool_response has no documented success field, so only tool_input.file_path is read. Never writes or logs anything to disk.
set -u
command -v jq >/dev/null 2>&1 || exit 0

input="$(cat)"
fp="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)" || exit 0
[ -n "$fp" ] || exit 0

[ -f "$fp" ] && [ ! -L "$fp" ] || exit 0

# Project boundary: resolved dir of the file must be inside CLAUDE_PROJECT_DIR (or cwd).
proj="$(cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null && pwd -P)" || exit 0
fdir="$(cd "$(dirname -- "$fp")" 2>/dev/null && pwd -P)" || exit 0
case "$fdir/" in "$proj"/*) ;; *) exit 0 ;; esac

# run_capped <cmd...>: 10s cap via timeout/gtimeout, else perl alarm, else uncapped. Output on stdout+stderr.
run_capped() {
  if command -v timeout >/dev/null 2>&1; then timeout 10 "$@" 2>&1
  elif command -v gtimeout >/dev/null 2>&1; then gtimeout 10 "$@" 2>&1
  elif command -v perl >/dev/null 2>&1; then perl -e 'alarm 10; exec @ARGV or exit 127' -- "$@" 2>&1
  else "$@" 2>&1
  fi
}

# False-positive guards: JSONC-style configs (tsconfig/jsconfig, .vscode/, .devcontainer/) allow comments and
# trailing commas; .sh/.bash files with a non-bash shebang (zsh, fish, ksh, python...) are not bash syntax.
base="${fp##*/}"
case "/$fp" in */.vscode/*|*/.devcontainer/*) exit 0 ;; esac
ext="${fp##*.}"
case "$ext" in
  sh|bash)
    first="$(head -n 1 -- "$fp" 2>/dev/null | tr -d '\r')"
    case "$first" in
      '#!'*) case "$first" in *bash*|*/sh|*/sh\ *|*'env sh'*|*'env -S sh'*) ;; *) exit 0 ;; esac ;;
    esac
    cmd=(bash -n -- "$fp") ;;
  json) case "$base" in tsconfig*.json|jsconfig*.json) exit 0 ;; esac
      cmd=(jq empty -- "$fp") ;;
  py) command -v python3 >/dev/null 2>&1 || exit 0
      cmd=(python3 -I -c "import ast,sys; ast.parse(open(sys.argv[1],'rb').read())" "$fp") ;;
  js|mjs|cjs) command -v node >/dev/null 2>&1 || exit 0
      cmd=(node --check -- "$fp") ;;
  go) command -v gofmt >/dev/null 2>&1 || exit 0
      cmd=(gofmt -e -l "$fp") ;;
  rs) command -v rustfmt >/dev/null 2>&1 || exit 0 # stdin: no sibling `mod x;` files are pulled in
      cmd=(bash -c 'rustfmt --edition 2021 --emit stdout <"$1" >/dev/null' _ "$fp") ;;
  dart) command -v dart >/dev/null 2>&1 || exit 0
      cmd=(dart format --output=none "$fp") ;;
  *) exit 0 ;;
esac

res="$(run_capped "${cmd[@]}")"
rc=$?
[ "$rc" -eq 0 ] && exit 0
# 124 = timeout, 127 = checker missing, 142/143 = alarm/terminated: not a syntax verdict, fail open.
case "$rc" in 124|127|142|143) exit 0 ;; esac
printf 'Syntax check failed for %s:\n%s\n' "$fp" "$(printf '%s\n' "$res" | head -n 20)" >&2
exit 2
