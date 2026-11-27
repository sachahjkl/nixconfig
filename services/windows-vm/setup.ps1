# First-logon setup of the Windows build and test VM (services/windows-vm.mod.nix).
# dockur/windows copies the OEM folder to C:\OEM and runs install.bat once, elevated, as the auto-logon user (dev).
# Every step is idempotent. Run it again (for example with a new Odin) from an elevated PowerShell:
#   powershell -ExecutionPolicy Bypass -File C:\OEM\setup.ps1 -OdinTag dev-2026-12a -OdinSha256 <sha256>
param(
  # The Odin that gui_toolkit pins (.github/actions/setup-odin/action.yml).
  [string]$OdinTag = 'dev-2026-11a',
  [string]$OdinSha256 = '259effedf2997293c8fa4a5e497496f8ebce9f826652d9dd353a9dd2113c31fd',
  [switch]$NoRestart
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Start-Transcript -Append -Path C:\OEM\setup.log | Out-Null

$tools = 'C:\tools'
$downloads = 'C:\tools\downloads'
New-Item -ItemType Directory -Force $tools, $downloads, C:\src | Out-Null

function Get-File([string]$url, [string]$name, [string]$sha256 = '') {
  $out = Join-Path $downloads $name
  # The first logon can come before the network is up: retry with a growing delay.
  for ($i = 1; $i -le 8; $i++) {
    try { Invoke-WebRequest -UseBasicParsing $url -OutFile $out; break }
    catch { if ($i -eq 8) { throw }; Start-Sleep -Seconds (15 * $i) }
  }
  if ($sha256) {
    $got = (Get-FileHash -Algorithm SHA256 $out).Hash.ToLower()
    if ($got -ne $sha256) { throw "${name}: SHA-256 mismatch ($got)" }
  }
  $out
}

function Set-RegistryValue([string]$key, [string]$name, $value, [string]$type = 'DWord') {
  # New-Item -Force on an existing key deletes its values: create it only when it is missing.
  if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
  New-ItemProperty -Path $key -Name $name -Value $value -PropertyType $type -Force | Out-Null
}

function Add-MachinePath([string[]]$dirs) {
  $path = @([Environment]::GetEnvironmentVariable('Path', 'Machine') -split ';' | Where-Object { $_ })
  $new = @($dirs | Where-Object { $path -notcontains $_ })
  if ($new.Count) { [Environment]::SetEnvironmentVariable('Path', (($new + $path) -join ';'), 'Machine') }
}

Write-Host '== Machine settings'
# A build VM: no sleep, no automatic updates that reboot it during a test run.
powercfg /change standby-timeout-ac 0
powercfg /change monitor-timeout-ac 0
powercfg /hibernate off
Set-RegistryValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' NoAutoUpdate 1
Set-RegistryValue 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' LongPathsEnabled 1
# The setting holds, but the cmdlet throws when this process's -ExecutionPolicy Bypass overrides it.
try { Set-ExecutionPolicy RemoteSigned -Scope LocalMachine -Force } catch { Write-Host 'execution policy: RemoteSigned (overridden in this process)' }
# Defender scans every object file of a build: exclude the build folders.
try { Add-MpPreference -ExclusionPath C:\src, C:\tools, $env:USERPROFILE } catch { Write-Warning "Defender exclusions: $_" }

Write-Host '== OpenSSH server'
if (-not (Get-Service sshd -ErrorAction SilentlyContinue)) {
  # The MSI of Win32-OpenSSH, pinned: the Windows capability comes from Windows Update, which hung with NoAutoUpdate set.
  $msi = Get-File 'https://github.com/PowerShell/Win32-OpenSSH/releases/download/10.4.0.0p1-Preview/OpenSSH-Win64-v10.4.0.0.msi' openssh.msi '788d8643464a01eb63640a2fd746f9ed23d106b5a901a35f88dc8cd40e446ac9'
  $p = Start-Process msiexec.exe -ArgumentList '/i', $msi, '/qn', '/norestart' -Wait -PassThru
  if ($p.ExitCode -notin 0, 3010) { throw "OpenSSH MSI: $($p.ExitCode)" }
}
Set-Service sshd -StartupType Automatic
# The first start writes the host keys and sshd_config.
Start-Service sshd
$config = 'C:\ProgramData\ssh\sshd_config'
$text = Get-Content -Raw $config
if ($text -notmatch '(?m)^PasswordAuthentication no') {
  # sshd keeps the first value it reads: these lines come before the Match block at the end.
  Set-Content -Path $config -Encoding ascii -Value ("PasswordAuthentication no`r`nKbdInteractiveAuthentication no`r`n" + $text)
}
$keys = 'C:\ProgramData\ssh\administrators_authorized_keys'
Copy-Item C:\OEM\authorized_keys $keys -Force
icacls.exe $keys /inheritance:r /grant '*S-1-5-32-544:F' /grant '*S-1-5-18:F' | Out-Null
Set-RegistryValue 'HKLM:\SOFTWARE\OpenSSH' DefaultShell 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' String
if (Get-NetFirewallRule -Name OpenSSH-Server-In-TCP -ErrorAction SilentlyContinue) {
  # The VM's network is Public: the rule must hold on every profile.
  Set-NetFirewallRule -Name OpenSSH-Server-In-TCP -Enabled True -Profile Any
} else {
  New-NetFirewallRule -Name OpenSSH-Server-In-TCP -DisplayName 'OpenSSH Server (sshd)' -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow -Profile Any | Out-Null
}
Restart-Service sshd

Write-Host '== Git'
if (-not (Test-Path 'C:\Program Files\Git\cmd\git.exe')) {
  $git = Get-File 'https://github.com/git-for-windows/git/releases/download/v2.56.1.windows.1/Git-2.56.1-64-bit.exe' git.exe 'c330c72e10b408cc39994bfefdb63542b0d93d21699325c3e0bd874af8a5a559'
  $p = Start-Process $git -ArgumentList '/VERYSILENT', '/NORESTART', '/NOCANCEL', '/SP-', '/SUPPRESSMSGBOXES', '/o:PathOption=Cmd' -Wait -PassThru
  if ($p.ExitCode) { throw "Git installer: $($p.ExitCode)" }
}
# git push over ssh runs git-receive-pack by name: the folder that has it goes on the Path.
Add-MachinePath @('C:\Program Files\Git\cmd', 'C:\Program Files\Git\mingw64\bin')
& 'C:\Program Files\Git\cmd\git.exe' config --system core.longpaths true

Write-Host '== Visual Studio Build Tools (MSVC x64, Windows SDK)'
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
function Find-VS { if (Test-Path $vswhere) { & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath } }
if (-not (Find-VS)) {
  $vs = Get-File 'https://aka.ms/vs/17/release/vs_buildtools.exe' vs_buildtools.exe
  $p = Start-Process $vs -ArgumentList '--quiet', '--wait', '--norestart', '--nocache',
    '--add', 'Microsoft.VisualStudio.Workload.VCTools',
    '--add', 'Microsoft.VisualStudio.Component.VC.Tools.x86.x64',
    '--add', 'Microsoft.VisualStudio.Component.Windows11SDK.26100' -Wait -PassThru
  if ($p.ExitCode -notin 0, 3010) { throw "Build Tools installer: $($p.ExitCode)" }
}
$vsPath = Find-VS
if (-not $vsPath) { throw 'no Visual Studio with the C++ x64 tools' }
# The CI runs every step in the vcvars64 environment (setup-odin): write it to the machine environment so that every
# ssh session, scheduled task and shell has link.exe, rc.exe and the SDK, as on the runner.
$before = @{}
Get-ChildItem env: | ForEach-Object { $before[$_.Name] = $_.Value }
$lines = cmd /c "`"$vsPath\VC\Auxiliary\Build\vcvars64.bat`" >nul && set"
if ($LASTEXITCODE) { throw "vcvars64.bat failed ($LASTEXITCODE)" }
$vcPaths = @()
foreach ($l in $lines) {
  $i = $l.IndexOf('=')
  if ($i -le 0) { continue }
  $name, $value = $l.Substring(0, $i), $l.Substring($i + 1)
  if ($before[$name] -eq $value) { continue }
  if ($name -eq 'Path') {
    $old = $before['Path'] -split ';'
    $vcPaths = @($value -split ';' | Where-Object { $_ -and $old -notcontains $_ })
  } else {
    [Environment]::SetEnvironmentVariable($name, $value, 'Machine')
  }
}
Add-MachinePath $vcPaths

Write-Host '== Rust (x86_64-pc-windows-msvc)'
if (-not (Test-Path "$env:USERPROFILE\.cargo\bin\cargo.exe")) {
  $rustup = Get-File 'https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe' rustup-init.exe
  & $rustup -y --profile minimal --default-toolchain stable --default-host x86_64-pc-windows-msvc
  if ($LASTEXITCODE) { throw "rustup-init: $LASTEXITCODE" }
}

Write-Host "== Odin $OdinTag"
$odinDir = "$tools\odin-$OdinTag"
if (-not (Test-Path "$odinDir\dist\odin.exe")) {
  $zip = Get-File "https://github.com/odin-lang/Odin/releases/download/$OdinTag/odin-windows-amd64-$OdinTag.zip" "odin-$OdinTag.zip" $OdinSha256
  Expand-Archive $zip -DestinationPath $odinDir -Force
}
# C:\tools\odin is a junction to the current version: the Path names it once, a new version only moves the junction.
$link = "$tools\odin"
if (Test-Path $link) { cmd /c rmdir $link | Out-Null }
New-Item -ItemType Junction -Path $link -Target $odinDir | Out-Null
Add-MachinePath @("$link\dist")
& "$link\dist\odin.exe" version

Set-Content -Path C:\OEM\setup.done -Value (Get-Date -Format o)
Write-Host '== Done'
Stop-Transcript | Out-Null
# The Build Tools and the machine environment take effect for every process after a restart.
if (-not $NoRestart) { Restart-Computer -Force }
