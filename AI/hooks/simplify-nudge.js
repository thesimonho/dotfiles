#!/usr/bin/env node
/**
 * Hook: Remind to run /simplify after substantial code changes.
 *
 * /simplify reviews recent code changes for reuse, quality, and efficiency; a
 * commit is the natural checkpoint. It deliberately does NOT inspect the diff or
 * guess which extensions count as "code" — a fight you can't win — and instead
 * fires once per session on a git commit and lets the agent judge: run /simplify
 * only if there were substantial code changes, skip otherwise. A hook can't
 * invoke a skill, so it reminds the agent to. Wire under PreToolUse for Bash.
 */

const { addContext } = require("../lib/hooks/hook-response");
const state = require("../lib/hooks/session-state");

let input = "";
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  const payload = JSON.parse(input);
  const command = payload.tool_input?.command ?? "";
  if (!/git\s+commit/.test(command)) {
    return; // the matcher is broad Bash; only act on commits
  }

  const sessionId = payload.session_id;
  if (state.read(sessionId).simplifyNudged) {
    return; // once per session
  }
  state.update(sessionId, { simplifyNudged: true });

  addContext(
    "PreToolUse",
    "If this session made substantial code changes and you haven't run /simplify on them yet, do so before committing — it reviews recent changes for reuse, quality, and efficiency. Skip for small or docs-only changes.",
  );
});
