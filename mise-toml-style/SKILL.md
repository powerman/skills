---
name: mise-toml-style
description: 'Personal style of mise.toml and mise tasks — layout of the file, a task per step, when `run` is a string, an array of groups or `depends`, safe order of tasks which read and write the same files, sh instead of bash, `sources`/`outputs`, hidden tasks, and verified behaviour of mise which its docs miss. Use it whenever you create, edit, review or refactor mise.toml, a mise task file or an included task file (e.g. tasks.toml), add tools or tasks, combine tasks into fmt/lint/test/ci/default, or debug a task which runs twice, races, skips or sees an old tool — even if the user only says "add a task" or "why does mise do X".'
user-invocable: true
license: MIT
compatibility: Designed for Claude Code or similar AI coding agents, and for projects using mise.
metadata:
  author: powerman
  version: '0.1.0'
---

# mise.toml Style

These rules keep tasks fast, free of races and easy to read.
Facts about mise behind them were verified by experiments
and are collected in `references/mise-facts.md`:
read it before relying on an unusual behaviour of mise
or when a task behaves in an unexpected way.

Where scripts of a project live (inline, `mise/tasks/`, Go) is described by the
`project-scripts` skill.

## Layout of the file

1. `min_version` (with a comment when the reason isn't obvious).
2. `[settings]`, `[task_config]`.
3. `[tools]`: tools required to install tools (languages, package managers) first,
   then project's languages (e.g. go),
   then groups `#--- Generate`, `#--- Format`, `#--- Lint`, `#--- Test`, `#--- Release`, …;
   each tool has a one-line comment saying what it is (usually from GitHub repo description);
   a pinned version has a comment saying why (e.g. `# Version must match .golangci.yml.`).
4. `[env]`, `[vars]`.
5. Tasks in this order: `default`,
   root tasks (`bump`, `generate`, `fix`, `fmt`, `lint`, `test`, `ci`),
   their subtasks (`fmt:*`, `lint:*`, …) in the same order as root tasks,
   other tasks, hidden helpers (`cachedir`, …).

Sections are separated by two empty lines, tasks by one.

## Tasks

### A step is a task

A step has a name, `sources`, `dir`, `env`, a place in the graph of tasks,
and can be run alone, so it's a task, not an element of an array of commands.
A task which only root tasks run (e.g. `fmt:toml`) starts hidden (`hide = true`);
`hide` is removed when somebody starts to run it by hand.

A helper which must not clutter the output (e.g. a cleanup run before each build)
has `quiet = true`.

### `run`: a string, groups or `depends`

- **A leaf task has a single `run` string.**
  Several commands are lines of a multi-line string:
  `sh -o errexit` stops it at a failed command just like an array of commands does,
  while an array passes arguments only to its last element,
  keeps neither variables nor `cd` between elements and starts a shell for each.
- **An array in `run` belongs to a task which groups other tasks**
  (`{ task = … }`, `{ tasks = [...] }`), with rare shell commands not worth own tasks.
  Groups run one after another, tasks of one group run in parallel.
- **A grouping task without shell commands, whose tasks are safe to run in parallel,
  has `depends` instead of `run`** (e.g. `depends = ['lint:*']` of task `lint`).
- `{ task = … }` is the cheapest way to run tasks one after another.
- A nested `mise run` starts mise once more and costs about twice as much as `{ task = … }`,
  so it's used only when a step must see tools changed by an earlier step:
  `mise up` followed by a task which needs the upgraded tool.
  Tasks started by one mise process get the tools resolved at its start.
  Such a nested `mise run` gets a comment explaining it.
- A glob in `depends` must match at least one task, so an aggregator like `bump:*`
  belongs to the config which also defines its subtasks.

### Order of readers and writers

Tasks which read files must not run in parallel with tasks which write them.
A task which combines them sets a safe order by groups in `run`:

```toml
[tasks.default]
description = 'Run all formatters, linters and tests'
run = [{ task = 'fmt' }, { tasks = ['lint', 'test'] }]

[tasks.fmt]
description = 'Format all files'
# Configs of formatters are YAML and TOML files too,
# and a formatter must not read a config while it's being rewritten.
run = [{ task = 'fmt:yaml' }, { task = 'fmt:toml' }, { task = 'fmt:*' }]
```

Don't order readers and writers by `depends` with `wait_for`.
`wait_for` must name each writer of each reader,
and it's easy to miss a non-obvious pair and get a race
(e.g. `fmt:markdown` reading YAML configs, `go:embed` of formatted files),
while groups order whole stages.
Don't rely on `wait_for` next to groups either:
it works only between tasks of one group
and silently doesn't wait for a task of another group or under a nested `run`.

### Duplicate runs

mise runs a task once per graph, but each group of `run` is a graph of its own.
Within one `run` mise still skips a task which an earlier group has already run,
either listed there or reached by transitive `depends` of listed tasks.
So in `fmt` above `{ task = 'fmt:*' }` doesn't rerun `fmt:yaml` and `fmt:toml`:
a glob in a later group may safely match tasks of earlier groups,
and splitting tasks into ordered groups costs no extra runs.

A task reached by `depends_post` or by a nested `run` of another task isn't skipped
and may run twice, even concurrently with itself.
Accept it: every task must keep working when it's run alone,
and restructuring tasks only to avoid such a rerun usually breaks that.

### Shell

- Write commands in POSIX sh, not bash: mise runs inline scripts by `sh -o errexit -c`.
- A task which needs bash is too complex for TOML: it becomes a file in `mise/tasks/`.
  Don't get used to bash in tasks by `shell = 'bash -c'` or a shebang in `run`:
  it turns a one-line `run` into four lines and hides that the task outgrew TOML.
- errexit doesn't fire inside a condition of `if` or in `&&`/`||` chains,
  and a pipe has the exit status of its last command.
  sh on CI (dash) may lack `pipefail`, so a failure of the left side of a pipe
  must not go unnoticed: write the pipe so that the failure breaks a later step
  (e.g. an empty `-coverpkg=$(go list … | paste …)` fails `go test`),
  or don't pipe at all.

### `sources` and `outputs`

- Write them relative to `dir` of the task (e.g. `outputs = ['../.cache/bin/*']`
  of a task with `dir = 'scripts'`).
- Add `outputs` only when a task produces files:
  without them mise stores the state of `sources` by itself and skips the task as well.
- Use them for cheap skipping of builds and of idempotent checks
  (e.g. `lint:toml` with `sources = ['**/*.toml', 'mise.lock']`).
  List configs of the tool and `mise.lock` (with `lockfile = true`),
  so an upgrade of the tool reruns the check.
  Catching a few extra files is fine.
- Don't skip tests by `sources`: it's easy to forget an input and skip tests silently.
  Go has its own test cache which tracks files and environment variables read by tests.
- Hide "sources up-to-date, skipping" by `silent = 'stdout'`, not `silent = true`:
  `true` hides errors too.

### Consistency of related tasks

- A check (`lint:toml`) covers exactly the files its formatter (`fmt:toml`) formats:
  otherwise the check may fail in a way the formatter can't fix.
- A task in `mise.toml` silently shadows a file task with the same name in `mise/tasks/`.
  To replace a shared file task, change the file, don't add a task with its name.

## Included task files

`[task_config] includes` adds TOML files with tasks (e.g. `scripts/tasks.toml`).

- List `mise/tasks` in `includes` too:
  `includes` replaces the default directories of file tasks.
- Put variables shared with an included file into `[vars]` of the root config
  and use them there as `{{vars.x}}`: mise rejects `[vars]` in an included file.
  A variable of one task is set by per-task `vars.x = …`.
- Build project paths there from `{{config_root}}`: it's the project root
  even in an included file.
