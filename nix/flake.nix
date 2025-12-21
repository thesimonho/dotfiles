{
  description = "Cross-platform config using Home Manager (Linux/macOS)";

  nixConfig = {
    max-jobs = "auto";
    cores = 0;
    download-buffer-size = 128;
    connect-timeout = 60;
    stalled-download-timeout = 300;
    warn-dirty = false;

    extra-substituters = [ "https://yazi.cachix.org" ];
    extra-trusted-public-keys =
      [ "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k=" ];
    extra-experimental-features = [ "nix-command" "flakes" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    ghostty.url = "github:ghostty-org/ghostty";
    agenix.url = "github:ryantm/agenix";
    yazi.url = "github:sxyazi/yazi";
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, nix-flatpak, home-manager
    , plasma-manager, agenix, ghostty, ... }:
    let
      pkgsFor = system:
        import nixpkgs {
          inherit system;
          overlays = [ ];
          config.allowUnfree = true;
        };

      unstableFor = system:
        import nixpkgs-unstable {
          inherit system;
          overlays = [ ];
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
          inputs.plasma-manager.homeModules.plasma-manager
          agenix.homeManagerModules.default
          ./hosts/home.nix
          ./hosts/work.nix
          ./modules/common.nix
          ./modules/kde.nix
          ./modules/ssh.nix
          ./modules/AI.nix
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
          inputs.plasma-manager.homeModules.plasma-manager
          agenix.homeManagerModules.default
          ./hosts/work.nix
          ./modules/common.nix
          ./modules/kde.nix
          ./modules/ssh.nix
          ./modules/AI.nix
          { home.stateVersion = "25.05"; } # dont touch this
        ];
      };
    };
}

