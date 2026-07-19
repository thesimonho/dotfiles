"""Behavior tests for effective agent configuration versioning."""

import sys
import tempfile
import unittest
from pathlib import Path

LIB_DIR = Path(__file__).resolve().parents[1] / "lib"
sys.path.insert(0, str(LIB_DIR))

from configuration_components import discover_agent_components  # noqa: E402
from configuration_manifest import (  # noqa: E402
    RegisteredComponent,
    build_manifest,
    compare_manifests,
    manifest_from_content,
)


class ConfigurationDiscoveryTests(unittest.TestCase):
    """Verify the public discovery result matches the effective config layout."""

    def test_discovers_only_direct_instruction_and_agent_markdown_files(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            repository_root = Path(temporary_directory)
            self._write(
                repository_root,
                "AI/instructions/fragments/workflow.md",
                "Work carefully.\r\n",
            )
            self._write(
                repository_root,
                "AI/settings/claude/settings.json",
                '{"model":"sonnet","env":{"B":"2","A":"1"}}',
            )
            self._write(
                repository_root,
                "AI/hooks/branch-guard.js",
                "export const guard = true;\n",
            )
            self._write(
                repository_root,
                "AI/lib/hooks/helper.js",
                "export const helper = true;\n",
            )
            self._write(
                repository_root,
                "AI/agents/.generated/claude/frank.md",
                "You are Frank.\n",
            )
            self._write(
                repository_root,
                "AI/agents/frank.md",
                "Plan carefully.\r\n",
            )
            self._write(repository_root, "AI/skills/verify/SKILL.md", "# Verify\n")
            self._write(
                repository_root, "AI/skills/verify/scripts/check.py", "print('ok')\n"
            )
            self._write(
                repository_root, "AI/skills/verify/.env", "SECRET=do-not-publish\n"
            )
            self._write(
                repository_root, "AI/skills/verify/cache/output.md", "generated\n"
            )

            components = discover_agent_components("claude", repository_root)
            components_by_id = {
                component.component_id: component for component in components
            }

            self.assertEqual(
                list(components_by_id),
                ["agent/frank", "instruction/workflow"],
            )
            self.assertEqual(
                components_by_id["agent/frank"].content, "Plan carefully.\n"
            )
            self.assertEqual(
                components_by_id["agent/frank"].source_paths,
                ("AI/agents/frank.md",),
            )
            self.assertEqual(
                components_by_id["instruction/workflow"].content, "Work carefully.\n"
            )

    def test_profiles_share_the_same_configuration_prompt_families(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            repository_root = Path(temporary_directory)
            self._write(
                repository_root, "AI/instructions/AGENTS.generated.md", "# Generated\n"
            )
            self._write(
                repository_root,
                "AI/instructions/fragments/workflow.md",
                "Work carefully.\n",
            )
            self._write(
                repository_root,
                "AI/agents/.generated/codex/frank.toml",
                'name = "frank"\n',
            )
            self._write(
                repository_root,
                "AI/agents/frank.md",
                "Plan carefully.\n",
            )
            self._write(
                repository_root, "AI/settings/codex/config.toml", 'model = "gpt"\n'
            )
            self._write(
                repository_root,
                "AI/settings/codex/rules/default.rules",
                "allow = true\n",
            )
            self._write(repository_root, "AI/settings/claude/settings.json", "{}")
            self._write(
                repository_root, "AI/hooks/claude-only.js", "export default true;\n"
            )
            self._write(repository_root, "AI/skills/verify/SKILL.md", "# Verify\n")

            codex_components = discover_agent_components("codex", repository_root)
            claude_components = discover_agent_components("claude", repository_root)
            component_ids = [component.component_id for component in codex_components]

            self.assertEqual(
                component_ids,
                ["agent/frank", "instruction/workflow"],
            )
            self.assertEqual(
                [component.registry_name for component in codex_components],
                [component.registry_name for component in claude_components],
            )

    def test_registry_names_remain_distinct_after_normalization(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            repository_root = Path(temporary_directory)
            self._write(
                repository_root,
                "AI/instructions/fragments/a_b.md",
                "underscore\n",
            )
            self._write(
                repository_root,
                "AI/instructions/fragments/a--b.md",
                "dashes\n",
            )

            components = discover_agent_components("claude", repository_root)

            registry_names = {component.registry_name for component in components}
            self.assertEqual(len(registry_names), len(components))

    def test_rejects_fragment_symlinks(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            repository_root = Path(temporary_directory) / "repository"
            outside_root = Path(temporary_directory) / "outside"
            self._write(outside_root, "payload.md", "outside\n")
            fragment_path = repository_root / "AI/instructions/fragments/reference.md"
            fragment_path.parent.mkdir(parents=True, exist_ok=True)
            fragment_path.symlink_to(outside_root / "payload.md")

            with self.assertRaisesRegex(ValueError, "must not be symlinks"):
                discover_agent_components("claude", repository_root)

    @staticmethod
    def _write(repository_root: Path, relative_path: str, content: str) -> None:
        target_path = repository_root / relative_path
        target_path.parent.mkdir(parents=True, exist_ok=True)
        target_path.write_text(content)


class ConfigurationManifestTests(unittest.TestCase):
    """Verify manifests fully describe and compare active component sets."""

    def test_comparison_classifies_added_removed_modified_and_unchanged_components(
        self,
    ):
        baseline = build_manifest(
            "claude",
            [
                self._registered("instruction/planning", 1, "hash-planning"),
                self._registered("instruction/workflow", 1, "hash-workflow-1"),
                self._registered("instruction/verification", 2, "hash-verify"),
            ],
        )
        current = build_manifest(
            "claude",
            [
                self._registered("instruction/security", 1, "hash-security"),
                self._registered("instruction/workflow", 2, "hash-workflow-2"),
                self._registered("instruction/verification", 2, "hash-verify"),
            ],
        )

        changes = compare_manifests(baseline, current)

        self.assertEqual(changes.added, ("instruction/security",))
        self.assertEqual(changes.removed, ("instruction/planning",))
        self.assertEqual(changes.modified, ("instruction/workflow",))
        self.assertEqual(changes.unchanged, ("instruction/verification",))
        self.assertIn("instruction/workflow: v1 -> v2", changes.summary)
        self.assertIn("Added:\n  instruction/security: v1", changes.summary)
        self.assertIn("Removed:\n  instruction/planning: v1", changes.summary)

    def test_manifest_identity_depends_on_content_not_provider_versions(self):
        mlflow_manifest = build_manifest(
            "claude",
            [self._registered("instruction/workflow", 9, "same-hash", "mlflow")],
        )
        alternate_provider_manifest = build_manifest(
            "claude",
            [self._registered("instruction/workflow", 3, "same-hash", "alternate")],
        )

        self.assertEqual(
            mlflow_manifest.manifest_id,
            alternate_provider_manifest.manifest_id,
        )
        self.assertNotEqual(
            mlflow_manifest.content,
            alternate_provider_manifest.content,
        )

    def test_manifest_round_trip_preserves_provider_prompt_references(self):
        original = build_manifest(
            "codex",
            [
                RegisteredComponent(
                    component_id="instruction/workflow",
                    content_hash="hash-workflow",
                    prompt_name="instruction--workflow",
                    prompt_version=2,
                    prompt_reference="prompts:/instruction--workflow/2",
                    source_paths=("AI/instructions/fragments/workflow.md",),
                )
            ],
        )

        restored = manifest_from_content(original.content)

        self.assertEqual(
            restored.components[0].prompt_reference,
            original.components[0].prompt_reference,
        )

    @staticmethod
    def _registered(
        component_id: str,
        version: int,
        content_hash: str,
        provider: str = "provider",
    ) -> RegisteredComponent:
        prompt_name = component_id.replace("/", "--")
        return RegisteredComponent(
            component_id=component_id,
            content_hash=content_hash,
            prompt_name=prompt_name,
            prompt_version=version,
            prompt_reference=f"{provider}:{prompt_name}:{version}",
            source_paths=(f"{component_id}.txt",),
        )


if __name__ == "__main__":
    unittest.main()
