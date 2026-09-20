---
name: stack-backend-fastapi-bce
description: Backend pack for Python FastAPI + SQLAlchemy + Alembic on PostgreSQL, in BCE (boundary-control-entity) layers per business domain. Backend layout, layer rules, tooling, test seams and known pitfalls. Load with stack-common and a frontend pack when designing or implementing a project that names this backend.
---

# Backend pack: FastAPI, BCE

Source: the todo-app build (2026-09-19), ADR-1 to ADR-25 of that project. Fulfils the backend contract in `stack-common`. Replace `<app>` (Python package) and `<domain>` (business component, for example `todos`) throughout.

| Layer | Choice |
|---|---|
| Backend | Python, FastAPI, sync SQLAlchemy 2.x (typed `Mapped[]`), psycopg 3, Alembic, pydantic-settings; `uv` for dependencies |
| Backend tests | pytest, pytest-cov, pytest-socket, import-linter, ruff |

Reference files (`references/`):
- `layout.md` – the `backend/` tree and the commands behind the Makefile targets
- `bce-backend.md` – the BCE layers, dependency rules and the import-linter contracts
- `testing-seams.md` – test layout per layer, injectable seams, fakes and the contract suite, Postgres test isolation
- `pitfalls.md` – things that went wrong once; read before scaffolding (also read the common ones in `stack-common`)

Fixed ADR-style decisions carried over (record deviations as new ADRs):
1. Sync SQLAlchemy with plain `def` routes (FastAPI runs them in a threadpool). Async is a separate decision.
2. Middleware order: CORS, request-context (catches unhandled exceptions, builds the 500 problem), body-limit, routes.
3. Apps are factories: `create_app(settings)`, no module-level `app`; run with `uvicorn --factory`.
