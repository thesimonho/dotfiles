---
agent:
  instruction: Query recorded runs through the MLflow REST API described here. Do not read the SQLite database directly, and do not write a throwaway Python client for a question this file already answers.
  on-change:
    - AI/evals/lib/tracking/**
    - AI/evals/lib/scoring/**
---

# Reading recorded results

Most work on this harness is post-run analysis: comparing an assessment across runs, finding which case dragged a mean down, checking whether a behaviour ever occurred. That is a read-only question about data MLflow already holds, so it belongs to the tracking server's REST API.

Use REST rather than the alternatives. The SQLite file under `infra/compose/data/mlflow` is the server's private storage; reading it couples analysis to a schema MLflow is free to change and bypasses the server's own view of soft-deleted runs. `AI/evals/.venv` exists to run evaluations, and reaching for it to answer a question means activating an environment and writing a client for a single query, which `curl` does not need.

The base URL is `MLFLOW_TRACKING_URI`, `http://127.0.0.1:5000` by default.

## The API version is split

Runs are `2.0`. Traces are `3.0`. These are not interchangeable: `POST` to `/api/2.0/mlflow/traces/search` returns `405`, and the published API reference does not make the split obvious. Verify against the running server before trusting any endpoint written down elsewhere, including this file.

| Question                                        | Endpoint                                    |
| ----------------------------------------------- | ------------------------------------------- |
| Which runs exist, and their aggregate metrics   | `POST /api/2.0/mlflow/runs/search`          |
| One run's metrics, params, and tags             | `GET /api/2.0/mlflow/runs/get?run_id=<id>`  |
| Per-case results, including every assessment    | `POST /api/3.0/mlflow/traces/search`        |

## Aggregate metrics across runs

Every percentage assessment is published as `<name>/mean`, so a cross-run comparison needs one request:

```bash
curl -s -X POST "$MLFLOW_TRACKING_URI/api/2.0/mlflow/runs/search" -H 'Content-Type: application/json' -d '{"experiment_ids": ["1"], "max_results": 50, "order_by": ["attributes.start_time DESC"]}'
```

## Per-case results and rationales

Trace search returns each case's assessments inline, so reading a scorer's verdict costs no extra request per trace. Each assessment carries `assessment_name`, `feedback.value`, `rationale`, and a `metadata` block naming the owning component.

```bash
curl -s -X POST "$MLFLOW_TRACKING_URI/api/3.0/mlflow/traces/search" -H 'Content-Type: application/json' -d '{"locations": [{"type": "MLFLOW_EXPERIMENT", "mlflow_experiment": {"experiment_id": "1"}}], "max_results": 100}'
```

Each trace carries the filter keys as `trace_metadata`: `agent.cli`, `agent.model`, `agent.effort`, `case_id`, `case.name`, `category`, `config.manifest_id`, and `evaluation.execution_id`. Add a `filter` field to narrow by any of them, quoting the dotted key in backticks, as in ``metadata.`agent.cli` = 'codex'``. Filtering on `config.manifest_id` groups every run of one configuration across both CLIs, which is what the provider-independent manifest identity exists for.

Rationale text can contain unescaped control characters, which makes `jq` fail to parse an otherwise successful response. Use a tolerant parser when that happens rather than concluding the request failed.

## What REST will not answer

Span-level evidence — the normalized `agent.spawn`, `tool.shell`, and `agent.definition-canary` events under `agent.invoke` — is not part of the trace search payload. Reading those needs the MLflow Python client's trace data, and that is the one case where the eval virtual environment is the right tool.
