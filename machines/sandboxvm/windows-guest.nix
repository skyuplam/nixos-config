# Windows guests of the sandbox: Cloud Hypervisor run directly by systemd.
#
# microvm.nix only builds NixOS guests, so this module replicates the parts
# of it that the Linux agent VM relies on: a host-created tap device,
# virtiofsd daemons, a disposable disk and a hardened hypervisor unit.
#
# Per VM <id>, `systemctl start sandboxvm-<id>` pulls in:
#   <id>-ssh-host-key                 stage the pinned host key (host-keys.nix)
#   sandboxvm-<id>-tap                create the tap device, owned by the VM user
#   sandboxvm-<id>-disk               fresh reflink copy of the golden image
#   sandboxvm-<id>-virtiofsd-<share>  one virtiofsd per share
#
# Guest-side setup (drivers, OpenSSH, virtiofs mounts) is in ./windows/.
{
  config,
  lib,
  pkgs,
  utils,
  ...
}: let
  cfg = config.sandboxvm;
  windowsVms = lib.filterAttrs (_: vm: vm.os == "windows") cfg.vms;

  stateRoot = "/var/lib/sandboxvm";

  # Guest-visible virtiofs tags; ./windows/provision.ps1 mounts these.
  sharesFor = vm: [
    {
      name = "hostkey";
      tag = "sandbox-hostkey";
      source = "/run/${vm.id}-ssh-host-key";
      readOnly = true;
      cache = "never";
    }
    {
      name = "input";
      tag = "sandbox-input";
      source = vm.inputDir;
      readOnly = false;
      cache = "auto";
    }
    {
      name = "pi";
      tag = "sandbox-pi";
      source = vm.piDir;
      readOnly = true;
      cache = "never";
    }
    {
      name = "gcloud";
      tag = "sandbox-gcloud";
      source = vm.gcloudDir;
      readOnly = true;
      cache = "never";
    }
  ];

  # Systemd hardening shared by the per-VM helper units.
  commonHardening = {
    NoNewPrivileges = true;
    PrivateTmp = true;
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectKernelLogs = true;
    ProtectControlGroups = true;
    ProtectClock = true;
    ProtectHostname = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    LockPersonality = true;
    SystemCallArchitectures = "native";
  };

  mkUnits = name: vm: let
    user = "sandboxvm-${vm.id}";
    stateDir = "${stateRoot}/${vm.id}";
    runDir = "/run/sandboxvm-${vm.id}";
    disk = "${stateDir}/disk.raw";
    apiSocket = "${runDir}/api.sock";
    serialSocket = "${runDir}/serial.sock";
    shares = sharesFor vm;
    unit = suffix: "sandboxvm-${vm.id}${suffix}";
    shareUnit = share: unit "-virtiofsd-${share.name}";
    shareSocket = share: "${runDir}/virtiofs-${share.name}.sock";
    helperUnits =
      [
        "${unit "-tap"}.service"
        "${unit "-disk"}.service"
      ]
      ++ map (share: "${shareUnit share}.service") shares;

    ch = pkgs.cloud-hypervisor;
    ip = lib.getExe' pkgs.iproute2 "ip";

    chArgs =
      [
        "--api-socket"
        "path=${apiSocket}"
        "--firmware"
        pkgs.OVMF-cloud-hypervisor.firmware
        "--cpus"
        ("boot=${toString vm.vcpu},kvm_hyperv=on"
          + lib.optionalString (vm.windows.maxPhysBits != null) ",max_phys_bits=${toString vm.windows.maxPhysBits}")
        "--memory"
        # Shared memory is required by vhost-user (virtiofs).
        "size=${toString vm.memoryMiB}M,shared=on"
        "--disk"
        "path=${disk},image_type=raw"
        "--net"
        "tap=${vm.tap},mac=${lib.toLower vm.mac}"
        # Windows Special Administration Console (SAC); see windows/README.md.
        "--serial"
        "socket=${serialSocket}"
        "--console"
        "off"
        "--seccomp"
        "true"
        "--fs"
      ]
      ++ map (share: "tag=${share.tag},socket=${shareSocket share}") shares;
  in
    {
      "${unit "-tap"}" = {
        description = "Tap interface for sandbox VM ${name}";
        partOf = ["${unit ""}.service"];
        restartIfChanged = false;
        serviceConfig =
          commonHardening
          // {
            Type = "oneshot";
            RemainAfterExit = true;
            CapabilityBoundingSet = "CAP_NET_ADMIN";
            # `ip tuntap` uses /dev/net/tun ioctls; `ip link` uses netlink.
            DeviceAllow = ["/dev/net/tun rw"];
            RestrictAddressFamilies = "AF_NETLINK AF_UNIX AF_INET";
            ProtectSystem = "strict";
            ProtectHome = true;
            ExecStop = "${ip} link delete ${vm.tap}";
          };
        # Single-queue tap (no multi_queue flag) to match the default
        # num_queues=2 of the --net argument. networkd enslaves it to the
        # bridge as an isolated port (network.nix).
        script = ''
          set -euo pipefail
          if [ -e /sys/class/net/${vm.tap} ]; then
            ${ip} link delete ${vm.tap}
          fi
          ${ip} tuntap add name ${vm.tap} mode tap user ${user} vnet_hdr
          ${ip} link set ${vm.tap} up
        '';
      };

      # Every boot starts from the pristine golden image. A guest-initiated
      # reboot is handled inside Cloud Hypervisor and does NOT reset the disk;
      # only restarting this unit does.
      "${unit "-disk"}" = {
        description = "Disposable disk for sandbox VM ${name}";
        partOf = ["${unit ""}.service"];
        restartIfChanged = false;
        path = [
          pkgs.coreutils
          pkgs.findutils
        ];
        serviceConfig =
          commonHardening
          // {
            Type = "oneshot";
            RemainAfterExit = true;
            UMask = "0077";
            # Root owns the state dir and the golden image; it only needs to
            # hand the copy to the VM user.
            CapabilityBoundingSet = "CAP_CHOWN";
            PrivateNetwork = true;
            RestrictAddressFamilies = "AF_UNIX";
            ProtectSystem = "strict";
            ProtectHome = true;
            ReadWritePaths = [stateDir];
            # Discard the session's disk on stop so nothing it wrote lingers.
            ExecStop = "${pkgs.coreutils}/bin/rm -f ${disk}";
          };
        script = ''
          set -euo pipefail
          golden=${lib.escapeShellArg vm.windows.goldenImage}
          tmp=${disk}.tmp
          trap 'rm -f "$tmp"' EXIT

          # Fail closed unless the golden image is a regular, root-owned file
          # that nobody else can modify.
          if [ ! -f "$golden" ] || [ -L "$golden" ]; then
            echo "golden image $golden missing or not a regular file" >&2
            exit 1
          fi
          if [ "$(stat -c %u "$golden")" != 0 ] || [ -n "$(find "$golden" -perm /022)" ]; then
            echo "golden image $golden must be root-owned and not group/world-writable" >&2
            exit 1
          fi

          rm -f ${disk} "$tmp"
          # reflink=always: refuse a full copy of a multi-GB image if the
          # filesystem cannot share extents.
          cp --reflink=always "$golden" "$tmp"
          chmod 0600 "$tmp"
          chown ${user}:${user} "$tmp"
          mv -f "$tmp" ${disk}
        '';
      };
    }
    // lib.listToAttrs (map (share:
      lib.nameValuePair (shareUnit share) {
        description = "virtiofsd (${share.name}) for sandbox VM ${name}";
        partOf = ["${unit ""}.service"];
        restartIfChanged = false;
        serviceConfig =
          commonHardening
          // {
            Type = "simple";
            # virtiofsd sets per-request fsuid/fsgid, so it runs as root;
            # it confines itself further with its own namespace sandbox.
            ExecStartPre = "${pkgs.coreutils}/bin/rm -f ${shareSocket share}";
            ExecStart = utils.escapeSystemdExecArgs ([
                (lib.getExe pkgs.virtiofsd)
                "--socket-path=${shareSocket share}"
                "--socket-group=${user}"
                "--shared-dir=${share.source}"
                "--cache=${share.cache}"
                "--sandbox=namespace"
                "--rlimit-nofile=1048576"
              ]
              ++ lib.optional share.readOnly "--readonly");
            # Cloud Hypervisor fails if a vhost-user socket is missing, so
            # only report ready once it exists, and make it connectable by
            # the VM user's group only.
            ExecStartPost = pkgs.writeShellScript "wait-${shareUnit share}" ''
              set -eu
              for _ in $(seq 100); do
                if [ -S ${shareSocket share} ]; then
                  chgrp ${user} ${shareSocket share}
                  chmod 0660 ${shareSocket share}
                  exit 0
                fi
                sleep 0.1
              done
              echo "virtiofsd socket ${shareSocket share} did not appear" >&2
              exit 1
            '';
            Restart = "on-failure";
            LimitNOFILE = 1048576;
            PrivateNetwork = true;
            RestrictAddressFamilies = "AF_UNIX";
            ProtectSystem = "strict";
            ProtectHome = "read-only";
            ReadWritePaths = [runDir] ++ lib.optional (!share.readOnly) share.source;
          };
        path = [pkgs.coreutils];
      })
    shares)
    // {
      "${unit ""}" = {
        description = "Sandbox VM ${name} (Windows, Cloud Hypervisor)";
        # Not started at boot; start explicitly like microvm@<name>.
        requires = helperUnits;
        after = helperUnits ++ ["network.target"];
        # Do not restart an active session merely because the host config
        # changed.
        restartIfChanged = false;
        serviceConfig =
          commonHardening
          // {
            Type = "simple";
            User = user;
            Group = user;
            SupplementaryGroups = ["kvm"];
            UMask = "0077";
            ExecStart = utils.escapeSystemdExecArgs ([(lib.getExe ch)] ++ chArgs);
            # ACPI power button: Windows shuts down cleanly. systemd kills
            # the hypervisor if that does not finish within TimeoutStopSec.
            ExecStop = pkgs.writeShellScript "stop-${unit ""}" ''
              ${ch}/bin/ch-remote --api-socket ${apiSocket} power-button
              ${pkgs.util-linux}/bin/waitpid "$MAINPID"
            '';
            TimeoutStopSec = "90s";
            Restart = "no";

            CapabilityBoundingSet = "";
            AmbientCapabilities = "";
            DevicePolicy = "closed";
            DeviceAllow = [
              "/dev/kvm rw"
              "/dev/net/tun rw"
            ];
            ProtectSystem = "strict";
            ProtectHome = true;
            ReadWritePaths = [
              runDir
              stateDir
            ];
            RestrictNamespaces = true;
            # AF_INET/AF_INET6: ioctl sockets for tap configuration.
            RestrictAddressFamilies = "AF_UNIX AF_INET AF_INET6 AF_NETLINK";
          };
      };
    };
