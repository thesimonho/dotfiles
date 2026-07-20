"""Run the eval suite through MLflow with complete config provenance."""

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent / "lib"))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import agent  # noqa: E402
from agent_execution_context import AgentExecutionContext  # noqa: E402
import configuration_components  # noqa: E402
import dataset_sync  # noqa: E402
import mlflow  # noqa: E402
import mlflow.genai  # noqa: E402
import mlflow_tracing  # noqa: E402
import scoring  # noqa: E402
from cases import CASES  # noqa: E402
from mlflow.entities import Feedback  # noqa: E402
from mlflow.genai import scorer  # noqa: E402
from mlflow.tracking import MlflowClient  # noqa: E402
from mlflow_agent_versions import MlflowAgentVersionRegistry  # noqa: E402
from mlflow_config_registry import MlflowConfigurationRegistry  # noqa: E402
from harness_environment import AGENT_ARGUMENT_CHOICES  # noqa: E402
from mlflow_parameter_names import (  # noqa: E402
    AGENT_CLI_FIELD,
    CASE_CATEGORY_FIELD,
    CASE_ID_FIELD,
)

AGENT_PROFILE = "claude"


def predict_fn(prompt: str, case_id: str, category: str) -> str:
    """Run one case while keeping its identity queryable on the trace."""
    _update_trace_preview(
        metadata={
            AGENT_CLI_FIELD: AGENT_PROFILE,
            CASE_ID_FIELD: case_id,
            CASE_CATEGORY_FIELD: category,
        },
        request_preview=prompt,
    )
    response = agent.run_agent(
        prompt,
        AgentExecutionContext(
            agent_cli=AGENT_PROFILE,
            case_id=case_id,
            category=category,
            evaluation_role="agent-under-test",
        ),
        profile=AGENT_PROFILE,
    )
    _update_trace_preview(response_preview=response)
    return response


def _update_trace_preview(
    *,
    metadata: dict[str, str] | None = None,
    request_preview: str | None = None,
    response_preview: str | None = None,
) -> None:
    """Update list-view text only when MLflow has opened a trace span."""
    if mlflow.get_current_active_span() is None:
        return
    if request_preview is not None:
        mlflow.update_current_trace(
            metadata=metadata,
            request_preview=request_preview,
        )
    if response_preview is not None:
        mlflow.update_current_trace(response_preview=response_preview)


@scorer
def evaluation_score(inputs: dict, outputs: str, expectations: dict) -> Feedback:
    """Return the case-selected metric with its scoring rationale."""
    case = {"tier": expectations["tier"], **expectations}
    judge_context = AgentExecutionContext(
        agent_cli=AGENT_PROFILE,
        case_id=inputs["case_id"],
        category=inputs["category"],
        evaluation_role="judge",
    )
    passed, reason = scoring.score_case(
        outputs,
        case,
        judge_context,
        profile=AGENT_PROFILE,
    )
    return Feedback(
        name=expectations["metric_name"],
        value=passed,
        rationale=reason,
    )


def parse_arguments() -> argparse.Namespace:
    """Parse an optional manifest version to use as the comparison baseline."""
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--agent",
        choices=AGENT_ARGUMENT_CHOICES,
        default="auto",
        help="Agent CLI and configuration profile to evaluate.",
    )
    parser.add_argument(
        "--baseline-manifest-version",
        type=int,
        help="Compare against this MLflow manifest prompt version instead of the latest.",
    )
    return parser.parse_args()


def run_evaluation(arguments: argparse.Namespace) -> None:
    """Run one evaluation after rejecting an unconfigured case suite."""
    if not CASES:
        raise RuntimeError(
            "no evaluation cases configured; add real cases to AI/evals/cases.py"
        )

    global AGENT_PROFILE
    AGENT_PROFILE = agent.resolve_agent_profile(arguments.agent)
    mlflow_tracing.init()
    client = MlflowClient()
    registry = MlflowConfigurationRegistry(
        client,
        mlflow.genai,
        profile=AGENT_PROFILE,
    )
    components = configuration_components.discover_agent_components(AGENT_PROFILE)
    publication = registry.prepare(
        components,
        baseline_version=arguments.baseline_manifest_version,
    )

    experiment = mlflow.get_experiment_by_name(mlflow_tracing.EXPERIMENT_NAME)
    if experiment is None:
        raise RuntimeError(
            f"MLflow experiment was not created: {mlflow_tracing.EXPERIMENT_NAME}"
        )
    experiment_id = experiment.experiment_id
    agent_version_registry = MlflowAgentVersionRegistry(client, mlflow)
    agent_version = agent_version_registry.resolve(
        publication,
        experiment_id,
    )
    dataset = dataset_sync.sync_mlflow_dataset(CASES, experiment_id)

    results = mlflow.genai.evaluate(
        data=dataset,
        predict_fn=predict_fn,
        scorers=[evaluation_score],
        model_id=agent_version.model_id,
    )
    agent_version_registry.publish_configuration_evidence(
        publication,
        agent_version,
    )
    registry.attach_to_run(
        results.run_id,
        publication,
        expected_trace_count=len(CASES),
    )

    print(results)
    print(
        f"configuration manifest: {publication.run_metadata['config_manifest_prompt']}"
    )
    print(f"agent version: {agent_version.model_id}")
    print(publication.changes.summary)


if __name__ == "__main__":
    run_evaluation(parse_arguments())
