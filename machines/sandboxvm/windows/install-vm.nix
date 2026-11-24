# `sandboxvm-win-install`: QEMU install environment for a Windows golden image
# that needs TPM 2.0 and Secure Boot (Windows 11 Pro/Enterprise).
#
# It runs as your own user. You don't need root or X11 access for root, only
# read/write access to /dev/kvm (kvm group). It builds the image in a
# directory you own. You then install it as golden.raw (windows/README.md).
#
# Per image it keeps two files next to it:
#   <image>.vars.fd  UEFI variable store (copy of the Microsoft-enrolled
#                    OVMF_VARS.ms.fd, so Secure Boot is on from first boot)
#   <image>.tpm/     swtpm TPM 2.0 state
# Cloud Hypervisor uses neither of them later.
{pkgs}: let
  ovmf = pkgs.OVMFFull.fd;
in
  pkgs.writeShellApplication {
    name = "sandboxvm-win-install";
    runtimeInputs = [pkgs.qemu_kvm pkgs.swtpm pkgs.coreutils];
    # SC2054: QEMU option values contain commas by design.
    excludeShellChecks = ["SC2054"];
    text = ''
      usage() {
        cat >&2 <<'EOF'
      usage: sandboxvm-win-install --image FILE [--iso WIN.iso --virtio-iso VIRTIO.iso]
                                   [--size 64G] [--cpus 4] [--mem 8G]
                                   [--mac AA:BB:CC:DD:EE:FF] [--clipboard]

        --image       raw disk image to create or reuse (must not exist under /nix/store)
        --iso         Windows installer ISO (omit after setup to boot from disk)
        --virtio-iso  virtio-win driver ISO
        --size        size when creating the image (default 64G)
        --mac         MAC address for the virtio NIC (colon-separated hex; match
                      sandboxvmWindows.mac when running provision.ps1)
        --clipboard   enable QEMU vdagent clipboard sharing (requires spice-guest-tools
                      or virtio-win-guest-tools with vioserial + vdagent in the guest)
      EOF
        exit 2
      }

      image="" iso="" virtio="" size="64G" cpus="4" mem="8G" mac="" clipboard=0
      while [ $# -gt 0 ]; do
        case "$1" in
          --image) image="''${2:?}"; shift 2 ;;
          --iso) iso="''${2:?}"; shift 2 ;;
          --virtio-iso) virtio="''${2:?}"; shift 2 ;;
          --size) size="''${2:?}"; shift 2 ;;
          --cpus) cpus="''${2:?}"; shift 2 ;;
          --mem) mem="''${2:?}"; shift 2 ;;
          --mac) mac="''${2:?}"; shift 2 ;;
          --clipboard) clipboard=1; shift ;;
          -h|--help) usage ;;
          *) echo "unknown argument: $1" >&2; usage ;;
        esac
      done

      [ -n "$image" ] || usage
      [[ "$size" =~ ^[0-9]+[GT]$ ]] || { echo "bad --size: $size" >&2; exit 2; }
      [[ "$cpus" =~ ^[0-9]{1,3}$ ]] || { echo "bad --cpus: $cpus" >&2; exit 2; }
      [[ "$mem" =~ ^[0-9]+[MG]$ ]] || { echo "bad --mem: $mem" >&2; exit 2; }
      if [ -n "$mac" ]; then
        [[ "$mac" =~ ^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$ ]] || { echo "bad --mac: $mac" >&2; exit 2; }
        if (( (16#''${mac%%:*} & 1) != 0 )); then
          echo "bad --mac (must be unicast): $mac" >&2; exit 2
        fi
        mac="''${mac,,}"
      fi
      for f in "$image" "$iso" "$virtio"; do
        # QEMU splits -drive options on commas.
        case "$f" in *,*) echo "path must not contain a comma: $f" >&2; exit 2 ;; esac
      done
      for f in "$iso" "$virtio"; do
        if [ -n "$f" ] && [ ! -r "$f" ]; then
          echo "cannot read $f" >&2; exit 1
        fi
      done

      if [ "$(id -u)" -eq 0 ]; then
        echo "run this as your user, not root (it only needs the kvm group)" >&2
        exit 1
      fi
      if [ ! -r /dev/kvm ] || [ ! -w /dev/kvm ]; then
        echo "no access to /dev/kvm: add your user to the kvm group and log in again" >&2
        exit 1
      fi

      image="$(realpath -m -- "$image")"
      case "$image" in
        /nix/store/*|/var/lib/sandboxvm/*)
          echo "build the image in a directory you own, then install it as golden.raw" >&2
          exit 1 ;;
      esac

      umask 077
      mkdir -p -- "$(dirname -- "$image")"
      if [ ! -e "$image" ]; then
        qemu-img create -f raw -- "$image" "$size"
      fi
      vars="$image.vars.fd"
      tpmdir="$image.tpm"
      if [ ! -e "$vars" ]; then
        install -m 0600 ${ovmf}/FV/OVMF_VARS.ms.fd "$vars"
      fi
      mkdir -p -- "$tpmdir"

      rundir="$(mktemp -d "''${XDG_RUNTIME_DIR:-/tmp}/sandboxvm-win-install.XXXXXX")"
      swtpm_pid=""
      cleanup() {
        if [ -n "$swtpm_pid" ]; then kill "$swtpm_pid" 2>/dev/null || true; fi
        rm -rf -- "$rundir"
      }
      trap cleanup EXIT

      sock="$rundir/swtpm.sock"
      swtpm socket --tpm2 \
        --tpmstate dir="$tpmdir" \
        --ctrl type=unixio,path="$sock" \
        --terminate &
      swtpm_pid=$!
      for _ in $(seq 50); do
        [ -S "$sock" ] && break
        sleep 0.1
      done
      [ -S "$sock" ] || { echo "swtpm did not start" >&2; exit 1; }

      netdev_opts="virtio-net-pci,netdev=n0,disable-legacy=on"
      if [ -n "$mac" ]; then
        netdev_opts+=",mac=$mac"
      fi

      args=(
        -machine q35,smm=on,accel=kvm
        -global driver=cfi.pflash01,property=secure,value=on
        -cpu host -smp "$cpus" -m "$mem"
        -drive if=pflash,format=raw,unit=0,readonly=on,file=${ovmf}/FV/OVMF_CODE.fd
        -drive if=pflash,format=raw,unit=1,file="$vars"
        -chardev socket,id=chrtpm,path="$sock"
        -tpmdev emulator,id=tpm0,chardev=chrtpm
        -device tpm-crb,tpmdev=tpm0
        -drive if=none,id=root,format=raw,file="$image"
        -device virtio-blk-pci,drive=root,disable-legacy=on
        -device "$netdev_opts"
        -netdev user,id=n0
        -vga std
      )
      if [ "$clipboard" -eq 1 ]; then
        args+=(
          -display gtk,clipboard=on
          -device virtio-serial-pci,disable-legacy=on
          -chardev qemu-vdagent,id=chvdagent,name=vdagent,clipboard=on
          -device virtserialport,chardev=chvdagent,name=com.redhat.spice.0
        )
      fi
      if [ -n "$iso" ]; then
        args+=(-drive media=cdrom,readonly=on,index=2,file="$iso")
      fi
      if [ -n "$virtio" ]; then
        args+=(-drive media=cdrom,readonly=on,index=3,file="$virtio")
      fi

      qemu-system-x86_64 "''${args[@]}"
    '';
  }
