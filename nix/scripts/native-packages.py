"""Reconcile native packages against a host-bound ownership receipt."""

import argparse
import fcntl
import hashlib
import json
import os
import platform
import plistlib
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

NAME = re.compile(r"[a-zA-Z0-9@_+][a-zA-Z0-9@._+\-]*\Z")


def fail(message):
    raise ValueError(message)


def read_json(path):
    with path.open() as stream:
        return json.load(stream)


def save(path, value):
    # Atomic replacement and fsync preserve a valid receipt across interruption.
    fd, temporary = tempfile.mkstemp(dir=path.parent, prefix=".receipt-")
    try:
        with os.fdopen(fd, "w") as stream:
            json.dump(value, stream, indent=2, sort_keys=True)
            stream.write("\n")
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
        directory = os.open(path.parent, os.O_RDONLY)
        try:
            os.fsync(directory)
        finally:
            os.close(directory)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def command(args, capture=False):
    if not capture:
        print("+ " + shlex.join(args), flush=True)
    try:
        return subprocess.run(args, check=True, text=True, capture_output=capture)
    except subprocess.CalledProcessError as error:
        if capture and error.stderr:
            print(error.stderr.rstrip(), file=sys.stderr)
        raise


BACKENDS = {
    "arch": ("pacman", "aur"),
    "darwin": ("homebrewFormula", "homebrewCask"),
    "fedora": ("dnf",),
    None: (),
}


def present(installed, name, backend):
    return name in installed.get(backend, set())


