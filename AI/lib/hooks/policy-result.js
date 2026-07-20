/** Results returned by agent-neutral hook policies. */

/** @returns {{ effect: "none" }} */
function doNothing() {
  return { effect: "none" };
}

/**
 * @param {string} reason
 * @param {string[]} [details]
 * @returns {{ effect: "block", reason: string, details: string[] }}
 */
function block(reason, details = []) {
  return { effect: "block", reason, details };
}

/**
 * @param {string} message
 * @returns {{ effect: "context", message: string }}
 */
function addContext(message) {
  return { effect: "context", message };
}

module.exports = { addContext, block, doNothing };
