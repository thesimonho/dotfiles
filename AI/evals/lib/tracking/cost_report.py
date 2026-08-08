"""Price-weight recorded token usage so runs compare on spend, not volume.

Raw token counts mislead across model bands: the cheapest run by token count
in the first baseline set was also the most expensive by more than three
times, because a top-band model can cost ten times a lower one per token.
Usage limits are weighted by list price, so spend is the axis a configuration
decision actually turns on.

Prices are applied when a report runs rather than stored on a run. A stored
cost would answer what a run once cost, which no forward-looking choice needs;
applying current rates instead means refreshing the table re-ranks every run,
which is the intended behaviour.
"""

from __future__ import annotations

import tomllib
from dataclasses import dataclass
from datetime import date, timedelta
from pathlib import Path

from harness_environment import REPOSITORY_ROOT

PRICING_PATH = REPOSITORY_ROOT / "AI/evals/pricing.toml"

_TOKEN_METRICS = {
    "output": "operations.tokens.output_tokens_total",
    "uncached_input": "operations.tokens.uncached_input_tokens_total",
    "cache_read": "operations.tokens.cached_input_tokens_total",
    "cache_write": "operations.tokens.cache_creation_input_tokens_total",
}

_TOKENS_PER_PRICED_UNIT = 1_000_000


@dataclass(frozen=True)
class ModelRate:
    """One model's prices in USD per million tokens."""

    profile: str
    name: str
    effective_from: date
    source: str
    input: float
    cache_write: float
    cache_read: float
    output: float


@dataclass(frozen=True)
class RateTable:
    """Every known rate, with the date its prices were last confirmed."""

    retrieved: date
    staleness_days: int
    rates: tuple[ModelRate, ...]

    def age_days(self, today: date) -> int:
        """Return how long ago the prices were confirmed."""
        return (today - self.retrieved).days

    def is_stale(self, today: date) -> bool:
        """Report whether the prices are old enough to need confirming."""
        return self.age_days(today) > self.staleness_days

    def rate_for(self, profile: str, model: str, today: date) -> ModelRate | None:
        """Return the newest rate for one model that has already taken effect.

        A scheduled price change is stored as a second entry with a later
        effective date, so the table stays correct through the change without
        being edited on the day it lands.
        """
        applicable = [
            rate
            for rate in self.rates
            if rate.profile == profile
            and rate.name == model
            and rate.effective_from <= today
        ]
        if not applicable:
            return None
        return max(applicable, key=lambda rate: rate.effective_from)


@dataclass(frozen=True)
class RunCost:
    """One run's spend at current prices, beside what the spend bought."""

    run_name: str
    profile: str
    model: str
    effort: str
    output_cost: float
    input_cost: float
    adherence: float | None

    @property
    def total_cost(self) -> float:
        """Return the run's whole cost in USD."""
        return self.output_cost + self.input_cost

    @property
    def cost_per_adherence_point(self) -> float | None:
        """Return USD per pooled adherence point, or None without a score."""
        if self.adherence is None or self.adherence <= 0:
            return None
        return self.total_cost / self.adherence


def load_rate_table(pricing_path: Path = PRICING_PATH) -> RateTable:
    """Read the rate table, defaulting undated entries to already effective."""
    payload = tomllib.loads(pricing_path.read_text())
    meta = payload["meta"]
    rates = tuple(
        ModelRate(
            profile=entry["profile"],
            name=entry["name"],
            effective_from=entry.get("effective_from", date.min),
            source=entry["source"],
            input=float(entry["input"]),
            cache_write=float(entry["cache_write"]),
            cache_read=float(entry["cache_read"]),
            output=float(entry["output"]),
        )
        for entry in payload["model"]
    )
    return RateTable(
        retrieved=meta["retrieved"],
        staleness_days=int(meta["staleness_days"]),
        rates=rates,
    )


def token_costs(metrics: dict[str, float], rate: ModelRate) -> tuple[float, float]:
    """Return one run's (output, input) cost in USD from its token metrics."""
    tokens = {
        component: metrics.get(metric_key, 0.0)
        for component, metric_key in _TOKEN_METRICS.items()
    }
    output_cost = tokens["output"] * rate.output
    input_cost = (
        tokens["uncached_input"] * rate.input
        + tokens["cache_read"] * rate.cache_read
        + tokens["cache_write"] * rate.cache_write
    )
    return (
        output_cost / _TOKENS_PER_PRICED_UNIT,
        input_cost / _TOKENS_PER_PRICED_UNIT,
    )


def format_cost_report(
    costs: list[RunCost],
    table: RateTable,
    today: date,
    unpriced: list[tuple[str, str, str]],
) -> str:
    """Render the spend ranking, cheapest first, with any pricing warnings."""
    lines = [
        f"token prices confirmed {table.retrieved} "
        f"({table.age_days(today)} days ago)",
        "",
    ]
    if table.is_stale(today):
        lines[:0] = [
            f"WARNING: prices are older than {table.staleness_days} days and "
            "may rank configurations wrongly. Refresh AI/evals/pricing.toml.",
            "",
        ]
    header = (
        f"{'run':38} {'$/run':>8} {'adherence':>10} "
        f"{'$/point':>8} {'$ output':>9} {'$ input':>8}"
    )
    lines.append(header)
    for cost in sorted(costs, key=lambda entry: entry.total_cost):
        adherence = "-" if cost.adherence is None else f"{cost.adherence:.1f}"
        per_point = cost.cost_per_adherence_point
        per_point_text = "-" if per_point is None else f"{per_point:.3f}"
        lines.append(
            f"{cost.run_name[:38]:38} {cost.total_cost:8.2f} {adherence:>10} "
            f"{per_point_text:>8} {cost.output_cost:9.2f} {cost.input_cost:8.2f}"
        )
    if unpriced:
        lines.extend(["", "unpriced runs (add the model to pricing.toml):"])
        lines.extend(
            f"  {run_name}: {profile} {model}"
            for run_name, profile, model in unpriced
        )
    upcoming = _scheduled_changes(table, today)
    if upcoming:
        lines.extend(["", "scheduled price changes:"])
        lines.extend(upcoming)
    return "\n".join(lines)


def _scheduled_changes(table: RateTable, today: date) -> list[str]:
    """Announce rates that take effect soon so a re-rank is not a surprise."""
    horizon = today + timedelta(days=60)
    return [
        f"  {rate.effective_from}: {rate.profile} {rate.name} "
        f"-> ${rate.input:g} input / ${rate.output:g} output per MTok"
        for rate in sorted(table.rates, key=lambda entry: entry.effective_from)
        if today < rate.effective_from <= horizon
    ]
