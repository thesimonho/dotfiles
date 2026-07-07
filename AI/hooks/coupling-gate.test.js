#!/usr/bin/env node
/**
 * Unit test for coupling-gate.js. verify-track.js records the session's edits;
 * the gate blocks the stop when a declared when-changed coupling is violated.
 * Run: node AI/hooks/coupling-gate.test.js
 */

const assert = require("node:assert");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { execFileSync } = require("node:child_process");

const TRACK = path.join(__dirname, "verify-track.js");
const GATE = path.join(__dirname, "coupling-gate.js");
const SESSION = "sess-coupling";

/** @returns {string} a fresh isolated state dir */
function freshStateDir() {
  return fs.mkdtempSync(path.join(os.tmpdir(), "coupling-state-"));
}

/**
 * A temp project dir seeded with the given {relPath: content} files.
 * @param {Record<string,string>} files
 * @returns {string}
 */
function project(files) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "coupling-proj-"));
  for (const [rel, content] of Object.entries(files)) {
    const abs = path.join(root, rel);
    fs.mkdirSync(path.dirname(abs), { recursive: true });
    fs.writeFileSync(abs, content);
  }
  return root;
}

/**
 * Run a hook and return its exit code (0 = allow, 2 = block).
 * @param {string} hook @param {object} payload @param {string} stateDir @returns {number}
 */
function runExit(hook, payload, stateDir) {
  try {
    execFileSync("node", [hook], {
      input: JSON.stringify(payload),
      env: { ...process.env, AGENT_HOOK_STATE_DIR: stateDir },
      stdio: ["pipe", "ignore", "ignore"],
    });
    return 0;
  } catch (error) {
    return error.status;
  }
}

/** Record an edit of relPath in the session via verify-track. */
function trackEdit(relPath, cwd, stateDir) {
  runExit(
    TRACK,
    { session_id: SESSION, tool_name: "Edit", cwd, tool_input: { file_path: relPath } },
    stateDir,
  );
}

const ROADMAP_COUPLED =
  '# Roadmap\n<INSTRUCTION when-changed="src/**">Clear completed items.</INSTRUCTION>\n';
const ROADMAP_PLAIN = "# Roadmap\n<INSTRUCTION>Keep this tidy.</INSTRUCTION>\n";

let failures = 0;
/** @param {string} name @param {() => void} fn */
function test(name, fn) {
  try {
    fn();
    console.log(`  ok  ${name}`);
  } catch (error) {
    failures += 1;
    console.error(`FAIL  ${name}: ${error.message}`);
  }
}

test("blocks when a when-changed glob matched but the declaring file was not touched", () => {
  const state = freshStateDir();
  const cwd = project({ "docs/roadmap.md": ROADMAP_COUPLED });
  trackEdit("src/app.ts", cwd, state);
  assert.strictEqual(runExit(GATE, { session_id: SESSION, cwd }, state), 2);
});

test("allows when the declaring file was also updated", () => {
  const state = freshStateDir();
  const cwd = project({ "docs/roadmap.md": ROADMAP_COUPLED });
  trackEdit("src/app.ts", cwd, state);
  trackEdit("docs/roadmap.md", cwd, state);
  assert.strictEqual(runExit(GATE, { session_id: SESSION, cwd }, state), 0);
});

test("allows when the edit does not match the glob", () => {
  const state = freshStateDir();
  const cwd = project({ "docs/roadmap.md": ROADMAP_COUPLED });
  trackEdit("lib/other.ts", cwd, state);
  assert.strictEqual(runExit(GATE, { session_id: SESSION, cwd }, state), 0);
});

test("dormant when no coupling is declared", () => {
  const state = freshStateDir();
  const cwd = project({ "docs/roadmap.md": ROADMAP_PLAIN });
  trackEdit("src/app.ts", cwd, state);
  assert.strictEqual(runExit(GATE, { session_id: SESSION, cwd }, state), 0);
});

test("loop guard: stop_hook_active never blocks", () => {
  const state = freshStateDir();
  const cwd = project({ "docs/roadmap.md": ROADMAP_COUPLED });
  trackEdit("src/app.ts", cwd, state);
  assert.strictEqual(runExit(GATE, { session_id: SESSION, cwd, stop_hook_active: true }, state), 0);
});

if (failures > 0) {
  console.error(`\n${failures} failing`);
  process.exit(1);
}
console.log("\n5 passing");
