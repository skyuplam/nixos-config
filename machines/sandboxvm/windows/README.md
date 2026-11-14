# Windows sandbox VM

**Status: draft, never booted.** This evaluates on the NixOS host but has
not been tested end to end with a real Windows guest. The steps marked
**verify** are the likely failure points.

The host side is `../windows-guest.nix`. It runs Cloud Hypervisor directly
under systemd because microvm.nix only builds NixOS guests. It reuses the
bridge, the egress-only nftables policy (`../network.nix`) and the pinned SSH
host key staging (`../host-keys.nix`) from the Linux agent VM.

| Linux agent (`microvm@<name>`)       | Windows agent (`sandboxvm-<id>`)                        |
|--------------------------------------|---------------------------------------------------------|
| NixOS closure built by Nix           | Hand-prepared golden image (`golden.raw`)               |
| `/var`, `/work`, store overlay reset | Whole disk is a fresh reflink copy on every start       |
| Reset also on guest reboot           | **Not** reset on guest reboot; restart the unit instead |
| virtiofs `/input`, `~/.pi`           | virtiofs drives `I:` and `P:` (WinFsp + viofs)          |
| sshd host key from read-only share   | Same, copied in by a boot task, share then unmounted    |

## 1. nix-secrets

Add a `sandboxvmWindows` attribute next to `sandboxvm`:

```nix
sandboxvmWindows = {
  name = "win-agent";            # hostname for ssh / known_hosts
  id = "win-agent";              # [a-z][a-z0-9-]{0,20}; unit and user names
  tap = "win-tap0";
  mac = "02:00:00:00:83:03";
  guestAddress = "192.168.83.3"; # inside sandboxvm.subnet
  vcpu = 4;
  memoryMiB = 8192;
  inputDir = "/home/<user>/sandbox/win-input";
  piDir = "/home/<user>/sandbox/win-pi"; # NOT the Linux VM's piDir
  sshHostPublicKey = "ssh-ed25519 AAAA... win-agent";
  # optional:
  # goldenImage = "/var/lib/sandboxvm/win-agent/golden.raw";
  # maxPhysBits = 39;
};
```

Then add the host private key to `secrets.yaml` as `<id>-ssh-host-key`
(e.g. `win-agent-ssh-host-key`). Generate a fresh ed25519 key for it and do
not reuse the Linux VM's key. The module refuses to evaluate with duplicate
taps, MACs, addresses, piDirs or host keys.

## 2. Build the golden image (once, with QEMU)

Cloud Hypervisor has no VGA, so install with QEMU and boot with CH only
afterwards (see [CH docs/windows.md]). Use a UEFI install, a raw image and
virtio disk/net. Windows Server 2025 or Windows 11 IoT Enterprise LTSC do
not need a TPM. Windows 11 Pro/Enterprise does, and this module does not
wire up swtpm.

```sh
# after switching to a config with sandboxvmWindows set, which creates the
# sandboxvm-win-agent user and /var/lib/sandboxvm/win-agent
sudo qemu-img create -f raw /var/lib/sandboxvm/win-agent/golden.raw 64G
OVMF=$(nix build --no-link --print-out-paths nixpkgs#OVMF.fd)/FV/OVMF.fd
sudo qemu-system-x86_64 -machine q35,accel=kvm -cpu host -smp 4 -m 8G \
  -bios "$OVMF" \
  -drive if=none,id=root,format=raw,file=/var/lib/sandboxvm/win-agent/golden.raw \
  -device virtio-blk-pci,drive=root,disable-legacy=on \
  -cdrom Win.iso -drive file=virtio-win.iso,media=cdrom,index=3 \
  -device virtio-net-pci,netdev=n0,disable-legacy=on,mac=02:00:00:00:83:03 \
  -netdev user,id=n0 -vga std
```

Load `viostor` from the virtio-win ISO during setup. Once Windows is
installed:

1. Install the virtio-win guest tools (NetKVM, viostor, viofs, VirtIO-FS
   service), [WinFsp] ("Core"), Git for Windows, Node.js LTS and pi
   (`npm install -g ...`). Download them from their official publishers and
   check signatures.
2. Copy `provision.ps1` into the guest and run it in an elevated PowerShell:

   ```powershell
   .\provision.ps1 -GuestAddress 192.168.83.3 -PrefixLength 24 `
     -HostAddress 192.168.83.1 -MacAddress 02:00:00:00:83:03 `
     -AgentAuthorizedKey 'ssh-ed25519 AAAA... you@host' `
     -PinnedHostPublicKey 'ssh-ed25519 AAAA... win-agent' `
     -HostOwnerUid 1000 -HostOwnerGid 100
   ```

   `HostOwnerUid/Gid` set the host owner of files the guest creates in
   `inputDir`/`piDir`. Use your host user's uid/gid.
3. Activate/license Windows. Don't put a product key in any Nix file,
   because the store is world-readable.
4. Shut down (not reboot), then lock the image down:

   ```sh
   sudo chown root:root /var/lib/sandboxvm/win-agent/golden.raw
   sudo chmod 0400 /var/lib/sandboxvm/win-agent/golden.raw
   ```

The image must stay on the same btrfs/XFS filesystem as
`/var/lib/sandboxvm`. Each start uses `cp --reflink=always` and fails
rather than doing a full copy.

To update the image, boot a copy with QEMU, change it, shut it down and
replace `golden.raw` atomically.

## 3. Use

```sh
sudo systemctl start sandboxvm-win-agent
ssh agent@win-agent          # host key is pinned; any mismatch is fatal
sudo systemctl stop sandboxvm-win-agent   # ACPI shutdown, disk discarded
```

Serial console (SAC, for when SSH does not come up):

```sh
sudo socat -,raw,echo=0 UNIX-CONNECT:/run/sandboxvm-win-agent/serial.sock
```

The guest boot task logs to `C:\ProgramData\sandboxvm\boot.log`. On any
failure it leaves sshd stopped.

## Verify first

- **CH and Windows virtiofs.** viofs is documented for QEMU/libvirt. CH
  exposes the same vhost-user-fs device, but this combination is untested.
- **Reading the host key over virtiofs.** The staged key is `0400 root` on
  the host. If the guest cannot read `K:\ssh_host_ed25519_key`, the boot
  task fails closed. Check how viofs maps the owner. Do not loosen the
  host-side mode without re-checking who in the guest can read the share
  before it is unmounted.
- **virtiofsd hardening.** The units add systemd sandboxing on top of
  virtiofsd's own namespace sandbox. If virtiofsd fails to start, check the
  journal before relaxing anything.
- **`max_phys_bits`.** CH's docs say Windows may need `39` on hosts with
  wider physical address spaces.

## Known limitations

- A guest-initiated reboot keeps the disk. Only restarting the unit
  restores the golden image. On Server SKUs only Administrators can reboot.
- No TPM and no display. RDP is not enabled, and SSH forwarding is
  disabled in the provided sshd_config.
- Anything in the golden image (installed tools, cached credentials) is in
  every session. Never sign in to personal accounts while preparing it.

[CH docs/windows.md]: https://github.com/cloud-hypervisor/cloud-hypervisor/blob/main/docs/windows.md
[WinFsp]: https://winfsp.dev/
