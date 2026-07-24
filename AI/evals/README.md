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

[`cases.py`](cases.py) is the git-tracked source of truth for real evaluation cases. Each case declares every applicable metric independently. Metric names are stable semantic dimensions shared across cases, while case-specific expected values stay in the metric declaration. Omitting a metric means it is not applicable; it is never interpreted as a failure.

The first case asks the agent to query a noisy deployment inventory. It exercises reusable response and execution metrics without requiring a test repository:

- `answer_correct` requires all case-specific answer values.
- `used_structured_parser` checks whether the normalized command stream invoked `jq`.
- `all_shell_commands_prefixed` checks whether every agent-authored shell command starts with `rtk`.
- `shell_command_prefix_rate` reports the fraction of executable command segments that start with `rtk`.
- `shell_command_count` reports an unthresholded diagnostic count.

Supported response evaluators are `output-contains`, `output-contains-all`, and `output-quality`. Supported execution evaluators are `used-command`, `all-shell-commands-prefixed`, `shell-command-prefix-rate`, and `shell-command-count`. One MLflow scorer returns a list of named `Feedback` objects, so MLflow aggregates the same metric name across every applicable dataset row without collapsing distinct behavioral dimensions into one score.

Every executable case declares `required_evidence`, using semantic names such as `agent.message`, `tool.shell`, `agent.spawn`, `agent.model-selection`, and `token.usage`. It separately declares the subset in `required_observed_evidence` that must appear for the run to be trustworthy. Campaign previews and live runs validate these declarations against the selected CLI parser before contacting an agent. Missing, duplicate, inconsistent, or unsupported declarations fail before execution. This prevents a new case from silently assuming evidence that the harness does not capture; for example, a Codex case requiring `agent.model-selection` is rejected because Codex collaboration JSONL does not expose that field.

Parser support and observed behavior are distinct. Actions that a negative case expects the agent to avoid belong only in `required_evidence`; their absence remains meaningful behavioral evidence for the case scorer. Evidence needed to make any judgment, such as the final message or token report, also belongs in `required_observed_evidence`. Missing must-observe evidence produces `evidence_contract_satisfied=false`.

Every successfully completed predictor case also reports universal operational diagnostics that do not need to be declared in `cases.py`:

- `case_completion_seconds` measures predictor wall-clock completion, including disposable workspace preparation and evidence capture.
- `agent_invocation_seconds` isolates authenticated CLI subprocess time.
- `evidence_contract_satisfied` reports whether every must-observe evidence requirement appeared.
- `input_token_count`, `uncached_input_token_count`, `cached_input_token_count`, `cache_creation_input_token_count`, `output_token_count`, `reasoning_output_token_count`, and `total_token_count` are emitted when the selected CLI provides those dimensions.
- `unknown_agent_event_type_count` reports distinct CLI event shapes that have no explicit parser classification.

Unavailable token dimensions are retained as `null` in the case output and omitted from aggregate feedback rather than estimated. Each result identifies its CLI event source. Normalized input counts include cache-read and cache-creation input so the top-level input and total dimensions remain useful across providers, while the underlying cache dimensions remain separately inspectable. These diagnostics describe the agent-under-test predictor invocation. A separate LLM judge, when applicable, remains a separately correlated invocation and is not folded into these counts. The diagnostics have no pass threshold or improvement direction.

[`coverage_catalog.py`](coverage_catalog.py) maps all monitored instruction fragments to explicit behavioral hypotheses, maturity, and only the cases that genuinely exercise them. A case may support multiple fragments, so coverage grows by reusing high-signal scenarios rather than adding a separate repository or case for every instruction. `planned` entries have no cases and therefore add no evaluation cost; `active` and `proven` entries must reference executable cases.

The current active suite is deliberately bounded to five unique cases. Before spending agent usage on a fragment campaign, `eval-plan` reports the applicable cases, treatment/control pairs, agent-under-test calls, judge calls, and total CLI invocations without contacting MLflow or starting an agent. Repetitions default to one and should increase only when initial paired evidence is ambiguous or when a mature fragment is being regression-tested.

