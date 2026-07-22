"""Behavior tests for controlled configuration comparisons."""

import sys
import tempfile
import unittest
from pathlib import Path

EVAL_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(EVAL_ROOT / "lib"))

from configuration_components import ConfigComponent  # noqa: E402
from configuration_variant import (  # noqa: E402
    comparison_variants,
    prepare_variant_profile,
)


def component(component_id: str) -> ConfigComponent:
    """Create a small configuration component for variant tests."""
    return ConfigComponent(
        component_id=component_id,
        registry_name=component_id.replace("/", "--"),
        content=f"# {component_id}\n",
        content_hash=f"hash-{component_id}",
        source_paths=(f"AI/{component_id}.md",),
    )


class ComparisonVariantsTest(unittest.TestCase):
    """Change exactly one component between treatment and control."""

    def test_removes_only_the_selected_component_from_control(self) -> None:
        components = (
            component("instruction/coding-style"),
            component("instruction/tools"),
            component("agent/frank"),
        )

        treatment, control = comparison_variants(
            components,
            "instruction/tools",
        )

        self.assertEqual(treatment.name, "treatment")
        self.assertEqual(treatment.components, components)
        self.assertEqual(control.name, "control")
        self.assertEqual(
            tuple(item.component_id for item in control.components),
            ("instruction/coding-style", "agent/frank"),
        )
        self.assertEqual(control.excluded_component_id, "instruction/tools")

    def test_rejects_component_kinds_not_yet_removed_from_runtime(self) -> None:
        components = (
            component("instruction/tools"),
            component("agent/frank"),
        )

        with self.assertRaisesRegex(ValueError, "instruction components"):
            comparison_variants(components, "agent/frank")

    def test_prepares_codex_with_only_the_selected_instructions(self) -> None:
        components = (
            component("instruction/coding-style"),
            component("instruction/tools"),
            component("agent/frank"),
        )
        _, control = comparison_variants(components, "instruction/tools")
        with tempfile.TemporaryDirectory() as directory:
            source_root = Path(directory) / "source"
            source_root.mkdir()
            (source_root / "auth.json").write_text("{}\n")
            (source_root / "config.toml").write_text('model = "test"\n')
            (source_root / "agents").mkdir()
            (source_root / "skills").mkdir()

            with prepare_variant_profile(
                "codex",
                control,
                source_config_root=source_root,
            ) as prepared:
                codex_root = Path(prepared.environment["CODEX_HOME"])
                generated_instructions = (codex_root / "AGENTS.md").read_text()

                self.assertIn("instruction/coding-style", generated_instructions)
                self.assertNotIn("instruction/tools", generated_instructions)
                self.assertTrue((codex_root / "agents").is_symlink())
                self.assertTrue((codex_root / "skills").is_symlink())
                self.assertFalse((codex_root / "hooks.json").exists())

            self.assertFalse(prepared.root.exists())

    def test_prepares_claude_rules_with_same_control_component_set(self) -> None:
        components = (
            component("instruction/coding-style"),
            component("instruction/tools"),
            component("agent/frank"),
        )
        _, control = comparison_variants(components, "instruction/tools")
        with tempfile.TemporaryDirectory() as directory:
            source_root = Path(directory) / "source"
            source_root.mkdir()
            (source_root / ".credentials.json").write_text("{}\n")
            (source_root / "agents").mkdir()
            (source_root / "skills").mkdir()

            with prepare_variant_profile(
                "claude",
                control,
                source_config_root=source_root,
            ) as prepared:
                claude_root = Path(prepared.environment["CLAUDE_CONFIG_DIR"])
                rule_names = tuple(
                    path.name for path in sorted((claude_root / "rules").iterdir())
                )

                self.assertEqual(rule_names, ("coding-style.md",))
                self.assertFalse((claude_root / "settings.json").exists())
                self.assertTrue((claude_root / "agents").is_symlink())
                self.assertTrue((claude_root / "skills").is_symlink())


if __name__ == "__main__":
    unittest.main()
