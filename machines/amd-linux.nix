{
  config,
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
    age.keyFile = "/var/lib/sops-nix/key.txt";
    secrets.hashedPassword = {
      neededForUsers = true;
    };
  };
}
