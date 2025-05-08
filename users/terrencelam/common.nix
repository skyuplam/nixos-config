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
}
