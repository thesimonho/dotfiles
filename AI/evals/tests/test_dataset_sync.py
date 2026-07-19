"""Behavior tests for exact MLflow evaluation dataset synchronization."""

import sys
import unittest
from pathlib import Path

LIB_DIR = Path(__file__).resolve().parents[1] / "lib"
sys.path.insert(0, str(LIB_DIR))

import dataset_sync  # noqa: E402


class DatasetSyncTests(unittest.TestCase):
    """Verify the hosted dataset exactly mirrors the configured cases."""

    def test_replaces_existing_records_before_merging_configured_cases(self):
        dataset = FakeDataset(["record-1", "record-2"])

        dataset_sync.replace_dataset_records(
            dataset,
            ({"prompt": "2+2", "tier": "deterministic"},),
        )

        self.assertEqual(dataset.deleted_record_ids, ["record-1", "record-2"])
        self.assertEqual(
            dataset.merged_records,
            [
                {
                    "inputs": {"prompt": "2+2"},
                    "expectations": {"tier": "deterministic"},
                }
            ],
        )


class FakeDataset:
    """Small dataset double exposing the MLflow replacement surface."""

    def __init__(self, record_ids):
        self._record_ids = record_ids
        self.deleted_record_ids = []
        self.merged_records = []

    def to_df(self):
        return {"dataset_record_id": FakeColumn(self._record_ids)}

    def delete_records(self, record_ids):
        self.deleted_record_ids.extend(record_ids)

    def merge_records(self, records):
        self.merged_records.extend(records)


class FakeColumn:
    """Pandas-column-shaped record ID container."""

    def __init__(self, values):
        self._values = values

    def tolist(self):
        return list(self._values)


if __name__ == "__main__":
    unittest.main()
