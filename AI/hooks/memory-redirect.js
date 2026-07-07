#!/usr/bin/env node
/**
 * Hook: Nudge toward hooks/rules over memory files for enforceable rules.
 *
 * Memory files are read by the model and decay in salience as context grows
 * (see reference_claude_vs_codex_instruction_adherence.md), so a rule that
 * must always hold is safer encoded as a deterministic hook or instruction
 * fragment than recalled from memory. This fires whenever a write targets a
 * `/memory/` path so that choice gets made deliberately, not by default. A
 * memory write is also the natural moment to prune: it reminds the agent to
 * audit the neighbouring memories for stale or superseded entries.
 */

const { addContext } = require("../lib/hooks/hook-response");

/**
 * Whether the file path is a Markdown file under a `/memory/` directory.
 *
 * @param {string} filePath
 * @returns {boolean}
 */
function isMemoryMarkdownFile(filePath) {
  return filePath.includes("/memory/") && filePath.endsWith(".md");
}

let input = "";
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  const payload = JSON.parse(input);
  const filePath = payload.tool_input?.file_path ?? "";
  if (!isMemoryMarkdownFile(filePath)) {
    return;
  }

  addContext(
    "PreToolUse",
    "Writing a memory: (1) if this is an ENFORCEABLE working rule (not just a fact to recall), prefer a deterministic hook/rule under AI/hooks or AI/instructions — hooks don't decay across context. (2) While here, audit the neighbouring memories in this directory and prune any that are now stale, superseded, or wrong.",
  );
});
