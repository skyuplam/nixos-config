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

  networking = {
    hostname = "tlamwb";
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
}
