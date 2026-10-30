---
name: commit
description: Make a safe conventional commit from the current changes. Use when you want to commit work. Never pushes unless asked.
disable-model-invocation: true
---

<!-- why: #6 #13 blanket staging commits secrets and unrelated files, and commits on main skip review; explicit file staging, a diff review and a branch check keep history clean. User-triggered only because it writes to git. Pairs with the pr skill. -->

# Commit

1. **Branch.** Run `git branch --show-current`. If it equals the default branch (`git symbolic-ref --short refs/remotes/origin/HEAD`, else `main`/`master`), create a feature branch first (`git switch -c <type>/<short-name>`). Never commit on the default branch.
2. **Review.** Run `git status` and `git diff --stat`, then `git diff <path>` for each non-env file (never print `.env*` contents). Understand every hunk; split unrelated changes into separate commits.
3. **Block secrets** before staging: skip `.env*`, keys, tokens, credentials and dumps (`.env.example` is fine), and scan the diff text for hardcoded keys. If one is found, stop and tell the user.
4. **Stage specific files** by path: `git add path/a path/b`. Never `git add -A` or `git add .`. Then check `git diff --staged --stat`; unstage strays with `git restore --staged <path>`.
5. **Message:** `type(scope): subject`.
   - Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert.
   - Subject: imperative, lowercase, no period, <=72 chars. Scope optional.
   - Body explains why, not what. One `-m` per paragraph; use single quotes (or `git commit -F <file>`) so backticks and `$(...)` in text are never executed.
   - Footers as their own `-m`: `Fixes #123`, `Refs #456`; breaking change: `BREAKING CHANGE: ...`.
   - No secrets, tokens, emails, names or other personal data in the message, except the attribution trailer the harness requires.
6. **Commit**, then run `git status` and `git log -1 --stat` to verify what was recorded.
7. **No push** unless the user asks. Never skip hooks and never amend published commits. If a hook fails, fix the cause and make a new commit.
