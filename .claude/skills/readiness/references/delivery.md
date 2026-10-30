# Delivery areas: ci-cd, dependencies, commits-versioning, license-legal, docs-runbooks
Read 2026-10-30 from owasp.org/www-project-top-10-ci-cd-security-risks/, docs.github.com/en/code-security/dependabot/working-with-dependabot/dependabot-options-reference (first 100,000 of ~182,000 characters), conventionalcommits.org/en/v1.0.0/. Stack-neutral; GitHub is the example host.

## ci-cd
- [ ] Pipeline runs build, lint, typecheck, tests on every PR; merging requires green and a review (tdd skill for test practice; Echo Signal rule). Deploy is automated from the default branch with a documented rollback.
- [ ] Pipeline security: review against the OWASP CI/CD Top 10 (CICD-SEC-1 flow control, 2 identity and access, 3 dependency chain abuse, 4 poisoned pipeline execution, 5 pipeline access controls, 6 credential hygiene, 7 insecure configuration, 8 third-party services, 9 artifact integrity, 10 logging and visibility). Source: https://owasp.org/www-project-top-10-ci-cd-security-risks/
- [ ] Secrets only from the CI secret store, never printed; least-privilege tokens; pin third-party actions/images (credential hygiene, CICD-SEC-6; config-secrets in ops.md).

## dependencies
- [ ] Automated update PRs (Dependabot or Renovate). Dependabot `dependabot.yml`: `version: 2`, `updates` per `package-ecosystem` with `directory`/`directories` and `schedule.interval` (daily, weekly, monthly, quarterly, semiannually, yearly, cron). Source: https://docs.github.com/en/code-security/dependabot/working-with-dependabot/dependabot-options-reference
- [ ] Defaults to know: 5 open version-update PRs (`open-pull-requests-limit`), security PRs have a separate fixed limit of 10, `groups` combine updates into one PR, `cooldown` delays version updates (3-day default per page) but not security updates, `ignore`/`allow` filter (same source).
- [ ] Lockfile committed; vulnerability audit (npm audit, pip-audit, etc.) runs in CI; a policy for how fast security updates are merged.

## versioning
- [ ] Commit format Conventional Commits: `<type>[scope][!]: <description>`, optional body and footers; `fix` = PATCH, `feat` = MINOR, breaking change (`!` or footer `BREAKING CHANGE:`, uppercase) = MAJOR. Source: https://www.conventionalcommits.org/en/v1.0.0/
- [ ] Other types (build, chore, ci, docs, style, refactor, perf, test) are allowed and have no SemVer effect unless breaking (same source). Commit skill: base:commit.
- [ ] Release tags follow SemVer and a changelog is generated or kept; versions bumped in one place.

## license
- [ ] Repo has a LICENSE file chosen on purpose; dependency licences checked for conflicts with it (copyleft in a closed product); third-party notices kept. General practice, no source read.
- [ ] Terms of service and privacy policy exist where user data is collected (retention: data.md#retention). Not legal advice.

## runbooks
- [ ] One short runbook per recurring incident: deploy/rollback, restore from backup (data.md#backup), DLQ redrive (async.md#queues), rotate a leaked secret, restart/scale. Each states who gets paged and how to verify recovery. README states how to run, test and deploy. General practice, no source read.

## UNVERIFIED
- OWASP CI/CD page: only the ten risk titles were read, not the mitigation text.
- Dependabot page: only the first 100,000 characters; `cooldown` 3-day default and 5-PR limit come from the fetch summary. Renovate not read; supply-chain tooling (SLSA, SBOM, Scorecard) not read.
- Conventionalcommits spec read in full via summary; commitlint/semantic-release tooling not read.
- ISO 10002 (complaint handling, referenced in the plan for feedback/support) could not be read: UNVERIFIED, no claim made from it.
- License selection, legal documents, runbook content and CI gating advice: general practice, no source read.