class Backend:
    def __init__(self, native_platform, repositories):
        self.platform = native_platform
        self.repositories = repositories
        if not isinstance(repositories, dict):
            fail("Repository declarations must be an object.")
        if repositories and native_platform != "fedora":
            fail("Repository declarations are supported only by the Fedora backend.")
        for name, repository in repositories.items():
            if not NAME.fullmatch(name) or not isinstance(repository, dict):
                fail("Invalid native repository declaration.")
            if set(repository) != {"baseurl", "gpgkey"} or any(
                not isinstance(value, str)
                or not value.startswith("https://")
                or any(char.isspace() for char in value)
                for value in repository.values()
            ):
                fail(f"Repository {name} requires HTTPS baseurl and gpgkey values.")

    def check_prerequisites(self, desired, helper):
        if self.platform is None:
            print("Native prerequisites: no native platform selected.")
            return
        required = {
            "arch": ["pacman", "sudo"],
            "darwin": ["brew"],
            "fedora": ["rpm", "dnf", "sudo"],
        }[self.platform]
        missing = [tool for tool in required if not shutil.which(tool)]
        if "aur" in desired.values():
            helpers = [helper] if helper else ["paru", "yay"]
            if not any(shutil.which(tool) for tool in helpers):
                missing.append(" or ".join(helpers))
        if missing:
            fail(
                "Missing native prerequisites: "
                + ", ".join(missing)
                + ". Install them before activating this host configuration."
            )
        print("Native prerequisites available for " + self.platform + ".")

    def installed(self):
        if self.platform == "arch":
            lock = Path("/var/lib/pacman/db.lck")
            if lock.exists():
                fail("Pacman database is locked; retry after the transaction finishes.")
            names = set(command(["pacman", "-Qq"], capture=True).stdout.splitlines())
            if lock.exists():
                fail("Pacman transaction started during the query; retry later.")
            return {"pacman": names, "aur": names}
        if self.platform == "darwin":
            return {
                kind: set(
                    command(
                        ["brew", "list", flag, "-1"], capture=True
                    ).stdout.splitlines()
                )
                for kind, flag in (
                    ("homebrewFormula", "--formula"),
                    ("homebrewCask", "--cask"),
                )
            }
        if self.platform == "fedora":
            return {
                "dnf": set(
                    command(
                        ["rpm", "-qa", "--qf", "%{NAME}\n"], capture=True
                    ).stdout.splitlines()
                )
            }
        return {}

    def install_command(self, name, backend, helper):
        if backend == "pacman":
            exact = command(
                ["pacman", "-Sp", "--print-format", "%n", "--", name], capture=True
            )
            if name not in exact.stdout.splitlines():
                fail(f"Not an exact repository package: {name}")
            return ["sudo", "pacman", "-S", "--needed", "--", name]
        if backend == "aur":
            return [helper, "-S", "--needed", "--aur", "--", name]
        if backend in ("homebrewFormula", "homebrewCask"):
            flag = "--formula" if backend == "homebrewFormula" else "--cask"
            return ["brew", "install", flag, "--", name]
        return ["sudo", "dnf", "install", "--", name]

    def protection_plan(self, desired, installed):
        if self.platform != "arch":
            return []
        query = subprocess.run(
            ["pacman", "-Qqe"], text=True, capture_output=True, check=False
        )
        if query.returncode not in (0, 1) or query.stderr:
            fail(f"Cannot query explicit packages: {query.stderr.strip()}")
        explicit = set(query.stdout.splitlines())
        return sorted(
            name
            for name, kind in desired.items()
            if present(installed, name, kind) and name not in explicit
        )

    def removal_preview(self, targets, desired):
        if self.platform != "arch" or not targets:
            return sorted(targets)
        lock = Path("/var/lib/pacman/db.lck")
        if lock.exists():
            fail("Pacman database is locked; retry later.")
        with tempfile.TemporaryDirectory(prefix="native-pacman-preview-") as temporary:
            database = Path(temporary)
            shutil.copytree("/var/lib/pacman/local", database / "local")
            # pacman -D requires root even on a temporary database. Change only
            # copied install reasons, then let pacman resolve the transaction.
            for description in (database / "local").glob("*/desc"):
                text = description.read_text()
                fields = dict(
                    part.split("\n", 1)
                    for part in text.strip().split("\n\n")
                    if "\n" in part
                )
                if fields.get("%NAME%") in desired:
                    text = re.sub(r"(%REASON%\n)[01](?=\n)", r"\g<1>0", text)
                    description.write_text(text)
            if lock.exists():
                fail("Pacman transaction started during preview; retry later.")
            result = command(
                [
                    "pacman",
                    "--dbpath",
                    str(database),
                    "-Rsp",
                    "--print-format",
                    "%n",
                    "--",
                    *targets,
                ],
                capture=True,
            )
        resolved = sorted(set(result.stdout.splitlines()))
        if set(resolved) & set(desired):
            fail("Removal would affect a declared package; refusing the transaction.")
        if not set(targets) <= set(resolved):
            fail("Pacman removal preview did not include every target.")
        return resolved

    def remove_commands(self, targets, owned):
        if self.platform == "arch":
            return [["sudo", "pacman", "-Rs", "--", *targets]]
        if self.platform == "darwin":
            return [
                ["brew", "uninstall", flag, "--", *names]
                for kind, flag in (
                    ("homebrewFormula", "--formula"),
                    ("homebrewCask", "--cask"),
                )
                if (names := [name for name in targets if owned[name] == kind])
            ]
        # DNF remove may cascade into unmanaged reverse dependencies. RPM
        # refuses those transactions instead; never pass --nodeps or --noscripts.
        return [["sudo", "rpm", "-e", "--", *targets]]

    @staticmethod
    def repository_path(name):
        return Path("/etc/yum.repos.d") / f"native-packages-{name}.repo"

    def repository_text(self, name):
        repository = self.repositories[name]
        return (
            f"[native-packages-{name}]\nname=Native packages: {name}\n"
            f"baseurl={repository['baseurl']}\nenabled=1\n"
            f"gpgcheck=1\ngpgkey={repository['gpgkey']}\n"
        )

    def repository_plan(self, receipt):
        # Repositories are shared package sources, not package-removal targets.
        changes = []
        owned = receipt.get("repositories", {})
        pending = receipt.get("pendingRepository")
        if not isinstance(owned, dict) or any(
            not NAME.fullmatch(name)
            or not isinstance(digest, str)
            or not re.fullmatch("[0-9a-f]{64}", digest)
            for name, digest in owned.items()
        ):
            fail("Invalid repository ownership receipt.")
        if pending is not None and (
            not isinstance(pending, dict)
            or set(pending) != {"name", "digest"}
            or not isinstance(pending["name"], str)
            or not NAME.fullmatch(pending["name"])
            or not isinstance(pending["digest"], str)
            or not re.fullmatch("[0-9a-f]{64}", pending["digest"])
        ):
            fail("Invalid repository journal.")
        for name in self.repositories:
            path = self.repository_path(name)
            if path.is_symlink():
                fail(f"Refusing repository symlink: {path}")
            current = (
                hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else None
            )
            desired = hashlib.sha256(self.repository_text(name).encode()).hexdigest()
            if current == desired:
                continue
            previous = owned.get(name)
            recovering = (
                pending and pending["name"] == name and current == pending["digest"]
            )
            if current is not None and current != previous and not recovering:
                fail(
                    f"Repository {path} has unmanaged changes; refusing to overwrite it."
                )
            changes.append(name)
        return changes

    def prepare_repositories(self, receipt, receipt_path, names):
        owned = receipt.setdefault("repositories", {})
        pending = receipt.get("pendingRepository")
        if pending:
            path = self.repository_path(pending["name"])
            if (
                path.exists()
                and not path.is_symlink()
                and hashlib.sha256(path.read_bytes()).hexdigest() == pending["digest"]
            ):
                owned[pending["name"]] = pending["digest"]
            receipt["pendingRepository"] = None
            save(receipt_path, receipt)
        for name in names:
            destination = self.repository_path(name)
            text = self.repository_text(name)
            digest = hashlib.sha256(text.encode()).hexdigest()
            receipt["pendingRepository"] = {"name": name, "digest": digest}
            save(receipt_path, receipt)
            with tempfile.TemporaryDirectory(prefix="native-repository-") as temporary:
                source = Path(temporary) / "repository.repo"
                source.write_text(text)
                staging = destination.with_suffix(".repo.pending")
                command(
                    ["sudo", "install", "-m", "0644", "--", str(source), str(staging)]
                )
                command(["sudo", "mv", "-T", "--", str(staging), str(destination)])
            if hashlib.sha256(destination.read_bytes()).hexdigest() != digest:
                fail(f"Repository verification failed: {destination}")
            owned[name] = digest
            receipt["pendingRepository"] = None
            save(receipt_path, receipt)


