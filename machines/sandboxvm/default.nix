{inputs, ...}: {
  imports = [
    inputs.microvm.nixosModules.host
    ./network.nix
    ./nixos-guest.nix
  ];
}
