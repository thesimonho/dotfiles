#!/usr/bin/env node
/**
 * Unit test for lint-config-files.js.
 *
 * Runs the hook against sample Edit/Write/MultiEdit and Codex apply_patch
 * payloads and asserts the surfaced additionalContext ("" when the hook stays
 * silent). Run: node AI/hooks/lint-config-files.test.js
 */

const assert = require("node:assert");
const path = require("node:path");
const { execFileSync } = require("node:child_process");

const HOOK = path.join(__dirname, "lint-config-files.js");

/**
 * Run the hook for a given tool_input and return the surfaced
 * additionalContext ("" when the hook stays silent).
 *
 * @param {object} toolInput
 * @returns {string}
 */
function surfacedFor(toolInput) {
  const stdout = execFileSync("node", [HOOK], {
    input: JSON.stringify({ tool_input: toolInput }),
    encoding: "utf8",
  });
  if (!stdout.trim()) {
    return "";
  }
  return JSON.parse(stdout).hookSpecificOutput.additionalContext;
}

let failures = 0;

/**
 * @param {string} name
 * @param {() => void} fn
 */
function test(name, fn) {
  try {
    fn();
    console.log(`  ok  ${name}`);
  } catch (error) {
    failures += 1;
    console.error(`FAIL  ${name}: ${error.message}`);
  }
}

test("fires for a GitHub workflow yml", () => {
  const surfaced = surfacedFor({ file_path: ".github/workflows/ci.yml" });
  assert.match(surfaced, /actionlint/);
});

test("fires for a GitHub workflow yaml", () => {
  const surfaced = surfacedFor({ file_path: ".github/workflows/deploy.yaml" });
  assert.match(surfaced, /actionlint/);
});

test("fires for a Dockerfile by basename", () => {
  const surfaced = surfacedFor({ file_path: "docker/Dockerfile" });
  assert.match(surfaced, /hadolint/);
});

test("fires for a *.dockerfile file", () => {
  const surfaced = surfacedFor({ file_path: "docker/worker.dockerfile" });
  assert.match(surfaced, /hadolint/);
});

test("fires for a shell script", () => {
  const surfaced = surfacedFor({ file_path: "scripts/deploy.sh" });
  assert.match(surfaced, /shellcheck/);
});

test("fires for a bash script", () => {
  const surfaced = surfacedFor({ file_path: "scripts/setup.bash" });
  assert.match(surfaced, /shellcheck/);
});

test("fires for a Terraform file", () => {
  const surfaced = surfacedFor({ file_path: "infra/main.tf" });
  assert.match(surfaced, /tflint/);
});

test("fires for a Codex apply_patch adding a workflow file", () => {
  const surfaced = surfacedFor({
    command: "*** Add File: .github/workflows/release.yml\n+name: release\n",
  });
  assert.match(surfaced, /actionlint/);
});

test("stays silent for an unrelated file", () => {
  assert.strictEqual(surfacedFor({ file_path: "src/index.ts" }), "");
});

test("stays silent when no path is present", () => {
  assert.strictEqual(surfacedFor({}), "");
});

if (failures > 0) {
  console.error(`\n${failures} failing`);
  process.exit(1);
}
console.log("\n9 passing");