def package_map(value, native_platform):
    if not isinstance(value, dict) or set(value) != set(BACKENDS[native_platform]):
        fail(
            f"Expected package lists for {native_platform}: {BACKENDS[native_platform]}"
        )
    result = {}
    for backend, packages in value.items():
        if not isinstance(packages, list):
            fail("Package declarations must be lists.")
        for name in packages:
            if not isinstance(name, str) or not NAME.fullmatch(name):
                fail(
                    "Use exact package names, without repositories, groups or versions."
                )
            if backend == "dnf" and "@" in name:
                fail(
                    "DNF declarations must be RPM names, not @group or module selectors."
                )
            if name in result and result[name] != backend:
                fail(f"Package {name} is declared through multiple native backends.")
            result[name] = backend
    return result


def load_manifest(path, host):
    manifest = read_json(path)
    if not isinstance(manifest, dict) or manifest.get("version") not in (1, 2, 4):
        fail(
            "Unsupported manifest version; switch Home Manager to generate the current manifest."
        )
    if manifest.get("host") != host:
        fail("Manifest must match the explicit --host.")
    native_platform = manifest.get("platform", manifest.get("os"))
    if (
        native_platform is not None and not isinstance(native_platform, str)
    ) or native_platform not in BACKENDS:
        fail(f"Unsupported native package platform: {native_platform}")
    machine_arch = {"arm64": "aarch64"}.get(platform.machine(), platform.machine())
    kernel = "darwin" if sys.platform == "darwin" else "linux"
    system = f"{machine_arch}-{kernel}"
    if manifest.get("system") != system:
        fail(f"Manifest system does not match {system}.")
    if kernel == "darwin":
        if native_platform != "darwin" or manifest.get("os") != "darwin":
            fail("Darwin requires the Homebrew mapping.")
        hardware = command(
            ["ioreg", "-rd1", "-c", "IOPlatformExpertDevice", "-a"], capture=True
        )
        machine = plistlib.loads(hardware.stdout.encode())[0]["IOPlatformUUID"]
    else:
        release = platform.freedesktop_os_release()
        families = (release.get("ID", ""), *release.get("ID_LIKE", "").split())
        if native_platform is not None and native_platform not in families:
            fail(
                f"Manifest platform {native_platform} does not match this Linux distro."
            )
        is_wsl = "microsoft" in Path("/proc/sys/kernel/osrelease").read_text().lower()
        expected_os = "wsl" if is_wsl else native_platform
        if manifest.get("os") != expected_os or (
            native_platform is None and not is_wsl
        ):
            fail("Manifest OS does not match this host.")
        machine = Path("/etc/machine-id").read_text().strip()
    if not machine:
        fail("A stable machine identity is required.")
    identity = {"host": host, "system": system, "machine": machine}
    backend = Backend(native_platform, manifest.get("repositories", {}))
    # Prevent Homebrew installs/uninstalls from pruning unrelated dependencies
    # or performing a system-wide update as a side effect.
    if native_platform == "darwin":
        os.environ["HOMEBREW_NO_AUTOREMOVE"] = "1"
        os.environ["HOMEBREW_NO_AUTO_UPDATE"] = "1"
    desired = package_map(manifest.get("packages"), native_platform)
    return identity, desired, backend


