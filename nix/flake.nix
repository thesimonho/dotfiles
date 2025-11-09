{
  description = "Cross-platform config using Home Manager (Linux/macOS)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # nix-darwin.url = "github:LnL7/nix-darwin/release-25.05";
    # nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    wezterm.url = "github:wezterm/wezterm?dir=nix";
    yazi.url = "github:sxyazi/yazi";
  };

  outputs =
    inputs@{ self, nixpkgs, nixpkgs-unstable, nixgl, home-manager, ... }:
    let
      pkgsFor = system:
        import nixpkgs {
          inherit system;
          overlays = [ nixgl.overlay ];
          config.allowUnfree = true;
        };
      unstableFor = system:
        import nixpkgs-unstable {
          inherit system;
          overlays = [ nixgl.overlay ];
          config.allowUnfree = true;
        };
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

      homeConfigurations."home" = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsFor "x86_64-linux";
        extraSpecialArgs = {
          inherit inputs;
          pkgsUnstable = unstableFor "x86_64-linux";
        };
        modules = [
          ./modules/common.nix
          ./modules/home.nix
          ./hosts/linux.nix
          { home.stateVersion = "25.05"; } # dont touch this
        ];
      };

      homeConfigurations."work" = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsFor "x86_64-linux";
        extraSpecialArgs = {
          inherit inputs;
          pkgsUnstable = unstableFor "x86_64-linux";
        };
        modules = [
          ./modules/common.nix
          ./modules/work.nix
          ./hosts/linux.nix
          { home.stateVersion = "25.05"; } # dont touch this
        ];
      };
    };
}

