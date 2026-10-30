#!/usr/bin/env bash
# PreToolUse(Bash) guard: asks (permissionDecision "ask", so it prompts even under bypassPermissions) before  # audit-ignore: endpoint-override comment mention only
# destructive git commands and recursive rm of risky targets. Sibling of guard-bash.sh, which hard-blocks the
# worst cases (exit 2); this one covers the "confirm first" tier. Never logs or stores the command.
# Method: quote-aware tokenizer -> simple commands -> skip shell keywords (if/then/do/{/!...) and unwrap
# sudo/doas/env(-S)/command/exec/time/nohup/nice/timeout/stdbuf/xargs/bash -c/eval -> match git/rm arguments,
# so quoted text (git commit -m "reset --hard", echo "rm -rf ~") does not trigger. Fails open without jq.
# A bare shell (bash/sh/...) fed by a pipe or here-string/heredoc with no -c and no script file asks, because
# its input cannot be inspected. Wrapper nesting deeper than 3 asks instead of passing silently.
# Also asks for: `git add -f/--force` (bypasses .gitignore), any recursive rm run through xargs (targets come
# from stdin), and find -delete / find -exec rm -r whose start paths are risky (or absent, i.e. cwd).
# Known limits: paths built from variables or globs, aliases and scripts, $(...) inside double quotes, heredoc
# bodies fed to a shell (stripped otherwise), bash -o/-O option values beyond the first.
#
# Hook precedence (code.claude.com/docs/en/hooks): all matching hooks run in parallel; when PreToolUse hooks
# disagree, "precedence is deny > defer > ask > allow", and exit code 2 blocks the call. So guard-bash.sh
# (exit 2) still blocks hard-reset, plain force-push and rm -rf ~ / even though this hook answers ask.

command -v jq >/dev/null 2>&1 || exit 0
INPUT="$(cat)"
CMD="$(printf '%s' "$INPUT" | jq -er '.tool_input.command // empty' 2>/dev/null)" || exit 0
[ -n "$CMD" ] || exit 0

. "$(dirname "$0")/lib-tokenize.sh" 2>/dev/null || { echo "guard-git: lib-tokenize.sh missing or broken; reinstall the base plugin." >&2; exit 2; } # SEP/PIPE/HERE + tokenize()

ask() { # reason
  jq -n --arg r "guard-git: $1" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$r}}'
  exit 0
}

# scan <string> <depth>: tokenizes and checks every simple command in it.
scan() {
  local w piped=0 PIPED=0
  local -a TOK SEG
  tokenize "$1"
  SEG=()
  for w in "${TOK[@]}"; do
    if [ "$w" = "$SEP" ]; then
      PIPED=$piped
      [ "${#SEG[@]}" -gt 0 ] && check_seg "$2"
      SEG=(); piped=0
    elif [ "$w" = "$PIPE" ]; then
      piped=1
    else
      SEG+=("$w")
    fi
  done
  PIPED=$piped
  [ "${#SEG[@]}" -gt 0 ] && check_seg "$2"
  return 0
}

# cap <depth>: wrapper nesting beyond 3 cannot be inspected, so ask rather than pass silently.
cap() { [ "$1" -lt 3 ] || ask "wrapper nesting deeper than 3 levels cannot be inspected. Confirm with the user."; }

