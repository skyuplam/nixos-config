{pkgs, ...}: {
  imports = [
    ./common.nix
  ];
  # https://daiderd.com/nix-darwin/manual/index.html#opt-homebrew.brews
  homebrew = {
    enable = true;
    brews = ["kanata" "skhd-zig"];
    casks = [
      "1password"
      "google-chrome"
      "keepingyouawake"
      "keyguard"
      "linearmouse"
      "openscad"
      "signal"
      "stats"
      "syncthing-app"
      "waterfox"
    ];
    taps = [
      "jackielii/tap"
      "krtirtho/apps"
    ];
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };
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
    stateVersion = 5;
  };

  # The user should already exist, but we need to set this up so Nix knows
  # what our home directory is (https://github.com/LnL7/nix-darwin/issues/423).
  users.users.terrencelam = {
    home = "/Users/terrencelam";
    # https://daiderd.com/nix-darwin/manual/index.html#opt-users.users._name_.shell
    shell = pkgs.fish;
  };
  programs.fish.enable = true;
  # fish is the default shell on Mac and we want to make sure that we're
  # configuring the rc correctly with nix-darwin paths.
  programs.fish.loginShellInit = ''
    # Nix
    if test -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
      . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
    end
    # End Nix
  '';
  environment.pathsToLink = ["/share/fish"];
  # Determinate Systems config
  environment.etc."determinate/config.json".text = ''
    {
      "garbageCollector": {
        "strategy": "automatic"
      }
    }
  '';
  system.primaryUser = "terrencelam";

  services = {
    yabai = {
      enable = true;
      package = pkgs.yabai;
      enableScriptingAddition = true;
      extraConfig = builtins.readFile (builtins.path {
        name = "yabai-config";
        path = ./config/yabai/yabairc;
      });
    };
    # skhd = {
    #   enable = true;
    #   package = pkgs.skhd-zig;
    #   skhdConfig = builtins.readFile (builtins.path {
    #     name = "skhd-config";
    #     path = ./config/skhd/skhdrc;
    #   });
    # };
  };
}
