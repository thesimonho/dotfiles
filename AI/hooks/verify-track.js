#!/usr/bin/env node
/**
 * Hook: Track whether code has changed since the last verification.
 *
 * Feeds the verify pre-commit gate. On a code edit it marks the session
 * "dirty"; when a recognised verify command runs it marks it "clean" again.
 * The gate reads that flag right before a `git commit`. Wire under
 * PostToolUse for Edit|Write|MultiEdit|Bash.
 *
 * Edits outside the project (scratchpad/tmp helper scripts, files above cwd) are
 * ignored entirely — they're not project code and shouldn't demand a verify run
 * or feed the coupling gate.
 */

const path = require("node:path");
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

  // Edit / Write / MultiEdit. Record the path (for the coupling gate) and, for
  // code files, flag the session dirty (for the verify gate).
  const edited = editedPath(toolInput);
  if (!edited) {
    return;
  }
  const cwd = payload.cwd ?? process.cwd();
  const relative = path.relative(cwd, path.resolve(cwd, edited));
  if (relative.startsWith("..")) {
    return; // outside the project (e.g. a scratchpad helper script) — not project code
  }
  const priorEdited = state.read(sessionId).edited ?? [];
  const patch = { edited: [...new Set([...priorEdited, relative])] };
  if (CODE_FILE.test(edited)) {
    patch.dirty = true;
  }
  state.update(sessionId, patch);
});
