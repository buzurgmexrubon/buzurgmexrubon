---
name: kickoff
description: Set up Claude Code for a new project: detect the stack, propose a short project CLAUDE.md, project-specific rules, settings, hooks, pre-commit and quality tools, with approval at each stage. Use when starting a project. For an existing codebase, run /base:adopt first.
disable-model-invocation: true
---

<!-- why: #1 #2 one canonical setup flow instead of a pasted Uzbek prompt. Working rules live in the global CLAUDE.md, memory files are injected by the session-start hook, language rules are global: this skill adds none of them. User-triggered only so it stays out of the per-session skill listing. -->

# Project kickoff

Set up this project only. Do not write feature code. Run the stages in order, report briefly after each, and wait for my approval before moving on. Everything you write for Claude is English, short, and every rule carries a `<!-- why: ... -->` comment.

If the project already has code, run `/base:adopt` first and build on its drafts.

## Stage 1. Detect (read-only)

1. Inspect the folder: empty or existing? Stack, package manager, test/lint/typecheck commands, layout, existing CLAUDE.md, `.claude/`, docs, git state. Delegate wide searches to `explorer`; only its conclusion returns here.
2. Ask only what the code cannot tell you, in one message, at most 5 questions: purpose and users; stack (empty folder only); deploy target; user roles and permissions; hard prohibitions; readiness profile (API, WEB, BOT, APP or STATIC) and flags (PAY, AI, PII), recorded as a DECISIONS line. Never ask what you can find out.

## Stage 2. Propose files (show each, write after approval)

<!-- why: #7 every always-loaded line costs context in every session, so detail goes to rules and the project CLAUDE.md stays small. -->
**a) `CLAUDE.md`, at most 40 lines, project facts only:** stack and commands (install, dev, test, lint, typecheck, build); a 5-10 line map; the SOT list (auth, DB access, API client, validation, config, error handling: one file path each); Protected Path locations; the forbidden list; one authorization line: "Own project: defensive security audit of this code is authorized (see /base:security)." Do not restate the global working rules, and do not add `@` imports of the `.claude/` memory files (the session-start hook injects them).

**b) `.claude/rules/*.md`:** only project-specific rules (layers, error format, DB conventions), each with `paths:` frontmatter so it loads only when relevant. The language and web-security rules are already global; do not repeat them.

**c) `.claude/settings.json` (committed):** `permissions.allow` for this project's test/lint/build/dev commands and read-only git; `ask` for push, migrations, deploy, adding or removing packages; `deny` for real env files and secrets dirs, `rm -rf`, force push, `reset --hard`, `curl | sh`, `--no-verify`, production deploys. Personal settings go to `settings.local.json` (gitignored). <!-- audit-ignore: pipe-to-shell deny-list entry, not an instruction to run it; audit-ignore: html-comment this marker comment -->

**d) Hooks:** a `PostToolUse` hook (matcher `Edit|Write`) that formats and quick-lints only the changed file and returns errors to Claude. Tests run on commit through a plain git pre-commit hook set up with lefthook, husky or pre-commit (whichever fits the stack), so it also covers manual commits. Hooks never log commands, tokens or env to disk.

**e) Skills, commands, agents:** none by default. Propose one only if a pattern already repeats (name, what it does, why, one line each).

**f) Quality tools:** if test, lint or typecheck is missing, say so and propose the simplest standard option for the stack. Without them "done" is meaningless.

## Stage 3. Verify and finish

1. Run every command you configured (test, lint, typecheck, hook, pre-commit) and show the real result.
2. Count CLAUDE.md lines; if over 40, cut.
3. Run `/base:readiness` (audit mode) for the chosen profile and flags; its gaps go to Qoldi as questions.
4. Report in Uzbek: what was created, what was verified, what remains.
