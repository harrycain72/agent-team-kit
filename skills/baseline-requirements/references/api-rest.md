# BL-API – REST API conventions

- **BL-API-1** Resource-oriented URLs: plural nouns, a versioned base path (`/api/v1/<resources>`, `/api/v1/<resources>/{id}`), no verbs in URLs.
- **BL-API-2** Correct methods and semantics: `GET` safe; `PUT` and `DELETE` idempotent; `POST` creates; `PATCH` partially updates. Define what `PUT` does with omitted fields (recommended: replaces the editable representation, omitted optional fields become null/default).
- **BL-API-3** Correct status codes: `200`, `201` (with `Location` on create), `204` (no body, for delete), `400` (malformed request such as invalid JSON), `404`, `405`, `413` (body too large), `415` (wrong media type), `422` (validation), `500`, `503` (dependency down). Document the check order when several apply (recommended: body-size guard first, then routing, then validation).
- **BL-API-4** JSON only. ISO 8601 UTC timestamps (`Z`). `snake_case` field names. A date without a time is a plain `YYYY-MM-DD` and stays timezone-agnostic on the server.
- **BL-API-5** Ids are opaque (recommended: UUID). A malformed id is `404`, never a database error.
- **BL-API-6** Collections paginate with `limit` and `offset` (defaults and a maximum, for example default 20, maximum 100), return `total`, and have a stable tiebreak in the sort order (for example by `id`). An offset past the end returns an empty page, not an error. Filters and search are query parameters; unknown or invalid values are `422`.
- **BL-API-7** All errors, including unknown routes, wrong methods and unhandled exceptions, use RFC 9457 Problem Details (`application/problem+json`): `type`, `title`, `status`, `detail`, plus `request_id`, and for validation errors an `errors[]` array of `{field, message}`. Unhandled exceptions return a generic message without internals. Never return the framework's default error shape.
- **BL-API-8** Request bodies are strict: unknown or read-only fields and an empty PATCH are `422`. Strings are trimmed before length checks. Reject characters the database cannot store (for example NUL) with `422`, never a `500`.
- **BL-API-9** OpenAPI 3 schema published and accurate, with examples per endpoint.
- **BL-API-10** `GET /health` (liveness) and `GET /health/ready` (readiness: dependencies reachable and schema migrated; `503` otherwise).
- **BL-API-11** CORS restricted to the configured frontend origin, applied to every response including errors produced by middleware (CORS is the outermost middleware).
- **BL-API-12** Every response carries `X-Request-ID` (echoing a valid incoming one, else generated); the same id appears in access logs and in the problem body.
