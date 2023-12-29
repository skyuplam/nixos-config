{
  description = "Tlam's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    zig.url = "github:mitchellh/zig-overlay";
    zls.url = "github:zigtools/zls";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    nixpkgs,
    home-manager,
    zls,
    ...
  }: let
    overlays = [
      inputs.neovim-nightly-overlay.overlay
      inputs.zig.overlays.default
      (_final: _prev: {inherit zls;})
    ];
    mkSystem = import ./lib/mksystem.nix {
      inherit overlays nixpkgs inputs;
    };
  in {
    nixosConfigurations.vm-aarch64-utm = mkSystem "vm-aarch64-utm" rec {
      system = "aarch64-linux";
      user = "terrencelam";
    };

    darwinConfigurations.macbook-pro-m2 = mkSystem "macbook-pro-m2" {
      system = "aarch64-darwin";
      user = "terrencelam";
      darwin = true;
    };
  };
}
