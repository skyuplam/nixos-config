{
  pkgs,
  lib,
  ...
}: let
  nodejs = pkgs.nodejs_18;
  yarn = pkgs.yarn.override {inherit nodejs;};
  prettier = {
    __raw = ''
      function(bufnr)
        if require("conform").get_formatter_info("prettier", bufnr).available then
          return { "prettier" }
        else
          return { "biome" }
        end
      end
    '';
  };
in {
  home = {
    packages = with pkgs; [
      nodejs
      yarn
      biome # toolchain for the web
      nodePackages.typescript-language-server
      nodePackages.yaml-language-server
      vscode-langservers-extracted
    ];
  };
}
