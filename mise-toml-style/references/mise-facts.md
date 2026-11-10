# Verified behaviour of mise tasks

Verified by experiments on toy configs with mise 2026.10.19–2026.10.25 (October–November 2026).
Most of it is missing from the docs of mise.
Re-check a fact after a big upgrade of mise before building on it.
Rules of `SKILL.md` rely on these facts:
when a re-check changes a fact, update the rules which rely on it.

When you test a fact yourself, use a fresh directory for each run:
re-running a toy in the same directory within a second gave inconsistent results.

## Contents

- Groups in `run`
- Duplicate runs
- `wait_for`
- Globs
- Shell and `run`
- Arguments
- Tools during a run
- `sources` and `outputs`
- File tasks
- Included task files
- Output
- Costs

## Groups in `run`

- `run = [{ task = … }, { tasks = [...] }]`:
  groups run one by one, tasks of a group in parallel.
- A failure kills parallel siblings, later groups don't run, the exit status is kept.
- A glob works in both `{ task = 'fmt:*' }` and `{ tasks = ['fmt:*'] }`, with no difference.
- A failed group, `--force`, `-j1`, `-j2` and skipping by `sources` work, no deadlocks.
- A cycle through `run` hangs without a message.
- `mise tasks deps` shows no tree for `run`; `mise run --dry-run` shows steps.

## Duplicate runs

- A task isn't repeated if an earlier group of the same `run` lists it
  or has it in transitive `depends` of listed tasks.
  It works for `depends` of tasks in a later group too
  (`[{ task = 'test:go' }, { task = 'test' }]` with `test` depending on `test:*`),
  and for `depends` of the task which owns this `run`.
- Not covered, so the task runs twice: `depends_post` and nested `run` of these tasks.
- Parallel branches of one group, when at least one has `run`,
  also run a shared leaf twice with overlap
  (e.g. a leaf of `fmt:*` whose `run` starts `fmt:yaml` runs it twice at once).

## `wait_for`

- It works only inside of one graph, and each group of `run` has its own graph.
  Inside of one group it works, also between `depends` of different tasks.
- From the first group to a later group it doesn't wait, without an error;
  a task under nested `run` doesn't wait in either direction.
  `--dry-run`, `-vv` and `mise tasks validate` show nothing;
  only `mise tasks deps` lacks the edge.
- A name which is in the config but not in the current run: no wait, no error.
  A name matching no task in the config: `task not found`, also for globs.

## Globs

- `*` doesn't cross `:`, `**` does; `lint:**` matches neither `lint` nor `lint-z:y`.
- `'test:[!g]*'` and `'test:{x,y}'` work for exclusion, `!test:go` doesn't.
- A glob in `depends` which matches no task fails with `task not found`.

## Shell and `run`

- The default inline shell is `sh -o errexit -c`,
  for an array element and for a multi-line string alike.
- A multi-line string stops at a failed line.
  Its echo `[task] $ …` shows only the first line.
- Array elements are separate processes: no shared variables or `cd`.
  Each element is echoed as `[task] $ cmd`.
- A multi-line string starting with `#!/usr/bin/env bash` runs by bash, and `pipefail` works.
- Each command of `run` starts the program by `exec`,
  so mise forwards Ctrl-C to the program and passes on its exit status.

## Arguments

- Arguments (`raw_args` or a usage spec) are appended only to the last element of an array.
- With `raw_args`, mise removes `--` after the task name,
  so a first argument starting with `-` needs `mise run <task> -- -- -x`.
- A `{ task = 'x', args = [...] }` step in `run` works.

## Tools during a run

- Tasks started by one mise process (`depends`, `{ task = … }`) get the tools
  resolved when this process started.
  After a step changes tools (`mise up`, an edit of `[tools]`),
  only a nested `mise run` sees the new versions.

## `sources` and `outputs`

- Both are relative to `dir` of the task.
- mise records the set of sources with sizes and mtimes,
  so an in-place edit, a new file, a deleted file and a revert to an older mtime (`cp -p`)
  all rerun the task.
- Without `outputs`, mise keeps the state of sources by itself and skips the task
  until they change.
- `outputs = ['dir/*']`: deleting the whole directory reruns, deleting one of its files doesn't.
- Any edit of the config file which defines the task reruns it, even of an unrelated comment.
- An absolute path in `outputs` (e.g. `{{config_root}}/…`) works,
  also one from a variable of `[env]` (`{{env.X}}/*`) in an included task file.
- `silent = "stdout"` hides "sources up-to-date, skipping" and keeps compile errors;
  `silent = true` hides compile errors too.
- 6 parallel `mise run` after a change of sources all got the new build.

## File tasks

- A task in `mise.toml` shadows a file task with the same name in `mise/tasks/`
  without a warning: `mise run` starts the TOML task, and `mise tasks ls` lists the name once.

## Included task files

- In a file of `task_config.includes`, `{{vars.*}}` of the root config work
  and `{{config_root}}` is the project root.
- `[vars]` there is a parse error; per-task `vars.x = …` works.
- `includes` replaces the default directories of file tasks.

## Output

- A top-level run of one task with groups has no prefixes on the output of leaves.
- `depends` with 2+ leaves gives prefixes like `[lint:a] …`.
- The exit status of a failed task is the exit status of `mise run`.
  mise also prints `[<task>] ERROR task failed` to stderr on any non-zero status;
  `-q`, `-S` and `MISE_SILENT` don't hide it.

## Costs

Each task mise runs costs tens of milliseconds:
mise resolves tools and env once more for it, without starting processes.
The cost grows with the number of tools, global tools of the developer included,
so numbers below differ between machines.

- Each task in the graph (`depends`, `{ task = … }`) costs about 20–30 ms,
  even a build task which is skipped by `sources`.
- A nested `mise run -q x` inside a task, where `x` depends on such a build task
  and starts a prebuilt program, costs about 100 ms per call;
  starting the program directly costs about 3 ms.
- `MISE_OFFLINE`, `MISE_PREFER_OFFLINE` and `task.run_auto_install = false` don't change it.
