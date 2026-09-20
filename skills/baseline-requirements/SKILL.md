---
name: baseline-requirements
description: Reusable general requirements (API conventions, security, accessibility, performance, quality and operability, testing gates, delivery flow) with stable IDs, to be referenced from a project's requirements.md instead of rewritten. Load when writing or reviewing requirements or a design.
---

# Baseline requirements

General requirements that apply to most web applications, split by topic under `references/`. Each rule has a stable ID (`BL-<TOPIC>-<n>`).

| Topic | File | ID prefix |
|---|---|---|
| REST API conventions | `references/api-rest.md` | BL-API |
| Security | `references/security.md` | BL-SEC |
| Accessibility and UX | `references/accessibility-ux.md` | BL-A11Y |
| Performance | `references/performance.md` | BL-PERF |
| Quality and operability | `references/quality-operability.md` | BL-OPS |
| Testing and TDD gates | `references/testing-tdd.md` | BL-TEST |
| Delivery flow (vertical slices, usable early) | `references/delivery-flow.md` | BL-FLOW |

## How a project uses them

In the project's `docs/requirements.md`, a short section "Applied baseline":

```
Applies: BL-API-*, BL-SEC-*, BL-A11Y-*, BL-TEST-*, BL-FLOW-*
Overrides:
- BL-PERF-1 (p95 <= 200 ms) -> p95 <= 500 ms, because <reason>
Excluded:
- BL-SEC-5 (authentication): out of scope, single-user local tool (assumption A1)
```

- **Reference by ID; do not copy the text.** The baseline stays one place, and the project document stays short.
- **Every override and exclusion needs a reason** and becomes an assumption or an ADR.
- Baseline numbers (limits, thresholds) are defaults; the project may tighten or relax them explicitly.
- A rule the project must satisfy is testable: the acceptance tests reference the rule ID.

## Adding to the baseline

Add a rule only when a second project needs it. Give it the next ID; never renumber; mark obsolete rules "Withdrawn".
