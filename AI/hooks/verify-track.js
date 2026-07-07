#!/usr/bin/env node
/**
 * Hook: Track whether code has changed since the last verification.
 *
 * Feeds the verify Stop-gate. On a code edit it marks the session "dirty"; when a
 * recognised verify command runs it marks it "clean" again. The gate reads that
 * flag at turn-end. Wire under PostToolUse for Edit|Write|MultiEdit|Bash.
 */

const state = require("../lib/hooks/session-state");

const CODE_FILE =
  /\.(js|jsx|ts|tsx|mjs|cjs|py|go|rs|dart|java|kt|rb|c|cc|cpp|h|hpp|nix|sh|lua|vue|svelte)$/i;

// A command that constitutes verification: the project's just recipes, a package
// script, or a gate tool invoked directly.
const VERIFY_COMMAND =
  /\b(just\s+(verify|test|check|analyze|lint|typecheck|build)|(npm|pnpm|yarn|bun)\s+(run\s+)?(test|lint|typecheck|build|check)|tsc\b|eslint\b|oxlint\b|jest\b|vitest\b|pytest\b|ruff\b|pyright\b|mypy\b|cargo\s+(test|check|clippy)|go\s+(test|vet))/;

/**
 * The edited file path across Claude and Codex tool shapes.
 *
 * @param {object} toolInput
 * @returns {string}
 */
function editedPath(toolInput) {
  const direct = toolInput.file_path ?? toolInput.path ?? "";
  if (direct) {
    return direct;
  }
  const patched = (toolInput.command ?? "").match(/^\*\*\* (?:Add|Update) File: (.+)$/m);
  return patched ? patched[1] : "";
}

let input = "";
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  const payload = JSON.parse(input);
  const sessionId = payload.session_id;
  const toolName = payload.tool_name ?? "";
  const toolInput = payload.tool_input ?? {};

  if (toolName === "Bash") {
    if (VERIFY_COMMAND.test(toolInput.command ?? "")) {
      state.update(sessionId, { dirty: false });
    }
    return;
  }

  // Edit / Write / MultiEdit (or a Codex apply_patch carried on Bash is handled
  // above via the command; here we cover the structured file tools).
  if (CODE_FILE.test(editedPath(toolInput))) {
    state.update(sessionId, { dirty: true });
  }
});
