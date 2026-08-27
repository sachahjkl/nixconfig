# Controlled Technical Language

Apply these rules to all technical prose. This includes responses, plans, task lists, documentation, comments, messages, reports, and commit descriptions.

Match the language that the user uses. For English, use pragmatic ASD-STE100 Simplified Technical English. For French, use the shared principles of Français rationalisé (GIFAS) and clear technical French. Do not copy English grammar rules into French when they make the text unnatural.

## Structure

- Write instructions in the imperative. Put each instruction in a separate sentence.
- Put a condition before the action: "If the build fails, read the log." In French: "Si la compilation échoue, lisez le journal."
- Limit instructions to 20 words per sentence. Limit descriptions to 25 words per sentence when practical.
- Give one fact per sentence and one topic per paragraph.
- Use lists for steps or for more than two related items.
- Use complete grammar. Do not use telegraphic fragments when they can cause ambiguity.

## Words

- Use one term for one concept. Do not rotate synonyms to add variety.
- Use short, common, and precise words. Keep necessary domain terms.
- Delete filler, promotion, hedging, and facts that the reader does not need.
- State measured properties instead of vague claims such as "robust", "powerful", "simple", or "performant".
- Prefer active voice. Name the actor when this information helps the reader.
- Use simple verb forms. In English, use only `can`, `will`, and `must` as modal verbs. Do not use `should`, `would`, `may`, `might`, or `could`.
- In French, replace vague forms such as "devrait", "pourrait", or "il se peut" with `doit`, `peut`, a condition, or a direct fact.

## Code And Names

- Apply the same terminology rules to new identifiers, file names, option names, and headings.
- Give each concept one stable name. Use that name in code and prose.
- Prefer short, specific names and complete words. Avoid unclear abbreviations and decorative synonyms.
- Follow the naming conventions and normal language of the project. Use English identifiers when the project uses English identifiers.
- Do not change established APIs, commands, identifiers, paths, quoted errors, logs, or product names only to obey this style.

Before delivery, remove ambiguity, filler, synonym rotation, hidden conditions, and sentences that exceed the limits without good reason.

## Engineering Principles

- Do not preserve backward compatibility. Remove obsolete paths instead of adding compatibility layers, fallbacks, or migrations.
- Choose the simplest implementation that fully meets current requirements. Avoid speculative abstractions, configuration, and indirection.
- Grow the system in layers. Start with the smallest end-to-end version that works.
- Add each capability to a product that already works. Never replace working behavior with unfinished complexity.
- Keep components modular and keep concerns separate.
- Prefer established, well-maintained libraries when they reduce complexity or improve reliability.
- Do not reimplement common functionality without a clear reason.
- Use existing project dependencies before writing an implementation or adding packages.
- Check dependency documentation and types before deciding that a dependency lacks a capability.
- Make architectural decisions for the long term. Do not accept temporary solutions that require later replacement.

## Project Nix Setup

- At the start of work in each project, inspect its Nix flake and development checks.
- Load the `nix-project` skill for detailed implementation and verification guidance.
- If the flake is absent or incomplete, add a backlog task and complete it during the current work.
- Expose applicable builds, tests, linters, formatters, and container images through `checks`.
- Configure appropriate `cachix/git-hooks.nix` hooks for the project languages and file formats.
- Set `package = pkgs.prek`. Do not use the Python `pre-commit` runner.
- Expose the pre-commit check through `checks` and install its hooks from the default development shell.
- Use FlakeHub URLs for public flakes that publish suitable releases.
- Use `0.2605` for Nixpkgs 26.05 projects. Use `0.1` only for Nixpkgs unstable projects.
- Keep secondary Nixpkgs inputs following the main Nixpkgs input.
- If hooks must survive garbage collection, keep `pkgs.prek` in a persistent profile or system closure.

Use this minimal pattern and adapt the hooks and checks to the project:

```nix
inputs = {
  nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.2605";
  git-hooks = {
    url = "https://flakehub.com/f/cachix/git-hooks.nix/0.1";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};

preCommitCheck = inputs.git-hooks.lib.${system}.run {
  package = pkgs.prek;
  src = ./.;
  hooks = {
    alejandra.enable = true;
    deadnix.enable = true;
    statix.enable = true;
  };
};

checks.pre-commit = preCommitCheck;
devShells.default = pkgs.mkShell {
  packages = preCommitCheck.enabledPackages;
  inherit (preCommitCheck) shellHook;
};
```
