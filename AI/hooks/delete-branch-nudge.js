#!/usr/bin/env node
/**
 * Hook: Nudge to delete the local branch after a merge completes (git.md).
 *
 * Fires as a soft, non-blocking reminder — merging is a legitimate terminal
 * action, but git.md says the local branch should be cleaned up right after.
 * Matches a fast-forward `git merge --ff` (the merge strategy git.md asks
 * for) or a completed `gh pr merge`.
 */

const { addContext } = require("../lib/hooks/hook-response");

const COMPLETED_MERGE = /git\s+merge\b.*--ff\b|gh\s+pr\s+merge\b/;

let input = "";
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  const payload = JSON.parse(input);
  const command = payload.tool_input?.command ?? "";

  if (!COMPLETED_MERGE.test(command)) {
    return;
  }

  addContext("PostToolUse", "Once merged, delete the local branch: git branch -d <name>.");
});
