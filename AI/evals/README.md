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

Every case has a stable `case_id`, a filterable `category`, a `metric_name`, and the prompt sent to the agent. Tier-specific expectations are:

- `output-quality` supplies a natural-language `rubric` to the selected CLI judge.
- `output-contains` supplies an `expected_mention` for a deterministic final-response check.

`output-contains` deliberately describes only response text. Tool calls, hooks, and intermediate steps are exported separately by the agent CLIs as OpenTelemetry traces.

## Agent telemetry flow

Codex and Claude send OTLP/gRPC to the dedicated loopback receiver at `127.0.0.1:4327`. Alloy keeps only traces whose resource attributes include `telemetry.purpose=evaluation`, removes known account and authorization attributes, batches them, and exports them to the same MLflow experiment used by the eval harness. Logs and metrics have no configured Alloy output and are dropped. Traces from ordinary interactive agent use that lack the evaluation marker are also dropped for now.

```text
eval runner -> Codex or Claude -> OTLP :4327 -> Alloy -> MLflow /v1/traces
normal use -> Codex or Claude -> OTLP :4327 -> Alloy -> drop
```

The separate port identifies agent traffic at ingress, but it is not the security or routing boundary. The immutable `telemetry.purpose=evaluation` resource attribute is what authorizes a trace for MLflow. Every eval process also receives `agent.cli`, `case_id`, `category`, and `evaluation.role`, allowing agent-under-test and judge traces to be distinguished without putting prompt or response text in resource attributes.

Each harness invocation generates one UUID as `evaluation.execution_id` and assigns it to every agent-under-test and judge CLI process in that invocation. This distinguishes repeated evaluations of the same case: `evaluation.execution_id` selects the run, `case_id` selects the case, and `evaluation.role` distinguishes the agent response from its judge. Every process also receives `config.manifest_id`, which identifies the exact profile-specific configuration manifest evaluated by that invocation.

MLflow trace storage should be treated as sensitive. Redaction is defense in depth for known identity fields, not a guarantee that span attributes or events contain no private content. Alloy's verbose debug exporter is intentionally absent because it would duplicate telemetry into container logs.

## Running the harness

The local [`justfile`](justfile) contains the supported workflow:

```bash
cd AI/evals

# Create the isolated Python environment.
just eval-setup

# Start loopback-only MLflow and Alloy, then wait until both answer.
just eval-up

# Run with this month's authenticated CLI.
just eval-run codex

# Equivalent direct runner, with an optional explicit baseline.
just eval-mlflow --agent codex
just eval-mlflow --agent codex --baseline-manifest-version 3

# Send the evaluation to a remote MLflow server.
MLFLOW_TRACKING_URI=https://mlflow.example.com just eval-run codex

# Inspect services or follow logs.
just eval-status
just eval-logs

# Stop MLflow while retaining its local data.
just eval-down

# Run project checks.
just eval-verify
```

Use `claude` instead of `codex` during a Claude month. `--agent auto` works only when exactly one supported CLI is installed. Both subprocesses run from the repository root so root-level instructions and trusted project configuration are discovered consistently. Each receives a least-privilege environment containing normal runtime essentials and its immutable OTEL evaluation context. Other variables, including MLflow settings and credentials from the harness process, are excluded by default. If an evaluated integration genuinely needs a credential or setting, opt in by variable name, for example `AGENT_EVAL_PASSTHROUGH_ENV=CONTEXT7_API_KEY just eval-run codex`. Multiple names are comma-separated. Each CLI call has a 30-minute timeout. Codex is explicitly launched with a read-only sandbox; Claude uses the effective permissions from the user's Claude configuration because the two CLIs do not expose an equivalent execution-policy interface.

The resource identities are:

- Default tracking URI: `http://localhost:5000`
- Agent OTLP/gRPC receiver: `http://127.0.0.1:4327`
- Alloy status endpoint: `http://127.0.0.1:12345`
- Experiment: `agent-harness-evals`
- Dataset: `agent-harness-cases`
- Prompt namespace: `agent-harness--*`

Set `MLFLOW_TRACKING_URI` in the harness environment to use another server. Agent subprocesses do not inherit that variable. The local Compose services and their `eval-up`, `eval-status`, `eval-logs`, and `eval-down` recipes manage the loopback stack; they are unnecessary when the remote MLflow and Alloy services are already running.

The Compose stack binds MLflow, Alloy, and OTLP ports to loopback. MLflow persists its SQLite database and artifacts under the ignored `infra/compose/data/mlflow` directory. `eval-up` starts MLflow first, creates or reuses the experiment, writes its ID to the ignored mode-`0600` `infra/compose/.env.mlflow-runtime`, and only then starts Alloy. The server image and Python dependency are pinned to MLflow 3.14.0; Alloy is pinned to 1.18.0.

