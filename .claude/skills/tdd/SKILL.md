---
name: tdd
description: Test-driven loop, one failing test then minimal code. USE FOR: the user asks for TDD, tests-first or red-green-refactor, or a bug whose cause is already known. DO NOT USE FOR: throwaway scripts, docs, config edits, pure refactors, or a failure with an unknown cause (use debug).
---

<!-- why: #1 #13 writing all tests up front or recomputing expectations with the code's own logic produces tests that pass for the wrong reason; one failing test at a time keeps each step verified. Model-invocable on purpose (unlike the /base:* flow skills); pairs with the debug skill. -->

# Test-driven loop

1. **Find the commands.** Read the repo's own build files, README and CI config (package.json, Makefile, pyproject.toml, go.mod, Cargo.toml, `.github/workflows`). Note the focused-test, full-suite, lint and typecheck commands. Never guess a default like `npm test`; if nothing documents them, ask.
2. **List the seams.** Name the public entry points the tests may call (functions, endpoints, CLI). If the seams are obvious (one entry point, <=3 files) state them in one line and proceed; otherwise show the list and wait for the user's confirmation. Test behaviour through those seams only, never private internals.
3. **Loop, one behaviour at a time:**
   - Write ONE failing test. Run it and see it fail for the right reason.
   - Write the minimal code that passes it. Run the focused test and see it pass.
   - Refactor only while green. Repeat with the next behaviour.
   Never write all the tests first.
4. **Expected values** come from the spec, a literal, or a known fixture. Never compute them with the code under test or a copy of its logic.
5. **Bug fix:** first write a reproduction test that fails because of the bug, then fix, then see it pass.
6. **Prefer real implementations** (real DB, files, modules) over mocks. Fake only slow, paid or non-deterministic edges (network, clock, randomness).
7. **Before saying "done":** run the full suite, lint and typecheck; report the real output. Never skip, weaken or delete a test to get green: no new `skip`/`xfail`/`.only` markers, no loosened or removed assertions. If a test must change, state why and show the diff.
8. **Unattended run:** for a multi-step loop use the built-in `/goal <check passes> or stop after N turns`; do not write a loop script or Stop hook.
