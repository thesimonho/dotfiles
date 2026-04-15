#!/usr/bin/env node
/**
 * Hook: Block unnecessary documentation file creation.
 *
 * Allowed .md files:
 *   - README.md, CLAUDE.md, AGENTS.md (anywhere in the tree)
 *   - Any .md file under ./docs/
 *
 * .txt files are always blocked.
 */

const ALWAYS_ALLOWED_MD = /\/(README|CLAUDE|AGENTS)\.md$/;
const DOCS_DIR_MD = /^docs\//;

let input = "";
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  const payload = JSON.parse(input);
  const path = payload.tool_input?.file_path ?? "";

  const isTxt = /\.txt$/.test(path);
  const isMd = /\.md$/.test(path);

  const isAllowed =
    isMd && (ALWAYS_ALLOWED_MD.test(path) || DOCS_DIR_MD.test(path));

  if (isTxt || (isMd && !isAllowed)) {
    console.error(`[Hook] BLOCKED: ${path}`);
    console.error(
      "[Hook] Allowed: README.md, CLAUDE.md, AGENTS.md, or docs/*.md",
    );
    process.exit(1);
  }
});
