"""Run the eval suite through MLflow with complete config provenance."""

import sys
from argparse import Namespace
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent / "lib"))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import agent  # noqa: E402
import configuration.components as configuration_components  # noqa: E402
import tracking.dataset_sync as dataset_sync  # noqa: E402
import mlflow  # noqa: E402
import mlflow.genai  # noqa: E402
import tracking.tracing as mlflow_tracing  # noqa: E402
from agent_event_contract import validate_case_evidence_requirements  # noqa: E402
from cases import CASES, select_cases, select_cases_for_profile  # noqa: E402
from configuration.catalog import resolve_evaluation_compute  # noqa: E402
from comparison_execution import run_component_comparison  # noqa: E402
from configuration.variant import (  # noqa: E402
    ConfigurationVariant,
    prepare_variant_profile,
)
from evaluation_arguments import parse_evaluation_arguments  # noqa: E402
from evaluation_arm import (  # noqa: E402
    print_completed_evaluation,
    run_evaluation_arm,
)
from mlflow.tracking import MlflowClient  # noqa: E402
from tracking.config_registry import MlflowConfigurationRegistry  # noqa: E402


def run_evaluation(arguments: Namespace) -> None:
    """Run one evaluation after rejecting an unconfigured case suite."""
    if not CASES:
        raise RuntimeError(
            "no evaluation cases configured; add real cases to AI/evals/cases.py"
        )

    agent_profile = agent.resolve_agent_profile(arguments.agent)
    model, effort = resolve_evaluation_compute(
        agent_profile,
        arguments.model,
        arguments.effort,
    )
    requested_cases = select_cases(arguments.case_ids, arguments.suite)
    selected_cases = select_cases_for_profile(
        requested_cases,
        agent_profile,
        explicit_selection=bool(arguments.case_ids),
    )
    validate_case_evidence_requirements(agent_profile, selected_cases)
    mlflow_tracing.init()
    client = MlflowClient()
    registry = MlflowConfigurationRegistry(
        client,
        mlflow.genai,
        profile=agent_profile,
    )
    components = configuration_components.discover_agent_components(agent_profile)
    experiment = mlflow.get_experiment_by_name(mlflow_tracing.EXPERIMENT_NAME)
    if experiment is None:
        raise RuntimeError(
            f"MLflow experiment was not created: {mlflow_tracing.EXPERIMENT_NAME}"
        )
    experiment_id = experiment.experiment_id
    dataset = dataset_sync.sync_mlflow_dataset(CASES, experiment_id)
    evaluation_data = dataset_sync.select_dataset_cases(dataset, selected_cases)

    if arguments.compare_component:
        run_component_comparison(
            client=client,
            registry=registry,
            profile=agent_profile,
            components=components,
            component_id=arguments.compare_component,
            selected_cases=selected_cases,
            evaluation_data=evaluation_data,
            experiment_id=experiment_id,
            baseline_manifest_version=arguments.baseline_manifest_version,
            model=model,
            effort=effort,
            advance_baseline=arguments.advance_baseline,
        )
        return

    if arguments.naked:
        active_components = tuple(
            component
            for component in components
            if not component.component_id.startswith(("instruction/", "hook/"))
        )
        active_variant = ConfigurationVariant(
            name="naked",
            components=active_components,
        )
    else:
        active_components = components
        active_variant = ConfigurationVariant(
            name="treatment",
            components=components,
        )
    with prepare_variant_profile(agent_profile, active_variant) as prepared_profile:
        completed = run_evaluation_arm(
            client=client,
            registry=registry,
            profile=agent_profile,
            components=active_components,
            selected_cases=selected_cases,
            evaluation_data=evaluation_data,
            experiment_id=experiment_id,
            baseline_manifest_version=arguments.baseline_manifest_version,
            model=model,
            effort=effort,
            profile_environment=prepared_profile.environment,
            agent_definition_canary=prepared_profile.agent_definition_canary,
            comparison_variant="naked" if arguments.naked else None,
            advance_baseline_alias=arguments.advance_baseline,
        )
    print_completed_evaluation(completed)


if __name__ == "__main__":
    run_evaluation(parse_evaluation_arguments())
