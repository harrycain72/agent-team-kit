# <Project> – Test strategy

<!-- Written by the test-manager. Save as docs/test-strategy.md, at the same level as docs/architecture.md. General: valid for every feature. Feature-specific cases and test data go in docs/features/e-N-<slug>/test-plan.md. -->

## 1. Goals and principles
What quality means for this product; TDD by vertical slice; tests state behaviour through public interfaces (team-workflow).

## 2. Test levels
| Level | What it proves | Written by | Tools | Runs in |
|---|---|---|---|---|
| Unit (per layer) | | developer (TDD) | | `make check` |
| Integration (real database) | | developer (TDD) | | `make check` |
| API contract | | developer, tester | | |
| Component (frontend) | | developer (TDD) | | |
| End-to-end (through the real UI) | | developer (one per slice), tester | | `make e2e` |
| Exploratory and manual | | tester | | |

## 3. Tools and versions
Taken from docs/architecture.md and the stack packs; do not re-decide them here.

## 4. Environments and test data
Test databases (unique name per run), how data is created, isolated and reset, seeding helpers, secrets, what must never be used (production data).

## 5. Naming, traceability and evidence
Each test names the criterion it covers (BL-TEST-7); red-before-green evidence in docs/tdd-log.md; how the test plans map criteria to cases.

## 6. Coverage gates and entry/exit criteria
Numbers and how they are measured; when a slice may go to `functional-test`, when it may go to `done`.

## 7. Non-functional testing
Accessibility, security, performance (only where the baseline applies it), responsiveness.

## 8. Browsers, devices and what stays manual

## 9. Defects
Severity levels, where they are recorded (the story card's `## Defects`), who fixes and re-checks.

## 10. Risks and open questions
