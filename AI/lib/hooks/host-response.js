/** Encode a shared policy result for one agent CLI. */

const SUPPORTED_HOSTS = new Set(["claude", "codex"]);

/**
 * @param {string} host
 * @param {string} hookEventName
 * @param {{ effect: string, reason?: string, details?: string[], message?: string }} result
 */
function writeHostResponse(host, hookEventName, result) {
  if (!SUPPORTED_HOSTS.has(host)) {
    throw new Error(`Unsupported hook host: ${host}`);
  }

  if (result.effect === "none") {
    return;
  }

  if (result.effect === "block") {
    writeBlockingResponse(result.reason ?? "Blocked by hook policy", result.details ?? []);
    return;
  }

  if (result.effect === "context") {
    writeAdditionalContext(hookEventName, result.message ?? "");
    return;
  }

  throw new Error(`Unsupported hook policy effect: ${result.effect}`);
}

/**
 * Both hosts use exit 2 plus stderr to block a pending PreToolUse action.
 *
 * @param {string} reason
 * @param {string[]} details
 */
function writeBlockingResponse(reason, details) {
  console.error(`[Hook] BLOCKED: ${reason}`);
  for (const detail of details) {
    console.error(`[Hook] ${detail}`);
  }
  process.exitCode = 2;
}

/**
 * Claude and Codex both accept additionalContext for the events wired here.
 *
 * @param {string} hookEventName
 * @param {string} message
 */
function writeAdditionalContext(hookEventName, message) {
  process.stdout.write(
    JSON.stringify({
      hookSpecificOutput: {
        hookEventName,
        additionalContext: message,
      },
    }),
  );
}

module.exports = { writeHostResponse };
