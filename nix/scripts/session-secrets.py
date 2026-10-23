"""Resolve secrets through native keyrings without plaintext staging."""

import ctypes
import getpass
import json
import os
import subprocess
import sys
import tempfile
import warnings
from pathlib import Path


class EnrollmentError(Exception):
    """A fixed, credential-free message suitable for bootstrap output."""


class UnsupportedPlatform(EnrollmentError):
    """A platform capability is deliberately unavailable."""


def macos_identity_present(service):
    """Query attributes only, preserving native errors instead of CLI exit codes."""
    security = ctypes.CDLL("/System/Library/Frameworks/Security.framework/Security")
    core = ctypes.CDLL(
        "/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation"
    )
    pointer = ctypes.c_void_p
    core.CFDictionaryCreateMutable.argtypes = [pointer, ctypes.c_long, pointer, pointer]
    core.CFDictionaryCreateMutable.restype = pointer
    core.CFDictionarySetValue.argtypes = [pointer, pointer, pointer]
    core.CFDictionarySetValue.restype = None
    core.CFStringCreateWithCString.argtypes = [
        pointer,
        ctypes.c_char_p,
        ctypes.c_uint32,
    ]
    core.CFStringCreateWithCString.restype = pointer
    core.CFRelease.argtypes = [pointer]
    core.CFRelease.restype = None
    security.SecItemCopyMatching.argtypes = [pointer, ctypes.POINTER(pointer)]
    security.SecItemCopyMatching.restype = ctypes.c_int32
    # Null callbacks are intentional: constants and owned strings live through the query.
    query = core.CFDictionaryCreateMutable(None, 0, None, None)
    strings = []
    result = pointer()
    try:

        def symbol(library, name):
            return pointer.in_dll(library, name).value

        def put(name, value):
            core.CFDictionarySetValue(query, symbol(security, name), value)

        put("kSecClass", symbol(security, "kSecClassGenericPassword"))
        for name, value in [
            ("kSecAttrService", service),
            ("kSecAttrAccount", "age-identity"),
        ]:
            text = core.CFStringCreateWithCString(None, value.encode(), 0x08000100)
            strings.append(text)
            put(name, text)
        put("kSecReturnAttributes", symbol(core, "kCFBooleanTrue"))
        put("kSecMatchLimit", symbol(security, "kSecMatchLimitOne"))
        put("kSecUseAuthenticationUI", symbol(security, "kSecUseAuthenticationUIFail"))
        status = security.SecItemCopyMatching(query, ctypes.byref(result))
        if status == 0:
            return True
        if status == -25300:  # errSecItemNotFound
            return False
        raise EnrollmentError(
            "Cannot query macOS Keychain. Unlock the login keychain and allow access, then retry. Nothing was replaced."
        )
    finally:
        for value in [result.value, query, *strings]:
            if value:
                core.CFRelease(value)


