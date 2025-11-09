{ inputs, pkgs, pkgsUnstable, lib, ... }:

{
  # ---------------------------------------------------------------------------
  # Shared packages and environment
  # ---------------------------------------------------------------------------
  home = { packages = with pkgs; [ ]; };

  # ---------------------------------------------------------------------------
  # Program configurations (home manager modules)
  # ---------------------------------------------------------------------------
  programs = {
    gh = { hosts = { "github.com" = { user = "thesimonho"; }; }; };
    git = { userEmail = "simonho.ubc@gmail.com"; };
  };
}
