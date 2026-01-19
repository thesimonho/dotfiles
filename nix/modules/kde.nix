{ pkgs, lib, ... }:

lib.mkIf pkgs.stdenv.isLinux {
  xdg.dataFile."dbus-1/services/org.freedesktop.secrets.service".text = ''
    [D-BUS Service]
    Name=org.freedesktop.secrets
    Exec=/usr/bin/kwalletd6
  '';

  programs = {
    plasma = {
      enable = true;
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
}
