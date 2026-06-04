---
name: go-bounded-context-hexagonal
description: Bounded-Context Hexagonal for Go CLI and backend service applications. Use whenever the user asks how to structure a Go application, choose package boundaries, define ports and adapters, wire dependencies, design a modular monolith, or compare approaches with hexagonal, clean architecture, or DDD. Prefer this skill by default for the user's own and new Go applications, even when the user only mentions package layout, hexagonal architecture, clean architecture, DDD, ports/adapters, or project structure. Do not use it as the primary architecture guide for reusable libraries, and do not let generic architecture or design-pattern skills override it for the user's default app structure.
user-invocable: true
license: MIT
compatibility: Designed for Claude Code or similar AI coding agents, and for Go CLI and backend service applications. For reusable libraries, prefer library-focused Go skills instead of this application-architecture skill.
metadata:
  author: powerman
  version: '0.2.0'
---

# Bounded-Context Hexagonal

This skill defines the Bounded-Context Hexagonal Go application architecture for CLI and backend service applications.
It is closest to Hexagonal Architecture, but it is stricter about bounded-context boundaries,
flatter package layout, and the separation between application and executable.

When recommendations conflict:

- This skill wins for application boundaries, package layout, ports/adapters, and wiring.
- For the user's own projects and for new application code, prefer this skill over generic architecture or design-pattern guidance, including `golang-design-patterns`.
- `golang-design-patterns` remains useful as background reference material and for understanding or adapting third-party codebases that already follow another architecture.
- `go-engineering-policy` still applies for non-architectural Go conventions unless it conflicts
  with this skill's application structure.

Apply these rules during:

- architecture discussions
- package layout design
- refactoring an app structure
- designing CLI and backend services
- modular monolith design
- testing strategy discussions for application boundaries

## Scope

- Use this skill for applications, not reusable libraries.
- Treat **Bounded Context = Application**.
- A tiny CLI may collapse packages into files without changing responsibilities.
- Prefer one coherent application boundary over multiple internal architectural layers.

## Core Model

### One application = one bounded context

Treat a Go application as one bounded context owned by one team.
Do not introduce extra internal bounded-context-like boundaries inside the app by default.

Consequences:

- Use **one In port for the whole application**.
- Use **one Repo/DAL Out port per owned database**.
- The application is the only owner of its database data.
  Other apps must use its API, or in a modular monolith call its direct `port.App` API.

### Executable != Application

Do not equate a binary with an application.

- A binary is a deployment unit.
- An application is a bounded context.
- One binary may include multiple applications.
- Different binaries may include the same application.

This means application code must stay importable whenever the app is meant to be imported by other packages.
Do not bury an importable application inside an executable-local `internal/` tree.

### Business logic is one `app` package by default

Do not split the business logic into `domain/` and `application/` by default.
That split is often a workaround for package cycles, not an architectural necessity.

The public architecture is fixed by `wire.go`, `port.App`, and the adapter boundaries.
The internal architecture of `app` should follow the needs of the specific business logic.
Inside `app`, organize code by use case, workflow, invariant cluster, subdomain, or private helper interfaces whenever that improves clarity.
Do not force one universal inner style on every application.

Prefer this order of growth:

1. Keep business logic in one `app` package.
2. Split it into files first.
3. If needed, add helper subpackages under `internal/app/...` while keeping `app` the facade.
4. If it still feels too large, re-check whether the bounded context is too wide.

### Adapters must stay thin

Adapters are allowed to do only three things:

- talk to the outside world
- validate external protocol or transport shape
- convert between external formats and application-facing types

Adapters must not contain business decisions.
The business logic package must not import transport or process packages like `net/http`, `os`, or transport SDKs.

## Layout Selection

Choose the layout shape before proposing a package tree.

### Prefer the simplest sufficient layout

Start with the simplest layout that honestly fits the application today.
Move to a special variant only when a concrete need appears, not just because the app might grow later.

Default progression:

1. **Flat** — when the executable is truly small and separate packages would mostly add noise.
2. **Default layout** — when the app benefits from explicit packages but still does not need to be imported from outside the executable boundary.
3. **Importable** — only when another package, binary, application, or repository must import the application boundary.

Typical transition signals:

- move from **Flat** to the **default layout** when the app stops feeling flat, adapters multiply, tests become awkward, or `app` wants helper subpackages
- move from the **default layout** to **Importable** when another binary, package, or repository must call the app through a stable in-process API
- do not skip straight to a more complex layout only because future growth is imaginable

### Use the **Flat** variant when:

- the executable is tiny
- splitting packages would add ceremony without improving tests or reuse
- you still keep the same roles (`wire`, `port`, `app`, `out`, `dal`) but collapse them into files

### Use the **default layout** when:

