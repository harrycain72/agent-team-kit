# BCE (boundary, control, entity) per business domain

| Layer | Responsibility | Must not |
|---|---|---|
| **boundary** | REST routers, request/response schemas, dependency wiring, mapping control errors to problem+json | contain business rules; import the repository, mutate models, import `sqlalchemy` directly |
| **control** | use cases (the service): orchestration, transactions, business errors | know about HTTP (`fastapi`, `starlette`) |
| **entity** | domain model with behaviour and invariants, rules and constants, query criteria, the repository **Protocol** and its SQL implementation | import `fastapi`, `starlette`, `pydantic`, or control/boundary |

Dependency direction: `boundary -> control -> entity`. `shared` may be imported by all layers and imports no domain package. A domain's `control/__init__.py` is its public API; other domains reach it only through that, with ids as references and no cross-domain ORM relationships.

Rules:
1. Business rules live in entity (rules module, model methods) and are orchestrated by control. Pydantic constraints in boundary reference the same constants (one source of truth) for accurate 422 and OpenAPI, but control/entity validate again.
2. Each write use case ends with `repo.commit()`; repository methods only `flush`; the session dependency rolls back on exception.
3. The session reaches boundary only as `SessionDep` (in `shared/deps.py`); boundary passes it and the injected clock to `create_<domain>_service(session, clock)` in control, the only place control imports the SQL repository.
4. Boundary never builds a repository.
5. `shared/db.py` holds only `Base`, the engine factory and the session factory (framework-free) so entity can import `Base`; the FastAPI dependency lives in `shared/deps.py`.

## Enforcement (import-linter, plus a pytest that runs it)

```toml
[tool.importlinter]
root_package = "<app>"
include_external_packages = true

[[tool.importlinter.contracts]]
name = "BCE layers"
type = "layers"
layers = ["<app>.<domain>.boundary", "<app>.<domain>.control", "<app>.<domain>.entity"]

[[tool.importlinter.contracts]]
name = "shared kernel does not depend on domains"
type = "forbidden"
source_modules = ["<app>.shared"]
forbidden_modules = ["<app>.<domain>"]

[[tool.importlinter.contracts]]
name = "control and entity are HTTP-free"
type = "forbidden"
source_modules = ["<app>.<domain>.control", "<app>.<domain>.entity"]
forbidden_modules = ["fastapi", "starlette"]

[[tool.importlinter.contracts]]
name = "entity is pydantic-free"
type = "forbidden"
source_modules = ["<app>.<domain>.entity"]
forbidden_modules = ["pydantic"]

[[tool.importlinter.contracts]]
name = "boundary does not touch the ORM directly"
type = "forbidden"
source_modules = ["<app>.<domain>.boundary"]
forbidden_modules = ["sqlalchemy"]
allow_indirect_imports = true   # boundary reaches sqlalchemy through entity models by design

[[tool.importlinter.contracts]]
name = "framework-free shared modules"
type = "forbidden"
source_modules = ["<app>.shared.db", "<app>.shared.clock"]
forbidden_modules = ["fastapi", "starlette", "pydantic"]
```

Do not use a global `exclude_type_checking_imports = true` or `ignore_imports` to make a contract pass; fix the module split instead (the first build had to undo exactly that).

## Errors and middleware

- Control raises business errors (`NotFound`, `ValidationError` with `FieldError` entries); boundary registers handlers mapping them to problem+json.
- Middleware order, outermost first: CORS, request-context (request id, access log, catches unhandled exceptions and returns the 500 problem with matching header and body ids), body-limit (413), routes. Problem builders read `request.state.request_id`, not a contextvar (Starlette's default 500 handler runs outside user middleware).
- Preflight requests are answered by CORS alone and carry no request id or access-log line; do not test for them.
