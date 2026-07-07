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
 * Staged file paths, or [] when nothing is staged or cwd is not a repo.
 *
 * @param {string} cwd
 * @returns {string[]}
 */
function stagedFiles(cwd) {
  try {
    const output = execFileSync("git", ["diff", "--cached", "--name-only"], { cwd, encoding: "utf8" });
    return output.split("\n").filter(Boolean);
  } catch {
    return [];
  }
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
  const hasCodeChange = stagedFiles(cwd).some((file) => CODE_FILE.test(file));
  if (!hasCodeChange) {
    return; // docs-only commit — no simplify pass needed
  }

  state.update(sessionId, { simplifyNudged: true });
  addContext(
    "PreToolUse",
    "Committing code changes: if you haven't already run /simplify on this diff, consider it — it reviews recent changes for reuse, quality, and efficiency before they land.",
  );
});
