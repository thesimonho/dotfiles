/**
 * PreToolUse gate: assess simplify before creating a PR. Either a completed
 * review or a reasoned skip satisfies the gate for the current branch state.
 */
const { block, doNothing } = require("../lib/hooks/policy-result");
const {
  snapshot,
  currentDecision,
  git,
} = require("../lib/hooks/review-checkpoint");
const { pullRequestCommands } = require("../lib/hooks/pr-command");

const CHECKPOINT = "rtk node ~/dotfiles/AI/lib/hooks/review-checkpoint-cli.js";

function evaluate(payload) {
  const requests = pullRequestCommands(
    payload.tool_input?.command ?? "",
    payload.cwd ?? process.cwd(),
  );
  for (const request of requests) {
    if (request.precedingWork) {
      return block(
        "Run preceding work separately, then retry PR creation so the checkpoint is checked against the resulting code state.",
      );
    }
    try {
      const current = snapshot(request.cwd);
      const sourceBranch = request.branch?.split(":").at(-1);
      if (sourceBranch && sourceBranch !== current.branch) {
        return block(
          "Create the PR from the checked-out source branch so its review decision can be checked.",
        );
      }
      if (request.repository) {
        const remotes = git(current.root, ["remote", "-v"])
          .trim()
          .split("\n")
          .map((line) => line.split(/\s+/)[1]?.replace(/\.git$/, ""));
        const repository = request.repository
          .replace(/\.git$/, "")
          .replace(/^https?:\/\/[^/]+\//, "");
        if (
          !remotes.some(
            (remote) =>
              remote?.endsWith("/" + repository) ||
              remote?.endsWith(":" + repository),
          )
        ) {
          return block(
            "Create the PR from its target repository checkout so its review decision can be checked.",
          );
        }
      }
      if (currentDecision(current)) continue;
      return block(
        "Assess whether this branch needs simplify before creating the PR. The review decision is missing or stale.",
        [
          "For substantial changes, run /simplify, resolve its concrete findings, commit the final changes, then record: " +
            CHECKPOINT +
            " reviewed",
          "For small, bounded, mechanical, or docs-only changes, record: " +
            CHECKPOINT +
            ' skip --reason "Why a review is unnecessary"',
          "Record from the PR's source checkout, then retry PR creation. No user approval is required for this assessment.",
        ],
      );
    } catch (error) {
      return block(
        "Could not check the branch's simplify decision. Run from a Git checkout with a committed branch.",
        [error.message],
      );
    }
  }
  return doNothing();
}

module.exports = { evaluate };
