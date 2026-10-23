---
agent:
  instruction: Preserve sequential service startup and project-root working directories.
  on-change: ["AI/evals/mise-tasks/**", "AI/evals/mise.toml"]
---

# Evaluation tasks

Run `mise -C AI/evals tasks` from the repository root. These executable Zsh tasks run from the repository root, load its optional `.env` through the eval mise configuration, and preserve the evaluation harness's isolated Python environment. Setup installs the HomeOps dependencies before the Python harness; service startup waits for MLflow before creating the experiment and starting Alloy.

The local mise Just pin supports the HomeOps fixture and its Just-usage assessments. Operational harness tasks use mise; the fixture remains an independent test subject. Task discovery and campaign previews do not invoke an agent or start services.
