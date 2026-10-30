# Ops areas: config-secrets, errors, logging, audit-log, monitoring-slo, health-shutdown
Read 2026-10-30 from rfc-editor.org/rfc/rfc9457.html, cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html, opentelemetry.io/docs/concepts/context-propagation/, sre.google/sre-book/monitoring-distributed-systems/, sre.google/sre-book/service-level-objectives/, kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/. Stack-neutral.

## config-secrets
- Pointer only: security skill and user/rules/web-security.md are the SOT (secrets, env files, `.env.example`). Do not copy rules here. Check: config read in one module, fails fast at startup when a required value is missing.

## errors
- [ ] One error-handling module maps internal errors to a single response shape (RFC 9457 problem+json is the standard choice); unknown errors become a generic 500 with a correlation id. Source: https://www.rfc-editor.org/rfc/rfc9457.html
- [ ] No stack traces, SQL or hostnames in responses: problem details expose the HTTP interface, not debugging internals (RFC 9457 sections 4-5).
- [ ] Do not swallow errors: every catch logs with context or rethrows; background jobs report failures somewhere a human sees.
- [ ] Logging failure must not crash the app or leak data. Source: OWASP Logging Cheat Sheet below.

## logging
- [ ] Structured (JSON) logs with level, event time, request/trace id, user id (not email), route, status, duration. Sanitize CR/LF and cap size of user-supplied values (log injection). Source: https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html
- [ ] Log: auth successes/failures, authorization and validation failures, startup/shutdown/config changes, privileged actions, data import/export, file uploads.
- [ ] Never log passwords, tokens, keys, session ids, connection strings, card/bank data, sensitive PII (same source).
- [ ] Correlation: a trace/request id propagated across services (W3C `traceparent` header by default in OpenTelemetry) and attached to logs. Source: https://opentelemetry.io/docs/concepts/context-propagation/
- [ ] Logs shipped off the host, access restricted, retention set; alert if logging stops (OWASP).

## audit-log
- [ ] Who/what/when/old-to-new for: role and permission changes, admin actions, money movements, PII reads/exports, deletions. Event list from OWASP "higher-risk actions". Source: OWASP link above.
- [ ] Append-only: app role has INSERT but no UPDATE/DELETE on the audit table; tamper detection or off-host copy (OWASP: tamper detection, read-only media).
- [ ] Separate from debug logs; retention follows data.md#retention.

## monitoring
- [ ] Track the four golden signals: latency (success and error separately), traffic, errors (including wrong 200s), saturation. Source: https://sre.google/sre-book/monitoring-distributed-systems/
- [ ] Page on user-visible symptoms; causes are for dashboards. Every page is urgent, actionable and needs human judgment (same source).
- [ ] Define few SLIs/SLOs from user needs, using percentiles (e.g. p99), with an error budget; start loose and tighten. Source: https://sre.google/sre-book/service-level-objectives/
- [ ] External uptime check from outside the host plus error tracking; one named owner for alerts.
- [ ] Bot: alert on webhook failures/backlog (BOT profile; user/rules/telegram-bot.md).

## health-shutdown
- [ ] Separate endpoints: liveness (process only) and readiness (can serve, including dependencies). Liveness must NOT check the database or other remote services, else a dependency blip restarts every replica at once. Source: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/ (the dependency warning came from the fetch summary and may be general guidance, see UNVERIFIED)
- [ ] Failing readiness removes the instance from traffic without restarting it; slow-starting apps use a startup probe (same page).
- [ ] On SIGTERM: stop accepting new work, finish in-flight requests and jobs, close DB/queue connections, within the grace period (Kubernetes default 30 s per fetch summary).
- [ ] Jobs and webhook handlers are safe to re-run after a hard kill (see api.md#idempotency).

## UNVERIFIED
- Kubernetes page: only the first 100,000 characters were returned; the fetch tool stated the external-dependency liveness warning and graceful-termination details came from general guidance, not visible text. Default 30 s grace period likewise.
- SRE book: read via a summarising tool; chapters' remaining sections (alert design chapters, burn rates) not read.
- OpenTelemetry page: only the concept page; no SDK specifics.
- Audit-log table design (INSERT-only role, off-host copy beyond OWASP's wording), alerting owner, uptime-check advice, log retention periods: general practice, no source read.
- `## config-secrets` is a pointer only; nothing new was sourced.
