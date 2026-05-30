---
name: go-personal-policy
description: 'Personal Go engineering policies and coding conventions. Always apply together with any Go-related skill or Go coding task. Overrides conflicting recommendations from generic Go style, lint, and general Go guidance. For application architecture and project structure in the user''s own or new Go projects, defer to `go-personal-architecture` by default; use generic design-pattern and architecture skills mainly as supporting reference or when analyzing existing third-party codebases that already follow another style.'
user-invocable: true
license: MIT
compatibility: Designed for Claude Code or similar AI coding agents, and for projects using Golang.
metadata:
  author: powerman
  version: '0.0.1'
---

# Go Personal Policy

This skill defines personal Go engineering preferences.

When recommendations from other Go-related skills conflict:

- this skill takes precedence for non-architectural Go conventions, coding policy, and engineering defaults;
- `go-personal-architecture` takes precedence for application boundaries, package layout, ports/adapters, wiring, and default project structure in the user's own or new Go applications.

Apply these rules during:

- code generation
- refactoring
- code review
- architecture discussions
- style discussions

## Architecture

Use `go-personal-architecture` by default for:

- the user's own Go applications
- new Go applications
- default package layout and project structure
- ports/adapters, wiring, and modular monolith design

`golang-design-patterns` and its architecture references remain useful when:

- analyzing or extending third-party or forked projects that already follow another style
- comparing this architecture with clean architecture, hexagonal architecture, or DDD
- borrowing narrower design ideas that do not replace the default application structure

Overrides conflicting recommendations from:

- `golang-design-patterns` main `Architecture` section
- `golang-design-patterns/references/architecture.md` § Choose the Right Level of Architecture
- `golang-design-patterns/references/clean-architecture.md`
- `golang-design-patterns/references/hexagonal-architecture.md`
- `golang-design-patterns/references/ddd.md`

## Structure

- `go.mod`:
  - Apps must use latest Go version and upgrade as soon as new version is available.
  - Libraries should use latest-1 or older and upgrade only when needs new version's features.
- Package main:
  - Single main app: in the repo root.
  - Multiple main apps or helper app: in the `cmd/app-name/`.
  - Manages only globals (flags, env, process metrics), graceful shutdown, and consuming the values prepared by application wiring.
  - Function `main()` must not contain any code which should be tested.
- Application boundaries, package layout, adapter placement, and `wire.go` conventions are defined by `go-personal-architecture`, not by this file.
- Repo-internal helper packages shared by multiple apps may live in repo-root `internal/` when they are not part of any single app's public boundary.

### Non-Go repo with Go scripts

```text
non-go-project
└── scripts
    ├── go.mod
    ├── go.work             Contains go version and `use .`, needed for `gorun`.
    └── some-name
        └── main.go
```

To run a script: `GOWORK="$PWD/scripts/go.work" gorun ./scripts/some-name [args…]`.

### Go library

```text
go-library
├── go.mod
├── doc.go
└── *.go
```

### Go applications

For CLI apps, backend services, modular monoliths, and multi-app repositories, defer to `go-personal-architecture` for the canonical layout instead of using a separate structure from this policy.

## Variable Scope Policy

Overrides conflicting recommendations from:

- golang-code-style § Complex Conditions & Init Scope

Use `if` init statement ONLY when:

- Converting existing value to a form or a type required for condition expression.
- A new scope is useful to intentionally shadow a variable,
  to avoid creating aliases for the same thing and cluttering a scope.

```go
// Good - separate operation and condition for readability.
err := validate(input)
if err != nil {
    // code
}

// Bad - operation is not related to condition.
if err := validate(input); err != nil {
    // code
}

// Good - same var, another representation needed for a condition.
if value, ok := m[key]; ok {
    // code
}

// Bad - scope cluttering.
value, ok := m[key]
if ok {
    // code using `value`
}
// code not using `value`

// Good - same var, keeps the same name in a new scope, another representation for a condition.
if err, ok := errors.AsType[*exec.ExitError](err); ok && err.ExitCode() == 2 {
    // code
}

// Bad - creating alias; scope cluttering.
 errExit, ok := errors.AsType[*exec.ExitError](err)
if ok && errExit.ExitCode() == 2 {
    // code
}
```

