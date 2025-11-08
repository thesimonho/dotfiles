{
  description = "Cross-platform config using Home Manager (Linux/macOS)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # nix-darwin.url = "github:LnL7/nix-darwin/release-25.05";
    # nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let mkPkgs = system: import nixpkgs { inherit system; };
    in {
      apps.x86_64-linux.hm = {
        type = "app";
        program =
          "${home-manager.packages.x86_64-linux.home-manager}/bin/home-manager";
      };
      # apps.aarch64-darwin.hm = {
      #   type = "app";
      #   program =
      #     "${home-manager.packages.aarch64-darwin.home-manager}/bin/home-manager";
      # };

      homeConfigurations."linux" = home-manager.lib.homeManagerConfiguration {
        system = "x86_64-linux";
        pkgs = mkPkgs "x86_64-linux";
        modules = [
          ./hosts/linux.nix
          ./modules/common.nix
          ./modules/flatpak.nix
          { home.stateVersion = "25.05"; }
        ];
      };
    };
}

