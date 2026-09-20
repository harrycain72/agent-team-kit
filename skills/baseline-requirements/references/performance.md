# BL-PERF – Performance

- **BL-PERF-1** p95 API latency at most 200 ms for list, get, create, update and delete with up to 10,000 records on a development-class machine (default; projects override with a reason).
- **BL-PERF-2** UI interactive within 2 s on broadband; UI feedback for direct manipulation (toggles) within 100 ms, using optimistic updates with rollback.
- **BL-PERF-3** Indexes for every documented filter and sort order; state which orders use an index and which sort in memory.
- **BL-PERF-4** Load and performance testing with k6, run in Docker, thresholds as gates (p95, error rate below 1 %, checks above 99 %). It runs on demand and optionally in CI, not in the TDD loop. Functional API tests stay in the unit and integration suites.
