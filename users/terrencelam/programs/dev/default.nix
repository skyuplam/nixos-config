{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./nix.nix
    ./web.nix
    ./rust.nix
    ./doc.nix
    ./lua.nix
  ];

  programs = {
    nixvim.plugins = {
      lsp.servers = {
        typos_lsp = {
          enable = true;
          cmd = [(lib.getExe pkgs.typos-lsp)];
        };
      };
    };
  };
}
