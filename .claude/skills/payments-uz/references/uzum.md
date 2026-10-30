# Uzum (developer.uzumbank.uz, public docs; read 2026-10-19)
Portal lists Checkout, Merchant (webhooks), FastPay, Dynamic QR, Nasiya, CrossBorder, Fiscalization and more. Only Checkout and Merchant were read.

## Checkout 1.10.3 (we call Uzum)
- Headers `X-API-Key`, `X-Terminal-Id` (uuid), `Content-Language` (ru-RU|uz-UZ|en-EN). Base host: NOT FOUND on the page: get it from onboarding.
- Endpoints: POST /api/v1/payment/register (payType ONE_STEP|TWO_STEP; operationType PAYMENT|BINDING), /api/v1/acquiring/refund, /payment/merchantPay, /api/v1/acquiring/getBindings, unBindCard, getMerchantCertificate, purchaseReceipt.
- register body: amount* (integer, smallest unit = tiyin), currency* (860), orderNumber* (1–36 chars), clientId*, viewType* (WEB_VIEW|IFRAME|REDIRECT), sessionTimeoutSecs* (600–1800), paymentParams*, optional successUrl, failureUrl, cart. Reply `{errorCode, message, result}` with orderId and payment page URL.
- Refund: header `X-Operation-Id` (uuid idempotency key); only after COMPLETED; full or partial. Statuses: REGISTERED, COMPLETED, DECLINED, REFUNDED.
- Callback fields: orderId, operationState, operationType, cardType, merchantOperationId, orderNumber, rrn, bindingId. We must answer 200 OK, else Uzum retries up to 5 times.
- Errors: 3027 order number exists, 3028 operation exists, 3000 wrong payment status, 3019/3021 wrong cancel/refund amount, 3020/3022 cancel/refund period expired.

## Merchant API (Uzum calls our webhooks)
- Verify `Authorization: Basic base64(login:password)` on every call. POST JSON: /check, /create, /confirm, /reverse, /status. Fields: serviceId, timestamp (ms), transId (uuid), params, amount (tiyin on /create).
- Statuses OK, CREATED, CONFIRMED, FAILED. No /confirm within 30 min of /create → FAILED. /status is retried up to 10 times.
- Errors are HTTP 400 with string `errorCode`: 10001 access denied, 10008 already paid, 10009 cancelled, 10010 transId already created (reply on repeated /create), 10011 wrong amount, 10014 not found, 10015 cancelled (on /confirm), 10016 already confirmed, 10017 cannot cancel, 10018 already cancelled, 99999 internal.

## UNVERIFIED / gaps
- Checkout callback authentication is NOT documented on the page (no signature/HMAC found). Do not trust the callback body alone: confirm the order state another way (no Checkout status endpoint was read: UNVERIFIED), and ask Uzum how callbacks are authenticated.
- Nasiya, FastPay, Dynamic QR, /confirm /reverse /status bodies: not read.