# wrap_opts <wrapper>: advances i (check_seg's) past the wrapper's own options/assignments using a per-wrapper
# table of options that take a separate value; sets SPLIT for env -S.
wrap_opts() {
  local nm="$1" w vo=" "
  case "$nm" in
    sudo) vo=" -u --user -g --group -h --host -p --prompt -C -D --chdir -R --chroot -T --command-timeout -U --other-user " ;;
    doas) vo=" -u -C " ;;
    env) vo=" -u --unset -C --chdir " ;;
    exec) vo=" -a " ;;
    time) vo=" -f --format -o --output " ;;
    nice) vo=" -n --adjustment " ;;
    timeout) vo=" -s --signal -k --kill-after " ;;
    stdbuf) vo=" -i -o -e --input --output --error " ;;
    xargs) vo=" -I -n -P -s -L -d -E -a -J --max-args --max-procs --max-chars --max-lines --delimiter --eof --arg-file " ;;
  esac
  while :; do
    w="${W[$i]-}"
    case "$w" in
      --) i=$((i + 1)); break ;;
      -S|--split-string)
        if [ "$nm" = env ]; then SPLIT="${W[$((i + 1))]-}"; i=$((i + 2)); return 0; fi
        i=$((i + 1)) ;;
      -S?*) if [ "$nm" = env ]; then SPLIT="${w#-S}"; i=$((i + 1)); return 0; fi; i=$((i + 1)) ;;
      --split-string=*) if [ "$nm" = env ]; then SPLIT="${w#*=}"; i=$((i + 1)); return 0; fi; i=$((i + 1)) ;;
      -*) case "$vo" in *" $w "*) i=$((i + 2)) ;; *) i=$((i + 1)) ;; esac ;;
      [A-Za-z_]*=*) i=$((i + 1)) ;;
      *) break ;;
    esac
  done
  [ "$nm" = timeout ] && i=$((i + 1)) # the duration
  return 0
}

# check_seg <depth>: strips keywords and wrappers from SEG, then dispatches on the real command.
check_seg() {
  local depth="$1" i=0 w j n here=0 SPLIT="" xa=0
  local -a W
  W=("${SEG[@]}")
  while :; do
    w="${W[$i]-}"
    n="${w##*/}"
    case "$n" in
      "") return 0 ;;
      then|do|else|elif|if|while|until|'!'|'{'|'}') i=$((i + 1)) ;;
      sudo|doas|env|command|exec|time|nohup|nice|builtin|timeout|stdbuf|xargs)
        i=$((i + 1))
        [ "$n" = xargs ] && xa=1
        wrap_opts "$n"
        if [ -n "$SPLIT" ]; then
          cap "$depth"
          scan "$SPLIT ${W[*]:$i}" "$((depth + 1))"
          return 0
        fi ;;
      [A-Za-z_]*=*) i=$((i + 1)) ;;
      *) break ;;
    esac
  done
  w="${W[$i]-}"
  [ -n "$w" ] || return 0
  case "${w##*/}" in
    git) check_git "$i" ;;
    rm) check_rm "$i" ;;
    find) check_find "$i" ;;
    bash|sh|zsh|dash|ksh)
      j=$((i + 1))
      while [ "$j" -lt "${#W[@]}" ]; do
        case "${W[$j]}" in
          "$HERE") here=1; j=$((j + 1)) ;; # next word is the here-string/delimiter
          -o|-O|+o|+O) j=$((j + 1)) ;;
          --*) ;;
          -*c*) cap "$depth"; scan "${W[$((j + 1))]-}" "$((depth + 1))"; return 0 ;;
          -*) ;;
          *) return 0 ;;
        esac
        j=$((j + 1))
      done
      if [ "$here" = 1 ] || [ "${PIPED:-0}" = 1 ]; then
        ask "a shell reading commands from a pipe/here-string cannot be inspected. Confirm with the user."
      fi ;;
    eval)
      cap "$depth"
      scan "${W[*]:$((i + 1))}" "$((depth + 1))" ;;
  esac
  return 0
}

