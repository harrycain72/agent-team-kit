---
name: team-workflow
description: How the four-role team (business-analyst, architect, developer, tester) works together: stage order, file-based handoffs, TDD by vertical slice, definition of done, ownership and escalation rules. Load before starting or coordinating any project with these agents.
---

# Team workflow

Roles: **business-analyst** (requirements), **architect** (design and slice plan), **developer** (test-first implementation), **tester** (review, acceptance, end-to-end, exploratory). The **lead** (the main session) coordinates and verifies.

The work is tracked on the **Ordna board** (https://ordna.sh, `tasks/`) as epics, user stories and tasks. Load the `ordna-tasks` skill: it defines the hierarchy, who creates what, and how each role moves and updates tasks. The board is the current state of the project; the files below are the content.

## 0. Approval gate (the user, before any code)

`docs/requirements.md` and `docs/architecture.md` each carry a `Status:` line. Agents write `Status: draft`. **Only the user sets it to approved**, after reading the document, by editing the file (with `Approved by` and `Approved on`). **Until both documents are approved, no agent (developer, tester, the lead, any other) writes code, tests, configuration or scripts.** Documents, the test plan and the board (`tasks/`) may be written meanwhile.

- The lead, when a document is finished, asks the user to review it and to set the status; it does not set it, and does not start the build without it. `.claude/scripts/check-approval.sh` reports the state (exit 0 only when both are approved).
- An approved document is frozen. A change (a defect in the design, a new requirement) goes to the lead, the user reopens the document by setting the status back to `draft`, the owner edits it, and the user approves again. Work that depends on the changed part stops until then.
- The rule is enforced by a hook (`.claude/hooks/require-approval.sh`, registered in `.claude/settings.json`) that blocks file-editing tools, and reported by `check-board.sh`. The hook does not see shell commands that write files, so the agents' instructions forbid them too.

## 1. Stages and handoffs

| Stage | Owner | Input | Output (the contract) | Done when |
|---|---|---|---|---|
| Requirements | business-analyst | the idea, `CLAUDE.md`, baseline requirements | `docs/requirements.md` (`Status: draft`) + an epic per goal and a story per `US-N` on the board | stories have testable acceptance criteria; assumptions and open questions listed; `check-board.sh --stage requirements` passes |
| Design | architect | requirements | `docs/architecture.md` (`Status: draft`; + ADRs, slice plan) + a `dev` and a `verify` task per story | every open question resolved as an ADR; slice plan ordered; tag and package versions checked; `check-board.sh --stage design` passes |
| Build | developer(s) | design; **both documents approved by the user** | code, tests, TDD log entries; `dev` task `doing` then `review` | slice green, `make check` (or equivalent) green |
| Verify | tester | slice + acceptance criteria | test plan, extra tests, defect tasks; story criteria ticked; `verify` and `dev` tasks `done` | each criterion pass / fail / not tested, observed not assumed |

Rules of the handoff:
- **Files are the contract.** Each stage writes its result to a named file and ends its turn with a short summary and the path. Do not paste long documents into messages.
- **One authoritative file per stage.** No draft variants left in the tree (a stray second requirements draft caused confusion once).
- **No editing upstream.** A downstream agent that finds a defect in an upstream document reports it to the lead; the owner changes it.
- **Independent stages run in parallel.** For example, backend and frontend developers on different slices, the tester's plan while the architect designs.
- **The lead verifies.** After every agent report, re-run the checks (tests, lint, coverage) yourself before accepting, and run `.claude/scripts/check-board.sh` to see that the board matches what was reported. Reports are claims. Only the lead moves a story or epic to `done`.
- **The board is updated as work changes state.** Each role claims its task before starting, moves it to `review` when finished (developer) or `done` (tester, after verifying), and never marks its own work `done`. A role that finishes without updating the board has not finished.
- If agents cannot message each other, all handoffs go through the lead. Design to need few of them.

## 2. TDD by vertical slice (the default process)

1. **Slice** = one user-visible behaviour through all layers (for example "create a todo"), ending in a working application. Deliver slice by slice, not layer by layer. The slice rules are the baseline **BL-FLOW-1 to BL-FLOW-6**; in short: S0 is a walking skeleton, slices are ordered by time-to-usage, and a slice is done only when a user can use it through the real interface. Never split one behaviour into backend and frontend tasks.
2. The **developer** of the slice writes the failing test first, then the code:
   - RED: an outer test at the API (or UI) boundary describing the behaviour, then unit tests per layer touched. Run them; confirm they fail **for the right reason**.
   - GREEN: the minimum code to pass.
   - REFACTOR: clean up with all tests green; behaviour changes start a new RED.
3. **No production code and no branch without a test that failed first.** Exempt: generated code and pure configuration (they start from a failing check instead).
4. The **tester** does not write layer tests ahead of the code. The tester reviews the slice's tests against the acceptance criteria, adds acceptance, end-to-end and exploratory tests, and reports defects.
5. **Evidence:** the red test is committed (or logged with command and failing summary line) before the implementation. Retroactive tests are allowed only when logged as such and shown able to fail.
6. Tests state behaviour through public interfaces. Do not test private helpers or mock what you own; use fakes for the ports (repository, clock, ids).
7. Never edit an existing test just to make it pass; report it, or change it with a logged reason.

Why not tester-writes-tests-first for whole layers: it serialised the work (developers idled), the tests were written against interfaces that did not exist yet (names became guesses), later design changes forced test rewrites, and no endpoint worked after an hour. See `references/lessons-learned.md`.

## 3. Definition of done (per slice)

- [ ] Both documents were approved by the user before the first line of code (the approval is in the file, not in a chat message)
- [ ] Failing-test evidence exists and the tests were written before the code
- [ ] Every new source module has its unit test file (enforced by a mapping test, not by review)
- [ ] Full check green: lint and format, layer rules, type check, all unit and integration tests, coverage gates (defaults: 90 % backend, 80 % frontend; see `baseline-requirements`)
- [ ] No skip / xfail / `.only` without a written reason and follow-up in the TDD log
- [ ] Usable (BL-FLOW-4): the behaviour works through the real UI, the app starts with the one dev command, and the tester observed it
- [ ] End-to-end test for the slice exists and passes, referenced by story id (BL-FLOW-5); no orphaned endpoint or UI action (BL-FLOW-6)
- [ ] Refactor step done; API docs and README updated if behaviour or run instructions changed
- [ ] Board: `dev` and `verify` tasks are `done`, every story criterion is ticked by the tester, no `defect` task is open, and `check-board.sh` passes
- [ ] The lead re-ran the check and saw it pass, then moved the story (and its epic, when all its stories are done) to `done`

## 4. Practical rules learned

- Give each agent a **unique test database name per run**; a fixed shared name made parallel runs collide.
- Keep the **suite collectable** at every handoff: reds come from missing production code only, never from missing test helpers.
- **Verify before pinning**: check that image tags and package versions exist.
- If a **permission prompt or classifier denies a command**, do not work around it; name the command and let the user decide.
- **Untested branches** are a process breach: ask for the test first, leave the branch out until it is red.
- Do not run `git init`, commit or push unless the user asked. That includes `ordna commit`: task changes stay in the working tree.
- Enable the tools agents need to hand off (`SendMessage`), or plan for the lead to relay.
