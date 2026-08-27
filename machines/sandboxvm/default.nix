{inputs, ...}: {
  imports = [
    inputs.microvm.nixosModules.host
    ./network.nix
    ./pi-agent.nix
  ];
}
