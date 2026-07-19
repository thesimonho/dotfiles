"""Behavior tests for publishing configuration versions to MLflow."""

import json
import sys
import unittest
from pathlib import Path
from types import SimpleNamespace

LIB_DIR = Path(__file__).resolve().parents[1] / "lib"
sys.path.insert(0, str(LIB_DIR))

from configuration_components import ConfigComponent  # noqa: E402
from mlflow_config_registry import MlflowConfigurationRegistry  # noqa: E402


class MlflowConfigurationRegistryTests(unittest.TestCase):
    """Verify MLflow prompt reuse, publication, and run association."""

    def test_reuses_historical_content_and_links_complete_configuration_to_run(self):
        component = _component("instruction/workflow", "original", "hash-original")
        reverted_prompt = _prompt(component, version=1)
        later_prompt = _prompt(
            _component("instruction/workflow", "later", "hash-later"),
            version=2,
        )
        client = FakeMlflowClient(
            prompt_versions={component.registry_name: [later_prompt, reverted_prompt]}
        )
        genai = FakeMlflowGenai(client)
        registry = MlflowConfigurationRegistry(client, genai)

        publication = registry.prepare((component,))
        registry.attach_to_run("run-1", publication)

        self.assertEqual(publication.manifest.components[0].prompt_version, 1)
        self.assertEqual(genai.created_prompts, ["agent-harness--claude--manifest"])
        self.assertEqual(client.params["agent.cli"], "claude")
        self.assertNotIn("agent.cli", client.tags)
        self.assertNotIn("eval.cli", client.tags)
        self.assertNotIn("eval.profile", client.tags)
        linked_run_prompts = [prompt for _, prompt in client.run_links]
        self.assertEqual(
            linked_run_prompts[0].name,
            "agent-harness--claude--manifest",
        )
        self.assertEqual(linked_run_prompts[1:], [reverted_prompt])
        self.assertIn(reverted_prompt.uri, client.params.values())
        self.assertEqual(
            client.tags["eval.config.manifest_id"], publication.manifest.manifest_id
        )
        self.assertIn("instruction/workflow", client.tags["mlflow.note.content"])
        self.assertIn(reverted_prompt.uri, client.tags["mlflow.note.content"])
        self.assertIn("configuration/manifest.json", client.logged_dicts)

    def test_uses_explicit_manifest_version_as_comparison_baseline(self):
        old_component = _component("instruction/workflow", "old", "hash-old")
        new_component = _component("instruction/workflow", "new", "hash-new")
        old_prompt = _prompt(old_component, version=1)
        new_prompt = _prompt(new_component, version=2)
        baseline_manifest = _manifest_prompt(old_prompt, version=4)
        client = FakeMlflowClient(
            prompt_versions={
                new_component.registry_name: [new_prompt, old_prompt],
                "agent-harness--claude--manifest": [baseline_manifest],
            }
        )
        registry = MlflowConfigurationRegistry(client, FakeMlflowGenai(client))

        publication = registry.prepare((new_component,), baseline_version=4)
        registry.attach_to_run("run-1", publication)

        self.assertEqual(publication.baseline_prompt_version, 4)
        self.assertIn("instruction/workflow: v1 -> v2", publication.changes.summary)
        self.assertEqual(
            client.tags["mlflow.runName"],
            "claude-manifest-v5 - workflow v1 -> v2",
        )
        self.assertIn(
            "instruction/workflow: v1 -> v2", client.tags["mlflow.note.content"]
        )

    def test_uses_last_evaluated_alias_instead_of_newest_published_manifest(self):
        evaluated_component = _component(
            "instruction/workflow", "evaluated", "hash-evaluated"
        )
        failed_component = _component("instruction/workflow", "failed", "hash-failed")
        current_component = _component(
            "instruction/workflow", "current", "hash-current"
        )
        evaluated_prompt = _prompt(evaluated_component, version=1)
        failed_prompt = _prompt(failed_component, version=2)
        current_prompt = _prompt(current_component, version=3)
        evaluated_manifest = _manifest_prompt(evaluated_prompt, version=1)
        failed_manifest = _manifest_prompt(failed_prompt, version=2)
        client = FakeMlflowClient(
            prompt_versions={
                current_component.registry_name: [
                    evaluated_prompt,
                    failed_prompt,
                    current_prompt,
                ],
                "agent-harness--claude--manifest": [
                    evaluated_manifest,
                    failed_manifest,
                ],
            },
            prompt_aliases={
                ("agent-harness--claude--manifest", "last-evaluated"): 1,
            },
        )
        registry = MlflowConfigurationRegistry(client, FakeMlflowGenai(client))

        publication = registry.prepare((current_component,))

        self.assertEqual(publication.baseline_prompt_version, 1)
        self.assertIn("instruction/workflow: v1 -> v3", publication.changes.summary)

    def test_advances_last_evaluated_alias_only_when_attaching_completed_run(self):
        component = _component("instruction/workflow", "new", "hash-new")
        client = FakeMlflowClient()
        registry = MlflowConfigurationRegistry(client, FakeMlflowGenai(client))
        publication = registry.prepare((component,))

        self.assertEqual(client.prompt_aliases, {})

        registry.attach_to_run("run-1", publication)

        self.assertEqual(
            client.prompt_aliases[
                ("agent-harness--claude--manifest", "last-evaluated")
            ],
            publication.manifest_prompt.version,
        )

    def test_links_complete_prompt_objects_to_every_case_trace(self):
        component = _component("instruction/workflow", "new", "hash-new")
        component_prompt = _prompt(component, version=1)
        client = FakeMlflowClient(
            prompt_versions={component.registry_name: [component_prompt]},
            trace_ids=("trace-1", "trace-2"),
        )
        registry = MlflowConfigurationRegistry(client, FakeMlflowGenai(client))
        publication = registry.prepare((component,))

        registry.attach_to_run("run-1", publication)

        expected_prompts = [publication.manifest_prompt, component_prompt]
        self.assertEqual(
            client.trace_prompt_links,
            [
                ("trace-1", expected_prompts),
                ("trace-2", expected_prompts),
            ],
        )

    def test_waits_for_every_expected_trace_before_advancing_the_baseline(self):
        component = _component("instruction/workflow", "new", "hash-new")
        component_prompt = _prompt(component, version=1)
        client = FakeMlflowClient(
            prompt_versions={component.registry_name: [component_prompt]},
            trace_id_batches=((), ("trace-1", "trace-2")),
        )
        registry = MlflowConfigurationRegistry(
            client,
            FakeMlflowGenai(client),
            sleep=lambda _: None,
        )
        publication = registry.prepare((component,))

        registry.attach_to_run("run-1", publication, expected_trace_count=2)

        self.assertEqual(client.trace_search_count, 2)
        self.assertEqual(len(client.trace_prompt_links), 2)
        self.assertIn(
            ("agent-harness--claude--manifest", "last-evaluated"),
            client.prompt_aliases,
        )

    def test_creates_first_versions_when_mlflow_reports_missing_prompt_families(self):
        component = _component("instruction/workflow", "new", "hash-new")
        client = FakeMlflowClient(raise_for_missing_prompts=True)
        registry = MlflowConfigurationRegistry(client, FakeMlflowGenai(client))

        publication = registry.prepare((component,))

        self.assertEqual(publication.manifest.components[0].prompt_version, 1)
        self.assertEqual(
            client.prompt_versions.keys(),
            {component.registry_name, "agent-harness--claude--manifest"},
        )

    def test_names_the_manifest_for_the_selected_agent_profile(self):
        component = _component("settings/codex", "model", "hash-model")
        component = ConfigComponent(
            component_id=component.component_id,
            registry_name="agent-harness--codex--settings--codex",
            content=component.content,
            content_hash=component.content_hash,
            source_paths=component.source_paths,
        )
        client = FakeMlflowClient()
        registry = MlflowConfigurationRegistry(
            client,
            FakeMlflowGenai(client),
            profile="codex",
        )

        publication = registry.prepare((component,))
        registry.attach_to_run("run-1", publication)

        self.assertEqual(publication.manifest.profile, "codex")
        self.assertEqual(client.params["agent.cli"], "codex")
        self.assertEqual(
            publication.manifest_prompt.name, "agent-harness--codex--manifest"
        )


