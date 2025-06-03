{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./doc.nix
    ./lua.nix
    ./nix.nix
    ./rust.nix
    ./web.nix
  ];
}
