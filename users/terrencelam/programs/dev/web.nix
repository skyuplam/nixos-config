{pkgs, ...}: let
  nodejs = pkgs.stable.nodejs_18;
  yarn = pkgs.yarn.override {inherit nodejs;};
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
