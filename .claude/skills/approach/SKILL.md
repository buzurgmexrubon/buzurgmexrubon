---
name: approach
description: Choose how to build before writing code: from scratch, adapt an open-source project, or use a ready service. Scores each option on fixed criteria, recommends one, records it in DECISIONS, and sets a checkpoint date.
disable-model-invocation: true
argument-hint: <what we want to build>
---

<!-- why: #9 #11 projects fail months in because the build-vs-adapt choice was made by feel. One short, evidence-based comparison at the start, plus a dated checkpoint, catches a wrong road in weeks, not months. Reading open-source code is allowed; installing or vendoring it unaudited is not (global CLAUDE.md third-party rule). -->

# Choose the approach

Argument: `$ARGUMENTS`. Change no code. Stack first: read CLAUDE.md, `.claude/` memory and the existing code.

1. **Options.** Always weigh: (A) build from scratch, (B) adapt an open-source project, (C) buy/use a ready service or library. Drop an option only with a concrete reason. For B and C, send `researcher` to find candidates (repo, last commit, license, size, open issues, how many of my requirements it already covers). Evidence with sources; mark UNVERIFIED what you could not confirm.
2. **Score** each option on: fit to my requirements, time to first working version, long-term maintenance (who updates it), license and security (run `/base:audit` on any external code before adopting it), lock-in and cost, and how well it matches my stack and SOT layout. One line of evidence per cell.
3. **Cheapest experiment.** For the top two options name the smallest spike (hours, not days) that would prove or kill them. Run it when it is cheap; no experiment, no rejection.
4. **Recommend one**, say what would change your mind, and state the main risk.
5. **Record.** After I approve: add `D<n> | date | approach: <choice> | <why, rejected options>` to `.claude/DECISIONS.md`, and set the `## Checkpoint` section of `.claude/STATUS.md` (replace any old one) to `<date +3 weeks>: is the approach still right? (progress vs. goal, surprises, would I choose again?)`. If the decision replaces an earlier one, strike it as usual.
6. **Report in Uzbek**: choice, why, risk, the checkpoint date.
