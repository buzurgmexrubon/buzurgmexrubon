---
name: clean-gone
description: List and delete local git branches whose remote branch is gone (after merged PRs), with the user's OK. Use when you want to tidy stale local branches.
disable-model-invocation: true
---

<!-- why: #13 stale local branches pile up after squash-merges; deleting them blindly can lose unmerged work, so list first, show what each holds, delete only on OK. Idea from the official commit-commands clean_gone, rewritten with a confirm step. -->

# Clean gone branches

1. `git fetch -p` then `git branch -vv | grep ': gone]'`. Never touch the current branch or the default branch (`git branch --show-current`).
2. For each candidate show `git log --oneline <default>..<branch>` (commits not on the default branch; find the default with `git symbolic-ref --short refs/remotes/origin/HEAD`). If that list is non-empty, flag the branch as possibly unmerged work.
3. Show the list to the user and ask which to delete. Do not delete without an explicit OK.
4. Delete with `git branch -d <name>`. Use `-D` only for a branch the user confirmed is safe to lose (squash-merged branches need it); guard-git will ask again.
5. Re-run `git branch -vv` and report what remains.
