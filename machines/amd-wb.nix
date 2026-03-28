{config, ...}: {
  imports = [
    ./hardware/amd-wb.nix
    ./disko-config-wb.nix
    ./linux-shared.nix
  ];
  boot.loader.systemd-boot.enable = true;
  # Enable autoScrub for btrfs
  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
    fileSystems = ["/"];
  };

  services.libinput.enable = true;
  # Closing the lid
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandleLidSwitchExternalPower = "lock";
    HandleLidSwitchDocked = "ignore";
  };
  services.power-profiles-daemon.enable = false;
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 20;

      CPU_BOOST_ON_BAT = 0;
      CPU_SCALING_GOVERNOR_ON_BATTERY = "powersave";

      #Optional helps save long term battery health
      START_CHARGE_THRESH_BAT0 = 40; # 40 and below it starts to charge
      STOP_CHARGE_THRESH_BAT0 = 80; # 80 and above it stops charging
      RUNTIME_PM_ON_BAT = "auto";
    };
  };

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

  # From https://github.com/NixOS/nixos-hardware/pull/1676
  # Add Tuxedo InfinityBook Pro 14 Gen 10 hardware specifics
  # Add Motorcomm YT6801 Driver if available
  boot.extraModulePackages = with config.boot; [
    (
      if (kernelPackages ? yt6801)
      then kernelPackages.yt6801
      else null
    )
    # Enables the zenpower sensor in lieu of the k10temp sensor on Zen CPUs https://git.exozy.me/a/zenpower3
    # On Zen CPUs zenpower produces much more data entries
    # Refs. https://github.com/cguentherTUChemnitz/nixos-hardware/blob/6cdf1d899c48f7a9f16bf422b93a56271f473ea4/common/cpu/amd/zenpower.nix
    kernelPackages.zenpower
  ];

  boot.blacklistedKernelModules = ["k10temp"];
  # Enables the amd cpu scaling https://www.kernel.org/doc/html/latest/admin-guide/pm/amd-pstate.html
  # On recent AMD CPUs this can be more energy efficient.
  boot.kernelModules = ["zenpower"];
  boot.kernelParams = ["amd_pstate=active"];

  # https://wiki.nixos.org/wiki/Power_Management
  # swapon -s
  boot.resumeDevice = "/persist/swap/swapfile";

  systemd.sleep.settings.Sleep = {
    HibernateDelaySec = "1h";
  };

  powerManagement.enable = true;

  hardware = {
    tuxedo-drivers = {
      enable = true;
    };
    tuxedo-rs.enable = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?
}