def load_receipt(path, identity, backend):
    if not path.exists():
        return {"version": 3, "identity": identity, "owned": {}, "pending": None}
    receipt = read_json(path)
    if not isinstance(receipt, dict) or receipt.get("version") not in (1, 2, 3):
        fail("Unsupported ownership receipt; refusing to reset it.")
    if receipt.get("identity") != identity:
        fail("Receipt belongs to a different machine or host. Refusing reconciliation.")
    owned = receipt.get("owned")
    if not isinstance(owned, dict) or any(
        not NAME.fullmatch(name) or kind not in BACKENDS[backend.platform]
        for name, kind in owned.items()
    ):
        fail("Invalid ownership receipt.")
    if "pending" not in receipt:
        fail("Ownership receipt is missing its transaction journal.")
    pending = receipt["pending"]
    if pending is not None and (
        not isinstance(pending, dict)
        or set(pending) not in ({"name", "backend"}, {"name", "backend", "retain"})
        or not isinstance(pending.get("retain", False), bool)
        or not isinstance(pending["name"], str)
        or not NAME.fullmatch(pending["name"])
        or pending["backend"] not in BACKENDS[backend.platform]
    ):
        fail("Invalid pending transaction.")
    retained = receipt.setdefault("retained", [])
    if not isinstance(retained, list) or any(
        not isinstance(name, str) or name not in owned for name in retained
    ):
        fail("Invalid retained package ownership receipt.")
    receipt.pop("retained", None)
    if pending:
        pending.pop("retain", None)
    receipt["version"] = 3
    return receipt


def recover(receipt, installed):
    pending = receipt["pending"]
    if pending and present(installed, pending["name"], pending["backend"]):
        receipt["owned"][pending["name"]] = pending["backend"]
    receipt["pending"] = None
    receipt["owned"] = {
        name: backend
        for name, backend in receipt["owned"].items()
        if present(installed, name, backend)
    }


def make_plan(desired, receipt, installed, adopt):
    for name in adopt:
        if name not in desired or not present(installed, name, desired[name]):
            fail(f"Can only adopt a declared, installed package: {name}")
    owned = receipt["owned"]
    for name in set(owned) & set(desired):
        if owned[name] != desired[name] and {owned[name], desired[name]} != {
            "pacman",
            "aur",
        }:
            fail(
                f"Package {name} changed native backend; resolve ownership explicitly."
            )
    installed_names = {
        name for name, kind in desired.items() if present(installed, name, kind)
    }
    return {
        "install": sorted(set(desired) - installed_names),
        "remove": sorted(set(owned) - set(desired)),
        "adopt": sorted(set(adopt) - set(owned)),
        "preserve": sorted((set(desired) & installed_names) - set(owned) - set(adopt)),
    }


def show_plan(plan, identity):
    print(f"Native packages for {identity['host']} ({identity['system']})")
    for action, packages in plan.items():
        print(f"  {action}: {', '.join(packages) or '(none)'}")
    print(
        "Only owned targets are removed. On Arch, pacman also removes their unneeded dependencies; declared packages are protected."
    )


