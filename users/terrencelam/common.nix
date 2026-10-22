{inputs, ...}: let
  secretspath = builtins.toString inputs.nix-secrets;
in {
  sops = {
    defaultSopsFile = "${secretspath}/secrets.yaml";
    age = {
      sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
      keyFile = "/var/lib/sops-nix/key.txt";
      generateKey = true;
    };
  };

  # CVE-2026-111943 | eMudhra Intermediate CA Compromise
  # Ref. https://github.com/NixOS/nixpkgs/issues/576485
  security.pki.caCertificateBlacklist = [
    # CVE-2026-111943
    "Comodo AAA Services root"
    # https://hg-edge.mozilla.org/projects/nss/rev/26d38a0c3fb81e7fb2acedbaf4c42dd21dce0517
    "emSign ECC Root CA - G3"
    # https://hg-edge.mozilla.org/projects/nss/rev/8159223c48ceeb1273a1915bca95a517294ab0e0
    "emSign Root CA - C1"
    "emSign ECC Root CA - C3"
  ];
}
