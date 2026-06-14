# skills

A collection of [Agent Skills](https://agentskills.io).

Compatible with Claude Code, Cursor, Codex CLI, Gemini CLI, OpenCode, GitHub Copilot,
and any agent that supports the Agent Skills specification.

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

## Skills

| Skill                                                         | Description                                                                                                                   |
| ------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| [go-bounded-context-hexagonal](go-bounded-context-hexagonal/) | Bounded-Context Hexagonal Go application architecture — package layout, ports/adapters, wiring, and modular monolith patterns |
| [go-engineering-policy](go-engineering-policy/)               | Go engineering policies and coding conventions — constructors, variable scope, project structure, and style overrides         |
| [todo-plan](todo-plan/)                                       | Create a throwaway TODO working note for a multi-step task — agreed Plan + Progress checklist, ready to hand off to execution |
| [todo](todo/)                                                 | Resume a TODO working note (primary command) — no arg lists open notes to pick from, or pass a slug to continue               |
| [todo-done](todo-done/)                                       | Finish a TODO — verify its knowledge was extracted into docs/comments/commit, then delete the note                            |

## TODO workflow (`todo-plan` / `todo` / `todo-done`)

A lightweight, human-gated workflow for multi-step tasks.
The agent writes a short plan, you steer and review each step,
then the agent extracts durable knowledge before retiring the note.

Install all three skills as a set; individually they are not useful.

### What this is

- **Human-gated planning.** The agent proposes, you approve.
  Each step is meant to be reviewed before committing —
  not an autonomous vibe-coding run.
- **Throwaway working notes.** The plan is like the first message of a chat:
  it sets direction. Once execution starts the plan is immutable,
  but you can defer, split, cancel, or re-scope checklist items at any time.
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
