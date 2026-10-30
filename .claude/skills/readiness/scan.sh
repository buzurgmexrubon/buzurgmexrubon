#!/usr/bin/env bash
# why: #11 cheap first pass of /base:readiness audit mode: grep-able production signals, no judgement.
# Read-only: no network, never executes repo code, never follows symlinks (a symlinked root is refused),
# output capped (SCAN_MAX_LINES, default 60), always exit 0. Unclear -> "unknown", never a guess.
# Output: area<TAB>found|missing|unknown<TAB>"signal: path". Area ids are the SKILL.md index ids (SOT).
set -u

root="${1:-.}"
max="${SCAN_MAX_LINES:-60}"
case "$max" in '' | *[!0-9]*) max=60 ;; esac
count=0

emit() { # area status signal evidence
  [ "$count" -ge "$max" ] && return 0
  count=$((count + 1))
  printf '%s\t%s\t%s\n' "$1" "$2" "$(printf '%s: %s' "$3" "$4" | tr -d '\000-\037' | cut -c1-200)"
}

case "$root" in -*) root="./$root" ;; esac # a root named like an option must not be read as one
if [ -L "$root" ]; then emit scan unknown root "refused: root is a symlink"; exit 0; fi
if [ ! -d "$root" ]; then emit scan unknown root "not a directory"; exit 0; fi
cd "$root" 2>/dev/null || { emit scan unknown root "cannot enter directory"; exit 0; }

# content greps skip tests, docs, fixtures, build output, lockfiles, minified files and markdown
EXC="--exclude-dir=node_modules --exclude-dir=.git --exclude-dir=vendor --exclude-dir=build --exclude-dir=dist --exclude-dir=.dart_tool --exclude-dir=.venv --exclude-dir=venv --exclude-dir=.next --exclude-dir=target --exclude-dir=coverage --exclude-dir=__pycache__ --exclude-dir=tests --exclude-dir=test --exclude-dir=__tests__ --exclude-dir=spec --exclude-dir=specs --exclude-dir=fixtures --exclude-dir=docs --exclude=*.md --exclude=*.min.js --exclude=*.map --exclude=yarn.lock --exclude=pnpm-lock.yaml --exclude=package-lock.json --exclude=Cargo.lock --exclude=poetry.lock"
CODE_INC="--include=*.js --include=*.mjs --include=*.cjs --include=*.jsx --include=*.ts --include=*.tsx --include=*.py --include=*.go --include=*.dart --include=*.rb --include=*.php --include=*.java --include=*.kt --include=*.rs --include=*.cs --include=*.sql --include=*.prisma"
CI_INC="--include=*.yml --include=*.yaml --include=*.sh --include=Makefile --include=*.gradle"

# word-bounded ERE around alternatives: "per_page" must not match inside "upper_pages"
wb() { printf '(^|[^A-Za-z0-9_])(%s)([^A-Za-z0-9_]|$)' "$1"; }
# files that are tests BY NAME (a.test.ts, a.spec.js, a_test.go, test_a.py, a.integration.test.ts) are never evidence
TESTNAME='/[^/]*(\.test\.|\.spec\.|_test\.)[^/]*$|/test_[^/]*\.py$'
# config files (next.config.js ...) mention libraries without using them: not evidence for dependency-type signals
CFGNAME='/[^/]*\.config\.(js|cjs|mjs|ts)$'
# grep -r never follows symlinks met while walking. set -f: the unquoted option lists must not glob.
# BSD grep lets --include win over --exclude, so minified files, maps and test-named files are dropped by the grep -v.
_g() { # include-list ERE [keep-path-ERE] [drop-path-ERE]
  set -f
  # shellcheck disable=SC2086
  grep -rIliE $EXC $1 -e "$2" . 2>/dev/null | grep -vE "\.(min\.js|map)$|$TESTNAME" | grep -E "${3:-.}" | grep -vE "${4:-^\$}" | head -1
  set +f
}
# first regular file matching ERE $1 in code files
gfind() { _g "$CODE_INC" "$(wb "$1")"; }
# same, plus root dependency manifests: a library is evidence only as a dependency NAME ($2, see dep_has),
# never as a loose text match in package.json, and never from *.config.* files
gfind_m() {
  local f
  f="$(_g "$CODE_INC" "$(wb "$1")" . "$CFGNAME")"
  [ -z "$f" ] && f="$(dep_has "$2")"
  printf '%s' "$f"
}
# same, in CI/build files
gfind_ci() { _g "$CI_INC" "$1"; }
# regular files by name (find does not follow symlinks by default)
_nf() {
  find . \( -name node_modules -o -name .git -o -name vendor -o -name .dart_tool -o -name .venv -o -name tests -o -name test -o -name __tests__ -o -name fixtures -o -name docs \) -prune -o -type f "$@" -print 2>/dev/null
}
# first such file; test-named files are skipped
nfind() { _nf "$@" | grep -vE "$TESTNAME" | head -1; }
# first nested directory (depth <= 4, real dirs only: find -type d never matches a symlink) with one of the given names
nested_dir() {
  local args=() n
  for n in "$@"; do args+=(-o -name "$n"); done
  find . -maxdepth 4 \( -name node_modules -o -name .git -o -name vendor -o -name .dart_tool -o -name .venv -o -name venv -o -name .next -o -name dist -o -name build -o -name target -o -name coverage -o -name fixtures -o -name docs \) -prune \
    -o -type d \( -false "${args[@]}" \) -print 2>/dev/null | head -1
}
isreal() { [ ! -L "$1" ] && [ -e "$1" ]; } # exists and is not a symlink

