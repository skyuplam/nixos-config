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
  programs.fish = {
    shellInit = ''
      set -x PLAYWRIGHT_NODEJS_PATH ${nodejs}/bin/node
      set -x PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD 1
      set -x PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS true
      set -x PLAYWRIGHT_BROWSERS_PATH ${pkgs.playwright-driver.browsers}
    '';
  };
}
