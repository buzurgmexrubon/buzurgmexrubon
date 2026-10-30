# Click
Read 2026-10-19 (docs.click.uz: shop-api/requests, shop-api/errors, merchant-api/requests, click-button). Pages are Russian.

## SHOP-API (Click calls us): Prepare (action=0) then Complete (action=1)
- Click POSTs `application/x-www-form-urlencoded`; we reply `application/json`.
- Request fields: click_trans_id, service_id, click_paydoc_id, merchant_trans_id, amount (float, sum), action, error, error_note, sign_time (`YYYY-MM-DD HH:mm:ss`), sign_string; Complete adds merchant_prepare_id.
- sign_string = md5 of the plain concatenation of the received strings (do not reformat amount): Prepare `click_trans_id + service_id + SECRET_KEY + merchant_trans_id + amount + action + sign_time`; Complete inserts `merchant_prepare_id` after `merchant_trans_id`. SECRET_KEY comes from Click at onboarding.
- Reply fields: click_trans_id, merchant_trans_id, error, error_note, plus merchant_prepare_id (Prepare) or merchant_confirm_id (Complete).
- Prepare, in this order (codes from the error table below): sign mismatch -1; order missing -5; amount differs from our order -2; already paid -4; otherwise reserve the goods and reply 0 with `merchant_prepare_id`, as JSON. Complete: needs a matching Prepare; after a good Prepare and card debit it may fail only with -4 (already confirmed) or -9 (retry of a cancelled one).
- A negative `error` in a request from Click means the payment failed: cancel in our billing and answer -9.
- If delivery fails after the debit: answer Complete successfully, then reverse via the merchant API.

## Error codes (ours to return)
0 ok · -1 sign check failed · -2 wrong amount · -3 action not found · -4 already paid · -5 user/order not found · -6 transaction not found (merchant_prepare_id) · -7 failed to update user · -8 error in request from Click · -9 transaction cancelled.

## CLICK-API-MERCHANT (we call Click), base `https://api.click.uz/v2/merchant/`
- Header `Auth: merchant_user_id:digest:timestamp`, digest = sha1(timestamp + secret_key), timestamp = 10-digit unix time.
- GET `payment/status/:service_id/:payment_id`; GET `payment/status_by_mti/:service_id/:merchant_trans_id/YYYY-MM-DD`; GET `invoice/status/:service_id/:invoice_id`; POST `invoice/create` (service_id, amount, phone_number, merchant_trans_id); card_token request/verify/payment.
- Reversal: `DELETE payment/reversal/:service_id/:payment_id`. Only completed, online-card payments of the current month (previous month: only on the 1st day of the next month); UZCARD may refuse.

## Payment link
GET `https://my.click.uz/services/pay/?service_id=&merchant_id=&amount=&transaction_param=&return_url=&card_type=`: host is my.click.uz. Required: service_id, merchant_id, amount (`N.NN`), transaction_param (= our merchant_trans_id). Optional: return_url, merchant_user_id, card_type (uzcard|humo).

## UNVERIFIED
- payment_status value table of the merchant API; error_code table of reversal (only HTTP codes are documented).
- docs.click.uz/additional/telegram-payments (Telegram Mini App payments) exists but was not read.
