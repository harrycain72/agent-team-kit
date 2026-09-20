# BL-OPS – Quality and operability

- **BL-OPS-1** One command starts local development (for example `make dev`); prerequisites documented in the README.
- **BL-OPS-2** Persistent storage survives restarts (named volume); a clearly destructive reset target exists.
- **BL-OPS-3** Structured (JSON) logging with request id; no personal data unless the requirements say so.
- **BL-OPS-4** Database schema changes only through migrations; a test proves models and migrations agree (no drift) and that migrations apply to an empty database and downgrade.
- **BL-OPS-5** The database runs as a container in development and CI; integration tests use a separate test database (never the development one) and a name guard that refuses non-test databases.
- **BL-OPS-6** CI runs the same check as local development (lint, layer rules, tests, coverage gates).
- **BL-OPS-7** Layer and dependency rules are enforced by tooling, not review.
- **BL-OPS-8** Documentation: requirements, architecture (build specification, with ADRs) and, when requested, arc42 documentation that summarises and links to it. One authoritative file per topic.
