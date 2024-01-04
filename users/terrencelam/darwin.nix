{pkgs, ...}: {
  # https://daiderd.com/nix-darwin/manual/index.html#opt-homebrew.brews
  homebrew = {
    enable = true;
    casks = [
      "1password"
      "google-chrome"
      "keepingyouawake"
      "linearmouse"
      "stats"
      "utm"
    ];
  };

  system = {
    # Keyboard
    # https://daiderd.com/nix-darwin/manual/index.html#opt-system.keyboard.enableKeyMapping
    keyboard.enableKeyMapping = true;
    keyboard.remapCapsLockToEscape = true;
    # Key repeat
    # https://daiderd.com/nix-darwin/manual/index.html#opt-system.defaults.NSGlobalDomain.InitialKeyRepeat
    defaults.NSGlobalDomain.InitialKeyRepeat = 12;
    defaults.NSGlobalDomain.KeyRepeat = 1;
  };

  # The user should already exist, but we need to set this up so Nix knows
  # what our home directory is (https://github.com/LnL7/nix-darwin/issues/423).
  users.users.terrencelam = {
    home = "/Users/terrencelam";
    # https://daiderd.com/nix-darwin/manual/index.html#opt-users.users._name_.shell
    shell = pkgs.zsh;
  };
  environment.pathsToLink = ["/share/zsh"];

  services = {
    yabai = {
      enable = true;
      package = pkgs.yabai;
    };
    skhd.enable = true;
  };
}
