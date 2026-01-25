#!/bin/bash
# UserPromptSubmit hook that forces explicit skill evaluation

cat <<'EOF'
INSTRUCTION: MANDATORY SKILL ACTIVATION SEQUENCE

Step 1 - EVALUATE (do this in your response):
For each skill in <available_skills> and agent in <available_agents>, state: [skill/agent-name] - YES/NO - [reason]

Step 2 - ACTIVATE (do this immediately after Step 1):
IF any agents are YES → Use Task(agent-name) and pass this task to EACH relevant agent NOW. Once all agents have been called and given their task, you can skip to End.
IF no agents are YES → State "No agents needed" and proceed

Next, for skills:
IF any skills are YES → Use Skill(skill-name) tool for EACH relevant skill NOW
IF no skills are YES → State "No skills needed" and proceed

Step 3 - IMPLEMENT:
Only after Step 2 is complete, proceed with implementation.

CRITICAL: You MUST call Task()/Skill() tool in Step 2. Do NOT skip to implementation.
The evaluation (Step 1) is WORTHLESS unless you ACTIVATE (Step 2) the agents/skills.

Example of correct sequence:
- research: NO - not a research task
- svelte5-runes: YES - need reactive state
- sveltekit-structure: YES - creating routes

[Then IMMEDIATELY use Skill() tool:]
> Skill(svelte5-runes)
> Skill(sveltekit-structure)

[THEN and ONLY THEN start implementation]

End.
EOF
