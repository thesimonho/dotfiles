/**
 * Hook: Verify pre-merge reminder.
 *
 * Verify-at-finish is the weakest measured behaviour. Right before a branch is
 * merged or a pull request is opened, if code changed this session and no
 * verify command has run since, this surfaces an advisory reminder — it does
 * NOT block. A soft reminder is deliberate: a hard block would halt in
 * environments without the tools a full verify needs (e.g. Claude web with no
 * browser). The model reads the reminder and decides. If measurement later
 * shows it is ignored too often, escalate to a decision:block.
 *
 * The merge/PR boundary is the checkpoint, not `git commit`. The verify skill
 * is explicitly scoped to "before merging or creating a PR" and tells the agent
 * not to rerun the suite after every edit, while git.md asks for small, frequent
 * commits — so firing per commit contradicted the very skill it points at, and
 * nagged on the majority of commits that are not a finished unit of work.
 * Because merges and PR creations are rare and each one really is the end of a
 * unit of work, this reminds every time, with no throttle needed.
 *
 * Only fires when the project has a real toolchain. Wire under PreToolUse for
 * the Bash tool.
 */

const fs = require("node:fs");
const path = require("node:path");
const { addContext, doNothing } = require("../lib/hooks/policy-result");
const state = require("../lib/hooks/session-state");

// Commands that end a unit of work: opening a pull/merge request on the common
// forges, or merging a branch locally.
const FINISH_COMMANDS = [
  /gh\s+pr\s+create/, // GitHub
  /glab\s+mr\s+create/, // GitLab
  /tea\s+pulls?\s+create/, // Gitea/Forgejo
  /git\s+merge\b/, // local merge, including fast-forward handoffs
];

// A project has verification tooling when one of these is present at cwd.
const TOOLING_MARKERS = [
  "justfile",
  "Justfile",
  "package.json",
  "Cargo.toml",
  "pyproject.toml",
  "go.mod",
];

/**
 * Whether the working directory has a verification toolchain worth reminding on.
 *
 * @param {string} cwd
 * @returns {boolean}
 */
function hasTooling(cwd) {
  return TOOLING_MARKERS.some((marker) =>
    fs.existsSync(path.join(cwd, marker)),
  );
}

function evaluate(payload) {
  const command = payload.tool_input?.command ?? "";

  if (!FINISH_COMMANDS.some((pattern) => pattern.test(command))) {
    return doNothing();
  }

  const session = state.read(payload.session_id);
  const cwd = payload.cwd ?? process.cwd();

  if (session.dirty && hasTooling(cwd)) {
    return addContext(
      "Code changed this session and no verify command ran afterward. Run the " +
        "/verify skill before merging or opening the pull request " +
        "— unless the remaining changes don't warrant it or this environment can't run it.",
    );
  }

  return doNothing();
}

module.exports = { evaluate };
