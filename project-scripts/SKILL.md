---
name: project-scripts
description: 'Personal policy for scripts of a project — where a script lives (inline in mise.toml, a shell file in mise/tasks/, or a Go program in scripts/), when shell must be rewritten in Go, and how Go scripts are laid out, built, run as mise tasks, tested, linted and covered. Use it whenever you write, move, review or plan a script or a mise file task, add or change scripts/, port a shell script to Go, want to add a test or a shared library to a script, or decide whether a project needs shfmt/shellcheck — even if the user only says "add a task which does X" or "this script got too complex".'
user-invocable: true
license: MIT
compatibility: Designed for Claude Code or similar AI coding agents, and for projects using mise and Go.
metadata:
  author: powerman
  version: '0.2.0'
---

# Project Scripts

Shell is a poor language for programming, so projects keep logic out of shell scripts.
When a script can't be avoided, it climbs a ladder of places,
and a script which gets complex is rewritten in Go instead of growing in shell.

This approach is being tried on real projects.
Follow it by default, so that results of different projects can be compared.
When a rule clearly doesn't fit the situation, deviate, say why,
and tell the user where the approach caused friction:
this feedback is what decides whether the approach survives.
Most rules below rest on verified behaviour of mise
(`references/mise-facts.md` of the `mise-toml-style` skill) or on other skills;
the few which are only a current choice are marked so.

For the style of `mise.toml` and its tasks see the `mise-toml-style` skill.

## Where a script lives

1. **Inline in `mise.toml`** — a trivial script.
   shfmt and shellcheck don't see inline scripts, which is one more reason to keep them trivial.
   A need for bash (`pipefail`, arrays) means the script has outgrown `mise.toml`.
2. **A shell file in `mise/tasks/`** — a long but linear script:
   mostly runs of external commands, little logic and few variables
   (e.g. bootstrap of a database: create users, grant rights).
   Rewriting such a script in Go would be pointless over-engineering.
   It has no tests and sources no shared libraries.
3. **A Go program in `scripts/`** — a script which needs a test,
   code shared with another script, or real logic (data processing, branching, error handling).
   The wish to write a test for a shell script or to extract a library from shell scripts
   is the signal to rewrite them in Go now.
   Don't build test infrastructure for shell (bats, helpers),
   and don't add a second language with its own environment (venv, `package.json`):
   one toolchain for all non-trivial scripts keeps every project simple.
4. **A script whose language is dictated by the place where it runs** stays in that language:
   a setup script mounted into a container by docker compose,
   a long step of a CI workflow moved out of `.yml`.
   These are not tasks of the project.
   Such a script lies next to its consumer
   or in `scripts/` next to the Go module (Go ignores non-Go files).

The habit to write scripts in shell is strong,
and shell scripts tend to grow into unmanageable code.
When a shell script starts to gain logic, or a change would add it,
insist on the rewrite in Go instead of extending the shell.
When an existing project gets Go scripts,
only the scripts which became too hard to write and test are rewritten;
linear shell scripts stay where they are.

### Scripts of a distributed agent skill

A script shipped inside an agent skill is not a script of the project which develops the skill:
it runs on machines of the skill's users, who may have no Go toolchain.
It lives inside the skill and is written in a language its users surely have.
The rest of this skill doesn't apply to it.

## shfmt and shellcheck

A project adds shfmt and shellcheck together with its first shell file.
A project which is expected to grow scripts (e.g. an example of the style of large projects)
may have them from the start.

## Go scripts

Go replaces shell to get clear code and tests.
A test needs the external commands of a script behind an interface,
which brings the layers of the hexagonal architecture,
and these layers are easier to keep in separate files than in one.
A single-file Go script without tests (shell rewritten line by line with `bitfield/script`)
gets neither benefit,
so it's usually a sign that the script should have stayed in shell or still lacks tests.

### Working example

