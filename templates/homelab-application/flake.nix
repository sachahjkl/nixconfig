{
  description = "Auto-provisioned homelab application";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.2605";
    git-hooks = {
      url = "https://flakehub.com/f/cachix/git-hooks.nix/0.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    git-hooks,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfreePredicate = package: nixpkgs.lib.getName package == "nomad";
    };
    deploymentConfig = pkgs.buildGoModule {
      pname = "deployment-config";
      version = "1.0.0";
      src = ./deploy/config;
      vendorHash = "sha256-QE/EwVzMqUO24ZAl0WBibGx6x0kNo1AUTZtfnQvX50k=";
      postInstall = ''
        mv "$out/bin/config" "$out/bin/deployment-config"
      '';
    };
    root = pkgs.runCommand "homelab-application-root" {} ''
      mkdir -p "$out/etc/caddy" "$out/srv"
      cp ${./Caddyfile} "$out/etc/caddy/Caddyfile"
      cp -R ${./site}/. "$out/srv/"
    '';
    dockerImage = pkgs.dockerTools.buildLayeredImage {
      name = "homelab-application";
      tag = "latest";
      created = "1970-01-01T00:00:01Z";
      contents = [pkgs.caddy root];
      config = {
        Cmd = ["${pkgs.caddy}/bin/caddy" "run" "--config" "/etc/caddy/Caddyfile"];
        ExposedPorts."8080/tcp" = {};
      };
    };
    preCommitCheck = git-hooks.lib.${system}.run {
      package = pkgs.prek;
      src = ./.;
      hooks = {
        actionlint.enable = true;
        alejandra.enable = true;
        check-added-large-files.enable = true;
        check-merge-conflicts.enable = true;
        check-yaml.enable = true;
        end-of-file-fixer.enable = true;
        gofmt.enable = true;
        trim-trailing-whitespace.enable = true;
      };
    };
  in {
    packages.${system} = {
      default = dockerImage;
      inherit deploymentConfig dockerImage;
    };

    apps.${system}.deploymentConfig = {
      type = "app";
      program = "${deploymentConfig}/bin/deployment-config";
    };

    checks.${system} = {
      inherit dockerImage;
      deployment-config = pkgs.runCommand "deployment-config-check" {nativeBuildInputs = [deploymentConfig pkgs.nomad pkgs.nomad-pack];} ''
        cd ${self}
        export HOME="$TMPDIR"
        deployment-config validate
        image="ghcr.io/sachahjkl/example@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
        deployment-config nomad-vars staging "$image" > "$TMPDIR/staging.vars.hcl"
        deployment-config nomad-vars production "$image" > "$TMPDIR/production.vars.hcl"
        nomad-pack render deploy/nomad --var-file "$TMPDIR/staging.vars.hcl" --to-dir "$TMPDIR/staging" --auto-approve
        nomad-pack render deploy/nomad --var-file "$TMPDIR/production.vars.hcl" --to-dir "$TMPDIR/production" --auto-approve
        nomad job validate "$TMPDIR/staging/homelab-application/application.nomad"
        nomad job validate "$TMPDIR/production/homelab-application/application.nomad"

        cp -R ${self} "$TMPDIR/stateful"
        chmod -R u+w "$TMPDIR/stateful"
        cat > "$TMPDIR/stateful/application.yaml" <<'EOF'
        application:
          name: example
          port: 8080
          healthPath: /health

        domain:
          production: example.sacha.house
          staging: staging.example.sacha.house

        volume:
          mountPath: /data
        EOF
        cd "$TMPDIR/stateful"
        deployment-config validate
        deployment-config volume-spec staging > "$TMPDIR/staging.volume.hcl"
        grep -F 'name = "example-staging-data"' "$TMPDIR/staging.volume.hcl"
        deployment-config nomad-vars staging "$image" > "$TMPDIR/stateful.vars.hcl"
        nomad-pack render deploy/nomad --var-file "$TMPDIR/stateful.vars.hcl" --to-dir "$TMPDIR/stateful-pack" --auto-approve
        nomad job validate "$TMPDIR/stateful-pack/homelab-application/application.nomad"
        touch "$out"
      '';
      pre-commit = preCommitCheck;
    };

    formatter.${system} = pkgs.alejandra;

    devShells.${system}.default = pkgs.mkShell {
      packages = preCommitCheck.enabledPackages ++ [deploymentConfig pkgs.nomad pkgs.nomad-pack];
      inherit (preCommitCheck) shellHook;
    };
  };
}
