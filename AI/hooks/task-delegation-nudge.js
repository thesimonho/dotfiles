#!/usr/bin/env node
/**
 * Hook: Nudge explicit agent/model selection at planning time.
 *
 * With sonnet as the standing model and no cheap mid-session model change (a
 * `/model` switch re-caches the whole conversation), the place to choose a
 * stronger model is a subagent spawn. When the agent starts planning (creates a
 * task), this reminds it to decide which tasks warrant a dedicated subagent/tier
 * and to record that on the task, rather than running everything inline on the
 * default model. It debounces on a time window rather than firing once per
 * session: a burst of TaskCreates in one planning phase collapses to a single
 * nudge, but a later planning phase in the same (reused, compacted) session fires
 * again. Wire under PostToolUse for the TaskCreate tool.
 */

const { addContext } = require("../lib/hooks/hook-response");
const state = require("../lib/hooks/session-state");

/** Re-nudge at most once per this window, to survive burst and session reuse. */
const DEBOUNCE_MS = 15 * 60 * 1000;

let input = "";
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  const payload = JSON.parse(input);
  const sessionId = payload.session_id;

  const lastNudgedAt = state.read(sessionId).taskDelegationNudgedAt ?? 0;
  if (Date.now() - lastNudgedAt < DEBOUNCE_MS) {
    return; // still inside the debounce window (same planning burst)
  }
  state.update(sessionId, { taskDelegationNudgedAt: Date.now() });

  addContext(
    "PostToolUse",
    "Planning: the model can't change cheaply mid-session, so pick it at spawn time. " +
      "With sonnet as the default, delegate heavy reasoning to an opus subagent (e.g. frank " +
      "for planning). If a task needs a specific agent or tier, note it on the task so it is " +
      "spawned deliberately rather than run inline.",
  );
});
