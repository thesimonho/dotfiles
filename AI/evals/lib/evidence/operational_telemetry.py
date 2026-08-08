"""Ungraded cost telemetry observed during one evaluation arm.

This is operational telemetry, not a metric: nothing here reaches the
assessment surface, no case declares it, and no comparison treats it as an
outcome. It exists so agent cost can be plotted across runs.

Three quantities, in increasing order of directness:

- Tool calls -- how many tools the agent invoked. A chained shell command is
  one call, because the agent issued one tool invocation.
- Tool round trips -- how many model responses requested tools. Each one costs
  a completion request when its results return, so this is what batching
  reduces: several tools requested in one response cost one round trip. Divide
  tool calls by round trips for the batching factor; it is not published,
  because it carries nothing the two terms do not.
- Tokens -- the billed quantity itself, kept in the dimensions the CLI
  reported rather than collapsed into a total.

Counts compare across runs of the same agent only. Claude and Codex normalize
different tool surfaces -- Codex reads files through `shell` while Claude has a
dedicated `Read` tool -- so one agent's total is not the other's.
"""

from collections import Counter
from dataclasses import dataclass, field
from typing import Any

from evidence.agent_events import AgentEvent

TELEMETRY_METRIC_PREFIX = "operations."
TELEMETRY_ARTIFACT = "operations/telemetry.json"


def tool_calls_by_name(events: tuple[AgentEvent, ...]) -> dict[str, int]:
    """Count real tool invocations, excluding synthesized observation events.

    Only `category == "tool"` events are genuine CLI tool calls. The event
    stream also carries agent-level records the harness synthesizes itself
    (model selections, definition canaries, plans), which would inflate any
    count taken over the whole stream.

    `AgentResult.tool_calls_by_name` is the single caller-facing entry point,
    so the span attribute and the run metric can never drift apart.
    """
    counts = Counter(event.name for event in events if event.category == "tool")
    return dict(sorted(counts.items()))


def claude_tool_round_trips(events: tuple[dict[str, Any], ...]) -> int:
    """Count Claude model responses that requested at least one tool.

    Claude streams one API response as several `assistant` events -- a
    thinking block and each parallel tool call arrive separately -- so the
    events themselves overcount. The shared `message.id` identifies the single
    underlying response, which is what actually costs a completion when its
    tool results return. Three tools batched into one response are one round
    trip; the same three issued sequentially are three.
    """
    tool_bearing_message_ids = {
        message_id
        for event in events
        if event.get("type") == "assistant"
        and isinstance(
            message_id := event.get("message", {}).get("id"),
            str,
        )
        and any(
            content.get("type") == "tool_use"
            for content in event.get("message", {}).get("content", [])
        )
    }
    return len(tool_bearing_message_ids)


@dataclass(frozen=True)
class CaseTelemetry:
    """Cost observed while running one case."""

    tool_calls_by_name: dict[str, int]
    tool_round_trips: int | None
    token_counts: dict[str, int]

    @property
    def tool_calls(self) -> int:
        """Total real tool invocations observed for this case."""
        return sum(self.tool_calls_by_name.values())


@dataclass
class OperationalTelemetryRecorder:
    """Collect per-case cost for run-level publication."""

    cases: dict[str, CaseTelemetry] = field(default_factory=dict)

    def record(self, case_id: str, telemetry: CaseTelemetry) -> None:
        """Keep the latest observation for a case, tolerating harness retries."""
        self.cases[case_id] = telemetry

    def summary(self, agent_profile: str) -> dict[str, Any]:
        """Render the inspectable per-case and per-tool breakdown."""
        tool_totals: Counter[str] = Counter()
        token_totals: Counter[str] = Counter()
        for telemetry in self.cases.values():
            tool_totals.update(telemetry.tool_calls_by_name)
            token_totals.update(telemetry.token_counts)
        measured_round_trips = [
            telemetry.tool_round_trips
            for telemetry in self.cases.values()
            if telemetry.tool_round_trips is not None
        ]
        total_tool_calls = sum(tool_totals.values())
        total_round_trips = sum(measured_round_trips)
        return {
            "agent_profile": agent_profile,
            "comparable_across_agents": False,
            "case_count": len(self.cases),
            "totals": {
                "tool_calls": total_tool_calls,
                "tool_round_trips": (
                    total_round_trips if measured_round_trips else None
                ),
                "tokens": dict(sorted(token_totals.items())),
            },
            "by_tool": dict(sorted(tool_totals.items())),
            "by_case": {
                case_id: {
                    "tool_calls": telemetry.tool_calls,
                    "tool_round_trips": telemetry.tool_round_trips,
                    "tokens": telemetry.token_counts,
                    "by_tool": telemetry.tool_calls_by_name,
                }
                for case_id, telemetry in sorted(self.cases.items())
            },
        }

    def run_metrics(self) -> dict[str, float]:
        """Render the run metrics that make cost plottable across runs.

        Per-case values matter more than totals whenever a run evaluates a
        different case set, so both are published. A dimension the CLI never
        reported is omitted rather than recorded as zero.
        """
        summary = self.summary("")
        case_count = summary["case_count"]
        if not case_count:
            return {}
        totals = summary["totals"]
        metrics = {
            "tool_calls_total": float(totals["tool_calls"]),
            "tool_calls_per_case": totals["tool_calls"] / case_count,
        }
        if totals["tool_round_trips"] is not None:
            metrics["tool_round_trips_total"] = float(totals["tool_round_trips"])
            metrics["tool_round_trips_per_case"] = (
                totals["tool_round_trips"] / case_count
            )
        for dimension, count in totals["tokens"].items():
            metrics[f"tokens.{dimension}_total"] = float(count)
            metrics[f"tokens.{dimension}_per_case"] = count / case_count
        return {
            f"{TELEMETRY_METRIC_PREFIX}{name}": value
            for name, value in metrics.items()
        }
