# AI area: ai-api-layer (flag +AI)
Read 2026-10-30 from genai.owasp.org/llm-top-10/, platform.claude.com/docs/en/api/errors. Stack-neutral; Claude API is the example provider.

## api-layer
- [ ] All LLM calls go through ONE client module (SOT): model id, timeouts, retries, logging and cost accounting live there, never per feature. Check the claude-api skill for provider specifics.
- [ ] Retry only transient failures (connection errors, 429, 5xx incl. 529 overloaded) with exponential backoff and honour `retry-after`; do not retry 400/401/403/404/413. The official SDKs retry twice by default and honour `retry-after` (configurable via max_retries). Source: https://platform.claude.com/docs/en/api/errors
- [ ] A 429 caused by a spend cap has no `retry-after` and keeps failing until access resumes: alert on it, do not loop (same source).
- [ ] Record the `request-id` response header (also `request_id` in the error body) in logs for every call; support needs it (same source; ops.md#logging).
- [ ] Long outputs: use streaming or a batch API rather than a big non-streaming request (SDK expects non-streaming calls under 10 minutes); mid-stream errors can arrive after a 200, so handle error events (same source).
- [ ] Per-user and global usage limits plus a spend alert, enforced before calling the API (api.md#rate-limit; OWASP LLM10 Unbounded Consumption).
- [ ] Treat model output and tool calls as untrusted input: validate before use, give the model least privilege (OWASP LLM01 Prompt Injection, LLM05 Improper Output Handling, LLM06 Excessive Agency). Source: https://genai.owasp.org/llm-top-10/
- [ ] Do not send secrets or unneeded personal data in prompts or logs (OWASP LLM02 Sensitive Information Disclosure; data.md#retention). API key from env only (security skill, SOT).
- [ ] Pin the model id explicitly and have a fallback/degraded behaviour when the API is down; evals or golden tests guard prompt changes (tdd skill).

## UNVERIFIED
- OWASP page was read as a list of titles with truncated excerpts; the per-risk mitigation guidance was NOT read. The 2025 list (LLM01-LLM10) is as shown on the page.
- Claude errors page read in full; rate-limit tiers, `retry-after` semantics beyond that page, prompt caching, token counting and batch pricing were not read (see the claude-api skill).
- Model deprecation/fallback policy, evals practice and cost-budget numbers: general practice, no source read.
- Other providers (OpenAI, Gemini) error/retry behaviour: not read.
