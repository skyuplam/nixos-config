{pkgs, ...}: {
  imports = [
    ./cad.nix
    ./doc.nix
    ./lua.nix
    ./nix.nix
    ./rust.nix
    ./web.nix
  ];
  home = {
    packages = with pkgs; [
      inotify-tools # File system event monitoring
    ];
  };
}
