{pkgs, ...}: let
  keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIi4mBqMk32PKYVGFJZBXqM+b6vw8b3J0pSFBGAQm3ps TlamM2"];
in {
  imports = [
    ./common.nix
  ];
  # Add ~/.local/bin to PATH
  environment.localBinInPath = true;

  # Since we're using fish as our shell
  programs = {
    fish.enable = true;
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
    nix-ld.dev.enable = true;
  };

  services = {
    gvfs.enable = true; # Mount, trash, and other functionalities
    tumbler.enable = true; # Thumbnail support for images
  };

  users = {
    groups.terrencelam = {};
    users = {
      terrencelam = {
        isNormalUser = true;
        home = "/home/terrencelam";
        group = "terrencelam";
        extraGroups = ["wheel" "video" "docker"];
        shell = pkgs.fish;

        openssh.authorizedKeys.keys = keys;
      };
      root.openssh.authorizedKeys.keys = keys;
    };
  };
  boot.initrd.network.ssh.authorizedKeys = keys;
}
