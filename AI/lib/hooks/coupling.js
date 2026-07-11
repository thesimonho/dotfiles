/**
 * Discovery for `agent.on-change` doc couplings — used by coupling-surface to
 * find which docs track which paths.
 */

const fs = require("node:fs");
const path = require("node:path");
const { parseAgentFrontmatter } = require("./frontmatter");

const MAX_BYTES = 256 * 1024;
const MAX_SCAN_FILES = 300;

/**
 * Compile a path glob (supporting `**` and `*`) into an anchored RegExp.
 *
 * @param {string} glob
 * @returns {RegExp}
 */
function globToRegExp(glob) {
  const escaped = glob.replace(/[.+^${}()|[\]\\]/g, "\\$&");
  const pattern = escaped.replace(/\*\*/g, " ").replace(/\*/g, "[^/]*").replace(/ /g, ".*");
  return new RegExp(`^${pattern}$`);
}

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
 * Collect markdown paths under a directory tree, bounded by a file budget.
 *
 * @param {string} dir
 * @param {string[]} accumulator absolute paths are pushed here
 */
function collectMarkdown(dir, accumulator) {
  if (accumulator.length >= MAX_SCAN_FILES) {
    return;
  }
  let entries;
  try {
    entries = fs.readdirSync(dir, { withFileTypes: true });
  } catch {
    return;
  }
  for (const entry of entries) {
    if (accumulator.length >= MAX_SCAN_FILES) {
      return;
    }
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      collectMarkdown(full, accumulator);
    } else if (entry.isFile() && entry.name.endsWith(".md")) {
      accumulator.push(full);
    }
  }
}

/**
 * Discover coupling declarations: root-level and docs/ markdown files that carry
 * an agent.on-change list.
 *
 * @param {string} cwd
 * @returns {{file: string, globs: string[], instruction: string}[]}
 */
function discoverCouplings(cwd) {
  const markdownPaths = [];
  collectMarkdown(cwd, markdownPaths); // root-level and any nested (docs/ included)

  const couplings = [];
  for (const absolute of markdownPaths) {
    const content = readSmallFile(absolute);
    if (content === null) {
      continue;
    }
    const { instruction, onChange } = parseAgentFrontmatter(content);
    if (onChange.length > 0) {
      couplings.push({
        file: path.relative(cwd, absolute),
        globs: onChange,
        instruction: instruction ?? "",
      });
    }
  }
  return couplings;
}

/**
 * Whether a cached coupling object still matches the shape this module
 * currently produces. A session's coupling cache is a plain JSON snapshot with
 * no version tag, so if the hook's code changes shape (a field renamed, etc.)
 * mid-session, an older cached snapshot silently no longer matches what the
 * reading code expects. This lets the caller detect that and re-discover
 * instead of crashing on a missing/undefined field.
 *
 * @param {*} coupling
 * @returns {boolean}
 */
function isValidCoupling(coupling) {
  return (
    typeof coupling === "object" &&
    coupling !== null &&
    typeof coupling.file === "string" &&
    Array.isArray(coupling.globs) &&
    coupling.globs.every((glob) => typeof glob === "string") &&
    typeof coupling.instruction === "string"
  );
}

module.exports = { globToRegExp, discoverCouplings, isValidCoupling };
