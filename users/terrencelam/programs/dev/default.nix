{
  pkgs,
  lib,
  ...
}: let
  inherit (pkgs.stdenv) isLinux;
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
      []
      ++ (lib.optionals isLinux [
        inotify-tools # File system event monitoring
        zmx
      ]);
  };
}
