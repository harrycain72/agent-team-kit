# Pitfalls (React frontend; each happened once)

See `stack-common/references/pitfalls.md` for the technology-neutral ones (including `passWithNoTests`).

1. **shadcn `form` registry item can be an empty stub.** Use the `field` component with react-hook-form.
2. **Vite template ships oxlint;** replace it with eslint if the design says eslint.
3. **TanStack Query retries 404 by default;** configure retry to network errors and 5xx.
4. **`tsc` and eslint on test files:** typed helpers (captured requests, user-event options) need matching types, or the typecheck gate fails.
