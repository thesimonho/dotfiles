#!/usr/bin/env node
/**
 * Hook: Block writes to build/output directories at the project root.
 *
 * Applies to Write, Edit, and MultiEdit. Checks the file path relative to
 * cwd so that nested dirs with the same name (e.g. src/components/build/)
 * are not blocked — only top-level matches.
 */

const path = require('path');

const BLOCKED_DIRS = ['dist', 'build', '.next', 'node_modules', '.git'];

let input = '';
process.stdin.on('data', chunk => (input += chunk));
process.stdin.on('end', () => {
  const payload = JSON.parse(input);
  const filePath = payload.tool_input?.file_path ?? '';
  const cwd = payload.cwd ?? process.cwd();

  const abs = path.resolve(cwd, filePath);
  const rel = path.relative(cwd, abs);
  const topLevelDir = rel.split(path.sep)[0];

  if (BLOCKED_DIRS.includes(topLevelDir)) {
    console.error(`[Hook] BLOCKED: Write to ${topLevelDir}/ is not allowed`);
    console.error(`[Hook] File: ${filePath}`);
    console.error('[Hook] Build and dependency directories must not be manually modified');
    process.exit(1);
  }

  console.log(input);
});