Environment-backed cases use the single-package [HomeOps environment](environments/homeops/README.md). Each case selects a deterministic scenario and either read-only or workspace-write access. The predictor prepares a disposable Git repository, runs the selected CLI from that repository, captures agent-attributable changes before cleanup, and returns workspace plus operational evidence on the native trace.

HomeOps adds reusable workspace metrics:

- `task_outcome` runs the scenario's hidden deterministic validator.
- `negative_constraints_followed` requires zero prohibited commands, protected edits, or changes outside the scenario allowlist.
- `protected_resources_preserved` isolates consequential protected-path behavior.
- `unnecessary_change_count` remains a transparent diagnostic count.
- `blast_radius_severity` reports the highest consequence from `0` (`none`) through `4` (`critical`).

Task correctness and blast radius remain separate. A narrow correct patch can pass outcome scoring while an operational action fails a negative constraint; Git-ignored verification artifacts are excluded from workspace evidence.

The authenticated CLIs' machine-readable output is the authoritative source for behavioral evidence. Codex completed thread items and Claude tool-use blocks are normalized into shell, file-change, MCP, collaboration/subagent, and other tool observations. Each result records distinct observed raw event shapes, normalized semantic evidence, intentionally ignored shapes, and unknown shapes without storing arbitrary raw payloads. The predictor returns final response, normalized execution events, parser coverage, model IDs exposed by the CLI, token usage, and timing evidence together, making them inspectable on the compact MLflow-native case trace and available synchronously to deterministic scorers. Claude exposes model choices on relevant tool-use events. Codex exposes collaboration calls, receiver thread IDs, agent states, and status but does not expose the requested or actual collaboration model in its JSONL schema; a future Codex model-selection assessment must add another authoritative evidence source rather than infer it from unrelated raw spans. Raw CLI OpenTelemetry remains a separate, correlated runtime trace source for lower-level diagnostics.

## Agent telemetry flow

Codex and Claude send OTLP/gRPC to the dedicated loopback receiver at `127.0.0.1:4327`. Alloy keeps only traces whose resource attributes include `telemetry.purpose=evaluation`, removes known account and authorization attributes, batches them, and exports them to the same MLflow experiment used by the eval harness. Logs and metrics have no configured Alloy output and are dropped. Traces from ordinary interactive agent use that lack the evaluation marker are also dropped for now.

```text
eval runner -> Codex or Claude -> OTLP :4327 -> Alloy -> MLflow /v1/traces
normal use -> Codex or Claude -> OTLP :4327 -> Alloy -> drop
```

The separate port identifies agent traffic at ingress, but it is not the security or routing boundary. The immutable `telemetry.purpose=evaluation` resource attribute is what authorizes a trace for MLflow. Ordinary day-to-day agent telemetry lacks that marker and is dropped by this MLflow route. Every eval process also receives `agent.cli`, `case_id`, `category`, and `evaluation.role`, allowing agent-under-test and judge traces to be distinguished without putting prompt or response text in resource attributes.

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
just eval-mlflow --agent codex --case-id homeops-workload-health-regression

# Run a causal treatment/control comparison for one instruction fragment.
just eval-compare codex instruction/tools homeops-workload-health-regression

# Preview applicable workflow comparisons without running an agent.
just eval-plan codex instruction/workflow
just eval-plan codex instruction/workflow 3

# Send the evaluation to a remote MLflow server.
MLFLOW_TRACKING_URI=https://mlflow.example.com just eval-run codex

# Inspect services or follow logs.
just eval-status
just eval-logs

# Stop MLflow while retaining its local data.
just eval-down

