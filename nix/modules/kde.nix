{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [ inputs.plasma-manager.homeModules.plasma-manager ];

  config = lib.mkIf (config.my.desktop == "kde") {
    # Re-enable pinentry's KWallet integration
    # (disabled by default to prevent deadlock when KWallet uses GPG encryption — safe with blowfish)
    home.sessionVariables.PINENTRY_KDE_USE_WALLET = "1";

    # Make KWallet the Secret Service provider on KDE. seahorse's
    # ssh-askpass (see modules/ssh.nix) writes through libsecret to
    # whichever daemon owns org.freedesktop.secrets — which we want
    # to be KWallet, so SSH passphrases land in the existing wallet
    # that PAM already unlocks at SDDM login.
    xdg.dataFile."dbus-1/services/org.freedesktop.secrets.service".text = ''
      [D-BUS Service]
      Name=org.freedesktop.secrets
      Exec=/usr/bin/kwalletd6
    '';

    programs = {
      plasma = {
        enable = true;
        configFile.kwalletrc.Wallet.Enabled = true;
        input.keyboard = {
          numlockOnStartup = "on";
          repeatDelay = 350;
          repeatRate = 30;
        };
        kwin.effects = {
          blur.enable = true;
          translucency.enable = true;
          wobblyWindows.enable = true;
        };
        kscreenlocker.timeout = 15;
        session.sessionRestore.restoreOpenApplicationsOnLogin = "startWithEmptySession";
        powerdevil.AC = {
          autoSuspend = {
            action = "nothing";
          };
          dimDisplay = {
            enable = true;
            idleTimeout = 600;
          };
          turnOffDisplay = {
            idleTimeout = 1200;
          };
        };
        shortcuts = {
          # mostly to remove Meta key binds
          ksmserver = {
            "Lock Session" = "Screensaver";
          };
          plasmashell = {
            "activate application launcher" = "Alt+F1";
            "show-on-mouse-pos" = "";
            "activate task manager entry 1" = "";
            "activate task manager entry 2" = "";
            "activate task manager entry 3" = "";
            "activate task manager entry 4" = "";
            "activate task manager entry 5" = "";
            "activate task manager entry 6" = "";
            "activate task manager entry 7" = "";
            "activate task manager entry 8" = "";
            "activate task manager entry 9" = "";
          };
          kwin = {
            "Overview" = "";
            "Edit Tiles" = "";
            "Show Desktop" = "";
            "Walk Through Windows" = "Alt+Tab";
            "Walk Through Windows (Reverse)" = "Alt+Shift+Tab";
            "Walk Through Windows of Current Application" = "Alt+`";
          };
          org_kde_powerdevil = {
            "powerProfile" = "Battery";
          };
          "org.kde.kscreen.desktop" = {
            "ShowOSD" = "Display";
          };
          "org.kde.spectacle.desktop" = {
            "RecordRegion" = "Meta+Shift+R";
          };
        };
      };
      konsole = {
        enable = true;
        defaultProfile = "zsh";
        profiles = {
          zsh = {
            command = "${pkgs.zsh}/bin/zsh";
            font.name = "CaskaydiaCove Nerd Font";
            font.size = 12;
            colorScheme = "Breeze";
          };
        };
      };
    };
  };
}
