{ pkgs, ... }: {
  programs.plasma = { enable = true; };

  programs.konsole = {
    enable = true;
    defaultProfile = "zsh";
    profiles = {
      zsh = {
        command = "${pkgs.zsh}/bin/zsh";
        font.name = "Fira Code";
        font.size = 12;
        colorScheme = "Breeze";
      };
    };
  };
}
