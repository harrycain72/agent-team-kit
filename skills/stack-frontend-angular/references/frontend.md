# Frontend (Angular + Angular Material)

## Versions (checked 2026-09-20; re-check before pinning)

- `@angular/core`, `@angular/cli`, `@angular/build`: 22.1.x. Node `^22.22.3 || ^24.15.0 || >=26` (engines of `@angular/core`).
- TypeScript **~6.0** (`@angular/build` peer range is `>=6.0 <6.1`). The newest TypeScript on npm is 7.x; do not upgrade past the peer range.
- The scaffold (`ng new`) gives: standalone components with no NgModules, no `zone.js` dependency (zoneless, `provideBrowserGlobalErrorListeners`), files `app.ts` / `app.spec.ts` (no `.component` suffix), test builder `@angular/build:unit-test` running Vitest `^4.0.8` in jsdom, `ng test`.
- `@angular/material` 22.1.x needs `@angular/cdk` at exactly the same version.
- angular-eslint 22.5, `@testing-library/angular` 19.x (peer: Angular >= 21, `@testing-library/dom` ^10), axe-core 4.13, Playwright 1.6x, `@vitest/coverage-v8` in the same major as the scaffold's Vitest (4.x).

## Layout

```
frontend/
├── package.json, angular.json (proxyConfig, unit-test coverage thresholds), tsconfig*.json, eslint.config.js, proxy.conf.json
├── playwright.config.ts, e2e/
└── src/
    ├── main.ts, index.html, styles.css          # Material theme in styles
    └── app/
        ├── app.ts, app.config.ts, app.routes.ts # providers: router, HttpClient with interceptors
        ├── core/{api, date, error}/             # request helper, ApiError, error interceptor, local-date helpers
        ├── shared/                              # reusable components and pipes
        ├── features/<domain>/{data-access, state, components, pages, models.ts}
        └── testing/                             # TestBed helpers, fixtures, HTTP mocking helpers
```

Add to `.gitignore`: `node_modules dist coverage .angular`. `angular.json` sets `serve` `proxyConfig` to `proxy.conf.json`, which maps `/api` and `/health` to `http://localhost:8000`.

## Scripts (the frontend contract)

```
dev        ng serve
test       ng test --no-watch                (ng test watches in a terminal by default)
test:cov   ng test --no-watch --coverage     (thresholds 80 through the builder's coverageThresholds)
lint       ng lint && tsc -p tsconfig.spec.json --noEmit
e2e        playwright test
```

## Conventions

- **TypeScript strict:** the 22.1 scaffold does **not** set `"strict": true`. Add it to `tsconfig.json` `compilerOptions` at S0.
- **Components:** standalone, `ChangeDetectionStrategy.OnPush`, signal `input()` / `output()`, `inject()` for dependencies, new control-flow syntax (`@if`, `@for`) in templates. Never hand-write what Material already provides.
- **API client:** `core/api` exposes one `request<T>(method, path, {body, params})` over `HttpClient`; paths relative to `/api/v1`. An interceptor turns every `HttpErrorResponse` into an `ApiError` carrying the parsed problem; a malformed `problem+json` body still yields an `ApiError` without a problem.
- **Data fetching:** feature services hold state in signals (`items`, `loading`, `error`, `params`). Reads may use `httpResource` if the pinned version marks it stable (check the Angular docs); mutations go through `HttpClient`. Optimistic update for direct manipulation with rollback, cancelling the in-flight list request; refetch after settle. Do not retry 4xx.
- **Forms:** typed reactive forms; validators mirror server limits; server field errors map to `control.setErrors({server: message})`; non-field failures go to a `MatSnackBar`; input is kept on failure.
- **States:** every list has loading (skeleton), error (with retry), empty (first-use vs no-match) and populated states. A `LiveAnnouncer` (`@angular/cdk/a11y`) announces counts and changes with correct singular/plural.
- **List params:** state in a signal (or router query params if the list must be linkable), fixed page size; changing filters resets the offset; search is debounced (`rxjs` `debounceTime` or a signal-based debounce); the page is corrected when the offset falls past the end.
- **Dates:** date-only values are parsed as local calendar dates (never through `new Date('YYYY-MM-DD')`, which is UTC). Test date logic under several time zones by running the suite with different `TZ` values.
- **Accessibility:** see `baseline-requirements` BL-A11Y; an axe-core check in component tests; Material components used per their documented a11y usage.

## Tests

- Unit and component tests are colocated: `x.spec.ts` beside `x.ts`; shared helpers in `src/app/testing/`. A mapping test fails if a source module has no spec file. Exemptions (`main.ts`, `app.config.ts`, route tables, types-only files) are listed with a reason.
- API services: `provideHttpClient()` + `provideHttpClientTesting()` and `HttpTestingController`; assert method, URL, params and body, then flush a response.
- Components: Testing Library for Angular (`render`, user-event) with real templates; do not test private members or mock what you own.
- e2e: one Playwright test per slice (BL-FLOW-5) against the `_e2e` database.

## Verify at first scaffold (record the outcome as an ADR or in the TDD log)

- The exact `coverageThresholds` key names in the `unit-test` builder options, and that `ng test --no-watch --coverage` fails below 80 %.
- That axe-core runs under the jsdom test environment (a `vitest-axe` package exists but was not tried); otherwise run axe in Playwright with `@axe-core/playwright`.
- That `TZ=... ng test` reaches the test process for the multi-time-zone date tests.
- That `httpResource` is stable in the pinned version.
