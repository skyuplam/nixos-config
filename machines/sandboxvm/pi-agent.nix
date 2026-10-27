{inputs, ...}: let
  settings = inputs.nix-secrets.sandboxvm;

  guestPkgs = import inputs.nixpkgs {
    system = "x86_64-linux";

    overlays = [
      inputs.microvm.overlay
      (final: _prev: let
        callPlaywrightPackage = package: args: let
          drv = final.callPackage package args;
        in
          if final.stdenv.hostPlatform.isLinux && builtins.baseNameOf (toString package) == "webkit.nix"
          then
            drv.overrideAttrs (oldAttrs: {
              # Playwright 1.63's WPE MiniBrowser gained this dependency, but
              # playwright-web-flake does not include it yet.
              buildInputs = (oldAttrs.buildInputs or []) ++ [final.libmanette];
            })
          else drv;
        playwrightPackages = final.callPackage (inputs.playwright.outPath + "/playwright-driver/driver.nix") {
          callPackage = callPlaywrightPackage;
        };
      in {
        playwright-test = playwrightPackages.playwright-test;
        playwright-driver = playwrightPackages.playwright-core;
      })
      (_final: prev: {pi = inputs.pi-agent.packages.${prev.stdenv.hostPlatform.system}.default;})
    ];
  };

  nodejs = guestPkgs.nodejs_22;
  yarn = guestPkgs.yarn.override {inherit nodejs;};
