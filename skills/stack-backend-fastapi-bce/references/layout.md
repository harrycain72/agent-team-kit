# Backend layout (FastAPI)

The repository root, `docs/`, compose and CI are in `stack-common/references/layout.md`. This pack defines `backend/`:

```
backend/
├── pyproject.toml       # deps, ruff (isort known-first-party), pytest (importlib mode), coverage gate, import-linter
├── alembic.ini, alembic/{env.py, versions/}
├── src/<app>/
│   ├── main.py          # create_app(settings=None) factory
│   ├── config.py        # Settings (pydantic-settings, env prefix)
│   ├── shared/          # shared kernel; imports no domain package
│   │   ├── db.py        # Base, make_engine(url), session factory  (NO fastapi/pydantic)
│   │   ├── deps.py      # get_session, SessionDep (FastAPI only; imported by boundary only)
│   │   └── clock.py, problem.py, request_context.py, logging.py, body_limit.py, health.py
│   └── <domain>/        # one BCE component per business domain
│       ├── __init__.py  # exports only: router, register_error_handlers
│       ├── boundary/    # router, schemas, dependencies, errors -> problem+json
│       ├── control/     # __init__ = public API; service, commands, errors
│       └── entity/      # rules, models, criteria, repository (Protocol), sql_repository
└── tests/{unit,integration,contract,architecture,support}/
```

Add to `.gitignore`: `.venv __pycache__ .coverage htmlcov`.

## Commands behind the Makefile targets

```
install (backend)   uv sync
migrate             db-up, then alembic upgrade head
dev-backend         uvicorn <app>.main:create_app --factory --reload --port 8000
test-unit (backend) pytest tests/unit
test-integration    db-up, pytest tests/integration tests/contract
test-backend        pytest --cov --cov-branch --cov-fail-under=90
lint (backend)      ruff check, ruff format --check, lint-imports
```
