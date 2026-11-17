# Secrets

## Accessing secrets

If authentication fails, report the missing variable or authentication error. Running apps retain inherited values until exit, including after 1Password locks; fully restart them to pick up rotations. Remote, VM, or isolated runtimes may not inherit host credentials.

If the user explicitly requests a direct 1Password lookup, warn that it may trigger approval and reuse one persistent interactive terminal for those requests.

## Creating secrets

If you create any new secrets, API keys, tokens (e.g. tokens for CI, service accounts etc.) make sure you record them somewhere, especially if they might need to be rotated one day. You should always ask before creating a new persistent secret.
