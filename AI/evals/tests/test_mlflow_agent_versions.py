"""Behavior tests for manifest-derived MLflow Agent Versions."""

import json
import sys
import unittest
from dataclasses import replace
from datetime import date
from pathlib import Path
from types import SimpleNamespace

LIB_DIR = Path(__file__).resolve().parents[1] / "lib"
sys.path.insert(0, str(LIB_DIR))

from configuration_manifest import (  # noqa: E402
    RegisteredComponent,
    build_manifest,
    compare_manifests,
)
from configuration_publication import ConfigurationPublication  # noqa: E402
from mlflow_agent_versions import MlflowAgentVersionRegistry  # noqa: E402
from mlflow_parameter_names import component_parameter_name  # noqa: E402


class MlflowAgentVersionRegistryTests(unittest.TestCase):
    """Verify complete manifest identity controls Agent Version reuse."""

    def test_reuses_the_agent_version_with_the_same_profile_and_manifest_hash(self):
        publication = _publication("codex", "prompts:/fragment/1")
        existing_model = SimpleNamespace(
            model_id="model-existing",
            name="codex-20260718-oldname",
            params={
                "agent.cli": "codex",
                "config.manifest_id": publication.manifest.manifest_id,
            },
            tags={},
        )
        client = FakeAgentVersionClient([existing_model])
        mlflow_api = FakeMlflowApi()
        registry = MlflowAgentVersionRegistry(
            client,
            mlflow_api,
            today=lambda: date(2026, 7, 19),
        )

        resolved_model = registry.resolve(publication, "experiment-1")

        self.assertIs(resolved_model, existing_model)
        self.assertEqual(mlflow_api.created_models, [])
        self.assertIn("params.`agent.cli` = 'codex'", client.search_filters[0])
        self.assertIn(
            f"params.`config.manifest_id` = '{publication.manifest.manifest_id}'",
            client.search_filters[0],
        )
        self.assertEqual(
            client.model_prompt_links,
            [],
        )
        self.assertEqual(client.model_tags, {})
        self.assertEqual(client.model_artifacts, {})

    def test_creates_an_agent_version_with_complete_manifest_lineage(self):
        publication = _publication("codex", "prompts:/fragment/3")
        client = FakeAgentVersionClient()
        mlflow_api = FakeMlflowApi()
        registry = MlflowAgentVersionRegistry(
            client,
            mlflow_api,
            today=lambda: date(2026, 7, 19),
        )

        resolved_model = registry.resolve(publication, "experiment-1")

        self.assertEqual(resolved_model.model_id, "model-created")
        created_model = mlflow_api.created_models[0]
        expected_name = f"codex-20260719-{publication.manifest.manifest_id[:8]}"
        self.assertEqual(created_model["name"], expected_name)
        self.assertEqual(created_model["model_type"], "agent")
        self.assertEqual(created_model["experiment_id"], "experiment-1")
        self.assertEqual(
            created_model["params"]["config.manifest_id"],
            publication.manifest.manifest_id,
        )
        self.assertEqual(created_model["params"]["agent.cli"], "codex")
        self.assertNotIn("eval.profile", created_model["tags"])
        self.assertNotIn("agent.cli", created_model["tags"])
        self.assertEqual(
            created_model["params"][component_parameter_name("instruction/workflow")],
            "prompts:/fragment/3",
        )
        self.assertEqual(
            client.model_prompt_links,
            [
                ("agent-harness--codex--manifest", "1", "model-created"),
                ("fragment", "1", "model-created"),
            ],
        )

    def test_publishes_immutable_configuration_evidence_after_evaluation(self):
        publication = _publication("codex", "prompts:/fragment/3")
        client = FakeAgentVersionClient()
        registry = MlflowAgentVersionRegistry(
            client,
            FakeMlflowApi(),
            today=lambda: date(2026, 7, 19),
        )

        model = registry.resolve(publication, "experiment-1")
        registry.publish_configuration_evidence(publication, model)

        description = client.model_tags["model-created"]["mlflow.note.content"]
        self.assertIn("## Agent configuration", description)
        self.assertIn(publication.manifest_prompt.uri, description)
        self.assertIn("instruction/workflow", description)
        self.assertIn("prompts:/fragment/3", description)
        self.assertNotIn("Changes from baseline", description)

    def test_uploads_only_the_immutable_manifest_to_created_version(self):
        publication = _publication("codex", "prompts:/fragment/3")
        client = FakeAgentVersionClient()
        registry = MlflowAgentVersionRegistry(
            client,
            FakeMlflowApi(),
            today=lambda: date(2026, 7, 19),
        )

        model = registry.resolve(publication, "experiment-1")
        registry.publish_configuration_evidence(publication, model)

        artifacts = client.model_artifacts["model-created"]
        self.assertEqual(
            json.loads(artifacts["configuration/manifest.json"]),
            publication.manifest.to_dict(),
        )
        self.assertNotIn("configuration/changes.txt", artifacts)

    def test_does_not_overwrite_existing_agent_version_evidence(self):
        publication = _publication("codex", "prompts:/fragment/1")
        existing_model = SimpleNamespace(
            model_id="model-existing",
            name="codex-20260718-oldname",
            params={
                "agent.cli": "codex",
                "config.manifest_id": publication.manifest.manifest_id,
            },
            tags={"mlflow.note.content": "already published"},
        )
        client = FakeAgentVersionClient([existing_model])
        registry = MlflowAgentVersionRegistry(client, FakeMlflowApi())

        registry.publish_configuration_evidence(publication, existing_model)

        self.assertEqual(client.model_tags, {})
        self.assertEqual(client.model_artifacts, {})

    def test_expands_the_hash_prefix_when_a_display_name_collides(self):
        publication = _publication("codex", "prompts:/fragment/3")
        publication = replace(
            publication,
            manifest=replace(
                publication.manifest,
                manifest_id="12345678aaaabbbb" + "c" * 48,
            ),
        )
        colliding_model = SimpleNamespace(
            model_id="model-collision",
            name="codex-20260719-12345678",
            params={
                "agent.cli": "codex",
                "config.manifest_id": "12345678dddd" + "e" * 52,
            },
            tags={},
        )
        client = FakeAgentVersionClient([colliding_model])
        mlflow_api = FakeMlflowApi()
        registry = MlflowAgentVersionRegistry(
            client,
            mlflow_api,
            today=lambda: date(2026, 7, 19),
        )

        registry.resolve(publication, "experiment-1")

        self.assertEqual(
            mlflow_api.created_models[0]["name"],
            "codex-20260719-12345678aaaa",
        )


