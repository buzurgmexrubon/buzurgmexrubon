---
name: security
description: Defensive security audit of the user's own project code. USE FOR: security check/audit, "is this secure", IDOR/injection/auth/secrets review, hardening the user's own repo. DO NOT USE FOR: attacking third-party or production systems, scanning hosts you do not own, writing weaponised exploits.
---

<!-- why: #10 the user owns the projects and needs full security audits; stating scope and authorization up front removes needless refusals, and one fixed checklist keeps audits consistent. Pairs with the reviewer agent and ~/.claude/rules/web-security.md. -->

# Security audit (own project, defensive)

**Scope statement (assume it, repeat it in the report):** the user owns this code; this is a defensive audit of local source and the local/dev/staging environment only. Never touch production or third-party hosts. No real credentials printed; give `path:line` and the kind only.

1. **Map.** Entry points (routes, bot handlers, CLI, jobs), trust boundaries, the Protected Path layer (authn → permission → ownership → validation → rate limit) and where each write passes it.
2. **Checklist** (load matching `~/.claude/rules/<lang>.md` and `web-security.md` first): authn/session; authorization and ownership (IDOR on every id param); input validation; SQL/NoSQL/command/path injection; XSS/CSRF/SSRF/open redirect; unsafe deserialization; secrets in code, logs, git history, `.env.example`; rate limits and abuse of costly endpoints; webhook/signature checks; CORS and security headers; dependency advisories (`npm audit`, `pip-audit`, `govulncheck`, `cargo audit`, whichever the repo uses); debug flags and error leakage.
3. **Evidence rule.** Report a finding only with the traced path from untrusted input to sink, or the exact missing check. A PoC is allowed only as a test or `curl` against the local dev server; no scanning of external hosts.
4. **Report**, ranked by severity: `path:line`, problem, impact, one-line fix. Fix the confirmed ones only when asked; each fix gets a regression test (tdd skill).
5. **Close.** List what was checked and what was not (e.g. no running staging, no pentest of infra). Never say "secure"; say "no findings in the checked scope".
