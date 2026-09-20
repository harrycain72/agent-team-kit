# <Project> – arc42 documentation

| # | Section | File |
|---|---|---|
| 1 | Introduction and goals | 01-introduction-and-goals.md |
| 2 | Constraints | 02-constraints.md |
| 3 | Context and scope | 03-context-and-scope.md |
| 4 | Solution strategy | 04-solution-strategy.md |
| 5 | Building block view | 05-building-block-view.md |
| 6 | Runtime view | 06-runtime-view.md |
| 7 | Deployment view | 07-deployment-view.md |
| 8 | Cross-cutting concepts | 08-cross-cutting-concepts.md |
| 9 | Architecture decisions | 09-architecture-decisions.md |
| 10 | Quality requirements | 10-quality-requirements.md |
| 11 | Risks and technical debt | 11-risks-and-technical-debt.md |
| 12 | Glossary | 12-glossary.md |

Diagrams: text-based (PlantUML or Mermaid) in `diagrams/`: context, building blocks, one runtime view, deployment.

## Source of truth and sync rule
- `docs/architecture.md` is the build specification and wins on any disagreement.
- arc42 summarises and links; do not copy long tables. Section 9 lists the ADRs as one-liners linking to architecture.md section 13.
- A change to a decision, building block, flow, topology or quality target updates the matching arc42 section in the same change (ADR -> 9; layer or module -> 5 and building-blocks diagram; flow -> 6 and diagram; container, port or database -> 7 and deployment diagram; new risk -> 11; new term -> 12).
- Numbers (thresholds, limits) live in one place; quote them only with a link.
