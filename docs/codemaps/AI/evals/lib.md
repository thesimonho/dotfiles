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
| `agent.py` | Invokes Claude/Codex with explicit model, effort, fail-closed native sandbox settings, and measured authenticated CLI subprocess duration |
| `agent_canary_evidence.py` | Recognizes only exact configured-agent canaries in final child-response footers |
| `agent_evidence.py` | Normalizes tool and collaboration events, exact expected child-definition canaries, emitted model IDs, shell commands, provider-aware token usage, and parser coverage from CLI event streams |
| `agent_event_contract.py` | Defines semantic case evidence requirements, per-profile parser support, missing-observation calculation, coverage evidence, and pre-execution validation |
| `agent_plan_evidence.py` | Recognizes Codex plan updates even when the CLI emits no completed plan item |
| `agent_execution_context.py` | Defines immutable OTEL resource identity for each evaluated agent or judge process, including execution, configuration, model, and effort identities |
| `agent_environment.py` | Builds allowlisted CLI environments with explicit integration passthrough |
| `shell_commands.py` | Splits compound shell evidence, locates executables after environment assignments, unwraps RTK, and follows nested shell commands |
| `evaluation_case.py` | Typed evaluation cases, including stable IDs, human-readable case names, and reusable output, evidence, workspace, documentation, and execution metric declarations |
| `evaluation_coverage.py` | Validates instruction-to-case coverage and projects treatment, control, and judge CLI usage before execution |
| `evaluation_scenario.py` | Hidden HomeOps scenario constraints, authorized paths, source/import-graph outcome validators, and consequence rules |
| `workspace_evidence.py` | Typed final workspace, simulator, documentation-update, negative-constraint, and blast-radius observations |
| `final_state_evidence.py` | Scans final agent-attributable additions, created commits, plan artifacts, plan references, debug logs, secrets, and changed function limits |
| `disposable_workspace.py` | Builds scenario repositories, exposes simulator tools and worktree-scoped writable paths, and captures agent-attributable file and command evidence from compound shell invocations |
| `capabilities.py` | Preflights and hashes shared CLI tools, skills, and agents and renders path-redacted MLflow evidence |
| `scoring.py` | Evaluates categorical completion and blast radius plus independently applicable tools, workflow, planning, Git, style, documentation, and security assessments |
| `typescript_module_graph.mjs` | Lexes TypeScript source to identify real relative imports whose runtime bindings are used |
| `dataset_sync.py` | Replaces hosted dataset contents and produces filtered hosted-dataset views so tiered runs retain the `agent-harness-cases` identity |
| `harness_environment.py` | Repository paths and supported agent profile constants |
| `harness_identity.py` | Environment-backed MLflow URI, experiment, dataset, and namespace identities |
| `configuration_components.py` | Discovers normalized instruction/config components and computes stable identities |
| `configuration_variant.py` | Builds treatment and single-component-ablated control profiles, materializes custom-agent files, and removes copied Codex OTEL configuration so native eval traces remain authoritative |
| `configuration_manifest.py` | Builds, serializes, compares, and summarizes configuration manifests |
| `comparison_evidence.py` | Verifies paired workspace identity and renders direction-aware deltas for the focused adherence metrics without aggregation |
| `configuration_publication.py` | Describes published configuration evidence and prompt references |
| `mlflow_config_registry.py` | Registers configuration components and manifests and links them to evaluation runs and native traces |
| `mlflow_agent_versions.py` | Resolves current and prior agent configuration versions |
| `mlflow_configuration_evidence.py` | Attaches configuration provenance to evaluation runs |
| `mlflow_parameter_names.py` | Central names for MLflow parameters, tags, and dataset fields, including the trace-queryable `case.name` field |
| `mlflow_tracing.py` | Configures trace capture around agent execution |
| `mlflow_trace_preview.py` | Sets stable human-readable request and response previews on native case traces |
| `mlflow_execution_trace.py` | Renders the measured agent invocation and normalized CLI event observations as child spans beneath each native case trace |
| `mlflow_experiment_bootstrap.py` | Creates the shared experiment and atomically renders Alloy's runtime experiment ID |

## Key exports

