"""Publish complete agent configurations through MLflow Prompt Registry."""

from __future__ import annotations

import hashlib
import time
from collections.abc import Callable
from typing import Any

from configuration_components import ConfigComponent
from configuration_manifest import (
    RegisteredComponent,
    build_manifest,
    compare_manifests,
    manifest_from_content,
)
from configuration_publication import ConfigurationPublication
from harness_identity import manifest_prompt_name
from mlflow_configuration_evidence import (
    CHANGES_ARTIFACT_PATH,
    DESCRIPTION_TAG,
    MANIFEST_ARTIFACT_PATH,
    configuration_description,
)
from mlflow_parameter_names import AGENT_CLI_FIELD, component_parameter_name

CONTENT_HASH_TAG = "eval.content_hash"
LAST_EVALUATED_ALIAS = "last-evaluated"
TRACE_LINK_ATTEMPTS = 5
TRACE_LINK_RETRY_SECONDS = 0.2


class MlflowConfigurationRegistry:
    """Resolve atomic components and complete manifests to immutable MLflow prompts."""

    def __init__(
        self,
        client: Any,
        genai: Any,
        profile: str = "claude",
        sleep: Callable[[float], None] = time.sleep,
    ):
        self._client = client
        self._genai = genai
        self._profile = profile
        self._sleep = sleep

    def prepare(
        self,
        components: tuple[ConfigComponent, ...],
        baseline_version: int | None = None,
    ) -> ConfigurationPublication:
        """Publish provenance before agent execution, failing closed on errors."""
        baseline_prompt = self._baseline_manifest_prompt(baseline_version)
        baseline_manifest = (
            manifest_from_content(baseline_prompt.template) if baseline_prompt else None
        )
        baseline_components = _components_by_id(baseline_manifest)
        registered_components = []
        for component in components:
            baseline_component = baseline_components.get(component.component_id)
            if _can_reuse_baseline_component(component, baseline_component):
                assert baseline_component is not None
                registered_components.append(
                    _registered_from_baseline(component, baseline_component)
                )
                continue
            prompt = self._register_component(component)
            registered_components.append(_registered_component(component, prompt))
        manifest = build_manifest(self._profile, registered_components)
        changes = compare_manifests(baseline_manifest, manifest)
        if baseline_prompt and baseline_prompt.template == manifest.content:
            manifest_prompt = baseline_prompt
        else:
            manifest_prompt = self._register_or_reuse_prompt(
                name=_manifest_prompt_name(self._profile),
                content=manifest.content,
                content_hash=_content_hash(manifest.content),
                component_id=f"config-set/{self._profile}",
                commit_message=_commit_message(changes.summary),
                extra_tags={"eval.manifest_id": manifest.manifest_id},
            )
        return ConfigurationPublication(
            manifest=manifest,
            manifest_prompt=manifest_prompt,
            changes=changes,
            baseline_prompt_version=getattr(baseline_prompt, "version", None),
        )

    def attach_to_run(
        self,
        run_id: str,
        publication: ConfigurationPublication,
        expected_trace_count: int | None = None,
    ) -> None:
        """Make configuration provenance visible from the completed evaluation run."""
        self._client.log_param(
            run_id,
            AGENT_CLI_FIELD,
            publication.manifest.profile,
        )
        prompt_versions = self._prompt_versions_for_publication(publication)
        for prompt_version in prompt_versions:
            self._client.link_prompt_version_to_run(run_id, prompt_version)
        for component in publication.manifest.components:
            parameter_name = component_parameter_name(component.component_id)
            self._client.log_param(run_id, parameter_name, component.prompt_reference)
        self._client.log_param(
            run_id,
            "config.manifest",
            publication.run_metadata["config_manifest_prompt"],
        )
        for key, value in publication.run_metadata.items():
            tag_value = value[:5000] if key == "config_changes" else value
            self._client.set_tag(run_id, _tag_name(key), tag_value)
        self._client.set_tag(
            run_id,
            DESCRIPTION_TAG,
            configuration_description(publication),
        )
        self._client.set_tag(
            run_id,
            "mlflow.runName",
            _run_name(self._profile, publication),
        )
        self._client.log_dict(
            run_id,
            publication.manifest.to_dict(),
            MANIFEST_ARTIFACT_PATH,
        )
        self._client.log_text(
            run_id,
            publication.changes.summary,
            CHANGES_ARTIFACT_PATH,
        )
        self._link_prompts_to_traces(
            run_id,
            prompt_versions,
            expected_trace_count,
        )
        self._client.set_prompt_alias(
            publication.manifest_prompt.name,
            LAST_EVALUATED_ALIAS,
            publication.manifest_prompt.version,
        )

    def _link_prompts_to_traces(
        self,
        run_id: str,
        prompt_versions: list[Any],
        expected_trace_count: int | None,
    ) -> None:
        experiment_id = self._client.get_run(run_id).info.experiment_id
        traces: list[Any] = []
        for attempt in range(TRACE_LINK_ATTEMPTS):
            traces = self._run_traces(run_id, experiment_id)
            if expected_trace_count is None or len(traces) == expected_trace_count:
                for trace in traces:
                    self._client.link_prompt_versions_to_trace(
                        prompt_versions,
                        trace.info.trace_id,
                    )
                return
            if attempt < TRACE_LINK_ATTEMPTS - 1:
                self._sleep(TRACE_LINK_RETRY_SECONDS)
        raise RuntimeError(
            "MLflow trace indexing did not expose the expected evaluation traces: "
            f"expected {expected_trace_count}, found {len(traces)}"
        )

    def _prompt_versions_for_publication(
        self,
        publication: ConfigurationPublication,
    ) -> list[Any]:
        prompt_versions = [publication.manifest_prompt]
        prompt_versions.extend(
            self._client.get_prompt_version(
                component.prompt_name,
                component.prompt_version,
            )
            for component in publication.manifest.components
        )
        return prompt_versions

    def _run_traces(self, run_id: str, experiment_id: str) -> list[Any]:
        traces = []
        page_token = None
        is_first_page = True
        while True:
            page = self._client.search_traces(
                locations=[experiment_id],
                run_id=run_id,
                max_results=100,
                page_token=page_token,
                include_spans=False,
                flush=is_first_page,
            )
            traces.extend(page)
            page_token = getattr(page, "token", None)
            if not page_token:
                return traces
            is_first_page = False

    def _register_component(self, component: ConfigComponent):
        return self._register_or_reuse_prompt(
            name=component.registry_name,
            content=component.content,
            content_hash=component.content_hash,
            component_id=component.component_id,
            commit_message=f"Update {component.component_id}",
            extra_tags={"eval.source_paths": ",".join(component.source_paths)},
        )

    def _register_or_reuse_prompt(
        self,
        *,
        name: str,
        content: str,
        content_hash: str,
        component_id: str,
        commit_message: str,
        extra_tags: dict[str, str],
    ):
        for prompt in self._prompt_versions(name):
            if getattr(prompt, "tags", {}).get(CONTENT_HASH_TAG) == content_hash:
                return prompt
        tags = {
            CONTENT_HASH_TAG: content_hash,
            "eval.component_id": component_id,
            **extra_tags,
        }
        return self._genai.register_prompt(
            name=name,
            template=content,
            commit_message=commit_message,
            tags=tags,
        )

    def _baseline_manifest_prompt(self, baseline_version: int | None):
        manifest_prompt_name = _manifest_prompt_name(self._profile)
        if baseline_version is not None:
            return self._client.get_prompt_version(
                manifest_prompt_name, baseline_version
            )
        try:
            return self._client.get_prompt_version_by_alias(
                manifest_prompt_name,
                LAST_EVALUATED_ALIAS,
            )
        except Exception as error:
            if getattr(error, "error_code", None) == "RESOURCE_DOES_NOT_EXIST":
                return None
            raise

    def _prompt_versions(self, name: str) -> tuple[Any, ...]:
        versions = []
        page_token = None
        while True:
            try:
                page = self._client.search_prompt_versions(
                    name=name,
                    max_results=1000,
                    page_token=page_token,
                )
            except Exception as error:
                if getattr(error, "error_code", None) == "RESOURCE_DOES_NOT_EXIST":
                    return ()
                raise
            versions.extend(page)
            page_token = getattr(page, "token", None)
            if not page_token:
                return tuple(versions)


