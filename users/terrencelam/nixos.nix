{ pkgs, inputs, ... }:

{
  # Add ~/.local/bin to PATH
  environment.localBinInPath = true;

  # Since we're using fish as our shell
  programs.zsh.enable = true;

  users.users.tlam = {
    isNormalUser = true;
    home = "/home/terrencelam";
    extraGroups = [ "docker" "wheel" ];
    shell = pkgs.zsh;
  };

  nixpkgs.overlays = import ../../lib/overlays.nix ++ [
    (import ./vim.nix { inherit inputs; })
  ];
}
