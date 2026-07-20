#!/usr/bin/env node
/**
 * Hook: Block all variants of git force push.
 *
 * Catches -f, --force, and --force-with-lease. The latter is blocked
 * because in an agentic context there's no meaningful distinction —
 * force rewriting remote history should always be a manual action.
 */

// Matches: git push ... -f / --force / --force-with-lease
const FORCE_PUSH = /git\s+push\b.*(\s-f\b|\s--force\b|\s--force-with-lease\b)/;
const { block, doNothing } = require("../lib/hooks/policy-result");

/**
 * @param {object} payload
 * @returns {{ effect: string, reason?: string, details?: string[] }}
 */
function evaluate(payload) {
  const command = payload.tool_input?.command ?? "";

  if (FORCE_PUSH.test(command)) {
    return block("Force push is not allowed", [
      "Rewriting remote history must be done manually",
    ]);
  }

  return doNothing();
}

module.exports = { evaluate };
