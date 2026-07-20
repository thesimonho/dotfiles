const path = require("node:path");
const { writeHostResponse } = require("./host-response");
const { normalizePayload } = require("./normalize-payload");

const POLICY_NAME = /^[a-z0-9-]+$/;
const POLICIES_DIRECTORY = path.resolve(__dirname, "../../hooks");

/**
 * Run one shared policy against a native hook payload.
 *
 * @param {"claude" | "codex"} host
 * @param {string} policyName
 */
async function runPolicy(host, policyName) {
  if (!POLICY_NAME.test(policyName)) {
    throw new Error(`Invalid hook policy name: ${policyName}`);
  }

  const nativePayload = await readStandardInput();
  const payload = normalizePayload(host, nativePayload);
  const policyPath = path.join(POLICIES_DIRECTORY, `${policyName}.js`);
  const policy = require(policyPath);
  const result = await policy.evaluate(payload);
  const hookEventName = payload.hook_event_name ?? "PreToolUse";
  writeHostResponse(host, hookEventName, result);
}

/** @returns {Promise<object>} */
function readStandardInput() {
  return new Promise((resolve, reject) => {
    let input = "";
    process.stdin.setEncoding("utf8");
    process.stdin.on("data", (chunk) => (input += chunk));
    process.stdin.on("end", () => {
      try {
        resolve(JSON.parse(input));
      } catch (error) {
        reject(error);
      }
    });
    process.stdin.on("error", reject);
  });
}

module.exports = { runPolicy };
