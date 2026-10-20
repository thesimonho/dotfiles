---
agent:
  instruction: Keep app selection and game editor bridge contracts current.
  on-change: ["nix/modules/apps/**", "nix/scripts/gamedev-*.py"]
---

# Applications

`catalog.nix` declares selectable applications and supporting integrations. `default.nix` resolves host selection and adapts Flatpak declarations. Keep application-specific behavior out of that shared adapter.

`gamedev.nix` contributes the Arch game editor integration through the `gamedev` bundle. It installs an executable Flatpak bridge named `code`, a host Ghostty/Neovim launcher, and `gamedev-configure`. Host Neovim comes from the common Neovim module; Ghostty comes from the desktop bundle. Other Linux platforms can install the game Flatpaks without this Arch editor integration.

`nix/scripts/gamedev-editor.py` accepts explicit Godot arguments and Unity's VS Code-style project plus `-g file:line:column`. It passes argument arrays without a shell, converts zero-based Godot positions, and opens an independent terminal window. Position the cursor on `VimEnter`: Neovim 0.12's separate UI/server startup does not preserve the earlier `+call cursor` approach.

`nix/scripts/gamedev-configure.py` merges only selected external-editor and Blender-path preferences. Godot uses versioned text resources; Unity uses base64 string values in the Flatpak's `data/unity3d/prefs`. Keep both files writable. Close editors before activation. Invalid existing preference files must fail rather than silently replace user settings. A new Godot profile needs one launch before `gamedev-configure` can find its settings file.

See `nix/README.md` for setup and runtime acceptance. Validate actual editor Open Script actions and Neovim file/cursor results; a successful launcher exit alone does not prove the integration works. Do not add or run unit tests.
