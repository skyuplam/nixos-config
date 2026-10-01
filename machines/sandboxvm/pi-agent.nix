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

      programs.fish.enable = true;

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
          pi-coding-agent
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

      # The account home, including Pi's sessions and configuration, vanishes
      # whenever the VM stops. Do not place long-lived API credentials here.
      fileSystems."/home/agent" = {
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

        writableStoreOverlay = "/nix/.rw-store";

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
          {
            image = "nix-store-overlay.img";
            mountPoint = config.microvm.writableStoreOverlay;
            size = 32768;
          }
        ];

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
          {
            proto = "virtiofs";
            tag = "rw-store";
            source = "/nix/store";
            mountPoint = "/nix/.ro-store";
          }
        ];
      };

      system.stateVersion = "26.05";
    };
  };
}
