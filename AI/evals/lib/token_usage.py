"""Provider-aware token counts normalized to comparable dimensions."""

from dataclasses import asdict, dataclass


@dataclass(frozen=True)
class TokenUsage:
    """Comparable token dimensions without estimating unavailable values."""

    source: str
    input_tokens: int | None = None
    uncached_input_tokens: int | None = None
    cached_input_tokens: int | None = None
    cache_creation_input_tokens: int | None = None
    output_tokens: int | None = None
    reasoning_output_tokens: int | None = None
    total_tokens: int | None = None

    def to_dict(self) -> dict[str, object]:
        """Render every dimension so unavailable values remain explicit."""
        return asdict(self)

    def available_counts(self) -> dict[str, int]:
        """Return only numeric dimensions suitable for MLflow feedback."""
        usage = asdict(self)
        return {
            name: value
            for name, value in usage.items()
            if name != "source" and isinstance(value, int)
        }
