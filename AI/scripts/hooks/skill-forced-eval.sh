#!/bin/bash
# UserPromptSubmit hook that forces explicit skill evaluation

cat <<'EOF'
INSTRUCTION: MANDATORY AGENT AND SKILL ACTIVATION SEQUENCE

Step 1 - EVALUATE (do this in your response):
For each skill in <available_skills> and agent in <available_agents>, state: [skill/agent-name] - YES/NO - [reason]

Step 2 - DECIDE (do this immediately after Step 1):
If any agents are YES then JUMP to Step 3.
If all agents are NO then JUMP to Step 4.

Step 3 - ACTIVATE AGENTS:
Determine the correct sequence of agents to activate and which <YES_skills> each agent needs.
Use Task(agent-name) to call EACH relevant agent. Give them the task and this instruction "Use <chosen_skills> to complete <task>" NOW.
Then SKIP Step 4 and 5. Jump straight to Step 6 NOW. do NOT activate skills or implement yourself - delegate to the agents.

Step 4 - ACTIVATE SKILLS:
IF any skills are YES → Use Skill(skill-name) tool for EACH relevant skill NOW
CRITICAL: You MUST call Skill() tool in Step 4. Do NOT skip to implementation.
The evaluation (Step 1) is WORTHLESS unless you ACTIVATE (Step 4) the skills.

Example of correct sequence:
- research: NO - not a research task
- svelte5-runes: YES - need reactive state
- sveltekit-structure: YES - creating routes

[Then IMMEDIATELY use Skill() tool:]
> Skill(svelte5-runes)
> Skill(sveltekit-structure)

Step 5 - IMPLEMENT:
ONLY after Step 4 is complete, proceed with implementation.

Step 6 - CONSOLIDATE:
Process the agent results OR implementation results, decide on the best course of action.
EOF
