---
name: telegram-auth
description: Login via Telegram (Mini App initData, OIDC login, legacy widget) with server-side validation. USE FOR: adding or reviewing Telegram-based auth/sessions in a web app, API or bot. DO NOT USE FOR: bot message handlers, payments, non-Telegram auth.
---

<!-- why: #10 #11 Telegram auth is reused in nearly every project and the classic bugs are trusting client data, mixing the key schemes and skipping auth_date. Facts read 2026-10-19 from core.telegram.org/bots/webapps, /bots/telegram-login and /widgets/login-legacy. This is the authn layer of the Protected Path: one SOT module. -->

# Telegram auth

Re-check the cited page before a non-trivial integration. One SOT function validates; every protected route reaches it through the shared auth middleware.

## Mini App initData (core.telegram.org/bots/webapps, "Validating data")
- Server side only; parse the raw `initData` query string, never trust `initDataUnsafe`.
- `data_check_string`: all fields except `hash`, sorted alphabetically, `key=value` joined by LF. UNVERIFIED: whether `signature` stays in the HMAC string (the page excludes it only in the Ed25519 scheme). Test with real initData from your bot and keep what validates.
- `secret_key` = HMAC_SHA256(key `"WebAppData"`, message bot_token). Accept if hex(HMAC_SHA256(key secret_key, data_check_string)) equals `hash`.
- Without the bot token (third party): `signature` is Ed25519 (base64url) over `<bot_id>:WebAppData` + LF + the sorted fields (without hash and signature). Public keys (hex): production `e7bf03a2fa4602af4580703d88dda5bb59f32ed8b02a56c187fe7d34caed242d`, test `40055058a4ee38156a06562e52eece92a771bcd8346a8c4615cb7376eddf72ec`. Re-check them on the page before pinning.

## Browser login (core.telegram.org/bots/telegram-login): OIDC
- Authorization code flow with PKCE (S256), scope `openid`, set `nonce`. Endpoints: `https://oauth.telegram.org/auth`, `/token` (Basic client_id:client_secret), JWKS `/.well-known/jwks.json`. Register allowed URLs in @BotFather.
- Validate the id_token: signature by JWKS (RS256), `iss` = `https://oauth.telegram.org`, `aud` = your bot id, `exp`, `nonce`. No UserInfo endpoint.

## Legacy Login Widget (core.telegram.org/widgets/login-legacy, archived)
- Same data_check_string; `secret_key` = SHA256(bot_token) (plain hash, NOT the Mini App scheme). Prefer OIDC for new work.

## Always
- Constant-time compare; reject missing `hash` or `auth_date`. The docs give no max age for `auth_date`: pick a short TTL for login (minutes to a few hours) and reject future values.
- After validation issue your own short-lived session bound to `user.id`; replays inside the window are possible, so use a one-time nonce for high-risk actions.
- User id only from validated data. Bot token and client secret stay server-side, never in the client or logs.
- Tests: valid payload, tampered field, stale `auth_date`, missing hash, wrong scheme (widget vs Mini App).
