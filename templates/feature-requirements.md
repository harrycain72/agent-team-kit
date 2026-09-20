# <Project> – <Feature title> – Requirements

Status: draft
Approved by: 
Approved on: 

<!-- Approval gate. Agents write "draft" and never change it. Only the user, after reading this document, replaces "draft" with the word approved on the Status line and fills in the two lines below it. This feature is built only when this file, docs/requirements.md and docs/architecture.md are all approved. An approved document is frozen: to change it, the user sets the status back to draft first. -->

<!-- One feature = one epic = one file. Save as docs/features/e-<N>-<slug>/requirements.md (slug: lower-case, digits, hyphens). The epic id E-N is the one in the feature index of docs/requirements.md. Story ids US-N are unique across the whole solution: look at the other feature files and the board for the highest one before numbering. Only stories of this epic go in this file. -->

Epic: E-<N>
Board: `T-nnn` (tags `epic`, `e-<N>`)
Solution context: docs/requirements.md (goal, scope, shared domain components, applied baseline)

## 1. Feature goal, users, problem
<one paragraph each; the one business goal of this epic>

## 2. Scope of this feature
### In scope
### Out of scope (Won't)

## 3. User stories
Priority: M(ust) / S(hould) / C(ould) / W(on't). Each story is one vertical slice a user can demonstrate (BL-FLOW-1).

### US-<n> <title> (M)
Epic: E-<N>. Board: `T-nnn` (tags `story`, `us-<n>`, `e-<N>`).
As a <role>, I want <capability>, so that <benefit>.
Acceptance criteria (one checkbox each on the board story, ticked by the tester):
1. Given <context>, when <action>, then <result>.
2. Validation: <limits, error responses>.
3. Edge cases: <...>

### Board (Ordna)
The analyst creates one story per `US-N` here and the epic `E-<N>` (skill `ordna-tasks`). Keep this table current.

| Story | Board id | Priority |
|---|---|---|
| US-<n> | T-nnn | M |

## 4. Baseline for this feature
The applied baseline of docs/requirements.md holds. Deviations for this feature only (each with a reason; it becomes an assumption or an ADR):
- <none>

## 5. Feature-specific non-functional requirements
(Only what neither the baseline nor docs/requirements.md §6 covers.)

## 6. Dependencies on other features
| Needs | From (E-N / US-N) | Why |
|---|---|---|
| | | |

Shared domain components used or changed (docs/requirements.md §3):

## 7. Assumptions
| ID | Assumption | Reversible how |
|---|---|---|
| E<N>-A1 | | |

## 8. Risks

## 9. Open questions
| ID | Question | Default chosen | Affects |
|---|---|---|---|
| E<N>-OQ-1 | | | |

## 10. Hand-off to the architect
Assumptions and open questions of this feature that affect the design.
