#!/usr/bin/env node
/**
 * Hook: Nudge toward the `rtk` wrapper for token-heavy CLI commands.
 *
 * tools.md's golden rule is "always prefix commands with rtk" so their output
 * gets compressed. The rule is unconditional and the wrapper falls back safely,
 * so the agent should prefix everything; this hook only decides where a missing
 * prefix is worth interrupting for. It fires on the commands rtk actually
 * compresses and stays silent on the rest (mkdir, echo, sleep, ...), where a
 * missing prefix costs nothing and a nudge would just be noise.
 */

const { addContext, doNothing } = require("../lib/hooks/policy-result");
const { shouldNudge } = require("../lib/hooks/nudge-throttle");

// The first-token CLIs rtk knows how to compress, drawn from its published
// coverage list. This is the nudge's trigger set, not a claim about the
// wrapper's full surface: rtk covers more, and prefixing anything outside this
// set is still correct per tools.md. Test runners come first because they are
// where the wrapper pays most, reducing output by 94-99%.
// https://www.rtk-ai.app/docs/resources/what-rtk-covers/
const RTK_COMPRESSIBLE_COMMANDS = new Set([
  // Tests and type/lint checks — the largest reductions.
  "pytest",
  "jest",
  "vitest",
  "playwright",
  "tsc",
  "eslint",
  "mypy",
  "ruff",
  // Files and search.
  "ls",
  "cat",
  "head",
  "tail",
  "grep",
  "rg",
  "find",
  "diff",
  "wc",
  "eza",
  "tree",
  // Version control and forges.
  "git",
  "gh",
  // Package managers and language toolchains.
  "npm",
  "pnpm",
  "yarn",
  "bun",
  "npx",
  "pip",
  "cargo",
  "go",
  // Containers and clusters.
  "docker",
  "kubectl",
  // Network and data.
  "curl",
  "psql",
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

/**
 * @param {object} payload
 * @returns {{ effect: string, message?: string }}
 */
function evaluate(payload) {
  const command = payload.tool_input?.command ?? "";
  if (!command || alreadyUsesRtk(command)) {
    return doNothing();
  }

  const firstToken = firstCommandTokenFrom(command);
  if (!RTK_COMPRESSIBLE_COMMANDS.has(firstToken)) {
    return doNothing();
  }

  if (!shouldNudge(payload.session_id, "rtk")) {
    return doNothing();
  }

  return addContext(`Prefix with \`rtk\` to save tokens, e.g. \`rtk ${firstToken} ...\`.`);
}

module.exports = { evaluate };
