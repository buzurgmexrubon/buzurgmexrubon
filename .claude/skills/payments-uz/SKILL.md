---
name: payments-uz
description: Uzbekistan payment integration (Payme, Click, Uzum) with the checks that must not be skipped. USE FOR: adding or reviewing a Payme/Click/Uzum merchant endpoint, webhook, order payment flow. DO NOT USE FOR: Stripe/other countries, UI-only work, non-payment webhooks.
---

<!-- why: #11 payment code is repeated in most projects and its bugs cost money (double credit, wrong amount, forged callback). Provider facts live in references/ (one file per provider, each with its source URLs and read date); this file holds only the rules that apply to all of them. Pairs with web-security rules and the Protected Path. -->

# Payments in Uzbekistan

1. Read `references/<provider>.md` for the provider in question, then re-check the cited page if the integration is non-trivial or the read date is old. Facts marked UNVERIFIED must be confirmed before coding (global Honesty rule).
2. Put the provider logic in ONE SOT module per provider; routes only call it. Callbacks pass the Protected Path's authentication step first.
3. Finish with `references/checklist.md`: every line must be true, or reported as a gap.

## Rules for every provider
- Authenticate every callback (Payme/Uzum Merchant: Basic header; Click: md5 sign_string) with a constant-time compare before using the body. Uzum Checkout callbacks have no documented authentication: confirm the order state another way (see references/uzum.md), never trust the body alone. An IP allow-list, if the provider publishes one, is an extra layer, never a replacement.
- Amount comes from OUR order record, never from the request; compare exactly, mind units (Payme and Uzum: tiyin; Click: sum, decimals).
- Idempotent by the provider's transaction id: unique DB constraint; a repeated call returns the stored result, never a second credit.
- Money and order state change in one DB transaction; order states are explicit (new, awaiting payment, paid, cancelled) and every move is checked.
- Never log secrets, the auth header or card data. Keys in config/env, never in code.
- Test with the provider's test environment; one test per error code you return, plus replay, wrong amount, bad signature.