report() { # area signal evidence-or-empty status-when-empty
  if [ -n "$3" ]; then emit "$1" found "$2" "$3"; else emit "$1" "$4" "$2" "-"; fi
}

manifests=""
for m in package.json requirements.txt pyproject.toml go.mod pubspec.yaml Gemfile composer.json; do
  isreal "$m" && manifests="$manifests $m"
done
# dependency NAME (quoted, line-start or path-delimited), not a substring: "pg" must not match "pgp" or "upgrade"
dep_has() {
  local q="'" pat
  pat="(^|[\"${q}[:space:]/])($1)([\"${q}=<>~ ;:[@/]|\$)"
  # shellcheck disable=SC2086
  [ -n "$manifests" ] && grep -lIiE -e "$pat" $manifests 2>/dev/null | head -1
}
src="$(nfind \( -name '*.js' -o -name '*.ts' -o -name '*.py' -o -name '*.go' -o -name '*.dart' -o -name '*.rb' -o -name '*.php' \))"
html="$(nfind -name '*.html')"
server="$(dep_has 'express|fastify|koa|@nestjs|hapi|@hapi|flask|fastapi|django|aiohttp|sanic|starlette|hono|gin-gonic|labstack|rails|laravel')"
db="$(dep_has 'pg|mysql|mysql2|sqlite3|better-sqlite3|sequelize|typeorm|prisma|@prisma|knex|mongoose|sqlalchemy|psycopg|psycopg2|asyncpg|gorm|activerecord|doctrine')"

# status when there is no evidence: unknown if the project type cannot say the area applies
st_src() { [ -n "$src" ] && echo missing || echo unknown; }
st_server() { [ -n "$server" ] && echo missing || echo unknown; }
st_db() { [ -n "$db" ] && echo missing || echo unknown; }

# config, license, supply chain, CI
if isreal .env.example; then emit config-secrets found env-example .env.example; else emit config-secrets missing env-example "-"; fi
lic=""
for f in LICENSE* license* COPYING*; do isreal "$f" && { lic="$f"; break; }; done
report license license "$lic" missing
bot=""
for f in .github/dependabot.yml renovate.json .github/renovate.json; do isreal "$f" && { bot="$f"; break; }; done
report dependencies bot "$bot" missing
ci="$(find .github/workflows -maxdepth 1 -type f \( -name '*.yml' -o -name '*.yaml' \) 2>/dev/null | head -1)"
[ -z "$ci" ] && isreal .gitlab-ci.yml && ci=.gitlab-ci.yml
report ci-cd workflows "$ci" missing

# data
mig=""
for d in migrations db/migrate prisma/migrations alembic supabase/migrations; do
  if [ -d "$d" ] && [ ! -L "$d" ]; then mig="$d"; break; fi
