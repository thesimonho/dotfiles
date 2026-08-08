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
 * Markers live in their own state namespace. Hooks bound to one event run as
 * concurrent processes against the same session file, and `session-state.update`
 * is a read-modify-write, so two of them can lose each other's changes. Losing a
 * nudge marker costs one extra nudge; losing the verify gate's `dirty` flag
 * costs a silently skipped verify reminder. Keeping them in separate files means
 * a nudge can never be the writer that drops it.
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

/** Separate state file, so nudge markers and verification state can't clobber each other. */
const MARKER_NAMESPACE = "nudges";

/** Marker keys live under this field, so they can't collide with anything else in the namespace. */
const MARKER_FIELD = "nudgedAt";

/**
 * Which of several nudges are due, recording them all as fired in one write.
 *
 * Batching matters because the caller may be checking many keys per tool call:
 * a per-key round trip would read and rewrite the state file once for each,
 * on a hook that already runs after every read and edit.
 *
 * Without a session id there is nothing to key state on — fire every time
 * rather than sharing one bucket across unrelated sessions, which would
 * silence the nudge permanently after its first use.
 *
 * @param {string} sessionId
 * @param {string[]} keys one marker per nudge (e.g. "justfile")
 * @param {{ everyMs?: number }} [options] minimum gap between nudges; defaults to an hour
 * @returns {string[]} the subset of keys that are due
 */
function dueNudges(sessionId, keys, { everyMs = DEFAULT_WINDOW_MS } = {}) {
  if (!sessionId) {
    return [...keys];
  }

  const markers = state.read(sessionId, MARKER_NAMESPACE)[MARKER_FIELD] ?? {};
  const now = Date.now();
  const due = keys.filter((key) => now - (markers[key] ?? 0) >= everyMs);
  if (due.length === 0) {
    return due;
  }

  const stamped = { ...markers };
  for (const key of due) {
    stamped[key] = now;
  }
  state.update(sessionId, { [MARKER_FIELD]: stamped }, MARKER_NAMESPACE);
  return due;
}

/**
 * Whether a single nudge is due, recording it as fired when it is.
 *
 * @param {string} sessionId
 * @param {string} key marker for this nudge (e.g. "justfile")
 * @param {{ everyMs?: number }} [options] minimum gap between nudges; defaults to an hour
 * @returns {boolean}
 */
function shouldNudge(sessionId, key, options) {
  return dueNudges(sessionId, [key], options).length > 0;
}

module.exports = { shouldNudge, dueNudges };
