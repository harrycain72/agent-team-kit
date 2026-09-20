# Test layout and seams

## Seams (constructor injection, no module-level singletons)

| Seam | Production | Test |
|---|---|---|
| Repository | `SqlAlchemy<Domain>Repository(session)` implementing a `typing.Protocol` | `InMemory<Domain>Repository` in `tests/support/`, proven equivalent by the shared contract suite |
| Session | request-scoped `Session` via `SessionDep` | SAVEPOINT-rolled-back session on the test database |
| Clock | `system_clock` | `FixedClock(start)` with `.advance(timedelta)`, rejects naive datetimes |
| Ids | `uuid4` | fixed id factory |
| Settings | env-based `Settings` | `Settings(_env_file=None, ...)` |

`create_app(settings)` is a factory; tests build apps with an in-memory repository (unit) or the real session (integration).

## Layout (`backend/tests/`)

| Path | Scope | I/O |
|---|---|---|
| `unit/<domain>/entity`, `unit/<domain>/control` | rules, model behaviour, use cases with the in-memory fake and fake clock | none (pytest-socket guard, autouse in `tests/unit`) |
| `unit/<domain>/boundary`, `unit/shared` | schemas, routers via TestClient with the in-memory repository, problem builders, middleware | none |
| `contract/` | one contract suite (`<Domain>RepositoryContract`) run against the fake AND against Postgres | none / DB |
| `integration/` | SQL repository, migrations, API against real Postgres, health/readiness | DB |
| `architecture/` | layer rules (runs import-linter), module-to-test-file mapping | none |
| `support/` | fakes and helpers (`fixed_clock`, `in_memory_..._repository`, `app_factory`) | none |

Frontend tests are defined by the frontend pack. Backend module-to-test mapping: a test fails if a non-exempt source module has no unit test file; exemptions (Protocols, generated code, pure configuration) are listed with a reason.

## Postgres in tests

- Same container as development, separate `<db>_test` database (created by the init SQL). Migrations applied once per session so every run also exercises them.
- Each test runs in a SAVEPOINT that is rolled back; no truncate needed.
- A name guard refuses to run against a database that does not end in `_test`.
- Tests that create or drop databases (migration tests) use a name unique per run (for example a uuid suffix), otherwise parallel runs collide.
- The contract suite runs on the fake and on Postgres, so the fake cannot drift.
