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
 * Throttling is by elapsed time, never once-per-session. A session is reused
 * across many work cycles, and `/compact` or `/clear` starts a genuinely new one
 * without changing the session id — a once-per-session marker would stay latched
 * and silence the nudge for the rest of the day. An hourly window forgets on
 * roughly the same cadence the context does.
 *
 * Call it at the point the nudge is about to be returned, NOT at the top of the
 * hook: a check that runs before the hook's real conditions burns the window on
 * a command that was never going to nudge anyway.
 *
 *   if (!shouldNudge(payload.session_id, "justfile")) return doNothing();
 *   return addContext("...");
 */

const state = require("./session-state");

/** Long enough that a nudge doesn't repeat within one work cycle, short enough to survive a compaction. */
const DEFAULT_WINDOW_MS = 60 * 60 * 1000;

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
 * @param {{ everyMs?: number }} [options] minimum gap between nudges; defaults to an hour
 * @returns {boolean}
 */
function shouldNudge(sessionId, key, { everyMs = DEFAULT_WINDOW_MS } = {}) {
  if (!sessionId) {
    return true;
  }

  const markers = state.read(sessionId)[MARKER_FIELD] ?? {};
  const lastNudgedAt = markers[key] ?? 0;
  if (Date.now() - lastNudgedAt < everyMs) {
    return false;
  }

  state.update(sessionId, { [MARKER_FIELD]: { ...markers, [key]: Date.now() } });
  return true;
}

module.exports = { shouldNudge };
