{
  pkgs,
  lib,
  ...
}: {
  programs = {
    nixvim = {
      plugins = {
        render-markdown = {
          enable = true;
        };
        lsp.servers = {
          marksman = {
            enable = true;
            settings.formatting.command = [
              (lib.getExe pkgs.marksman)
            ];
          };
        };

        hmts.enable = true;

        conform-nvim = {
          settings = {
            formatters_by_ft = {
              markdown = ["prettier"];
            };
          };
        };
      };
    };
  };
}
