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
