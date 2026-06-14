---
name: todo-plan
description: Create a throwaway TODO working note for a multi-step task — capture the agreed Plan and an empty Progress checklist under ~/.todo/<project>/<slug>.md. Use at the end of a planning discussion, before handing execution to another session or model.
user-invocable: true
license: MIT
compatibility: Designed for any AI coding agent with shell access; stores notes in a self-managed git repo under ~/.todo/.
metadata:
  author: powerman
  version: '0.1.0'
---

# /todo-plan

Capture the just-agreed plan for a task as a personal, throwaway working note.
The note is the hand-off artifact for `/todo` (execution)
and `/todo-done` (retirement).
It is never committed to the project repository
and never referenced in commits, PRs, or code.

## Arguments

`/todo-plan [<project>/]<slug> [extra instructions]`

- `<slug>` — kebab-case task name (e.g. `upgrade-go`). Required.
- `<project>/` — optional. Defaults to the current repository (see step 1).
  Pass it explicitly to plan a task for a different repository.
- Any free-form text after the slug is additional instruction for this invocation
  (a title, or a refinement to the agreed plan) — incorporate it into the note.

## Steps

1. Resolve the project id (worktree-stable — the same value from any worktree):

   ```sh
   git rev-parse --git-common-dir >/dev/null 2>&1 &&
       basename "$(dirname "$(cd "$(git rev-parse --git-common-dir)" && pwd)")"
   ```

   If the argument already contains a `<project>/` prefix, use that instead.
   If not inside a git repository and no `<project>/` was given, ask the user.

2. Ensure the notes store exists as its own git repository,
   then create the project directory:

   ```sh
   mkdir -p ~/.todo
   # Test for ~/.todo/.git directly rather than `git rev-parse`:
   # the latter also succeeds when ~/.todo sits inside an unrelated parent
   # repository (e.g. a versioned $HOME), which would silently route every
   # note commit into that repo instead of giving the notes their own.
   [ -d ~/.todo/.git ] || git -C ~/.todo init -q
   mkdir -p ~/.todo/<project>
   ```

3. If `~/.todo/<project>/<slug>.md` already exists, STOP — do not overwrite.
   Tell the user to use `/todo <project>/<slug>` or another slug instead.

4. Write the file from the template below.
   Fill `## Plan` from the design agreed in the current conversation
   (goal, rationale, boundaries, approach).
   Seed `## Progress` with a checklist derived from the plan's steps:

   ```markdown
   # <Task title>

   ## Plan

   <!-- Immutable. Goal / Why / Boundaries / Approach.
        Do NOT rewrite once execution starts. -->

   ## Progress

   <!-- Mutable. Tick items; append short notes for deviations from the Plan. -->

   - [ ] <first step>
   - [ ] <second step>
   ```

5. Commit the new note to the notes repository:

   ```sh
   git -C ~/.todo add -A
   git -C ~/.todo diff --cached --quiet ||
       git -C ~/.todo commit -q -m "plan: <project>/<slug>"
   ```

6. Report the path and remind the user this is a personal note:
   not committed to the project, never referenced in commits/PRs/code.
