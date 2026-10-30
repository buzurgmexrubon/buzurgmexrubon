#!/usr/bin/env bash
# PreToolUse(Bash) guard: blocks dangerous or secret-leaking commands (exit 2 + reason on stderr).
# Fails open (exit 0, silent) on missing jq or unparseable input. Never logs or stores the command.
# why: a positive-match blocklist keeps risky one-liners out without ever blocking normal work.
set -u

# SEP/PIPE/HERE + tokenize(). A missing lib must not silently disable the guard, so this one blocks.
. "$(dirname "$0")/lib-tokenize.sh" 2>/dev/null || { echo "guard-bash: lib-tokenize.sh missing or broken; reinstall the base plugin." >&2; exit 2; }
command -v jq >/dev/null 2>&1 || exit 0
INPUT="$(cat)"
CMD="$(printf '%s' "$INPUT" | jq -er '.tool_input.command // empty' 2>/dev/null)" || exit 0
[ -n "$CMD" ] || exit 0

block() { # category, advice
  printf 'guard-bash: blocked [%s]. %s\n' "$1" "$2" >&2
  exit 2
}

# why: words inside an inert heredoc (notes, commit message) are text, so every regex check below runs on this copy;
# interpreter heredocs keep their body and stay scanned.
GCMD="$(strip_heredocs "$CMD")"

# match <regex> [string]: ERE on the heredoc-stripped command (matches anywhere, line by line).
match() { printf '%s\n' "${2-$GCMD}" | grep -Eq -- "$1"; }

# Real env files only: .env and .env.<local|production|...>[.local]; .env.example/.sample/.template stay readable.
ENV_END='(["'"'"']|[[:space:]]|$|[;&|)])'
ENVB='\.env(\.(local|production|prod|development|dev|staging|test)(\.local)?)?'"$ENV_END"
PRE='[/[:space:]"'"'"'<]'

# ign_search: true when the whole command is a pattern search that only targets .gitignore/.dockerignore
# (e.g. `grep -n '.env' .gitignore`, `cat .gitignore | grep .env`); there `.env` is a pattern, not a file read.
# why: checking that .env is ignored is routine and must not be blocked; any other file argument still is.
IGNF='(^|/)\.(git|docker)ignore$'
ign_search() {
  local c="$CMD" w first=1 nfile=0 rest piped=0
  case "$c" in *$'\n'*|*';'*|*'&'*|*'<'*|*'>'*|*'`'*|*'$('*) return 1 ;; esac
  rest="$(printf '%s' "$c" | sed -E "s/^[[:space:]]*cat[[:space:]]+[\"']?[^[:space:]|\"']*\.(git|docker)ignore[\"']?[[:space:]]*\|[[:space:]]*//")"
  if [ "$rest" != "$c" ]; then
    # stdin is the ignore file: the first operand is the pattern; any further file operand must also be an ignore file
    piped=1; c="$rest"
  fi
  case "$c" in *'|'*) return 1 ;; esac
  set -f
  for w in $c; do
    if [ "$first" = 1 ]; then
      case "$w" in grep|rg) first=2; continue ;; *) set +f; return 1 ;; esac
    fi
    case "$w" in
      -e|-f|-e*|-f*|--regexp*|--file*) set +f; return 1 ;;
      -*) continue ;;
    esac
    if [ "$first" = 2 ]; then first=3; continue; fi   # first positional = the pattern
    w="${w#[\"\']}"; w="${w%[\"\']}"
    if printf '%s\n' "$w" | grep -Eq "$IGNF"; then nfile=$((nfile + 1)); else set +f; return 1; fi
  done
  set +f
  [ "$piped" = 1 ] && [ "$first" -ge 2 ] && return 0
  [ "$nfile" -ge 1 ]
}

