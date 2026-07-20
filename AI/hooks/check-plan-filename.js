/**
 * Hook: Enforce the date-stamp naming convention for plan files.
 *
 * planning.md: plan file names should start with a date and time stamp
 * YYYYMMDD, e.g. `20231201-<name>.md`. Plans are snapshots — the date stamp is
 * what lets readers tell a current plan from a stale one at a glance, and lets
 * doc-lifecycle tooling sort/archive them. A plan written without the stamp
 * loses that signal permanently (renaming later is friction nobody does), so
 * this blocks at write-time rather than relying on review to catch it.
 *
 * Only applies to paths under a plans directory nested in docs; every other
 * Write/Edit target is left alone.
 */

const { block, doNothing } = require("../lib/hooks/policy-result");

const UNDER_DOCS_PLANS = /(^|\/)docs\/plans\//;
const DATE_STAMPED_BASENAME = /^\d{8}(-\d{4})?-/;

/**
 * The file path a Write/Edit targets, across Claude and Codex tool shapes.
 *
 * @param {object} toolInput
 * @returns {string}
 */
function targetPathFrom(toolInput) {
  const direct = toolInput.file_path ?? toolInput.path ?? "";
  if (direct) {
    return direct;
  }

  const command = toolInput.command ?? "";
  const patched = command.match(/^\*\*\* (?:Add|Update) File: (.+)$/m);
  return patched ? patched[1] : "";
}

function evaluate(payload) {
  const toolInput = payload.tool_input ?? {};
  const targets = toolInput.file_paths ?? [targetPathFrom(toolInput)].filter(Boolean);
  const planTargets = targets.filter((target) => UNDER_DOCS_PLANS.test(target));
  if (planTargets.length === 0) {
    return doNothing(); // not a plan file
  }

  const invalidTarget = planTargets.find((target) => {
    const basename = target.split("/").pop() ?? target;
    return !DATE_STAMPED_BASENAME.test(basename);
  });
  if (!invalidTarget) {
    return doNothing(); // already correctly named
  }

  return block(
    "Plan files nested under docs/plans must start with a YYYYMMDD date stamp.",
    [`Target: ${invalidTarget}`, "Example of a correctly named plan: 20260707-my-plan (dot) html"],
  );
}

module.exports = { evaluate };
