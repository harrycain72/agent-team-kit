# Backend layout (Quarkus)

The repository root, `docs/`, compose and CI are in `stack-common/references/layout.md`. This pack defines `backend/`:

```
backend/
├── pom.xml                       # imports the pinned Quarkus BOM; enforcer, spotless, surefire, quarkus-jacoco
├── mvnw, mvnw.cmd, .mvn/wrapper/ # Maven wrapper
├── src/main/java/<pkg>/
│   ├── shared/                   # shared kernel: clock and id producers, problem builder, request-id filter; imports no domain package
│   └── <domain>/                 # one BCE component per business domain
│       ├── boundary/             # JAX-RS resource, request/response records, exception mappers -> problem+json
│       ├── control/              # public service, commands, business exceptions; @Transactional here
│       └── entity/               # rules, JPA entities, criteria, repository interface, Jpa<Domain>Repository
├── src/main/resources/
│   ├── application.properties    # base settings and %dev / %test profiles
│   └── db/migration/V1__*.sql    # Flyway
└── src/test/java/<pkg>/{unit,integration,contract,architecture,support}/
```

Add to `.gitignore`: `target/`.

## Configuration (`application.properties`)

```
quarkus.http.port=8000
quarkus.rest.path=/api/v1
quarkus.smallrye-health.root-path=/health
quarkus.jackson.fail-on-unknown-properties=true      # strict bodies
quarkus.http.limits.max-body-size=...                # 413 above the limit
quarkus.http.cors.enabled=true                       # origins from configuration
quarkus.devservices.enabled=false                    # use the compose database
quarkus.datasource.jdbc.url=${DB_URL}                # from the environment; .env.example lists it
quarkus.flyway.migrate-at-start=true
%test.quarkus.datasource.jdbc.url=jdbc:postgresql://localhost:5432/<db>_test
%test.quarkus.hibernate-orm.schema-management.strategy=validate   # models and migrations must agree
```

## Commands behind the Makefile targets

```
install (backend)   ./mvnw -B -q dependency:resolve
migrate             db-up, then ./mvnw flyway:migrate   (flyway-maven-plugin, URL from the environment)
dev-backend         ./mvnw quarkus:dev
test-unit (backend) ./mvnw test -DexcludedGroups=integration
test-integration    db-up, ./mvnw test -Dgroups=integration
test-backend        ./mvnw verify   (quarkus-jacoco report, coverage rule 90 % line and branch)
lint (backend)      ./mvnw spotless:check   (the ArchUnit rules run inside test-unit)
```

Run all of these from `backend/` (the Makefile does `cd backend`).

## Verify at first scaffold (record the outcome as an ADR or in the TDD log)

- The property names above against the pinned Quarkus version: `quarkus.rest.path`, `quarkus.smallrye-health.root-path` (so health is `/health`, not `/q/health`), `quarkus.hibernate-orm.schema-management.strategy`, `quarkus.jackson.fail-on-unknown-properties`.
- A test proving 413 and 500 responses carry CORS headers and the problem body with the request id.
- That the local JDK matches the pinned release; the enforcer plugin fails the build otherwise. (The development machine had JDK 27 and no global Maven when this pack was written; `--release 25` and the wrapper avoid depending on either.)
- How `quarkus-jacoco` combines with `jacoco:check` for the 90 % gate on `verify`.
- That `@Tag("integration")` selection with `-Dgroups` / `-DexcludedGroups` works with the pinned surefire.