check_git() { # uses W from check_seg; $1 = index of "git"
  local j=$(($1 + 1)) sub="" a first staged=0 wt=0 del=0 frc=0
  local -a A
  while [ "$j" -lt "${#W[@]}" ]; do
    case "${W[$j]}" in
      -C|-c|--git-dir|--work-tree|--namespace) j=$((j + 2)) ;;
      -*) j=$((j + 1)) ;;
      *) sub="${W[$j]}"; break ;;
    esac
  done
  [ -n "$sub" ] || return 0
  A=("${W[@]:$((j + 1))}")
  case "$sub" in
    push)
      for a in "${A[@]}"; do
        case "$a" in
          --force*) ask "git push with force/lease rewrites remote history. Confirm with the user." ;;
          --mirror|--prune) ask "git push --mirror/--prune overwrites or removes remote refs. Confirm with the user." ;;
          --delete) ask "git push --delete removes remote refs. Confirm with the user." ;;
          --*) ;;
          -*f*|-*d*|+*|*:+*) ask "git push with force/delete/+refspec rewrites or removes remote refs. Confirm with the user." ;;
          :*) ask "git push with a :ref refspec deletes a remote ref. Confirm with the user." ;;
        esac
      done ;;
    reset)
      for a in "${A[@]}"; do
        [ "$a" = "--hard" ] && ask "git reset --hard discards uncommitted work. Confirm with the user."
      done ;;
    clean)
      for a in "${A[@]}"; do
        case "$a" in
          --force) ask "git clean -f deletes untracked files for good. Confirm with the user." ;;
          --*) ;;
          -*f*) ask "git clean -f deletes untracked files for good. Confirm with the user." ;;
        esac
      done ;;
    checkout|restore|switch)
      for a in "${A[@]}"; do
        case "$a" in
          --staged|-S) staged=1 ;;
          --worktree|-W) wt=1 ;;
        esac
      done
      for a in "${A[@]}"; do
        case "$a" in
          .|:/)
            if [ "$sub" != switch ] && { [ "$staged" = 0 ] || [ "$wt" = 1 ] || [ "$sub" = checkout ]; }; then
              ask "git $sub $a discards all uncommitted changes. Confirm with the user."
            fi ;;
          --force|--discard-changes)
            [ "$sub" = restore ] || ask "git $sub $a throws away local changes. Confirm with the user." ;;
          --*) ;;
          -*[fB]*)
            [ "$sub" = restore ] || ask "git $sub -f/-B throws away local changes or resets a branch. Confirm with the user." ;;
        esac
      done ;;
    stash)
      first="${A[0]-}"
      case "$first" in
        ""|drop|clear|save|-*) ask "git stash (bare/save/drop/clear) moves or loses uncommitted work. Confirm with the user." ;;
        push) [ -n "${A[1]-}" ] || ask "git stash push without arguments moves all uncommitted work. Confirm with the user." ;;
      esac ;;
    branch)
      for a in "${A[@]}"; do
        case "$a" in
          --delete) del=1 ;;
          --force) frc=1 ;;
          --*) ;;
          -*D*) ask "git branch -D deletes a branch even if unmerged. Confirm with the user." ;;
          -*) case "$a" in *d*) del=1 ;; esac; case "$a" in *f*) frc=1 ;; esac ;;
        esac
      done
      [ "$del" = 1 ] && [ "$frc" = 1 ] && ask "git branch --delete --force deletes a branch even if unmerged. Confirm with the user." ;;
    add)
      for a in "${A[@]}"; do
        case "$a" in
          -A|--all|.) ask "git add -A/--all/. can stage secrets or build output. Add specific files instead, or confirm." ;;
          --force) ask "git add --force stages files that .gitignore excludes (often secrets or build output). Confirm with the user." ;;
          --*) ;;
          -*f*) ask "git add -f stages files that .gitignore excludes (often secrets or build output). Confirm with the user." ;;
        esac
      done ;;
    commit)
      for a in "${A[@]}"; do
        case "$a" in
          --all) ask "git commit -a stages every tracked change. Add specific files instead, or confirm." ;;
          --*) ;;
          -*) cluster_has_a "${a#-}" && ask "git commit -a stages every tracked change. Add specific files instead, or confirm." ;;
        esac
      done ;;
  esac
  return 0
}

