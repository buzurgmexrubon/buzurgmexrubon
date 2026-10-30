---
name: readiness
description: Production-readiness gaps (logging, backup, indexes, rate limits, queues, uploads, AI layer...). USE FOR: new project, "is this production ready", adding endpoint/table/job/upload, pre-launch audit. DO NOT USE FOR: security pentest (use security), payment providers (use payments-uz), one-line fixes.
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scan.sh *)
---

<!-- why: #11 the same production gaps (no backup, no index, no rate limit, no audit log) repeat in every new project. One lazy skill keeps the listing budget small; areas point to existing SOT skills/rules and never copy them (D10).
Connects to: scan.sh (read-only grep signals), references/*.md (one per area group, each with source URL and read date, D2), .claude/READINESS.md (tracking), security, web-security, telegram-bot, telegram-auth, payments-uz, architecture, tdd. -->

# Production readiness

## Profile and flags
Pick ONE profile, then add flags. An area applies only if its profile or flag matches; others are N/A.
- Profiles: API (server), WEB (site/app with a server), BOT (Telegram/chat bot), APP (mobile/desktop), STATIC (no backend).
- Flags: PAY (takes money), AI (calls an LLM API), PII (stores personal data).

## Modes
- Feature mode (default, e.g. adding an endpoint, table, job, upload): load ONLY the areas that change touches, read their reference, apply, report gaps. Never load the whole index.
- Audit mode (`/base:readiness`, "is this production ready"): 1) run `${CLAUDE_SKILL_DIR}/scan.sh <repo root>`: lines `area<TAB>found|missing|unknown<TAB>evidence`; unknown stays unknown, never guess. 2) hand semantic items (scan said unknown, or the area needs reading code) to `explorer`. 3) rank gaps by severity (data loss, security, money, outage, then polish). 4) write the top 5 as numbered questions with lowercase lettered options, recommended first, into STATUS "Open questions". 5) write the full list to `.claude/READINESS.md` (copy `${CLAUDE_PLUGIN_ROOT}/templates/READINESS.md` if missing; rows `| area | open/fixed/N/A | note |`).
- Waiver: an area that does not apply is recorded as a DECISIONS line `readiness: <area> N/A | why`; waived areas are not reported again.

## Area index
Format: id | profiles | where. References: data, api, ops, async, files, ai, mobile-bot, product, delivery (D2: source URL + read date, unverified facts marked UNVERIFIED).
- config-secrets | all | security skill + references/ops.md#config-secrets
- auth | API WEB BOT | security, telegram-auth (SOT, do not copy)
- roles | API WEB | security skill (SOT)
- validation | API WEB BOT | security skill (SOT)
- errors | API WEB BOT | references/ops.md#errors
- logging | API WEB BOT | references/ops.md#logging
- audit-log | API WEB +PII +PAY | references/ops.md#audit-log
- monitoring-slo | API WEB BOT APP | references/ops.md#monitoring
- health-shutdown | API WEB BOT | references/ops.md#health-shutdown
- db-indexing | API WEB BOT | references/data.md#indexing
- migrations | API WEB BOT | references/data.md#migrations
- backup-restore | API WEB BOT | references/data.md#backup
- retention-privacy | +PII | references/data.md#retention
- timezone | API WEB BOT | references/data.md#timezone
- api-design | API WEB | references/api.md#design
- idempotency | API WEB +PAY | references/api.md#idempotency
- rate-limit | API WEB BOT | references/api.md#rate-limit
- caching | API WEB | references/api.md#caching
- queues | API WEB BOT | references/async.md#queues
- notifications | API WEB BOT APP | references/async.md#notifications
- uploads | API WEB BOT | references/files.md#uploads
- image-compression | API WEB APP | references/files.md#images
- tests | all | tdd skill (SOT)
- payments | +PAY | payments-uz skill (SOT)
- ai-api-layer | +AI | references/ai.md#api-layer
- feedback | WEB APP BOT | references/product.md#feedback
- stats-reports | API WEB | references/product.md#reports
- analytics | WEB APP STATIC | references/product.md#analytics
- i18n | WEB APP BOT STATIC | references/product.md#i18n
- a11y | WEB APP STATIC | references/product.md#a11y
- search | API WEB | references/product.md#search
- feature-flags | API WEB APP | references/product.md#feature-flags
- ci-cd | all | references/delivery.md#ci-cd
- dependencies | all | references/delivery.md#dependencies
- commits-versioning | all | references/delivery.md#versioning
- license | all | references/delivery.md#license
- runbooks | API WEB BOT | references/delivery.md#runbooks
- mobile-release | APP | references/mobile-bot.md#release
- bot-extras | BOT | telegram-bot rules + references/mobile-bot.md#bot
