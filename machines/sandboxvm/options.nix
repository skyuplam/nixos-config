{lib, ...}: let
  inherit (lib) mkOption types;

  # Allowlist formats for values that end up in unit names, interface
  # names, nftables rules, shell scripts and hypervisor arguments. These
  # come from nix-secrets, so validate them rather than trusting them.
  # Max 21 chars so derived names such as the `sandboxvm-<id>` system user
  # stay within Linux's 32-character user-name limit.
  idType = types.strMatching "[a-z][a-z0-9-]{0,20}";
  secretNameType = types.strMatching "[A-Za-z0-9][A-Za-z0-9._-]{0,63}";
  ifNameType = types.strMatching "[a-zA-Z][a-zA-Z0-9_-]{0,14}";
  macType = types.strMatching "([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}";
  ipv4Type = types.strMatching "((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])";
  cidrType = types.strMatching "((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])/([0-9]|[12][0-9]|3[0-2])";
  # Absolute path without `..` segments, whitespace or shell/systemd
  # metacharacters.
  absPathType =
    types.addCheck (types.strMatching "(/[A-Za-z0-9._-]+)+")
    (p: !(lib.any (s: s == "." || s == "..") (lib.splitString "/" p)));
  ed25519PubType = types.strMatching "ssh-ed25519 [A-Za-z0-9+/=]+( .*)?";

  vmModule = {
    name,
    config,
    ...
  }: {
    options = {
      os = mkOption {
        type = types.enum [
          "nixos"
          "windows"
        ];
        description = "Guest operating system. Selects the backend module.";
      };

      id = mkOption {
        type = idType;
        default = name;
        description = ''
          Short identifier used in host unit, secret, user and runtime
          directory names. Kept separate from the VM name so existing
          unit and secret names stay stable.
        '';
      };

      tap = mkOption {
        type = ifNameType;
        description = "Host tap interface for the guest (enslaved to the sandbox bridge).";
      };

      mac = mkOption {
        type = macType;
        description = "Guest MAC address. Enforced on the bridge port.";
      };

      guestAddress = mkOption {
        type = ipv4Type;
        description = "Static guest IPv4 address. Enforced on the bridge port.";
      };

      vcpu = mkOption {type = types.ints.between 1 64;};

      memoryMiB = mkOption {type = types.ints.between 512 262144;};

      sshHostPublicKey = mkOption {
        type = ed25519PubType;
        description = "Pinned guest SSH host public key.";
      };

      sshHostKeySecret = mkOption {
        type = secretNameType;
        default = "${config.id}-ssh-host-key";
        description = "sops secret holding the matching guest SSH host private key.";
      };

      inputDir = mkOption {
        type = absPathType;
        description = "Host directory shared read-write with the guest as the work input.";
      };

      piDir = mkOption {
        type = absPathType;
        description = ''
          Host directory holding pi's configuration and credentials,
          shared read-write with the guest. Use a separate directory per
          VM: concurrent writers from different guests are not supported.
        '';
      };

      nixos = {
        authorizedKey = mkOption {
          type = types.nullOr types.str;
          default = null;
        };
        agentUid = mkOption {
          type = types.nullOr types.ints.positive;
          default = null;
        };
        agentGid = mkOption {
          type = types.nullOr types.ints.positive;
          default = null;
        };
        vsockCid = mkOption {
          type = types.nullOr (types.ints.between 3 4294967294);
          default = null;
        };
        varDiskMiB = mkOption {
          type = types.nullOr types.ints.positive;
          default = null;
        };
        workDiskMiB = mkOption {
          type = types.nullOr types.ints.positive;
          default = null;
        };
        nixStoreMiB = mkOption {
          type = types.nullOr types.ints.positive;
          default = null;
        };
      };

      windows = {
        goldenImage = mkOption {
          type = absPathType;
          default = "/var/lib/sandboxvm/${config.id}/golden.raw";
          description = ''
            Prepared raw Windows disk image (see windows/README.md). It is
            never written to: every start makes a fresh reflink copy, so
            it must live on the same btrfs/XFS filesystem as
            /var/lib/sandboxvm. Keep it root-owned and mode 0400. Never
            put it in the Nix store (non-redistributable, world-readable).
          '';
        };

        maxPhysBits = mkOption {
          type = types.nullOr (types.ints.between 36 52);
          default = null;
          description = ''
            Limit the guest physical address width. Cloud Hypervisor's
            Windows docs note this may be needed (e.g. 39) on hosts with a
            wider address space.
          '';
        };
      };
    };
  };
in {
  options.sandboxvm = {
    network = {
      bridge = mkOption {type = ifNameType;};
      subnet = mkOption {type = cidrType;};
      hostAddress = mkOption {type = ipv4Type;};
      prefixLength = mkOption {type = types.ints.between 8 30;};
      egressInterface = mkOption {type = ifNameType;};
    };

    vms = mkOption {
      type = types.attrsOf (types.submodule vmModule);
      default = {};
      description = "Sandbox VMs. All share one isolated bridge with egress-only Internet access.";
    };
  };
}
