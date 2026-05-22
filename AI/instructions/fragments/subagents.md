# Subagents

Spawn subagents to isolate context, parallelize independent work, or offload bulk mechanical tasks. Don't spawn when the parent needs the reasoning, when synthesis requires holding things together, or when spawn overhead dominates.

Parent owns final output and cross-spawn synthesis. User instructions override.

## Model Selection

Pick the cheapest model that can do the subtask well. If a subagent realizes it needs a higher tier than itself, return to the parent.

### Simple tasks

Bulk mechanical work, no judgment

Models: Claude Haiku, GPT5.3 Codex Spark

### Regular tasks

Scoped research, code exploration, in-scope synthesis

Models: Claude Sonnet, GPT5.5 medium reasoning

### Complex tasks

Subtasks needing real planning, decision making, or tradeoffs

Models: Claude Opus, GPT5.5 high reasoning

Escalate to the highest reasoning level if the task is not resolved after a few attempts.
