"""Push the git-tracked cases into MLflow's hosted evaluation dataset."""

from typing import Any

from agent_event_contract import EvidenceRequirement
from evaluation_case import EvaluationCase
from harness_identity import EVALUATION_DATASET_NAME
from mlflow_parameter_names import CASE_CATEGORY_FIELD, CASE_ID_FIELD

DATASET_NAME = EVALUATION_DATASET_NAME


def mlflow_records(cases: tuple[EvaluationCase, ...]) -> list[dict[str, Any]]:
    """Translate typed local cases into MLflow inputs and expectations."""
    input_field_names = {
        "prompt",
        "required_evidence",
        "required_observed_evidence",
        "workspace",
        CASE_ID_FIELD,
        CASE_CATEGORY_FIELD,
    }
    return [
        {
            "inputs": {
                "prompt": case["prompt"],
                "required_evidence": _required_evidence(case),
                "required_observed_evidence": _required_observed_evidence(case),
                CASE_ID_FIELD: case[CASE_ID_FIELD],
                CASE_CATEGORY_FIELD: case[CASE_CATEGORY_FIELD],
                **({"workspace": case["workspace"]} if "workspace" in case else {}),
            },
            "expectations": {
                name: value
                for name, value in case.items()
                if name not in input_field_names
            },
        }
        for case in cases
    ]


def _required_evidence(
    case: EvaluationCase,
) -> tuple[EvidenceRequirement, ...]:
    """Reject undeclared evidence before publishing a hosted dataset row."""
    requirements = case.get("required_evidence")
    if not requirements:
        raise ValueError(
            f"case {case['case_id']} must declare at least one evidence requirement"
        )
    return requirements


def _required_observed_evidence(
    case: EvaluationCase,
) -> tuple[EvidenceRequirement, ...]:
    """Require an explicit observation policy even when absence is allowed."""
    requirements = case.get("required_observed_evidence")
    if not isinstance(requirements, tuple):
        raise ValueError(
            f"case {case['case_id']} must declare required_observed_evidence"
        )
    return requirements


def sync_mlflow_dataset(cases: tuple[EvaluationCase, ...], experiment_id: str):
    from mlflow.genai.datasets import create_dataset, search_datasets

    existing = search_datasets(
        experiment_ids=[experiment_id], filter_string=f"name = '{DATASET_NAME}'"
    )
    if len(existing) > 1:
        raise RuntimeError(f"multiple MLflow datasets named {DATASET_NAME}")
    if existing:
        dataset = existing[0]
    else:
        create_dataset(
            name=DATASET_NAME,
            experiment_id=[experiment_id],
        )
        created = search_datasets(
            experiment_ids=[experiment_id],
            filter_string=f"name = '{DATASET_NAME}'",
        )
        if len(created) != 1:
            raise RuntimeError(f"could not reload dataset named {DATASET_NAME}")
        dataset = created[0]
    replace_dataset_records(dataset, cases)
    return dataset


def replace_dataset_records(dataset: Any, cases: tuple[EvaluationCase, ...]) -> None:
    """Replace hosted rows so removed local cases cannot remain evaluable."""
    existing_records = dataset.to_df()
    existing_record_ids = (
        existing_records["dataset_record_id"].tolist()
        if "dataset_record_id" in existing_records
        else []
    )
    if existing_record_ids:
        dataset.delete_records(existing_record_ids)
    _prepare_empty_dataset(dataset)
    dataset.merge_records(mlflow_records(cases))


def _prepare_empty_dataset(dataset: Any) -> None:
    """Work around MLflow 3.14 treating a loaded empty cache as one record."""
    mlflow_dataset = getattr(dataset, "_mlflow_dataset", None)
    if mlflow_dataset is None:
        return
    if mlflow_dataset.records == []:
        mlflow_dataset._records = None
