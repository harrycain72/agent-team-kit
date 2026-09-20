# Pitfalls (Quarkus backend)

See `stack-common/references/pitfalls.md` for the technology-neutral ones (pins, test database names, NUL characters, CORS order). The items below come from reading the generator output and the Quarkus conventions; none has bitten a project of ours yet.

1. **Jackson accepts unknown properties by default in Quarkus.** Set `quarkus.jackson.fail-on-unknown-properties=true` for strict bodies and test it with an extra field.
2. **`@TestTransaction` does not span HTTP calls.** REST Assured requests commit in their own transaction; clean the tables in `@BeforeEach`.
3. **`*IT` means a packaged-application test** in the Quarkus template (failsafe, `@QuarkusIntegrationTest`). Use `@Tag("integration")` for database tests.
4. **Dev Services starts its own PostgreSQL.** Disable it (`quarkus.devservices.enabled=false`) so development and tests use the compose databases and the `_test` name guard.
5. **Use the `quarkus-jacoco` extension for coverage,** not only the plain JaCoCo agent; `@QuarkusTest` classes are loaded by Quarkus' class loader and can be missed.
6. **Default port is 8080 and health is `/q/health`.** Set port 8000 and the health path in configuration to match the backend contract.
7. **Pin a stable Quarkus platform version.** The newest artifact on Maven Central can be a release candidate (`3.40.0.CR1` when this was written).
8. **Do not edit an applied Flyway migration.** Add a new `V<n>__` file; a checksum failure at start-up is the symptom.
9. **A malformed UUID path segment is 404 by JAX-RS rules,** but with the default body, not problem+json; add an exception mapper and a test.
10. **No global Maven on the development machine:** always call `./mvnw`.
