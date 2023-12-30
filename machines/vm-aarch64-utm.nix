{ config, pkgs, modulesPath, ... }: {
  imports = [
    ./hardware/vm-aarch64-utm.nix
    ./linux-shared.nix
    ./disko-config-utm.nix
  ];

  # Define your hostname.
  networking.hostName = "dev";

  # Interface is this on my M2
  networking.interfaces.enp0s10.useDHCP = true;

  # Qemu
  services.spice-vdagentd.enable = true;

  # For now, we need this since hardware acceleration does not work.
  # environment.variables.LIBGL_ALWAYS_SOFTWARE = "1";

  # Lots of stuff that uses aarch64 that claims doesn't work, but actually works.
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;

  # Disable the firewall since we're in a VM and we want to make it
  # easy to visit stuff in here. We only use NAT networking anyways.
  networking.firewall.enable = false;
}
