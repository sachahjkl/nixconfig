# AGENTS.md

## Repo Context

This is a `flake-parts` Nix repo. `flake.nix` imports every `*.mod.nix` file in the repository as a `flake-parts` module.

File placement matters:

- A `*.mod.nix` file in the import tree is not automatically a plain NixOS module.
- A `*.mod.nix` file must define flake-parts outputs such as `flake.nixosModules.*`, `perSystem`, `imports`, `options`, or `config`.
- Plain NixOS fragments should either be kept out of the import tree or wrapped/exported correctly.
- Host hardware files in this repo are flake-parts files exporting host-specific `flake.nixosModules.*` entries.

## Required Patterns

### Export NixOS Modules

Correct:

```nix
{ ... }:

{
  flake.nixosModules.someModule = { config, lib, pkgs, ... }: {
    # NixOS module body
  };
}
```

Wrong for a directly imported `*.mod.nix` file:

```nix
{ config, lib, pkgs, ... }: {
  # bare NixOS module body
}
```

### Scope Rules

- `perSystem = { pkgs, self', ... }: ...` is flake-parts/per-system scope.
- `flake.nixosModules.<name> = { config, lib, pkgs, ... }: ...` is NixOS module scope.
- `self'` exists in `perSystem`, not in NixOS module scope.
- In a NixOS module, use `self.packages.${pkgs.stdenv.hostPlatform.system}` when both `self` and `pkgs` are available.

### Standalone Module Evaluation

`nix flake check` evaluates exported `flake.nixosModules.*` directly. Do not assume another module has already declared an option unless the module imports it.

Use safe lookups when optional config may not exist:

```nix
let
  desktopEnvironment = lib.attrByPath [ "desktop" "environment" ] null config;
in
lib.mkIf (desktopEnvironment == "hyprland") { ... }
```

### Eager Derivations

Keep derivations behind conditionals when they are only needed conditionally. This avoids forcing packages during standalone module evaluation.

## Secrets

- Agenix recipient rules live in `secrets.nix`.
- Public recipient keys live in `modules/keys.mod.nix`.
- The agenix private key is stored in Bitwarden and restored to `~/.ssh/agenix`.
- Do not use the YubiKey resident `sk-*` SSH key for agenix; age needs a normal decryptable SSH key.
- `.age` files are safe to commit. Plaintext secrets and private keys are not.

## Verification

Use `path:` during development so untracked files are included:

```bash
nix flake check "path:$PWD" --no-write-lock-file
```

For Nix changes, also run the local linters when available:

```bash
deadnix .
statix check .
```

Enter `nix develop` once after cloning to install the repository pre-commit hooks.

## Best Practices

- Prefer small structural changes.
- Before creating a new Nix file, decide whether it is a flake-parts module or a private plain NixOS fragment.
- Keep host files thin and compose named modules explicitly.
- After changes, run `nix fmt`, `deadnix .`, `statix check .`, and `nix flake check "path:$PWD" --no-write-lock-file`.
