# BCE (boundary, control, entity) per business domain, in Java

| Layer | Responsibility | Must not |
|---|---|---|
| **boundary** | JAX-RS resources, request/response records with Bean Validation, exception mappers to problem+json | contain business rules; touch `jakarta.persistence` or a repository |
| **control** | use cases (the service): orchestration, `@Transactional`, business exceptions | know about HTTP (`jakarta.ws.rs`) |
| **entity** | domain model with behaviour and invariants, rules and constants, query criteria, the repository **interface** and its JPA implementation | import `jakarta.ws.rs`, Jackson, or control/boundary |

Dependency direction: `boundary -> control -> entity`. `shared` may be used by all layers and depends on no domain package. A domain's `control` package is its public API; other domains reach it only through that, with ids as references and no cross-domain JPA relationships.

Rules:
1. Business rules live in entity (rules class, entity methods) and are orchestrated by control. Bean Validation annotations in boundary reference the same `static final` constants (one source of truth) for accurate 422 and OpenAPI, but control and entity validate again.
2. Each write use case is one `@Transactional` control method; repository methods only persist and flush; a runtime exception rolls back.
3. Boundary injects only the control service. The control service is the only place that uses the repository interface; the JPA implementation is a CDI bean chosen by injection, never constructed in boundary.
4. JPA entities are allowed in entity (they are the persistence model, like SQLAlchemy models); they do not leak into responses: boundary maps them to response records.
5. Constructor injection only; producers in `shared` provide `java.time.Clock` and `Supplier<UUID>`.

## Enforcement (ArchUnit, in `src/test/java/<pkg>/architecture/`)

```java
@AnalyzeClasses(packages = "<pkg>", importOptions = ImportOption.DoNotIncludeTests.class)
class ArchitectureTest {

  @ArchTest
  static final ArchRule bceLayers = layeredArchitecture().consideringOnlyDependenciesInLayers()
      .layer("Boundary").definedBy("..boundary..")
      .layer("Control").definedBy("..control..")
      .layer("Entity").definedBy("..entity..")
      .whereLayer("Boundary").mayNotBeAccessedByAnyLayer()
      .whereLayer("Control").mayOnlyBeAccessedByLayers("Boundary")
      .whereLayer("Entity").mayOnlyBeAccessedByLayers("Control", "Boundary");

  @ArchTest
  static final ArchRule sharedIsDomainFree = noClasses().that().resideInAPackage("<pkg>.shared..")
      .should().dependOnClassesThat().resideInAnyPackage("<pkg>.<domain>..");

  @ArchTest
  static final ArchRule controlAndEntityAreHttpFree = noClasses()
      .that().resideInAnyPackage("..control..", "..entity..")
      .should().dependOnClassesThat().resideInAnyPackage("jakarta.ws.rs..", "org.jboss.resteasy.reactive..");

  @ArchTest
  static final ArchRule entityIsJsonFree = noClasses().that().resideInAPackage("..entity..")
      .should().dependOnClassesThat().resideInAPackage("com.fasterxml.jackson..");

  @ArchTest
  static final ArchRule boundaryDoesNotTouchPersistence = noClasses().that().resideInAPackage("..boundary..")
      .should().dependOnClassesThat().resideInAnyPackage("jakarta.persistence..", "org.hibernate..");
}
```

The boundary rule allows boundary to read entity types (to map them) but not to use the persistence API. Add one cross-domain rule per pair of domains: a domain may depend on another domain's `..control..` package only.

Do not weaken a rule with `allowEmptyShould` or exclusions to make it pass; fix the package split instead.

## Errors and request handling

- Control throws business exceptions (`NotFoundException`-style, `ValidationFailed` with field errors); boundary registers `@ServerExceptionMapper` methods (or `ExceptionMapper` classes) mapping them to problem+json, and one catch-all mapper builds the 500 problem.
- A `ContainerRequestFilter` sets the request id (from the incoming header or generated), puts it in the logging MDC and echoes it as a response header; problem builders read it from the request context so the ids in header and body match.
- A malformed `UUID` path segment fails parameter conversion and yields 404 per JAX-RS; map that to the problem body too.
- Preflight requests are answered by CORS alone; do not test them for request ids.
