/**
 * Hook: Remind to run /simplify before opening a pull request.
 *
 * /simplify reviews recent code changes for reuse, quality, and efficiency. A
 * pull request is the natural checkpoint: it is the point where a whole branch
 * goes out for review, so cleanup lands once per unit of work instead of once
 * per commit. Firing on every `git commit` nudged far too often — commits are
 * deliberately small and frequent, and most of them are not worth a review pass.
 *
 * It deliberately does NOT inspect the diff or guess which extensions count as
 * "code" — a fight you can't win — and instead lets the agent judge: run
 * /simplify only if the branch has substantial code changes, skip otherwise.
 * A hook can't invoke a skill, so it reminds the agent to. Wire under PreToolUse
 * for Bash.
 */

const { addContext, doNothing } = require("../lib/hooks/policy-result");

// Commands that open a pull/merge request on the common forges.
const PULL_REQUEST_COMMANDS = [
  /gh\s+pr\s+create/, // GitHub
  /glab\s+mr\s+create/, // GitLab
  /tea\s+pulls?\s+create/, // Gitea/Forgejo
];

function evaluate(payload) {
  const command = payload.tool_input?.command ?? "";
  const isOpeningPullRequest = PULL_REQUEST_COMMANDS.some((pattern) => pattern.test(command));

  if (!isOpeningPullRequest) {
    return doNothing(); // the matcher is broad Bash; only act on PR creation
  }

  return addContext(
    "If this branch made substantial code changes and you haven't run /simplify on them yet, do so before opening the PR — it reviews the changes for reuse, quality, and efficiency. Commit any resulting fixes before continuing. Skip for small or docs-only branches.",
  );
}

module.exports = { evaluate };
