"""Resolve MLflow Agent Versions from complete configuration manifests."""

from __future__ import annotations

from datetime import UTC, date, datetime
from typing import Any, Callable

from configuration_publication import ConfigurationPublication
from mlflow_configuration_evidence import (
    DESCRIPTION_TAG,
    agent_version_description,
    upload_model_manifest_artifact,
)
from mlflow_parameter_names import AGENT_CLI_FIELD, component_parameter_name


class MlflowAgentVersionRegistry:
    """Create or reuse Agent Versions using profile and manifest identity."""

    def __init__(
        self,
        client: Any,
        mlflow_api: Any,
        today: Callable[[], date] | None = None,
    ):
        self._client = client
        self._mlflow = mlflow_api
        self._today = today or _utc_today

    def resolve(
        self,
        publication: ConfigurationPublication,
        experiment_id: str,
    ) -> Any:
        """Return the Agent Version for this complete configuration."""
        for model in self._models(experiment_id, publication):
            if _matches(publication, model):
                return model
        model_name = self._available_model_name(
            experiment_id,
            publication,
            self._today(),
        )
        model = self._mlflow.create_external_model(
            name=model_name,
            experiment_id=experiment_id,
            model_type="agent",
            params=_model_parameters(publication),
            tags={
                "eval.manifest_id": publication.manifest.manifest_id,
                "eval.configuration_scope": "configuration-components",
            },
        )
        self._link_prompts(publication, model.model_id)
        return model

    def publish_configuration_evidence(
        self,
        publication: ConfigurationPublication,
        model: Any,
    ) -> None:
        """Publish immutable evidence once, after an evaluation succeeds."""
        if DESCRIPTION_TAG in (getattr(model, "tags", None) or {}):
            return
        self._client.set_logged_model_tags(
            model.model_id,
            {DESCRIPTION_TAG: agent_version_description(publication)},
        )
        upload_model_manifest_artifact(self._client, model.model_id, publication)

    def _link_prompts(
        self,
        publication: ConfigurationPublication,
        model_id: str,
    ) -> None:
        self._client.link_prompt_version_to_model(
            publication.manifest_prompt.name,
            str(publication.manifest_prompt.version),
            model_id,
        )
        for component in publication.manifest.components:
            self._client.link_prompt_version_to_model(
                component.prompt_name,
                str(component.prompt_version),
                model_id,
            )

    def _available_model_name(
        self,
        experiment_id: str,
        publication: ConfigurationPublication,
        creation_date: date,
    ) -> str:
        for prefix_length in (8, 12, 16, 64):
            candidate = _model_name(publication, creation_date, prefix_length)
            page = self._client.search_logged_models(
                [experiment_id],
                filter_string=f"name = '{candidate}'",
                max_results=1,
            )
            if not page:
                return candidate
        raise RuntimeError("could not create a unique Agent Version display name")

    def _models(
        self,
        experiment_id: str,
        publication: ConfigurationPublication,
    ) -> tuple[Any, ...]:
        models = []
        page_token = None
        profile = publication.manifest.profile
        manifest_id = publication.manifest.manifest_id
        filter_string = (
            f"params.`{AGENT_CLI_FIELD}` = '{profile}' AND "
            f"params.`config.manifest_id` = '{manifest_id}'"
        )
        while True:
            page = self._client.search_logged_models(
                [experiment_id],
                filter_string=filter_string,
                max_results=1000,
                page_token=page_token,
            )
            models.extend(page)
            page_token = getattr(page, "token", None)
            if not page_token:
                return tuple(models)


def _matches(
    publication: ConfigurationPublication,
    model: Any,
) -> bool:
    return bool(
        model.params.get(AGENT_CLI_FIELD) == publication.manifest.profile
        and model.params.get("config.manifest_id") == publication.manifest.manifest_id
    )


def _model_parameters(publication: ConfigurationPublication) -> dict[str, str]:
    parameters = {
        AGENT_CLI_FIELD: publication.manifest.profile,
        "config.manifest_id": publication.manifest.manifest_id,
        "config.manifest_prompt": str(publication.manifest_prompt.uri),
    }
    for component in publication.manifest.components:
        parameter_name = component_parameter_name(component.component_id)
        parameters[parameter_name] = component.prompt_reference
    return parameters


def _model_name(
    publication: ConfigurationPublication,
    creation_date: date,
    manifest_prefix_length: int = 8,
) -> str:
    """Build a readable display name without weakening full-hash identity."""
    profile = publication.manifest.profile
    manifest_prefix = publication.manifest.manifest_id[:manifest_prefix_length]
    return f"{profile}-{creation_date:%Y%m%d}-{manifest_prefix}"


def _utc_today() -> date:
    """Return the UTC date used in newly created Agent Version names."""
    return datetime.now(UTC).date()
