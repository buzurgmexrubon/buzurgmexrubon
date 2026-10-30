---
paths:
  - "**/bot/**"
  - "**/bots/**"
  - "**/handlers/**"
  - "**/*bot*.py"
  - "**/*bot*.ts"
  - "**/*bot*.go"
---
# Telegram bots
## Conventions
<!-- why: the user builds many Telegram bots; these are the recurring failure points -->
- Webhook vs long polling is a project decision: check `.claude/DECISIONS.md`; if absent, ask and record it before coding.
- Webhook: HTTPS endpoint with a secret path/`secret_token` header verified on every request; answer 200 fast, do work async.
- Bot token comes only from the environment (`BOT_TOKEN`); never in code, fixtures, logs or error messages. `.env.example` holds a placeholder only.
- Rate-limit per user id (token bucket or counter with TTL), not globally; respect Telegram's limits (about 30 msg/s overall, 1 msg/s per chat) and handle 429 `retry_after`.
- Validate `callback_data`: it is client-controlled. Max 64 bytes; parse against a strict format, check the user may act on that object, ignore unknown values.
- Idempotent updates: dedupe on `update_id` (store last processed or a short-TTL set); handlers must be safe to run twice.
- Escape user text for the chosen `parse_mode`; never build HTML/Markdown from raw input.
## Commands
<!-- why: #8 detect real commands instead of guessing -->
- Detect the framework from deps (aiogram, python-telegram-bot, telegraf, grammY, go-telegram-bot-api, telebot) and use the language rule's commands (python.md, typescript.md, go.md).
- Test handlers with fake updates; never call the real Bot API from tests.
## Review checks
<!-- why: reviewer agent loads this section for bot diffs -->
- Token literal anywhere, or token logged; webhook without secret verification.
- Handler without per-user rate limit; unvalidated `callback_data`; admin actions without an id allowlist check.
- Handler re-implementing auth/ownership checks instead of the shared Protected Path layer.
- Non-idempotent side effects (payments, DB writes) without `update_id` dedupe; blocking calls in the update loop.
