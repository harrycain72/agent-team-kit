# <Project> – Requirements (solution overview)

Status: draft
Approved by: 
Approved on: 

<!-- Approval gate. Agents write "draft" and never change it. Only the user, after reading this document, replaces "draft" with the word approved on the Status line and fills in the two lines below it. Building a feature needs this document, docs/architecture.md and that feature's own requirements file all approved. An approved document is frozen: to change it, the user sets the status back to draft first. -->

<!-- Scope of this file. The solution is a set of features. Each feature is one epic (E-N) and has its own requirements file, docs/features/e-N-<slug>/requirements.md, with the epic's user stories (template: feature-requirements.md). This file holds only what is shared by all features. It contains no user stories. -->

## 1. Goal, users, problem
<one paragraph each>

## 2. Scope
### In scope (MVP)
### Out of scope (Won't)

## 3. Business domain components (shared by the features)
| Component | Description | Used by (E-N) |
|---|---|---|

## 4. Features (epics)
One row per feature. The requirements file is authoritative for the feature; keep this index current. Feature files live in `docs/features/e-N-<slug>/requirements.md`. Epic ids are unique across the solution and never reused.

| Epic | Feature | Requirements file | Priority | Depends on | Board id |
|---|---|---|---|---|---|
| E-1 | <feature> | docs/features/e-1-<slug>/requirements.md | M | – | T-nnn |

## 5. Applied baseline (see the baseline-requirements skill)
Applies to every feature: BL-...
Overrides (with reason):
Excluded (with reason):
(A feature may deviate further; it says so in its own file, with a reason.)

## 6. Solution-wide non-functional requirements
(Only what the baseline does not cover and that holds for every feature.)

## 7. Assumptions
| ID | Assumption | Reversible how |
|---|---|---|
| A1 | | |

## 8. Risks and dependencies

## 9. Open questions
| ID | Question | Default chosen | Affects |
|---|---|---|---|
| OQ-1 | | | |

## 10. Hand-off to the architect
Summary of the assumptions and open questions that affect the design as a whole. Feature-specific ones are in the feature files.
