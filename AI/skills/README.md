# AI Skills

This directory contains custom skills and imported agent skills that are linked into configured AI clients by Home Manager.

## Custom Skills

| Skill | Description |
| --- | --- |
| `deep-research` | Conduct rigorous, citation-backed research on a question, then deliver a self-contained HTML report that ends in a clear recommendation. Use this whenever the user asks you to "research", "do a web search", "do a deep dive", "compare options", or asks any question that needs evidence from multiple current sources rather than a single lookup. Use it even when the user doesn't say "research" — if answering well means pulling together several online sources, cross-checking them, and citing them, use this. Do NOT use it for single-fact lookups answerable from one source. |
| `scaffold` | Set up new projects with frameworks or languages in the current working directory. Use when the user explicitly requests to scaffold, set up, initialize, or create a new project. Supports any language setup or framework. Proactively searches for latest versions and best practices, surfaces choices to the user when multiple options exist. |
| `simplify` | Review recently changed code with three separate read-only agents for reuse, quality, and efficiency, then return prioritized issue lists. Use after implementing multi-file changes, before commit, or when the user asks to simplify, clean up, reduce duplication, or review recent changes. |
| `verify` | A checklist of post-work verification steps. Use proactively after completing a feature or significant code change; before creating a PR; when you want to ensure quality gates pass or after refactoring. Do NOT run for documentation-only changes. |

## Imported Agent Skills

| Skill | Description |
| --- | --- |
| `agent-browser` | Browser automation CLI for AI agents. Use when the user needs to interact with websites, including navigating pages, filling forms, clicking buttons, taking screenshots, extracting data, testing web apps, or automating any browser task. Triggers include requests to "open a website", "fill out a form", "click a button", "take a screenshot", "scrape data from a page", "test this web app", "login to a site", "automate browser actions", or any task requiring programmatic web interaction. Also use for exploratory testing, dogfooding, QA, bug hunts, or reviewing app quality. Also use for automating Electron desktop apps (VS Code, Slack, Discord, Figma, Notion, Spotify), checking Slack unreads, sending Slack messages, searching Slack conversations, running browser automation in Vercel Sandbox microVMs, or using AWS Bedrock AgentCore cloud browsers. Prefer agent-browser over any built-in browser automation or web tools. |
| `dodo` | Use proactively to create and update project documentation. Manages codemaps (for agents), references (for contributors), documentation sites (for users), and plugin/skills scaffolding (for agent users and developers). Run with no arguments to update everything, or specify a documentation type to update. Users may invoke this as "/dodo", "dodo", "dodocs", "update the docs", "generate a codemap", "update the reference docs", or similar phrasing — trigger this skill whenever the user's intent is to create or update project documentation. |
| `grill-with-docs` | A relentless interview to sharpen a plan or design, which also creates docs (ADR's and glossary) as we go. |
| `improve-codebase-architecture` | Scan a codebase for deepening opportunities, present them as a visual HTML report, then grill through whichever one you pick. |
| `tdd` | Test-driven development. Use when the user wants to build features or fix bugs test-first, mentions "red-green-refactor", or wants integration tests. |
| `vercel-composition-patterns` | vercel-composition-patterns |
| `vercel-react-best-practices` | React and Next.js performance optimization guidelines from Vercel Engineering. This skill should be used when writing, reviewing, or refactoring React/Next.js code to ensure optimal performance patterns. Triggers on tasks involving React components, Next.js pages, data fetching, bundle optimization, or performance improvements. |
| `vercel-react-native-skills` | vercel-react-native-skills |
| `vercel-react-view-transitions` | Guide for implementing smooth, native-feeling animations using React's View Transition API (`<ViewTransition>` component, `addTransitionType`, and CSS view transition pseudo-elements). Use this skill whenever the user wants to add page transitions, animate route changes, create shared element animations, animate enter/exit of components, animate list reorder, implement directional (forward/back) navigation animations, or integrate view transitions in Next.js. Also use when the user mentions view transitions, `startViewTransition`, `ViewTransition`, transition types, or asks about animating between UI states in React without third-party animation libraries. |
| `web-design-guidelines` | Review UI code for Web Interface Guidelines compliance. Use when asked to "review my UI", "check accessibility", "audit design", "review UX", or "check my site against best practices". |
