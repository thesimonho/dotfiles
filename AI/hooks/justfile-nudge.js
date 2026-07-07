#!/usr/bin/env node
/**
 * Hook: Nudge toward `just` recipes when a justfile exists.
 *
 * tools.md: "the project will have a justfile containing a set of recipes for
 * common tasks. Check that first before running your own custom commands."
 * This fires only when a build/test/lint-shaped command is about to bypass a
 * justfile that's actually present at the tool's cwd — otherwise it would nag
 * on every Bash call in a project that happens to have a justfile.
 */

const fs = require("node:fs");
const path = require("node:path");
const { addContext } = require("../lib/hooks/hook-response");

// package-manager `run <script>` invocations for the common build/test/lint
// tasks, plus bare invocations of the underlying tools those scripts wrap.
const BUILD_TEST_LINT_COMMAND =
  /\b(npm|pnpm|yarn|bun)\s+run\s+(build|test|lint|typecheck|check)\b|\b(tsc|eslint|jest|vitest|pytest|cargo\s+build|cargo\s+test|go\s+build|go\s+test)\b/;

// A command already routed through `just` (as the command itself, or after a
// leading env-var assignment) — this hook has nothing to add in that case.
const ALREADY_USES_JUST = /^(\s*[A-Za-z_][A-Za-z0-9_]*=\S+\s+)*just(\s|$)/;

/**
 * Whether a `justfile`/`Justfile` exists directly in the given directory.
 *
 * @param {string} directory
 * @returns {boolean}
 */
function hasJustfileIn(directory) {
  return (
    fs.existsSync(path.join(directory, "justfile")) ||
    fs.existsSync(path.join(directory, "Justfile"))
  );
}

let input = "";
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  const payload = JSON.parse(input);
  const command = payload.tool_input?.command ?? "";
  const cwd = payload.cwd ?? process.cwd();

  if (ALREADY_USES_JUST.test(command)) {
    return;
  }

  if (!BUILD_TEST_LINT_COMMAND.test(command)) {
    return;
  }

  if (!hasJustfileIn(cwd)) {
    return;
  }

  addContext(
    "PreToolUse",
    "This project has a justfile — check `just --list` for a recipe before running custom commands (tools.md).",
  );
});
