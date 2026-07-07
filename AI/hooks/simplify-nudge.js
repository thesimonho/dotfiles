#!/usr/bin/env node
/**
 * Hook: Remind to run /simplify before committing code changes.
 *
 * /simplify reviews recently changed code for reuse, quality, and efficiency; a
 * commit is the natural checkpoint. This nudges once per session when the staged
 * diff includes code files — not for docs-only commits — to run /simplify if it
 * hasn't been already. A hook can't invoke a skill, so it reminds the agent to.
 * Wire under PreToolUse for Bash (self-filters to git commit).
 */

const { execFileSync } = require("node:child_process");
const { addContext } = require("../lib/hooks/hook-response");
const state = require("../lib/hooks/session-state");

const CODE_FILE =
  /\.(js|jsx|ts|tsx|mjs|cjs|py|go|rs|dart|java|kt|rb|c|cc|cpp|h|hpp|nix|sh|lua|vue|svelte)$/i;

/**
 * Run a git command and return its output lines ([] on failure).
 *
 * @param {string} cwd
 * @param {string[]} args
 * @returns {string[]}
 */
function gitLines(cwd, args) {
  try {
    return execFileSync("git", args, { cwd, encoding: "utf8" }).split("\n").filter(Boolean);
  } catch {
    return [];
  }
}

/**
 * The files this commit will include. Prefers the staged set; when nothing is
 * staged yet — the `git add … && git commit` one-liner, where this hook runs
 * before the add — it falls back to all uncommitted tracked changes vs HEAD.
 *
 * @param {string} cwd
 * @returns {string[]}
 */
function committedFiles(cwd) {
  const staged = gitLines(cwd, ["diff", "--cached", "--name-only"]);
  return staged.length > 0 ? staged : gitLines(cwd, ["diff", "HEAD", "--name-only"]);
}

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

  const cwd = payload.cwd ?? process.cwd();
  const hasCodeChange = committedFiles(cwd).some((file) => CODE_FILE.test(file));
  if (!hasCodeChange) {
    return; // docs-only commit — no simplify pass needed
  }

  state.update(sessionId, { simplifyNudged: true });
  addContext(
    "PreToolUse",
    "Committing code changes: if you haven't already run /simplify on this diff, consider it — it reviews recent changes for reuse, quality, and efficiency before they land.",
  );
});
