"""Per-case prediction and scoring callables shared by every evaluation arm."""

import time
from collections.abc import Callable
from contextlib import ExitStack
from dataclasses import asdict
from typing import Any, cast

import mlflow
from mlflow.entities import Feedback
from mlflow.genai import scorer

import agent
import scoring
from agent_event_contract import (
    EvidenceRequirement,
    unobserved_evidence_requirements,
)
from agent_execution_context import AgentExecutionContext, EvaluationRole
from disposable_workspace import prepare_workspace
from evaluation_case import WorkspaceSpec
from evaluation_run_identity import EvaluationIdentity, WorkspaceSnapshotRecorder
from evidence.operational_telemetry import OperationalTelemetryRecorder
from tracking.execution_trace import invoke_traced_agent
from tracking.parameter_names import (
    AGENT_CLI_FIELD,
    CASE_CATEGORY_FIELD,
    CASE_ID_FIELD,
    CASE_NAME_FIELD,
)
from tracking.trace_preview import update_trace_preview


def execution_context(
    *,
    identity: EvaluationIdentity,
    case_id: str,
    category: str,
    role: EvaluationRole,
) -> AgentExecutionContext:
    """Construct the shared immutable identity for an agent CLI process."""
    return AgentExecutionContext(
        agent_cli=identity.profile,
        agent_model=identity.model,
        agent_effort=identity.effort,
        case_id=case_id,
        category=category,
        evaluation_role=role,
        evaluation_execution_id=identity.execution_id,
        config_manifest_id=identity.manifest_id,
        comparison_group_id=identity.comparison_group_id,
        comparison_variant=identity.comparison_variant,
        ablated_component_id=identity.ablated_component_id,
    )


def build_predict_fn(
    identity: EvaluationIdentity,
    profile_environment: dict[str, str] | None = None,
    agent_definition_canary: str | None = None,
    workspace_snapshots: WorkspaceSnapshotRecorder | None = None,
    telemetry: OperationalTelemetryRecorder | None = None,
) -> Callable[..., dict[str, object]]:
    """Build a predictor whose native case traces share immutable run identity."""

    def predict_fn(
        prompt: str,
        case_id: str,
        case_name: str,
        category: str,
        required_evidence: list[str] | tuple[str, ...],
        required_observed_evidence: list[str] | tuple[str, ...],
        workspace: WorkspaceSpec | None = None,
    ) -> dict[str, object]:
        """Run one case while keeping its identity queryable on the trace."""
        case_started_at = time.perf_counter()
        update_trace_preview(
            metadata={
                AGENT_CLI_FIELD: identity.profile,
                CASE_ID_FIELD: case_id,
                CASE_NAME_FIELD: case_name,
                CASE_CATEGORY_FIELD: category,
                **identity.trace_metadata(),
            },
            request_preview=case_name,
        )
        agent_context = execution_context(
            identity=identity,
            case_id=case_id,
            category=category,
            role="agent-under-test",
        )
        if not all(isinstance(requirement, str) for requirement in required_evidence):
            raise TypeError("case evidence requirements must be strings")
        evidence_requirements: tuple[EvidenceRequirement, ...] = tuple(
            cast(EvidenceRequirement, requirement) for requirement in required_evidence
        )
        if not all(
            isinstance(requirement, str) for requirement in required_observed_evidence
        ):
            raise TypeError("observed evidence requirements must be strings")
        observed_evidence_requirements: tuple[EvidenceRequirement, ...] = tuple(
            cast(EvidenceRequirement, requirement)
            for requirement in required_observed_evidence
        )
        if workspace is None:
            result = invoke_traced_agent(
                lambda: agent.run_agent(
                    prompt,
                    agent_context,
                    profile=identity.profile,
                    environment_overrides=profile_environment,
                    agent_definition_canary=agent_definition_canary,
                    model=identity.model,
                    effort=identity.effort,
                ),
                evidence_requirements,
                observed_evidence_requirements,
            )
            workspace_evidence = None
        else:
            workspace_stack = ExitStack()
            try:
                with mlflow.start_span(
                    name="workspace.prepare",
                    span_type="CHAIN",
                ):
                    prepared_workspace = workspace_stack.enter_context(
                        prepare_workspace(
                            workspace["environment"],
                            workspace["scenario"],
                        )
                    )
                if workspace_snapshots is not None:
                    workspace_snapshots.record(
                        case_id,
                        prepared_workspace.workspace_snapshot_hash,
                    )
                result = invoke_traced_agent(
                    lambda: agent.run_agent(
                        prompt,
                        agent_context,
                        profile=identity.profile,
                        workspace_path=prepared_workspace.path,
                        workspace_access=workspace["access"],
                        environment_overrides={
                            **(profile_environment or {}),
                            **prepared_workspace.environment,
                        },
                        additional_writable_paths=(
                            prepared_workspace.additional_writable_paths
                        ),
                        agent_definition_canary=agent_definition_canary,
                        model=identity.model,
                        effort=identity.effort,
                    ),
                    evidence_requirements,
                    observed_evidence_requirements,
                )
                with mlflow.start_span(
                    name="workspace.capture",
                    span_type="CHAIN",
                ) as capture_span:
                    workspace_evidence = asdict(
                        prepared_workspace.capture_evidence(
                            shell_commands=result.shell_commands,
                        )
                    )
                    capture_span.set_outputs(workspace_evidence)
            finally:
                with mlflow.start_span(
                    name="workspace.cleanup",
                    span_type="CHAIN",
                ):
                    workspace_stack.close()
        update_trace_preview(response_preview=result.response)
        case_completion_seconds = time.perf_counter() - case_started_at
        unobserved_required_evidence = unobserved_evidence_requirements(
            observed_evidence_requirements,
            result.event_coverage.normalized_evidence_types,
        )
        observed_tool_calls = result.tool_calls_by_name
        if telemetry is not None:
            telemetry.record(case_id, result.telemetry)
        output = {
            "response": result.response,
            "execution_evidence": {
                "shell_commands": result.shell_commands,
                "events": tuple(event.to_dict() for event in result.events),
                "model_ids": result.model_ids,
                "required_evidence": evidence_requirements,
                "required_observed_evidence": observed_evidence_requirements,
                "unobserved_required_evidence": unobserved_required_evidence,
                "event_coverage": result.event_coverage.to_dict(),
            },
            "operational_evidence": {
                "case_completion_seconds": case_completion_seconds,
                "agent_invocation_seconds": result.invocation_seconds,
                "token_usage": result.token_usage.to_dict(),
                "tool_call_count": result.tool_call_count,
                "tool_calls_by_name": observed_tool_calls,
                "tool_round_trips": result.tool_round_trips,
            },
        }
        active_span = mlflow.get_current_active_span()
        if active_span is not None:
            active_span.set_attributes(
                {
                    "evaluation.case_completion_seconds": case_completion_seconds,
                    "evaluation.agent_invocation_seconds": result.invocation_seconds,
                    "evaluation.tool_call_count": result.tool_call_count,
                }
            )
        if workspace_evidence is not None:
            output["workspace_evidence"] = workspace_evidence
        return output

    return predict_fn


