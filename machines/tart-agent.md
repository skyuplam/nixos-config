# macOS agent sandbox with Tart

The macOS counterpart of `machines/sandboxvm` (the NixOS `pi-agent` VM),
running on the MacBook with Apple's Virtualization.framework.

| Piece | Where |
|---|---|
| Guest (VM) config, nix-darwin | `machines/tart-agent.nix`, `darwinConfigurations.tart-agent` |
| Host (MacBook) config | `machines/tart-host.nix`: Tart with Softnet, sudo rule, pinned host key, `tart-agent-ssh`, `tart-agent-deploy` |
| Settings | `nix-secrets` → `tartAgent` |

## Compared with pi-agent

| pi-agent (NixOS host) | tart-agent (MacBook) |
|---|---|
| Non-root `agent`, no sudo, key-only SSH, no forwarding | Same: standard hidden user, `050-sandbox.conf`, `AuthorizedKeysFile none` |
| Pinned SSH host key, no trust-on-first-use (TOFU) | Same: `tart-agent` alias in `/etc/ssh/ssh_known_hosts` |
| Tools from Nix (pi, node 22, git, rg, …) | Same, except no Playwright browsers |
| `/input` and `~/.pi` virtiofs shares | `--dir=input:…`, `--dir=pi:…` under `/Volumes/My Shared Files` |
| nftables: only the public Internet, no host, no LAN | Softnet: public Internet + **host gateway**, no LAN, no other VMs, anti-spoofing |
| Disk reset on every boot | **Not yet**: comes with disposable `tart clone` sessions |

## 1. Keys and nix-secrets

On the MacBook, create two keys. Use the admin one only for maintenance; it
never goes into the VM.

```sh
ssh-keygen -t ed25519 -f ~/.ssh/tart_agent_ed25519 -C tart-agent
ssh-keygen -t ed25519 -f ~/.ssh/tart_<adminUser>_ed25519 -C tart-admin   # helpers look for this exact name
```

Add to `nix-secrets`:

```nix
tartAgent = {
  adminUser = "admin";            # account you create in Setup Assistant
  agentUid = 550;                 # unused uid in the VM (>= 501)
  authorizedKey = "ssh-ed25519 AAAA... tart-agent";      # ~/.ssh/tart_agent_ed25519.pub
  adminAuthorizedKey = "ssh-ed25519 AAAA... tart-admin"; # ~/.ssh/tart_<adminUser>_ed25519.pub
  # sshHostPublicKey = "ssh-ed25519 AAAA...";            # added in step 2
};
```

Then run `darwin-rebuild switch --flake .#macbook-pro-m2`. This installs
Tart with Softnet, the helpers, and a sudoers rule that lets your user run
the Softnet binary (and only that binary) as root without a password.

## 2. First boot (GUI, once)

```sh
tart run tahoe-vanilla
```

1. Setup Assistant: create the admin account named `adminUser` with a strong
   password. Skip Apple Account sign-in, and turn off Location, Analytics and
   Siri.
2. System Settings → General → Sharing → **Remote Login: on**, *Allow full
   disk access for remote users*: off, *Allow access for*: **All users**.
   With "Only these users: Administrators", macOS PAM rejects `agent` even
   with a valid key ("Access denied … by PAM account configuration").
   sshd's `AllowUsers` and key-only auth still restrict who can log in.
3. Terminal in the VM: `cat /etc/ssh/ssh_host_ed25519_key.pub`. Copy that
   line into `tartAgent.sshHostPublicKey` and rebuild the MacBook. The key
   is read from the VM's own screen, so no trust-on-first-use is involved.
4. Install Determinate Nix from its signed macOS `.pkg`
   (docs.determinate.systems). Do not pipe a script into a shell. Then allow
   the admin account to import store paths (use your `adminUser` name):

   ```sh
   echo 'extra-trusted-users = admin' | sudo tee -a /etc/nix/nix.custom.conf
   ```

   Use `extra-trusted-users`, not `trusted-users`: a later `trusted-users`
   line in `nix.conf` would replace it. Check after a reboot with
   `nix store info --store daemon` (must show `Trusted: 1`).

   Shut the VM down.

## 3. Apply the Nix configuration

```sh
tart run --no-graphics --no-audio --no-clipboard --net-softnet tahoe-vanilla &
tart-agent-deploy tahoe-vanilla \
  "$(nix build --no-link --print-out-paths .#darwinConfigurations.tart-agent.system)"
```

Before the first deploy, the admin account still accepts its password, so
type it when prompted. After activation only the admin key works. Run
`tart-agent-deploy` again whenever you change `machines/tart-agent.nix`.

## 4. Use it

```sh
mkdir -p ~/sandbox/mac-input ~/sandbox/mac-pi   # separate from pi-agent's piDir
tart run --no-graphics --no-audio --no-clipboard --net-softnet \
  --dir=input:"$HOME/sandbox/mac-input" --dir=pi:"$HOME/sandbox/mac-pi" \
  tahoe-vanilla &
tart-agent-ssh tahoe-vanilla            # as agent
tart-agent-ssh tahoe-vanilla admin      # maintenance
```

Inside the VM, `~agent/.pi` is a symlink to `/Volumes/My Shared Files/pi`,
so pi uses its default config dir `~/.pi/agent` on the share. Without
`--dir=pi:…` the link dangles and pi cannot save state.

Until you switch to disposable clones, anything the agent does persists in
`tahoe-vanilla`. Once it is configured, `tart clone tahoe-vanilla
tart-agent-golden` and run sessions from clones only.

## 5. Check it

As `agent` in the VM:

```sh
id                                   # not in group admin
sudo -n true                         # must fail
curl -sI https://example.com         # Internet works
nc -z -G 3 192.168.1.1 443           # your LAN/router: must fail
ls -l "/Volumes/My Shared Files"     # shares visible; check owner/mode
```

From the MacBook:

```sh
# Must be refused (no password logins):
ssh -o PubkeyAuthentication=no -o HostKeyAlias=tart-agent admin@"$(tart ip tahoe-vanilla)"
# Must work:
tart-agent-ssh tahoe-vanilla agent -- true
```

As admin in the VM, `sudo sshd -T | grep -Ei 'passwordauth|kbdinteractive|authenticationmethods|allowusers|allowtcp'`
should show the values from `050-sandbox.conf`.

## Known gaps

- **Host reachable:** the VM can reach services the Mac exposes on its vmnet
  gateway address. With nixpkgs' Softnet 0.21.1, `--net-softnet-block=@host`
  also drops replies to your SSH sessions, so do not use it. Until a newer
  Softnet (with directional `out @host` rules) is packaged, keep host
  services bound to localhost or enable the macOS firewall's *Block all
  incoming connections*.
- **Egress:** traffic leaves via the Mac's normal route, not a dedicated
  uplink like `wg0`.
- **Shares:** the `pi` share holds pi's credentials and is writable by the
  guest, the same as pi-agent. Use `--dir=…:ro` for anything the agent
  should only read.
- **Admin access:** `admin` is allowed over SSH, using the separate admin
  key. pi-agent has no such account.
- **Host key:** every clone of the golden image shares its SSH host key.
  It is only readable by root inside the VM.