def _component(component_id: str, content: str, content_hash: str) -> ConfigComponent:
    return ConfigComponent(
        component_id=component_id,
        registry_name=f"agent-harness--claude--{component_id.replace('/', '--')}",
        content=content,
        content_hash=content_hash,
        source_paths=(f"{component_id}.md",),
    )


def _prompt(component: ConfigComponent, version: int):
    return SimpleNamespace(
        name=component.registry_name,
        version=version,
        uri=f"prompts:/{component.registry_name}/{version}",
        template=component.content,
        tags={
            "eval.component_id": component.component_id,
            "eval.content_hash": component.content_hash,
        },
    )


def _manifest_prompt(component_prompt, version: int):
    component_id = component_prompt.tags["eval.component_id"]
    payload_without_id = {
        "profile": "claude",
        "schema_version": 1,
        "components": {
            component_id: {
                "content_hash": component_prompt.tags["eval.content_hash"],
                "source_paths": [f"{component_id}.md"],
            }
        },
    }
    import hashlib

    identity_content = json.dumps(payload_without_id, indent=2, sort_keys=True) + "\n"
    manifest_id = hashlib.sha256(identity_content.encode()).hexdigest()
    payload = {
        **payload_without_id,
        "manifest_id": manifest_id,
        "components": {
            component_id: {
                **payload_without_id["components"][component_id],
                "prompt_name": component_prompt.name,
                "prompt_reference": component_prompt.uri,
                "prompt_version": component_prompt.version,
            }
        },
    }
    return SimpleNamespace(
        name="agent-harness--claude--manifest",
        version=version,
        uri=f"prompts:/agent-harness--claude--manifest/{version}",
        template=json.dumps(payload, indent=2, sort_keys=True) + "\n",
        tags={"eval.content_hash": "manifest-hash"},
    )


