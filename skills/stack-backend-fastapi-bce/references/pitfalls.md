# Pitfalls (FastAPI backend; each happened once)

See `stack-common/references/pitfalls.md` for the technology-neutral ones (Makefile, pins, test database names, NUL characters, CORS order, index scans).

1. **Duplicate test file names** (`test_errors.py` in two layers): use pytest `--import-mode=importlib` and `pythonpath=["."]`, no `__init__.py` under `tests/`.
2. **ruff isort treats not-yet-existing packages as third-party:** set `[tool.ruff.lint.isort] known-first-party = ["<app>", "tests"]`.
3. **`Base` and `SessionDep` in one module** forces import-linter exceptions. Split `shared/db.py` and `shared/deps.py` from the start.
4. **Default 500 handler runs outside user middleware,** so the request id was empty; catch unhandled exceptions in the outermost app middleware.
