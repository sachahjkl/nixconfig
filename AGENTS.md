# AGENTS.md

## Repo Context

This repo is a `flake-parts` Nix
  repo.`flake.nix`
  uses
  an
  import
  tree
  over
  the
  repository, so every matching `.nix` file is imported as a `flake-parts` module unless it is filtered out.

That means file placement matters:

- A normal file in the tree is **not** automatically a plain NixOS module.
- A normal file in the tree **is** a `flake-parts` module and must define things like `flake.nixosModules.*`, `perSystem`, `imports`, `options`, or `config` in `flake-parts` style.
- If a file is meant to be only a plain NixOS module fragment, do **not** leave it as a top-level import-tree file unless it is wrapped/exported correctly.
- Host `hardware-configuration.nix` files should also be proper flake-part files in this repo, exporting host-specific `flake.nixosModules.*` entries.

## Required Patterns

### 1. Export NixOS modules from flake-part files

Correct pattern:

```nix
{ ... }:

{
flake.nixosModules.someModule = { config, lib, pkgs, ... }: {
# NixOS module body
};
}
```

Wrong pattern for this repo:

```nix
{ config, lib, pkgs, ... }: {
# bare NixOS module body
}
```

The wrong pattern only works when that file is imported by some other NixOS module, not when `flake-parts` imports it directly from the tree.

### 2. Distinguish `flake-parts` scope from NixOS module scope

Common scopes in this repo:

- `perSystem = { pkgs, self', ... }: ...`
- `flake.nixosModules.<name> = { config, lib, pkgs, ... }: ...`

Rules:

- `self'` is a `perSystem` helper, not a NixOS module argument.
- `selfPkgs = self.packages.${pkgs.stdenv.hostPlatform.system};` is valid inside a NixOS module when both `self` and `pkgs` are in scope.
- Flake-level options and NixOS options are different layers. Do not assume a `perSystem` package can read NixOS module `config.*` unless that value was explicitly lifted to flake-parts scope.

### 3. Keep standalone exported modules evaluable

Because `nix flake check` evaluates `flake.nixosModules.*` directly, exported modules must not assume some other module has already declared options like `desktop.environment`.

Use safe lookups when gating behavior:

```nix
let
desktopEnvironment = lib.attrByPath [ "desktop" "environment" ] null config;
isHypr = lib.elem desktopEnvironment [ "hyprland" "both" "all" ];
in
lib.mkIf isHypr { ... }
```

Avoid direct access like:

```nix
lib.elem config.desktop.environment [ ... ]
```

if the module may be evaluated standalone.

### 4. Keep eager derivations behind `mkIf` when possible

If a module exports packages via `environment.systemPackages`, construct helper derivations inside the conditional branch when they are only needed there.

This avoids forcing arguments during standalone module evaluation.

## Lessons From This Repo

### Hyprland split lesson

When splitting `hyprland` into multiple files in this repo, the correct shape is:

- one file per flake-exported module, e.g. `hyprland/apps.nix`
- each file exports `flake.nixosModules.hyprlandApps = ...`
- hosts import those named modules explicitly

Do **not**:

- drop plain NixOS module fragments into the import tree and expect them to behave like private includes
- rely on one umbrella module to hide the fact that the files themselves are being imported by `flake-parts`

### Verification lesson

If new files are untracked, `nix flake check` may evaluate `git+file://...` source semantics and miss them.

Use:

```bash
nix flake check "path:$PWD" --no-write-lock-file
```

when verifying in-progress work that includes untracked files.

## Best Practices For Future Changes

- Prefer small structural changes, but keep the `flake-parts` import model in mind before moving files.
- When creating a new `.nix` file under the import tree, decide first whether it is:
- a `flake-parts` module file, or
- a plain NixOS module that should only be referenced by another exported module.
- If it is the second kind, either:
- keep it out of the import tree, or
- make it a proper flake-part that exports the NixOS module.
- `hardware-configuration.nix` keeps its conventional name, but in this repo it should wrap the generated module as a flake-part export instead of being imported as a raw path.
- Before a refactor, check the scope you are in: `perSystem`, flake-part top level, or NixOS module.
- After changes, run `nix flake check "path:$PWD" --no-write-lock-file`.