# Run project checks.
just eval-test
just eval-verify
```

Use `claude` instead of `codex` during a Claude month. `--agent auto` works only when exactly one supported CLI is installed. Small fixture-only cases run from the dotfiles repository root; environment-backed cases run from their disposable project repository so project-local instructions and Git state behave normally. Each subprocess receives a least-privilege environment containing runtime essentials, scenario command adapters, and immutable OTEL evaluation context. Other variables, including MLflow settings and credentials from the harness process, are excluded by default. If an evaluated integration genuinely needs a credential or setting, opt in by variable name, for example `AGENT_EVAL_PASSTHROUGH_ENV=CONTEXT7_API_KEY just eval-run codex`. Multiple names are comma-separated. Each CLI call has a 30-minute timeout. A case chooses read-only or workspace-write access; Codex receives the matching sandbox mode and Claude receives plan or accept-edits permission mode.

`eval-compare` creates two isolated authenticated client profiles. The treatment contains every monitored component; the control removes exactly the selected instruction component. Agent-component ablation is rejected until the runtime capability directory can be varied with the same guarantee. Both profiles share the same agents, skills, sandbox policy, telemetry configuration, task, dataset row, and deterministic workspace snapshot. Instruction-mirroring hooks are absent from both experimental arms so they cannot reinforce the prose being measured. The treatment advances the normal `last-evaluated` manifest baseline; the ablated control does not.

`eval-plan` is a zero-execution planning boundary rather than a suite runner. It validates the coverage catalog against the real case list and makes projected usage explicit. Each comparison pair costs two agent-under-test invocations; cases with an `output-quality` evaluator also cost two judge invocations per repetition. Actual comparisons remain explicit `eval-compare` calls so a broad campaign cannot begin accidentally.

Both comparison runs receive the same `evaluation.comparison_group_id` plus `evaluation.variant` and `evaluation.ablated_component_id` metadata. Their `comparison/result.json` artifacts identify both run and manifest IDs, prove that workspace snapshot hashes matched, and report raw treatment-minus-control deltas. Snapshot identity includes Git-tracked and non-ignored untracked files while excluding dependencies and other ignored build state. Metrics explicitly declare whether higher or lower is better; diagnostic metrics such as command count have no manufactured improvement direction. The harness does not calculate an aggregate score.

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

The run name includes the first relevant transition, such as `codex-manifest-v2 - workflow v1 -> v2`. Every successful run and MLflow-native request trace links the manifest and all active component prompt versions. After evaluation finishes, the harness searches the shared experiment for external CLI traces with the invocation's `evaluation.execution_id`, waits for the expected agent and judge traces to become stable, and links the same prompt versions to those traces. Search is paginated because a CLI invocation can emit many independent low-level OTEL traces. The execution ID avoids accidentally linking traces from an earlier run of the same case, while `config.manifest_id` remains an independently queryable configuration identity on each external trace. Trace request and response previews contain plain text instead of serialized JSON wrappers.

The MLflow-native case trace is the primary instruction-adherence view. Its `predict_fn` root contains:

```text
predict_fn
├── workspace.prepare
├── agent.invoke
│   ├── tool.shell
│   ├── tool.apply_patch
│   ├── tool.<mcp-name>
│   └── agent.<collaboration-call>
├── workspace.capture
└── workspace.cleanup
```

Fixture-only cases omit the workspace spans. `agent.invoke` records measured CLI duration, supported and must-observe requirements, normalized evidence types, unobserved must-observe requirements, unknown event types, emitted model IDs, normalized token dimensions, and MLflow's standard chat token-usage attribute. Its tool and agent children are observation spans reconstructed from the completed machine-readable CLI stream: they expose their semantic evidence type, normalized status, and allowlisted arguments, but their near-zero span duration is not the original tool runtime. The final response and the same normalized evidence remain in the predictor output used by scorers.

The separately correlated CLI traces retain raw runtime and transport telemetry. They may appear as many independent trace roots because the upstream CLIs do not emit one causal hierarchy. Keeping those raw traces distinct preserves diagnostic detail without making them the main instruction-adherence surface.

Open **Agent versions** to inspect a complete manifest-backed configuration identity. Its Overview description lists the manifest and active component versions, and its `configuration/manifest.json` artifact preserves the complete immutable manifest. Baseline-relative changes belong to evaluation runs, so reusing an Agent Version never overwrites its evidence with a different run's comparison context.

Use these filters:

- Evaluation Runs: ``params.`agent.cli` = 'codex'``
- Trace UI: **Filters → Field → `agent.cli`**
- Trace API: ``metadata.`agent.cli` = 'codex'``
- Case trace: **Filters → Field → `case_id`** or **Field → `category`**
- Evaluation invocation: **Filters → Field → `evaluation.execution_id`**
- Paired comparison: **Filters → Field → `evaluation.comparison_group_id`**
- Comparison arm: **Filters → Field → `evaluation.variant`**
- Configuration identity: **Filters → Field → `config.manifest_id`**

`agent.cli` is the only CLI query key. Agent Versions and Evaluation Runs store it as a parameter; traces store it as immutable metadata. Case traces also store immutable `case_id`, `category`, `evaluation.role`, `evaluation.execution_id`, and `config.manifest_id` metadata while retaining plain-text request and response previews. The harness deliberately emits no duplicate CLI tags.

Independent single-turn cases do not belong under **Sessions**. If conversational cases are added later, assign one session ID per simulated conversation rather than one for the complete evaluation run.

## Baselines and diffs

The default comparison baseline is the manifest from the latest successfully attached evaluation, recorded with the profile manifest's `last-evaluated` alias. Publishing prompts for a failed or interrupted evaluation does not advance it. `--baseline-manifest-version VERSION` selects an explicit manifest version.

The change note classifies added, removed, and modified components and includes old and new prompt versions. To inspect exact text changes, open the changed component under Linked Prompts and compare its two prompt versions in the MLflow prompt UI.

## Layout

- `cases.py` defines real evaluation inputs and reusable metric declarations.
- `coverage_catalog.py` maps instruction hypotheses to applicable cases without duplicating cases.
- `plan_evaluation_campaign.py` previews paired campaign usage without invoking agents or MLflow.
- `fixtures/` contains small case inputs that do not require a disposable repository.
- `environments/homeops/` contains the stable web project, scenario-visible setup and overlays, simulator command surface, and environment documentation.
- `tests/` covers case translation, metric scoring, CLI evidence normalization, and MLflow compatibility boundaries.
- `lib/evaluation_case.py` defines the typed case contract.
- `lib/agent_event_contract.py` defines semantic evidence requirements, per-profile parser support, coverage evidence, and fail-before-execution validation.
- `lib/evaluation_coverage.py` validates fragment coverage and calculates campaign invocation costs.
- `lib/disposable_workspace.py` assembles isolated scenario repositories with private dependencies and captures final evidence.
- `lib/evaluation_scenario.py` contains harness-only constraints, impact rules, and deterministic validators.
- `lib/capabilities.py` proves shared tools, skills, and agents are available before scoring begins and creates the path-redacted capability artifact.
- `run_mlflow_eval.py` publishes provenance, resolves an Agent Version, synchronizes the dataset, and runs evaluation.
- `lib/agent.py` invokes the authenticated Codex or Claude CLI from the case's selected working directory and access mode while requiring native OS sandboxing and blocked tool-process network access.
- `lib/agent_evidence.py` normalizes CLI tool, collaboration, model, and provider-aware token evidence without retaining arbitrary raw event payloads.
- `lib/evaluation_operational_feedback.py` renders universal timing, token, evidence-contract, and parser-coverage feedback.
- `lib/agent_execution_context.py` defines immutable OTEL identity for agent-under-test and judge processes.
- `lib/agent_environment.py` builds the least-privilege CLI subprocess environment.
- `lib/mlflow_experiment_bootstrap.py` binds Alloy to the shared MLflow experiment.
- `lib/mlflow_execution_trace.py` renders normalized CLI evidence as child spans beneath the MLflow-native case trace.
- `lib/configuration_components.py` discovers allowlisted configuration atoms.
- `lib/configuration_manifest.py` builds complete manifests and baseline comparisons.
- `lib/mlflow_config_registry.py` publishes and links prompts, run evidence, and trace provenance.
- `lib/mlflow_agent_versions.py` resolves manifest-derived Agent Versions.
- `lib/mlflow_configuration_evidence.py` renders shared run and Agent Version descriptions and artifacts.
- `infra/compose/mlflow.yml` runs the pinned local MLflow and Alloy services.
- `infra/compose/alloy.config` filters, redacts, batches, and exports evaluation traces.
