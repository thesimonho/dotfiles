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

let input = '';
process.stdin.on('data', chunk => (input += chunk));
process.stdin.on('end', () => {
  const payload = JSON.parse(input);
  const command = payload.tool_input?.command ?? '';

  if (FORCE_PUSH.test(command)) {
    console.error('[Hook] BLOCKED: Force push is not allowed');
    console.error('[Hook] Rewriting remote history must be done manually');
    process.exit(1);
  }

  console.log(input);
});