def main():
    settings = json.loads(Path(sys.argv[1]).read_text())
    action = sys.argv[2]
    platform = settings["platform"]
    if platform not in ("kde", "macos"):
        raise UnsupportedPlatform(
            "Native secret delivery is not implemented for WSL or this desktop. Activation stopped; no file fallback is available."
        )
    if action == "check-platform":
        return
    store_name = "KWallet" if platform == "kde" else "macOS Keychain"
    env = os.environ.copy()
    for name in ("FNOX_AGE_KEY", "FNOX_AGE_KEY_FILE", "FNOX_PROFILE"):
        env.pop(name, None)
    env["FNOX_CONFIG_DIR"] = settings["isolatedConfig"]
    env["FNOX_NON_INTERACTIVE"] = "1"
    fnox = [settings["fnox"], "--no-daemon", "--non-interactive"]

    def require_wallet():
        if platform == "macos":
            return  # Keychain access and consent are handled by the native provider.
        try:
            locked = subprocess.run(
                [
                    "/usr/bin/busctl",
                    "--user",
                    "get-property",
                    "org.freedesktop.secrets",
                    "/org/freedesktop/secrets/collection/kdewallet",
                    "org.freedesktop.Secret.Collection",
                    "Locked",
                ],
                capture_output=True,
                check=True,
                timeout=3,
            )
        except (subprocess.SubprocessError, OSError):
            raise EnrollmentError(
                "Open and unlock kdewallet in KWallet Manager, enable its Secret Service API, then rerun bootstrap."
            ) from None
        if locked.stdout.strip() != b"b false":
            raise EnrollmentError("Unlock kdewallet before rerunning bootstrap.")

    def resolve(config, *args):
        require_wallet()
        return subprocess.run(
            [*fnox, "-c", config, *args],
            env=env,
            capture_output=True,
            check=True,
            timeout=15,
        ).stdout

    def decrypt(path, output):
        identity = resolve(settings["identityConfig"], "get", "AGE_IDENTITY")
        subprocess.run(
            [settings["age"], "--decrypt", "--identity", "/dev/stdin", path],
            input=identity,
            stdout=output,
            stderr=subprocess.PIPE,
            check=True,
            timeout=30,
        )

    def identity_present():
        if platform == "macos":
            return macos_identity_present(settings["keychainService"])
        require_wallet()
        found = subprocess.run(
            [
                "/usr/bin/busctl",
                "--user",
                "--json=short",
                "call",
                "org.freedesktop.secrets",
                "/org/freedesktop/secrets",
                "org.freedesktop.Secret.Service",
                "SearchItems",
                "a{ss}",
                "2",
                "service",
                settings["keychainService"],
                "username",
                "age-identity",
            ],
            capture_output=True,
            check=True,
            timeout=5,
        )
        unlocked, locked = json.loads(found.stdout)["data"]
        if locked:
            raise EnrollmentError(
                "The age identity is in a locked collection. Unlock it and rerun bootstrap."
            )
        return bool(unlocked)

    if action == "enroll":

        def validate(identity):
            result = subprocess.run(
                [settings["ageKeygen"], "-y"],
                input=identity,
                capture_output=True,
                timeout=5,
            )
            if (
                result.returncode
                or result.stdout.decode().strip() != settings["ageRecipient"]
            ):
                raise EnrollmentError(
                    "The age identity does not match this repository's public recipient. Nothing was replaced."
                )

        if identity_present():
            validate(resolve(settings["identityConfig"], "get", "AGE_IDENTITY"))
            print("Age identity already enrolled and verified; no prompt needed.")
            return
        try:
            with open("/dev/tty", "w") as terminal:
                if not terminal.isatty():
                    raise OSError("not a terminal")
                with warnings.catch_warnings():
                    warnings.simplefilter("error", getpass.GetPassWarning)
                    identity = (
                        getpass.getpass(
                            "Age private key from Bitwarden (hidden): ", stream=terminal
                        ).strip()
                        + "\n"
                    ).encode()
        except (OSError, EOFError, getpass.GetPassWarning):
            raise EnrollmentError(
                "Age identity is missing. Run bootstrap from an interactive terminal to enroll it."
            ) from None
        validate(identity)
        # fnox writes its reference configuration; the key itself goes only over stdin.
        with tempfile.TemporaryDirectory(prefix="dotfiles-enrollment-") as directory:
            config = Path(directory) / "identity.toml"
            config.write_bytes(Path(settings["identityConfig"]).read_bytes())
            subprocess.run(
                [
                    *fnox,
                    "-c",
                    str(config),
                    "set",
                    "AGE_IDENTITY",
                    "--provider",
                    "keychain",
                    "--key-name",
                    "age-identity",
                ],
                input=identity,
                env=env,
                capture_output=True,
                check=True,
                timeout=15,
            )
        stored = resolve(settings["identityConfig"], "get", "AGE_IDENTITY")
        validate(stored)
        if stored.strip() != identity.strip():
            raise EnrollmentError(
                "Stored identity verification failed. Check the native keyring before continuing."
            )
        print(f"Age identity enrolled in {store_name} and verified.")
    elif action == "environment":
        if platform == "macos":
            raise UnsupportedPlatform(
                "macOS desktop API delivery is not implemented pending runtime verification. Use fnox exec for explicit terminal commands."
            )
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
                env=env,
                capture_output=True,
                check=True,
                timeout=10,
            )
    elif action == "decrypt":
        decrypt(sys.argv[3], sys.stdout.buffer)
    elif action == "ssh":
        if platform == "macos":
            # Manual terminal loading only; native passphrase caching is unverified.
            with open("/dev/tty", "w"):
                pass
        for key in settings["sshKeys"]:
            if platform == "kde":
                env["SSH_ASKPASS"] = key["askpass"]
                env["SSH_ASKPASS_REQUIRE"] = "force"
            else:
                env["SSH_ASKPASS_REQUIRE"] = "never"
            reader, writer = os.pipe()
            with os.fdopen(reader, "rb") as source:
                child = subprocess.Popen(
                    [settings["sshAdd"], "-q", "-"],
                    stdin=source,
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    env=env,
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
        print(
            str(error)
            if sys.argv[2] == "enroll" or isinstance(error, UnsupportedPlatform)
            else "Session secret operation failed; no secret details logged.",
            file=sys.stderr,
        )
        sys.exit(1)
    except Exception:
        # Provider/tool errors can include credential data. Never log them.
        print(
            "Session secret operation failed; no secret details logged.",
            file=sys.stderr,
        )
        sys.exit(1)
