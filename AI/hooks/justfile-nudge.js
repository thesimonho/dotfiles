#!/usr/bin/env node
/**
 * Hook: Nudge toward `just` recipes when a justfile exists.
 *
 * The rule lives here rather than in prose: when a project has a justfile of
 * recipes for common tasks, check it before running a custom command.
 * This fires only when a build/test/lint-shaped command is about to bypass a
 * justfile that's actually present at the tool's cwd — otherwise it would nag
 * on every Bash call in a project that happens to have a justfile.
 *
 * Even so narrowed it repeated often, so it is capped at once an hour: the point
 * is to make the agent look at `just --list`, and for the rest of that work
 * cycle the reminder has nothing left to teach. It's a window rather than once
 * per session so a later cycle — a compaction, a new task in a reused session —
 * hears it again.
 */

const fs = require("node:fs");
const path = require("node:path");
const { addContext, doNothing } = require("../lib/hooks/policy-result");
const { shouldNudge } = require("../lib/hooks/nudge-throttle");

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

function evaluate(payload) {
  const command = payload.tool_input?.command ?? "";
  const cwd = payload.cwd ?? process.cwd();

  if (ALREADY_USES_JUST.test(command)) {
    return doNothing();
  }

  if (!BUILD_TEST_LINT_COMMAND.test(command)) {
    return doNothing();
  }

  if (!hasJustfileIn(cwd)) {
    return doNothing();
  }

  // Checked last, so a command that was never going to nudge can't spend the
  // window.
  if (!shouldNudge(payload.session_id, "justfile")) {
    return doNothing();
  }

  return addContext(
    "This project has a justfile — check `just --list` for a recipe before running custom commands.",
  );
}

module.exports = { evaluate };
