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

## Startup and project sessions

Starting `nvim` without arguments restores the current directory's saved
session, or opens the file picker in that directory when no session exists.
Dashboard project actions and the Projects picker use the same loader in
`lua/utils/ui.lua`. Explicit file/directory arguments and piped input keep their
normal startup behaviour. The dashboard does not open automatically; it is
still available through `Snacks.dashboard()`.

Persisted owns session storage and automatic saving, limited to `~/dotfiles`
and `~/Projects`. Its automatic loader is disabled because the shared loader
owns startup. The shared loader preserves Persisted load events and sources
sessions without suppressing errors. A failed restore reports the session path
and error, then stops automatic saving to protect the saved session from a
partial restore, including saves on tab changes. Resolve the error and reload
the session, or select a project without a saved session, to permit saving again.

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

## Terminal controls

In Normal mode, `Space` then `\` opens the terminal choices menu. Another `\` toggles regular terminals; `1` through `4` select a terminal and `s` opens the terminal selector. These are Normal-mode mappings: press `Esc` to leave a regular terminal's input mode first.

The toggle action uses ToggleTerm's live terminal registry. Hidden agent terminals reserve their IDs but do not count as regular shells or decide whether shells should open or close. Restored terminal buffer names are not proof that a live ToggleTerm instance exists.

## Plugin ownership and local overrides

LazyVim owns Snacks setup and the notification handoff to Noice. Add Snacks
options and filetype key specs instead of replacing its `config` function.
Plugin rules and listeners belong in the owning plugin's load callback, after
`setup(opts)`. Use which-key specs and nvim-lint options instead of requiring
those plugins during spec import or `init`.

The options picker captures its source window and buffer. Local changes apply
to that source; the global toggle edits global values and defaults for future
windows/buffers. Global-only options always use global scope. Numeric prompts
accept whole numbers. Window line-number toggles survive buffer changes;
utility buffers receive their defaults on FileType.

Ruff LSP owns Python diagnostics. `lua/plugins/languages/python.lua` supplies
one set of personal rule overrides to Ruff LSP and Conform's Ruff fix/format
commands. Project configuration still supplies other settings. nvim-lint does
not run a second Ruff diagnostic pass. Markdown's linter and formatter share
`lua/plugins/languages/.markdownlint.yaml`.

nvim-dap-go owns the Go adapter and built-in debug choices; Mason installs
Delve but does not add duplicate Go configurations. Resolve launch paths and
the adapter working directory at launch time so project switches and symlinked
checkouts work. Package-info loads for package.json buffers in any directory.

Neo-tree hides ignored files but always shows `.env*`; `.git` can be shown
with the hidden toggle. `node_modules`, `.DS_Store`, and `thumbs.db` stay hidden.
Host-side terminal selection recognises both `.devcontainer.json` and
`.devcontainer/devcontainer.json`. Docker detection uses `/.dockerenv`.

The status column caches marks once per statuscol redraw tick and Git signs
once per line in that tick. Keep this cache on statuscol's window-owned args;
it must refresh on redraw and must not retain deleted buffers globally.
The unused process/Compose service helpers and their shell scripts were
removed. They are not a supported editor integration; Git review remains
independent of them.
