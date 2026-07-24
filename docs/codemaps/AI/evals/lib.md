---
agent:
  instruction: Update this codemap when evaluation harness library modules or their public responsibilities change.
  on-change: "AI/evals/lib/**"
---

# AI Evaluation Library

Python modules supporting the agent evaluation harness. The library separates agent execution, case schemas, MLflow dataset/scoring integration, tracing, and reproducible configuration provenance.

## Files

| File | Description |
| --- | --- |
| `agent.py` | Invokes Claude/Codex with fail-closed native sandbox settings and measures authenticated CLI subprocess duration |
| `agent_evidence.py` | Normalizes tool and collaboration events, emitted model IDs, shell commands, provider-aware token usage, and parser coverage from CLI event streams |
| `agent_event_contract.py` | Defines semantic case evidence requirements, per-profile parser support, coverage evidence, and pre-execution validation |
| `agent_execution_context.py` | Defines immutable OTEL resource identity for each evaluated agent or judge process, including shared execution and configuration identities |
| `agent_environment.py` | Builds allowlisted CLI environments with explicit integration passthrough |
| `evaluation_case.py` | Typed case and reusable response/execution metric declarations |
| `evaluation_coverage.py` | Validates instruction-to-case coverage and projects treatment, control, and judge CLI usage before execution |
| `evaluation_operational_feedback.py` | Produces universal timing, token, evidence-contract, and unknown-event feedback |
| `evaluation_scenario.py` | Hidden HomeOps scenario constraints, authorized paths, outcome validators, and consequence rules |
| `workspace_evidence.py` | Typed final workspace, simulator, negative-constraint, and blast-radius observations |
| `disposable_workspace.py` | Builds scenario repositories with private dependencies, exposes simulator tools, and captures agent-attributable evidence |
| `capabilities.py` | Preflights and hashes shared CLI tools, skills, and agents and renders path-redacted MLflow evidence |
| `scoring.py` | Evaluates independently named response, execution, workspace, and blast-radius metrics |
| `dataset_sync.py` | Converts cases to MLflow records and replaces dataset contents |
| `harness_environment.py` | Repository paths and supported agent profile constants |
| `harness_identity.py` | Environment-backed MLflow URI, experiment, dataset, and namespace identities |
| `configuration_components.py` | Discovers normalized instruction/config components and computes stable identities |
| `configuration_variant.py` | Builds treatment and single-component-ablated control profiles with identical non-instruction capabilities |
| `configuration_manifest.py` | Builds, serializes, compares, and summarizes configuration manifests |
| `comparison_evidence.py` | Verifies paired workspace identity and renders direction-aware metric deltas without aggregation |
| `configuration_publication.py` | Describes published configuration evidence and prompt references |
| `mlflow_config_registry.py` | Registers configuration components and manifests, links them to evaluation runs and native traces, and discovers external CLI traces by execution ID for prompt linking |
| `mlflow_agent_versions.py` | Resolves current and prior agent configuration versions |
| `mlflow_configuration_evidence.py` | Attaches configuration provenance to evaluation runs |
| `mlflow_parameter_names.py` | Central names for MLflow parameters, tags, and dataset fields |
| `mlflow_tracing.py` | Configures trace capture around agent execution |
| `mlflow_execution_trace.py` | Renders the measured agent invocation and normalized CLI event observations as child spans beneath each native case trace |
| `mlflow_experiment_bootstrap.py` | Creates the shared experiment and atomically renders Alloy's runtime experiment ID |

## Key exports

| Symbol | File | Description |
| --- | --- | --- |
| `run_agent()` / `run_judge()` | `agent.py` | Executes the selected CLI for a case or judge prompt |
| `AgentExecutionContext` | `agent_execution_context.py` | Serializes case, category, CLI, role, `evaluation.execution_id`, and `config.manifest_id` as OTEL resource attributes |
| `build_child_environment()` | `agent_environment.py` | Selects safe runtime variables and explicit integration passthrough for a CLI process |
| `EvaluationCase` / `EvaluationMetric` | `evaluation_case.py` | Describe a prompt and every independently applicable reusable metric |
| `plan_instruction_campaign()` / `format_campaign_plan()` | `evaluation_coverage.py` | Resolve applicable cases and render a zero-execution usage preview |
| `prepare_workspace()` | `disposable_workspace.py` | Creates one disposable scenario repository and removes it after evidence capture |
| `probe_capabilities()` / `capability_manifest()` | `capabilities.py` | Separates missing environment capabilities from instruction-adherence failures and records their identities without host paths |
| `AgentResult` | `agent.py` | Pairs the final response with normalized events, parser coverage, shell commands, models, token usage, and invocation duration |
| `AgentEvent` / `TokenUsage` | `agent_evidence.py` | Preserve comparable execution and usage dimensions without retaining arbitrary raw CLI payloads |
| `AgentEventCoverage` / `validate_case_evidence_requirements()` | `agent_event_contract.py` | Distinguish parser support, observed evidence, intentionally ignored events, and unknown schema shapes before scoring |
| `invoke_traced_agent()` | `mlflow_execution_trace.py` | Creates the readable `agent.invoke` subtree used as the primary instruction-adherence trace |
| `build_manifest()` / `compare_manifests()` | `configuration_manifest.py` | Creates stable manifests and identifies configuration changes |
| `discover_agent_components()` | `configuration_components.py` | Enumerates provenance-bearing client configuration inputs |
| `comparison_variants()` / `prepare_variant_profile()` | `configuration_variant.py` | Defines the one-component experimental difference and assembles hook-free authenticated profiles |
| `build_comparison_evidence()` | `comparison_evidence.py` | Rejects mismatched workspace snapshots and renders paired run evidence |
| `sync_mlflow_dataset()` | `dataset_sync.py` | Makes the remote dataset match local cases |

## Relationships

- **Used by**: `AI/evals/cases.py`, `AI/evals/coverage_catalog.py`, `AI/evals/plan_evaluation_campaign.py`, and `AI/evals/run_mlflow_eval.py`.
- **Integrates with**: MLflow for datasets, runs, scorers, prompts, and traces; Claude and Codex CLIs for execution.
- **Validates cases by**: requiring semantic parser-support and must-observe declarations, then rejecting inconsistent or unsupported combinations before starting an agent.
- **Correlates traces by**: one `evaluation.execution_id` shared by agent and judge CLI invocations in a harness run, plus `config.manifest_id` for the exact published configuration. The native trace owns the readable harness and CLI-event tree; after evaluation, the registry uses the execution ID to find separate raw OTLP traces and link the same prompt versions.

## Entry point

Start with `plan_evaluation_campaign.py` for cost previews or `run_mlflow_eval.py` for orchestration, then follow calls into `evaluation_coverage.py`, `dataset_sync.py`, `scoring.py`, and `agent.py`.
