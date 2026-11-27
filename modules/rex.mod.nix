{inputs, ...}: {
  # Rex, the terminal and session server from Superlogical. Every host that imports this
  # module gets the rex client, its terminfo entry and its ssh guard. A host that sets
  # rex.server.enable also runs the shared server on /run/rex/server.sock.
  flake.nixosModules.rex = {
    config,
    lib,
    options,
    ...
  }: let
    cfg = config.rex;
    rexCfg = config.services.rex;
    # baseUser declares userName; flake check evaluates this module without it.
    userName = lib.attrByPath ["userName"] "sacha" config;
    hasPreservationDirs = lib.hasAttrByPath ["persist" "system" "directories"] options;
  in {
    imports = [inputs.rex.nixosModules.default];

    options.rex.server.enable = lib.mkEnableOption "the shared Rex server, run as the primary user";

    config = lib.mkMerge [
      # The upstream module installs the client only when a server mode is on.
      (lib.mkIf (!cfg.server.enable) {
        environment.systemPackages = [rexCfg.package];
        programs.ssh.extraConfig = lib.mkAfter ''
          Include ${rexCfg.package}/share/rex/ssh_config.d/50-rex.conf
        '';
      })

      (lib.mkIf cfg.server.enable {
        services.rex = {
          enable = true;
          socketActivation = true;
          # The server runs each terminal as its own account. As the rex system account, a
          # terminal has no home, no dotfiles and no sudo. As the owner, it is the owner's shell.
          user = userName;
        };

        users.users.${userName}.extraGroups = [rexCfg.group];

        # A client looks for the account's personal server under $XDG_RUNTIME_DIR/rex and
        # starts one there if none runs. This server runs as the owner, so make it his
        # personal server: every session, local or over ssh://, then reaches it, and it
        # outlives logouts without linger. The unit sets the same directory for itself.
        environment.sessionVariables.REX_RUNTIME_DIR = "/run/rex";
      })

      # Sessions survive a reboot only if their state does.
      (lib.optionalAttrs hasPreservationDirs {
        persist.system.directories = lib.mkIf cfg.server.enable ["/var/lib/rex"];
      })
    ];
  };
}
