# Repository layout

```
<repo>/
├── Makefile                 # targets below
├── README.md                # quick start; state auth scope (local/trusted network only if no auth)
├── .gitignore               # .env, coverage output, plus what the backend and frontend packs add
├── .env.example             # committed; copy to .env (git-ignored)
├── docker-compose.yml       # postgres service: pinned image, named volume, healthcheck, loopback port
├── docker/postgres/init/01-create-databases.sql   # CREATE DATABASE <db>_test; CREATE DATABASE <db>_e2e;
├── .github/workflows/ci.yml # postgres service container; runs the same checks as `make check`
├── perf/                    # k6: script, helpers, seed.sql (own database <db>_perf)
├── docs/
│   ├── requirements.md      # one authoritative file
│   ├── architecture.md      # build specification: design, API contract, ADRs, slice plan
│   ├── tdd-log.md           # append-only red/green evidence per slice
│   ├── test-plan.md
│   └── arc42/               # optional; summarises and links to architecture.md
├── backend/                 # tree defined by the backend pack
└── frontend/                # tree defined by the frontend pack
```

## Makefile targets

The names are fixed by this pack so `make check` and CI look the same in every project. The commands behind them come from the pack in the last column.

| Target | Does | Filled by |
|---|---|---|
| `install` | install backend and frontend dependencies | both |
| `db-up` / `db-down` / `db-reset` / `db-logs` / `db-psql` | manage the compose database | common |
| `migrate` | `db-up`, then apply migrations to the development database | backend |
| `dev-backend` | run the backend with reload on port 8000 | backend |
| `dev-frontend` | run the frontend dev server (`npm run dev`) | frontend |
| `dev` | `db-up migrate`, then `dev-backend` and `dev-frontend` in parallel; the one development command (BL-OPS-1) | common |
| `test-unit` | backend unit tests and frontend `npm run test`; no database, the TDD inner loop | both |
| `test-integration` | `db-up`, backend integration and contract tests | backend |
| `test-backend` | backend tests with coverage gate 90 % (line and branch) | backend |
| `test-frontend` | `npm run test:cov`, gate 80 % | frontend |
| `lint` | backend format, lint and layer rules, then `npm run lint` | both |
| `check` | `lint test`; the definition-of-done gate | common |
| `e2e` | `db-up`, prepare the `_e2e` database, start the backend against it, `npm run e2e` | common, frontend |
| `perf-seed` / `perf` | seed a throw-away database, run k6 in Docker against a separate API port | common |
| `list` | keep a `list` target; grep `$(firstword $(MAKEFILE_LIST))` (see pitfalls) | common |
