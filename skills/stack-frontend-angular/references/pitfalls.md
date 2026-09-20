# Pitfalls (Angular frontend)

See `stack-common/references/pitfalls.md` for the technology-neutral ones (pins, `passWithNoTests`).

Found while checking the registry and a scratch scaffold (2026-09-20):

1. **TypeScript 7 is the newest on npm, but `@angular/build` accepts only `>=6.0 <6.1`.** Pin `typescript@~6.0`; an unpinned install fails or warns on peers.
2. **The scaffold's `tsconfig.json` has no `"strict": true`.** Add it before writing code, or the strictness gates in the design are not real.
3. **`ng test` watches in a terminal.** The `test` and `test:cov` scripts pass `--no-watch` or `make check` hangs.
4. **`@vitest/coverage-v8` must match the Vitest major** the scaffold installs (4.x); the newest on npm is 5.x.
5. **`@angular/material` and `@angular/cdk` must be the same version,** exactly.
6. **The default test environment is jsdom,** so layout, focus and real-browser behaviour are not proven by unit tests; rely on the per-slice Playwright test for those.
