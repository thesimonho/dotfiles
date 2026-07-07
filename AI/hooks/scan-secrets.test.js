#!/usr/bin/env node
/**
 * Unit test for scan-secrets.js.
 *
 * Runs the hook as a child process against sample tool payloads and asserts the
 * exit code (0 = allow, 2 = block). Run: node AI/hooks/scan-secrets.test.js
 */

const assert = require("node:assert");
const path = require("node:path");
const { execFileSync } = require("node:child_process");

const HOOK = path.join(__dirname, "scan-secrets.js");

/**
 * Run the hook with a payload and return its exit code (0 when it allows).
 *
 * @param {object} payload
 * @returns {number}
 */
function exitCodeFor(payload) {
  try {
    execFileSync("node", [HOOK], {
      input: JSON.stringify(payload),
      stdio: ["pipe", "ignore", "ignore"],
    });
    return 0;
  } catch (error) {
    return error.status;
  }
}

const cases = [
  {
    name: "blocks a hardcoded AWS access key",
    payload: {
      tool_input: {
        file_path: "src/config.js",
        content: 'const key = "AKIAABCDEFGHIJKLMNOP";',
      },
    },
    expect: 2,
  },
  {
    name: "blocks a private key header",
    payload: {
      tool_input: {
        file_path: "id_rsa",
        content: "-----BEGIN RSA PRIVATE KEY-----\nMIIEpAIBAAKCAQEA...",
      },
    },
    expect: 2,
  },
  {
    name: "blocks a GitHub token",
    payload: {
      tool_input: {
        file_path: ".env.local",
        content: "GH_TOKEN=ghp_abcdefghijklmnopqrstuvwxyz012345",
      },
    },
    expect: 2,
  },
  {
    name: "blocks an OpenAI-style key",
    payload: {
      tool_input: { file_path: "app.py", content: 'openai_key = "sk-abcdefghijklmnopqrstuvwx"' },
    },
    expect: 2,
  },
  {
    name: "blocks a Slack token",
    payload: {
      tool_input: { file_path: "app.py", content: 'slack_token = "xoxb-1234567890-abcdef"' },
    },
    expect: 2,
  },
  {
    name: "blocks a generic hardcoded password assignment",
    payload: {
      tool_input: { file_path: "settings.py", content: 'password = "hunter2pass"' },
    },
    expect: 2,
  },
  {
    name: "blocks a hardcoded secret in a Codex apply_patch body",
    payload: {
      tool_input: {
        command: '*** Add File: config.py\n+api_key = "abcdef1234567890"\n*** End Patch',
      },
    },
    expect: 2,
  },
  {
    name: "allows an env-var reference for an api key",
    payload: {
      tool_input: { file_path: "app.js", content: "const apiKey = process.env.KEY;" },
    },
    expect: 0,
  },
  {
    name: "allows an os.environ reference for a token",
    payload: {
      tool_input: { file_path: "app.py", content: 'token = os.environ["TOKEN"]' },
    },
    expect: 0,
  },
  {
    name: "allows an obvious placeholder password",
    payload: {
      tool_input: { file_path: "settings.py", content: 'password = "<your_password>"' },
    },
    expect: 0,
  },
  {
    name: "allows a redacted example secret",
    payload: {
      tool_input: { file_path: "README.md", content: 'api_key = "changeme_placeholder"' },
    },
    expect: 0,
  },
  {
    name: "allows clean content with no secrets",
    payload: {
      tool_input: { file_path: "src/index.js", content: "export const answer = 42;" },
    },
    expect: 0,
  },
];

let failures = 0;
for (const testCase of cases) {
  try {
    assert.strictEqual(exitCodeFor(testCase.payload), testCase.expect);
    console.log(`  ok  ${testCase.name}`);
  } catch {
    failures += 1;
    console.error(`FAIL  ${testCase.name} (expected exit ${testCase.expect})`);
  }
}

if (failures > 0) {
  console.error(`\n${failures} failing`);
  process.exit(1);
}
console.log(`\n${cases.length} passing`);
