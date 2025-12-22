{
  config,
  inputs,
  pkgs,
  pkgsUnstable,
  lib,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  home = {
    packages = with pkgs; [
      (pkgsUnstable.opencode)
      (pkgsUnstable.claude-code)
      (pkgsUnstable.claude-code-acp)
      (pkgsUnstable.codex)
      (pkgsUnstable.codex-acp)
    ];
  };
}
