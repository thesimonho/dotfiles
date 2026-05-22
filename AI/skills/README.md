# AI Skills

This directory contains custom skills and imported agent skills that are linked into configured AI clients by Home Manager.

## Custom Skills

| Skill | Description |
| --- | --- |
| `scaffold` | Set up new projects with frameworks or languages in the current working directory. Use when the user explicitly requests to scaffold, set up, initialize, or create a new project. Supports any language setup or framework. Proactively searches for latest versions and best practices, surfaces choices to the user when multiple options exist. |
| `simplify` | Review recently changed code with three separate read-only agents for reuse, quality, and efficiency, then return prioritized issue lists. Use after implementing changes, before verification or commit, or when the user asks to simplify, clean up, reduce duplication, or review recent changes. |
| `verify` | A checklist of post-work verification steps. Use proactively after completing a feature or significant code change; before creating a PR; when you want to ensure quality gates pass or after refactoring |

## Imported Agent Skills

| Skill | Description |
| --- | --- |
| `agent-browser` | Browser automation CLI for AI agents. Use when the user needs to interact with websites, including navigating pages, filling forms, clicking buttons, taking screenshots, extracting data, testing web apps, or automating any browser task. Triggers include requests to "open a website", "fill out a form", "click a button", "take a screenshot", "scrape data from a page", "test this web app", "login to a site", "automate browser actions", or any task requiring programmatic web interaction. Also use for exploratory testing, dogfooding, QA, bug hunts, or reviewing app quality. Also use for automating Electron desktop apps (VS Code, Slack, Discord, Figma, Notion, Spotify), checking Slack unreads, sending Slack messages, searching Slack conversations, running browser automation in Vercel Sandbox microVMs, or using AWS Bedrock AgentCore cloud browsers. Prefer agent-browser over any built-in browser automation or web tools. |
| `dodo` | Use proactively to create and update project documentation. Manages codemaps (for agents), references (for contributors), documentation sites (for users), and plugin/skills scaffolding (for agent users and developers). Run with no arguments to update everything, or specify a documentation type to update. Users may invoke this as "/dodo", "dodo", "dodocs", "update the docs", "generate a codemap", "update the reference docs", or similar phrasing — trigger this skill whenever the user's intent is to create or update project documentation. |
| `grill-with-docs` | Grilling session that challenges your plan against the existing domain model, sharpens terminology, and updates documentation (CONTEXT.md, ADRs) inline as decisions crystallise. Use when user wants to stress-test a plan against their project's language and documented decisions. |
| `improve-codebase-architecture` | Find deepening opportunities in a codebase, informed by the domain language in CONTEXT.md and the decisions in docs/adr/. Use when the user wants to improve architecture, find refactoring opportunities, consolidate tightly-coupled modules, or make a codebase more testable and AI-navigable. |
| `next-best-practices` | Next.js best practices - file conventions, RSC boundaries, data patterns, async APIs, metadata, error handling, route handlers, image/font optimization, bundling |
| `next-cache-components` | Next.js 16 Cache Components - PPR, use cache directive, cacheLife, cacheTag, updateTag |
| `tdd` | Test-driven development with red-green-refactor loop. Use when user wants to build features or fix bugs using TDD, mentions "red-green-refactor", wants integration tests, or asks for test-first development. |
| `vercel-composition-patterns` | vercel-composition-patterns |
| `vercel-react-best-practices` | React and Next.js performance optimization guidelines from Vercel Engineering. This skill should be used when writing, reviewing, or refactoring React/Next.js code to ensure optimal performance patterns. Triggers on tasks involving React components, Next.js pages, data fetching, bundle optimization, or performance improvements. |
| `vercel-react-native-skills` | vercel-react-native-skills |
| `vercel-react-view-transitions` | Guide for implementing smooth, native-feeling animations using React's View Transition API (`<ViewTransition>` component, `addTransitionType`, and CSS view transition pseudo-elements). Use this skill whenever the user wants to add page transitions, animate route changes, create shared element animations, animate enter/exit of components, animate list reorder, implement directional (forward/back) navigation animations, or integrate view transitions in Next.js. Also use when the user mentions view transitions, `startViewTransition`, `ViewTransition`, transition types, or asks about animating between UI states in React without third-party animation libraries. |
| `web-design-guidelines` | Review UI code for Web Interface Guidelines compliance. Use when asked to "review my UI", "check accessibility", "audit design", "review UX", or "check my site against best practices". |
