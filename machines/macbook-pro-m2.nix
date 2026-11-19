{pkgs, ...}: {
  imports = [./tart-host.nix];

  # Give Tart's VirtioFS shares more headroom in the host-wide file table.
  launchd.daemons.set-maxfiles.serviceConfig = {
    ProgramArguments = ["/usr/sbin/sysctl" "kern.maxfiles=32768"];
    RunAtLoad = true;
  };

  # We install Nix using a separate installer so we don't want nix-darwin
  # to manage it for us. This tells nix-darwin to just use whatever is running.
  # nix.useDaemon = true;
  nix.enable = false;

  # use flakes
  nix.channel.enable = false;

  # Keep in async with vm-shared.nix. (todo: pull this out into a file)
  nix = {
    # We need to enable flakes
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
  };

  nixpkgs.config.allowUnfree = true;
}
