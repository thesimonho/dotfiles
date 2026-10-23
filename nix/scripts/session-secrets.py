"""Resolve KDE login secrets without plaintext files or secret diagnostics."""

import json
import os
from pathlib import Path
import subprocess
import sys


def main():
    settings = json.loads(Path(sys.argv[1]).read_text())
    action = sys.argv[2]
    env = os.environ.copy()
    for name in ("FNOX_AGE_KEY", "FNOX_AGE_KEY_FILE", "FNOX_PROFILE"):
        env.pop(name, None)
    env["FNOX_CONFIG_DIR"] = settings["isolatedConfig"]
    env["FNOX_NON_INTERACTIVE"] = "1"
    fnox = [settings["fnox"], "--no-daemon", "--non-interactive"]

    def resolve(config, *args):
        locked = subprocess.run(
            ["/usr/bin/busctl", "--user", "get-property", "org.freedesktop.secrets",
             "/org/freedesktop/secrets/collection/kdewallet",
             "org.freedesktop.Secret.Collection", "Locked"],
            capture_output=True, check=True, timeout=3,
        )
        if locked.stdout.strip() != b"b false":
            raise RuntimeError("wallet must already be unlocked")
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

    if action == "environment":
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
    except Exception:
        # Provider/tool errors can include credential data. Never log them.
        print("Session secret operation failed; no secret details logged.", file=sys.stderr)
        sys.exit(1)
