# Data areas: db-indexing, migrations, backup-restore, retention-privacy, timezone
Read 2026-10-30 from postgresql.org/docs/current/ddl-constraints.html, postgresql.org/docs/current/sql-createindex.html, martinfowler.com/bliki/ParallelChange.html, docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/back-up-data.html, lex.uz/docs/4831939, cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html. Stack-neutral checklists; PostgreSQL is the worked example.

## indexing
- [ ] Every foreign-key (referencing) column that is joined or deleted-through has an index; PostgreSQL does NOT create it for you. A DELETE/UPDATE on the referenced table scans the referencing table. Source: https://www.postgresql.org/docs/current/ddl-constraints.html
- [ ] Every WHERE / ORDER BY / join column of a hot query is covered; check with the DB's EXPLAIN on realistic data volume, not an empty dev DB.
- [ ] Unique business keys (provider transaction id, external id, email) are UNIQUE constraints, not app-level checks.
- [ ] Building an index on a live table: PostgreSQL `CREATE INDEX CONCURRENTLY` avoids blocking writes but cannot run inside a transaction block (many migration tools wrap in one: disable that for this step); it takes two table scans and waits for old transactions. Source: https://www.postgresql.org/docs/current/sql-createindex.html
- [ ] After a failed concurrent build an INVALID index remains: it is ignored by queries but still costs on writes. Check `\d`, drop and retry (or REINDEX CONCURRENTLY). Same source.

## migrations
- [ ] Schema changes use parallel change: expand (add new alongside old), migrate (move readers/writers and backfill), contract (drop old only when nothing uses it). Source: https://martinfowler.com/bliki/ParallelChange.html
- [ ] Each deploy works with both the previous and the next schema (old code keeps running during rollout); never rename or drop a column in the same release that stops using it.
- [ ] Migrations are versioned files in the repo, run by one tool, applied in CI against a copy; none is edited after merge.
- [ ] Large backfills run in batches outside the schema migration; adding NOT NULL / defaults / indexes on big tables checked against the DB's locking rules (see indexing).
- [ ] A down/rollback path or an explicit "forward-fix only" note per migration.

## backup
- [ ] Every store that cannot be rebuilt is listed (DB, uploads, secrets/config); data that can be reproduced from sources is marked as such. Source: https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/back-up-data.html (REL09-BP01)
- [ ] RPO and RTO written down; backup frequency follows RPO.
- [ ] Backups are automatic, encrypted, and stored away from the primary (other account/region/provider) (REL09-BP02, BP03, titles only; sub-pages not read).
- [ ] A restore was actually performed and timed at least once, and is repeated on a schedule (REL09-BP04, title only). An untested backup counts as no backup.
- [ ] Backup credentials differ from app credentials; app cannot delete its own backups.

## retention
- [ ] Per PII field: why it is stored, how long, who can read it, how it is deleted (user request and automatic expiry), including backups and logs.
- [ ] Logs and audit trails exclude passwords, tokens, card data and unneeded PII (see ops.md#logging). Source: https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html
- [ ] Uzbekistan: the Law "On personal data" No. LRU-547, Article 27-1, as shown on lex.uz, requires data of Uzbek citizens processed with information technologies to be collected and stored on technical means physically located in Uzbekistan, in databases registered in the State Register of Personal Databases. Source: https://lex.uz/docs/4831939 (summary returned by the fetch tool, not a verbatim read of the statute; may predate the 2026 amendment).
- [ ] Not legal advice: have a lawyer confirm the current text before choosing hosting for personal data.
- [ ] Deletion path exists and is tested (hard delete or irreversible anonymization), not only a `deleted` flag.
- SOT for access control and secrets: security skill and user/rules/web-security.md (do not copy).

## timezone
- [ ] Store timestamps in UTC with an unambiguous type (timestamptz / epoch / ISO-8601 with offset); convert only at the display edge.
- [ ] Keep the event time separate from the record/log time when clients can upload late. Source: https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html
- [ ] Servers use synchronized clocks (NTP); scheduled jobs state their timezone (Uzbekistan is UTC+5, no DST: UNVERIFIED here).
- [ ] Day boundaries ("today", reports, daily limits) use the business timezone explicitly, never the server default.
- [ ] Payment provider timestamps: see payments-uz skill (Payme uses 13-digit ms; Click uses a local-format string).

## UNVERIFIED
- Kun.uz article on the 26 Mar 2026 amendment (kun.uz/en/news/2026/03/27/uzbekistan-amends-personal-data-law-to-facilitate-global-payment-systems): fetch returned only the headline. Claim that since 26 Mar 2026 only biometric, genetic and telecom-subscriber data must stay in Uzbekistan is NOT confirmed by anything read; the lex.uz text read (Art. 27-1) is the older general rule. Treat the current scope as unknown.
- lex.uz statute text was read through a summarising tool, not verbatim.
- AWS sub-pages REL09-BP01..04 were not opened; only the topic list.
- Uzbekistan UTC+5 / no DST: from memory, no source read.
- Backup tooling choices, restore cadence and RPO/RTO values: no source read; project-specific.
