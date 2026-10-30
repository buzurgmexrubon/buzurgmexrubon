---
name: debug
description: Systematic debugging from a deterministic repro loop. USE FOR: a failure with an unknown cause: bug, failing test, crash, flaky behaviour, "why does this fail". DO NOT USE FOR: obvious one-line fixes, feature work, code review, performance tuning without a failing check, or no failing behaviour.
---

<!-- why: #1 #13 guessing fixes without a repeatable failure wastes turns and leaves debug noise behind; a fast pass/fail loop plus ranked hypotheses makes each step falsifiable. Model-invocable on purpose; pairs with the tdd skill. -->

# Systematic debugging

1. **Repro loop first** (skip only when the cause is trivially obvious). Build a fast, deterministic pass/fail check before touching code: a test, a `curl`, a headless-browser script, or `git bisect run <script>` for a regression. Run it and see it fail. If it is flaky, make it deterministic (fix seed, clock, ordering) or loop it until the failure rate is known.
2. **Minimise.** Cut input, steps and dependencies until the failure is as small as possible and still fails.
3. **Hypothesise.** Write 3-5 ranked hypotheses. Each names what you would observe if it is true and what would disprove it.
4. **Instrument.** Test the top hypothesis by changing or logging ONE variable at a time. Every temporary log carries one unique prefix (e.g. `DBG-7f3a`). Record the result, keep or drop the hypothesis, move on.
5. **Regression test.** Follow the bug-fix steps of the tdd skill (failing reproduction test, fix, pass). Then run the full suite, lint and typecheck. Never get green by skipping, loosening or deleting a test; if one must change, state why and show the diff.
6. **Clean up.** `grep` the prefix and remove every tagged log and temporary file. Confirm the grep is empty.

**Stop rule:** if 2 attempts on the same hypothesis fail, stop and report what was tried, what was observed, and the remaining hypotheses. Do not keep patching; ask the user which hypothesis to try next.

**Final report** ends with one status: `verified` (repro now passes and the suite is green, with the command output), `partial`, or `failed`. If the repro was not re-run, say `unverified`, never "fixed".
