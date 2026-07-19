# Agent configuration eval harness

This harness measures whether changes to global Codex or Claude configuration improve agent behavior. It runs git-tracked evaluation cases through the selected authenticated CLI and records scores, traces, configuration provenance, prompt versions, and manifest-derived Agent Versions in a local MLflow 3.14.0 server.

Git commits and working-tree state are not configuration identity. Before an evaluation begins, the runner publishes every monitored file as an independently versioned MLflow prompt and publishes a manifest containing the complete component set. Uncommitted instruction edits therefore have durable, inspectable provenance without requiring a commit.

## Monitored configuration

Only direct Markdown children of these directories are monitored:

- `AI/instructions/fragments/*.md` becomes `instruction/<filename-stem>`.
- `AI/agents/*.md` becomes `agent/<filename-stem>`.

Nested and generated files, including `AI/agents/.generated/**`, are excluded. Symlinks are rejected so a run cannot publish content from outside the allowlisted directories.

Each component is a prompt family in the `agent-harness--*` namespace. Content is reused by hash, including historical versions, so reverting a file reuses its original prompt version. Adding or removing a file changes the complete manifest set without deleting historical prompt versions.

Component prompt families are shared by Codex and Claude because the monitored source files are shared. Manifests remain profile-specific:

- `agent-harness--codex--manifest`
- `agent-harness--claude--manifest`

The profile is part of manifest identity, and each CLI needs an independent `last-evaluated` baseline. Every manifest lists the active component IDs, hashes, source paths, prompt names, and prompt versions.

MLflow creates or reuses one Agent Version for each `(agent CLI, manifest hash)` pair. The full manifest hash is authoritative identity; a readable name such as `codex-20260719-6a4f8383` is only a display label. Git metadata may be recorded automatically by MLflow, but it is not used for configuration identity.

## Evaluation cases

[`cases.py`](cases.py) is the git-tracked source of truth for real evaluation cases. No cases are configured yet. Until real cases are added, the runner exits with `no evaluation cases configured` before initializing MLflow or publishing any resource.

## Running the harness

The local [`justfile`](justfile) contains the supported workflow:

```bash
cd AI/evals

# Create the isolated Python environment.
just eval-setup

# Start the loopback-only MLflow server and wait until it answers.
just eval-up

# Run with this month's authenticated CLI.
just eval-run codex

# Equivalent direct runner, with an optional explicit baseline.
just eval-mlflow --agent codex
just eval-mlflow --agent codex --baseline-manifest-version 3

# Inspect services or follow logs.
just eval-status
just eval-logs

# Stop MLflow while retaining its local data.
just eval-down

# Run project checks.
just eval-verify
```

Use `claude` instead of `codex` during a Claude month. `--agent auto` works only when exactly one supported CLI is installed. Both subprocesses run from the repository root so root-level instructions and trusted project configuration are discovered consistently. MLflow environment variables are removed from the subprocess environment, and each CLI call has a 30-minute timeout. Codex is explicitly launched with a read-only sandbox; Claude uses the effective permissions from the user's Claude configuration because the two CLIs do not expose an equivalent execution-policy interface.

The local resource identities are:

- Tracking URI: `http://localhost:5000`
- Experiment: `agent-harness-evals`
- Dataset: `agent-harness-cases`
- Prompt namespace: `agent-harness--*`

The Compose service binds port 5000 to loopback and persists the SQLite database and artifacts under the ignored `infra/compose/data/mlflow` directory. The server image and Python dependency are both pinned to MLflow 3.14.0.

## Inspecting results

Open <http://127.0.0.1:5000> and select **Evaluation runs** to compare aggregate metrics and individual request rows. The current scorer records `tiered_score` for every case and `tiered_score/mean` for the run.

Open the underlying run for complete provenance:

- **Overview → Description** shows the comparison changes and active component references.
- **Overview → Parameters** shows the complete component-to-prompt-version map and `agent.cli`.
- **Overview → About this run** shows linked manifest and component prompts.
- **Artifacts → configuration** contains `manifest.json` and `changes.txt`.

The run name includes the first relevant transition, such as `codex-manifest-v2 - workflow v1 -> v2`. Every successful run and request trace links the manifest and all active component prompt versions. Trace request and response previews contain plain text instead of serialized JSON wrappers.

Open **Agent versions** to inspect a complete manifest-backed configuration identity. Its Overview description lists the manifest and active component versions, and its `configuration/manifest.json` artifact preserves the complete immutable manifest. Baseline-relative changes belong to evaluation runs, so reusing an Agent Version never overwrites its evidence with a different run's comparison context.

Use these filters:

- Evaluation Runs: ``params.`agent.cli` = 'codex'``
- Trace UI: **Filters → Field → `agent.cli`**
- Trace API: ``metadata.`agent.cli` = 'codex'``

`agent.cli` is the only CLI query key. Agent Versions and Evaluation Runs store it as a parameter; traces store it as immutable metadata. The harness deliberately emits no duplicate CLI tags.

Independent single-turn cases do not belong under **Sessions**. If conversational cases are added later, assign one session ID per simulated conversation rather than one for the complete evaluation run.

## Baselines and diffs

The default comparison baseline is the manifest from the latest successfully attached evaluation, recorded with the profile manifest's `last-evaluated` alias. Publishing prompts for a failed or interrupted evaluation does not advance it. `--baseline-manifest-version VERSION` selects an explicit manifest version.

The change note classifies added, removed, and modified components and includes old and new prompt versions. To inspect exact text changes, open the changed component under Linked Prompts and compare its two prompt versions in the MLflow prompt UI.

## Layout

- `cases.py` defines real evaluation inputs and expectations.
- `run_mlflow_eval.py` publishes provenance, resolves an Agent Version, synchronizes the dataset, and runs evaluation.
- `lib/agent.py` invokes the authenticated Codex or Claude CLI from the repository root.
- `lib/configuration_components.py` discovers allowlisted configuration atoms.
- `lib/configuration_manifest.py` builds complete manifests and baseline comparisons.
- `lib/mlflow_config_registry.py` publishes and links prompts, run evidence, and trace provenance.
- `lib/mlflow_agent_versions.py` resolves manifest-derived Agent Versions.
- `lib/mlflow_configuration_evidence.py` renders shared run and Agent Version descriptions and artifacts.
- `infra/compose/mlflow.yml` runs the pinned local MLflow server.
