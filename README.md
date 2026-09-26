# dotfiles

## Keybinding grammar

- `hjkl` means direction.

- Action keys keep the same meaning across scopes where possible:
  - `n` = new
  - `d` = delete/close

- Direct modifier chords are for frequent navigation:
  - `Ctrl+hjkl` moves between 2D panes/windows in the current app.
  - `Shift+h/l` moves between 1D siblings such as buffers, tabs, and pages.
  - `Super` scopes direct chords to the terminal / terminal multiplexer layer.

- Leader keys, prefixes, and key tables are for lifecycle and manipulation commands such as new, split, close, rename, and zoom.
  - The final key represents the action where possible (`n` new, `d` delete, etc.)
  - Modifiers distinguish the target scope when the same action applies to multiple object types:
    - no additional modifier = local/pane
    - `Shift` = 1D sibling, such as a buffer or tab
    - `Ctrl` = higher-level container, such as a workspace

- `Alt` is app-local options/alternate behavior, not a shared custom layer.

### Examples

Navigation:

- `Ctrl+hjkl` → move between Neovim windows or other 2D panes.
- `Super+Ctrl+hjkl` → move between terminal multiplexer panes.
- `Shift+h/l` → previous/next buffer or tab.
- `Super+Shift+h/l` → previous/next terminal multiplexer tab.

Lifecycle commands:

- `prefix+Shift+d` → close the current tab.
- `prefix+Ctrl+d` → close the current workspace.
- `prefix+Shift+n` → create a new tab.
- `prefix+Ctrl+n` → create a new workspace.

The exact leader or prefix key is application-specific; the grammar after it should remain consistent where practical.
