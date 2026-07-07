#!/usr/bin/env node
/**
 * Hook: Block secrets from entering a commit.
 *
 * security.md is explicit — "No hardcoded secrets. Use environment variables
 * instead." A leaked credential in history is expensive to undo (rotation,
 * scrubbing), so this blocks at commit time, the point where content would enter
 * history.
 *
 * It prefers gitleaks — the same scanner this repo already runs in CI
 * (.github/workflows/gitleaks.yaml) — and falls back to a small built-in pattern
 * set when gitleaks is not on PATH, so there is never a coverage gap and no hard
 * dependency (e.g. a fresh worktree before the toolchain is installed). Non-agent
 * commits (lazygit, manual) are covered by the same CI scan. Wire under
 * PreToolUse for Bash; it self-filters to `git commit`.
 */

const { execFileSync, spawnSync } = require("node:child_process");
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
 * Run a git command, returning stdout or "" (so callers fail open on non-repos).
 *
 * @param {string} cwd
 * @param {string[]} args
 * @returns {string}
 */
function git(cwd, args) {
  try {
    return execFileSync("git", args, { cwd, encoding: "utf8" });
  } catch {
    return "";
  }
}

/**
 * Which region a commit will include: the staged diff normally, or the unstaged
 * working-tree diff for the `git add … && git commit` one-liner (this hook runs
 * before the add, so nothing is staged yet). Returns the gitleaks flag and the
 * matching `git diff` args, or null when there is nothing to scan.
 *
 * @param {string} cwd
 * @returns {{gitleaksFlag: string, diffArgs: string[]}|null}
 */
function scanRegion(cwd) {
  if (git(cwd, ["diff", "--cached", "--name-only"]).trim()) {
    return { gitleaksFlag: "--staged", diffArgs: ["diff", "--cached", "--unified=0"] };
  }
  if (git(cwd, ["diff", "--name-only"]).trim()) {
    return { gitleaksFlag: "--pre-commit", diffArgs: ["diff", "--unified=0"] };
  }
  return null;
}

/**
 * Scan with gitleaks. Returns "clean", "leak" (with a report), or "unavailable"
 * when gitleaks is absent or the CLI shape is unexpected, so the caller can fall
 * back to the built-in patterns.
 *
 * @param {string} cwd
 * @param {string} gitleaksFlag
 * @returns {{status: "clean"}|{status: "leak", report: string}|{status: "unavailable"}}
 */
function runGitleaks(cwd, gitleaksFlag) {
  const result = spawnSync(
    "gitleaks",
    ["git", gitleaksFlag, "--no-banner", "--redact"],
    { cwd, encoding: "utf8" },
  );
  if (result.error) {
    return { status: "unavailable" }; // not on PATH
  }
  if (result.status === 0) {
    return { status: "clean" };
  }
  if (result.status === 1) {
    return { status: "leak", report: (result.stdout || result.stderr || "").trim() };
  }
  return { status: "unavailable" }; // e.g. 126 unknown flag on an older CLI
}

/**
 * The added (`+`) lines of a diff, for the built-in fallback scan.
 *
 * @param {string} diff
 * @returns {string}
 */
function addedLines(diff) {
  return diff
    .split("\n")
    .filter((line) => line.startsWith("+") && !line.startsWith("+++"))
    .map((line) => line.slice(1))
    .join("\n");
}

/**
 * First built-in secret pattern matching real (non-placeholder) content.
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
    const lineStart = content.lastIndexOf("\n", match.index) + 1;
    const lineEndIndex = content.indexOf("\n", match.index);
    const line = content.slice(lineStart, lineEndIndex === -1 ? content.length : lineEndIndex);
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
  const command = payload.tool_input?.command ?? "";
  if (!/git\s+commit/.test(command)) {
    return; // the matcher is broad Bash; only act on commits
  }

  const cwd = payload.cwd ?? process.cwd();
  const region = scanRegion(cwd);
  if (!region) {
    return; // nothing staged or changed — let git handle the empty commit
  }

  const gitleaks = runGitleaks(cwd, region.gitleaksFlag);
  if (gitleaks.status === "clean") {
    return;
  }
  if (gitleaks.status === "leak") {
    block("gitleaks detected a secret in this commit", [
      "Remove it and use an environment variable or secret store instead.",
      `See the file and rule with: gitleaks git ${region.gitleaksFlag} -v`,
    ]);
    return;
  }

  // gitleaks unavailable — fall back to the built-in patterns on the diff.
  const found = firstRealSecretMatch(addedLines(git(cwd, region.diffArgs)));
  if (found) {
    block("Hardcoded secret detected in commit (gitleaks not on PATH — built-in scan)", [
      `Pattern: ${found.name}`,
      "Remove it and use an environment variable instead.",
    ]);
  }
});
