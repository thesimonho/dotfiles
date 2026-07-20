/**
 * Hook: Remind to run /simplify after substantial code changes.
 *
 * /simplify reviews recent code changes for reuse, quality, and efficiency; a
 * commit is the natural checkpoint. It deliberately does NOT inspect the diff or
 * guess which extensions count as "code" — a fight you can't win — and instead
 * fires on every git commit and lets the agent judge: run /simplify only if there
 * were substantial code changes, skip otherwise. It fires per commit rather than
 * once per session because a session is reused across many work cycles. A hook
 * can't invoke a skill, so it reminds the agent to. Wire under PreToolUse for Bash.
 */

const { addContext, doNothing } = require("../lib/hooks/policy-result");

function evaluate(payload) {
  const command = payload.tool_input?.command ?? "";
  if (!/git\s+commit/.test(command)) {
    return doNothing(); // the matcher is broad Bash; only act on commits
  }

  return addContext(
    "If this session made substantial code changes and you haven't run /simplify on them yet, do so before committing — it reviews recent changes for reuse, quality, and efficiency. Skip for small or docs-only changes.",
  );
}

module.exports = { evaluate };
