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

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    nixpkgs,
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
    # Bainary cache hint in Flakes https://nixos.wiki/wiki/Binary_Cache#Binary_cache_hint_in_Flakes
    nixConfig = {
      extra-substituters = [
        "https://nix-community.cachix.org"
        "https://hyprland.cachix.org"
      ];
      extra-trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs"
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
    };

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
