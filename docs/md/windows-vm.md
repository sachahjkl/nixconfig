# Windows VM

The homelab runs Windows 11 for the coding agents: the Windows tests and builds of gui_toolkit (D3D11 on WARP, the DXBC shaders that only `D3DCompile` writes) run there over ssh, without a GitHub CI run. The module is `services/windows-vm.mod.nix`; the setup inside Windows is `services/windows-vm/setup.ps1`.

## Decisions

- **dockur/windows in Docker, not a libvirt domain.** The homelab already declares its Docker containers with `virtualisation.oci-containers`. dockur downloads the evaluation ISO from Microsoft, writes the answer file, installs the VirtIO drivers and runs an OEM script at the first logon. A libvirt domain needs all of that by hand: the ISO, the driver ISO, an `autounattend.xml`, a NAT network and its port forwards.
- **Windows 11 Enterprise evaluation (`VERSION=11e`), no key.** It runs 90 days. When it expires, delete the data folder and restart the container: the installation and the setup run again without help.
- **Ports on the Tailscale address only.** Docker's published ports pass before the NixOS firewall, so the binding address is the only guard. SSH (host port 2222) and RDP (3389) bind `100.106.51.80`. The browser console (8006) has no password and binds `127.0.0.1`: reach it with `ssh -L 8006:127.0.0.1:8006 homelab`.
- **Key login only.** `setup.ps1` turns off password logins in `sshd_config` and writes the admin keys of `modules/keys.mod.nix` to `administrators_authorized_keys` (the user `dev` is an administrator). The account's password, in `windows-vm/environment` of `secrets/homelab.yaml`, serves the RDP console and the auto-logon.
- **The vcvars64 environment in the machine environment.** The CI runs each step inside vcvars64 (`setup-odin`). The setup writes that environment to the machine variables once, so every ssh session has `link.exe`, `rc.exe` and the SDK without a wrapper.
- **On demand, not always on.** The container does not start at boot or on a deploy: an agent runs `sudo systemctl start docker-windows-vm` on the homelab, works, then stops it. The disk stays, so a start takes about a minute and no new installation.
- **The homelab keeps priority.** The VM has 4 cores at a CPU weight of 256 (Docker's default is 1024) and at most 6 GB. The QEMU balloon gives memory back to the host under pressure, down to 2 GB.

## Subtleties

- The OpenSSH server comes from the pinned Win32-OpenSSH MSI, not the Windows capability: the capability downloads from Windows Update, and with `NoAutoUpdate` set it hung.
- The OEM folder is a store path mounted at `/oem`. dockur copies it into Windows only during the installation: a change of `setup.ps1` reaches an installed VM only by copying the script and running it again, or by a new installation.
- `setup.ps1` is idempotent. It takes `-OdinTag` and `-OdinSha256`: when gui_toolkit moves to a new Odin, run it again with the new pin. `C:\tools\odin` is a junction to the current version.
- The disk image lives on Btrfs with copy-on-write off (`chattr +C` through tmpfiles), else every guest write fragments the file.
- A program started from ssh runs in a non-interactive session. Tests that need the desktop run in the logged-on session of `dev` (auto-logon) through a scheduled task.