- only the executable should use the app
- no external package should import the app boundary
- the app is large enough that explicit packages help
- hiding the app behind `package main` is acceptable

### Use the **Importable** variant when:

- another package or binary must import the app
- another repository's tests must run the app as a function
- the app participates in a modular monolith
- the app should expose a direct in-process API

## Flat Layout

Use this only for very small applications where separate packages would be mostly noise.

```text
tool-basic/
├── go.mod
├── main.go
├── wire.go
├── port.go
├── app.go
├── redis.go
└── ...
```

Rules for this variant:

- Keep responsibilities separated even if files share a package.
- Do not move wiring logic into `main.go` just because the app is small.
- Collapse packages only when the app is truly tiny.
- When the app grows, expand to the default layout first.

## Default Layout

Use this layout when the app does not need to be imported from outside the executable boundary.

```text
tool/
├── go.mod
├── main.go
├── wire.go                     Mandatory; do not push wiring into main.go.
└── internal/
    ├── port/
    │   ├── port.go             App + Repo + other Out ports + port-level errors.
    │   └── types.go            Optional boundary DTO/types file.
    ├── app/
    │   ├── app.go              Implements port.App.
    │   └── ...
    ├── in/
    │   ├── http/
    │   │   └── adapter.go
    │   └── nats/
    │       └── adapter.go
    ├── dal/
    │   ├── adapter.go
    │   └── migrations/
    │       └── 00001_some_name.sql
    └── out/
        ├── nats/
        │   └── adapter.go
        └── redis/
            └── adapter.go
```

Rules for this layout:

- `wire.go` is still mandatory.
- `wire.go` may live in `package main`.
- Keep the private in-process contract in `internal/port`.
- `internal/app` stays focused on business logic and implements `port.App`.

## Importable Layout

Use this layout only when the application must be imported by other packages, binaries, or repositories.

```text
modular-monolith/
├── go.mod
├── api/                        External wire contracts: proto, events, OpenAPI, etc.
├── apps/
│   ├── registry.go             Optional registry struct containing all wired apps.
│   └── exampleapp/             Suffix "…app" is optional.
│       ├── wire.go             Public wiring API for this application.
│       ├── integration_test.go Integration smoke tests for the whole app.
│       ├── port/
│       │   ├── port.go         App + Repo + other Out ports + port-level errors.
│       │   └── types.go        Optional boundary DTO/types file.
│       └── internal/
│           ├── app/
│           │   ├── app.go      Implements port.App.
│           │   └── ...
│           ├── in/
│           │   ├── grpc/
│           │   │   └── adapter.go
│           │   ├── http/
│           │   │   └── adapter.go
│           │   └── nats/
│           │       └── adapter.go
│           ├── dal/
│           │   ├── adapter.go
│           │   └── migrations/
│           │       └── 00001_some_name.sql
│           └── out/
│               ├── nats/
│               │   └── adapter.go
│               └── redis/
│                   └── adapter.go
├── cmd/
│   ├── cli/
│   │   └── main.go
│   └── server/
│       └── main.go
├── dom/                        Optional shared pure business types if public outside repo.
├── internal/
│   └── dom/                    Optional shared pure business types if only repo-internal.
└── platform/
    ├── log/
    ├── metrics/
    ├── repo/
    └── serve/
```

Rules for this variant:

- `wire.go` is mandatory.
- `integration_test.go` next to `wire.go` is recommended as the first place to smoke test the whole app.
- The direct in-process API exposed to other packages is `port.App`, not the concrete `internal/app` type.
- `port/` is public because it is the bounded-context contract.
- `internal/app` stays private and implements `port.App`.
- `cmd/*/main.go` stays thin and should only handle process concerns plus consuming the prepared values returned by `wire.go`.
- In multi-app repositories, `main` may call `apps.Registry()` to assemble all applications and return a registry such as `type Registry struct { Example example_port.App; Other other_port.App; ... }`.
- `apps/registry.go` is the composition root for all application modules in the repository and should not accumulate unrelated functionality.
- Applications do not import each other directly. They collaborate through the registry.
- Prefer passing only the needed part of another application's API through DI instead of keeping the whole registry as a global.
- `api/*` defines wire formats between processes.
- `port/*` defines the in-process contract of the application.
- `internal/in/*` adapts `api/*` or transport-specific DTOs to `port.App`.
- `internal/out/*` and `internal/dal/*` may depend on `api/*` when external wire formats are shared.

## Ports

### Keep port interfaces together

Prefer one `port.go` file containing all application-facing interfaces:

- `App`
- `Repo` / DAL port(s)
- other Out ports
- port-level errors

Why:

- In `Transaction Script` style, `Repo` methods often mirror `App` methods closely.
- Reading all port interfaces together makes it easier to verify whether the available Out ports are sufficient to implement `App` methods.
- Splitting interface files too early hides the contract surface.

