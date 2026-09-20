# BL-SEC – Security

- **BL-SEC-1** Validate and bound all input: lengths, numeric ranges, `limit`, request body size (recommended default 64 KiB, `413`).
- **BL-SEC-2** Parameterised queries or an ORM only; no string-built SQL. Escape wildcard characters in `LIKE`/`ILIKE` searches.
- **BL-SEC-3** Escape output in the UI; no raw HTML rendering of user text.
- **BL-SEC-4** No secrets in the repository. Configuration through environment variables; commit `.env.example`, ignore `.env`. Bind development databases and services to loopback.
- **BL-SEC-5** Authentication and authorisation: state explicitly whether they are in scope. If not, document that the deployment is local or trusted-network only. If yes, add a users domain and per-resource ownership checks.
- **BL-SEC-6** Errors never leak internals (stack traces, SQL, file paths) to clients; details go to the log with the request id.
- **BL-SEC-7** Dependencies pinned via lockfiles; pinned container image tags (verified to exist).
- **BL-SEC-8** Set a database statement timeout and bounded connection pools.
