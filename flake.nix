{
  description = "Tlam's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    wgsl-analyzer = {
      url = "github:wgsl-analyzer/wgsl-analyzer";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
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
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # firefox-nightly = {
    #   url = "github:nix-community/flake-firefox-nightly";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # A wayland native krunner-like runner, made with customizability in mind.
    anyrun = {
      url = "github:Kirottu/anyrun";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nil = {
      url = "github:oxalica/nil";
    };
    # FIXME: https://github.com/NixOS/nix/issues/12281
    nix-secrets = {
      url = "git+file:./../nix-secrets?shadow=1&ref=main";
      inputs = {};
    };
    nix-ld = {
      url = "github:Mic92/nix-ld";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    nixpkgs,
    nixpkgs-stable,
    zls,
    ...
  }: let
    overlays = [
      # inputs.neovim-nightly-overlay.overlays.default
      inputs.zig.overlays.default
      (_final: _prev: {inherit zls;})
      (_final: prev: {stable = import nixpkgs-stable {inherit (prev) system;};})
      # (_final: prev: {inherit (inputs.firefox-nightly.packages.${prev.system}) firefox-nightly-bin;})
      (_final: prev: {wgsl-analyzer = inputs.wgsl-analyzer.packages.${prev.system}.default;})
      (_final: prev: {nil = inputs.nil.packages.${prev.system}.default;})
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
        "https://anyrun.cachix.org"
      ];
      extra-trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs"
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "anyrun.cachix.org-1:pqBobmOjI7nKlsUMV25u9QHa9btJK65/C8vnO3p346s="
      ];
    };

    nixosConfigurations.vm-aarch64-utm = mkSystem "vm-aarch64-utm" {
      system = "aarch64-linux";
      user = "terrencelam";
    };

    nixosConfigurations.amd-linux = mkSystem "amd-linux" {
      system = "x86_64-linux";
      user = "terrencelam";
    };

    nixosConfigurations.amd-ws = mkSystem "amd-ws" {
      system = "x86_64-linux";
      user = "terrencelam";
    };

    darwinConfigurations.macbook-pro-m2 = mkSystem "macbook-pro-m2" {
      system = "aarch64-darwin";
      user = "terrencelam";
      darwin = true;
    };
  };
}
