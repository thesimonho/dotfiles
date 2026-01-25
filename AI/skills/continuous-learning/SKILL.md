---
name: continuous-learning
description: Automatically extract reusable patterns from Claude Code sessions and save them as learned skills for future use.
---

# Continuous Learning Skill

Automatically evaluates Claude Code sessions on end to extract reusable patterns that can be saved as learned skills.

## How It Works

This skill runs as a **Stop hook** at the end of each session:

1. **Session Evaluation**: Checks if session has enough messages (default: 10+)
2. **Pattern Detection**: Identifies extractable patterns from the session
3. **Skill Extraction**: Saves useful patterns to `~/.claude/skills/learned/`

## Pattern Types

| Pattern                | Description                           |
| ---------------------- | ------------------------------------- |
| `error_resolution`     | How specific errors were resolved     |
| `user_corrections`     | Patterns from user corrections        |
| `workarounds`          | Solutions to framework/library quirks |
| `debugging_techniques` | Effective debugging approaches        |
| `project_specific`     | Project-specific conventions          |

## Why Stop Hook?

- **Lightweight**: Runs once at session end
- **Non-blocking**: Doesn't add latency to every message
- **Complete context**: Has access to full session transcript
