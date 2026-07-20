/**
 * Hook: Enforce conventional commit message format on `git commit` calls.
 *
 * Only validates commits using -m "message". Commits that open an editor
 * (no -m flag) are allowed through — the user is in control at that point.
 * Amends without -m are also allowed.
 *
 * Expected format: type(scope)?: description
 * Breaking change suffix (!) is supported: feat!: description
 *
 * Also enforces git.md's "first line max 70 chars" rule: the description
 * portion (after the `type(scope)?: ` prefix) must not exceed 70 characters,
 * so commit subjects stay skimmable in `git log --oneline` and PR lists.
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
// Group 4 captures the description so its length can be checked separately
// from the type/scope prefix.
const CONVENTIONAL = new RegExp(`^(${TYPES.join("|")})(\\(.+\\))?(!)?:\\s(.+)`);
const MAX_SUBJECT_LENGTH = 70;
const { block, doNothing } = require("../lib/hooks/policy-result");

/**
 * Extract the commit message from a -m "...", -m '...', or -m $'...' flag.
 * Only the first -m is read, since that is always the subject line when a
 * separate body is passed via additional -m flags. Returns null if no -m
 * flag is present.
 *
 * @param {string} command
 * @returns {string|null}
 */
function extractMessage(command) {
  const match = command.match(/-m\s+\$?(['"])([\s\S]*?)\1/);
  return match ? match[2] : null;
}

function evaluate(payload) {
  const command = payload.tool_input?.command ?? "";

  if (!/git\s+commit/.test(command)) {
    return doNothing();
  }

  // --amend without -m: user is editing the existing message manually
  if (/--amend/.test(command) && !/-m\s/.test(command)) {
    return doNothing();
  }

  const message = extractMessage(command);

  // No -m flag: editor will open, allow through
  if (!message) {
    return doNothing();
  }

  const firstLine = message.split("\n")[0];
  const conventionalMatch = firstLine.match(CONVENTIONAL);

  if (!conventionalMatch) {
    return block("Commit message does not follow conventional commit format", [
      `Message: "${firstLine}"`,
      "Format:  type(scope)?: description",
      `Types:   ${TYPES.join(", ")}`,
    ]);
  }

  const subject = conventionalMatch[4];

  if (subject.length > MAX_SUBJECT_LENGTH) {
    return block("Commit subject exceeds the 70 character limit", [
      `Subject: "${subject}" (${subject.length} chars)`,
      "First line max 70 chars — move detail into the commit body instead",
    ]);
  }

  return doNothing();
}

module.exports = { evaluate };