The local topology intentionally matches the first homelab stage. When MLflow and Alloy move to the homelab, the harness tracking URI and CLI OTLP endpoint change, but the evaluation attributes and Alloy routing policy do not. A later Tempo exporter can receive ordinary traces without changing the MLflow evaluation branch.

## Inspecting results

Open the configured MLflow server and select **Evaluation runs** to compare aggregate metrics and individual request rows. Each case chooses a descriptive metric name, and the corresponding feedback includes the scorer's rationale. MLflow aggregates cases that share a metric name.

Open the underlying run for complete provenance:

- **Overview → Description** shows the comparison changes and active component references.
- **Overview → Parameters** shows the complete component-to-prompt-version map and `agent.cli`.
- **Overview → About this run** shows linked manifest and component prompts.
- **Artifacts → configuration** contains `manifest.json` and `changes.txt`.

The run name includes the first relevant transition, such as `codex-manifest-v2 - workflow v1 -> v2`. Every successful run and MLflow-native request trace links the manifest and all active component prompt versions. After evaluation finishes, the harness searches the shared experiment for external CLI traces with the invocation's `evaluation.execution_id`, waits for the expected agent and judge traces to become stable, and links the same prompt versions to those traces. The execution ID avoids accidentally linking traces from an earlier run of the same case, while `config.manifest_id` remains an independently queryable configuration identity on each external trace. Trace request and response previews contain plain text instead of serialized JSON wrappers.

This external-trace correlation and prompt-linking path is installed preemptively. There are no real evaluation cases yet, so its full case-to-agent-to-judge end-to-end behavior cannot be verified until the first cases are added.

Open **Agent versions** to inspect a complete manifest-backed configuration identity. Its Overview description lists the manifest and active component versions, and its `configuration/manifest.json` artifact preserves the complete immutable manifest. Baseline-relative changes belong to evaluation runs, so reusing an Agent Version never overwrites its evidence with a different run's comparison context.

Use these filters:

- Evaluation Runs: ``params.`agent.cli` = 'codex'``
- Trace UI: **Filters → Field → `agent.cli`**
- Trace API: ``metadata.`agent.cli` = 'codex'``
- Case trace: **Filters → Field → `case_id`** or **Field → `category`**
- Evaluation invocation: **Filters → Field → `evaluation.execution_id`**
- Configuration identity: **Filters → Field → `config.manifest_id`**

`agent.cli` is the only CLI query key. Agent Versions and Evaluation Runs store it as a parameter; traces store it as immutable metadata. Case traces also store immutable `case_id`, `category`, `evaluation.role`, `evaluation.execution_id`, and `config.manifest_id` metadata while retaining plain-text request and response previews. The harness deliberately emits no duplicate CLI tags.

Independent single-turn cases do not belong under **Sessions**. If conversational cases are added later, assign one session ID per simulated conversation rather than one for the complete evaluation run.

## Baselines and diffs

The default comparison baseline is the manifest from the latest successfully attached evaluation, recorded with the profile manifest's `last-evaluated` alias. Publishing prompts for a failed or interrupted evaluation does not advance it. `--baseline-manifest-version VERSION` selects an explicit manifest version.

The change note classifies added, removed, and modified components and includes old and new prompt versions. To inspect exact text changes, open the changed component under Linked Prompts and compare its two prompt versions in the MLflow prompt UI.

## Layout

- `cases.py` defines real evaluation inputs and expectations.
- `lib/evaluation_case.py` defines the typed case contract.
- `run_mlflow_eval.py` publishes provenance, resolves an Agent Version, synchronizes the dataset, and runs evaluation.
- `lib/agent.py` invokes the authenticated Codex or Claude CLI from the repository root.
- `lib/agent_execution_context.py` defines immutable OTEL identity for agent-under-test and judge processes.
- `lib/agent_environment.py` builds the least-privilege CLI subprocess environment.
- `lib/mlflow_experiment_bootstrap.py` binds Alloy to the shared MLflow experiment.
- `lib/configuration_components.py` discovers allowlisted configuration atoms.
- `lib/configuration_manifest.py` builds complete manifests and baseline comparisons.
- `lib/mlflow_config_registry.py` publishes and links prompts, run evidence, and trace provenance.
- `lib/mlflow_agent_versions.py` resolves manifest-derived Agent Versions.
- `lib/mlflow_configuration_evidence.py` renders shared run and Agent Version descriptions and artifacts.
- `infra/compose/mlflow.yml` runs the pinned local MLflow and Alloy services.
- `infra/compose/alloy.config` filters, redacts, batches, and exports evaluation traces.
