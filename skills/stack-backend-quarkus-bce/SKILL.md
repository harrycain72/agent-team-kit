---
name: stack-backend-quarkus-bce
description: Backend pack for Java + Quarkus + Hibernate ORM + Flyway on PostgreSQL, built with Maven, in BCE (boundary-control-entity) layers per business domain, with layer rules enforced by ArchUnit. Backend layout, layer rules, tooling, test seams and known pitfalls. Load with stack-common and a frontend pack when designing or implementing a project that names this backend.
---

# Backend pack: Quarkus, BCE

Fulfils the backend contract in `stack-common`. Authored from Maven Central and the code.quarkus.io generator (2026-09-20); it has not yet been through a full project build, so treat the "Verify at first scaffold" list in `references/layout.md` as open items. Replace `<pkg>` (Java base package) and `<domain>` (business component, for example `todos`) throughout.

| Layer | Choice |
|---|---|
| Backend | Java 25, Quarkus 3.39.4 (latest stable; 3.40.0.CR1 is a release candidate, not used), Maven via the wrapper `./mvnw` (Maven 3.9.16; no global `mvn` needed) |
| Extensions | `quarkus-rest-jackson`, `quarkus-hibernate-orm` (plain JPA, not Panache active record), `quarkus-jdbc-postgresql`, `quarkus-flyway`, `quarkus-hibernate-validator`, `quarkus-smallrye-health`, `quarkus-arc` |
| Backend tests | JUnit 5, REST Assured, `quarkus-junit`, ArchUnit 1.5.0 (`archunit-junit5`), `quarkus-jacoco` (coverage gate) |
| Build hygiene | `maven-enforcer-plugin` 3.6.3 (Java and Maven versions), `spotless-maven-plugin` 3.10.2 (format check), `flyway-maven-plugin` 13.7.0 (the `migrate` target) |

Reference files (`references/`):
- `layout.md` – the `backend/` tree, configuration, the commands behind the Makefile targets, verify list
- `bce-backend.md` – the BCE layers, dependency rules and the ArchUnit rules
- `testing-seams.md` – test layout per layer, injectable seams, fakes and the contract suite, PostgreSQL test isolation
- `pitfalls.md` – things to watch for; read before scaffolding (also read the common ones in `stack-common`)

Fixed decisions (record deviations as new ADRs):
1. JAX-RS resources are plain blocking methods on the Quarkus REST stack; reactive types are a separate decision.
2. Constructor injection everywhere (no field `@Inject`), so unit tests build objects without a CDI container.
3. `@Transactional` sits on control-layer service methods only, never on resources or repositories.
4. The database comes from Docker Compose (`stack-common`); Quarkus Dev Services is disabled so development and tests use the same, named databases.
5. Migrations are Flyway SQL files, applied at start in dev and test; an applied migration is never edited.
