# Test layout and seams (Quarkus)

## Seams (constructor injection, no static singletons)

| Seam | Production | Test |
|---|---|---|
| Repository | `Jpa<Domain>Repository` (`@ApplicationScoped`, `EntityManager`) implementing the entity-layer interface | `InMemory<Domain>Repository` in `support/`, proven equivalent by the shared contract suite |
| Transaction | container-managed, `@Transactional` on control methods | `@TestTransaction` for repository tests; explicit clean-up for HTTP tests (see below) |
| Clock | `java.time.Clock` from a producer in `shared` | `FixedClock` with `.advance(Duration)` |
| Ids | `Supplier<UUID>` from a producer | fixed supplier |
| Settings | `@ConfigMapping` interface | build the mapping by hand in unit tests; `@TestProfile` for Quarkus tests |

Unit tests construct services with the in-memory repository and fake clock directly; no CDI container.

## Layout (`backend/src/test/java/<pkg>/`)

| Package | Scope | I/O |
|---|---|---|
| `unit/<domain>/{entity,control}` | rules, entity behaviour, use cases with the in-memory fake and fixed clock; plain JUnit 5 | none |
| `unit/<domain>/boundary`, `unit/shared` | mappers, problem builders, request records and validation; plain JUnit 5 with hand-built objects | none |
| `contract/` | one contract suite (`<Domain>RepositoryContract`) run against the fake AND against PostgreSQL | none / DB |
| `integration/` | JPA repository, migrations, API through REST Assured against real PostgreSQL, health; `@QuarkusTest` and `@Tag("integration")` | DB |
| `architecture/` | ArchUnit layer rules, module-to-test mapping, the no-I/O rule for unit tests | none |
| `support/` | fakes and helpers (`FixedClock`, `InMemory...Repository`, name-guard extension) | none |

- **No I/O in unit tests, enforced mechanically (BL-TEST-4):** an ArchUnit rule on test classes: nothing in `..unit..` may depend on `io.quarkus.test..`, `java.net.Socket`, `java.net.http..` or `java.sql..`.
- **Module-to-test mapping (BL-TEST-2):** a test walks `src/main/java` and fails if a non-exempt class (interfaces, generated code, pure configuration are exempt, each with a reason) has no `<Class>Test` under `src/test/java`.
- **Naming:** unit and integration tests both end in `Test`; the split is `@Tag("integration")`, not `*IT`. `*IT` classes are for packaged-application tests (`@QuarkusIntegrationTest`).

## PostgreSQL in tests

- Same container as development, separate `<db>_test` database (created by the init SQL). Flyway migrates at start, so every run also exercises the migrations.
- Repository tests run in `@TestTransaction` and roll back.
- **API tests through REST Assured run in a different thread and transaction from the test method, so `@TestTransaction` does not cover them.** Truncate the domain tables in a `@BeforeEach` instead.
- A name-guard JUnit extension refuses to run when the JDBC URL's database does not end in `_test`.
- Tests that create or drop databases (migration tests) use a name unique per run (for example a UUID suffix), otherwise parallel runs collide.
- The contract suite runs on the fake and on PostgreSQL, so the fake cannot drift.
- Schema drift: with `schema-management.strategy=validate` in the test profile, Hibernate fails start-up if the JPA model and the Flyway schema disagree; add a test for downgrade and apply-to-empty-database as BL-OPS-4 requires.
