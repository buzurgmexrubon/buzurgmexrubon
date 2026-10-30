---
name: architecture
description: Design-principles check for structural code changes. USE FOR: adding a module, service or endpoint, deciding where code lives, restructuring, "is this well designed". DO NOT USE FOR: one-line fixes, bug hunting (use debug), security audits (use security), framework choice.
---

<!-- why: the plugin enforces process (SOT, Protected Path, surgical changes) but nothing enforced design shape; a short checklist applied before writing and again in review keeps layering and abstraction honest without a big framework. Same list is used by the reviewer agent. -->

# Architecture check

Run before writing structural code, then re-run on the diff. Match the project's existing structure first (grep how a similar feature is built); never invent a new pattern.

1. **Layers, one direction.** transport (handler/route/UI) -> service (business rules) -> data access (repository/client). A lower layer never imports a higher one. No SQL, HTTP clients or env reads in handlers; no request/response objects in services.
2. **One reason to change.** A module or function that needs "and" to describe it is two units. Split only along an existing seam, not a speculative one.
3. **SOT and Protected Path.** Config, auth, validation, DB access and API client each live in one module that everything imports. A write path passes the shared Protected Path layer; never re-implement it per feature.
4. **No premature abstraction.** Extract a helper/interface only on the third real use, or when a second implementation exists today. No factories, plugin systems or flags for a single case.
5. **Dependencies point at stable things.** Inject collaborators (parameter or constructor) instead of constructing them inside business logic, so tests need no patching of globals.
6. **Errors have one owner.** Domain code raises/returns typed errors; only the transport layer maps them to status codes or messages. No swallowed errors, no error handling copied per call site.
7. **Small surface.** Export the minimum; no cross-module reach into another module's internals; no circular imports.

Output: a short list of violations as `path:line` + the rule number + a one-line fix, or "architecture ok". If a rule is knowingly broken, say why in one line instead of hiding it.
