{pkgs, ...}: let
  keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIi4mBqMk32PKYVGFJZBXqM+b6vw8b3J0pSFBGAQm3ps TlamM2"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMpu1jDjQq08V1YbdchJbTXr6vXFHjzxJYewhYSeeNj+ Tlam key for tlamwb"
  ];
in {
  imports = [
    ./common.nix
  ];
  # Add ~/.local/bin to PATH
  environment.localBinInPath = true;

  # CVE-2026-111943 | eMudhra Intermediate CA Compromise
  # Ref. https://github.com/NixOS/nixpkgs/issues/576485
  security.pki.caCertificateBlacklist = [
    # CVE-2026-111943
    "Comodo AAA Services root"
    # https://hg-edge.mozilla.org/projects/nss/rev/26d38a0c3fb81e7fb2acedbaf4c42dd21dce0517
    "emSign ECC Root CA - G3"
    # https://hg-edge.mozilla.org/projects/nss/rev/8159223c48ceeb1273a1915bca95a517294ab0e0
    "emSign Root CA - C1"
    "emSign ECC Root CA - C3"
  ];

  # Since we're using fish as our shell
  programs = {
    fish.enable = true;
    # Needed to enable GTK
    dconf.enable = true;

    # Scrollable-tiling Wayland compositor
    niri.enable = true;

    # thunar file manager(part of xfce) related options
    thunar = {
      enable = true;
      plugins = with pkgs; [
        thunar-archive-plugin
        thunar-volman
      ];
    };
    nix-ld.enable = true;
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
