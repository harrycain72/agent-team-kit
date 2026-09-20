# Frontend (React + shadcn)

- **Stack:** Vite, React, TypeScript strict, Tailwind v4, shadcn/ui (generate components with the CLI; never hand-write `components/ui/*`), TanStack Query, react-hook-form + zod, `@` path alias, dev proxy of `/api` and `/health` to the backend.
- **Structure:** `lib/` (api client, date helpers, theme), `components/` (shared, plus generated `ui/`), `features/<domain>/{api,hooks,components,schema.ts,types.ts}`, `test/` (setup, msw handlers, `renderWithProviders` with a fresh QueryClient and `retry: false`).
- **API client:** one `request<T>(method, path, {body, params, signal})`; paths relative to `/api/v1`; errors become an `ApiError` carrying the parsed problem; a malformed `problem+json` body still yields an `ApiError` without a problem.
- **Data fetching:** query keys per resource and params; `placeholderData: keepPreviousData` to avoid flicker; optimistic update for direct manipulation with rollback, cancelling in-flight list queries; invalidate after settle. Do not retry 4xx.
- **Forms:** zod schemas mirror server limits; server field errors map to `setError`; non-field failures go to a toast; input is kept on failure.
- **States:** every list has loading (skeleton), error (with retry), empty (first-use vs no-match) and populated states. A visually hidden `aria-live` region announces counts and changes with correct singular/plural.
- **List params:** state in React, fixed page size; changing filters resets the offset; search is debounced; the page is corrected when the offset falls past the end.
- **Dates:** date-only values are parsed as local calendar dates (never through `new Date('YYYY-MM-DD')`, which is UTC). Test date logic under several time zones with Vitest's default `forks` pool.
- **Accessibility:** see `baseline-requirements` BL-A11Y; vitest-axe in component tests.
- **e2e:** one Playwright happy path per slice (BL-FLOW-5) against a throw-away database.
- **Unit tests:** colocated, `X.test.ts(x)` beside `X.ts(x)`; shared helpers in `src/test/`. A mapping test fails if a source module has no test file. Exemptions (generated shadcn `components/ui/*`, types-only files, bootstrap) are listed with a reason.

## Layout

```
frontend/
├── package.json, vite.config.ts (alias, proxy, vitest + coverage thresholds), eslint.config.js, components.json
├── playwright.config.ts, e2e/
└── src/{main.tsx, App.tsx, lib/{api,date,theme}, components/{ui,*}, features/<domain>/{api,hooks,components,schema.ts,types.ts}, test/}
```

Add to `.gitignore`: `node_modules dist coverage`.

## Scripts (the frontend contract)

```
dev        vite
test       vitest run
test:cov   vitest run --coverage        (thresholds 80)
lint       eslint . && tsc -b --noEmit
e2e        playwright test
```