# Known limit: code run by an interpreter (python -c, node, heredoc scripts) that opens an env file by itself.
# --- token-level env-file check -------------------------------------------------------------------------
# why: regexes enumerate readers and positions; this walks every simple command and flags any argument that
# names a real env file (also after --opt=, host:, or inside sh -c / eval strings) unless the command cannot
# read file contents (ls, find, test, git check-ignore...) or the file is only a cp/mv/scp destination.
ENVW='^\.env(\.[^/]+)?$'
ENVT='\.(example|sample|template)$'
ENVNAMES=(.env .env.local .env.production .env.prod .env.development .env.dev .env.staging .env.test .env.bak)
BE=(); BECAP=0
brace_expand() { # appends the expansions of $1 to BE (first {a,b} group, recursive, capped at 64)
  local w="$1" pre body post alt re='^([^{]*)\{([^{}]*)\}(.*)$'
  [ "${#BE[@]}" -lt 64 ] || { BECAP=1; return 0; }
  if [[ $w =~ $re ]]; then
    pre="${BASH_REMATCH[1]}"; body="${BASH_REMATCH[2]},"; post="${BASH_REMATCH[3]}"
    while [ -n "$body" ]; do
      alt="${body%%,*}"; body="${body#*,}"
      brace_expand "$pre$alt$post"
    done
  else
    BE+=("$w")
  fi
}

