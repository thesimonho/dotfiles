#!/usr/bin/env node
/**
 * Hook: Nudge explicit agent/model selection at planning time.
 *
 * With sonnet as the standing model and no cheap mid-session model change (a
 * `/model` switch re-caches the whole conversation), the place to choose a
 * stronger model is a subagent spawn. When the agent starts planning (creates a
 * task), this reminds it once per session to decide which tasks warrant a
 * dedicated subagent/tier and to record that on the task, rather than running
 * everything inline on the default model. Fires once per session to stay quiet
 * during a planning burst. Wire under PostToolUse for the TaskCreate tool.
 */

const { addContext } = require("../lib/hooks/hook-response");
const state = require("../lib/hooks/session-state");

let input = "";
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  const payload = JSON.parse(input);
  const sessionId = payload.session_id;

  if (state.read(sessionId).taskDelegationNudged) {
    return; // already reminded this session
  }
  state.update(sessionId, { taskDelegationNudged: true });

  addContext(
    "PostToolUse",
    "Planning: the model can't change cheaply mid-session, so pick it at spawn time. " +
      "With sonnet as the default, delegate heavy reasoning to an opus subagent (e.g. frank " +
      "for planning). If a task needs a specific agent or tier, note it on the task so it is " +
      "spawned deliberately rather than run inline.",
  );
});
