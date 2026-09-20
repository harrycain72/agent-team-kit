# Contracts between the packs

A backend pack and a frontend pack each promise the following. If a pack cannot keep a promise, that is an ADR in the project, not a silent gap.

## Backend contract (every `stack-backend-*` pack)

- Lives in `backend/`, listens on port 8000, serves the API under `/api/v1` and a health endpoint at `/health` (liveness) with readiness.
- Reads configuration from environment variables; `.env.example` lists them all. Development and tests never share a database.
- Errors are `application/problem+json` carrying the request id (baseline BL-API); business errors map to 404, 409 and 422 as the baseline says.
- CORS is the outermost layer, so 4xx and 5xx responses (413, 500) carry CORS headers too; a test proves it.
- Schema changes only through migrations; a test proves models and migrations agree, that migrations apply to an empty database and that they downgrade (BL-OPS-4). A guard refuses to run tests against a database whose name does not end in `_test` (BL-OPS-5).
- Layer and dependency rules are enforced by tooling, in the test run (BL-OPS-7). The pack defines the layers.
- Tests: unit tests do no I/O and that is enforced mechanically (BL-TEST-4); ports have in-memory fakes proven by a contract suite that also runs against the real database (BL-TEST-5); integration tests run against real PostgreSQL with per-test isolation (BL-TEST-6); coverage gate 90 % line and branch (BL-TEST-3).
- Fills the Makefile targets `migrate`, `dev-backend`, `test-integration`, `test-backend` and the backend halves of `install`, `test-unit` and `lint`.

## Frontend contract (every `stack-frontend-*` pack)

- Lives in `frontend/` with its own `package.json`.
- Dev server proxies `/api` and `/health` to the backend on port 8000, so the browser sees one origin.
- `npm run` scripts, which the Makefile calls and nothing else:

| Script | Does |
|---|---|
| `dev` | dev server with reload |
| `test` | all unit and component tests once (no watch mode; CI-safe) |
| `test:cov` | the same with coverage; gate 80 % (lines, statements, functions, branches) |
| `lint` | linter and a full type check, including test files |
| `e2e` | Playwright against a running app on the `_e2e` database; at least one test per slice (BL-FLOW-5) |

- The API client speaks relative paths under `/api/v1`. Any error, including a malformed `problem+json` body, becomes one typed error carrying the parsed problem when there is one. It never retries a 4xx.
- Server field errors map onto form fields; other failures are shown as a toast; the user's input is kept.
- Every list has loading, error (with retry), empty (first use versus no match) and populated states, and a live region that announces counts and changes with correct singular and plural (BL-A11Y).
- Date-only values are parsed as local calendar dates, never through a UTC parse; date logic is tested under several time zones.
- A mapping test fails if a source module has no test file; exemptions (generated code, types-only files, bootstrap) are listed with a reason (BL-TEST-2).
- Fills the Makefile targets `dev-frontend`, `test-frontend`, `e2e` and the frontend halves of `install`, `test-unit` and `lint`.
