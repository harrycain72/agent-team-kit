# Lessons learned (todo-app build, 2026-09-19)

Five agents, about one hour. Source: ADR-25 and arc42 section 11.4 of that project.

| Lesson | What happened | Response |
|---|---|---|
| Relay handoffs serialise the work | Developers idled while the tester wrote the next layer of tests | Vertical slices; the slice's developer writes test and code |
| Tests far ahead of code go stale | Interface names were guesses that had to be ratified; design changes (error precedence, module split, CORS order) forced renegotiation | Outer test first; layer tests written with the code |
| Proving tests needs a second implementation | The tester built a throw-away reference implementation outside the repo just to prove its own tests were sound | Not needed when code follows its test immediately |
| Red-before-green was an honour system | Retroactive tests; an untested defensive branch added with the code | Commit or log the red test first; mechanical checks |
| Shared resources collide | Two agents ran the migration test on one fixed database name | Unique test database per run and per agent |
| Agents could not message each other | The lead relayed every handoff | Fewer handoffs by design; enable `SendMessage` |
| A stray second requirements draft | Two conflicting requirement files confused the agents | One authoritative file per stage |
| Unverified guesses in design | A pinned image tag was a guess | Verify tags and versions before pinning |
| Architecture docs missed rules given late | Rules sent to an agent while it was mid-task arrived after it finished | Put rules in the project's `CLAUDE.md` / agent definitions before starting |
| Design gaps found only when tests were written | NUL byte in text gave a 500; `request_id` empty on 500; CORS headers missing on 413/500 | Write the outer test early; ask the architect for a decision, record it as an ADR |
| Vertical slices did not guarantee usability | A slice could end at a tested API with no UI path, so the feature was not usable yet | BL-FLOW: walking skeleton, order by time-to-usage, a slice is done only when usable through the real interface, one e2e test per slice |
| Installing third-party tooling was blocked by the permission classifier | `npm i -g`, `ordna init` needed the user to run them with `!` | Tell the user the exact command and continue with other work |
| The team did not use the task board it was meant to | The kit named Ordna only in this table; no agent created or updated a task, and the analyst had no `Bash` to run it. A bare `ordna init` also fails without a terminal | 0.4.0: `ordna-tasks` skill, roles own board updates, `ordna init --storage=file` in `new-project.sh`, `check-board.sh` to verify it mechanically |
