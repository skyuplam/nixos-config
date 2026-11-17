# Host side of the Tart agent sandbox on the MacBook (nix-darwin).
#
#   * Tart with Softnet network isolation on PATH.
#   * Passwordless sudo for exactly the Softnet binary, which it needs to
#     create the vmnet interface (it drops to the calling user afterwards).
#     Without this, Tart would try to set the SUID bit on a /nix/store file.
#   * The VM's SSH host key pinned under the alias "tart-agent", plus a
#     helper that connects to a VM's current DHCP address with that pin.
{
  currentSystemUser,
  inputs,
  lib,
  pkgs,
  ...
}: let
  settings = inputs.nix-secrets.tartAgent or {};
  hostPublicKey = settings.sshHostPublicKey or null;
  adminUser = settings.adminUser or "admin";
  # Interpolated into shell scripts below; allowlist it.
  validAdminUser =
    lib.assertMsg (builtins.match "[a-z_][a-z0-9_-]{0,31}" adminUser != null)
    "tartAgent.adminUser must be a plain macOS short name";

  tart = pkgs.tart.override {enableSoftnet = true;};
  softnet = lib.getExe' pkgs.softnet "softnet";

  # Copy a built darwinConfigurations.tart-agent system into a running VM
  # and activate it, like `darwin-rebuild switch` on the guest.
  tartAgentDeploy = assert validAdminUser;
    pkgs.writeShellApplication {
      name = "tart-agent-deploy";
      runtimeInputs = [tart pkgs.openssh];
      text = ''
        if [ $# -ne 2 ]; then
          echo "usage: tart-agent-deploy <vm> <darwin-system store path>" >&2
          # shellcheck disable=SC2016 # literal example, not meant to expand
          echo '  e.g. tart-agent-deploy tahoe-vanilla "$(nix build --no-link --print-out-paths .#darwinConfigurations.tart-agent.system)"' >&2
          exit 2
        fi
        vm=$1
        sys=$2
        [[ $vm =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$ ]] || { echo "invalid VM name" >&2; exit 2; }
        [[ $sys =~ ^/nix/store/[a-z0-9]{32}-darwin-system-[A-Za-z0-9._+-]+$ ]] || { echo "not a darwin-system store path" >&2; exit 2; }
        [ -x "$sys/activate" ] || { echo "$sys/activate missing; build it first" >&2; exit 1; }

        ip=$(tart ip --wait 60 "$vm")
        [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || { echo "could not resolve IPv4 of $vm" >&2; exit 1; }

        ssh_opts=(
          -o HostKeyAlias=tart-agent
          -o StrictHostKeyChecking=yes
          -o UserKnownHostsFile=/dev/null
          -o UpdateHostKeys=no
          -o CheckHostIP=no
          -o ForwardAgent=no
          -o ClearAllForwardings=yes
        )
        identity="$HOME/.ssh/tart_${adminUser}_ed25519"
        if [ -f "$identity" ]; then
          ssh_opts+=(-i "$identity" -o IdentitiesOnly=yes)
        fi

        # Requires `trusted-users = root ${adminUser}` in the guest's Nix config.
        NIX_SSHOPTS="''${ssh_opts[*]}" nix copy --to "ssh-ng://${adminUser}@$ip" "$sys"
        ssh -t "''${ssh_opts[@]}" -- "${adminUser}@$ip" \
          "sudo nix-env -p /nix/var/nix/profiles/system --set $sys && sudo $sys/activate"
      '';
    };

  tartAgentSsh = pkgs.writeShellApplication {
    name = "tart-agent-ssh";
    runtimeInputs = [tart pkgs.openssh];
    text = ''
      usage() {
        echo "usage: tart-agent-ssh <vm> [user] [-- remote command...]" >&2
        exit 2
      }
      [ $# -ge 1 ] || usage
      vm=$1
      shift
      user=agent
      if [ $# -ge 1 ] && [ "$1" != "--" ]; then
        user=$1
        shift
      fi
      [ $# -ge 1 ] && [ "$1" = "--" ] && shift

      [[ $vm =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$ ]] || { echo "invalid VM name" >&2; exit 2; }
      [[ $user =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] || { echo "invalid user name" >&2; exit 2; }

      opts=()
      # Per-account key (~/.ssh/tart_<user>_ed25519), never the agent's key for admin.
      identity="$HOME/.ssh/tart_''${user}_ed25519"
      if [ -f "$identity" ]; then
        opts+=(-i "$identity" -o IdentitiesOnly=yes)
      fi
      # Allocate a TTY for interactive remote commands (e.g. sudo prompts).
      if [ -t 0 ]; then
        opts+=(-t)
      fi

      ip=$(tart ip --wait 60 "$vm")
      [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || { echo "could not resolve IPv4 of $vm" >&2; exit 1; }

      # Every clone shares the golden image's host key, pinned system-wide
      # as "tart-agent". Never fall back to trust-on-first-use.
      exec ssh \
        -o HostKeyAlias=tart-agent \
        -o StrictHostKeyChecking=yes \
        -o UserKnownHostsFile=/dev/null \
        -o UpdateHostKeys=no \
        -o CheckHostIP=no \
        -o ForwardAgent=no \
        -o ClearAllForwardings=yes \
        "''${opts[@]}" \
        -- "$user@$ip" "$@"
    '';
  };
in {
  environment.systemPackages = [
    tart
    tartAgentDeploy
    tartAgentSsh
  ];

  security.sudo.extraConfig = ''
    ${currentSystemUser} ALL=(root) NOPASSWD: ${softnet}
  '';

  programs.ssh.knownHosts = lib.mkIf (hostPublicKey != null) {
    tart-agent = {
      hostNames = ["tart-agent"];
      publicKey = hostPublicKey;
    };
  };
}
