---
paths:
  - "**/*.rs"
  - "**/Cargo.toml"
---
# Rust
## Conventions
<!-- why: #10 one standard per language; Rust's safety is only as good as its unsafe and error discipline -->
- Library code returns `Result` with a typed error (`thiserror`); binaries may use `anyhow`. Propagate with `?`.
- No `unwrap()`/`expect()` outside tests and provably-infallible cases; if used, `expect("why it cannot fail")`.
- Borrow before you clone; take `&str`/`&[T]` params; do not clone just to silence the borrow checker.
- `unsafe` only with a `// SAFETY:` comment stating the invariant; keep blocks minimal.
- Async: never hold a `std::sync::Mutex` guard across `.await`; no blocking calls on the runtime (`spawn_blocking`).
- Derive `Debug`; keep public API small; features in `Cargo.toml` stay additive.
## Commands
<!-- why: #8 detect real commands instead of guessing -->
- Detect first: `Cargo.toml` (workspace members, features, edition), `rust-toolchain.toml`, `Makefile`/`justfile`, CI files.
- Fallbacks: check `cargo check --all-targets`; test `cargo test`; lint `cargo clippy --all-targets -- -D warnings`.
- Format `cargo fmt --all` (verify with `--check`). In a workspace add `--workspace`; honour feature flags used in CI.
## Review checks
<!-- why: reviewer agent loads this section for Rust diffs -->
- `unwrap`/`expect`/indexing that can panic on external input; `as` numeric casts that truncate.
- `unsafe` without `SAFETY` comment; `transmute`; raw-pointer lifetimes.
- Guard held across `.await`; blocking I/O in async; unbounded channels or tasks.
- Needless `clone()`/`to_string()` in hot paths; `#[allow(...)]` added to silence clippy without reason.
- New helper duplicating an existing one (SOT); new crate for trivial code; wildcard versions.
