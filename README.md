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

## Setup a VM with NixOS on a macOS with UTM

1. Download the Minimal ISO image from the official https://nixos.org/download#nixos-iso
   e.g. [64-bit ARM](https://channels.nixos.org/nixos-23.11/latest-nixos-minimal-aarch64-linux.iso)
2. Create a new VM with UTM and setting the OS to Linux as well as applying the ISO image to boot
3. Once the VM is booted, copy the [disko config file](./machines/disko-config-utm.nix)

```sh
curl -o /tmp/disko-config.nix https://raw.githubusercontent.com/skyuplam/nixos-config/main/machines/disko-config-utm.nix
```

4. Run disko to partition, format and mount the disks

```sh
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko /tmp/disko-config.nix
```

5. Complete the NixOS installation

- Generate initial nixos config

```sh
sudo nixos-generate-config --no-filesystems --root /mnt
```

- Move the disko config to /mnt/etc/nixos

```sh
sudo mv /tmp/disko-config.nix /mnt/etc/nixos
```

- Update the nixos configurations to include the disko module and the disko config

```nix
imports =
 [ # Include the results of the hardware scan.
   ./hardware-configuration.nix
   "${builtins.fetchTarball "https://github.com/nix-community/disko/archive/master.tar.gz"}/module.nix"
   ./disko-config.nix
 ];
```

6. Finish the installation and reboot

```sh
sudo nixos-install
sudo reboot
```