in {
  microvm.vms.${settings.name} = {
    pkgs = guestPkgs;
    autostart = false;

    # Do not automatically restart an active coding session merely because
    # the host configuration changed.
    restartIfChanged = false;

    config = {
      config,
      lib,
      pkgs,
      utils,
      ...
    }: let
      disposableVolumes = [
        {
          image = "var.img";
          serial = "pi-agent-var";
          mountPoint = "/var";
          size = settings.varDiskMiB;
          fsType = "ext4";
        }
        {
          image = "work.img";
          serial = "pi-agent-work";
          mountPoint = "/work";
          size = settings.workDiskMiB;
          fsType = "ext4";
        }
        {
          image = "nix-store-overlay.img";
          serial = "pi-agent-nix";
          mountPoint = config.microvm.writableStoreOverlay;
          size = 32768;
          fsType = "ext4";
        }
      ];
      volumeDevice = volume: "/dev/disk/by-id/virtio-${volume.serial}";
      volumeDevices = map volumeDevice disposableVolumes;
      volumeDeviceUnits = map (device: "${utils.escapeSystemdPath device}.device") volumeDevices;
      mkfsExt4 = "${pkgs.e2fsprogs}/bin/mkfs.ext4";
    in {
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
            uid = settings.agentUid;
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
        groups.agent.gid = settings.agentGid;
      };

      security.sudo.enable = false;
      programs.nix-ld.enable = true;

      programs.fish = {
        enable = true;
        shellInit = ''
          set -x PLAYWRIGHT_NODEJS_PATH ${nodejs}/bin/node
          set -x PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD 1
          set -x PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS true
          set -x PLAYWRIGHT_BROWSERS_PATH ${pkgs.playwright-driver.browsers}
        '';
      };

      programs.tmux = {
        enable = true;
        plugins = with pkgs; [
          tmuxPlugins.catppuccin
          tmuxPlugins.cpu
        ];
        extraConfigBeforePlugins = ''
          # Options to make tmux more pleasant
          set -g mouse on
          set -g default-terminal "tmux-256color"
          # Enable extended keys
          set -g extended-keys on
          set -g extended-keys-format csi-u

          setw -g aggressive-resize on

          set -s set-clipboard on

          # Better pane splitting (and keep current path)
          bind s split-window -h -c "#{pane_current_path}"
          bind v split-window -v -c "#{pane_current_path}"
          bind c new-window -c "#{pane_current_path}"

          # Vim-style pane navigation
          bind h select-pane -L
          bind j select-pane -D
          bind k select-pane -U
          bind l select-pane -R

          # Vim-style pane resizing
          bind -r H resize-pane -L 5
          bind -r J resize-pane -D 5
          bind -r K resize-pane -U 5
          bind -r L resize-pane -R 5

          # Configure the catppuccin plugin
          set -g @catppuccin_flavor "mocha"
          set -g @catppuccin_window_status_style "rounded"
          set -g @catppuccin_status_background "none"
        '';
        extraConfig = ''
          # Make the status line pretty and add some modules
          set -g status-right-length 100
          set -g status-left-length 100
          set -g status-left ""
          set -g status-right "#{E:@catppuccin_status_application}"
          set -agF status-right "#{E:@catppuccin_status_cpu}"
          set -agF status-right "#{E:@catppuccin_status_ram}"
          set -ag status-right "#{E:@catppuccin_status_session}"
          set -ag status-right "#{E:@catppuccin_status_uptime}"
          #set -agF status-right "#{E:@catppuccin_status_battery}"
        '';
      };

      services.openssh = {
        enable = true;

        # Generate VM-local host keys on the disposable /var volume.
        # They change on every boot and are never copied from the host.
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

      environment = {
        systemPackages = with pkgs; [
          biome
          cacert
          coreutils
          curl
          fd
          git
          gnumake
          gnutar
          gzip
          jq
          nodejs
          pi
          ripgrep
          yarn
        ];

        variables = {
          PI_TELEMETRY = "0";
          PI_SKIP_VERSION_CHECK = "1";
          EDITOR = "nvim";
          VISUAL = "nvim";
        };
      };

      programs = {
        zoxide = {
          enable = true;
          enableFishIntegration = true;
        };

        neovim = {
          enable = true;
          defaultEditor = true;
        };
      };

      fileSystems =
        lib.listToAttrs (map (volume:
          lib.nameValuePair volume.mountPoint {
            # Mount by the same serial-based path the reset formats, rather
            # than MicroVM's positional /dev/vdX, so the two cannot diverge.
            device = lib.mkForce (volumeDevice volume);
            # Freshly formatted before mounting; do not race the reset
            # service with filesystem checks in the initrd.
            noCheck = true;
          })
        disposableVolumes)
        // {
          # The home is ephemeral EXCEPT for the host-backed .pi share below.
          # Pi's credentials, sessions and configuration in that share persist.
          "/home/agent" = {
            device = "tmpfs";
            fsType = "tmpfs";
            options = [
              "mode=0700"
              "uid=${toString settings.agentUid}"
              "gid=${toString settings.agentGid}"
              "nosuid"
              "nodev"
            ];
          };
        };

      boot.initrd.systemd = {
        # The initrd builder copies only listed paths (plus ELF libraries),
        # not tools a script merely names, so ship mkfs.ext4 explicitly.
        storePaths = [mkfsExt4];

        # Reset inside the initrd, not just in the host's preStart hook: a
        # guest-initiated reboot must also discard all VM-local filesystem
        # state. Serial-based paths keep the read-only store image out of
        # this list.
        services.reset-agent-volumes = {
          description = "Reset disposable Pi agent filesystems";
          requiredBy = ["sysroot.mount"];
          before = ["sysroot.mount"];
          requires = volumeDeviceUnits;
          after = volumeDeviceUnits;
          unitConfig.DefaultDependencies = false;
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script =
            lib.concatMapStringsSep "\n" (device: ''
              ${mkfsExt4} -F ${lib.escapeShellArg device}
            '')
            volumeDevices;
        };
      };

      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

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

        # Ship only the guest's closure, never the physical host's /nix/store.
        # Newly built/downloaded paths live in the disposable overlay.
        storeOnDisk = true;
        writableStoreOverlay = "/nix/.rw-store";

        interfaces = [
          {
            type = "tap";
            id = settings.tap;
            mac = settings.mac;
          }
        ];

        volumes = disposableVolumes;

        shares = [
          {
            proto = "virtiofs";
            tag = "pi-input";
            source = settings.inputDir;
            mountPoint = "/input";
            readOnly = false;
            # libgit2 (used by Nix flakes) mmaps Git pack indexes. With
            # cache = "never", virtiofs rejects mmap with ENODEV, which
            # libgit2 reports as missing Git objects.
            cache = "auto";
          }
          {
            proto = "virtiofs";
            tag = "pi-config";
            source = settings.piDir;
            mountPoint = "/home/agent/.pi";
            readOnly = false;
            cache = "never";
          }
        ];
      };

      system.stateVersion = "26.05";
    };
  };
}