Optional split:

- move DTO-like boundary types to `types.go`
- move errors to `errors.go` only if `port.go` becomes noisy

Even when split into files, keep them in the same `port` package.
Errors are part of the port contract, not internal implementation details.

### Keep `port` outside `app` except in the Flat variant

Treat `port` as the application boundary contract and `app` as its implementation.
That means the default shape is either:

- everything collapsed into one package for a truly flat executable, or
- `port` as a separate package and `app` implementing it

Why this split matters:

- if everything is still in one flat package, there is no package-boundary problem to solve yet
- once `app` grows and wants helper subpackages, a `port.go` inside `app` starts pushing those subpackages to import `app` just to reach the contract
- at the same time, the top-level `app` package may need to import its own helper subpackages
- that creates avoidable import-cycle pressure around the very contract that should stay dependency-light

So prefer these defaults:

- **Flat**: keeping `port.go` and `app.go` in one package is fine because the app is intentionally flat
- **default layout**: use `internal/port` + `internal/app`
- **Importable**: use public `port/` + private `internal/app`

Do not put `port` inside `app` as the default for non-flat layouts.
If you do collapse them temporarily, treat it as a local simplification for a flat app, not as the growth path.

### `App` is the direct application API

For importable applications, direct in-process calls must go through `port.App`.
Do not expose `internal/app` as public API.

This is how:

- modular monolith apps call each other directly
- CLI entrypoints use the application without inventing a fake `in/cli` adapter
- external integration tests introspect the app through public methods

### Repo is a transaction boundary

Treat the DAL port as a `Transaction Script` style boundary.
Do not invent extra transaction abstractions unless the concrete case requires them.
A separate `app/tx.go` layer is usually unnecessary.

Use task-centric DAL methods that reflect business operations and their transactional needs.
This usually gives clearer transaction boundaries than entity-shaped `Get/Save` repositories.
It also allows SQL to be optimized for each business task instead of being distorted by ORM-like repository shapes.

Like `app`, the internal structure of `dal` is free to follow the actual persistence complexity.
Start with one package, then split by files, helpers, or private subpackages only when that improves clarity.

## Adapters

### `internal/in/*`

Use `internal/in/*` only for application-owned inbound adapters reached through transport or messaging.
Typical examples:

- HTTP
- gRPC
- NATS / Kafka subscriber
- other network or message driven entrypoints

Do **not** create `internal/in/cli`.
CLI belongs to the executable layer, not to the application-owned inbound adapters.

### CLI lives in `main`

For CLI binaries:

- treat `main.go` or `cmd/*/main.go` as the CLI adapter
- wire the application in `wire.go`
- call `port.App` directly

This avoids creating fake abstraction layers for Cobra, Kong, urfave/cli, and similar frameworks.

### `internal/dal`

Use `internal/dal` for the owned database adapter.
Keep migrations near it.

This is separate from `out/` because the owned DB is special:

- it defines transactional boundaries
- it carries migrations
- it is owned by the application
- it is tested differently from other outbound dependencies

### `internal/out/*`

Use `internal/out/*` for outbound adapters except the owned DB.
Examples:

- Redis
- NATS publisher
- email or SMS provider
- third-party HTTP/gRPC clients

`out/*` may depend on `api/*` when shared external wire contracts exist.

## Wiring

`wire.go` is mandatory in all package modes.

Its responsibility is wiring only:

- build the dependency graph
- prepare already-configured application and adapter objects
- return values ready to be started or used by the caller

Do not make `wire.go` start servers, background workers, or other lifecycle-managed processes by itself.
That would make the same wiring harder to reuse from CLI code and integration tests.

Do not put dependency graph construction into `main.go`.
`main.go` should only coordinate:

- flags and env
- process lifecycle
- graceful shutdown
- starting and stopping the already-prepared values returned by `wire.go`

### Prefer one wiring entrypoint

Recommend one main wiring entrypoint per application as the default.
In practice, the API that is convenient for the application's own integration tests is often also the API that works well for:

- `cmd/server/main.go`
- `cmd/cli/main.go`
- integration tests in other applications or repositories

A single entrypoint helps keep the application boundary coherent.
Only introduce multiple wiring entrypoints when the concrete use cases truly diverge.

### Design the returned value for all main consumers

The main wiring entrypoint should usually return a value that can satisfy all key consumers with minimal adaptation:

- CLI code needs direct access to `port.App`
- server code needs the prepared inbound adapters or startable components
- integration tests may need mock injection plus `port.App` access for introspection

The stable rule is: make wiring explicit, reusable, testable, and separate from `main.go`.
Do not optimize `wire.go` for one executable in a way that makes the same application harder to reuse elsewhere.

