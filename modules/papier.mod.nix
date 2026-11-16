{inputs, ...}: {
  # Papier, the clipboard's history (github:sachahjkl/papier): one process for
  # the graphical session, hidden in the notification area; `papier toggle`
  # shows its window. A user service, so that it starts in every session that
  # reaches graphical-session.target (Hyprland, through uwsm); the ShojiWM
  # desktop starts its own.
  flake.nixosModules.papier = {
    lib,
    pkgs,
    ...
  }: let
    papier = inputs.papier.packages.${pkgs.stdenv.hostPlatform.system}.default;
  in {
    environment.systemPackages = [papier];

    # The history itself (history.db), which the root's tmpfs would lose at
    # each boot.
    persist.user.directories = [".local/share/papier"];

    systemd.user.services.papier = {
      description = "Papier, the clipboard's history";
      wantedBy = ["graphical-session.target"];
      partOf = ["graphical-session.target"];
      after = ["graphical-session.target"];
      # The ShojiWM desktop starts its own (programs.clipboard.background).
      unitConfig.ConditionEnvironment = "!XDG_CURRENT_DESKTOP=ShojiWM";
      serviceConfig = {
        ExecStart = "${lib.getExe papier} --hidden";
        Restart = "on-failure";
      };
    };
  };
}
