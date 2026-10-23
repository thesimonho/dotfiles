"""Resolve KDE login secrets without plaintext files or secret diagnostics."""

import getpass
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import warnings


class EnrollmentError(Exception):
    """A fixed, credential-free message suitable for bootstrap output."""


def main():
    settings = json.loads(Path(sys.argv[1]).read_text())
    action = sys.argv[2]
    env = os.environ.copy()
    for name in ("FNOX_AGE_KEY", "FNOX_AGE_KEY_FILE", "FNOX_PROFILE"):
        env.pop(name, None)
    env["FNOX_CONFIG_DIR"] = settings["isolatedConfig"]
    env["FNOX_NON_INTERACTIVE"] = "1"
    fnox = [settings["fnox"], "--no-daemon", "--non-interactive"]

    def require_wallet():
        try:
            locked = subprocess.run(
                ["/usr/bin/busctl", "--user", "get-property", "org.freedesktop.secrets",
                 "/org/freedesktop/secrets/collection/kdewallet",
                 "org.freedesktop.Secret.Collection", "Locked"],
                capture_output=True, check=True, timeout=3,
            )
        except (subprocess.SubprocessError, OSError):
            raise EnrollmentError("Open and unlock kdewallet in KWallet Manager, enable its Secret Service API, then rerun bootstrap.") from None
        if locked.stdout.strip() != b"b false":
            raise EnrollmentError("Unlock kdewallet before rerunning bootstrap.")

    def resolve(config, *args):
        require_wallet()
        return subprocess.run(
            [*fnox, "-c", config, *args], env=env, capture_output=True,
            check=True, timeout=15,
        ).stdout

    def decrypt(path, output):
        identity = resolve(settings["identityConfig"], "get", "AGE_IDENTITY")
        subprocess.run(
            [settings["age"], "--decrypt", "--identity", "/dev/stdin", path],
            input=identity, stdout=output, stderr=subprocess.PIPE,
            check=True, timeout=30,
        )

    if action == "enroll":
        require_wallet()
        found = subprocess.run(
            ["/usr/bin/busctl", "--user", "--json=short", "call",
             "org.freedesktop.secrets", "/org/freedesktop/secrets",
             "org.freedesktop.Secret.Service", "SearchItems", "a{ss}", "2",
             "service", settings["keychainService"], "username", "age-identity"],
            capture_output=True, check=True, timeout=5,
        )
        unlocked, locked = json.loads(found.stdout)["data"]
        if locked:
            raise EnrollmentError("The age identity is in a locked collection. Unlock it and rerun bootstrap.")

        def validate(identity):
            result = subprocess.run(
                [settings["ageKeygen"], "-y"], input=identity,
                capture_output=True, timeout=5,
            )
            if result.returncode or result.stdout.decode().strip() != settings["ageRecipient"]:
                raise EnrollmentError("The age identity does not match this repository's public recipient. Nothing was replaced.")

        if unlocked:
            validate(resolve(settings["identityConfig"], "get", "AGE_IDENTITY"))
            print("Age identity already enrolled and verified; no prompt needed.")
            return
        try:
            with open("/dev/tty", "w") as terminal:
                if not terminal.isatty():
                    raise OSError("not a terminal")
                with warnings.catch_warnings():
                    warnings.simplefilter("error", getpass.GetPassWarning)
                    identity = (getpass.getpass("Age private key from Bitwarden (hidden): ", stream=terminal).strip() + "\n").encode()
        except (OSError, EOFError, getpass.GetPassWarning):
            raise EnrollmentError("Age identity is missing. Run bootstrap from an interactive terminal to enroll it.") from None
        validate(identity)
        # fnox writes its reference configuration; the key itself goes only over stdin.
        with tempfile.TemporaryDirectory(prefix="dotfiles-enrollment-") as directory:
            config = Path(directory) / "identity.toml"
            config.write_bytes(Path(settings["identityConfig"]).read_bytes())
            subprocess.run(
                [*fnox, "-c", str(config), "set", "AGE_IDENTITY",
                 "--provider", "keychain", "--key-name", "age-identity"],
                input=identity, env=env, capture_output=True, check=True, timeout=15,
            )
        stored = resolve(settings["identityConfig"], "get", "AGE_IDENTITY")
        validate(stored)
        if stored.strip() != identity.strip():
            raise EnrollmentError("Stored identity verification failed. Check KWallet before continuing.")
        print("Age identity enrolled in KWallet and verified.")
    elif action == "environment":
        result = json.loads(resolve(settings["globalConfig"], "env", "--json"))
        values = result["set"]
        if result.get("files") or set(values) != set(settings["globalKeys"]):
            raise ValueError("unexpected secret environment")
        for name in result.get("remove", []):
            env.pop(name, None)
        env.update(values)
        if values:
            subprocess.run(
                [settings["dbusUpdate"], "--systemd", *sorted(values)],
                env=env, capture_output=True, check=True, timeout=10,
            )
    elif action == "decrypt":
        decrypt(sys.argv[3], sys.stdout.buffer)
    elif action == "ssh":
        for key in settings["sshKeys"]:
            env["SSH_ASKPASS"] = key["askpass"]
            env["SSH_ASKPASS_REQUIRE"] = "force"
            reader, writer = os.pipe()
            with os.fdopen(reader, "rb") as source:
                child = subprocess.Popen(
                    [settings["sshAdd"], "-q", "-"], stdin=source,
                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, env=env,
                )
            try:
                with os.fdopen(writer, "wb") as destination:
                    decrypt(key["encrypted"], destination)
                if child.wait(timeout=30) != 0:
                    raise RuntimeError("SSH loading failed")
            finally:
                if child.poll() is None:
                    child.kill()
                    child.wait()
    else:
        raise ValueError("unknown action")


if __name__ == "__main__":
    try:
        main()
    except EnrollmentError as error:
        print(str(error) if sys.argv[2] == "enroll" else "Session secret operation failed; no secret details logged.", file=sys.stderr)
        sys.exit(1)
    except Exception:
        # Provider/tool errors can include credential data. Never log them.
        print("Session secret operation failed; no secret details logged.", file=sys.stderr)
        sys.exit(1)