done
[ -z "$mig" ] && mig="$(nested_dir migrations)"
report migrations dir "$mig" "$(st_db)"
report db-indexing index "$(gfind 'CREATE INDEX|CREATE UNIQUE INDEX|createIndex|add_index|@@index|index=True|db_index')" "$(st_db)"
report db-indexing foreign-keys "$(gfind 'FOREIGN KEY|REFERENCES [A-Za-z_"]+|ForeignKey|@relation')" "$(st_db)"
report retention-privacy soft-delete "$(gfind 'deleted_at|deletedAt|is_deleted')" "$(st_db)"

# runtime
report health-shutdown health "$(gfind '/health|/healthz|/readyz|/livez')" "$(st_server)"
report health-shutdown sigterm "$(gfind 'SIGTERM')" "$(st_server)"
report logging logger "$(gfind_m 'pino|winston|bunyan|getLogger|structlog|loguru|slog|zap|import logging' 'pino|winston|bunyan|log4js|structlog|loguru|go\.uber\.org/zap|logrus|zerolog')" "$(st_src)"
report monitoring-slo error-tracking "$(gfind_m 'sentry|sentry_sdk|@sentry|sentry_flutter|crashlytics|firebase_crashlytics' '@sentry|sentry|sentry-sdk|sentry_sdk|sentry_flutter|firebase_crashlytics|firebase-crashlytics')" "$(st_src)"
report rate-limit limiter "$(gfind_m 'rate-limit|ratelimit|rate_limit|slowapi|throttle|limiter' '[A-Za-z0-9@/_.-]*(rate-?limit|slowapi|throttl|limiter)[A-Za-z0-9_.-]*')" "$(st_server)"
report idempotency header "$(gfind 'Idempotency-Key')" "$(st_server)"
# pagination counts only in server-side paths; a match only in other files (UI components) is unknown
pg_re='per_page|page_size|pageSize|next_cursor|nextCursor|query\.(page|limit)|args\.get\(.(page|limit)'
pg="$(_g "$CODE_INC" "$(wb "$pg_re")" '/(server|routes?|routers?|handlers?|api|controllers?|backend|endpoints?|resolvers?|views)/|/[^/]*(route|handler|controller|router|server)[^/]*$')"
pg_st="$(st_server)"
[ -z "$pg" ] && [ -n "$(gfind "$pg_re")" ] && pg_st=unknown
report api-design pagination "$pg" "$pg_st"

# product, release, process
arb="$(nfind -name '*.arb')"
[ -z "$arb" ] && arb="$(gfind_m 'i18n|gettext|react-intl|i18next|flutter_localizations' 'i18next|react-i18next|next-i18next|next-intl|react-intl|vue-i18n|flutter_localizations|gettext|flask-babel')"
# next.config.* is evidence only with a real top-level i18n key (not a comment or string)
for f in next.config.js next.config.mjs next.config.cjs next.config.ts; do
  [ -z "$arb" ] && isreal "$f" && grep -qE '^[[:space:]]*i18n[[:space:]]*:' "$f" 2>/dev/null && arb="$f"
done
report i18n localization "$arb" "$([ -n "$src$html" ] && echo missing || echo unknown)"
if isreal pubspec.yaml; then
  report mobile-release obfuscate "$(gfind_ci '[-]-obfuscate')" missing
else emit mobile-release unknown obfuscate "-"; fi
cl=""
for f in .commitlintrc* commitlint.config.*; do isreal "$f" && { cl="$f"; break; }; done
report commits-versioning commitlint "$cl" missing

# tests
td=""
for d in tests test __tests__ spec; do
  if [ -d "$d" ] && [ ! -L "$d" ]; then td="$d"; break; fi
done
[ -z "$td" ] && td="$(nested_dir tests test __tests__ spec)"
[ -z "$td" ] && td="$(_nf \( -name '*_test.*' -o -name '*.test.*' -o -name '*.spec.*' -o -name 'test_*.py' \) | head -1)"
report tests dir "$td" "$(st_src)"
tc=""
isreal package.json && grep -q '"test"[[:space:]]*:' package.json 2>/dev/null && tc="package.json"
[ -z "$tc" ] && isreal Makefile && grep -q '^test:' Makefile 2>/dev/null && tc="Makefile"
[ -z "$tc" ] && isreal pyproject.toml && grep -q pytest pyproject.toml 2>/dev/null && tc="pyproject.toml"
[ -z "$tc" ] && isreal pubspec.yaml && grep -q flutter_test pubspec.yaml 2>/dev/null && tc="pubspec.yaml"
report tests command "$tc" "$(st_src)"
exit 0
