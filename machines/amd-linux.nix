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

  environment = {
    systemPackages = [pkgs.sbctl];
  };

  boot = {
    loader.systemd-boot.enable = lib.mkForce false;
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
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
}
