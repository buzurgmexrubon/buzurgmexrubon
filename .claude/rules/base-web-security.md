---
paths:
  - "**/auth/**"
  - "**/api/**"
  - "**/routes/**"
  - "**/middleware/**"
  - "**/controllers/**"
  - "**/handlers/**"
---
# Web security
## Conventions
<!-- why: #10 one security standard; Protected Path = one shared layer every write passes through, not a list of directories -->
- Protected Path: every write/change passes ONE shared layer in this order: authentication, permission, ownership (resource belongs to this user), input validation, rate/usage limit. It lives in one SOT middleware/module; never re-implement it per route or feature, never skip it because "not asked".
- SOT: core systems (auth, DB access, API client, validation, config, error handling) each have one source-of-truth module; import it, never copy it.
- Public routes are an explicit allowlist. Ownership is checked per object (IDOR), not just "logged in". Rate-limit every write endpoint per user/IP, not only login/reset.
- Validate all input (body, query, params, headers, files) with a schema at the edge; reject unknown fields; cap sizes.
- SQL: parameterised queries or the ORM only. Never concatenate or f-string user input into SQL; identifiers come from an allowlist.
- Secrets: env or secret manager only. Never log tokens, passwords, cookies, `Authorization` headers or full request bodies; redact before logging.
- Hash passwords with argon2 or bcrypt. Session cookies are HttpOnly, Secure and SameSite. Tokens expire. Compare secrets in constant time.
- CORS: explicit origins, never `*` with credentials; CSRF protection on cookie-authenticated state changes.
- Errors to clients are generic; details go to server logs. No stack traces in responses.
## Commands
<!-- why: #8 detect real commands instead of guessing -->
- Use the language rule's test/lint commands; add or run a test for the denied path (401/403), not only the happy path.
- Scan: `gitleaks detect` or `git grep -nEi "(secret|token|password|api[_-]?key)\s*[=:]"` on the diff.
- Dependency audit if available: `npm audit`, `pip-audit`, `govulncheck ./...`, `cargo audit`.
## Review checks
<!-- why: reviewer agent loads this section for Protected Path diffs -->
- Write path bypasses, reorders or re-implements the shared Protected Path layer; missing ownership check (IDOR); role check only on the client.
- Duplicated auth, validation, DB-access, config or error-handling logic instead of importing its SOT.
- String-built SQL; unvalidated input reaching shell, file paths (`../`), URLs (SSRF) or templates.
- Secrets, tokens or PII in logs, error messages, URLs or committed files; `.env` staged.
- Wildcard CORS, disabled TLS verification, weak hashing (md5/sha1), write endpoint without rate limit.
