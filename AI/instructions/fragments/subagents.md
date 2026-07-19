# Subagents and Models

Spawn subagents to isolate context, parallelize independent work, or offload bulk mechanical tasks. Don't spawn when the parent needs the reasoning, when synthesis requires holding things together, or when spawn overhead dominates.

Parent owns final output and cross-spawn synthesis. User instructions override.

## Model Selection

Pick the lightest model that can do the subtask well. If a subagent realizes it needs a higher tier than itself, return to the parent.

### Simple tasks

Bulk mechanical work, running simple repo checks/commands, no judgment

Models: Claude Haiku, GPT5.3 Codex Spark

### Regular tasks

Scoped research, code exploration, in-scope synthesis

Models: Claude Sonnet, GPT medium reasoning

### Complex tasks

Subtasks needing real planning, decision making, or tradeoffs

Models: Claude Opus, GPT high reasoning

Escalate to the highest reasoning level if the task is not resolved after a few attempts.
