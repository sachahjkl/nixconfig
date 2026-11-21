{
  description = "Sacha's NixOS system configuration";

  # Flake `nixConfig` must be a literal. Keep these lists in sync with nix-config.nix.
  nixConfig = {
    extra-experimental-features = [
      "flakes"
      "nix-command"
    ];
    extra-substituters = [
      "https://cache.homelab.sacha.house"
      "https://cache.numtide.com"
      "https://nix-community.cachix.org"
      "https://sachahjkl.cachix.org"
      "https://install.determinate.systems"
    ];
    extra-trusted-public-keys = [
      "homelab-cache-1:ZaUHSv8slKsAKc9kd0AGI8p1HUjUumfho7ShgUVlnUg="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "sachahjkl.cachix.org-1:cepX7PCUV88hCchnh9prZM5V72wRkCf6oSJL6JfgWs0="
      "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-parts.url = "github:hercules-ci/flake-parts";

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";

    # main, the branch the checkout of house-desktop follows: its portal must speak
    # the same protocol as the configuration that runs. It brings ShojiWM (the
    # author's fork, its fixes waiting for review in FORK.md) and its NixOS module.
    shojiwm-desktop = {
      url = "github:sachahjkl/shojiwm-desktop";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        git-hooks.follows = "git-hooks";
        # The same programs as the rest of this system: one build of each.
        inspecteur.follows = "inspecteur";
        classeur.follows = "classeur";
        papier.follows = "papier";
        cliche.follows = "cliche";
      };
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    preservation.url = "github:nix-community/preservation";

    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hjem-rum = {
      url = "github:snugnug/hjem-rum";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.hjem.follows = "hjem";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wrapper-modules = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mt7927 = {
      url = "github:cmspam/mt7927-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hex = {
      url = "github:anomalyco/hex";
      # Hex needs rustc 1.97, and nixpkgs 26.05 has rustc 1.95.
      # The Hex nixpkgs pin has a glibc that is not older than the system glibc.
      inputs.home-manager.follows = "home-manager";
    };

    # Hokum builds with nixos-unstable's Rust, newer than nixpkgs 26.05's, so
    # it keeps its own nixpkgs, as Hex does.
    hokum.url = "github:anomalyco/hokum";

    bootvine = {
      url = "git+https://codeberg.org/wvhulle/bootvine";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    classeur = {
      url = "git+https://github.com/sachahjkl/classeur?submodules=1";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        git-hooks.follows = "git-hooks";
      };
    };

    papier = {
      url = "git+https://github.com/sachahjkl/papier?submodules=1";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        git-hooks.follows = "git-hooks";
      };
    };

    # inspecteur, the task manager of the Windows 7 configuration
    # (github:sachahjkl/inspecteur). git+https: a github: URL leaves its
    # gui_toolkit submodule out.
    inspecteur = {
      url = "git+https://github.com/sachahjkl/inspecteur?submodules=1";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        git-hooks.follows = "git-hooks";
      };
    };

    # cliche, the screen capture of the desktop (github:sachahjkl/cliche), which
    # shojiwm-desktop installs: here so that its release is this system's.
    cliche = {
      url = "git+https://github.com/sachahjkl/cliche?submodules=1";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        git-hooks.follows = "git-hooks";
      };
    };

    # feuille and socle, the other Froment Software programs: git+https for
    # their gui_toolkit submodule, as above. (atelier has no Nix package: on
    # Nix each program comes from its own flake, atelier is the other systems'
    # installer.)
    feuille = {
      url = "git+https://github.com/sachahjkl/feuille?submodules=1";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        git-hooks.follows = "git-hooks";
      };
    };

    socle = {
      url = "git+https://github.com/sachahjkl/socle?submodules=1";
      inputs = {
        bootvine.follows = "bootvine";
        determinate.follows = "determinate";
        disko.follows = "disko";
        git-hooks.follows = "git-hooks";
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
      };
    };

    modus = {
      url = "github:sachahjkl/modus";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        git-hooks.follows = "git-hooks";
      };
    };

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.flake-parts.follows = "flake-parts";
    };

    skills = {
      url = "github:sachahjkl/skills";
      inputs = {
        flake-parts.follows = "flake-parts";
        git-hooks.follows = "git-hooks";
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake
    {
      inherit inputs;

      specialArgs.lib = inputs.nixpkgs.lib.extend (
        final: prev:
          inputs.nixpkgs.lib.recursiveUpdate prev (
            import ./lib {
              lib = final;
              inherit inputs;
              inherit (inputs) self;
            }
          )
      );
    }
    (
      {lib, ...}: let
        inherit (lib.filesystem) listFilesRecursive;
        inherit (lib.lists) filter;
        inherit (lib.strings) hasSuffix;
      in {
        systems = ["x86_64-linux"];

        imports =
          [
            inputs.disko.flakeModules.default
          ]
          ++ filter (path: hasSuffix ".mod.nix" (toString path)) (listFilesRecursive ./.);
      }
    );
}
