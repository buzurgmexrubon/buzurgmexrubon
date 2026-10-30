---
paths:
  - "**/*.py"
  - "**/pyproject.toml"
  - "**/requirements*.txt"
---
# Python
## Conventions
<!-- why: #10 one standard per language; typed, boring, explicit code is cheapest to review -->
- Type-hint all public functions; use `pathlib`, f-strings, dataclasses/pydantic for structured data.
- No bare `except:` or `except Exception: pass`; catch the narrowest type and log or re-raise.
- No mutable default args; no `from x import *`; no `print` for diagnostics (use `logging`).
- I/O-bound code: `async` end to end; never call blocking libs (`requests`, `time.sleep`) inside `async def`.
- Pin deps in the project's own manager (uv/poetry/pip); do not add a second one.
## Commands
<!-- why: #8 flow too heavy - detect the real commands once instead of guessing -->
- Detect first: read `pyproject.toml` (`[tool.ruff]`, `[tool.pytest.ini_options]`, `[tool.mypy]`/`[tool.pyright]`), `Makefile`, `tox.ini`, CI files. Use what the project defines.
- Fallbacks: test `pytest -q`; lint `ruff check .`; format `ruff format .`; types `mypy .` or `pyright`.
- Runner: `uv run` if `uv.lock`, `poetry run` if `poetry.lock`, else the active venv.
- Run the narrowest test first (`pytest -q path::test`), full suite before reporting done.
## Review checks
<!-- why: reviewer agent loads this section for Python diffs -->
- Blocking I/O in async code; missing `await`; un-awaited coroutines.
- `subprocess` with `shell=True` on variable input; `eval`/`exec`; `pickle` on untrusted data; `yaml.load` without SafeLoader.
- SQL built with f-strings or `%`; secrets or tokens in code or log lines.
- Swallowed exceptions; mutable default args; new global state.
- New helper duplicating an existing one (SOT); new dependency without need; lint/test config edited to pass.
