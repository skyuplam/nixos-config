{
  pkgs,
  lib,
  ...
}: {
  home = {
    packages = with pkgs; [
      alejandra
      statix
      nil
    ];
  };

  programs = {
    nixvim = {
      plugins = {
        rustaceanvim = {
          enable = true;
        };
      };
    };
  };
}
