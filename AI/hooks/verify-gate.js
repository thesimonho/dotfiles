#!/usr/bin/env node
/**
 * Hook: Verify Stop-reminder.
 *
 * Verify-at-finish is the weakest measured behaviour. At turn-end, if code
 * changed this session and no verify command ran after it, this surfaces an
 * advisory reminder — it does NOT block. A soft reminder is deliberate: a hard
 * block would force unnecessary compute on doc-only-adjacent turns and would
 * halt in environments without the tools a full verify needs (e.g. Claude web
 * with no browser). The model reads the reminder and decides. If measurement
 * later shows it is ignored too often, escalate to a decision:block.
 *
 * Only fires when the project has a real toolchain. Wire under the Stop event.
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
  const session = state.read(payload.session_id);
  const cwd = payload.cwd ?? process.cwd();

  if (session.dirty && hasTooling(cwd)) {
    addContext(
      "Stop",
      "Code changed this session and no verify command ran afterward. Run the " +
        "project's verify recipe (e.g. `just verify`, `npm test`) before finishing " +
        "— unless the remaining changes don't warrant it or this environment can't run it.",
    );
  }
});
