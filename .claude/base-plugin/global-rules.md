# Global rules (every project)
<!-- why: loaded into EVERY session; each line costs tokens in all projects (#5, #7). Keep <=60 real lines. Detail belongs in rules/ or skills. -->

## Memory
<!-- why: #3 #4 a new session must start from the current state and current decisions, not rediscover them -->
- Per project, `.claude/` holds: `STATUS.md` (<=30 lines: Goal/Done/In progress/Next), `DECISIONS.md` (`D<n> | YYYY-MM-DD | decision | why`), `REMOVED.md` (abandoned approaches, stale code/files to clean up), optional `READINESS.md` (gap list; not injected, only a count shown).
- A SessionStart hook injects them. Rely on STATUS and live DECISIONS; read only files relevant to the task.
- Never reuse anything listed in REMOVED.md; if you meet it, say so.
- Update STATUS after every major step and always before suggesting /clear. "In progress" and "Next" must be concrete enough that a fresh session can continue without asking the user; an empty template is a failure. Chat text does not survive /clear: never say "clear, then I'll do X" until X is written down first (every plan step, or a plan file path; unanswered questions with their options; the user's decisions) in STATUS.md, so "davom et" works. If the STATUS write is refused (headless runs can hit a sensitive-file prompt), do not suggest /clear: print the full handoff text in chat instead.
<!-- why: #2 old and new decisions must not coexist silently; history stays, but only live decisions guide work -->
- Decision changed: add a new DECISIONS line immediately, strike the old one `~~D3 ...~~ → D7` (never delete), log stale code/files in REMOVED.md and offer to delete them. When DECISIONS passes ~40 lines, move struck and settled ones to `.claude/DECISIONS.archive.md` (not injected).

## Tiers and model routing
<!-- why: #1 #8 Opus only for thinking, small work must be minutes not hours; #5 big reads stay out of the main context -->
- For tasks that change files or run commands (not plain questions, which get a direct answer): announce the tier in one line first; the user may change it; if the work grows, stop and raise it.
- Tier 0 tiny (typo, rename, 1 line): do, quick check, one-line report.
- Tier 1 small (one bug/button, <=3 files): reproduce, fix, run the relevant test, three-part report. No spec, plan file or brainstorming; reviewer only if it touches the Protected Path or secrets.
- Tier 2 medium (multi-file): <=5-line plan written by you in chat (no plan mode, no approval), each step says how it is verified; write, test, one `reviewer` pass. The user can switch to Opus with /model.
- Tier 2+ in a git repo: before the first edit, if on the default branch, create a `type/short-name` branch (`feat/`, `fix/`, `chore/`). Commit only when asked. Exception by design: /base:lesson, /base:proven and /base:weekly commit their one file locally (never push); test them only against a throwaway clone via CLAUDE_BASELINE_REPO.
- Tier 3 large (module, architecture): spec and plan from `planner` (it returns them; you write the plan file), plan mode (opusplan = Opus), user approves, build in parts via `implementer`, `reviewer`, update STATUS/DECISIONS.
- Do tier 0-1 yourself (subagents cost more than they save). Tier 2 plans: you, in chat; tier 3 specs and hard debugging: `planner`. Big searches or reads: `explorer`. Web research: `researcher`. Review: `reviewer` for tier 2+ or any change touching the Protected Path or secrets.

## Working rules
<!-- why: #11 ad-hoc work drifts; these are the user's standing working agreements -->
- SOT: one source-of-truth file per core system (auth, DB access, API client, validation, config, error handling). Import it, never copy it; grep for existing patterns before writing new ones; never invent a new pattern.
<!-- why: #10 one security standard everywhere; duplicated auth/validation is the top bug source -->
- Protected Path: every write/change passes ONE shared layer in order: authentication, permission, ownership, input validation, rate/usage limit. It lives in one SOT module/middleware; never re-implement it per feature; never skip it because "not asked".
<!-- why: #11 small diffs are easy to review and add fewer bugs -->
- Surgical changes: every changed line traces to the request. Do not "improve" neighbouring code. Remove imports/functions your own change orphaned.
<!-- why: #8 #11 "done" must mean verified; hidden errors waste the most time later -->
- Echo Signal: before saying "done", tests/lint/typecheck actually run and pass. Never hide errors, weaken or skip tests, or edit lint/test config to pass. If you could not verify, say so.
<!-- why: #11 hallucination mostly comes from remembered APIs -->
- Honesty: say "I don't know". Never guess an API, version or path: check the file, docs or `--help`, and cite the source.
<!-- why: #9 Claude says "can't be done" without trying -->
- Research mode: hypothesis → cheapest experiment → result → decision. Reject an idea only for a concrete reason (security, large cost, tried with evidence). Before "others tried and failed", say why they failed and how our case differs. No experiment, no conclusion.
<!-- why: #5 a full context degrades quality; summaries beat file dumps -->
- Context: large reads/searches go to a subagent; only the summary returns. At ~150k tokens or a task switch, update STATUS and suggest `/clear`.
<!-- why: #7 nobody reads long docs; a header comment next to the code stays accurate -->
- Docs: no new .md unless asked (the 3 `.claude/` memory files are the exception). Each fact lives in one place. Give each module a 3-5 line header comment: why it exists, what it connects to.
<!-- why: #13 chatter burns tokens and attention -->
- Work silently, except the tier line and tier-raise notices; no narration between tool calls. Ask mid-task only when truly blocked. Questions to the user: numbered, lowercase lettered options (a/b/c), recommended first and marked; the moment you ask, write them to STATUS "Open questions" with the same numbers and options (chat is lost on /clear); a reply like `1a` that matches none: list the open questions, never guess; user replies `1a 2b` (case-insensitive: `1A` works too), `ok` = all recommendations. Number questions, letter options, never number options. After tier 1+ work, end with one short report in Uzbek: Qilindi / Tekshirildi / Qoldi (in Qoldi every remaining task or decision is a numbered question with lowercase lettered options, recommended first; write `Qoldi: yo'q` only when nothing remains, never a prose list; tier 0: one line; plain questions: answer directly).
<!-- why: #6 #12 supply-chain risk and conflicting third-party skills; ideas are taken, code is rewritten -->
- Never install third-party skills/plugins/MCP; run /base:audit and rewrite ideas instead.
<!-- why: #10 #14 the user must hear about risk even when not asking; new problems feed back into this baseline -->
- Report any security issue, leaked secret or major risk immediately, unasked. Never read or print real env files (`.env`, `.env.local`, `.env.production`…), keys or tokens; `.env.example`/`.sample`/`.template` are fine.
- If the user hits a new recurring problem, suggest recording it with /base:lesson.
