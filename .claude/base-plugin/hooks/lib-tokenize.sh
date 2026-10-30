#!/usr/bin/env bash
# Shared quote-aware shell tokenizer, sourced by guard-git.sh and guard-bash.sh (one copy, never duplicated).
# tokenize <string> fills the array TOK with words (quotes removed); SEP marks the boundary between simple
# commands, PIPE marks a segment whose stdin is a pipe, HERE a here-string/heredoc operator. strip_heredocs drops heredoc bodies. Pure bash, no I/O.
SEP=$'\001'
PIPE=$'\002' # marks a segment whose stdin is a pipe
HERE=$'\003' # marks a here-string / heredoc operator inside a segment

# tokenize <string>: fills TOK with words (quotes removed); SEP marks the boundary between simple commands.
tokenize() {
  local s="$1" i=0 n=${#1} c nx q="" cur="" has=0
  TOK=()
  while [ "$i" -lt "$n" ]; do
    c="${s:$i:1}"; i=$((i + 1))
    if [ "$q" = "'" ]; then
      if [ "$c" = "'" ]; then q=""; else cur="$cur$c"; fi
      continue
    fi
    if [ "$q" = '"' ]; then
      case "$c" in
        '"') q="" ;;
        '\')
          nx="${s:$i:1}"
          case "$nx" in
            '"'|'\'|'$'|'`') cur="$cur$nx"; i=$((i + 1)) ;;
            *) cur="$cur$c" ;;
          esac ;;
        *) cur="$cur$c" ;;
      esac
      continue
    fi
    case "$c" in
      "'") q="'"; has=1 ;;
      '"') q='"'; has=1 ;;
      '\')
        nx="${s:$i:1}"; i=$((i + 1))
        [ "$nx" = $'\n' ] || { cur="$cur$nx"; has=1; } ;;
      ' '|$'\t')
        [ "$has" = 1 ] && { TOK+=("$cur"); cur=""; has=0; } ;;
      '|')
        [ "$has" = 1 ] && { TOK+=("$cur"); cur=""; has=0; }
        TOK+=("$SEP")
        case "${s:$i:1}" in
          '|') i=$((i + 1)) ;;
          '&') i=$((i + 1)); TOK+=("$PIPE") ;;
          *) TOK+=("$PIPE") ;;
        esac ;;
      '<')
        [ "$has" = 1 ] && { TOK+=("$cur"); cur=""; has=0; }
        if [ "${s:$i:1}" = "<" ]; then
          while [ "${s:$i:1}" = "<" ]; do i=$((i + 1)); done
          TOK+=("$HERE")
        else
          TOK+=("$SEP")
        fi ;;
      ';'|'&'|'('|')'|'`'|'>'|$'\n')
        [ "$has" = 1 ] && { TOK+=("$cur"); cur=""; has=0; }
        TOK+=("$SEP") ;;
      *) cur="$cur$c"; has=1 ;;
    esac
  done
  [ "$has" = 1 ] && TOK+=("$cur")
  return 0
}

# strip_heredocs <string>: drops the body of a heredoc only when it is certainly inert data: a quoted delimiter
# (no $(...)/backtick expansion), a data-sink command (cat, tee, git commit, gh pr/issue create|edit|comment),
# and a plain intro line (no quotes before <<, no pipe/;/&/(/#/backtick). Anything else keeps its body so it is
# still scanned as commands (fail closed).
strip_heredocs() {
  local line l2 pre tag dash out="" skip="" tabs=0 bad
  local re='(^|[^<])<<(-?)[[:space:]]*(["'"'"']?)([A-Za-z_][A-Za-z0-9_]*)'
  local sink='^[[:space:]]*(cat|tee|git[[:space:]]+commit|gh[[:space:]]+(pr|issue)[[:space:]]+(create|edit|comment))([[:space:]]|$)'
  while IFS= read -r line || [ -n "$line" ]; do
    if [ -n "$skip" ]; then
      l2="$line"
      [ "$tabs" = 1 ] && l2="${line#"${line%%[!$'\t']*}"}"
      [ "$l2" = "$skip" ] && skip=""
      continue
    fi
    out="$out$line"$'\n'
    if [[ $line =~ $re ]] && [ -n "${BASH_REMATCH[3]}" ]; then
      tag="${BASH_REMATCH[4]}"; dash="${BASH_REMATCH[2]}"
      [[ $line =~ $sink ]] || continue
      pre="${line%%<<*}"; bad=0
      case "$line" in *'|'*|*';'*|*'&'*|*'`'*|*'$('*|*'('*|*'#'*|*'\') bad=1 ;; esac
      case "$pre" in *"'"*|*'"'*) bad=1 ;; esac
      if [ "$bad" = 0 ]; then
        skip="$tag"; tabs=0
        [ -n "$dash" ] && tabs=1
      fi
    fi
  done <<< "$1"
  printf '%s' "$out"
}
