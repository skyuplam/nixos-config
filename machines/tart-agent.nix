# nix-darwin configuration for the macOS agent VM ("golden image") that runs
# under Tart on the MacBook. It mirrors the guest side of
# machines/sandboxvm/nixos-guest.nix as closely as macOS allows.
#
# Setup and deployment: machines/tart-agent.md. In short, on the MacBook:
#   tart-agent-deploy <vm> "$(nix build --no-link --print-out-paths \
#     .#darwinConfigurations.tart-agent.system)"
{
  inputs,
  lib,
  pkgs,
  ...
}: let
  settings = inputs.nix-secrets.tartAgent;

  nodejs = pkgs.nodejs_22;
  yarn = pkgs.yarn.override {inherit nodejs;};

  # Tart mounts every --dir share under this directory in macOS guests.
  shareRoot = "/Volumes/My Shared Files";
in {
  nixpkgs = {
    hostPlatform = "aarch64-darwin";
    overlays = [
      (_final: prev: {pi = inputs.pi-agent.packages.${prev.stdenv.hostPlatform.system}.default;})
    ];
  };

  # Determinate Nix manages the daemon and nix.conf in the guest.
  nix.enable = false;

  system = {
    stateVersion = 6;
    # Admin account created in Setup Assistant; owns nix-darwin activation.
    primaryUser = settings.adminUser;
  };

  networking = {
    hostName = "tart-agent";
    computerName = "tart-agent";
    localHostName = "tart-agent";
  };

  users = {
    knownUsers = ["agent"];

    users = {
      # Standard (non-admin), hidden account used by the coding agent.
      agent = {
        uid = settings.agentUid;
        gid = 20; # staff
        home = "/Users/agent";
        createHome = true;
        isHidden = true;
        shell = pkgs.fish;
        description = "Sandbox coding agent";
        openssh.authorizedKeys.keys = [settings.authorizedKey];
      };

      # Maintenance only (nix copy + activation). Use a key that never
      # enters the VM; the agent cannot read it or become admin.
      ${settings.adminUser}.openssh.authorizedKeys.keys = [settings.adminAuthorizedKey];
    };
  };

  services.openssh = {
    enable = true;
    # Only the ed25519 key; it is pinned on the host (HostKeyAlias tart-agent)
    # and shared by every clone of the golden image.
    hostKeys = [
      {
        type = "ed25519";
        path = "/etc/ssh/ssh_host_ed25519_key";
      }
    ];
  };

  environment.etc = {
    # sshd uses the first value it reads and includes sshd_config.d/* in
    # lexical order, so this file must sort before macOS's 100-macos.conf
    # and nix-darwin's 100-/101- files to take precedence.
    "ssh/sshd_config.d/050-sandbox.conf".text = ''
      AuthenticationMethods publickey
      PubkeyAuthentication yes
      PasswordAuthentication no
      KbdInteractiveAuthentication no
      PermitRootLogin no
      AllowUsers agent ${settings.adminUser}
      # Only the nix-darwin managed keys (AuthorizedKeysCommand); the agent
      # cannot add its own ~/.ssh/authorized_keys.
      AuthorizedKeysFile none

      AllowAgentForwarding no
      AllowTcpForwarding no
      AllowStreamLocalForwarding no
      GatewayPorts no
      PermitTunnel no
      X11Forwarding no
      PermitUserEnvironment no
    '';
  };

  system.activationScripts.postActivation.text = ''
    # Fail closed if the agent account was ever made an administrator.
    if /usr/sbin/dseditgroup -o checkmember -m agent admin >/dev/null 2>&1; then
      echo "error: user 'agent' must not be in the admin group" >&2
      exit 1
    fi

    # sysadminctl creates the account without a password. Set a random one
    # that is never stored, so only SSH public-key login remains. (It is
    # briefly visible in the VM's process list to root/admin only.)
    /usr/bin/dscl . -passwd /Users/agent "$(/usr/bin/openssl rand -base64 33)"

    # pmset works over SSH; nix-darwin's power.sleep uses systemsetup, which
    # needs Full Disk Access there.
    /usr/bin/pmset -a sleep 0 displaysleep 0 disksleep 0
  '';

  programs.fish.enable = true;
  environment.shells = [pkgs.fish];

  programs.tmux = {
    enable = true;
    enableMouse = true;
    extraConfig = ''
      set -g default-terminal "tmux-256color"
      set -g extended-keys on
      set -g extended-keys-format csi-u
      setw -g aggressive-resize on
      set -s set-clipboard on

      bind s split-window -h -c "#{pane_current_path}"
      bind v split-window -v -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"
    '';
  };

  environment = {
    systemPackages = with pkgs; [
      biome
      cacert
      coreutils
      curl
      fd
      gh
      ghostty-bin.terminfo # xterm-ghostty for SSH sessions
      git
      gnumake
      gnutar
      gzip
      jq
      neovim
      nodejs
      pi
      ripgrep
      yarn
      zoxide
    ];

    variables = {
      PI_TELEMETRY = "0";
      PI_SKIP_VERSION_CHECK = "1";
      # The persistent pi config share (`tart run --dir=pi:...`).
      PI_CODING_AGENT_DIR = "${shareRoot}/pi/agent";
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };

  # Keep the VM predictable: no idle sleep (would drop SSH sessions) and no
  # automatic macOS updates (the golden image is updated deliberately).
  system.defaults.SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false;

  assertions = [
    {
      assertion = lib.hasPrefix "ssh-ed25519 " settings.authorizedKey;
      message = "tartAgent.authorizedKey must be an ssh-ed25519 public key.";
    }
    {
      assertion = settings.authorizedKey != settings.adminAuthorizedKey;
      message = "tartAgent: use different keys for the agent and admin accounts.";
    }
  ];
}
