{
  description = "Cross-platform Config (Linux/macOS)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-25.05";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let forSystem = system: import nixpkgs { inherit system; };
    in {
      # ---------- Linux (non-NixOS) via Home Manager ----------
      homeConfigurations."linux" = home-manager.lib.homeManagerConfiguration {
        system = "x86_64-linux";
        pkgs = forSystem "x86_64-linux";
        modules =
          [ ./hosts/linux.nix ./modules/common.nix ./modules/flatpak.nix ];
      };

      # ---------- macOS via nix-darwin + Home Manager ----------

    };
}
