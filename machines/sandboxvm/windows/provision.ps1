<#
.SYNOPSIS
  One-time provisioning of the Windows sandbox golden image.

.DESCRIPTION
  Run once, as Administrator, inside the Windows VM while preparing the
  golden image (see README.md). It configures the guest so that, on every
  boot under machines/sandboxvm/windows-guest.nix:

    * the network uses the static address enforced on the host bridge port;
    * the pinned SSH host key is copied in from the read-only
      `sandbox-hostkey` virtiofs share, checked against the pinned public
      key, and the share is unmounted again before sshd starts (fail closed:
      no valid key, no sshd);
    * a non-administrator `pi-agent` (or `-AgentUser`) account accepts only
      the given SSH key;
    * the `sandbox-input`, `sandbox-pi` and `sandbox-gcloud` shares are
      mounted as I:, P: and G:.

  Prerequisites (install before running): virtio-win guest tools (NetKVM,
  viostor, viofs drivers and the VirtIO-FS service), WinFsp with the "Core"
  feature, Git for Windows (pi's bash tool needs it), Node.js LTS and
  Google Cloud CLI (gcloud).

  The script never receives or stores a private key or a password. It ends
  by deleting any SSH host key so none is baked into the image.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory)][ValidatePattern('^\d{1,3}(\.\d{1,3}){3}$')][string]$GuestAddress,
  [Parameter(Mandatory)][ValidateRange(8, 30)][int]$PrefixLength,
  [Parameter(Mandatory)][ValidatePattern('^\d{1,3}(\.\d{1,3}){3}$')][string]$HostAddress,
  [Parameter(Mandatory)][ValidatePattern('^([0-9a-fA-F]{2}[:-]){5}[0-9a-fA-F]{2}$')][string]$MacAddress,
  [Parameter(Mandatory)][ValidatePattern('^ssh-ed25519 [A-Za-z0-9+/=]+( .*)?$')][string]$AgentAuthorizedKey,
  [Parameter(Mandatory)][ValidatePattern('^ssh-ed25519 [A-Za-z0-9+/=]+( .*)?$')][string]$PinnedHostPublicKey,
  [Parameter(Mandatory)][ValidateRange(1, 4294967294)][long]$HostOwnerUid,
  [Parameter(Mandatory)][ValidateRange(1, 4294967294)][long]$HostOwnerGid,
  [ValidatePattern('^[a-z][a-z0-9_-]{0,19}$')][string]$AgentUser = 'pi-agent',
  [ValidatePattern('^\d{1,3}(\.\d{1,3}){3}$')][string[]]$DnsServers = @('1.1.1.1', '9.9.9.9')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
  [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { throw 'Run this script as Administrator.' }

$sandboxDir = Join-Path $env:ProgramData 'sandboxvm'
$sshDir = Join-Path $env:ProgramData 'ssh'
$winfspBin = Join-Path ${env:ProgramFiles(x86)} 'WinFsp\bin'
$virtiofsExe = Join-Path $env:ProgramFiles 'Virtio-Win\VioFS\virtiofs.exe'

foreach ($p in @((Join-Path $winfspBin 'launchctl-x64.exe'), (Join-Path $winfspBin 'fsreg.bat'), $virtiofsExe)) {
  if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { throw "Missing prerequisite: $p" }
}

# Restrict a file or directory to SYSTEM and Administrators only.
function Set-AdminOnlyAcl([string]$Path) {
  $acl = New-Object System.Security.AccessControl.DirectorySecurity
  if (Test-Path -LiteralPath $Path -PathType Leaf) { $acl = New-Object System.Security.AccessControl.FileSecurity }
  $acl.SetAccessRuleProtection($true, $false)
  foreach ($sid in @('S-1-5-18', 'S-1-5-32-544')) {
    $id = New-Object System.Security.Principal.SecurityIdentifier($sid)
    $inherit = if ($acl -is [System.Security.AccessControl.DirectorySecurity]) { 'ContainerInherit,ObjectInherit' } else { 'None' }
    $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($id, 'FullControl', $inherit, 'None', 'Allow')))
  }
  $acl.SetOwner((New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-544')))
  Set-Acl -LiteralPath $Path -AclObject $acl
}

# Normalize MAC for boot-time NIC matching. Static IPv4 is applied in
# boot.ps1 rather than here because Windows ties static IP config to a NIC's
# PCI slot, which differs between QEMU (image build) and Cloud Hypervisor.
$mac = ($MacAddress -replace ':', '-').ToUpperInvariant()

# --- Agent account: non-admin, random password nobody knows ---------------
$existingUser = Get-LocalUser -Name $AgentUser -ErrorAction SilentlyContinue
if ($existingUser) {
  if (Get-LocalGroupMember -Group (Get-LocalGroup -SID 'S-1-5-32-544') | Where-Object { $_.SID -eq $existingUser.SID }) {
    throw "$AgentUser must not be an Administrator"
  }
}
$bytes = New-Object byte[] 48
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
$pw = ConvertTo-SecureString ([Convert]::ToBase64String($bytes)) -AsPlainText -Force
if ($existingUser) {
  Set-LocalUser -Name $AgentUser -Password $pw -PasswordNeverExpires $true
} else {
  New-LocalUser -Name $AgentUser -Password $pw -PasswordNeverExpires -AccountNeverExpires -Description 'Sandbox coding agent' | Out-Null
}
$agentAccount = Get-LocalUser -Name $AgentUser
$agentSid = $agentAccount.SID
$usersGroup = Get-LocalGroup -SID 'S-1-5-32-545'
if (-not (Get-LocalGroupMember -Group $usersGroup | Where-Object { $_.SID -eq $agentSid })) {
  Add-LocalGroupMember -Group $usersGroup -Member $agentAccount
}
if (Get-LocalGroupMember -Group (Get-LocalGroup -SID 'S-1-5-32-544') | Where-Object { $_.SID -eq $agentSid }) {
  throw "$AgentUser must not be an Administrator"
}
$pw = $null; [Array]::Clear($bytes, 0, $bytes.Length)

# --- OpenSSH server ------------------------------------------------------
$cap = Get-WindowsCapability -Online -Name 'OpenSSH.Server*' | Select-Object -First 1
if ($cap.State -ne 'Installed') { Add-WindowsCapability -Online -Name $cap.Name | Out-Null }
Stop-Service sshd -ErrorAction SilentlyContinue
# Started only by the boot task, after the pinned host key is in place.
Set-Service -Name sshd -StartupType Manual

New-Item -ItemType Directory -Force -Path $sshDir, $sandboxDir | Out-Null
# The boot task copies the host key here; it must inherit an admin-only ACL.
Set-AdminOnlyAcl $sshDir
Set-AdminOnlyAcl $sandboxDir

$authKeys = Join-Path $sshDir 'agent_authorized_keys'
Set-Content -LiteralPath $authKeys -Value $AgentAuthorizedKey -Encoding ascii
Set-AdminOnlyAcl $authKeys

Set-Content -LiteralPath (Join-Path $sshDir 'sshd_config') -Encoding ascii -Value @"
HostKey __PROGRAMDATA__/ssh/ssh_host_ed25519_key
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
AllowUsers $AgentUser
AuthorizedKeysFile __PROGRAMDATA__/ssh/agent_authorized_keys
AllowAgentForwarding no
AllowTcpForwarding no
GatewayPorts no
PermitTunnel no
X11Forwarding no
PermitUserEnvironment no
Subsystem sftp sftp-server.exe
"@

Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue | Remove-NetFirewallRule
Get-NetFirewallRule -Name 'sandboxvm-ssh' -ErrorAction SilentlyContinue | Remove-NetFirewallRule
New-NetFirewallRule -Name 'sandboxvm-ssh' -DisplayName 'SSH from sandbox host only' -Direction Inbound `
  -Profile Any -Protocol TCP -LocalPort 22 -RemoteAddress $HostAddress -Action Allow | Out-Null

# Windows 11 client SKUs need the EMS-SAC Tools capability for a live SAC>
# serial console; on Server SKUs SAC is built in and this capability is absent.
$sacCap = Get-WindowsCapability -Online -Name 'Windows.Desktop.EMS-SAC.Tools*' | Select-Object -First 1
if ($sacCap -and $sacCap.State -ne 'Installed') {
  Add-WindowsCapability -Online -Name $sacCap.Name | Out-Null
}

# --- virtiofs: WinFsp launcher entry (multiple instances) ------------------
Set-Service -Name VirtioFsSvc -StartupType Manual -ErrorAction SilentlyContinue
Stop-Service VirtioFsSvc -ErrorAction SilentlyContinue
& (Join-Path $winfspBin 'fsreg.bat') virtiofs $virtiofsExe "-t %1 -m %2 -o $HostOwnerUid`:$HostOwnerGid"
if ($LASTEXITCODE -ne 0) { throw 'fsreg.bat failed' }

# pi reads its configuration from the persistent P: share; gcloud and ADC
# read credentials/config from the read-only G: share.
[Environment]::SetEnvironmentVariable('PI_CODING_AGENT_DIR', 'P:\agent', 'Machine')
[Environment]::SetEnvironmentVariable('PI_TELEMETRY', '0', 'Machine')
[Environment]::SetEnvironmentVariable('PI_SKIP_VERSION_CHECK', '1', 'Machine')
[Environment]::SetEnvironmentVariable('CLOUDSDK_CONFIG', 'G:\', 'Machine')
[Environment]::SetEnvironmentVariable('GOOGLE_APPLICATION_CREDENTIALS', 'G:\application_default_credentials.json', 'Machine')

# --- Boot task -----------------------------------------------------------
$pinned = ($PinnedHostPublicKey -split ' ')[0..1] -join ' '
$dnsArrayLiteral = ($DnsServers | ForEach-Object { "'$_'" }) -join ', '
$bootScript = Join-Path $sandboxDir 'boot.ps1'
Set-Content -LiteralPath $bootScript -Encoding ascii -Value @"
Set-StrictMode -Version Latest
`$ErrorActionPreference = 'Stop'
`$launchctl = '$(Join-Path $winfspBin 'launchctl-x64.exe')'
`$sshDir = '$sshDir'
`$dest = Join-Path `$sshDir 'ssh_host_ed25519_key'
`$pinned = '$pinned'
`$mac = '$mac'
`$guestAddress = '$GuestAddress'
`$prefixLength = $PrefixLength
`$hostAddress = '$HostAddress'
`$dnsServers = @($dnsArrayLiteral)
function Invoke-Launchctl([string[]]`$LaunchArgs) {
  & `$launchctl @LaunchArgs | Out-Null
  if (`$LASTEXITCODE -ne 0) { throw "launchctl `$(`$LaunchArgs -join ' ') failed: `$LASTEXITCODE" }
}
Start-Transcript -LiteralPath '$(Join-Path $sandboxDir 'boot.log')' -Force | Out-Null
`$ok = `$false
try {
  # Never reuse a key from a previous boot. The ssh directory is
  # SYSTEM/Administrators-only, so the copy below inherits that ACL.
  Get-ChildItem -LiteralPath `$sshDir -Filter 'ssh_host_*' -ErrorAction SilentlyContinue | Remove-Item -Force

  Invoke-Launchctl @('start', 'virtiofs', 'viofsK', 'sandbox-hostkey', '\\.\K:')
  `$src = 'K:\ssh_host_ed25519_key'
  for (`$i = 0; `$i -lt 60 -and -not (Test-Path -LiteralPath `$src); `$i++) { Start-Sleep -Seconds 1 }
  if (-not (Test-Path -LiteralPath `$src -PathType Leaf)) { throw 'host key share not available' }
  Copy-Item -LiteralPath `$src -Destination `$dest -Force
  # Unmount before anything else runs so the key is only reachable here.
  Invoke-Launchctl @('stop', 'virtiofs', 'viofsK')

  `$acl = New-Object System.Security.AccessControl.FileSecurity
  `$acl.SetAccessRuleProtection(`$true, `$false)
  foreach (`$sid in @('S-1-5-18', 'S-1-5-32-544')) {
    `$id = New-Object System.Security.Principal.SecurityIdentifier(`$sid)
    `$acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(`$id, 'FullControl', 'Allow')))
  }
  `$acl.SetOwner((New-Object System.Security.Principal.SecurityIdentifier('S-1-5-18')))
  Set-Acl -LiteralPath `$dest -AclObject `$acl

  `$derived = ((& "`$env:WINDIR\System32\OpenSSH\ssh-keygen.exe" -y -f `$dest) -split ' ')[0..1] -join ' '
  if (`$LASTEXITCODE -ne 0 -or `$derived -ne `$pinned) {
    throw 'host key does not match the pinned public key'
  }

  # Configure static IPv4 on the NIC with the bridge-enforced MAC. Done at
  # boot (after host-key verification) because Windows binds static IP config
  # to the NIC's PCI slot, which differs between QEMU and Cloud Hypervisor,
  # and keeping it after host-key check leaves QEMU DHCP intact during maintenance.
  `$matchedNics = @()
  for (`$i = 0; `$i -lt 30 -and `$matchedNics.Count -eq 0; `$i++) {
    `$matchedNics = @(Get-NetAdapter -Physical | Where-Object { `$_.MacAddress -eq `$mac })
    if (`$matchedNics.Count -eq 0) { Start-Sleep -Seconds 1 }
  }
  if (`$matchedNics.Count -ne 1) { throw "Expected exactly one adapter with MAC `$mac (found `$(`$matchedNics.Count))" }
  `$nic = `$matchedNics[0]
  Set-NetIPInterface -InterfaceIndex `$nic.ifIndex -AddressFamily IPv4 -Dhcp Disabled
  Get-NetIPAddress -InterfaceIndex `$nic.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Remove-NetIPAddress -Confirm:`$false
  Get-NetRoute -InterfaceIndex `$nic.ifIndex -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue |
    Remove-NetRoute -Confirm:`$false
  New-NetIPAddress -InterfaceIndex `$nic.ifIndex -IPAddress `$guestAddress -PrefixLength `$prefixLength -DefaultGateway `$hostAddress | Out-Null
  Set-DnsClientServerAddress -InterfaceIndex `$nic.ifIndex -ServerAddresses `$dnsServers
  # The host drops all non-IPv4 frames from the guest anyway.
  Disable-NetAdapterBinding -Name `$nic.Name -ComponentID ms_tcpip6

  Invoke-Launchctl @('start', 'virtiofs', 'viofsI', 'sandbox-input', '\\.\I:')
  Invoke-Launchctl @('start', 'virtiofs', 'viofsP', 'sandbox-pi', '\\.\P:')
  Invoke-Launchctl @('start', 'virtiofs', 'viofsG', 'sandbox-gcloud', '\\.\G:')

  Start-Service sshd
  `$ok = `$true
} catch {
  Write-Output "sandboxvm-boot FAILED: `$_"
} finally {
  # Best effort: normally already unmounted above.
  try { & `$launchctl stop virtiofs viofsK 2>`$null | Out-Null } catch { }
  Stop-Transcript | Out-Null
}
if (-not `$ok) {
  # Fail closed: no verified host key, no sshd. See boot.log via RDP/SAC.
  Stop-Service sshd -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath `$dest -Force -ErrorAction SilentlyContinue
  exit 1
}
"@
Set-AdminOnlyAcl $bootScript

$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$bootScript`""
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId 'S-1-5-18' -RunLevel Highest
Register-ScheduledTask -TaskName 'sandboxvm-boot' -Action $action -Trigger $trigger -Principal $principal -Force | Out-Null

# --- Image hygiene -------------------------------------------------------
# The disk is discarded on every stop; hibernation and fast startup only
# waste space and can resurrect state.
powercfg.exe /hibernate off | Out-Null
# Serial console (SAC) for headless debugging under Cloud Hypervisor.
bcdedit.exe /emssettings emsport:1 emsbaudrate:115200 | Out-Null
bcdedit.exe /ems on | Out-Null
bcdedit.exe /bootems on | Out-Null

# Never ship a host key in the golden image.
Get-ChildItem -LiteralPath $sshDir -Filter 'ssh_host_*' -ErrorAction SilentlyContinue | Remove-Item -Force

Write-Host 'Provisioning complete. Shut down (not reboot) and copy the disk out as the golden image.'
