# Stable, pinned SSH host identities for every sandbox VM.
#
# Each guest's private host key is held in sops (nix-secrets/secrets.yaml);
# the matching public key is pinned in nix-secrets and in the host's
# known_hosts. The key is staged into a root-only tmpfs directory that is
# exported to the guest read-only via virtiofs.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.sandboxvm;

  # Unit that serves the staged key to the guest; staging must finish first.
  consumerUnit = name: vm:
    if vm.os == "nixos"
    then "microvm-virtiofsd@${name}.service"
    else "sandboxvm-${vm.id}-virtiofsd-hostkey.service";
in {
  sops.secrets = lib.mapAttrs' (_: vm:
    lib.nameValuePair vm.sshHostKeySecret {
      owner = "root";
      group = "root";
      mode = "0400";
      restartUnits = ["${vm.id}-ssh-host-key.service"];
    })
  cfg.vms;

  # Pin each guest's host key system-wide so SSH never needs TOFU and any
  # change is reported as a hard failure instead of being silently accepted.
  programs.ssh.knownHosts =
    lib.mapAttrs (name: vm: {
      hostNames = [
        name
        vm.guestAddress
      ];
      publicKey = vm.sshHostPublicKey;
    })
    cfg.vms;

  # Stage exactly one file (the guest host key) in a root-only tmpfs
  # directory that is exported to the guest read-only. A copy is needed
  # because sops-nix paths are symlinks into /run/secrets.d, which would not
  # resolve inside the guest, and exporting /run/secrets.d would leak every
  # other host secret.
  systemd.services = lib.mapAttrs' (name: vm: let
    runtimeDir = "${vm.id}-ssh-host-key";
    keyFile = "ssh_host_ed25519_key";
  in
    lib.nameValuePair "${vm.id}-ssh-host-key" {
      description = "Stage SSH host key for ${
        if vm.os == "nixos"
        then "MicroVM"
        else "sandbox VM"
      } ${name}";
      requiredBy = [(consumerUnit name vm)];
      before = [(consumerUnit name vm)];
      after = ["sops-install-secrets.service"];
      path = [
        pkgs.coreutils
        pkgs.openssh
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        UMask = "0077";
        RuntimeDirectory = runtimeDir;
        RuntimeDirectoryMode = "0700";
        # virtiofsd holds the directory open; do not delete it underneath it.
        RuntimeDirectoryPreserve = "yes";

        CapabilityBoundingSet = "";
        NoNewPrivileges = true;
        PrivateNetwork = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = "AF_UNIX";
        SystemCallArchitectures = "native";
      };
      script = ''
        set -euo pipefail
        dest="$RUNTIME_DIRECTORY/${keyFile}"
        tmp="$dest.tmp"
        trap 'rm -f "$tmp"' EXIT

        install -m 0400 ${lib.escapeShellArg config.sops.secrets.${vm.sshHostKeySecret}.path} "$tmp"

        # Fail closed unless the secret is a valid key that matches the
        # public key pinned in known_hosts.
        derived="$(ssh-keygen -y -f "$tmp" | cut -d' ' -f1,2)"
        expected="$(printf '%s\n' ${lib.escapeShellArg vm.sshHostPublicKey} | cut -d' ' -f1,2)"
        if [ "$derived" != "$expected" ]; then
          echo "${vm.id} SSH host key does not match pinned public key" >&2
          exit 1
        fi

        mv -f "$tmp" "$dest"
      '';
    })
  cfg.vms;
}
