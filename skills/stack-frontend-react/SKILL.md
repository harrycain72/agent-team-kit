---
name: stack-frontend-react
description: Frontend pack for Vite + React + TypeScript + Tailwind + shadcn/ui with TanStack Query. Frontend layout, npm scripts, data fetching, forms, states, tests and known pitfalls. Load with stack-common and a backend pack when designing or implementing a project that names this frontend.
---

# Frontend pack: React (shadcn)

Source: the todo-app build (2026-09-19). Fulfils the frontend contract in `stack-common`.

| Layer | Choice |
|---|---|
| Frontend | Vite, React, TypeScript (strict), Tailwind v4, shadcn/ui, TanStack Query, react-hook-form + zod |
| Frontend tests | vitest, testing-library, msw, vitest-axe, Playwright (one e2e per slice, BL-FLOW-5), eslint |

Reference files (`references/`):
- `frontend.md` – layout, npm scripts, structure, data fetching, states, tests, accessibility
- `pitfalls.md` – things that went wrong once; read before scaffolding
