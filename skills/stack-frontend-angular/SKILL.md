---
name: stack-frontend-angular
description: Frontend pack for Angular (standalone, signals, zoneless) with Angular Material, HttpClient, typed reactive forms, Vitest via the Angular unit-test builder and Playwright. Frontend layout, npm scripts, conventions, tests and known pitfalls. Load with stack-common and a backend pack when designing or implementing a project that names this frontend.
---

# Frontend pack: Angular

Fulfils the frontend contract in `stack-common`. Authored from the npm registry and a scratch `ng new` scaffold (2026-09-20); it has not yet been through a full project build, so treat the "Verify at first scaffold" list in `references/frontend.md` as open items.

| Layer | Choice |
|---|---|
| Frontend | Angular 22.1 (standalone components, signals, zoneless), TypeScript ~6.0 strict, Angular Material + CDK (same version), `HttpClient` with an error interceptor, typed reactive forms |
| Frontend tests | `@angular/build:unit-test` with Vitest and jsdom, `HttpTestingController`, Testing Library for Angular, axe-core, Playwright (one e2e per slice, BL-FLOW-5), angular-eslint |

Reference files (`references/`):
- `frontend.md` – versions, layout, npm scripts, conventions, data fetching, states, tests, verify list
- `pitfalls.md` – things to watch for; read before scaffolding
