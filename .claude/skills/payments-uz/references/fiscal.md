# Fiscalization (Payme, Click)
Read 2026-10-30. Payme pages read in full via WebFetch; the Click page read via Playwright (rendered text only, nothing submitted).
- https://developer.help.paycom.uz/initsializatsiya-platezhey/otpravka-cheka-po-metodu-post/ (receipt via POST form, `detail`)
- https://developer.help.paycom.uz/metody-merchant-api/setfiscaldata (SetFiscalData)
- https://docs.click.uz/merchant-api/fiscalization (Click Merchant API, "Фискализация данных")

## Payme: `detail` in the checkout POST form
- `detail` is a JSON object, Base64-encoded, sent as the `detail` hidden input. Amounts (item `price`, `discount`, shipping `price`, form `amount`) are in tiyin.
- Top level: `receipt_type` (page text "Продажа/Возврат = 0"; only value 0 is shown), `shipping` {title, price} optional, `items[]`. The page calls `items` optional in the table but "required for fiscalization" in the example comment.
- Item fields, required: `title` (string), `price` (number, tiyin per unit), `count` (number), `code` (string, IKPU), `package_code` (string, packaging code taken from the found IKPU's details on the tax site), `vat_percent` (number). Optional: `discount` (tiyin, for the whole quantity), `units` (number, unit-of-measure code, depends on the product).
- Example item: title "Помидоры", price 505000, count 2, discount 10000, code "00702001001000001", units 241092, vat_percent 15, package_code "123456".

## Payme: SetFiscalData (Merchant API, we receive)
- Not mandatory. Payme calls it on our billing after a receipt succeeds. Params: `id` (Payme receipt id), `type` ("PERFORM" or "CANCEL"), `fiscal_data` {receipt_id, status_code, message, terminal_id, fiscal_sign, qr_code_url, date}.
- Reply `{result:{success:true}}`; errors -32001 receipt not found, -32700 bad JSON, -32602 bad params.
- The tax authority issues two separate fiscal receipts (payment and cancellation): store the CANCEL `fiscal_data` as its own record.

## Click: Merchant API fiscalization (we call Click)
- Auth on every request: header `Auth: merchant_user_id:digest:timestamp`, `digest` = sha1(timestamp + secret_key), `timestamp` = 10-digit UNIX time. Headers `Accept`, `Auth`, `Content-Type`; formats application/json, application/xml.
- Submit items: `POST https://api.click.uz/v2/merchant/payment/ofd_data/submit_items`. Body: `service_id` (int), `payment_id` (long, Click payment id), `items` (Item[], required, at least one), `received_ecash`, `received_cash`, `received_card` (int, tiyin).
- Item required (marked *): `Name` string(63) (with unit of measure), `SPIC` string(17) (IKPU), `PackageCode` string(20), `Price` uint64 (total of the line, tiyin), `Amount` uint64 (quantity), `VAT` uint64 (VAT sum, tiyin), `VATPercent` int, `CommissionInfo` {`TIN` string(9) or `PINFL` string(14); must contain one of them}. Optional: `Barcode` string(13), `Labels` string[300] (marking codes), `Units` uint64, `GoodPrice` uint64 (per unit), `Discount` uint64, `Other` uint64 (other discounts).
- Submit QR: `POST https://api.click.uz/v2/merchant/payment/ofd_data/submit_qrcode`. Body: `service_id`, `payment_id`, `qrcode` (string, link to the fiscal receipt, e.g. an ofd.soliq.uz/epi?... URL).
- Get fiscal data: `GET https://api.click.uz/v2/merchant/payment/ofd_data/:service_id/:payment_id` -> `{paymentId, qrCodeURL}`.
- Submit responses: `{"error_code":0,"error_note":"Success"}`. Non-zero codes are not listed on this page.

## Rules that follow
- Take IKPU `code`, `package_code`, `vat_percent` and prices from our own catalogue/order, never from the request; sum of items must equal the order amount (see UNVERIFIED).
- Idempotent store of SetFiscalData by receipt `id` + `type`.
- Click: the Auth secret_key stays server-side in env; send submit_items only for payments we confirmed ourselves, with amounts from our order.

## UNVERIFIED
- Click: error codes for ofd_data calls; whether `Price` must equal `GoodPrice` x `Amount` and whether received_* must sum to the payment amount (page silent); when to call submit_items relative to Complete; whether submit_qrcode is an alternative to submit_items (page does not say); the separate sidebar page "Фискализация товаров и услуг" was not read; field-name casing (PascalCase in Items table, snake_case elsewhere) is as shown, not confirmed against a live call.
- Payme: whether the sum of items (+ shipping - discount) must equal `amount` is not stated on the page; whether `receipt_type` 1 is refund; the `status_code` list (page refers to a list it does not include); the `perform_data`/`cancel_data` combined structure is mentioned but not specified.
- Payme `items` required or optional in the POST form: the page contradicts itself; treat as required when the merchant is fiscalized.
- Payme receipts.create (Subscribe API) fiscal fields were not read.
