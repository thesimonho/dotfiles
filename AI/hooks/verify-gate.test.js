#!/usr/bin/env node
/**
 * Unit test for the verify flow: verify-track.js (mark dirty/clean) feeding
 * verify-gate.js (observe-only Stop). Run: node AI/hooks/verify-gate.test.js
 */

const assert = require("node:assert");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { execFileSync } = require("node:child_process");

const TRACK = path.join(__dirname, "verify-track.js");
const GATE = path.join(__dirname, "verify-gate.js");
const SESSION = "sess-1";

/**
 * Fresh isolated state dir + observe-log path for one scenario.
 * @returns {{stateDir: string, observeLog: string}}
 */
function freshEnv() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "verify-hook-"));
  return {
    stateDir: path.join(root, "sessions"),
    observeLog: path.join(root, "verify-observe.log"),
  };
}

/**
 * @param {string} hook
 * @param {object} payload
 * @param {string} stateDir
 */
function run(hook, payload, stateDir) {
  execFileSync("node", [hook], {
    input: JSON.stringify(payload),
    env: { ...process.env, AGENT_HOOK_STATE_DIR: stateDir },
    stdio: ["pipe", "ignore", "ignore"],
  });
}

/** @param {string} log @returns {number} */
function lineCount(log) {
  return fs.existsSync(log)
    ? fs.readFileSync(log, "utf8").trim().split("\n").filter(Boolean).length
    : 0;
}

const edit = { session_id: SESSION, tool_name: "Edit", tool_input: { file_path: "src/app.ts" } };
const runVerify = {
  session_id: SESSION,
  tool_name: "Bash",
  tool_input: { command: "just verify" },
};

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

// cwd with tooling vs without
const withTooling = fs.mkdtempSync(path.join(os.tmpdir(), "proj-"));
fs.writeFileSync(path.join(withTooling, "justfile"), "verify:\n\techo ok\n");
const noTooling = fs.mkdtempSync(path.join(os.tmpdir(), "bare-"));

test("code edit then stop → records a would-block (tooling present)", () => {
  const env = freshEnv();
  run(TRACK, edit, env.stateDir);
  run(GATE, { session_id: SESSION, cwd: withTooling }, env.stateDir);
  assert.strictEqual(lineCount(env.observeLog), 1);
});

test("verify after edit clears dirty → no would-block", () => {
  const env = freshEnv();
  run(TRACK, edit, env.stateDir);
  run(TRACK, runVerify, env.stateDir);
  run(GATE, { session_id: SESSION, cwd: withTooling }, env.stateDir);
  assert.strictEqual(lineCount(env.observeLog), 0);
});

test("no tooling → no would-block even when dirty", () => {
  const env = freshEnv();
  run(TRACK, edit, env.stateDir);
  run(GATE, { session_id: SESSION, cwd: noTooling }, env.stateDir);
  assert.strictEqual(lineCount(env.observeLog), 0);
});

test("stop_hook_active loop guard → no would-block", () => {
  const env = freshEnv();
  run(TRACK, edit, env.stateDir);
  run(GATE, { session_id: SESSION, cwd: withTooling, stop_hook_active: true }, env.stateDir);
  assert.strictEqual(lineCount(env.observeLog), 0);
});

test("doc-only edit does not mark dirty", () => {
  const env = freshEnv();
  run(
    TRACK,
    { session_id: SESSION, tool_name: "Edit", tool_input: { file_path: "README.md" } },
    env.stateDir,
  );
  run(GATE, { session_id: SESSION, cwd: withTooling }, env.stateDir);
  assert.strictEqual(lineCount(env.observeLog), 0);
});

fs.rmSync(withTooling, { recursive: true, force: true });
fs.rmSync(noTooling, { recursive: true, force: true });

if (failures > 0) {
  console.error(`\n${failures} failing`);
  process.exit(1);
}
console.log("\n5 passing");
