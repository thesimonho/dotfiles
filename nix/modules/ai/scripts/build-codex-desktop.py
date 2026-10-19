"""Build the native AUR package with the declared ChatGPT Community features."""

import json
import os
import shlex
import subprocess
import sys
import tempfile
from pathlib import Path

SELECTION_MARKER = Path("/opt/codex-desktop/.codex-linux/dotfiles-features.json")


def configured():
    """An ordinary AUR upgrade drops our marker and needs reconciliation."""
    try:
        return json.loads(SELECTION_MARKER.read_text()) == json.loads(
            Path(os.environ["CODEX_LINUX_FEATURES_CONFIG"]).read_text()
        )
    except (OSError, ValueError):
        return False


def run(args, **kwargs):
    print("+ " + shlex.join(map(str, args)), flush=True)
    return subprocess.run(args, check=True, **kwargs)


def prepare(source):
    """Called by makepkg after fetching upstream, before its install.sh."""
    config_path = Path(os.environ["CODEX_LINUX_FEATURES_CONFIG"])
    config = json.loads(config_path.read_text())
    enabled = config.get("enabled")
    if not isinstance(enabled, list) or any(not isinstance(x, str) for x in enabled):
        raise ValueError("Feature config requires an enabled list of feature IDs.")
    manifests = {
        path.parent.name: json.loads(path.read_text())
        for path in (source / "linux-features").glob("*/feature.json")
    }
    resolved = set(enabled)
    pending = list(enabled)
    while pending:
        name = pending.pop()
        feature = manifests.get(name)
        if feature is None or feature.get("internal"):
            raise ValueError(f"Unknown or internal feature: {name}")
        for dependency in feature.get("requires", []):
            if dependency not in resolved:
                resolved.add(dependency)
                pending.append(dependency)
    for name in sorted(resolved):
        conflicts = resolved.intersection(manifests[name].get("conflicts", []))
        if conflicts:
            raise ValueError(
                f"Feature {name} conflicts with {', '.join(sorted(conflicts))}"
            )
    config["enabled"] = sorted(resolved)
    config_path.write_text(json.dumps(config, indent=2) + "\n")
    dependencies = sorted(
        {
            dependency
            for name in resolved
            for dependency in manifests[name]
            .get("packageDependencies", {})
            .get("pacman", [])
        }
    )
    config_path.with_suffix(".deps.sh").write_text(
        "depends+=(" + shlex.join(dependencies) + ")\n"
    )
    print("Resolved features: " + ", ".join(config["enabled"]), flush=True)
    run(["node", "scripts/lib/linux-features.js", "--enabled"], cwd=source)
    run(["make", "build-native-feature-helpers"], cwd=source)


def build(helper):
    if os.geteuid() == 0:
        raise ValueError("Run the native build as your normal user.")
    original = Path(os.environ["CODEX_LINUX_FEATURES_CONFIG"])
    with tempfile.TemporaryDirectory(prefix="codex-desktop-aur-") as temporary:
        work = Path(temporary)
        config = work / "features.json"
        config.write_text(original.read_text())
        os.environ["CODEX_LINUX_FEATURES_CONFIG"] = str(config)
        # Use the user's helper for retrieval and review; Pacman still owns the
        # package produced and installed by makepkg. No separate updater runs.
        run([helper, "-G", "--", "codex-desktop-git"], cwd=work)
        recipe_dir = work / "codex-desktop-git"
        recipe = recipe_dir / "PKGBUILD"
        text = recipe.read_text()
        anchor = "    ./install.sh\n"
        if text.count(anchor) != 1:
            raise ValueError(
                "AUR prepare() changed; review the new recipe before building."
            )
        command = shlex.join(
            [sys.executable, str(Path(__file__).resolve()), "--prepare"]
        )
        text = text.replace(
            anchor,
            f'    {command} "$PWD"\n'
            '    source "${CODEX_LINUX_FEATURES_CONFIG%.json}.deps.sh"\n' + anchor,
        )
        # cargo is provided by either Arch rust or rustup. Preserve the user's
        # installed provider; makepkg resolves missing repository dependencies.
        text += "\nmakedepends+=(cargo make pkgconf)\n"
        # Record the requested selection inside the Pacman-owned payload. An
        # unconfigured external upgrade removes it, so plan schedules a rebuild.
        text += """
eval "$(declare -f package | sed '1s/package/codex_original_package/')"
package() {
    codex_original_package
    install -Dm644 "$CODEX_DECLARED_FEATURES" \\
        "$pkgdir/opt/codex-desktop/.codex-linux/dotfiles-features.json"
}
"""
        os.environ["CODEX_DECLARED_FEATURES"] = str(original)
        recipe.write_text(text)
        print("Review the AUR recipe and local feature-build addition:", flush=True)
        print(text, flush=True)
        if not sys.stdin.isatty():
            raise ValueError(
                "The custom native build requires interactive recipe review."
            )
        if (
            input("Build and install this native package? [y/N] ").strip().lower()
            != "y"
        ):
            raise ValueError("Cancelled before building or installing.")
        run(["/usr/bin/makepkg", "--syncdeps", "--install", "--force"], cwd=recipe_dir)
        actual = json.loads(
            Path("/opt/codex-desktop/.codex-linux/build-info.json").read_text()
        )["linuxFeatures"]["enabled"]
        expected = json.loads(config.read_text())["enabled"]
        if set(actual) != set(expected):
            raise ValueError(
                "Installed feature metadata does not match the build selection."
            )
        os.environ["CODEX_LINUX_FEATURES_CONFIG"] = str(original)
        if not configured():
            raise ValueError(
                "Installed package is missing its declared feature marker."
            )


if __name__ == "__main__":
    try:
        if sys.argv[1:] == ["--check"]:
            sys.exit(0 if configured() else 1)
        elif len(sys.argv) == 3 and sys.argv[1] == "--prepare":
            prepare(Path(sys.argv[2]))
        elif len(sys.argv) == 2 and Path(sys.argv[1]).name in ("paru", "yay"):
            build(sys.argv[1])
        else:
            raise ValueError("Expected paru/yay or --prepare SOURCE.")
    except (ValueError, OSError, KeyError, subprocess.CalledProcessError) as error:
        print(f"codex-desktop-build: {error}", file=sys.stderr)
        sys.exit(1)
