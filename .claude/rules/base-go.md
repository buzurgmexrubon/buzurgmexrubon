---
paths:
  - "**/*.go"
  - "**/go.mod"
---
# Go
## Conventions
<!-- why: #10 one standard per language; idiomatic Go is explicit about errors and goroutine lifetime -->
- Handle every error; wrap with context: `fmt.Errorf("load config: %w", err)`. Compare with `errors.Is/As`.
- `context.Context` is the first parameter of anything that does I/O; never store it in a struct.
- Every goroutine has an owner and a stop condition (ctx cancel, WaitGroup, errgroup). No fire-and-forget.
- Accept interfaces, return structs; define interfaces at the consumer, keep them small.
- No `panic` for expected failures; no global mutable state; `defer` Close right after a successful open.
- Table-driven tests; `t.Helper()`, `t.Cleanup()`; use `t.Parallel()` only if tests share no state.
## Commands
<!-- why: #8 detect real commands instead of guessing -->
- Detect first: `go.mod` (module, Go version), `Makefile`/`Taskfile.yml` targets, `.golangci.yml`, CI files.
- Fallbacks: test `go test ./...`; race `go test -race ./...`; vet `go vet ./...`.
- Lint `golangci-lint run` if `.golangci.yml` exists; format `gofmt -l .` (or `goimports`); build `go build ./...`.
- After editing `go.mod` imports run `go mod tidy` and review the diff.
## Review checks
<!-- why: reviewer agent loads this section for Go diffs -->
- Ignored errors (`_ =`), `err` shadowing, errors compared with `==` instead of `errors.Is`.
- Goroutine leaks, unbounded goroutines, missing `ctx` propagation, `time.After` in loops.
- Data races: map access across goroutines, loop-variable capture (Go < 1.22), unsynchronised shared state.
- `defer` inside loops; unclosed `resp.Body`/files; nil-map writes; `http.Client` without timeout.
- SQL via string concatenation; secrets in logs; new helper duplicating an existing one (SOT).
