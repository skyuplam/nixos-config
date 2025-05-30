# This function creates a NixOS system based on our VM setup for a
# particular architecture.
# from https://github.com/mitchellh/nixos-config/blob/main/lib/mksystem.nix
{
  nixpkgs,
  overlays,
  inputs,
}: name: {
  system,
  user,
  darwin ? false,
  wsl ? false,
}: let
  # True if this is a WSL system.
  isWSL = wsl;

  # The config files for this system.
  machineConfig = ../machines/${name}.nix;
  userOSConfig =
    ../users/${user}/${
      if darwin
      then "darwin"
      else "nixos"
    }.nix;
  userHMConfig = ../users/${user}/home-manager.nix;

  # NixOS vs nix-darwin functionst
  systemFunc =
    if darwin
    then inputs.darwin.lib.darwinSystem
    else nixpkgs.lib.nixosSystem;
  home-manager =
    if darwin
    then inputs.home-manager.darwinModules
    else inputs.home-manager.nixosModules;
in
  systemFunc rec {
    inherit system;

    modules = [
      # Apply our overlays. Overlays are keyed by system type so we have
      # to go through and apply our system type. We do this first so
      # the overlays are available globally.
      {nixpkgs.overlays = overlays;}

      (
        if !darwin && !isWSL
        then inputs.disko.nixosModules.disko
        else {}
      )
      (
        if !darwin && !wsl
        then inputs.sops-nix.nixosModules.sops
        else if darwin
        then inputs.sops-nix.darwinModules.sops
        else {}
      )
      (
        if !darwin && !isWSL
        then inputs.lanzaboote.nixosModules.lanzaboote
        else {}
      )
      (
        if !darwin && !isWSL
        then inputs.nix-ld.nixosModules.nix-ld
        else {}
      )

      machineConfig
      userOSConfig
      home-manager.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.${user} = import userHMConfig {
            inherit isWSL;
            inherit inputs;
          };
        };
      }

      # We expose some extra arguments so that our modules can parameterize
      # better based on these values.
      {
        config._module.args = {
          currentSystem = system;
          currentSystemName = name;
          currentSystemUser = user;
          inherit isWSL;
          inherit inputs;
        };
      }
    ];
  }
