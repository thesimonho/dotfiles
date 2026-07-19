"""Behavior tests for resetting only the local MLflow eval harness."""

import sys
import unittest
from pathlib import Path
from types import SimpleNamespace

LIB_DIR = Path(__file__).resolve().parents[1] / "lib"
sys.path.insert(0, str(LIB_DIR))

from mlflow_harness_reset import reset_local_harness  # noqa: E402


class MlflowHarnessResetTests(unittest.TestCase):
    """Verify cleanup stays inside the harness ownership boundary."""

    def test_treats_a_missing_experiment_as_already_clean(self):
        client = FakeResetClient(has_harness_experiment=False)

        report = reset_local_harness(client)

        self.assertEqual(report.deleted_trace_ids, ())
        self.assertEqual(report.deleted_run_ids, ())
        self.assertEqual(report.deleted_model_ids, ())
        self.assertEqual(report.deleted_dataset_ids, ())
        self.assertEqual(report.deleted_prompt_names, ())
        self.assertEqual(client.deleted_resources, [])

    def test_deletes_only_exact_harness_resources(self):
        client = FakeResetClient()

        report = reset_local_harness(client)

        self.assertEqual(report.deleted_trace_ids, ("trace-harness",))
        self.assertEqual(report.deleted_run_ids, ("run-harness",))
        self.assertEqual(report.deleted_model_ids, ("model-harness",))
        self.assertEqual(report.deleted_dataset_ids, ("dataset-harness",))
        self.assertEqual(
            report.deleted_prompt_names,
            ("agent-harness--instruction--workflow",),
        )
        self.assertEqual(client.trace_ids, {"trace-other"})
        self.assertEqual(client.run_ids, {"run-other"})
        self.assertEqual(client.model_ids, {"model-other"})
        self.assertEqual(client.dataset_ids, {"dataset-other"})
        self.assertEqual(client.prompt_names, {"another-project--prompt"})
        self.assertEqual(client.trace_search_page_sizes, [100, 100])

    def test_refuses_to_delete_a_dataset_shared_with_another_experiment(self):
        client = FakeResetClient(dataset_experiment_ids=("experiment-harness", "other"))

        with self.assertRaisesRegex(ValueError, "shared with another experiment"):
            reset_local_harness(client)

        self.assertEqual(client.deleted_resources, [])

    def test_refuses_to_delete_a_prompt_shared_with_another_experiment(self):
        client = FakeResetClient(prompt_experiment_ids=("experiment-harness", "other"))

        with self.assertRaisesRegex(ValueError, "prompt .* shared"):
            reset_local_harness(client)

        self.assertEqual(client.deleted_resources, [])

    def test_rejects_nonlocal_tracking_servers(self):
        client = FakeResetClient()
        client.tracking_uri = "https://mlflow.example.com"
        with self.assertRaisesRegex(ValueError, "local MLflow server"):
            reset_local_harness(client)


class FakeResetClient:
    """Minimal MLflow client with harness and unrelated resources."""

    def __init__(
        self,
        dataset_experiment_ids=("experiment-harness",),
        prompt_experiment_ids=("experiment-harness",),
        has_harness_experiment=True,
    ):
        self.tracking_uri = "http://localhost:5000"
        self.trace_ids = {"trace-harness", "trace-other"}
        self.run_ids = {"run-harness", "run-other"}
        self.model_ids = {"model-harness", "model-other"}
        self.dataset_ids = {"dataset-harness", "dataset-other"}
        self.prompt_names = {
            "agent-harness--instruction--workflow",
            "another-project--prompt",
        }
        self.dataset_experiment_ids = dataset_experiment_ids
        self.prompt_experiment_ids = prompt_experiment_ids
        self.has_harness_experiment = has_harness_experiment
        self.deleted_resources = []
        self.trace_search_page_sizes = []

    def get_experiment_by_name(self, name):
        if name == "agent-harness-evals" and self.has_harness_experiment:
            return SimpleNamespace(experiment_id="experiment-harness")
        return None

    def search_traces(self, locations, **kwargs):
        if locations != ["experiment-harness"]:
            raise AssertionError(f"unexpected trace locations: {locations!r}")
        self.trace_search_page_sizes.append(kwargs["max_results"])
        if kwargs["include_spans"] is not False:
            raise AssertionError("reset trace inventory must exclude span payloads")
        trace_ids = self.trace_ids & {"trace-harness"}
        return FakePage(
            [
                SimpleNamespace(info=SimpleNamespace(trace_id=value))
                for value in trace_ids
            ]
        )

    def search_runs(self, experiment_ids, **kwargs):
        run_ids = self.run_ids & {"run-harness"}
        return FakePage(
            [SimpleNamespace(info=SimpleNamespace(run_id=value)) for value in run_ids]
        )

    def search_logged_models(self, experiment_ids, **kwargs):
        model_ids = self.model_ids & {"model-harness"}
        return FakePage(
            [
                SimpleNamespace(
                    model_id=value,
                    experiment_id="experiment-harness",
                )
                for value in model_ids
            ]
        )

    def search_datasets(self, experiment_ids, **kwargs):
        if "dataset-harness" not in self.dataset_ids:
            return FakePage([])
        return FakePage(
            [
                SimpleNamespace(
                    dataset_id="dataset-harness",
                    name="agent-harness-cases",
                    experiment_ids=list(self.dataset_experiment_ids),
                )
            ]
        )

    def search_prompts(self, **kwargs):
        prompts = []
        for value in sorted(self.prompt_names):
            experiment_ids = (
                self.prompt_experiment_ids
                if value.startswith("agent-harness--")
                else ("other",)
            )
            tags = {"_mlflow_experiment_ids": f",{','.join(experiment_ids)},"}
            prompts.append(SimpleNamespace(name=value, tags=tags))
        return FakePage(prompts)

    def delete_traces(self, experiment_id, trace_ids):
        for trace_id in trace_ids:
            self.trace_ids.remove(trace_id)
            self.deleted_resources.append(("trace", trace_id))
        return len(trace_ids)

    def delete_run(self, run_id):
        self.run_ids.remove(run_id)
        self.deleted_resources.append(("run", run_id))

    def delete_logged_model(self, model_id):
        self.model_ids.remove(model_id)
        self.deleted_resources.append(("model", model_id))

    def delete_dataset(self, dataset_id):
        self.dataset_ids.remove(dataset_id)
        self.deleted_resources.append(("dataset", dataset_id))

    def delete_prompt(self, name):
        self.prompt_names.remove(name)
        self.deleted_resources.append(("prompt", name))


class FakePage(list):
    """List-compatible MLflow result page without continuation."""

    token = None


if __name__ == "__main__":
    unittest.main()
