---
name: refine
description: Turn a rough prompt into a precise task before any work starts: find the gaps, ask at most 3 questions each with a recommended answer, then show the rewritten prompt for confirmation. Use when my request may be incomplete.
disable-model-invocation: true
argument-hint: <rough prompt>
---

<!-- why: #11 a general or incomplete prompt costs hours when the wrong thing is built. The cheap fix is one short confirmation round before work. User-triggered only so it never slows down clear requests. -->

# Refine a prompt

Argument: `$ARGUMENTS` (my rough prompt). Change no files in this skill.

1. **Read first.** Check the project (CLAUDE.md, `.claude/` memory, relevant code) so you never ask what the code or memory already answers.
2. **Find gaps** in: goal and done-criteria, scope (what is out), constraints (stack, SOT files, Protected Path), inputs/outputs, how it will be verified, and the tier. Also flag where my prompt contradicts a live DECISION or a REMOVED item.
3. **Ask only about real ambiguity**, in one message, at most 3 questions. Each question carries your recommended answer and a one-line reason, so I can reply "ok" or "1: yes, 2: B".
4. **Show the rewritten prompt**: goal, scope, out of scope, constraints, verification, tier. Short, in my language, no padding. End with "Shuni nazarda tutdingizmi?" and wait.
5. After I confirm (or edit), run the refined task under the normal tier rules. If nothing is ambiguous, say so, show the one-paragraph restatement, and proceed on confirmation.
