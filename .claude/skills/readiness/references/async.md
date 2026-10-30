# Async areas: queues, notifications
Read 2026-10-30 from docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html. Stack-neutral; SQS is one example of a queue, the DLQ ideas apply to any broker.

## queues
- [ ] Every queue has a dead-letter queue (DLQ) for messages that keep failing, so they can be inspected instead of retried forever or lost. Source: https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html
- [ ] Set the max-receive/retry count high enough to survive transient errors; too low (SQS example: 1) moves a message to the DLQ after a single failure (same source).
- [ ] DLQ retention longer than the source queue's: on SQS standard queues expiry counts from the original enqueue time, so a short DLQ retention deletes messages early (same source).
- [ ] Alarm on DLQ depth (any message arriving is a signal) and keep a documented redrive procedure (see delivery.md#runbooks).
- [ ] Consumers are idempotent: delivery is at-least-once in most brokers, so a job may run twice (see api.md#idempotency). Jobs shut down cleanly on SIGTERM (ops.md#health-shutdown).
- [ ] Ordered (FIFO) queues: a DLQ can break ordering; SQS docs warn against using one where order matters (same source).

## notifications
- [ ] Pointer only: no page was read for this area. Check: one notification module owns sending (email/push/chat), sends go through the queue above, user opt-out and per-channel preferences are stored, and sends are rate-limited and deduplicated (see api.md#rate-limit).
- [ ] Bot channel limits and 429 retry_after handling: user/rules/telegram-bot.md (SOT).

## UNVERIFIED
- Only the SQS DLQ page was read (fetch tool summary of the full page); other brokers' DLQ behaviour (RabbitMQ, Redis, BullMQ, Kafka) not read.
- `## notifications` is general practice (opt-out, dedupe, preferences); no source read. Push provider (FCM/APNs) limits and email deliverability rules (SPF/DKIM/DMARC, unsubscribe headers) not read.
- Alarm-on-DLQ advice is general practice; the SQS page only links a CloudWatch alarms page that was not fetched.
