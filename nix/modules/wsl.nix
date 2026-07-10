{
  config,
  lib,
  pkgs,
  ...
}:

/*
  Single home for everything WSL-specific.

  A host becomes a "Windows + WSL" box by setting `my.os = "wsl"`; this module
  is the one place that then wires up the Windows<->Linux interop. Tool-specific
  WSL tweaks that belong with their tool (the SSH auth socket in ssh.nix, GPG
  pinentry in gpg.nix, the zsh agent-preload) stay there on purpose — this module
  owns the *cross-cutting* interop, not every `isWSL` branch in the repo.

  Distro-level, root-owned concerns nix can't manage from home-manager
  (e.g. /etc/wsl.conf interop.appendWindowsPath / automount) live in
  post-setup.sh, not here.
*/

let
  inherit (lib) mkIf mkOption types;

  isWSL = config.my.os == "wsl";
  dotfiles = config.my.dotfilesPath;
  windowsUser = config.my.wsl.windowsUser;

  windowsHome = "/mnt/c/Users/${toString windowsUser}";
  weztermSource = "${dotfiles}/wezterm";
  # WezTerm.exe on Windows searches %USERPROFILE%\.config\wezterm\wezterm.lua.
  weztermTarget = "${windowsHome}/.config/wezterm";
in
{
  options.my.wsl = {
    windowsUser = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "simon";
      description = ''
        Windows account name under C:\Users. When set, the WezTerm config is
        mirrored to %USERPROFILE%\.config\wezterm so the Windows-side terminal
        reads the same nix-managed source as everything else — no hand-kept
        second clone. Leave null to skip the mirror.
      '';
    };
  };

  config = mkIf isWSL {
    # Bridge Linux -> Windows default browser. `wslu` provides `wslview`, which
    # hands URLs and paths to the Windows shell. Setting BROWSER makes every
    # tool that shells out to it (nvim `gx`, gh, git web, xdg-open) open the
    # Windows browser instead of failing silently.
    home.packages = [ pkgs.wslu ];
    home.sessionVariables.BROWSER = "wslview";

    home.shellAliases = {
      # `open .` / `open <url>` — wslview resolves files, dirs, and URLs
      # against the Windows default handler (Explorer, browser, etc.).
      open = "wslview";
      # Shell <-> Windows clipboard. clip.exe copies; Get-Clipboard reads it
      # back (stripping the CR that PowerShell appends to each line).
      pbcopy = "clip.exe";
      pbpaste = "powershell.exe -NoProfile -Command Get-Clipboard | tr -d '\\r'";
    };

    # WSL prepends the entire Windows PATH by default; post-setup.sh disables
    # that (interop.appendWindowsPath=false) for speed and a clean completion
    # namespace. Re-add only the dirs holding the binaries wslview and the
    # clipboard aliases call: System32 (clip.exe, cmd.exe, rundll32.exe), the
    # WindowsPowerShell dir (powershell.exe — NOT directly in System32), and
    # the Windows dir (explorer.exe). Harmless while appendWindowsPath is still
    # on; the sole Windows PATH source once it's off. Assumes drive C:.
    home.sessionPath = [
      "/mnt/c/Windows/System32"
      "/mnt/c/Windows/System32/WindowsPowerShell/v1.0"
      "/mnt/c/Windows"
    ];

    # Mirror the WezTerm config onto the Windows filesystem. A *copy* (not a
    # symlink) because Windows apps can't follow WSL symlinks, and the *whole
    # tree* (not a UNC bootstrap) so `wezterm.config_dir` resolves colors/ and
    # required modules locally with no cross-boundary path juggling. Re-synced
    # on every `home-manager switch`; source of truth stays the WSL repo.
    home.activation.mirrorWeztermToWindows = mkIf (windowsUser != null) (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ -d "${windowsHome}" ] && [ -d "${weztermSource}" ]; then
          run rm -rf ${lib.escapeShellArg weztermTarget}
          run mkdir -p ${lib.escapeShellArg weztermTarget}
          run cp -r ${lib.escapeShellArg weztermSource}/. ${lib.escapeShellArg weztermTarget}/
        else
          echo "wsl: skipping WezTerm mirror (missing ${windowsHome} or ${weztermSource})"
        fi
      ''
    );
  };
}
