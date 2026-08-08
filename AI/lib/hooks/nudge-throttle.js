/**
 * Rate-limit a nudge so it doesn't repeat within a session.
 *
 * Several nudges are worth saying once but become noise on repeat: the agent
 * has read the reminder and either acted on it or decided not to, so saying it
 * again on the next matching command adds nothing. Each hook that needed this
 * grew its own throttle on top of `session-state` (a Set of surfaced keys, a
 * timestamp debounce, a boolean flag), so this collects the timestamp shape —
 * the one two hooks share — into one place.
 *
 * Call it at the point the nudge is about to be returned, NOT at the top of the
 * hook: a check that runs before the hook's real conditions burns the session's
 * one allowance on a command that was never going to nudge anyway.
 *
 *   if (!shouldNudge(payload.session_id, "justfile")) return doNothing();
 *   return addContext("...");
 */

const state = require("./session-state");

/** Marker keys are namespaced under this, so they can't collide with other session state. */
const MARKER_FIELD = "nudgedAt";

/**
 * Whether a nudge is due, recording it as fired when it is.
 *
 * Without a session id there is nothing to key state on — fire every time
 * rather than sharing one bucket across unrelated sessions, which would
 * silence the nudge permanently after its first use.
 *
 * @param {string} sessionId
 * @param {string} key namespaced marker, one per nudge (e.g. "justfile")
 * @param {{ everyMs?: number }} [options] minimum gap between nudges; omit for once per session
 * @returns {boolean}
 */
function shouldNudge(sessionId, key, { everyMs = Infinity } = {}) {
  if (!sessionId) {
    return true;
  }

  const markers = state.read(sessionId)[MARKER_FIELD] ?? {};
  const lastNudgedAt = markers[key];
  // The `lastNudgedAt` guard is what makes `everyMs: Infinity` mean "once per
  // session" rather than "never" — without it the first call is also inside the
  // window, because every elapsed time is less than Infinity.
  if (lastNudgedAt && Date.now() - lastNudgedAt < everyMs) {
    return false;
  }

  state.update(sessionId, { [MARKER_FIELD]: { ...markers, [key]: Date.now() } });
  return true;
}

module.exports = { shouldNudge };
