# skills

A collection of [Agent Skills](https://agentskills.io).

Compatible with Claude Code, Cursor, Codex CLI, Gemini CLI, OpenCode, GitHub Copilot,
and any agent that supports the Agent Skills specification.

## Skills

| Skill                                                         | Description                                                                                                                   |
| ------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| [go-bounded-context-hexagonal](go-bounded-context-hexagonal/) | Bounded-Context Hexagonal Go application architecture — package layout, ports/adapters, wiring, and modular monolith patterns |
| [go-engineering-policy](go-engineering-policy/)               | Go engineering policies and coding conventions — constructors, variable scope, project structure, and style overrides         |
| [todo-plan](todo-plan/)                                       | Create a throwaway TODO working note for a multi-step task — agreed Plan + Progress checklist, ready to hand off to execution |
| [todo](todo/)                                                 | Resume a TODO working note (primary command) — no arg lists open notes to pick from, or pass a slug to continue               |
| [todo-done](todo-done/)                                       | Finish a TODO — verify its knowledge was extracted into docs/comments/commit, then delete the note                            |

## Installation

### Universal (recommended)

Works with any supported agent:

```shell
# Install all skills
npx skills add powerman/skills --all

# Install a specific skill
npx skills add powerman/skills --skill go-bounded-context-hexagonal
npx skills add powerman/skills --skill go-engineering-policy

# Install to specific agents
npx skills add powerman/skills --skill go-bounded-context-hexagonal -a claude-code -a cursor
```

### Claude Code — Plugin Marketplace (granular install)

```shell
/plugin marketplace add powerman/skills
/plugin install go-bounded-context-hexagonal@powerman/skills
/plugin install go-engineering-policy@powerman/skills
```

### Project-level auto-setup

Add to `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "powerman/skills": {
      "source": {
        "source": "github",
        "repo": "powerman/skills"
      }
    }
  },
  "enabledPlugins": {
    "go-bounded-context-hexagonal@powerman/skills": true,
    "go-engineering-policy@powerman/skills": true
  }
}
```

### Manual (any agent)

Clone the repo and symlink or copy skill directories to your agent's skills path:

```shell
git clone https://github.com/powerman/skills.git

# Claude Code
ln -s "$PWD/skills/go-bounded-context-hexagonal" ~/.claude/skills/

# Cursor
ln -s "$PWD/skills/go-bounded-context-hexagonal" ~/.cursor/skills/

# OpenCode / Codex CLI
ln -s "$PWD/skills/go-bounded-context-hexagonal" .agents/skills/
```

## TODO workflow (`todo-plan` / `todo` / `todo-done`)

A lightweight, human-gated workflow for multi-step tasks.
The agent writes a short plan, you steer and review each step,
then the agent extracts durable knowledge before retiring the note.

Install all three skills as a set; individually they are not useful.

### What this is

- **Human-gated planning.** The agent proposes, you approve.
  Each step is meant to be reviewed before committing —
  not an autonomous vibe-coding run.
- **Throwaway working notes.** The plan is like the first message of a chat: it sets direction.
  Once execution starts the Plan is fixed — not because requirements can't change,
  but so the gap between original intent and what actually happened stays visible
  (deviations go into `## Progress`, never by rewriting the Plan — a thing models love to do).
  You can still defer, split, cancel, or re-scope checklist items;
  if the Plan itself is no longer the task,
  retire the note and re-plan rather than rewrite it.
  The note gets deleted when done (after extracting what's worth keeping).
- **Agent-independent.** Notes live in `~/.todo/<project>/` as plain Markdown
  in their own git repo, so they work with any agent that can run shell commands.

### What this is not

- Not an autonomous execution system — there is no completion gate
  that forces the agent to finish everything before stopping.
  **The gate is you.**
- Not Spec-Driven Development — no formal specs, no acceptance criteria,
  no long-lived specification files synced with code.
- Not a project management tool — no dependencies, no assignees, no board.
  It's a scratchpad for one task at a time.

### How it compares

Several tools sit in nearby niches.
The choice between them is mostly about two things:
how long the artifact lives, and who is expected to drive.

- **In-session todo lists** — the agent's own checklist
  (Claude Code's `TodoWrite`, the plan mode in Cursor or Codex).
  These keep a single task in focus but live only inside the session:
  they don't survive a context compaction, a restart, or a model switch,
  and there is no saved plan to review or hand off.
  This workflow is that same single-task focus promoted to a file —
  made persistent, reviewable, and resumable by any agent.

- **[ai-dev-tasks](https://github.com/snarktank/ai-dev-tasks)**
  (PRD → task list → one sub-task at a time, human-approved)
  is the closest match in spirit,
  and a good fit if you want the plan to stay a living document inside the repo.
  The difference is _lifecycle_: its PRD and `tasks-*.md` live in the project and
  persist, the plan keeps being edited, and nothing is distilled at the end.
  Here the note lives outside the project, the Plan is frozen once execution starts,
  and `/todo-done` forces durable knowledge out into docs/comments/commit
  before deleting the scaffolding.

- **Project-memory docs** (Cline Memory Bank and similar) solve the opposite problem:
  long-lived context about the _whole project_, committed _inside_ the repo.
  Reach for those when you want the agent to remember the project across tasks;
  reach for this when you want to carry _one_ task across sessions
  and then throw the scaffolding away.

- **Spec-Driven Development** (Spec Kit, OpenSpec, Kiro, BMAD) and **task systems** (Task Master)
  add formal specs or dependency graphs, sub-task expansion, and multi-agent roles.
  They earn their weight on large or team projects and are overhead for a single focused change.
  When a note starts wanting acceptance criteria or task dependencies,
  that is the signal to graduate to one of them.

### How it works

- `/todo-plan` creates `~/.todo/<project>/<slug>.md` with immutable `## Plan`
  and mutable `## Progress` (checklist + deviation notes).
- `/todo` resumes a note and works unchecked items in order.
  The agent writes code; you review and commit before the next step.
- `/todo-done` reads the note for knowledge worth keeping
  (rationale, trade-offs, deviations), extracts it into docs/comments/commit,
  then deletes the note — deletion is committed, so it stays recoverable.
- Everything is auto-committed to `~/.todo/`'s own git repo,
  never touching the project's history.

### Usage

```text
/todo-plan [<project>/]<slug>     # at the end of a planning discussion
/todo [[<project>/]<slug>]        # work the next step (no arg → pick interactively)
/todo-done [[<project>/]<slug>]   # extract knowledge, then retire (no arg → pick)
```

Prefix with `<project>/` to work on a note owned by another repository
while you are inside the current one — for cross-repository tasks.

### Recommended `CLAUDE.md` snippet

The skills are self-contained, but adding this to your user-level `CLAUDE.md`
(or `AGENTS.md`) makes the agent respect the notes
even when it opens one without going through a skill:

```markdown
## TODO working notes

Working notes for multi-step tasks live in `~/.todo/<project>/<slug>.md`,
managed by the `/todo-plan`, `/todo` and `/todo-done` skills.

- `~/.todo/` is its own git repository; the skills commit every change.
  Never commit notes into a project repo or reference them in commits/PRs/code.
- `## Plan` is immutable — once execution starts, NEVER rewrite it.
- `## Progress` is the only mutable part — tick the checklist
  and append short notes for deviations.
- Treat a TODO like the first message of a chat, not a living document.
```
