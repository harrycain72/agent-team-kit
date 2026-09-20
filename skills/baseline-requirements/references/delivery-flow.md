# BL-FLOW – Delivery flow

- **BL-FLOW-1** Work is planned and delivered as vertical slices. A slice is one user-visible behaviour through all layers. Backend-only and frontend-only tasks or slices for the same behaviour are not allowed.
- **BL-FLOW-2** S0 is a walking skeleton: the thinnest end-to-end path (UI, API, storage) that a user can start with the one development command (BL-OPS-1).
- **BL-FLOW-3** Slices are ordered by the time until a user gets value, not by architectural layer.
- **BL-FLOW-4** A slice is done only when its behaviour is reachable and works through the real interface. Stubs, hardcoded data and fakes behind the interface are allowed. Ending at an API with no UI path is not.
- **BL-FLOW-5** Every slice has at least one end-to-end test through the real UI and API (through the CLI or API if the product has no UI), referenced by story id. The tester observes it running.
- **BL-FLOW-6** No orphaned layer: every endpoint has a UI path, or a listed reason why not, and every UI action has a working endpoint.