def build_evaluation_scorer(
    identity: EvaluationIdentity,
    metrics_by_case_id: dict[str, Any],
    profile_environment: dict[str, str] | None = None,
):
    """Build a scorer whose judge traces share the evaluation execution ID."""

    @scorer
    def evaluation_score(
        inputs: dict,
        outputs: dict,
    ) -> list[Feedback]:
        """Return every response-derived metric applicable to this case."""
        judge_context = execution_context(
            identity=identity,
            case_id=inputs["case_id"],
            category=inputs["category"],
            role="judge",
        )
        metrics = tuple(
            scoring.metric_from_mapping(metric)
            for metric in metrics_by_case_id[inputs["case_id"]]
        )
        response_results = scoring.score_response_metrics(
            outputs["response"],
            metrics,
            judge_context,
            profile=identity.profile,
            environment_overrides=profile_environment,
        )
        execution_results = scoring.score_execution_metrics(
            tuple(outputs["execution_evidence"]["shell_commands"]),
            metrics,
            tuple(outputs["execution_evidence"]["events"]),
            agent_profile=identity.profile,
            parent_model=identity.model,
            parent_effort=identity.effort,
        )
        workspace_results = (
            scoring.score_workspace_metrics(outputs["workspace_evidence"], metrics)
            if "workspace_evidence" in outputs
            else []
        )
        cross_results = scoring.score_cross_metrics(
            outputs["response"],
            tuple(outputs["execution_evidence"]["events"]),
            metrics,
        )
        return [
            Feedback(
                name=result.name,
                value=result.value,
                rationale=result.rationale,
                metadata=scoring.metric_metadata(
                    next(metric for metric in metrics if metric["name"] == result.name)
                ),
            )
            for result in (
                *response_results,
                *execution_results,
                *workspace_results,
                *cross_results,
            )
        ]

    return evaluation_score
