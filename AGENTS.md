# AGENTS.md

## Repo Context

This is a `flake-parts` Nix repo. `flake.nix` imports every `*.mod.nix` file in the repository as a `flake-parts` module.

File placement matters:

- A `*.mod.nix` file in the import tree is not automatically a plain NixOS module.
- A `*.mod.nix` file must define flake-parts outputs such as `flake.nixosModules.*`, `perSystem`, `imports`, `options`, or `config`.
- Plain NixOS fragments must stay out of the `*.mod.nix` import tree or be wrapped by a `*.mod.nix` file.
- Host hardware files in this repo are flake-parts files exporting host-specific `flake.nixosModules.*` entries.

## Required Patterns

### Export NixOS Modules

Correct:

```nix
_: {
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

`nix flake check` evaluates exported `flake.nixosModules.*` directly. Do not assume another module has declared an option unless the module imports it.

Use `lib.hasAttrByPath` with `lib.optionalAttrs` when setting optional options, and `lib.attrByPath` when reading optional values (`lib.mkIf false` still checks option existence):

```nix
let
  hasPersistDirs = lib.hasAttrByPath [ "persist" "user" "directories" ] options;
  steamEnabled = lib.attrByPath [ "gaming" "steam" "enable" ] false config;
in
lib.optionalAttrs hasPersistDirs {
  persist.user.directories = lib.mkIf steamEnabled [ ".local/share/Steam" ];
}
```

### Eager Derivations

Keep derivations behind conditionals when they are only needed conditionally. This avoids forcing packages during standalone module evaluation.

## Secrets

- All encrypted secrets use `sops-nix` with age recipient rules in `.sops.yaml`.
- Encrypted payloads live in `secrets/shared.yaml` (cross-host) and `secrets/homelab.yaml` (homelab-only).
- Use `nix run .#bootstrapAge` to install the age private key into `~/.config/sops/age/keys.txt` and `/persist/var/lib/sops-nix/key.txt` (or `/var/lib/sops-nix/key.txt` on non-preserved hosts).
- Public SSH admin keys live in `modules/keys.mod.nix`.
- Encrypted SOPS files are safe to commit. Plaintext secrets and private keys are not.

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

## Changelog

- `CHANGELOG.md` follows Keep a Changelog and semantic versioning. Do not edit it by hand.
- Write each change that a user can see as one fragment in `changelog.d/`, in the same commit as the change. `changelog.d/README.md` gives the format.
- If a change has no effect that a user can see, write no fragment.

## Roadmap

- `ROADMAP.md` holds the planned work: `# Roadmap`, then `## Now`, `## Next` and `## Later`, each a list. An optional `## Maybe` comes last.
- Start each entry with a bold summary, then one or two sentences on what it gives the user. Give no dates. If a design exists, link its intent file.
- When a work is done, remove its entry in the same commit as its changelog fragment.

## Intent

- This repo follows https://srcmd.org. It has no `src`, so the intent folder is `docs/md/`. Read `docs/md/README.md` first.
- Change the intent first, then the Nix code. A change of design changes its intent file in the same commit.
- `docs/md/README.md` lists every other file of the folder in its `## File Index`.

## Best Practices

- Prefer small structural changes.
- Before creating a new Nix file, decide whether it is a flake-parts module or a private plain NixOS fragment.
- Keep host files thin and compose named modules explicitly.
- After changes, run `nix fmt`, `deadnix .`, `statix check .`, and `nix flake check "path:$PWD" --no-write-lock-file`.
