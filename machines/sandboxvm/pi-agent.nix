{inputs, ...}: let
  settings = inputs.nix-secrets.sandboxvm;

  guestPkgs = import inputs.nixpkgs {
    system = "x86_64-linux";

    overlays = [
      inputs.microvm.overlay
    ];
  };
in {
  microvm.vms.${settings.name} = {
    pkgs = guestPkgs;
    autostart = false;

    # Do not automatically restart an active coding session merely because
    # the host configuration changed.
    restartIfChanged = false;

    config = {
      config,
      pkgs,
      ...
    }: {
      networking = {
        hostName = settings.name;
        useDHCP = false;
        useNetworkd = true;
        enableIPv6 = false;

        nameservers = [
          "1.1.1.1"
          "9.9.9.9"
        ];

        firewall = {
          enable = true;
          allowedTCPPorts = [22];
          allowPing = false;
        };
      };

      systemd.network = {
        enable = true;

        networks."10-pi-agent" = {
          matchConfig.MACAddress = settings.mac;

          address = [
            "${settings.guestAddress}/${toString settings.prefixLength}"
          ];

          routes = [
            {
              Destination = "0.0.0.0/0";
              Gateway = settings.hostAddress;
              GatewayOnLink = true;
            }
          ];

          networkConfig = {
            DHCP = "no";
            IPv6AcceptRA = false;
            LinkLocalAddressing = "no";
          };
        };
      };

      users = {
        mutableUsers = false;

        users = {
          agent = {
            isNormalUser = true;
            uid = 1000;
            group = "agent";
            home = "/home/agent";
            createHome = true;
            shell = pkgs.fish;

            openssh.authorizedKeys.keys = [
              settings.authorizedKey
            ];
          };

          root.openssh.authorizedKeys.keys = [settings.authorizedKey];
        };
        groups.agent.gid = 1000;
      };

      security.sudo.enable = false;

      programs.fish.enable = true;

      services.openssh = {
        enable = true;

        # Store host keys on the VM-local /var volume. They are not copied
        # from the physical host.
        hostKeys = [
          {
            path = "/var/lib/ssh/ssh_host_ed25519_key";
            type = "ed25519";
          }
        ];

        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = "no";
          AllowUsers = ["agent"];

          AllowAgentForwarding = false;
          AllowTcpForwarding = false;
          GatewayPorts = "no";
          X11Forwarding = false;
        };
      };

      environment = let
        nodejs = pkgs.nodejs_22;
        yarn = pkgs.yarn.override {inherit nodejs;};
      in {
        systemPackages = with pkgs; [
          pi-coding-agent
          git
          ripgrep
          fd
          jq
          curl
          cacert
          coreutils
          gnutar
          gzip
          gnumake
          nodejs
          yarn
          neovim
        ];

        variables = {
          PI_TELEMETRY = "0";
          PI_SKIP_VERSION_CHECK = "1";
          EDITOR = "nvim";
          VISUAL = "nvim";
        };
      };

      # The account home, including Pi's sessions and configuration, vanishes
      # whenever the VM stops. Do not place long-lived API credentials here.
      fileSystems."/home/agent" = {
        device = "tmpfs";
        fsType = "tmpfs";
        options = [
          "mode=0700"
          "uid=1000"
          "gid=1000"
          "nosuid"
          "nodev"
        ];
      };

      systemd.tmpfiles.rules = [
        "d /work/repo 0700 agent agent -"
        "d /var/lib/ssh 0700 root root -"
      ];

      systemd.settings.Manager.DefaultTimeoutStopSec = "10s";

      microvm = {
        hypervisor = "cloud-hypervisor";
        vcpu = settings.vcpu;
        mem = settings.memoryMiB;
        socket = "control.socket";
        vsock.cid = settings.vsockCid;

        interfaces = [
          {
            type = "tap";
            id = settings.tap;
            mac = settings.mac;
          }
        ];

        volumes = [
          {
            image = "var.img";
            mountPoint = "/var";
            size = settings.varDiskMiB;
            fsType = "ext4";
          }
          {
            image = "work.img";
            mountPoint = "/work";
            size = settings.workDiskMiB;
            fsType = "ext4";
          }
        ];

        shares = [
          {
            proto = "virtiofs";
            tag = "pi-input";
            source = settings.inputDir;
            mountPoint = "/input";
            readOnly = true;
            cache = "never";
          }
        ];

        # Because /nix/store is not shared from the host, microvm.nix builds a
        # store disk containing only the guest closure.
        storeOnDisk = true;
      };

      system.stateVersion = "26.05";
    };
  };
}
