# API areas: api-design, idempotency, rate-limit, caching
Read 2026-10-30 from google.aip.dev/158, datatracker.ietf.org/doc/draft-ietf-httpapi-idempotency-key-header/, docs.stripe.com/api/idempotent_requests, rfc-editor.org/rfc/rfc9111.html, core.telegram.org/bots/faq, rfc-editor.org/rfc/rfc9457.html. Stack-neutral.

## design
- [ ] Every list endpoint is paginated from day one (adding it later is a breaking change); page size optional with a documented default and a hard maximum; cursor token is opaque and URL-safe; empty next token marks the end. Source: https://google.aip.dev/158
- [ ] A page token is not authorization: every page request is re-authorized (same source). Other filters must stay identical across pages.
- [ ] Errors use one shape, preferably RFC 9457 `application/problem+json` (type, title, status, detail, instance); `status` must match the HTTP status; never put stack traces or internals in the body. Source: https://www.rfc-editor.org/rfc/rfc9457.html
- [ ] Versioning policy chosen (URL or header) before the first external client; additive changes only inside a version.
- [ ] Input validation, authN, roles: security skill and user/rules/web-security.md (SOT, do not copy). Layering and where code lives: architecture skill.

## idempotency
- [ ] Every non-idempotent write that clients may retry (payments, orders, sends) accepts an `Idempotency-Key`; client generates a random key (UUID v4 style). Sources: https://docs.stripe.com/api/idempotent_requests, https://datatracker.ietf.org/doc/draft-ietf-httpapi-idempotency-key-header/
- [ ] Server stores key + request fingerprint + first response; a retry returns the stored response (Stripe v1 stores status and body, including 500s).
- [ ] Same key with a different payload is rejected (IETF draft: 422; Stripe: error); a retry while the first is still running gets 409 (draft).
- [ ] Keys are kept long enough for realistic retry windows: Stripe v1 may prune keys at least 24 hours old; keys up to 255 chars; do not use personal data as keys. Source: Stripe page above.
- [ ] Incoming webhooks and provider callbacks: dedupe on the provider's transaction id with a UNIQUE constraint (payments-uz skill is the SOT).
- [ ] Test: the same request sent twice concurrently creates exactly one record.

## rate-limit
- [ ] Limits per identity (user/API key/IP) on login, signup, password reset, OTP/SMS, expensive search and any write; limiter lives in one shared middleware (Protected Path), not per route.
- [ ] Exceeded limit returns 429 with a Retry-After hint (practice; no source read here); clients back off.
- [ ] Outbound Telegram limits respected by a queue: avoid more than 1 message/s to one chat, at most 20 messages/min in one group, about 30 messages/s for broadcasts; exceeding gives 429. Source: https://core.telegram.org/bots/faq (Telegram bot rules: user/rules/telegram-bot.md).
- [ ] Limiter store survives restarts and is shared across instances (e.g. Redis) when more than one instance runs.
- [ ] Usage/cost limits for paid downstream calls (SMS, LLM) per user per day.

## caching
- [ ] Responses with personal data: `Cache-Control: private` or `no-store`; both control storage only, not privacy guarantees. Source: https://www.rfc-editor.org/rfc/rfc9111.html
- [ ] A shared cache (CDN/proxy) must not reuse a response to a request carrying `Authorization` unless the response allows it with `public`, `must-revalidate` or `s-maxage` (same source). Never add `public` to authenticated endpoints by default.
- [ ] Cache keys include everything the response varies on (user, language, tenant); `Vary` set accordingly.
- [ ] App-level cache (Redis, memory) has a TTL and an invalidation point on every write path; stale-data tolerance stated per entry.
- [ ] Static assets are fingerprinted with long max-age; HTML and API default to short or none.

## UNVERIFIED
- RFC 9111 final ~7,500 characters not read; Authorization/no-store/private statements come from the part read.
- Idempotency-Key draft (-08) is an Internet-Draft and may change; 409/422 codes are from the fetch summary.
- Telegram FAQ: `retry_after` handling was not on the page read; Telegram's own API docs not read.
- Retry-After on 429, API versioning, Vary details, static-asset max-age advice: from general practice, no source read.
- Redis/shared-limiter advice: no source read.
