{
  pkgs,
  config,
  ...
}: let
  keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIi4mBqMk32PKYVGFJZBXqM+b6vw8b3J0pSFBGAQm3ps TlamM2"];
in {
  # Add ~/.local/bin to PATH
  environment.localBinInPath = true;

  # Since we're using zsh as our shell
  programs = {
    zsh.enable = true;
    # Needed to enable gtk
    dconf.enable = true;

    # thunar file manager(part of xfce) related options
    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-volman
      ];
    };
  };

  services = {
    gvfs.enable = true; # Mount, trash, and other functionalities
    tumbler.enable = true; # Thumbnail support for images
  };

  users = {
    mutableUsers = false;
    groups.terrencelam = {};
    users = {
      terrencelam = {
        isNormalUser = true;
        home = "/home/terrencelam";
        group = "terrencelam";
        extraGroups = ["wheel" "video" "docker"];
        shell = pkgs.zsh;

        openssh.authorizedKeys.keys = keys;
      };
      root.openssh.authorizedKeys.keys = keys;
    };
  };
  boot.initrd.network.ssh.authorizedKeys = keys;
}
