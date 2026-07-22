"""Behavior tests for cross-CLI evaluation capabilities."""

import sys
import tempfile
import unittest
from pathlib import Path

EVAL_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(EVAL_ROOT / "lib"))

from capabilities import capability_manifest, probe_capabilities  # noqa: E402


class CapabilityProbeTest(unittest.TestCase):
    """Fail setup separately from agent instruction scoring."""

    def test_hashes_required_tools_skills_and_agents_for_codex(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            binary_path = root / "bin"
            binary_path.mkdir()
            tool_path = binary_path / "rtk"
            tool_path.write_text("#!/bin/sh\nexit 0\n")
            tool_path.chmod(0o700)

            codex_home = root / "codex"
            skill_path = codex_home / "skills" / "verify" / "SKILL.md"
            skill_path.parent.mkdir(parents=True)
            skill_path.write_text("# Verify\n")
            agent_path = codex_home / "agents" / "frank.toml"
            agent_path.parent.mkdir(parents=True)
            agent_path.write_text('name = "frank"\n')

            snapshot = probe_capabilities(
                "codex",
                {
                    "PATH": str(binary_path),
                    "HOME": str(root),
                    "CODEX_HOME": str(codex_home),
                },
                required_tools=("rtk",),
                required_skills=("verify",),
                required_agents=("frank",),
            )

            self.assertEqual(snapshot.profile, "codex")
            self.assertEqual(tuple(snapshot.tools), ("rtk",))
            self.assertEqual(tuple(snapshot.skills), ("verify",))
            self.assertEqual(tuple(snapshot.agents), ("frank",))
            self.assertEqual(len(snapshot.skills["verify"].content_hash), 64)

            manifest = capability_manifest((snapshot,))

            self.assertEqual(manifest["snapshots"][0]["profile"], "codex")
            self.assertEqual(
                manifest["snapshots"][0]["tools"]["rtk"],
                snapshot.tools["rtk"].content_hash,
            )
            self.assertNotIn(str(root), str(manifest))
            self.assertEqual(len(manifest["manifest_hash"]), 64)


if __name__ == "__main__":
    unittest.main()
