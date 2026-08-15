---
agent:
  instruction: "Keep this marketplace limited to inert cross-surface installation probes."
  on-change: ".agents/plugins/marketplace.json"
---

# Work Surface Marketplace

This is a deliberately minimal Git-backed marketplace used to test whether a plugin is available on ChatGPT and Codex surfaces.

## Plugin

`work-surface-probe` contains one inert skill. When explicitly asked to check the plugin, it replies with the fixed marker `WORK-SURFACE-PROBE-AVAILABLE`.

The marketplace entry is at `.agents/plugins/marketplace.json`. The plugin source is `plugins/work-surface-probe`.
