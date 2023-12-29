# NixOS System Configurations

This repository contains a collection of NixOS system configurations.

## Setup macOS with [nix-darwin](https://github.com/LnL7/nix-darwin)

- Build the config
```sh
nix build ./\#darwinConfigurations.macbook-pro-m2.system
```
- Switch to the new setup
```sh
./result/sw/bin/darwin-rebuild switch --flake ./\#macbook-pro-m2
```