# cluster_has_a <short-flag-letters>: true if 'a' appears before the first option that takes a value.
cluster_has_a() {
  local f="$1" k=0 ch
  while [ "$k" -lt "${#f}" ]; do
    ch="${f:$k:1}"
    case "$ch" in
      a) return 0 ;;
      m|F|C|c|t|S|u) return 1 ;;
    esac
    k=$((k + 1))
  done
  return 1
}

check_rm() { # uses W from check_seg; $1 = index of "rm"
  local j=$(($1 + 1)) a rec=0 endopts=0
  local -a T
  T=()
  while [ "$j" -lt "${#W[@]}" ]; do
    a="${W[$j]}"; j=$((j + 1))
    if [ "$endopts" = 0 ]; then
      case "$a" in
        --) endopts=1; continue ;;
        --recursive) rec=1; continue ;;
        --*) continue ;;
        -*[rR]*) rec=1; continue ;;
        -*) continue ;;
      esac
    fi
    T+=("$a")
  done
  [ "$rec" = 1 ] || return 0
  [ "$xa" = 1 ] && ask "recursive rm run through xargs deletes whatever arrives on stdin. Confirm with the user."
  for a in "${T[@]}"; do
    risky_target "$a" && ask "recursive rm of '$a' (home, root, system dir, cwd/parent, direct child of home, .git or a bare glob). Confirm with the user."
  done
  return 0
}

check_find() { # uses W from check_seg; $1 = index of "find"
  local j=$(($1 + 1)) a del=0 rmx=0 inpaths=1 k
  local -a P
  P=()
  while [ "$j" -lt "${#W[@]}" ]; do
    a="${W[$j]}"; j=$((j + 1))
    if [ "$inpaths" = 1 ]; then
      case "$a" in
        -H|-L|-P|-O*) continue ;;
        -*|'!') inpaths=0 ;;
        *) P+=("$a"); continue ;;
      esac
    fi
    case "$a" in
      -delete) del=1 ;;
      -exec|-execdir|-ok|-okdir)
        [ "${W[$j]-}" ] && [ "${W[$j]##*/}" = rm ] || continue
        k=$((j + 1))
        while [ "$k" -lt "${#W[@]}" ]; do
          case "${W[$k]}" in
            ';'|'+') break ;;
            --recursive|-[rR]*|-[!-]*[rR]*) rmx=1 ;;
          esac
          k=$((k + 1))
        done ;;
    esac
  done
  [ "$del" = 1 ] || [ "$rmx" = 1 ] || return 0
  [ "${#P[@]}" -gt 0 ] || ask "find -delete / -exec rm -r with no start path runs from the current directory. Confirm with the user."
  for a in "${P[@]}"; do
    risky_target "$a" && ask "find -delete / -exec rm -r starting at '$a' (home, root, system dir, cwd/parent, direct child of home). Confirm with the user."
  done
  return 0
}

risky_target() { # $1 = path as written (quotes already removed)
  local t="$1" p rest
  while [ "${#t}" -gt 1 ] && [ "${t%/}" != "$t" ]; do t="${t%/}"; done
  case "$t" in
    '~'|'$HOME'|'${HOME}'|.|..|'../*'|'$PWD'|'${PWD}'|'$PWD/*'|'${PWD}/*'|/usr|/etc|/bin|/var|/System|/Library|/Applications|'/usr/*'|'/etc/*'|'/bin/*'|'/var/*'|'/System/*'|'/Library/*'|'/Applications/*'|/|'/*'|'~/*'|'$HOME/*'|'${HOME}/*'|'*'|'./*'|.git|*/.git) return 0 ;;
  esac
  [ -n "${HOME:-}" ] && [ "$t" = "$HOME" ] && return 0
  for p in '~/' '$HOME/' '${HOME}/' "${HOME:-/nonexistent-home}/"; do
    rest="${t#"$p"}"
    if [ "$rest" != "$t" ] && [ -n "$rest" ]; then
      case "$rest" in */*) ;; *) return 0 ;; esac
    fi
  done
  return 1
}

scan "$(strip_heredocs "$CMD")" 0
exit 0
