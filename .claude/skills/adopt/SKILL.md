---
name: adopt
description: Reconstruct project memory for an existing codebase: scan code, git history, docs and old Claude memory, then draft STATUS, DECISIONS and REMOVED for approval. Use before /base:kickoff on a project that already has code. Never deletes anything.
disable-model-invocation: true
---

<!-- why: #3 #8 an existing project's problem is old and new decisions mixed together; this rebuilds the memory files from evidence instead of memory. Writes only after approval, never deletes. -->

# Adopt an existing project

1. **Scan.** Send `explorer` to read: the code layout, the last 100 commits (`git log -100`), existing docs (README, CLAUDE.md, docs/), and `~/.claude/projects/<slug>/memory/` (slug = the absolute project path with every non-alphanumeric character, including spaces, `.`, `_` and `/`, replaced by `-`; e.g. `/Users/me/My App` becomes `-Users-me-My-App`; if that dir does not exist, `ls ~/.claude/projects` and pick the matching one; if none, skip it). Ask for evidence as `path:line` or commit hashes; only conclusions return here.
2. **Draft three files** in the formats of the memory-file templates:
   - `.claude/STATUS.md` (at most 30 lines): goal, done, remaining, next step.
   - `.claude/DECISIONS.md`: one line per decision, `D<n> | YYYY-MM-DD | decision | why`. Where the evidence shows a decision was reversed, mark it superseded: `~~D3 ...~~ → D7`.
   - `.claude/REMOVED.md`: header `Item | Date | Why / evidence | Replaced by | Cleanup done?`, then one row per stale code, file or abandoned approach (evidence = `path` + reason).
3. **Approve.** Show the three drafts. If any of these files already exist, show a diff of draft vs current instead of overwriting. Write them only after I approve (or after the edits I ask for). Never delete or modify any other file; removal is only listed.
4. Report in Uzbek: what was found, what was written, and that `/base:kickoff` is the next step, and that `/base:readiness` audits production gaps.
