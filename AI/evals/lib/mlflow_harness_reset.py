"""Guarded cleanup for expendable local MLflow agent-harness history."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Callable

from harness_identity import (
    EVALUATION_DATASET_NAME,
    MLFLOW_EXPERIMENT_NAME,
    PROMPT_NAMESPACE_PREFIX,
)

LOCAL_TRACKING_URIS = {
    "http://127.0.0.1:5000",
    "http://localhost:5000",
}
PROMPT_EXPERIMENT_IDS_TAG = "_mlflow_experiment_ids"


@dataclass(frozen=True)
class HarnessResetReport:
    """Exact MLflow resource identities removed by one reset."""

    deleted_trace_ids: tuple[str, ...]
    deleted_run_ids: tuple[str, ...]
    deleted_model_ids: tuple[str, ...]
    deleted_dataset_ids: tuple[str, ...]
    deleted_prompt_names: tuple[str, ...]


def reset_local_harness(client: Any) -> HarnessResetReport:
    """Delete only resources owned by the exact local agent-harness experiment."""
    _require_local_tracking_uri(client.tracking_uri)
    experiment = client.get_experiment_by_name(MLFLOW_EXPERIMENT_NAME)
    if experiment is None:
        return HarnessResetReport((), (), (), (), ())

    experiment_id = str(experiment.experiment_id)
    trace_ids = _trace_ids(client, experiment_id)
    run_ids = _run_ids(client, experiment_id)
    model_ids = _model_ids(client, experiment_id)
    datasets = _datasets(client, experiment_id)
    _require_experiment_owned_datasets(datasets, experiment_id)
    dataset_ids = tuple(sorted(dataset.dataset_id for dataset in datasets))
    prompt_names = _owned_prompt_names(client, experiment_id)

    _delete_traces(client, experiment_id, trace_ids)
    for run_id in run_ids:
        client.delete_run(run_id)
    for model_id in model_ids:
        client.delete_logged_model(model_id)
    for dataset_id in dataset_ids:
        client.delete_dataset(dataset_id)
    for prompt_name in prompt_names:
        client.delete_prompt(prompt_name)

    _verify_empty(client, experiment_id)
    return HarnessResetReport(
        deleted_trace_ids=trace_ids,
        deleted_run_ids=run_ids,
        deleted_model_ids=model_ids,
        deleted_dataset_ids=dataset_ids,
        deleted_prompt_names=prompt_names,
    )


def _require_local_tracking_uri(tracking_uri: str) -> None:
    if tracking_uri.rstrip("/") not in LOCAL_TRACKING_URIS:
        raise ValueError("harness reset is restricted to the local MLflow server")


def _require_experiment_owned_datasets(
    datasets: tuple[Any, ...],
    experiment_id: str,
) -> None:
    for dataset in datasets:
        attached_experiment_ids = {str(value) for value in dataset.experiment_ids}
        if attached_experiment_ids != {experiment_id}:
            raise ValueError(
                f"dataset {dataset.dataset_id} is shared with another experiment"
            )


def _delete_traces(client: Any, experiment_id: str, trace_ids: tuple[str, ...]) -> None:
    for offset in range(0, len(trace_ids), 1000):
        batch = list(trace_ids[offset : offset + 1000])
        deleted_count = client.delete_traces(experiment_id, trace_ids=batch)
        if deleted_count != len(batch):
            raise RuntimeError("MLflow deleted fewer harness traces than requested")


def _verify_empty(client: Any, experiment_id: str) -> None:
    remaining = {
        "traces": _trace_ids(client, experiment_id),
        "runs": _run_ids(client, experiment_id),
        "models": _model_ids(client, experiment_id),
        "datasets": tuple(
            dataset.dataset_id for dataset in _datasets(client, experiment_id)
        ),
        "prompts": _owned_prompt_names(client, experiment_id),
    }
    nonempty = {name: values for name, values in remaining.items() if values}
    if nonempty:
        raise RuntimeError(f"MLflow harness reset was incomplete: {nonempty}")


def _trace_ids(client: Any, experiment_id: str) -> tuple[str, ...]:
    traces = _search_all(
        client.search_traces,
        locations=[experiment_id],
        max_results=100,
        include_spans=False,
    )
    return tuple(sorted(trace.info.trace_id for trace in traces))


def _run_ids(client: Any, experiment_id: str) -> tuple[str, ...]:
    runs = _search_all(
        client.search_runs,
        experiment_ids=[experiment_id],
        max_results=1000,
    )
    return tuple(sorted(run.info.run_id for run in runs))


def _model_ids(client: Any, experiment_id: str) -> tuple[str, ...]:
    models = _search_all(
        client.search_logged_models,
        experiment_ids=[experiment_id],
        max_results=1000,
    )
    invalid_models = [
        model.model_id for model in models if str(model.experiment_id) != experiment_id
    ]
    if invalid_models:
        raise RuntimeError(
            f"MLflow returned models outside the experiment: {invalid_models}"
        )
    return tuple(sorted(model.model_id for model in models))


def _datasets(client: Any, experiment_id: str) -> tuple[Any, ...]:
    datasets = _search_all(
        client.search_datasets,
        experiment_ids=[experiment_id],
        filter_string=f"name = '{EVALUATION_DATASET_NAME}'",
        max_results=50,
    )
    return tuple(
        dataset for dataset in datasets if dataset.name == EVALUATION_DATASET_NAME
    )


def _owned_prompt_names(client: Any, experiment_id: str) -> tuple[str, ...]:
    prompts = _search_all(
        client.search_prompts,
        filter_string=f"name LIKE '{PROMPT_NAMESPACE_PREFIX}%'",
        max_results=1000,
    )
    owned_prompts = tuple(
        prompt for prompt in prompts if prompt.name.startswith(PROMPT_NAMESPACE_PREFIX)
    )
    for prompt in owned_prompts:
        experiment_ids = _prompt_experiment_ids(prompt)
        if experiment_ids != {experiment_id}:
            raise ValueError(f"prompt {prompt.name} is shared with another experiment")
    return tuple(sorted(prompt.name for prompt in owned_prompts))


def _prompt_experiment_ids(prompt: Any) -> set[str]:
    serialized_ids = prompt.tags.get(PROMPT_EXPERIMENT_IDS_TAG, "")
    return {value for value in serialized_ids.split(",") if value}


def _search_all(search: Callable[..., Any], **kwargs: Any) -> tuple[Any, ...]:
    results = []
    page_token = None
    while True:
        page = search(page_token=page_token, **kwargs)
        results.extend(page)
        page_token = getattr(page, "token", None)
        if not page_token:
            return tuple(results)
