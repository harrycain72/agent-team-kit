# <Project> – <Feature title> – Technical PRD

Status: draft
Approved by: 
Approved on: 

<!-- Approval gate. Agents write "draft" and never change it. Only the user, after reading this document, replaces "draft" with the word approved on the Status line and fills in the two lines below it. A feature is built only when docs/business-prd.md, docs/architecture.md, this feature's business-prd.md and this file are all approved. An approved document is frozen: to change it, the user sets the status back to draft first. -->

<!-- One feature = one epic = one business-prd.md + one technical-prd.md. Save as docs/features/e-<N>-<slug>/technical-prd.md, next to the business-prd.md. Written by the architect. It holds everything specific to THIS feature; docs/architecture.md holds only what is valid for all features (layout, tooling, cross-cutting rules, the walking skeleton). Do not repeat architecture.md here; link to it. -->

Epic: E-<N>
Business PRD: docs/features/e-<N>-<slug>/business-prd.md
General architecture: docs/architecture.md

## 1. Scope and approach
How this feature is realised on the general architecture, in a few lines.

## 2. Domain and data model
Entities, fields, constraints, indexes, migrations of this feature.

## 3. API contract
Endpoints, request and response bodies, status codes, error cases, ordering and paging rules of this feature (baseline BL-API-* applies; note deviations).

## 4. Backend design
Components per BCE layer (boundary, control, entity), ports and fakes, validation rules.

## 5. Frontend design
Screens, components, state and data fetching, forms, states (loading, empty, error), accessibility notes.

## 6. Decisions (ADRs) specific to this feature
One per significant decision (context, options, decision, trade-off). Ids stay unique across the solution and are never renumbered; general decisions live in docs/architecture.md.

## 7. Slice plan
One row per story, in delivery order (BL-FLOW-1..6). Story card ids are on the board.

| Slice | Story (US-N) | Card | User entry point | Outer acceptance test | E2E test | Layers touched |
|---|---|---|---|---|---|---|

## 8. Criteria to tests
Every criterion US-N.m of the business PRD with the test that covers it (the test-manager's test plan holds the detailed cases).

## 9. Notes for the tester
What needs acceptance and exploratory attention; behaviour that is known and accepted.

## 10. Risks, assumptions and open points
