{
  inputs,
  lib,
  ...
}: let
  settings = inputs.nix-secrets.sandboxvm;
in {
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  systemd.network = {
    netdevs."20-${settings.bridge}".netdevConfig = {
      Kind = "bridge";
      Name = settings.bridge;
    };

    networks = {
      "20-${settings.bridge}" = {
        matchConfig.Name = settings.bridge;

        address = [
          "${settings.hostAddress}/${toString settings.prefixLength}"
        ];

        routingPolicyRules = [
          {
            From = settings.subnet;
            Table = 254;
            Priority = 8;
          }
        ];

        networkConfig = {
          ConfigureWithoutCarrier = true;
          IPv4Forwarding = true;
          IPv6AcceptRA = false;
          LinkLocalAddressing = "no";
        };

        linkConfig.RequiredForOnline = "no";
      };

      "21-${settings.tap}" = {
        matchConfig.Name = settings.tap;

        networkConfig = {
          Bridge = settings.bridge;
          LinkLocalAddressing = "no";
        };

        linkConfig.RequiredForOnline = "no";
      };
    };
  };

  # The microvm host module also creates share directories. Creating this
  # one first keeps it under the host user's control rather than making it
  # a general writable workspace.
  systemd.tmpfiles.settings."05-pi-agent-microvm" = {
    "${settings.inputDir}".d = {
      user = "terrencelam";
      group = "kvm";
      mode = "0750";
    };
  };

  networking = {
    nftables.enable = true;

    firewall = {
      enable = true;
      backend = "nftables";
      filterForward = true;

      # Preserve the host's existing WireGuard-compatible behavior.
      checkReversePath = "loose";

      # Do not put pi-br0 here. A trusted interface would give the guest
      # broad access to services on the host.
      trustedInterfaces = lib.mkAfter [
        "virbr0"
      ];

      # The earlier pi-agent-isolation table blocks forbidden destinations.
      # Traffic is accepted here only if policy routing chose wg0.
      extraForwardRules = ''
        iifname "${settings.bridge}" \
          oifname "${settings.egressInterface}" \
          ip saddr ${settings.subnet} \
          counter accept \
          comment "Pi MicroVM to public Internet through designated uplink"
      '';
    };

    nftables.tables = {
      # This table runs before the normal NixOS firewall input/forward chains.
      # Drop verdicts are final across later base chains.
      "pi-agent-isolation" = {
        family = "inet";
        content = ''
          set blocked_ipv4 {
            type ipv4_addr
            flags interval
            elements = {
              0.0.0.0/8,
              10.0.0.0/8,
              100.64.0.0/10,
              127.0.0.0/8,
              169.254.0.0/16,
              172.16.0.0/12,
              192.0.0.0/24,
              192.0.2.0/24,
              192.168.0.0/16,
              198.18.0.0/15,
              198.51.100.0/24,
              203.0.113.0/24,
              224.0.0.0/4,
              240.0.0.0/4
            }
          }

          chain input {
            type filter hook input priority -10; policy accept;

            # Permit replies to connections initiated by the host, notably
            # SSH from 192.168.83.1 to the guest.
            iifname "${settings.bridge}" \
              ct state { established, related } \
              accept

            # Reject all new guest-initiated connections to the host.
            iifname "${settings.bridge}" \
              counter drop \
              comment "Block Pi MicroVM access to host services"
          }

          chain forward {
            type filter hook forward priority -10; policy accept;

            iifname "${settings.bridge}" \
              ip saddr != ${settings.subnet} \
              counter drop \
              comment "Reject spoofed source from Pi bridge"

            iifname "${settings.bridge}" \
              ip daddr @blocked_ipv4 \
              counter drop \
              comment "Block Pi MicroVM access to private and reserved IPv4"

            iifname "${settings.bridge}" \
              oifname "${settings.bridge}" \
              counter drop \
              comment "Prevent Pi bridge lateral traffic"
          }
        '';
      };

      "pi-agent-nat" = {
        family = "ip";
        content = ''
          chain postrouting {
            type nat hook postrouting priority srcnat; policy accept;

            iifname "${settings.bridge}" \
              oifname "${settings.egressInterface}" \
              ip saddr ${settings.subnet} \
              masquerade \
              comment "NAT Pi MicroVM through designated uplink"
          }
        '';
      };
    };
  };
}
