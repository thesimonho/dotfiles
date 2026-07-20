const assert = require("node:assert/strict");
const path = require("node:path");
const { spawnSync } = require("node:child_process");
const test = require("node:test");

const RUNNERS_DIRECTORY = path.resolve(__dirname, "../lib/hooks/runners");

/**
 * Execute one policy through a native host runner.
 *
 * @param {"claude" | "codex"} host
 * @param {string} policyName
 * @param {object} payload
 */
function runPolicy(host, policyName, payload) {
  return spawnSync(
    process.execPath,
    [path.join(RUNNERS_DIRECTORY, `${host}.js`), policyName],
    { input: JSON.stringify(payload), encoding: "utf8" },
  );
}

for (const host of ["claude", "codex"]) {
  test(`${host} blocks a rejected tool call`, () => {
    const result = runPolicy(host, "block-force-push", {
      hook_event_name: "PreToolUse",
      tool_input: { command: "git push --force origin main" },
    });

    assert.equal(result.status, 2);
    assert.match(result.stderr, /Force push is not allowed/);
    assert.equal(result.stdout, "");
  });

  test(`${host} adds model-visible context without approving`, () => {
    const result = runPolicy(host, "rtk-nudge", {
      hook_event_name: "PreToolUse",
      tool_input: { command: "git status" },
    });

    assert.equal(result.status, 0);
    assert.equal(result.stderr, "");
    assert.deepEqual(JSON.parse(result.stdout), {
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        additionalContext: "Prefix with `rtk` to save tokens, e.g. `rtk git ...`.",
      },
    });
  });

  test(`${host} remains silent when a policy abstains`, () => {
    const result = runPolicy(host, "rtk-nudge", {
      hook_event_name: "PreToolUse",
      tool_input: { command: "rtk git status" },
    });

    assert.equal(result.status, 0);
    assert.equal(result.stderr, "");
    assert.equal(result.stdout, "");
  });
}

test("Codex apply_patch input reaches the shared file policy", () => {
  const result = runPolicy("codex", "block-doc-files", {
    cwd: "/workspace",
    hook_event_name: "PreToolUse",
    tool_name: "apply_patch",
    tool_input: { command: "*** Add File: stray.md\n+content" },
  });

  assert.equal(result.status, 2);
  assert.match(result.stderr, /stray\.md/);
});