env_word() { # true when w, a part after = : @, or a brace-group member, has a real env file basename
  local w="$1" part tok cand rc=1
  BE=(); BECAP=0
  brace_expand "$w"
  [ "$BECAP" = 0 ] || return 0 # too many expansions to inspect: fail closed
  set -f
  for tok in "${BE[@]}" ${w//[\{\},]/ }; do
    for part in "$tok" "${tok#*=}" "${tok#*:}" "${tok#@}" "${tok#*=@}"; do
      part="${part##*/}"
      if printf '%s\n' "$part" | grep -Eq -- "$ENVW" && ! printf '%s\n' "$part" | grep -Eq -- "$ENVT"; then rc=0; break 2; fi
      # a glob that starts with a dot and can expand to a real env file (.e*, .env*, .en?, .e[n]v)
      case "$part" in
        .*[*?[]*) for cand in "${ENVNAMES[@]}"; do
                    # shellcheck disable=SC2053 # $part is intentionally a glob pattern
                    if [[ $cand == $part ]] 2>/dev/null; then rc=0; break 3; fi
                  done ;;
      esac
    done
  done
  set +f
  return $rc
}

env_seg() { # uses SEG from env_scan; $1 = depth
  local depth="$1" i=0 n w cmd wrapped=0 k j sub pat=0 tflag=0 last=-1 pw="" fx=0
  local -a A POS
  while [ "$i" -lt "${#SEG[@]}" ]; do
    w="${SEG[$i]}"; n="${w##*/}"
    case "$n" in
      then|do|else|elif|if|while|until|'!'|'{'|'}'|sudo|doas|env|command|exec|time|nohup|nice|builtin|stdbuf|xargs|timeout) wrapped=1; i=$((i + 1)) ;;
      -*) if [ "$wrapped" = 1 ]; then
            case " -u -g -n -a -s -k -I -P -L -C -p -h -U -T -R -D -i -o -e " in *" $w "*) env_word "${SEG[$((i + 1))]-}" && block secret-file-read "A real env file must not be read through a wrapper option."; i=$((i + 2)) ;; *) i=$((i + 1)) ;; esac
          else break; fi ;;
      [0-9]*) if [ "$wrapped" = 1 ]; then i=$((i + 1)); else break; fi ;; # timeout duration
      [A-Za-z_]*=*) i=$((i + 1)) ;;
      *) break ;;
    esac
  done
  [ "$i" -lt "${#SEG[@]}" ] || return 0
  cmd="${SEG[$i]##*/}"
  A=("${SEG[@]:$((i + 1))}")
  case "$cmd" in
    sh|bash|zsh|dash|ksh)
      k=0
      while [ "$k" -lt "${#A[@]}" ]; do
        case "${A[$k]}" in
          --*) ;;
          -o|-O) k=$((k + 1)) ;;
          -*c*) [ "$depth" -lt 3 ] && env_scan "${A[$((k + 1))]-}" "$((depth + 1))"; return 0 ;;
          -*) ;;
          *) break ;;
        esac
        k=$((k + 1))
      done ;;
    eval) [ "$depth" -lt 3 ] && env_scan "${A[*]-}" "$((depth + 1))"; return 0 ;;
    find)
      for w in "${A[@]+"${A[@]}"}"; do
        case "$w" in -exec|-execdir|-ok|-okdir) fx=1 ;; esac
      done
      if [ "$fx" = 1 ]; then
        for w in "${A[@]+"${A[@]}"}"; do
          env_word "$w" && block secret-file-read "find -exec must not read a real env file; read .env.example instead."
        done
      fi
      return 0 ;;
    ls|echo|printf|test|'['|'[['|stat|touch|mkdir|cd|pwd|basename|dirname|realpath|readlink|chmod|chown|ln|which|type|true|false|rm) return 0 ;;
    git)
      k=0; sub=""
      while [ "$k" -lt "${#A[@]}" ]; do
        case "${A[$k]}" in
          -C|-c|--git-dir|--work-tree|--namespace) k=$((k + 2)) ;;
          -*) k=$((k + 1)) ;;
          *) sub="${A[$k]}"; break ;;
        esac
      done
      case "$sub" in check-ignore|status|ls-files|add|rm|rev-parse|check-attr|restore|checkout) return 0 ;; esac ;;
    cp|mv|scp|rsync|install)
      POS=()
      for w in "${A[@]+"${A[@]}"}"; do
        case "$w" in
          -t|--target-directory|--target-directory=*) tflag=1 ;;
          -*) ;;
          *) POS+=("$w") ;;
        esac
      done
      last=$(( ${#POS[@]} - 1 ))
      for ((k = 0; k < ${#POS[@]}; k++)); do
        if [ "$tflag" = 0 ] && [ "$k" -eq "$last" ]; then break; fi
        env_word "${POS[$k]}" && block secret-file-read "A real env file must not be a copy/move source; copy .env.example instead."
      done
      return 0 ;;
    grep|egrep|fgrep|rg)
      pat=1
      for w in "${A[@]+"${A[@]}"}"; do
        case "$w" in
          --regexp|--regexp=*|--file|--file=*|-[a-zA-Z]*[ef]) pat=0 ;;
        esac
      done ;;
  esac
  for w in "${A[@]+"${A[@]}"}"; do
    case "$w" in
      -*) ;;
      *) if [ "$pat" = 1 ]; then pat=0; continue; fi ;;
    esac
    env_word "$w" && block secret-file-read "Read .env.example instead, or ask the user for the specific variable names."
  done
  return 0
}

env_scan() { # <string> <depth>: tokenizes and checks every simple command
  local w
  local -a TOK SEG
  tokenize "$1"
  SEG=()
  [ "${#TOK[@]}" -gt 0 ] || return 0
  for w in "${TOK[@]}"; do
    if [ "$w" = "$SEP" ]; then
      [ "${#SEG[@]}" -gt 0 ] && env_seg "$2"
      SEG=()
    elif [ "$w" = "$PIPE" ] || [ "$w" = "$HERE" ]; then
      :
    else
      SEG+=("$w")
    fi
  done
  [ "${#SEG[@]}" -gt 0 ] && env_seg "$2"
  return 0
}

match '(curl|wget)[^|]*\|[[:space:]]*(ba|z)?sh([^[:alnum:]_]|$)' \
  && block pipe-to-shell "Download the script to a file, read it, then run it."

match '--no-verify([^[:alnum:]_-]|$)' "$GCMD" \
  && block skip-hooks "Fix the failing hook instead of skipping it, or ask the user first."

# --force-with-lease (and --force-if-includes) are the safe forms: strip them before looking for a force flag.
SAFE_PUSH="$(printf '%s\n' "$GCMD" | sed -E 's/--force-with-lease(=[^[:space:]]*)?//g; s/--force-if-includes//g')"
match '(git[[:space:]]+push[[:space:]]([^;&|]*[[:space:]])?(-[a-zA-Z]*f[a-zA-Z]*|--force)([^[:alnum:]_-]|$)|git[[:space:]]+push[[:space:]]([^;&|]*[[:space:]])?\+[^[:space:]])' "$SAFE_PUSH" \
  && block force-push "Use --force-with-lease after asking the user."

match 'git[[:space:]]+reset[[:space:]]+--hard' "$GCMD" \
  && block hard-reset "Use git reset --soft or git stash, or ask the user first."

match 'rm([[:space:]]+-[-a-zA-Z]+)*[[:space:]]+(-[a-zA-Z]*[rR][a-zA-Z]*|--recursive)([[:space:]]+-[-a-zA-Z]+)*[[:space:]]+(/|~|\$HOME|\$\{HOME\})/?\*?([[:space:]]|[;&|)]|$)' \
  && block root-home-wipe "Delete a specific project subdirectory instead of / or the home directory."

! ign_search && match '(^|[^[:alnum:]_.-])(cat|less|more|head|tail|bat|grep|rg|strings|base64|xxd)[[:space:]]([^|;&]*'"$PRE"')?'"$ENVB" \
  && block secret-file-read "Read .env.example instead, or ask the user for the specific variable names."
match '(^|[^[:alnum:]_.-])(cp|scp|mv)([[:space:]]+-[^[:space:]]*)*[[:space:]]+["'"'"']?([^[:space:]|;&"'"'"']*/)?'"$ENVB" \
  && block secret-file-read "A real env file must not be the copy/move source; copy .env.example instead."
match '(^|[^<])<([^<|;&]*'"$PRE"')?'"$ENVB" \
  && block secret-file-read "Read .env.example instead, or ask the user for the specific variable names."
# command position: start, after ; & | ( {, after a keyword/wrapper, or after NAME=value assignments
CMDPOS='(^|[;&|({])[[:space:]]*(((then|do|else|eval|command|builtin|exec|time)|[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*)[[:space:]]+)*'
match "$CMDPOS"'(source|\.)[[:space:]]+([^|;&]*'"$PRE"')?'"$ENVB" \
  && block secret-file-read "Do not source real env files; use .env.example or ask the user."

! ign_search && env_scan "$(strip_heredocs "$CMD")" 0

KEYDIRS='((~|\$HOME|\$\{HOME\})|/(Users|home)/[^/[:space:]]+|/root)/\.(ssh|aws)([/[:space:]]|$)|id_rsa|id_ed25519' # audit-ignore: credential-read guard pattern, not a read
match "$KEYDIRS" \
  && block key-dirs "Do not touch SSH or AWS credentials; ask the user for what you need."

match "$CMDPOS"'(printenv|env|set|export|export[[:space:]]+-p|compgen[[:space:]]+-e|(declare|typeset)[[:space:]]+-[xp]+)[[:space:]]*([;&|)]|$)' \
  && block env-dump "Print only the specific variable you need (e.g. echo \"\$NAME\" for a non-secret name)."
match '/proc/[^[:space:]]*/environ' \
  && block env-dump "Process environments hold secrets; read only the specific variable you need."
match "$CMDPOS"'(echo|printf|print|cat)[[:space:]]+([^;&|]*[[:space:]"'"'"'])?\$\{?([A-Za-z0-9_]*_)?(KEY|TOKEN|SECRET|PASSWORD|PASSWD|CREDENTIAL)S?([^A-Za-z0-9_]|$)' \
  && block secret-var "Do not print secret variables; check whether the variable is set (test -n) without showing it."
match "$CMDPOS"'printenv[[:space:]]+([A-Za-z0-9_]*_)?(KEY|TOKEN|SECRET|PASSWORD|PASSWD|CREDENTIAL)S?([^A-Za-z0-9_]|$)' \
  && block secret-var "Do not print secret variables; check whether the variable is set (test -n) without showing it."

# why: irreversible damage outside the project (permissions, disks, fork bombs) is never part of normal work.
match '(chmod|chown|chgrp)[[:space:]]([^;&|]*[[:space:]])?(-[a-zA-Z]*R[a-zA-Z]*|--recursive)[[:space:]]([^;&|]*[[:space:]])?(/|~|\$HOME|\$\{HOME\})/?\*?([[:space:]]|[;&|)]|$)' \
  && block perm-wipe "Change permissions on a specific project path, never on / or the home directory."
match "$CMDPOS"'((sudo|doas)[[:space:]]+)?(mkfs(\.[A-Za-z0-9]+)?|mke2fs|wipefs|newfs[A-Za-z_]*|diskutil[[:space:]]+(erase|partition|zero|secure|reformat)[A-Za-z]*)([[:space:]]|$)' \
  && block disk-wipe "Formatting or erasing disks is never part of project work; ask the user."
match "$CMDPOS"'((sudo|doas)[[:space:]]+)?dd[[:space:]]+([^;&|]*[[:space:]])?of=/dev/(sd|hd|vd|xvd|nvme|mmcblk|disk|rdisk|loop|md|mapper|dm-)' \
  && block disk-wipe "Writing to a block device destroys data; ask the user."
match '>[[:space:]]*/dev/(sd|hd|vd|xvd|nvme|mmcblk|disk|rdisk)' \
  && block disk-wipe "Writing to a block device destroys data; ask the user."
match ':\(\)[[:space:]]*\{[^}]*:[[:space:]]*\|[[:space:]]*:' \
  && block fork-bomb "Fork bombs are never allowed."

exit 0
