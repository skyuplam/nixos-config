{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware/amd-ws.nix
    ./linux-shared.nix
    ./disko-config-ws.nix
  ];

  environment = {
    systemPackages = [pkgs.sbctl];
  };

  boot = {
    # This is not a complete NixOS configuration and you need to reference
    # your normal configuration here.
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    initrd.systemd.enable = true;
  };

  fonts = {
    # use fonts specified by user rather than default ones
    enableDefaultPackages = false;
    fontDir.enable = true;

    packages = with pkgs; [
      # icon fonts
      dejavu_fonts
      font-awesome
      material-design-icons
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
      noto-fonts-emoji
      source-han-sans
      source-han-serif
      source-sans
      source-serif
    ];
    # user defined fonts
    # the reason there's Noto Color Emoji everywhere is to override DejaVu's
    # B&W emojis that would sometimes show instead of some Color emojis
    fontconfig.defaultFonts = {
      serif = ["Source Han Serif TC" "Noto Color Emoji"];
      sansSerif = ["Source Han Sans TC" "Noto Color Emoji"];
      monospace = ["JetBrainsMono Nerd Font" "Noto Color Emoji"];
      emoji = ["Noto Color Emoji"];
    };
  };

  networking.hostName = "tlamws";
  networking.firewall = {
    allowedUDPPorts = [inputs.nix-secrets.networking.wireguard.wg0.listenPort];
  };
}