| Symbol | File | Description |
| --- | --- | --- |
| `run_agent()` / `run_judge()` | `agent.py` | Executes the selected CLI with the requested model and effort for a case or judge prompt |
| `AgentExecutionContext` | `agent_execution_context.py` | Serializes case, category, CLI, role, model, effort, `evaluation.execution_id`, and `config.manifest_id` as OTEL resource attributes |
| `build_child_environment()` | `agent_environment.py` | Selects safe runtime variables and explicit integration passthrough for a CLI process |
| `shell_segments()` / `unwrapped_shell_invocations()` | `shell_commands.py` | Provide one command-parsing source of truth for tool-prefix and prohibited-action evidence |
| `EvaluationCase` / `EvaluationMetric` | `evaluation_case.py` | Describe each stable case ID, human-readable case name, prompt, and independently applicable reusable metric |
| `plan_instruction_campaign()` / `format_campaign_plan()` | `evaluation_coverage.py` | Resolve applicable cases and render a zero-execution usage preview |
| `prepare_workspace()` | `disposable_workspace.py` | Creates one disposable scenario repository and removes it after evidence capture |
| `probe_capabilities()` / `capability_manifest()` | `capabilities.py` | Separates missing environment capabilities from instruction-adherence failures and records their identities without host paths |
| `AgentResult` | `agent.py` | Pairs the final response with normalized events, parser coverage, shell commands, models, token usage, and invocation duration |
| `AgentEvent` / `TokenUsage` | `agent_evidence.py` | Preserve comparable execution and usage dimensions without retaining arbitrary raw CLI payloads |
| `AgentEventCoverage` / `validate_case_evidence_requirements()` | `agent_event_contract.py` | Distinguish parser support, observed evidence, intentionally ignored events, and unknown schema shapes before scoring |
| `invoke_traced_agent()` | `mlflow_execution_trace.py` | Creates the readable `agent.invoke` subtree used as the primary instruction-adherence trace |
| `build_manifest()` / `compare_manifests()` | `configuration_manifest.py` | Creates stable manifests and identifies configuration changes |
| `discover_agent_components()` | `configuration_components.py` | Enumerates provenance-bearing client configuration inputs |
| `comparison_variants()` / `prepare_variant_profile()` | `configuration_variant.py` | Defines the one-component experimental difference and assembles hook-free authenticated profiles with raw Codex OTEL disabled |
| `build_comparison_evidence()` | `comparison_evidence.py` | Rejects mismatched workspace snapshots and renders paired run evidence |
| `mlflow_records()` / `sync_mlflow_dataset()` / `select_dataset_cases()` | `dataset_sync.py` | Serialize local case inputs, synchronize the complete hosted catalog, and select tier rows without losing dataset identity |

## Relationships

- **Used by**: `AI/evals/cases.py`, `AI/evals/coverage_catalog.py`, `AI/evals/plan_evaluation_campaign.py`, and `AI/evals/run_mlflow_eval.py`.
- **Case selection**: `AI/evals/cases.py` owns `CASES`, named `smoke`, `core`, and `extended` suite memberships, and `select_cases()`; `AI/evals/run_mlflow_eval.py` accepts mutually exclusive `--case-id` and `--suite` selection, keeps the hosted dataset synchronized with the complete catalog, and supplies selected rows through a filtered hosted-dataset view.
- **Makes cases queryable by**: storing the stable `case_id`, category, and display `case.name` trace metadata. The trace request preview uses the human-readable `case_name`, while the full prompt remains a dataset input.
- **Integrates with**: MLflow for datasets, runs, scorers, prompts, and traces; Claude and Codex CLIs for execution.
- **Validates cases by**: requiring semantic parser-support and must-observe declarations, then rejecting inconsistent or unsupported combinations before starting an agent.
- **Correlates traces by**: one `evaluation.execution_id` shared by every case in a harness run, plus `config.manifest_id`, `agent.model`, and `agent.effort` for the exact evaluated configuration. The native trace owns the readable harness and normalized CLI-event tree.

## Entry point

Start with `AI/evals/cases.py` to choose a named suite or resolve explicit IDs, `plan_evaluation_campaign.py` for cost previews, or `run_mlflow_eval.py` for orchestration. Then follow calls into `evaluation_coverage.py`, `dataset_sync.py`, `scoring.py`, and `agent.py`.
