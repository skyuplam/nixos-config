{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./doc.nix
    ./lua.nix
    ./nix.nix
    ./web.nix
  ];
}