[powerman/go-scripts-example](https://github.com/powerman/go-scripts-example)
is a project whose own tasks are Go scripts in this style,
tested on CI on Linux, macOS and Windows.
Look there for what this skill only describes:
the full code of a program and its tests (a Fake of `World`, a Mock of `App`,
an integration test of the real `World`), code shared in `scripts/internal/`,
`.mockery.yml`, tasks and CI of a project which supports Windows.
Read it when you add the first Go script to a project
or when you're unsure how a file of a program should look.
It evolves separately and may be ahead of this skill:
when they disagree, tell the user about the difference.

### Module

`scripts/` is a separate Go module with its own `go.mod`:

- dependencies of scripts (Kong, `bitfield/script`, …) don't get into `go.mod` of the project;
- the same layout works in projects of every language;
- in a Go project `go list ./...` of the root skips the nested module,
  so linters, tests and coverage of the project don't see scripts.

golangci-lint looks for its config from `scripts/` upwards,
so in a Go project scripts are linted by the root `.golangci.yml`,
with the same rules as the code.
A project in another language has `scripts/.golangci.yml`.

Go commands for scripts run in `scripts/`: `go run ./scripts/hello` from the root fails,
because the root isn't this module.
So each task in `scripts/tasks.toml` has `dir = 'scripts'`,
and CI without mise uses `go -C scripts`.

`scripts/` has no own `mise.toml`: mise loads configs of parent directories too,
so tools, tasks and settings of both would mix.
Go and tools for scripts are tools of the root `mise.toml`,
and tasks to develop scripts are in `scripts/tasks.toml`, included by the root config:

```toml
[task_config]
includes = ['mise/tasks', 'scripts/tasks.toml']
```

`includes` replaces the default directories of file tasks, so `mise/tasks` must be listed too.

The name `scripts/` describes the role (automation of the routine of the project),
not the language.
It isn't `mise/go/`: Go scripts don't depend on mise and can be run by hand or on CI.

### Program

- A program of task `<task-name>` is `scripts/<task-name>/` (`:` in the name becomes `-`).
  Shared code lives in `scripts/internal/`.
  These names are a current choice.
- A program follows the flat layout of the `go-bounded-context-hexagonal` skill:
  a thin `main.go`, and `internal/` with
  `port.go` (`App`, `World` of external commands, errors, types),
  `app.go`, `cmd.go` (Kong CLI calling `App`), `wire.go`, `world.go` (real commands).
  When scripts need a change of this layout,
  it's made in the `go-bounded-context-hexagonal` skill, not here.
- The Kong struct is the only spec of the CLI.
  It has a field `UsageSpec kongusage.Flag` (`github.com/powerman/kongusage`)
  which prints the usage spec for mise, and a test checks the spec by `kongusage.CheckSpec`.
  `kong.Name` is the task name: the binary is named by its directory.
- `main.go` binds `App` made by `WireApp` to Kong
  (`ctx.BindTo(internal.WireApp(), (*internal.App)(nil))`),
  so a test of the CLI binds a mock instead.
- `Run` returns errors: `ctx.FatalIfErrorf` exits with the exit status of a failed command
  (an error with `ExitCode()`), so the status reaches mise.
- External commands are run with `github.com/bitfield/script` (a current choice):
  - start a pipe by `script.NewPipe().WithStderr(os.Stderr)`,
    otherwise stderr of a command goes into the pipe and its filters;
  - run a command built from values by `ExecCommand(name, args...)`,
    a literal shell command line by `Shell`, never by `Exec` (inconsistent quoting);
  - never discard the error of the last stage of a pipe;
  - it can't set a working directory of a command, so use options like `git -C <dir>`;
  - a command which exits with status 1 when nothing is found (like `git grep`)
    needs a check of `ExitStatus()`, like `|| [ $? -eq 1 ]` in shell.

Go conventions of the `go-engineering-policy` skill apply to scripts as to any Go code.

### Tests

The general rules (gomock for exact calls, the mockery template `fake` for state)
are in the `go-engineering-policy` skill; for a script they mean:

- **Logic (`app.go`) is tested with a stateful Fake of `World`**, generated by mockery.
  A test helper embeds the Fake and keeps the state of the world (e.g. files of a repository),
  which default hooks read and change.
  A test sets the initial state, runs `App` and checks the final state
  instead of listing each expected call,
  so it doesn't break when the logic reads a file once more or in another order.
  A failure is injected for one call by `PushReturn`, calls are checked by `History`.
- **CLI (`cmd.go`) is tested with a Mock of `App`**, generated by mockgen
  (`//go:generate mockgen -source=port.go …`):
  the exact call of `App` made for given flags is exactly what such a test should check.
  The test parses arguments by Kong like `main.go`, with writers and exit replaced.
- **Real `World` (`world.go`) is tested by an integration test**
  with real commands in a temporary directory (e.g. a real git repository),
  which shows that the commands work on each OS.

Generated Fakes and Mocks are `_test.go` files of package `internal_test` next to `port.go`.
`scripts/.mockery.yml` lists `World` of each program,
and the template is a copy of `fake` from `github.com/powerman/mockery-templates`
in `scripts/.mockery/`.

### Task

A task in Go is a one-liner in `mise.toml`:

```toml
[tasks.hello]
description = 'Print a greeting'
depends = ['scripts:build']
usage = 'mount run="mise run -q hello --usage-spec"'
raw_args = true
run = '.cache/bin/hello'
```

- `scripts:build` rebuilds programs into `.cache/bin/` only when files of `scripts/` change,
  so a start takes a few milliseconds.
  `go run` isn't used: its own check of changes takes much longer.
- Another task which runs a program does the same (`depends` and `.cache/bin/…`):
  `mise run` or `{ task = … }` would add tens of milliseconds to each start.
- A program started outside of mise may be outdated:
  run `mise run scripts:build` before running it many times by hand.
- mise runs the `usage` command only to complete arguments of this task,
  so the spec is never stale and a broken spec breaks completion of only this task.
  Each Tab on arguments of the task checks for changes (maybe builds) and starts the program,
  which takes a few tens of milliseconds.
- `raw_args = true` makes mise pass arguments as is instead of parsing them by the spec,
  so `--help` and invalid flags reach Kong.
  mise removes `--` after the task name, so a first argument starting with `-`
  needs `mise run <task> -- -- -x`.
- Don't write a spec of arguments in `mise.toml` and don't add a file to `mise/tasks/`.

### Tasks to develop scripts

Tasks in `scripts/tasks.toml` have prefix `scripts:`.
It keeps them apart from tasks of the project (e.g. `lint:go` of a Go project)
and from its globs like `lint:*`.
The prefix isn't `scripts:go:`: scripts in another language with own tooling
would need their own directory anyway.

Root tasks `generate`, `fmt`, `lint`, `test` and `bump` run them.
Tasks which nobody runs alone are hidden (`scripts:build`, `scripts:fmt`, `scripts:lint`, …),
tasks useful alone stay visible (`scripts:test`, `scripts:fix`, `scripts:cover`).

`bump` runs `scripts:bump` by a nested `mise run` after `mise up`:
a task started by `{ task = … }` would get the Go of the old process,
and `go.mod` would get the Go version from before the upgrade.

`scripts:generate` deletes outputs of mockery before running it:
mockery fails to load a package with an outdated output.
`scripts:lint` also lints usage specs of all programs by `usage lint`.

Reference files (copy and adapt):

- `references/scripts-tasks.toml` — `scripts/tasks.toml`;
- `references/root-mise.toml` — parts of the root `mise.toml` which serve scripts;
- `references/scripts-mockery.yml` — `scripts/.mockery.yml`.

### Platforms

Scripts support the platforms of the project, no more.
A project which doesn't support Windows has no `run_windows` in tasks of scripts
(drop it when copying the reference files) and no Windows job on CI.

In a project which supports Windows:

- mise runs inline scripts by `cmd /c` on Windows, which can't run `.cache/bin/hello`,
  so a task which runs a program has `run_windows = '.cache\bin\hello'`.
- Tasks needed to run and test scripts (`scripts:build`, `scripts:build:clean`, `scripts:test`)
  work in cmd too, with PowerShell in `run_windows` where POSIX sh is needed.
  Other tasks to develop scripts may need POSIX sh (e.g. Git Bash).
- Git returns paths with `/`, while arguments may use `\`:
  convert them by `filepath.ToSlash` before comparing.
- Tools of `mise.toml` may be unavailable on Windows,
  so CI on Windows installs only tools of scripts (`install_args` of `jdx/mise-action`)
  and sets `MISE_AUTO_INSTALL=false`, so `mise run` doesn't try to install others.

A program doesn't need mise,
so CI may build and test scripts by Go alone on platforms of the project without mise.
There `KONGUSAGE_TEST_SKIP_USAGE=1` makes the test of the spec skip the missing tool `usage`.

### Coverage of scripts

- It goes to its own file, `vars.scripts_cover = '.cache/scripts.cover.out'` in the root config.
  `vars.cover` of a Go project is taken by coverage of the project,
  and coverage of scripts must count neither in its total nor in its badge.
  `[vars]` can't be put into `scripts/tasks.toml`: mise rejects it in an included task file.
- Scripts use the shared `.cache/` of the project, never a second `.cache/` in `scripts/`,
  so task `cachedir` creates only `.cache`.
  Tasks run with `dir = 'scripts'`, so the path is `{{config_root}}/{{vars.scripts_cover}}`:
  `config_root` is the project root even in an included file.
- `scripts:cover` shows the full report:
  only CI needs the total alone, and CI doesn't measure scripts.
- Coverage tasks have no `sources`/`outputs`:
  they run only by hand, and the test cache of Go reuses results of `-coverprofile` runs
  more precisely, because it tracks files and environment variables the tests read.
