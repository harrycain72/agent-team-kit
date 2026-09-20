# TDD log

Append-only red/green evidence per slice (one entry each). Keep the red run before the implementation.

### <Slice id> – <behaviour>
- Board: story `T-nnn`, dev task `T-nnn`
- RED: `<command>` -> `<failing summary line, reason>`
- GREEN: `<command>` -> `<passing summary line>`
- REFACTOR: `<what changed>`; check green: `<command>`
- Retroactive tests or changed existing tests (with reason): <none>