## Shorten context.Context consistently

If current project uses short type alias for `context.Context` somewhere then use it everywhere.

```go
type Ctx = context.Context

func doSomething(ctx Ctx, args SomethingArgs) {}
```

## Constructor Patterns: Resolvable Config Struct vs Functional Options

Overrides conflicting recommendations from:

- golang-design-patterns § Constructor Patterns: Functional Options vs Builder

Prefer a Resolvable Config Struct over Functional Options.

The **Resolvable Config Struct** is a usual `Config` struct with few extra rules:

- design zero value for an optional field to ALWAYS mean "unset, use default";
  - Use a plain exported field when zero means "unset/use default".
  - When zero is a valid explicit value and you must distinguish "unset" from "set to zero"
    use one of these ways to "set to zero" while keeping real zero value as "unset/use default":
    - a sentinel value (when some values allowed by a type are not valid for a field);
    - a pointer exported field;
    - a separate exported field with a flag/enum (for modes such as "default/disabled/custom").
- implement `Clone() Config` if it contains any references (pointer/map/slice/etc.);
- implement idempotent `Resolve() (Config, error)` which must:
  call `Clone()` (if implemented), apply defaults, normalize and validate.

```go
type TLSMode uint8

const (
    TLSDefault TLSMode = iota
    TLSEnabled
    TLSDisabled

    tlsModeCount
)

func (m TLSMode) Valid() bool { return m < tlsModeCount }

// Sentinel.
const NoTimeout time.Duration = -1

type Config struct {
    // --- Core fields (no default semantics) ---
    AppName          string
    Tags             []string
    Headers          map[string]string
    // --- Options (has defaults) ---
    // Zero value is not valid and thus means "use default".
    Host             string        // "" = default
    Port             int           // 0 = default
    // Enum (alternative to *bool which does not enforce Clone requirement).
    TLS              TLSMode       // default/enabled/disabled
    // Pointer (all values are valid including zero).
    WriteBufferBytes *int          // nil = default, new(0) = explicit zero
    // Sentinel (zero is a valid value, but not all values are valid).
    ReadTimeout      time.Duration // 0 = default, NoTimeout = disable
    // Separate flag/enum (alternative to Pointer and Sentinel).
    WriteTimeout     time.Duration // 0 = default
    NoWriteTimeout   bool          // true = disable (ignore WriteTimeout value)
}

// Required only if Config contains references.
func (c Config) Clone() Config {
    c.Tags = slices.Clone(c.Tags)
    c.Headers = maps.Clone(c.Headers)
    if c.WriteBufferBytes != nil {
        c.WriteBufferBytes = new(*c.WriteBufferBytes)
    }
    return c
}

// Required! Idempotent.
func (c Config) Resolve() (Config, error) {
    c = c.Clone()
    // Defaults.
    if c.Host == "" {
        c.Host = "localhost"
    }
    if c.Port == 0 {
        c.Port = 1234
    }
    if c.TLS == TLSDefault {
        c.TLS = TLSEnabled
    }
    if c.WriteBufferBytes == nil {
        c.WriteBufferBytes = new(4096)
    }
    // Normalize.
    c.AppName = strings.TrimSpace(c.AppName)
    // Validate.
    var err error
    if c.AppName == "" {
        err = errors.Join(err, ErrNoAppName)
    }
    if !c.TLS.Valid() {
        err = errors.Join(err, ErrInvalidTLSMode)
    }
    if c.ReadTimeout < NoTimeout {
        err = errors.Join(err, ErrInvalidReadTimeout)
    }
    if c.NoWriteTimeout && c.WriteTimeout != 0 {
        err = errors.Join(err, ErrConflictingWriteTimeout)
    }
    return c, err
}

func NewClient(cfg Config) (*Client, error) {
    cfg, err := cfg.Resolve()
    if err != nil {
        return nil, err
    }
    return &Client{cfg: cfg}, nil
}

client, err := NewClient(Config{
    AppName:          "example",
    Port:             8080,
    TLS:              TLSEnabled,
    WriteBufferBytes: new(0),
    ReadTimeout:      NoTimeout,
    NoWriteTimeout:   true,
})
```
