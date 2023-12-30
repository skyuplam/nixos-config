{
  pkgs,
  inputs,
  ...
}: {
  # Add ~/.local/bin to PATH
  environment.localBinInPath = true;

  # Since we're using fish as our shell
  programs.zsh.enable = true;

  users.users.terrencelam = {
    isNormalUser = true;
    home = "/home/terrencelam";
    group = "terrencelam";
    extraGroups = ["docker" "wheel" "video"];
    shell = pkgs.zsh;
  };
}
