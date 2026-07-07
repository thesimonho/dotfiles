#!/usr/bin/env node
/**
 * Hook: Nudge toward the `rtk` wrapper for token-heavy CLI commands.
 *
 * tools.md's golden rule is "always prefix commands with rtk" so their output
 * gets compressed — but that rule only pays off for the wrapper's curated set
 * of CLIs, and only when it's actually missing from the command. This stays
 * silent for anything outside that set so it doesn't nag on arbitrary Bash
 * calls (curl, mkdir, echo, ...) where rtk has nothing to compress.
 */

const { addContext } = require("../lib/hooks/hook-response");

// The first-token CLIs rtk knows how to compress, per tools.md.
const RTK_COMPRESSIBLE_COMMANDS = new Set([
  "git",
  "ls",
  "cat",
  "grep",
  "rg",
  "find",
  "eza",
  "tree",
  "npm",
  "pnpm",
  "yarn",
  "bun",
  "cargo",
  "go",
  "docker",
  "kubectl",
]);

// Leading `sudo`/env-var assignments (FOO=bar cmd) sit before the real command
// token — strip them so `sudo git push` and `FOO=bar git push` are recognized.
const LEADING_NOISE = /^(sudo\s+|[A-Za-z_][A-Za-z0-9_]*=\S+\s+)+/;

/**
 * The first real command token of a shell command, ignoring `sudo` and
 * leading env-var assignments.
 *
 * @param {string} command
 * @returns {string}
 */
function firstCommandTokenFrom(command) {
  const withoutLeadingNoise = command.trim().replace(LEADING_NOISE, "");
  return withoutLeadingNoise.split(/\s+/)[0] ?? "";
}

/**
 * Whether `rtk` already appears as a command word (not just a substring, so
 * e.g. a file named `artk.txt` doesn't count as already using the wrapper).
 *
 * @param {string} command
 * @returns {boolean}
 */
function alreadyUsesRtk(command) {
  return /(^|[\s;&|])rtk(\s|$)/.test(command);
}

let input = "";
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  const payload = JSON.parse(input);
  const command = payload.tool_input?.command ?? "";
  if (!command || alreadyUsesRtk(command)) {
    return;
  }

  const firstToken = firstCommandTokenFrom(command);
  if (!RTK_COMPRESSIBLE_COMMANDS.has(firstToken)) {
    return;
  }

  addContext(
    "PreToolUse",
    `Prefix with \`rtk\` to save tokens (tools.md), e.g. \`rtk ${firstToken} ...\`.`,
  );
});
