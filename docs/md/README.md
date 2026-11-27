# Intent

This folder records the intent of this configuration: the purpose, the design decisions, the refused alternatives and the subtle points. Documentation for a reader who operates the machines stays in `README.md` and `docs/`.

## Overview

- `flake.nix` imports every `*.mod.nix` file in the repository as a flake-parts module. A plain NixOS module must be exported through `flake.nixosModules.<name>`.
- `modules/` holds the reusable NixOS modules and the aggregate modules (`common`, `workstation`, `desktop`, `server`, ...).
- `hosts/<host>/` holds the thin host entrypoints, their hardware modules and their disko configurations.
- `services/` holds the homelab and WSL service modules. `packages/` holds wrapped packages, dev shells and the formatter.
- `.tack/` holds the inputs: `pins.toml` declares them, `pins.lock.json` locks them.
- `secrets/` holds SOPS-encrypted YAML. `.sops.yaml` gives the age recipients. sops-nix decrypts them at activation.
- `modules/deploy.mod.nix` deploys the homelab with deploy-rs.

## Subtleties

- **tack, not flake.lock.** The inputs are tack pins in `.tack/`. Update them with `nix run .#update` or `tack update <pin>`. Do not rely on `flake.lock`.
- **`path:` flake references.** Use `path:$PWD` with `--no-write-lock-file` during development. A `git+file` reference ignores untracked files, so a new module is invisible to the evaluation.
- **deploy-rs for the homelab.** `nix run .#deploy` pushes the homelab configuration over ssh as the `deploy` user, then activates it as root. The flake checks include the deploy-rs checks. A local `nixos-rebuild` on the homelab also works.
- **The Rex server runs as the owner (`sacha`), not as the `rex` account.** The server runs each terminal as its own account. As the `rex` system account, a terminal has no home, no dotfiles and no sudo. As the owner, a terminal is the owner's shell. `REX_RUNTIME_DIR=/run/rex` makes this server the owner's personal server, so every rex command and every `ssh://` session reach it, and it survives logouts without linger. `/var/lib/rex` is preserved so sessions survive a reboot.

## File Index

Each intent file gets one line here: a link and a short description.

- [windows-vm.md](windows-vm.md): the Windows 11 VM on the homelab for Windows builds and tests over ssh.
