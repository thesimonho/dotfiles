"""Rank recorded evaluation runs by what they would cost at current prices."""

import sys
from datetime import date
from pathlib import Path

EVALUATION_ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(EVALUATION_ROOT / "lib"))

import mlflow  # noqa: E402
from harness_identity import (  # noqa: E402
    MLFLOW_EXPERIMENT_NAME,
    MLFLOW_TRACKING_URI,
)
from mlflow.tracking import MlflowClient  # noqa: E402
from tracking.cost_report import (  # noqa: E402
    RunCost,
    format_cost_report,
    load_rate_table,
    token_costs,
)


def pooled_adherence(run_id: str, experiment_id: str) -> float | None:
    """Average every percentage assessment recorded against one run.

    Pooling across assessments rather than across metric means keeps each
    observation equally weighted, so a metric measured once does not count as
    much as one measured in every case.
    """
    traces = mlflow.search_traces(
        locations=[experiment_id],
        run_id=run_id,
        return_type="list",
    )
    values = [
        assessment.feedback.value
        for trace in traces
        for assessment in (trace.info.assessments or [])
        if assessment.name.endswith("_percent")
        and assessment.valid
        and assessment.feedback is not None
        and isinstance(assessment.feedback.value, (int, float))
    ]
    if not values:
        return None
    return sum(values) / len(values)


def main() -> None:
    """Print every run ranked by spend at today's prices."""
    mlflow.set_tracking_uri(MLFLOW_TRACKING_URI)
    client = MlflowClient(tracking_uri=MLFLOW_TRACKING_URI)
    experiment = client.get_experiment_by_name(MLFLOW_EXPERIMENT_NAME)
    if experiment is None:
        raise SystemExit(f"no experiment named {MLFLOW_EXPERIMENT_NAME}")

    today = date.today()
    table = load_rate_table()
    costs = []
    unpriced = []
    for run in client.search_runs([experiment.experiment_id]):
        parameters = run.data.params
        profile = parameters.get("agent.cli")
        model = parameters.get("agent.model")
        if profile is None or model is None:
            continue
        run_name = run.data.tags.get("mlflow.runName", run.info.run_id)
        rate = table.rate_for(profile, model, today)
        if rate is None:
            unpriced.append((run_name, profile, model))
            continue
        output_cost, input_cost = token_costs(run.data.metrics, rate)
        costs.append(
            RunCost(
                run_name=run_name,
                profile=profile,
                model=model,
                effort=parameters.get("agent.effort", "unknown"),
                output_cost=output_cost,
                input_cost=input_cost,
                adherence=pooled_adherence(
                    run.info.run_id,
                    experiment.experiment_id,
                ),
            )
        )
    print(format_cost_report(costs, table, today, unpriced))


if __name__ == "__main__":
    main()
