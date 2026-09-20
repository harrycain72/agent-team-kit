# Common pitfalls (each happened once)

1. **Makefile `-include .env` breaks a `list` target** that greps `$(MAKEFILE_LIST)`: `.env` becomes part of the list. Use `$(firstword $(MAKEFILE_LIST))`.
2. **Unverified pins:** verify the Postgres image tag (`docker manifest inspect`) and package versions before writing them. Check the peer requirements too: the newest release of a tool can be one its framework does not support yet.
3. **Fixed database names in tests** collide when agents run in parallel; use a unique name per run for any test that creates or drops a database.
4. **NUL character in text** makes PostgreSQL raise and returns a 500 unless the rules reject it (422) in the domain rules and the request schemas.
5. **Middleware order:** with CORS inside the body-limit or request-context layer, 413 and 500 responses lack CORS headers and the browser sees an opaque network error. CORS outermost.
6. **A backward index scan gives `id DESC`,** not the `id ASC` tiebreak; claim index use only for the forward orders.
7. **`passWithNoTests` (or its equivalent)** is a temporary crutch for an empty scaffold; remove it as soon as tests exist, or an empty suite passes the gate.
