# <Project> – Test plan

## 1. Entry and exit criteria
Prerequisites (docker compose up, test database), coverage gates, evidence of red before green, suite run twice in random order.

## 2. Test data
## 3. Acceptance criteria to test cases
| Criterion (US-n.m or BL-ID) | Case id | Level (unit / API / component / e2e) | Preconditions | Steps | Expected |
|---|---|---|---|---|---|

## 4. Unit tests (separate from integration and e2e)
Backend by layer; frontend components, hooks, API client. Module-to-test-file traceability.

## 5. Integration tests (real database)
## 6. End-to-end and exploratory
One row per slice (BL-FLOW-4, BL-FLOW-5): the user entry point, the e2e test, and whether the tester observed it working through the real UI. Also list any endpoint or UI action without a counterpart (BL-FLOW-6).

| Slice | User entry point | E2E test | Observed via real UI (pass / fail / not tested) |
|---|---|---|---|
## 7. Non-functional (accessibility, responsiveness, performance with k6, security)
## 8. Risks and edge cases
## 9. To confirm against architecture.md
| Id | Item | Decision (ADR) |
|---|---|---|
