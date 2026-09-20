# BL-TEST – Testing and TDD gates

- **BL-TEST-1** TDD by vertical slice (see the `team-workflow` skill): failing test first, minimal code, refactor; evidence logged.
- **BL-TEST-2** A unit test file exists for every non-exempt source module, enforced by a mapping test. Exempt (with a listed reason): generated code, Protocols and pure configuration.
- **BL-TEST-3** Coverage gates enforced by tooling: backend 90 % (line and branch), frontend 80 % (lines, statements, functions, branches). Defaults; projects may tighten.
- **BL-TEST-4** Unit tests (entity and control layers, pure frontend logic) do no I/O; enforced mechanically (for example a socket guard).
- **BL-TEST-5** Ports have in-memory fakes (repository, clock, ids). A shared contract test suite runs against both the fake and the real implementation, so the fake cannot drift.
- **BL-TEST-6** Integration tests run against the real database with per-test isolation (rollback of a savepoint) and a unique database name per run when the database is shared.
- **BL-TEST-7** Each acceptance criterion maps to at least one test, referenced by the criterion or story id.
- **BL-TEST-8** End-to-end coverage through the real UI and API: see BL-FLOW-5 (one per slice).
- **BL-TEST-9** No skip / xfail / `.only` without a written reason and follow-up.
- **BL-TEST-10** Assert behaviour through public interfaces; no tests of private helpers; time and randomness injected.