in {
  assertions =
    lib.mapAttrsToList (name: vm: {
      assertion = !(lib.hasPrefix "/nix/store" vm.windows.goldenImage);
      message = "sandboxvm: golden image of ${name} must not be in the Nix store.";
    })
    windowsVms;

  users = lib.mkMerge (lib.mapAttrsToList (_: vm: {
      users."sandboxvm-${vm.id}" = {
        isSystemUser = true;
        group = "sandboxvm-${vm.id}";
        description = "Cloud Hypervisor for sandbox VM ${vm.id}";
      };
      groups."sandboxvm-${vm.id}" = {};
    })
    windowsVms);

  systemd.tmpfiles.rules = lib.optionals (windowsVms != {}) (
    ["d ${stateRoot} 0755 root root -"]
    ++ lib.concatLists (lib.mapAttrsToList (_: vm: [
        # Root-owned: only the disk unit writes here. The VM user may only
        # traverse it to open its own disk.raw.
        "d ${stateRoot}/${vm.id} 0710 root sandboxvm-${vm.id} -"
        # API, serial and vhost-user sockets.
        "d /run/sandboxvm-${vm.id} 0750 sandboxvm-${vm.id} sandboxvm-${vm.id} -"
      ])
      windowsVms)
  );

  systemd.services = lib.mkMerge (lib.mapAttrsToList mkUnits windowsVms);
}
