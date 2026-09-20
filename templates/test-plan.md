# <Project> – <Feature title> – Test plan

<!-- Written by the test-manager. Save as docs/features/e-<N>-<slug>/test-plan.md, next to the feature's business-prd.md and technical-prd.md. Feature-specific; the general approach is in docs/test-strategy.md (do not repeat it). Executed by the developer (TDD tests, one e2e per slice) and the tester (acceptance, e2e, exploratory). -->

Epic: E-<N>
Business PRD: docs/features/e-<N>-<slug>/business-prd.md
Technical PRD: docs/features/e-<N>-<slug>/technical-prd.md
Test strategy: docs/test-strategy.md

## 1. Scope, entry and exit criteria
What is tested, what is not (and why); prerequisites; when the feature's stories may be accepted.

## 2. Test cases
One row per case. Every criterion `US-N.m` of the business PRD has at least one case, or a row in section 5 saying it is not tested and why. Cases state exact expected results, with the wording of the requirements.

| Case id | Criterion | Level (unit / API / component / e2e / manual) | Preconditions | Test data | Steps | Expected result | Automated by |
|---|---|---|---|---|---|---|---|

## 3. Test data
Named datasets with exact values, how each is created and reset (unique database per run). Large or generated data goes in `docs/features/e-<N>-<slug>/test-data/` and is referenced here.

| Dataset | Purpose | Values / volume | How created and reset | Used by cases |
|---|---|---|---|---|
| valid | | | | |
| boundary | | | | |
| invalid | | | | |
| hostile (markup, NUL, emoji, very long) | | | | |
| volumes (0, 1, page size, page size + 1, many) | | | | |

## 4. Exploratory charters
One line each: mission, area, what to vary, what to look for.

## 5. Traceability
| Criterion | Cases | Status (planned / not tested, reason) |
|---|---|---|

## 6. Risks and edge cases

## 7. Open points for the analyst or architect
