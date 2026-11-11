# General rules for the project

## Project Context (Reference)

A collection of Agent Skills.

## Mandatory Rules

### Contribution Requirements

- Write code comments and documentation in English.
- Documentation describes the current state of the project,
  not the history of its changes or code which no longer exists.
- When a check fails, fix the cause, whether it is in the code or in the test itself.
  Suppress a linter warning only when it is a false positive,
  ignores the specifics of the current implementation,
  or its fix would make the code worse;
  suppress it narrowly (a specific rule at a specific place) and state the reason next to it.
  When the cause cannot be fixed within the task,
  report it instead of skipping the test or silencing the linter.