class FakeMlflowClient:
    def __init__(
        self,
        prompt_versions=None,
        raise_for_missing_prompts=False,
        prompt_aliases=None,
        trace_ids=(),
        trace_id_batches=None,
    ):
        self.prompt_versions = prompt_versions or {}
        self.raise_for_missing_prompts = raise_for_missing_prompts
        self.prompt_aliases = prompt_aliases or {}
        self.trace_ids = trace_ids
        self.trace_id_batches = trace_id_batches
        self.trace_search_count = 0
        self.run_links = []
        self.params = {}
        self.tags = {}
        self.logged_dicts = {}
        self.logged_texts = {}
        self.trace_prompt_links = []

    def search_prompt_versions(self, name, max_results=None, page_token=None):
        if self.raise_for_missing_prompts and name not in self.prompt_versions:
            raise FakeMissingPromptError(f"Prompt with name={name} not found")
        return self.prompt_versions.get(name, [])

    def get_prompt_version(self, name, version):
        return next(
            prompt
            for prompt in self.prompt_versions.get(name, [])
            if prompt.version == int(version)
        )

    def get_prompt_version_by_alias(self, name, alias):
        version = self.prompt_aliases.get((name, alias))
        if version is None:
            raise FakeMissingPromptError(f"Prompt alias {alias} not found")
        return self.get_prompt_version(name, version)

    def set_prompt_alias(self, name, alias, version):
        self.prompt_aliases[(name, alias)] = version

    def search_traces(
        self,
        *,
        locations,
        run_id,
        max_results,
        page_token=None,
        include_spans=False,
        flush=False,
    ):
        selected_trace_ids = self.trace_ids
        if self.trace_id_batches is not None:
            batch_index = min(
                self.trace_search_count,
                len(self.trace_id_batches) - 1,
            )
            selected_trace_ids = self.trace_id_batches[batch_index]
        self.trace_search_count += 1
        traces = [
            SimpleNamespace(info=SimpleNamespace(trace_id=trace_id))
            for trace_id in selected_trace_ids
        ]
        return FakePage(traces)

    def get_run(self, run_id):
        return SimpleNamespace(
            info=SimpleNamespace(experiment_id="experiment-1"),
        )

    def link_prompt_versions_to_trace(self, prompt_versions, trace_id):
        self.trace_prompt_links.append((trace_id, prompt_versions))

    def link_prompt_version_to_run(self, run_id, prompt):
        self.run_links.append((run_id, prompt))

    def log_param(self, run_id, key, value):
        self.params[key] = value

    def set_tag(self, run_id, key, value):
        self.tags[key] = value

    def log_dict(self, run_id, dictionary, artifact_file):
        self.logged_dicts[artifact_file] = dictionary

    def log_text(self, run_id, text, artifact_file):
        self.logged_texts[artifact_file] = text


class FakeMlflowGenai:
    def __init__(self, client):
        self.client = client
        self.created_prompts = []

    def register_prompt(self, name, template, commit_message=None, tags=None):
        self.created_prompts.append(name)
        versions = self.client.prompt_versions.setdefault(name, [])
        prompt = SimpleNamespace(
            name=name,
            version=max((existing.version for existing in versions), default=0) + 1,
            uri=f"prompts:/{name}/{len(versions) + 1}",
            template=template,
            tags=tags or {},
        )
        versions.append(prompt)
        return prompt


class FakeMissingPromptError(RuntimeError):
    """MLflow-compatible not-found error for prompt registry tests."""

    error_code = "RESOURCE_DOES_NOT_EXIST"


class FakePage(list):
    """List-compatible page with no continuation token."""

    token = None


if __name__ == "__main__":
    unittest.main()