## Shared Domain Types

Use shared pure business types only in repositories that contain multiple applications, for example `apps/*` modular monolith repositories.
Possible locations:

- `dom/` when the shared types are part of public repo API
- `internal/dom/` when they are shared only inside the repository

Good examples:

- `Money`
- `Email`
- `CountryCode`
- `TimeRange`

Do not turn `dom/` into a generic dumping ground.
It must stay pure and must not depend on ports, adapters, or infrastructure.

## Naming

Prefer short, high-signal names for packages and frequently used identifiers.
Short names matter most for packages that are referenced often in code. For package names that mostly stay in the directory tree and are rarely imported directly, clarity and local convention matter more.
Recommended package names:

- `dom`
- `app`
- `in`
- `out`
- `dal`
- `srv`
- `svc`
- `sub`
- `repo` when `dal` is not the better fit

Do not repeat the same business noun at every level.
If the repository or directory already says `order_service`, do not add redundant names like:

- `order_service.go`
- `order/order.go`
- `service/order_service.go`

Prefer consistent generic filenames where the package already provides context:

- `adapter.go` for the main adapter implementation file
- `app.go` for the main business-logic file
- `port.go` for the main port contract file
- `wire.go` for wiring

Prefer `New` as the main constructor name when the package name already explains what is being created.

For an importable application package, an `app` suffix on the package itself
(`apps/exampleapp`, `package exampleapp`) is optional but can be convenient:
it lets embedders import it without an alias and avoids a generic, shadow-prone bare noun.
If used, keep the bare context name for runtime identity
(`port.AppName`, env prefixes, asset paths).

## Testing Strategy

- Generate mocks for all In/Out ports.
- Test business logic with unit tests using mocks for Out ports.
- Test In adapters with unit tests using a mock `port.App`.
- Test DAL adapters with integration tests against a real temporary database.
- Test other Out adapters with integration tests against fake or real network services started by the test.
- For services, add smoke tests that exercise:
  - each external API entrypoint
  - each subscriber or event-consumer type

For importable applications, external repositories' tests may import the app and start it via public wiring APIs.
That is a valid use case and should shape the package mode choice.

## Modular Monolith Rules

In repositories with multiple `apps/*`, treat each application as the same application module you would otherwise deploy as a separate service.
Moving these modules into one binary changes transport and wiring, not ownership, dependency mapping, or interaction design.

Use `apps/registry.go` as the in-process composition root for these modules.
Typical shape:

```go
package apps

type Registry struct {
	Example example_port.App
	Other   other_port.App
}
```

Guidelines:

- `main` or another top-level composition root may call `apps.Registry()` to assemble all applications.
- `apps/registry.go` is a composition root, not a service locator and not a place for unrelated business logic.
- `port.App` is the direct in-process API of an application module.
- When one application needs another application's functionality, prefer taking the needed part through DI from the registry instead of accessing the entire registry as a global.
- Cross-application data ownership still applies: applications do not read each other's data directly from the database. Enforce this operationally, for example with separate credentials even on a shared DB.
- Document the interaction map the same way you would for separate services when it stops being obvious from the directory tree alone.

## Decision Checklist for Claude

When proposing a design or refactor, follow this checklist:

1. Decide whether the application is reusable or private.
2. Keep one `App` boundary for the whole bounded context.
3. Keep one Repo/DAL port per owned DB.
4. Make `wire.go` explicit and mandatory.
5. Use `port.App` as the direct public API for importable apps.
6. Do not create `internal/in/cli`.
7. Keep adapters thin.
8. Keep the package tree flat: prefer `in/`, `out/`, `dal/`, `app/` over deep `adapter/primary/secondary/...` trees.
9. Introduce `dom/` or `internal/dom/` only for truly shared pure types in repositories with multiple applications.
10. If `app` or `dal` grows, split by files first, then by helper subpackages, and only then question the bounded context.
11. In modular monolith repositories, treat each application as an application module and use `apps/registry.go` as the composition root.
12. Prefer DI from the registry over global registry access when wiring one application's dependency on another application's API.
13. Document the application-module map when cross-application interactions stop being obvious from the directory tree.

## What to Avoid

Avoid these default moves unless the specific case truly needs them:

- splitting every app into `domain/`, `application/`, and `service/`
- one repository per entity or aggregate by default
- deep `adapter/primary/secondary` directory trees
- `internal/in/cli`
- putting all wiring into `main.go`
- exposing concrete internal app types instead of `port.App`
- placing importable application code under executable-local `internal/`
- treating multi-app repositories as if applications should import each other's internal business logic directly
- turning `apps/registry.go` into a generic dumping ground or service locator
- defaulting to global registry access when a narrower dependency can be injected from the registry
