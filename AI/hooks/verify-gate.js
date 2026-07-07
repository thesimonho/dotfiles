#!/usr/bin/env node
/**
 * Hook: Verify pre-commit reminder.
 *
 * Verify-at-finish is the weakest measured behaviour. Right before a `git
 * commit` runs, if code changed this session and no verify command has run
 * since, this surfaces an advisory reminder — it does NOT block. A soft
 * reminder is deliberate: a hard block would halt in environments without the
 * tools a full verify needs (e.g. Claude web with no browser). The model reads
 * the reminder and decides. If measurement later shows it is ignored too
 * often, escalate to a decision:block.
 *
 * `git commit` is the natural checkpoint for this — it's the moment work gets
 * sealed into history — unlike a Stop/turn-end boundary, which fires on every
 * turn regardless of whether the work is actually finished. Because commits
 * are infrequent and each one is a real checkpoint, this reminds every time,
 * with no once-per-session throttle needed.
 *
 * Only fires when the project has a real toolchain. Wire under PreToolUse for
 * the Bash tool.
 */

const fs = require("node:fs");
const path = require("node:path");
const { addContext } = require("../lib/hooks/hook-response");
const state = require("../lib/hooks/session-state");

// A project has verification tooling when one of these is present at cwd.
const TOOLING_MARKERS = ["justfile", "Justfile", "package.json", "Cargo.toml", "pyproject.toml", "go.mod"];

/**
 * Whether the working directory has a verification toolchain worth reminding on.
 *
 * @param {string} cwd
 * @returns {boolean}
 */
function hasTooling(cwd) {
  return TOOLING_MARKERS.some((marker) => fs.existsSync(path.join(cwd, marker)));
}

let input = "";
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  const payload = JSON.parse(input);
  const command = payload.tool_input?.command ?? "";

  if (!/git\s+commit/.test(command)) {
    return;
  }

  const session = state.read(payload.session_id);
  const cwd = payload.cwd ?? process.cwd();

  if (session.dirty && hasTooling(cwd)) {
    addContext(
      "PreToolUse",
      "Code changed this session and no verify command ran afterward. Run the " +
        "project's verify recipe (e.g. `just verify`, `npm test`) before committing " +
        "— unless the remaining changes don't warrant it or this environment can't run it.",
    );
  }
});
