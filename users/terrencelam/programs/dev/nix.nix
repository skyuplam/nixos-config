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
        lsp.servers = {
          nil_ls = {
            enable = true;
            settings.formatting.command = [
              (lib.getExe pkgs.alejandra)
            ];
          };
          statix = {
            enable = true;
          };
        };

        hmts.enable = true;

        conform-nvim = {
          settings = {
            formatters_by_ft = {
              nix = ["alejandra"];
            };
          };
        };
      };
    };
  };
}
