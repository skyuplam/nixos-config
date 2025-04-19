{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./nix.nix
    ./web.nix
    ./rust.nix
    ./lua.nix
  ];
}
