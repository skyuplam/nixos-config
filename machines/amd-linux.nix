{
  lib,
  pkgs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware/amd-linux.nix
    ./linux-shared.nix
  ];

  sops = {
    defaultSopsFile = ../secrets/user.yaml;
    age.keyFile = "/var/lib/sops-nix/keys.txt";
    secrets.hashedPassword = {
      neededForUsers = true;
    };
  };

  environment = {
    systemPackages = [pkgs.sbctl];
  };

  boot = {
    loader.systemd-boot.enable = lib.mkForce false;
    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };
  };

  networking.hostName = "tlamws";
}
