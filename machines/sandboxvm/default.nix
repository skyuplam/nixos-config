{
  config,
  inputs,
  lib,
  ...
}: let
  cfg = config.sandboxvm;

  # Existing Linux (NixOS) agent VM. Its id stays "pi-agent" so the sops
  # secret, staging unit and guest disk serials keep their current names.
  linux = inputs.nix-secrets.sandboxvm;

  # Optional Windows agent VM. Absent from nix-secrets until a golden image
  # exists; see ./windows/README.md for the expected attributes.
  windows = inputs.nix-secrets.sandboxvmWindows or null;

  vmList = lib.attrValues cfg.vms;
  allUnique = values: lib.length values == lib.length (lib.unique values);
in {
  imports = [
    inputs.microvm.nixosModules.host
    ./host-keys.nix
    ./network.nix
    ./nixos-guest.nix
    ./options.nix
    ./windows-guest.nix
  ];

  sandboxvm = {
    network = {
      inherit (linux) bridge subnet hostAddress prefixLength egressInterface;
    };

    vms =
      {
        ${linux.name} = {
          os = "nixos";
          id = "pi-agent";
          sshHostKeySecret = "pi-agent-ssh-host-key";
          inherit (linux) tap mac guestAddress vcpu memoryMiB sshHostPublicKey inputDir piDir;
          nixos = {
            inherit (linux) authorizedKey agentUid agentGid vsockCid varDiskMiB workDiskMiB nixStoreMiB;
          };
        };
      }
      // lib.optionalAttrs (windows != null) {
        ${windows.name} = {
          os = "windows";
          inherit (windows) id tap mac guestAddress vcpu memoryMiB sshHostPublicKey inputDir piDir;
          windows =
            lib.optionalAttrs (windows ? goldenImage) {inherit (windows) goldenImage;}
            // lib.optionalAttrs (windows ? maxPhysBits) {inherit (windows) maxPhysBits;};
        };
      };
  };

  assertions =
    [
      {
        assertion = lib.all (name: builtins.match "[a-z][a-z0-9-]{0,62}" name != null) (lib.attrNames cfg.vms);
        message = "sandboxvm: VM names must be lowercase hostnames.";
      }
      {
        assertion = allUnique (map (vm: vm.id) vmList);
        message = "sandboxvm: VM ids must be unique.";
      }
      {
        assertion = allUnique (map (vm: vm.tap) vmList);
        message = "sandboxvm: tap interfaces must be unique.";
      }
      {
        assertion = allUnique (map (vm: lib.toLower vm.mac) vmList);
        message = "sandboxvm: MAC addresses must be unique.";
      }
      {
        assertion = allUnique (map (vm: vm.guestAddress) vmList);
        message = "sandboxvm: guest addresses must be unique.";
      }
      {
        assertion = lib.all (vm: vm.guestAddress != cfg.network.hostAddress) vmList;
        message = "sandboxvm: a guest address equals the host bridge address.";
      }
      {
        assertion = allUnique (map (vm: vm.piDir) vmList);
        message = "sandboxvm: each VM needs its own piDir (concurrent pi writers are unsupported).";
      }
      {
        assertion = allUnique (map (vm: vm.sshHostPublicKey) vmList);
        message = "sandboxvm: each VM needs its own SSH host key.";
      }
    ]
    ++ map (vm: {
      assertion = vm.tap != cfg.network.bridge && vm.tap != cfg.network.egressInterface;
      message = "sandboxvm: tap ${vm.tap} collides with the bridge or egress interface.";
    })
    vmList;
}
