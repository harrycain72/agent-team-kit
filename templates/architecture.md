# <Project> – Technical design (build specification)

Status: draft
Approved by: 
Approved on: 

<!-- Approval gate. Agents write "draft" and never change it. Only the user, after reading this document, replaces "draft" with the word approved on the Status line and fills in the two lines below it. Building a feature needs this document, docs/business-prd.md and that feature's requirements file (docs/features/e-N-<slug>/business-prd.md) all approved. An approved document is frozen: to change it, the user sets the status back to draft first. -->

## 1. Overview
Context, stack (see the backend and frontend packs), diagram.

## 2. Repository layout
Exact tree the developer creates (mark generated files).

## 3. Backend – BCE structure
Layer responsibilities, dependency rules, import-linter contracts, cross-domain access.

## 4. Data model
Tables, types, constraints, indexes (which sort orders use which index), query semantics, migrations.

## 5. REST API contract
### 5.1 Schemas
### 5.2 Endpoints (method, path, status codes, request/response, query params) and the check order
### 5.3 Error format (RFC 9457)
### 5.4 CORS, config, health
### 5.5 Cross-cutting backend (middleware order, sessions, logging)

## 6. Backend tooling
## 7. Frontend design (stack, components, data fetching, states, accessibility)
## 8. Frontend tooling

## 9. Testing strategy, TDD workflow and definition of done
### 9.1 TDD workflow (vertical slice; see the team-workflow skill)
### 9.2 Definition of done and quality gates
### 9.3 Design for testability (seams)
### 9.4 Backend test layout
### 9.5 Database in tests
### 9.6 Backend test-file mapping (module -> unit test file)
### 9.7 Frontend test layout and mapping

## 10. Non-functional summary (link baseline IDs; only project numbers here)
## 11. Local infrastructure and run instructions (compose, .env.example, Makefile)

## 12. Implementation plan – slices
Rules: BL-FLOW-1 to BL-FLOW-6. S0 is a walking skeleton (thinnest usable end-to-end path). Order slices by time until a user gets value, not by layer. Every slice names how a user reaches it.

The design is one document for the whole solution; the slices are grouped by feature. Every story of every feature requirements file (`docs/features/e-N-<slug>/business-prd.md`) is one slice. A feature's slices are buildable only once that feature is approved. Adding a feature later means the user reopens this document (status back to draft) so the architect can add its slices.

Board (skill `ordna-tasks`): every slice is one story with one `dev` and one `verify` task. Never split a slice by layer.

| Slice | Epic (feature) | Behaviour (story ids) | Board: story / dev / verify | User entry point (UI) | Outer acceptance test | End-to-end test | Layers touched |
|---|---|---|---|---|---|---|---|
| S0 | E-0 Foundation | Walking skeleton (thinnest usable end-to-end path) | T-nnn / T-nnn / T-nnn | | | | |
| S1 | E-1 | | | | | | |

## 13. Decisions (ADRs)
Append only; never renumber; supersede instead of editing history. Use adr.md.
### 13.1 Amendments made during the build

## 14. What the tester should verify