def apply(desired, receipt, plan, path, helper, yes, backend):
    if (
        any(
            plan[key]
            for key in ("install", "remove", "adopt", "repositories", "mark-explicit")
        )
        and not yes
    ):
        if not sys.stdin.isatty():
            fail("Apply requires an interactive confirmation or explicit --yes.")
        if input("Apply this native package plan? [y/N] ").strip().lower() != "y":
            fail("Cancelled; no package changes made.")
    if any(desired[name] == "aur" for name in plan["install"]):
        helper = helper or shutil.which("paru") or shutil.which("yay")
        if not helper:
            fail("AUR installation requires an existing paru or yay.")
    backend.prepare_repositories(receipt, path, plan["repositories"])
    for name in plan["adopt"]:
        receipt["owned"][name] = desired[name]
    save(path, receipt)
    for name in plan["install"]:
        if present(backend.installed(), name, desired[name]):
            print(f"Preserving newly pre-existing package: {name}")
            continue
        kind = desired[name]
        args = backend.install_command(name, kind, helper)
        receipt["pending"] = {"name": name, "backend": kind}
        save(path, receipt)
        try:
            command(args)
        finally:
            # Failed helpers may still commit targets. Failed queries leave the
            # journal intact for recovery. Helpers/makepkg never run as root.
            if present(backend.installed(), name, desired[name]):
                receipt["owned"][name] = kind
            receipt["pending"] = None
            save(path, receipt)
        if name not in receipt["owned"]:
            fail(f"Install did not produce exact package {name}; stopping.")
    if backend.platform == "arch":
        installed = backend.installed()
        if any(not present(installed, name, kind) for name, kind in desired.items()):
            fail(
                "A declared package is missing; refusing removal until installation succeeds."
            )
        protect = backend.protection_plan(desired, installed)
        if protect:
            command(["sudo", "pacman", "-D", "--asexplicit", "--", *protect])
    if plan["remove"]:
        # Never cascade into reverse dependencies or bypass dependency checks.
        installed = backend.installed()
        targets = [
            name
            for name in plan["remove"]
            if present(installed, name, receipt["owned"][name])
        ]
        if targets:
            resolved = backend.removal_preview(targets, desired)
            if resolved != sorted(plan["remove"] + plan["remove-dependencies"]):
                print("Updated removal transaction: " + ", ".join(resolved), flush=True)
            for args in backend.remove_commands(targets, receipt["owned"]):
                command(args)
        remaining = backend.installed()
        for name in plan["remove"]:
            if not present(remaining, name, receipt["owned"][name]):
                receipt["owned"].pop(name, None)
        save(path, receipt)
        if any(name in receipt["owned"] for name in plan["remove"]):
            fail("Some removal targets remain installed; receipt retained for retry.")
    print("Native package reconciliation complete.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("check", "plan", "apply"))
    parser.add_argument("--host", required=True, help="Stable homeConfigurations key")
    parser.add_argument(
        "--manifest",
        type=Path,
        default=Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config")))
        / "native-packages/manifest.json",
    )
    parser.add_argument(
        "--state-dir",
        type=Path,
        default=Path(
            os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state"))
        )
        / "native-packages",
    )
    parser.add_argument(
        "--adopt",
        action="append",
        default=[],
        metavar="PACKAGE",
        help="Take ownership of a declared pre-existing package",
    )
    parser.add_argument("--aur-helper", choices=("paru", "yay"))
    parser.add_argument(
        "--yes",
        action="store_true",
        help="Approve adapter plan; package prompts remain",
    )
    args = parser.parse_args()
    if os.geteuid() == 0:
        fail("Run as your normal user; privileged package operations use sudo.")
    identity, desired, backend = load_manifest(args.manifest, args.host)
    if args.action == "check":
        backend.check_prerequisites(desired, args.aur_helper)
        return
    args.state_dir.mkdir(mode=0o700, parents=True, exist_ok=True)
    with (args.state_dir / "lock").open("a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            fail("Another native package command is running.")
        path = args.state_dir / "receipt.json"
        receipt = load_receipt(path, identity, backend)
        installed = backend.installed()
        recover(receipt, installed)
        plan = make_plan(desired, receipt, installed, args.adopt)
        plan["mark-explicit"] = backend.protection_plan(desired, installed)
        resolved = backend.removal_preview(plan["remove"], desired)
        plan["remove-dependencies"] = sorted(set(resolved) - set(plan["remove"]))
        plan["repositories"] = backend.repository_plan(receipt)
        show_plan(plan, identity)
        if args.action == "apply":
            apply(
                desired,
                receipt,
                plan,
                path,
                args.aur_helper,
                args.yes,
                backend,
            )


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        print(f"native-packages: {error}", file=sys.stderr)
        sys.exit(1)
    except KeyboardInterrupt:
        print(
            "\nnative-packages: interrupted; run plan/apply again to recover.",
            file=sys.stderr,
        )
        sys.exit(130)
