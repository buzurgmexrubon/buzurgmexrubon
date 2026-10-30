---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
  - "**/*.mjs"
  - "**/package.json"
---
# TypeScript / JavaScript
## Conventions
<!-- why: #10 one standard per language; strict types catch what review would otherwise have to -->
- Keep `strict: true`. No `any` (use `unknown` + narrowing); no `@ts-ignore` without a reason (`@ts-expect-error` with comment).
- Validate external data (HTTP bodies, env, JSON) at the boundary with a schema (zod/valibot) instead of casting.
- `async/await`; every promise is awaited or deliberately `void`ed; no `.then` chains mixed with `await`.
- Prefer `const`, named exports, early returns; no default-export barrels that hide cycles.
- Frontend: no `dangerouslySetInnerHTML`/`innerHTML` with user data; effects have correct dependency arrays and cleanup.
## Commands
<!-- why: #8 detect real commands instead of guessing -->
- Detect first: `package.json` "scripts" (test, lint, typecheck, build, format), `Makefile`, CI files.
- Package manager from the lockfile: `pnpm-lock.yaml` pnpm, `yarn.lock` yarn, `bun.lock`/`bun.lockb` bun, else npm. Never mix.
- Fallbacks: types `npx tsc --noEmit`; lint `npx eslint .` or `npx biome check .`; test per config (`vitest`, `jest`, `node --test`).
- Run the project's script (`pnpm test`), not the raw tool, when one exists.
## Review checks
<!-- why: reviewer agent loads this section for TS/JS diffs -->
- `any`, `as` casts on external data, non-null `!` on values that can be null, ignored promise rejections.
- Floating promises, `await` in loops that could be parallel, missing error handling on `fetch` (`res.ok`).
- XSS sinks (`innerHTML`, `eval`, `new Function`), secrets in client bundles (`NEXT_PUBLIC_`/`VITE_` prefixed secrets).
- New helper duplicating an existing one (SOT); new dependency for a one-liner; lockfile changed without a matching `package.json` change.
