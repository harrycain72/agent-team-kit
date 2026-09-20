---
name: stack-common
description: Conventions shared by every stack combination (one backend pack plus one frontend pack): repository layout, Makefile targets, the backend and frontend contracts, HTTP API decisions and common pitfalls. Load together with the backend and frontend packs a project names.
---

# Stack common

A project names **one backend pack and one frontend pack** in its `CLAUDE.md`. This pack holds what does not depend on which ones: the repository layout, Makefile target names, the contracts the two sides fulfil, and decisions about the HTTP API. Any backend pack works with any frontend pack because both follow the contracts.

| Side | Pack | Stack |
|---|---|---|
| Backend | `stack-backend-fastapi-bce` | Python, FastAPI, SQLAlchemy, Alembic, uv |
| Backend | `stack-backend-quarkus-bce` | Java, Quarkus, Hibernate ORM, Flyway, Maven |
| Frontend | `stack-frontend-react` | Vite, React, shadcn, TanStack Query |
| Frontend | `stack-frontend-angular` | Angular, Angular Material, Vitest |

Reference files (`references/`):
- `layout.md` – repository tree and Makefile targets, with which pack fills each
- `contracts.md` – what a backend pack and a frontend pack must each provide
- `pitfalls.md` – technology-neutral things that went wrong once; read before scaffolding

Database: PostgreSQL (pinned image, verified tag) in Docker Compose; databases `<db>`, `<db>_test`, `<db>_e2e` and `<db>_perf` on the same container. Performance: k6 in Docker (baseline BL-PERF-4).

API decisions (record deviations as new ADRs):
1. UUID ids; a malformed id is 404.
2. Hard delete, offset pagination, strict bodies that reject unknown fields (see `baseline-requirements` BL-API).
3. Overdue and similar display logic is computed in the UI with the browser's local date; the server stays timezone-agnostic.
