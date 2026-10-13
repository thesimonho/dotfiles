---
agent:
  instruction: Keep the Neovim setup and commit-review contract current when these files change.
  on-change: "nvim/**"
---

# Neovim

This directory configures Neovim with LazyVim. Plugin overrides live in
`lua/plugins/`, editor settings in `lua/config/`, and local helpers in
`lua/utils/`. Keep the plugin lockfile unchanged unless a plugin update is part
of the task.

## Shared Git helpers

`lua/utils/git.lua` owns directory-based Git operations. `run(cwd, args)` runs
Git in an explicit directory and returns raw stdout, including NUL separators.
It raises an error when Git fails. `get_git_root(cwd)` returns the absolute
working-tree root or `nil` when Git cannot resolve one. Its default is the
editor's current directory; pass the terminal directory explicitly for terminal
integrations. Git handles both ordinary checkouts and worktrees with `.git`
files. Snacks root lookups used by buffer UI remain based on the buffer path.

Keep review state, buffer ownership, highlights, and controls in
`lua/utils/git_review.lua`. Shared Git helpers have no review side effects.

## LazyGit commit review

Open LazyGit through Snacks in Neovim. In the commits panel, select a commit and
press `Ctrl+O`. The custom command in `lazygit/config.yml` loads
`utils.git_review` through the owning editor's `$NVIM` socket. It does not depend
on the editor having registered `:GitReviewOpen` at startup. The repository
directory comes from the Snacks terminal buffer metadata, not its window
options or the editor's current directory.

The helper hides the LazyGit window, opens and lists the changed files that
still exist in the working tree, and enables Gitsigns plus line backgrounds for
those buffers. `Shift+H` and `Shift+L` move between buffers. `<leader>gH` toggles
review highlights; `<leader>gC` clears the review and closes only buffers created
by the helper. It preserves pre-existing buffers and refuses to discard unsaved
changes. Run the close command again after saving a buffer it could not close.

The files remain editable. The comparison uses the selected commit's first
parent; a root commit uses the empty tree. For an older commit, the highlights
also include later changes and local edits in those files. Files deleted from
the working tree are skipped. This is a working-tree review, not a snapshot of
historical file contents.

Gitsigns attachment is asynchronous. Wait for its first diff summary, then reattach the review buffer with the selected parent as its initial base. This keeps an in-flight index read from overwriting the review comparison, including when highlights are enabled again for a hidden buffer. Review line backgrounds use a separate namespace so other buffers retain their normal highlighting. Disabling review restores the normal index comparison.

Restart LazyGit after changing its config. Restart Neovim to load changed
keymaps; the remote open command itself can load the helper in an existing
editor session.
