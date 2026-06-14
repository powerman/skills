---
name: todo-done
description: Finish a TODO — verify its durable knowledge (Plan rationale, Progress deviations) was moved into docs, code comments, or the commit/PR, then delete the working note. With no argument it lists open notes (most-recently-modified first) and asks which to retire.
user-invocable: true
license: MIT
compatibility: Designed for any AI coding agent with shell access; removes notes from a self-managed git repo under ~/.todo/.
metadata:
  author: powerman
  version: '0.1.0'
---

# /todo-done

Retire a finished working note after salvaging anything worth keeping.
The deletion is committed, so the note stays recoverable from the notes repo's git history.

## Arguments

`/todo-done [[<project>/]<slug>] [extra instructions]`

- No argument — discover the open notes and ask which to retire (see step 1).
- `<slug>` / `<project>/<slug>` — resolved exactly like `/todo`.
- Any free-form text after the slug is additional instruction for retirement
  (e.g. where to extract a specific piece of knowledge) — follow it.

## Steps

1. Resolve the target note (project id and selection work exactly as in `/todo`).
   If no slug was given, list the open notes most-recently-modified first
   (`ls -t ~/.todo/<project>/*.md`, falling back to `ls -t ~/.todo/*/*.md`) and ask
   which to retire via your interactive multiple-choice tool (e.g. `AskUserQuestion`),
   most-recent first; if you have no such tool, print the list and ask.

2. Read `~/.todo/<project>/<slug>.md` and review it for durable value that must
   outlive the note:
   - `## Plan` — rationale, trade-offs, boundaries;
   - `## Progress` — deviations from the original plan.

   For each such item, confirm it already lives in the right place
   (documentation, code comments, the commit/PR message, or another TODO).
   List anything not yet captured and extract it now,
   or confirm with the user that it can be dropped.

3. Once nothing valuable remains only in the note, delete it and commit the removal:

   ```
   rm ~/.todo/<project>/<slug>.md
   rmdir ~/.todo/<project> 2>/dev/null || true
   git -C ~/.todo add -A
   git -C ~/.todo diff --cached --quiet ||
       git -C ~/.todo commit -q -m "done: <project>/<slug>"
   ```

4. Confirm what was extracted (and where) and that the note was removed.
