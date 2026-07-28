"""Readable MLflow trace previews for evaluation list views."""

import mlflow


def update_trace_preview(
    *,
    metadata: dict[str, str] | None = None,
    request_preview: str | None = None,
    response_preview: str | None = None,
) -> None:
    """Update list-view text only when MLflow has opened a trace span."""
    if mlflow.get_current_active_span() is None:
        return
    if request_preview is not None:
        mlflow.update_current_trace(
            metadata=metadata,
            request_preview=request_preview,
        )
    if response_preview is not None:
        mlflow.update_current_trace(response_preview=response_preview)
