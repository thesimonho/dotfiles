{
  description = "Cross-platform config using Home Manager (Linux/macOS)";

  nixConfig = {
    extra-substituters = [ 
      "https://wezterm.cachix.org"
      "https://yazi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "wezterm.cachix.org-1:kAbhjYUC9qvblTE+s7S+kl5XM1zVa4skO+E/1IDWdH0="
      "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
    ];
  };

  inputs = {
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/release-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixgl.url = "github:nix-community/nixGL";
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
        ghostty.url = "github:ghostty-org/ghostty";
    wezterm.url = "github:wezterm/wezterm?dir=nix";
    yazi.url = "github:sxyazi/yazi";
  };

  outputs =
    inputs@{ self, nixpkgs, nixpkgs-unstable, nixgl, nix-flatpak, home-manager, ghostty,... }:
    let
  pkgsFor = system:
  import nixpkgs {
    inherit system;
    overlays = [ nixgl.overlays.default ];
    config.allowUnfree = true;
  };

  unstableFor = system:
  import nixpkgs-unstable {
    inherit system;
    overlays = [ nixgl.overlays.default ];
    config.allowUnfree = true;
  };
    in {
      apps.x86_64-linux.hm = {
        type = "app";
        program =
          "${home-manager.packages.x86_64-linux.home-manager}/bin/home-manager";
      };

      homeConfigurations."home" = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsFor "x86_64-linux";
        extraSpecialArgs = {
          inherit inputs;
          pkgsUnstable = unstableFor "x86_64-linux";
        };
        modules = [
      inputs.nix-flatpak.homeManagerModules.nix-flatpak
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
      inputs.nix-flatpak.homeManagerModules.nix-flatpak
          ./modules/common.nix
          ./modules/work.nix
          ./hosts/linux.nix
          { home.stateVersion = "25.05"; } # dont touch this
        ];
      };
    };
}

