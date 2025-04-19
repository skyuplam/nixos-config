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
}
