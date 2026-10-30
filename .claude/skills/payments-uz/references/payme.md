# Payme (Paycom) Merchant API
Read 2026-10-19 from developer.help.paycom.uz (protokol-merchant-api/*, metody-merchant-api/*, oshibki-errors, tipy-dannykh, initsializatsiya-platezhey/*). Sidebar labels of CheckPerformTransaction and CheckTransaction are swapped on the site: read by page title.

## Protocol
- JSON-RPC 2.0, HTTPS POST. Payme sends `Authorization: Basic base64(login:password)`; requests come from 185.234.113.1–15 only (allow-list is optional extra). Bad auth: error -32504.
- Always answer HTTP 200 (anything else is treated as -32400). TLS 1.0–1.2 must work.
- Amount: integer tiyin. Times: 13-digit ms. States: 1 created, 2 performed, -1 cancelled from 1, -2 cancelled from 2. Cancel reasons: 1–5, 10 (4 timeout, 5 refund).
- Methods: CheckPerformTransaction, CreateTransaction, PerformTransaction, CancelTransaction, CheckTransaction, GetStatement. GetStatement and CancelTransaction are mandatory. GetStatement: transactions with from <= time <= to, ascending by creation, only successfully created ones.
- If a response is lost Payme retries Create and Perform with the same parameters: handle them idempotently.

## Rules
- CheckPerform: order exists and is payable, amount equals the order → `{allow:true}`.
- Create: verify account and amount, reserve the order (status "awaiting payment"), store the Payme id with a UNIQUE constraint. If the transaction already exists, run the basic check and return the stored result.
- Perform: only from state 1 (else -31008). Cancel: of a fulfilled order -31007; works on states 1 and 2.
- Created transactions expire after 12 h (43,200,000 ms): state -1, reason 4 (job or lazy check).

## Errors
General: -32300 not POST, -32700 parse, -32600 bad structure, -32601 method not found, -32504 no privileges, -32400 system. Merchant: -31001 wrong amount, -31003 transaction not found, -31007 cannot cancel (fulfilled), -31008 impossible in this state, -31050..-31099 bad account input (localized `message` required, `data` names the account field).

## Checkout link
GET `https://checkout.paycom.uz/` + base64 of `m=<merchant>;ac.<field>=<order>;a=<tiyin>;l=<ru|uz|en>;c=<return url>;ct=<ms>;cr=<currency>` (page example: `a=500` is 5 sum). POST form variant: merchant, account[order_id], amount, lang, callback, callback_timeout, description, detail. Build `a` from the order amount on the server.

## UNVERIFIED (pages do not say; confirm in the Payme test cabinet)
- Exact reply to a repeated Perform on state 2 and a repeated Cancel on a cancelled transaction (the state diagram is an image). Safe default: return the stored result.
- Error code when an order already has another pending transaction (likely -31008 or -31099).
