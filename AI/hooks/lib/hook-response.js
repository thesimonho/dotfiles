/**
 * Helpers for agent hook command responses.
 *
 * Claude Code and Codex both treat exit code 2 plus stderr as blocking
 * feedback for tool-use hooks, so policy scripts can stay agent-neutral.
 */

/**
 * Blocks the pending tool use with a human-readable reason.
 *
 * @param {string} reason
 * @param {string[]} details
 */
function block(reason, details = []) {
  console.error(`[Hook] BLOCKED: ${reason}`);

  for (const detail of details) {
    console.error(`[Hook] ${detail}`);
  }

  process.exit(2);
}

/**
 * Writes model-visible context for non-blocking reminder hooks.
 *
 * @param {string} hookEventName
 * @param {string} additionalContext
 */
function addContext(hookEventName, additionalContext) {
  process.stdout.write(
    JSON.stringify({
      hookSpecificOutput: {
        hookEventName,
        additionalContext,
      },
    }),
  );
}

module.exports = {
  addContext,
  block,
};
