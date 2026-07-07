#!/usr/bin/env node
/**
 * Hook: Surface the nearest README when a docs file is touched.
 *
 * documentation.md says to check a directory's README before working in it, but
 * an agent reading one file rarely reads its neighbours. A hook can't force a
 * second Read — so instead it injects the nearest README's content directly,
 * which is stronger than forcing a read (the context is simply there).
 *
 * Scoped to files under a `docs/` directory to stay high-signal: it walks up
 * from the touched file to the nearest README.md within the docs subtree and
 * surfaces it once per README per session (deduped in session state), so
 * re-reading files in the same tree doesn't re-inject. Wire under PostToolUse
 * for Read|Edit.
 */

const fs = require("node:fs");
const path = require("node:path");
const { addContext } = require("../lib/hooks/hook-response");
const state = require("../lib/hooks/session-state");

const MAX_BYTES = 256 * 1024;
const MAX_SURFACED_CHARS = 1500;
const DOCS_SEGMENT = /(^|\/)docs(\/|$)/;

/**
 * Read a small text file, or null when missing/too large/unreadable.
 *
 * @param {string} absolutePath
 * @returns {string|null}
 */
function readSmallFile(absolutePath) {
  try {
    const stat = fs.statSync(absolutePath);
    if (!stat.isFile() || stat.size > MAX_BYTES) {
      return null;
    }
    return fs.readFileSync(absolutePath, "utf8");
  } catch {
    return null;
  }
}

/**
 * Walk up from a file's directory to the nearest README.md, staying within the
 * docs subtree and not returning the touched file itself.
 *
 * @param {string} absoluteFile
 * @returns {string|null} absolute README path, or null
 */
function nearestReadme(absoluteFile) {
  let dir = path.dirname(absoluteFile);
  for (let depth = 0; depth < 8; depth++) {
    if (!DOCS_SEGMENT.test(dir)) {
      return null; // left the docs subtree
    }
    const candidate = path.join(dir, "README.md");
    if (candidate !== absoluteFile && fs.existsSync(candidate)) {
      return candidate;
    }
    const parent = path.dirname(dir);
    if (parent === dir) {
      return null;
    }
    dir = parent;
  }
  return null;
}

let input = "";
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  const payload = JSON.parse(input);
  const target = payload.tool_input?.file_path ?? payload.tool_input?.path ?? "";
  if (!target || !DOCS_SEGMENT.test(target)) {
    return;
  }

  const cwd = payload.cwd ?? process.cwd();
  const absoluteFile = path.resolve(cwd, target);
  const readme = nearestReadme(absoluteFile);
  if (!readme) {
    return;
  }

  const sessionId = payload.session_id;
  const relative = path.relative(cwd, readme) || readme;
  const alreadySurfaced = state.read(sessionId).readmesSurfaced ?? [];
  if (alreadySurfaced.includes(relative)) {
    return; // one surface per README per session
  }
  state.update(sessionId, { readmesSurfaced: [...alreadySurfaced, relative] });

  const content = readSmallFile(readme);
  if (content === null) {
    return;
  }
  const body =
    content.length > MAX_SURFACED_CHARS ? `${content.slice(0, MAX_SURFACED_CHARS)}…` : content;

  addContext(
    "PostToolUse",
    `This docs tree has a README (${relative}) — read it for context before working here:\n${body}`,
  );
});
