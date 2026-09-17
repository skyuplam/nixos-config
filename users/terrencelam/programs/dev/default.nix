{
  pkgs,
  lib,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) isLinux;
in {
  imports = [
    ./cad.nix
    ./doc.nix
    ./lua.nix
    ./nix.nix
    ./rust.nix
    ./web.nix
  ];

  home = {
    packages = with pkgs;
      [just-lsp]
      ++ (lib.optionals isLinux [
        inotify-tools # File system event monitoring
        devenv
        typos-lsp
      ]);
  };
}