def _publication(profile: str, prompt_reference: str) -> ConfigurationPublication:
    component = RegisteredComponent(
        component_id="instruction/workflow",
        content_hash="hash-workflow",
        prompt_name="fragment",
        prompt_version=1,
        prompt_reference=prompt_reference,
        source_paths=("AI/instructions/fragments/workflow.md",),
    )
    manifest = build_manifest(profile, [component])
    manifest_prompt = SimpleNamespace(
        name=f"agent-harness--{profile}--manifest",
        version=1,
        uri=f"prompts:/agent-harness--{profile}--manifest/1",
    )
    return ConfigurationPublication(
        manifest=manifest,
        manifest_prompt=manifest_prompt,
        changes=compare_manifests(None, manifest),
        baseline_prompt_version=None,
    )


class FakeAgentVersionClient:
    """Minimal LoggedModel and prompt-link client."""

    def __init__(self, models=()):
        self.models = list(models)
        self.model_prompt_links = []
        self.model_artifacts = {}
        self.model_tags = {}
        self.search_filters = []

    def search_logged_models(self, experiment_ids, **kwargs):
        filter_string = kwargs.get("filter_string", "")
        self.search_filters.append(filter_string)
        if filter_string.startswith("name = '"):
            name = filter_string.removeprefix("name = '").removesuffix("'")
            return [model for model in self.models if model.name == name]
        return [
            model
            for model in self.models
            if model.params.get("agent.cli") in filter_string
            and model.params.get("config.manifest_id") in filter_string
        ]

    def link_prompt_version_to_model(self, name, version, model_id):
        self.model_prompt_links.append((name, version, model_id))

    def set_logged_model_tags(self, model_id, tags):
        self.model_tags[model_id] = tags

    def log_model_artifacts(self, model_id, local_dir):
        root = Path(local_dir)
        self.model_artifacts[model_id] = {
            path.relative_to(root).as_posix(): path.read_text()
            for path in root.rglob("*")
            if path.is_file()
        }


class FakeMlflowApi:
    """Minimal external-model creation API."""

    def __init__(self):
        self.created_models = []

    def create_external_model(self, **kwargs):
        self.created_models.append(kwargs)
        return SimpleNamespace(model_id="model-created", **kwargs)


if __name__ == "__main__":
    unittest.main()
