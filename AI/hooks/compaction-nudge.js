#!/usr/bin/env node
/**
 * Hook: Nudge to re-ground context at task boundaries (PR/merge/push).
 *
 * Standing instructions decay as context grows (see
 * reference_claude_vs_codex_instruction_adherence.md) — a PR create/merge or
 * a push is a natural checkpoint where one task ends and the next begins, so
 * that's the cue to suggest /compact or /clear before drift sets in.
 */

const { addContext } = require("../lib/hooks/hook-response");

// Command shapes that mark a task boundary worth re-grounding after.
const TASK_BOUNDARY_PATTERNS = [
  /\bgh\s+pr\s+create\b/,
  /\bgh\s+pr\s+merge\b/,
  /\bgit\s+merge\b.*--ff\b/,
  /\bgit\s+push\b/,
];

/**
 * Whether the command matches any task-boundary pattern.
 *
 * @param {string} command
 * @returns {boolean}
 */
function isTaskBoundaryCommand(command) {
  return TASK_BOUNDARY_PATTERNS.some((pattern) => pattern.test(command));
}

let input = "";
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  const payload = JSON.parse(input);
  const command = payload.tool_input?.command ?? "";
  if (!command || !isTaskBoundaryCommand(command)) {
    return;
  }

  addContext(
    "PostToolUse",
    "Task boundary reached (PR/merge/push). Good moment to /compact or /clear to re-ground context before the next task — long context is where standing instructions decay.",
  );
});
