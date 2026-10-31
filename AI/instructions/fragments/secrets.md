# Secrets

## Accessing secrets

Maintain one persistent interactive terminal session for all credential-dependent commands for the duration of the agent session. Reuse the same running shell across tool calls; do not start a new terminal or shell for each command. If repeated 1Password approvals occur, investigate whether commands are using the same terminal before issuing further credential requests.

Resolution order:

1. Use the project's existing secret-loading setup when available, such as an application loading a mounted `.env` file.
2. Run commands normally. The interactive shell loads configured 1Password plugin wrappers; do not add another `op plugin run` around them. If authentication fails, inspect the command's resolution and authentication setup before retrying.
3. For commands without an existing credential source, use the 1Password MCP to find the appropriate Environment ID and inspect its variable names, then run `with-secrets <environment-id> <command> <args>` in the same terminal. Use the shared AI Environment for general AI tools.

## Creating secrets

If you create any new secrets, API keys, tokens (e.g. tokens for CI, service accounts etc.) make sure you record them somewhere, especially if they might need to be rotated one day. You should always ask before creating a new persistent secret.
