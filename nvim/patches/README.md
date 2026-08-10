---
agent:
  instruction: Keep patches minimal, pinned to the lazy-lock revision, and remove them when upstream contains the fix.
  on-change:
    - "nvim/patches/**"
    - "nvim/lazy-lock.json"
---

# Neovim plugin patches

This directory contains small downstream fixes that Lazy applies before it
builds a pinned plugin. Each patch must name the upstream problem in its header
and remain safe to apply when the plugin build runs more than once.

Remove a patch and its build hook as soon as the pinned upstream revision
contains the same fix.
