{config, ...}: {
  imports = [
    ./hardware/vm-aarch64-utm.nix
    ./linux-shared.nix
    ./disko-config-utm.nix
  ];

  # Don't require password for sudo
  security.sudo.wheelNeedsPassword = false;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.mutableUsers = false;

  sops = {
    defaultSopsFile = ../secrets/user.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";
    secrets.hashedPassword = {
      neededForUsers = true;
    };
  };

  networking = {
    useDHCP = false;
    interfaces.enp0s1.useDHCP = true;

    # Define your hostname.
    hostName = "dev";
    # Interface is this on my M2
  };

  # Qemu
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  # For now, we need this since hardware acceleration does not work.
  # environment.variables.LIBGL_ALWAYS_SOFTWARE = "1";

  # Lots of stuff that uses aarch64 that claims doesn't work, but actually works.
  nixpkgs.config.allowUnfree = true;

  # Disable the firewall since we're in a VM and we want to make it
  # easy to visit stuff in here. We only use NAT networking anyways.
  networking.firewall.enable = false;
}
