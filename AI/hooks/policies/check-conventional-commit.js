#!/usr/bin/env node
/**
 * Hook: Enforce conventional commit message format on `git commit` calls.
 *
 * Only validates commits using -m "message". Commits that open an editor
 * (no -m flag) are allowed through — the user is in control at that point.
 * Amends without -m are also allowed.
 *
 * Expected format: type(scope)?: description
 * Breaking change suffix (!) is supported: feat!: description
 */

const TYPES = [
  "feat",
  "fix",
  "chore",
  "docs",
  "style",
  "refactor",
  "perf",
  "test",
  "build",
  "ci",
  "revert",
];
const CONVENTIONAL = new RegExp(`^(${TYPES.join("|")})(\\(.+\\))?(!)?:\\s.+`);
const { block } = require("../lib/hook-response");

/**
 * Extract the commit message from a -m "..." or -m '...' flag.
 * Returns null if no -m flag is present.
 *
 * @param {string} command
 * @returns {string|null}
 */
function extractMessage(command) {
  const match = command.match(/-m\s+(['"])([\s\S]*?)\1/);
  return match ? match[2] : null;
}

let input = "";
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  const payload = JSON.parse(input);
  const command = payload.tool_input?.command ?? "";

  if (!/git\s+commit/.test(command)) {
    return;
  }

  // --amend without -m: user is editing the existing message manually
  if (/--amend/.test(command) && !/-m\s/.test(command)) {
    return;
  }

  const message = extractMessage(command);

  // No -m flag: editor will open, allow through
  if (!message) {
    return;
  }

  const firstLine = message.split("\n")[0];

  if (!CONVENTIONAL.test(firstLine)) {
    block("Commit message does not follow conventional commit format", [
      `Message: "${firstLine}"`,
      "Format:  type(scope)?: description",
      `Types:   ${TYPES.join(", ")}`,
    ]);
  }
});
