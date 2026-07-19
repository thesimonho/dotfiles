"""Push the git-tracked cases into MLflow's hosted evaluation dataset."""

from harness_identity import EVALUATION_DATASET_NAME

DATASET_NAME = EVALUATION_DATASET_NAME


def mlflow_records(cases):
    return [
        {
            "inputs": {"prompt": case["prompt"]},
            "expectations": {k: v for k, v in case.items() if k != "prompt"},
        }
        for case in cases
    ]


def sync_mlflow_dataset(cases, experiment_id):
    from mlflow.genai.datasets import create_dataset, search_datasets

    existing = search_datasets(
        experiment_ids=[experiment_id], filter_string=f"name = '{DATASET_NAME}'"
    )
    if len(existing) > 1:
        raise RuntimeError(f"multiple MLflow datasets named {DATASET_NAME}")
    dataset = (
        existing[0]
        if existing
        else create_dataset(
            name=DATASET_NAME,
            experiment_id=[experiment_id],
        )
    )
    replace_dataset_records(dataset, cases)
    return dataset


def replace_dataset_records(dataset, cases) -> None:
    """Replace hosted rows so removed local cases cannot remain evaluable."""
    existing_records = dataset.to_df()
    existing_record_ids = (
        existing_records["dataset_record_id"].tolist()
        if "dataset_record_id" in existing_records
        else []
    )
    if existing_record_ids:
        dataset.delete_records(existing_record_ids)
    dataset.merge_records(mlflow_records(cases))
