---
name: todo-done
description: Finish a TODO — review the resulting change against the Plan, verify its durable knowledge (Plan rationale, Progress deviations) was moved into docs, code comments, or the commit/PR, then delete the working note. With no argument it lists open notes (most-recently-modified first) and asks which to retire.
user-invocable: true
license: MIT
compatibility: Designed for any AI coding agent with shell access; removes notes from a self-managed git repo under ~/.todo/.
metadata:
  author: powerman
  version: '0.2.0'
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
   - `## Progress` — deviations from the original plan,
     and any checklist items left unchecked (deferred or cut).

   For each such item, confirm it already lives in the right place
   (documentation, code comments, the commit/PR message, or another TODO).
   List anything not yet captured and extract it now,
   or confirm with the user that it can be dropped.

   Unfinished checklist items are durable value too: when leftover work still matters,
   spin it out as its own TODO with `/todo-plan` rather than letting it vanish with the note.

3. Do not stop at "every checklist box is ticked" —
   that only confirms the executor believes it's done,
   and retirement sessions tend to run on a stronger model than execution sessions,
   the same gap `/todo-plan` accounts for.
   Actually review the resulting change against the `## Plan`:
   - read the real diff (`git diff` / `git log -p` for the relevant commits),
     not just the note's checklist;
   - check it matches the Plan's goal, boundaries, and approach,
     and flags any silent deviation not recorded under `## Progress`;
   - look for correctness issues an executor could plausibly have introduced
     (wrong edge-case handling, skipped error paths,
     signatures that drifted from what the Plan specified);
   - confirm format/lint/test actions required by the project were actually run and pass,
     not merely assumed.

   If review surfaces a real problem send it back to the user
   instead of retiring the note as if it were done.

4. Once nothing valuable remains only in the note and review found no open problem,
   delete it and commit the removal:

   ```
   rm ~/.todo/<project>/<slug>.md
   rmdir ~/.todo/<project> 2>/dev/null || true
   git -C ~/.todo add -A
   git -C ~/.todo diff --cached --quiet ||
       git -C ~/.todo commit -q -m "done: <project>/<slug>"
   ```

5. Confirm what was extracted (and where), what the review checked,
   and that the note was removed.
