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

A lightweight, plan-then-execute workflow for multi-step tasks —
a much lighter alternative to full Spec-Driven Development frameworks.
Install all three skills as a set; individually they are not useful.
Notes are stored in `~/.todo/`, so the skills work with any agent that can run shell commands.

### Why

A strong model designs the task and writes a short plan;
a cheaper model (or a later session) executes it step by step;
the strong model later reviews the result and extracts anything worth keeping.
The plan is a **throwaway working note**, not a tracked project document:
it sets direction, like the first message of a chat.

### How it works

- Notes live in a dedicated git repository at `~/.todo/<project>/<slug>.md`,
  outside any project repo — so they never pollute commits, survive `git worktree`,
  and a task spanning several repositories keeps a single note.
- `<project>` is the worktree-stable repository id of the task's primary repo.
  The same task planned for several repositories gets one note per project,
  tracked independently.
- Each note has two sections with different rules:
  - `## Plan` — **immutable**: the agreed goal, rationale and boundaries.
  - `## Progress` — **mutable**: a checklist plus short notes for any deviation.
- The skills create the repo on first use and commit every change automatically,
  so you can `git -C ~/.todo log`/`diff` to review history.
  `/todo-done` deletes a note, but the deletion is committed, so it stays recoverable.

### Usage

```text
/todo-plan [<project>/]<slug>     # at the end of a planning discussion
/todo [[<project>/]<slug>]        # work the next step (no arg → pick interactively)
/todo-done [[<project>/]<slug>]   # extract knowledge, then retire (no arg → pick)
```

Pass a `<project>/` prefix to act on a note owned by another repository while you
work inside the current one — the intended way to handle cross-repository tasks.

### Recommended `CLAUDE.md` snippet

The skills are self-contained, but adding this to your user-level `CLAUDE.md`
(or `AGENTS.md`) makes the agent respect the notes even when it opens one without
going through a skill:

```markdown
## TODO working notes

Working notes for multi-step tasks live in `~/.todo/<project>/<slug>.md`,
managed by the `/todo-plan`, `/todo` and `/todo-done` skills.

- `~/.todo/` is its own git repository; the skills commit every change.
  Never commit notes into a project repo or reference them in commits/PRs/code.
- `## Plan` is immutable — once execution starts, NEVER rewrite it.
- `## Progress` is the only mutable part — tick the checklist and append short
  notes for deviations.
- Treat a TODO like the first message of a chat, not a living document.
```
