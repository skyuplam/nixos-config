{config, ...}: {
  imports = [
    ./hardware/vm-aarch64-utm.nix
    ./linux-shared.nix
    ./disko-config-utm.nix
  ];

  # Don't require password for sudo
  security.sudo.wheelNeedsPassword = false;

  sops = {
    defaultSopsFile = ../secrets/user.yaml;
    age.keyFile = "/var/lib/sops-nix/keys.txt";
    secrets.hashedPassword = {
      neededForUsers = true;
    };
  };

  networking = {
    useDHCP = false;
    interfaces.enp0s1.useDHCP = true;

    # Define your hostname.
    hostName = "dev";
  };

  # Qemu
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  # Disable the firewall since we're in a VM and we want to make it
  # easy to visit stuff in here. We only use NAT networking anyways.
  networking.firewall.enable = false;
}
