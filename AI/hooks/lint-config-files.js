#!/usr/bin/env node
/**
 * Hook: Nudge toward the matching configured linter after editing a config file.
 *
 * tools.md says to "assume linters are installed and configured" and to use
 * them first when double-checking code. This maps a handful of well-known
 * config/script file shapes to their dedicated linter, so the agent is
 * reminded to run the specific tool rather than eyeballing the diff.
 * Agent-neutral: reads the Claude tool_input.file_path as well as the path
 * embedded in a Codex apply_patch command body.
 */

const { addContext, doNothing } = require("../lib/hooks/policy-result");

// Ordered path-shape -> linter-nudge rules. Order matters only in that the
// first match wins; the shapes below don't overlap in practice.
const LINTER_RULES = [
  {
    matches: (filePath) => /(^|\/)\.github\/workflows\/[^/]+\.ya?ml$/.test(filePath),
    message: "Edited a GitHub workflow — run actionlint to validate.",
  },
  {
    matches: (filePath) => /(^|\/)Dockerfile$|\.dockerfile$/.test(filePath),
    message: "Edited a Dockerfile — run hadolint to validate.",
  },
  {
    matches: (filePath) => /\.(sh|bash)$/.test(filePath),
    message: "Edited a shell script — run shellcheck to validate.",
  },
  {
    matches: (filePath) => /\.tf$/.test(filePath),
    message: "Edited a Terraform file — run tflint to validate.",
  },
];

/**
 * The file path an Edit/Write/MultiEdit targeted, across Claude and Codex
 * tool shapes (Codex apply_patch carries the path inside the command body).
 *
 * @param {object} toolInput
 * @returns {string}
 */
function targetPathFrom(toolInput) {
  const direct = toolInput.file_path ?? toolInput.path ?? "";
  if (direct) {
    return direct;
  }

  const command = toolInput.command ?? "";
  const patched = command.match(/^\*\*\* (?:Add|Update) File: (.+)$/m);
  return patched ? patched[1] : "";
}

function evaluate(payload) {
  const target = targetPathFrom(payload.tool_input ?? {});
  if (!target) {
    return doNothing();
  }

  const rule = LINTER_RULES.find((candidate) => candidate.matches(target));
  if (!rule) {
    return doNothing();
  }

  return addContext(rule.message);
}

module.exports = { evaluate };
