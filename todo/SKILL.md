---
name: todo
description: Resume work on a TODO working note — the primary, frequent command. With no argument it lists open notes (most-recently-modified first) and asks which to resume; with a slug it opens that note and continues from the next unchecked Progress step under the working-note discipline.
user-invocable: true
license: MIT
compatibility: Designed for any AI coding agent with shell access; reads notes from a self-managed git repo under ~/.todo/.
metadata:
  author: powerman
  version: '0.1.0'
---

# /todo

Resume execution of a task from its working note.
This is the command you run most often, so it has the short name.

## Arguments

`/todo [[<project>/]<slug>] [extra instructions]`

- No argument — discover the open notes and ask which to resume (see step 2).
- `<slug>` — resume that note in the current project.
- `<project>/<slug>` — resume a note owned by another repository while you are
  working inside the current one. This is the intended way to handle a task whose
  changes span several repositories.
- Any free-form text after the slug is additional instruction for this step
  (a refinement, a constraint, where to focus) — follow it.

## Steps

1. Resolve the project id (worktree-stable — the same value from any worktree):

   ```sh
   git rev-parse --git-common-dir >/dev/null 2>&1 &&
       basename "$(dirname "$(cd "$(git rev-parse --git-common-dir)" && pwd)")"
   ```

2. Resolve the target note:
   - If a slug was given, use `~/.todo/<project>/<slug>.md`
     (a `<project>/` prefix overrides the current project).
   - If no slug was given, list the open notes, most-recently-modified first:

     ```
     ls -t ~/.todo/<project>/*.md 2>/dev/null # current project
     ls -t ~/.todo/*/*.md 2>/dev/null         # all projects, if the above is empty
     ```

     Ask which to resume using your interactive multiple-choice tool
     (e.g. `AskUserQuestion` in Claude Code), offering the most-recently-modified
     notes first — up to the tool's option limit; its free-text / "Other" choice
     covers the rest. If you have no such tool, print the list and ask.

3. Read the note. Load `## Plan` as immutable context and `## Progress` as state.

4. Work the unchecked `- [ ]` items in `## Progress`, in order, continuing as far
   as you can this session — `/todo` resumes the task, it does not stop after one
   item unless something blocks you. For each item you complete:
   - tick it off;
   - if you departed from the Plan, append a short deviation note under
     `## Progress` — do NOT edit `## Plan`.

   Treat the note as direction, not a document to keep in sync as prose.

5. Commit the updated note to the notes repository.
   This is separate from any commits in the project you are working on —
   it only records the note's progress:

   ```sh
   git -C ~/.todo add -A
   git -C ~/.todo diff --cached --quiet ||
       git -C ~/.todo commit -q -m "progress: <project>/<slug>"
   ```

6. When all items are done, suggest `/todo-done <project>/<slug>`.
