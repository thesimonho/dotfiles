{ pkgs, lib }:
let
  editor = pkgs.writeShellScript "gamedev-nvim" ''
    exec ${pkgs.python3}/bin/python3 ${../../scripts/gamedev-editor.py} "$@"
  '';
  configure = pkgs.writeShellScriptBin "gamedev-configure" ''
    exec ${pkgs.python3}/bin/python3 ${../../scripts/gamedev-configure.py}
  '';
in
{
  bundles = [ "gamedev" ];
  requirements.operatingSystems = [ "arch" ];
  requirements.hasDesktop = true;
  contributions = {
    packages = [ configure ];
    homeFiles.".local/share/gamedev/bin/code" = {
      executable = true;
      text = ''
        #!/bin/sh
        exec flatpak-spawn --host ${editor} "$@"
      '';
    };
    activation.gamedevEditors = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${configure}/bin/gamedev-configure
    '';
  };
}