def _registered_component(
    component: ConfigComponent, prompt: Any
) -> RegisteredComponent:
    return RegisteredComponent(
        component_id=component.component_id,
        content_hash=component.content_hash,
        prompt_name=prompt.name,
        prompt_version=int(prompt.version),
        prompt_reference=str(prompt.uri),
        source_paths=component.source_paths,
    )


def _components_by_id(manifest) -> dict[str, RegisteredComponent]:
    if manifest is None:
        return {}
    return {component.component_id: component for component in manifest.components}


def _can_reuse_baseline_component(
    component: ConfigComponent,
    baseline_component: RegisteredComponent | None,
) -> bool:
    return bool(
        baseline_component
        and baseline_component.content_hash == component.content_hash
        and baseline_component.prompt_name == component.registry_name
    )


def _registered_from_baseline(
    component: ConfigComponent,
    baseline_component: RegisteredComponent,
) -> RegisteredComponent:
    return RegisteredComponent(
        component_id=component.component_id,
        content_hash=component.content_hash,
        prompt_name=baseline_component.prompt_name,
        prompt_version=baseline_component.prompt_version,
        prompt_reference=baseline_component.prompt_reference,
        source_paths=component.source_paths,
    )


def _tag_name(metadata_key: str) -> str:
    suffix = metadata_key.removeprefix("config_")
    return f"eval.config.{suffix}"


def _run_name(profile: str, publication: ConfigurationPublication) -> str:
    manifest_version = publication.manifest_prompt.version
    return f"{profile}-manifest-v{manifest_version} - {_change_label(publication)}"


def _change_label(publication: ConfigurationPublication) -> str:
    changes = publication.changes
    if changes.modified:
        assert changes.baseline is not None
        component_id = changes.modified[0]
        baseline_components = {
            component.component_id: component
            for component in changes.baseline.components
        }
        current_components = {
            component.component_id: component
            for component in changes.current.components
        }
        component_name = component_id.removeprefix("instruction/")
        baseline_version = baseline_components[component_id].prompt_version
        current_version = current_components[component_id].prompt_version
        return f"{component_name} v{baseline_version} -> v{current_version}"
    if changes.baseline is None:
        return "initial configuration"
    change_count = len(changes.added) + len(changes.removed)
    if change_count:
        return f"{change_count} structural changes"
    return "no configuration changes"


def _content_hash(content: str) -> str:
    return hashlib.sha256(content.encode()).hexdigest()


def _commit_message(summary: str) -> str:
    return summary.replace("\n", "; ")[:500]


def _manifest_prompt_name(profile: str) -> str:
    return manifest_prompt_name(profile)
