#!/usr/bin/env node
/**
 * Hook: Nudge to delete the local branch after a merge completes.
 *
 * Fires as a soft, non-blocking reminder — merging is a legitimate terminal
 * action, but the local branch should be cleaned up right after. That rule
 * lives here rather than in prose. Matches a fast-forward `git merge --ff`
 * (the merge strategy git.md asks for) or a completed `gh pr merge`.
 */

const { addContext, doNothing } = require("../lib/hooks/policy-result");

const COMPLETED_MERGE = /git\s+merge\b.*--ff\b|gh\s+pr\s+merge\b/;

function evaluate(payload) {
  const command = payload.tool_input?.command ?? "";

  if (!COMPLETED_MERGE.test(command)) {
    return doNothing();
  }

  return addContext("Once merged, delete the local branch: git branch -d <name>.");
}

module.exports = { evaluate };
