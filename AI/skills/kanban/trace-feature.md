# Trace Feature

Find all GitHub Project and issue tracker tickets that are related to a particular feature to understand its context and current state. Use that information to construct a dependency map of issues and tasks.

This could be for the specific feature being asked about, or multiple features that are affected by, or dependent on, the feature.

## How to trace

Identify the feature in question, then reference the project's `docs/glossary.md` for terminology. Apply `domain-modeling` as an overlay if the feature's tickets, documentation, and code use inconsistent domain terms or operations. In a tracked repository, locate the feature's Milestone first, read its predecessor links and scope anchors, then list its open Project tickets and search related issues by relevant terminology and keywords.

Identify both milestone-level sequencing and native issue-level blocking relationships. Treat parent/sub-issue relationships as grouping, not proof of execution order.

Present the user with the Milestone → feature slice → issue dependency map, with a summary of what has been done, current Project state, and what is blocked or coming up.
