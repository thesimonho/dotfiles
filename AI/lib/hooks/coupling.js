/**
 * Discovery for `agent.on-change` doc couplings — used by coupling-surface to
 * find which docs track which paths.
 */

const fs = require("node:fs");
const path = require("node:path");
const { parseAgentFrontmatter } = require("./frontmatter");

const MAX_BYTES = 256 * 1024;
const MAX_SCAN_FILES = 300;

// Vendored and generated trees hold thousands of markdown files — mostly
// READMEs — that can never declare a coupling. Skipping them at the directory
// level is what makes this cheap: a filename filter alone would still have to
// walk them. On this repository that is 489 candidates down to 231, and 114ms
// down to 15ms, on a hook that runs after every read and edit.
const SKIPPED_DIRECTORIES = new Set([
  ".git",
  "node_modules",
  ".venv",
  "venv",
  "site-packages",
  "dist",
  "build",
  "target",
  ".next",
  ".cache",
]);

// Filenames that can declare a coupling anywhere in the tree. Everything else
// must live under docs/ or at the repository root. Without this the scan is
// bounded only by MAX_SCAN_FILES, and a repository large enough to exceed it
// loses couplings silently, picked off by directory walk order.
const INDEX_FILENAMES = new Set(["README.md", "INDEX.md", "AGENTS.md", "SKILL.md"]);

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
 * Whether a markdown file is somewhere a coupling may be declared: under a
 * `docs/` directory at any depth, directly at the repository root, or under one
 * of the index filenames that can appear anywhere.
 *
 * @param {string} relativePath repository-relative, POSIX separators
 * @returns {boolean}
 */
function isCouplingCandidate(relativePath) {
  const segments = relativePath.split(path.sep);
  const isRepositoryRoot = segments.length === 1;
  const isUnderDocs = segments.slice(0, -1).includes("docs");
  return isRepositoryRoot || isUnderDocs || INDEX_FILENAMES.has(segments[segments.length - 1]);
}

/**
 * Collect the markdown paths that may declare a coupling, bounded by a file
 * budget. The budget is now a backstop rather than the primary limit — the
 * directory skip and candidate filter are what keep the set small.
 *
 * @param {string} root the repository root, for relative-path decisions
 * @param {string} dir directory currently being walked
 * @param {string[]} accumulator absolute paths are pushed here
 */
function collectMarkdown(root, dir, accumulator) {
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
      if (!SKIPPED_DIRECTORIES.has(entry.name)) {
        collectMarkdown(root, full, accumulator);
      }
    } else if (entry.isFile() && entry.name.endsWith(".md")) {
      if (isCouplingCandidate(path.relative(root, full))) {
        accumulator.push(full);
      }
    }
  }
}

/**
 * Discover coupling declarations: markdown carrying an `agent.on-change` list,
 * among the files where one may be declared — anything under a `docs/`
 * directory, anything directly at the repository root, and any README.md,
 * INDEX.md, AGENTS.md, or SKILL.md anywhere.
 *
 * @param {string} cwd
 * @returns {{file: string, globs: string[], instruction: string}[]}
 */
function discoverCouplings(cwd) {
  const markdownPaths = [];
  collectMarkdown(cwd, cwd, markdownPaths);

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
