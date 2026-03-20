{}: {
  imports = [
    ./disko-config-wb.nix
    ./linux-shared.nix
  ];

  networking = {
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
