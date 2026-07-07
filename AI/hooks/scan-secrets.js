#!/usr/bin/env node
/**
 * Hook: Block hardcoded secrets from being written into the repo.
 *
 * security.md is explicit — "No hardcoded secrets (API keys, passwords, tokens).
 * Use environment variables instead." A leaked credential in a commit is expensive
 * to undo (rotation, history scrubbing), so this blocks at write-time rather than
 * relying on a later review to catch it.
 *
 * Scans the content Edit/Write/MultiEdit would introduce, plus Bash commands that
 * carry a Codex apply_patch body (`*** Add File:` / `*** Update File:` followed by
 * `+`-prefixed lines), for known credential shapes and generic secret-assignment
 * patterns. Obvious placeholders (process.env, <angle brackets>, "xxx", "example",
 * etc.) are ignored so scaffolding and docs don't get flagged.
 */

const { block } = require("../lib/hooks/hook-response");

// Known credential shapes: provider-specific tokens whose format alone is a
// strong enough signal to block without a nearby variable name.
const KNOWN_SECRET_PATTERNS = [
  { name: "AWS access key", pattern: /AKIA[0-9A-Z]{16}/ },
  { name: "private key header", pattern: /-----BEGIN [A-Z ]*PRIVATE KEY-----/ },
  { name: "GitHub token", pattern: /ghp_[A-Za-z0-9]{30,}/ },
  { name: "OpenAI-style API key", pattern: /sk-[A-Za-z0-9]{20,}/ },
  { name: "Slack token", pattern: /xox[baprs]-[A-Za-z0-9-]{10,}/ },
];

// Generic shape: a secret-ish variable name assigned a literal string of
// meaningful length, e.g. `password = "hunter2pass"` or `api_key: "abcdef123"`.
const SECRET_ASSIGNMENT = {
  name: "hardcoded secret assignment",
  pattern: /(password|passwd|secret|api[_-]?key|token|access[_-]?key)\s*[:=]\s*["'][^"']{8,}["']/i,
};

// Values that look like secrets but obviously aren't — env references,
// templated placeholders, or redaction markers.
const PLACEHOLDER_MARKERS =
  /process\.env|os\.environ|[<>]|xxx|example|changeme|your_|placeholder|redacted|\*\*\*\*/i;

/**
 * The text a write would introduce, across Claude and Codex tool shapes.
 *
 * @param {object} toolInput
 * @returns {string}
 */
function writtenContentFrom(toolInput) {
  const parts = [toolInput.content, toolInput.new_string, toolInput.command];
  return parts.filter((part) => typeof part === "string").join("\n");
}

/**
 * The single line a match occurred on, used to check for nearby placeholder
 * markers without letting an unrelated line's `process.env` mask a real secret
 * elsewhere in the same file.
 *
 * @param {string} content
 * @param {number} matchIndex
 * @returns {string}
 */
function lineContaining(content, matchIndex) {
  const lineStart = content.lastIndexOf("\n", matchIndex) + 1;
  const lineEndIndex = content.indexOf("\n", matchIndex);
  const lineEnd = lineEndIndex === -1 ? content.length : lineEndIndex;
  return content.slice(lineStart, lineEnd);
}

/**
 * Find the first secret pattern that matches real (non-placeholder) content.
 *
 * @param {string} content
 * @returns {{name: string}|null}
 */
function firstRealSecretMatch(content) {
  for (const candidate of [...KNOWN_SECRET_PATTERNS, SECRET_ASSIGNMENT]) {
    const match = candidate.pattern.exec(content);
    if (!match) {
      continue;
    }

    const line = lineContaining(content, match.index);
    if (!PLACEHOLDER_MARKERS.test(line)) {
      return candidate;
    }
  }
  return null;
}

let input = "";
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  const payload = JSON.parse(input);
  const content = writtenContentFrom(payload.tool_input ?? {});
  if (!content) {
    return;
  }

  const found = firstRealSecretMatch(content);
  if (!found) {
    return;
  }

  block("Hardcoded secret detected in written content", [
    `Pattern: ${found.name}`,
    "security.md: no hardcoded secrets — use environment variables instead.",
  ]);
});
