# Product areas: feedback, stats-reports, analytics, i18n, a11y, search, feature-flags
Read 2026-10-30 from w3.org/TR/WCAG22/ (first 100,000 of ~270,000 characters), openfeature.dev/docs/reference/intro. Other areas here are general practice, see UNVERIFIED. Stack-neutral.

## feedback
- [ ] In-app way to report a problem or give feedback that attaches app version, platform and request/trace id (not personal data), and lands somewhere a named owner reads. Triage state (new/seen/done) is stored. General practice, no source read.

## reports
- [ ] Stats/report queries run against a read replica or pre-aggregated tables, not hot write tables; paginated and time-bounded; exports go through the audit-log (ops.md#audit-log) and respect timezone choice (data.md#timezone). General practice, no source read.

## analytics
- [ ] Define events and properties in one tracking plan/module, never ad-hoc strings per screen; no personal data in event properties; consent and opt-out honoured before sending (data.md#retention for privacy). General practice, no source read.

## i18n
- [ ] All user-visible strings come from one message catalogue; no concatenated sentences; plural, date, number and currency formatting via the platform locale APIs; right-to-left and text-expansion checked; default-language fallback. General practice, no source read.

## a11y
- [ ] Target WCAG 2.2 level AA. Conformance levels are A, AA, AAA; content conforming to 2.2 also conforms to 2.0 and 2.1; 4.1.1 Parsing was removed in 2.2. Source: https://www.w3.org/TR/WCAG22/
- [ ] New in 2.2 and relevant at AA/A: 2.4.11 Focus Not Obscured (Minimum) AA, 2.5.7 Dragging Movements AA, 2.5.8 Target Size (Minimum) AA, 3.3.8 Accessible Authentication (Minimum) AA, 3.2.6 Consistent Help A, 3.3.7 Redundant Entry A (same source; level table read, the criterion text of 2.5.7, 2.5.8, 3.3.x was not).
- [ ] Keyboard-only and screen-reader pass on core flows; labels on all inputs; colour contrast checked; automated checker in CI plus manual check.

## search
- [ ] Decide DB full-text (Postgres tsvector, indexes: data.md#indexing) versus a search service only when needed; queries are length-capped, parameterised and rate-limited; results re-authorised per user (security skill). General practice, no source read.

## feature-flags
- [ ] Flags are evaluated through one wrapper so the provider can change; OpenFeature is a vendor-neutral spec with: evaluation API, providers (translation layer to a flag system, vendor SDK, REST or file), evaluation context, hooks (validation, logging, telemetry), and events. Source: https://openfeature.dev/docs/reference/intro
- [ ] Each flag has an owner, an expiry/removal date, and a safe default if the provider is down; flag changes are audit-logged. Kill-switch for risky features (general practice).
- [ ] Do not use flags for authorization or secrets (roles: security skill, SOT).

## UNVERIFIED
- WCAG: page read via summarising fetch, first 100,000 characters only. The criterion texts of 2.5.7, 2.5.8 (24 CSS px minimum is commonly cited but NOT confirmed here), 3.2.6, 3.3.7, 3.3.8 were truncated and not read. Remaining sections of the spec not read.
- OpenFeature intro page does not cover default values on error or flag types; "safe default if provider down" is general practice.
- feedback, reports, analytics, i18n, search: no source read at all; entries are general practice. Candidates to read later: Unicode CLDR/ICU for i18n, Postgres full-text docs, GDPR/ePrivacy consent text.
- Flag lifecycle (owner, expiry) advice: general practice.
