{...}: {
  imports = [
    ./hardware/amd-wb.nix
    ./disko-config-wb.nix
    ./linux-shared.nix
  ];
  boot.loader.systemd-boot.enable = true;
  # boot.initrd.luks.devices = {
  #   crypted = {
  #     device = "/dev/disk/by-partlabel/luks";
  #     allowDiscards = true;
  #     bypassWorkqueues = true;
  #   };
  # };
  # Enable autoScrub for btrfs
  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
    fileSystems = ["/"];
  };

  services.libinput.enable = true;

  networking = {
    hostName = "tlamwb";
    networkmanager.enable = true;
    enableIPv6 = true;
  };

  # Enable in-memory compressed devices and swap space provided by the zram kernel module.
  # See https://www.kernel.org/doc/Documentation/blockdev/zram.txt .
  zramSwap = {
    enable = true;
    # one of "lzo", "lz4", "zstd"
    algorithm = "zstd";
    priority = 5;
    memoryPercent = 50;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
