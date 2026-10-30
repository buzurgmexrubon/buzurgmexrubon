# Mobile and bot areas: mobile-release, bot-extras
Read 2026-10-30 from developer.android.com/google/play/requirements/target-sdk, docs.flutter.dev/deployment/obfuscate, core.telegram.org/bots/api (first 100,000 of ~582,000 characters only). Stack-neutral except where the platform is named.

## release
- [ ] Target API level meets Google Play policy. Page says "Starting August 31 2026": new apps and updates must target Android 16 (API 36) or higher (Wear OS and Automotive: API 35; Android TV and XR: API 34); existing apps need API 35 or higher to stay available to new users on newer Android versions; extension requests up to 1 Nov 2026. Source: https://developer.android.com/google/play/requirements/target-sdk
- [ ] Check the date in Play Console before every release: the page was updated 2026-10-28, so the deadline is already past as of this read date; confirm extension status in the help article the page links.
- [ ] Release builds are signed with a key kept out of the repo (config-secrets in ops.md); upload key/keystore backup exists.
- [ ] Flutter release: build with `--obfuscate --split-debug-info=<dir>`, keep the symbols files per release, de-obfuscate traces with `flutter symbolize -i <trace> -d <symbols>`. Obfuscation renames symbols only; it does not encrypt resources or protect secrets, so no secrets in the app. Source: https://docs.flutter.dev/deployment/obfuscate
- [ ] Code that depends on class/function names breaks when obfuscated (e.g. `runtimeType.toString()` checks); web builds are not obfuscated, only minified (same source).
- [ ] Crash reporting wired up, with a staged rollout and a force-update/min-version check for broken releases (monitoring: ops.md#monitoring). Flutter tooling: flutter skill.

## bot
- [ ] Rules for webhook secret, rate limits, callback_data, dedupe: user/rules/telegram-bot.md (SOT, do not copy).
- [ ] setWebhook `secret_token`: sent in header `X-Telegram-Bot-Api-Secret-Token` on every webhook request, 1-256 characters, only A-Z a-z 0-9 _ - allowed; compare it on every request. Source: https://core.telegram.org/bots/api
- [ ] Webhook ports supported: 443, 80, 88, 8443 (same source). `max_connections` 1-100, default 40; `drop_pending_updates` discards queued updates (same source).
- [ ] Webhook and getUpdates are mutually exclusive: getUpdates does not work while a webhook is set (same source). Record the choice in DECISIONS.
- [ ] Alert on webhook failures/backlog (ops.md#monitoring); handle bot blocked-by-user errors by marking the user inactive instead of retrying.

## UNVERIFIED
- Play page: the fetch tool returned a summary; the "extension forms later this year" wording and the help-article link were not followed. Whether the deadline or extension changed after 2026-10-28 is unknown.
- Apple App Store requirements (minimum Xcode/SDK, privacy manifests, review rules): not read.
- Flutter page does not describe uploading symbols to a crash service; Crashlytics/Sentry symbol upload steps not read.
- Telegram Bot API page: only the first 100,000 characters were read; broadcast/rate-limit text (about 30 msg/s overall, 1 msg/s per chat is quoted in user/rules/telegram-bot.md, not verified here), paid broadcasts and webhook IP ranges were not read. Dead-user handling is general practice.
- Staged rollout, force-update and keystore backup advice: general practice, no source read.
