---
agent:
  instruction: Keep the custom command entry points and editor requirements current.
  on-change: "lazygit/config.yml"
---

# LazyGit

`config.yml` contains terminal UI settings, keybindings, and custom Git commands.
Snacks adds its theme and Neovim editing integration when it opens LazyGit.

In the commits panel, `Ctrl+O` sends the selected commit to
`nvim/lua/utils/git_review.lua` through `$NVIM`. Launch LazyGit from Snacks in
Neovim so the helper can hide the owning terminal and return to the editor.
Command output stays in the LazyGit log, and remote-command failures are shown
instead of being hidden. See `nvim/README.md` for the review controls and
comparison limits. Quit and reopen LazyGit after editing this config.
