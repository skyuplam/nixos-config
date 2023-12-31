{
  pkgs,
  config,
  ...
}: {
  # Add ~/.local/bin to PATH
  environment.localBinInPath = true;

  # Since we're using fish as our shell
  programs.zsh.enable = true;

  users.groups.terrencelam = {};

  users.users.terrencelam = {
    isNormalUser = true;
    home = "/home/terrencelam";
    group = "terrencelam";
    extraGroups = ["docker" "wheel" "video"];
    shell = pkgs.zsh;
    hashedPasswordFile = config.sops.secrets.hashedPassword.path;

    openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIi4mBqMk32PKYVGFJZBXqM+b6vw8b3J0pSFBGAQm3ps TlamM2"];
  };
}
