_: {
  perSystem = {pkgs, ...}: {
    # tack writes the files in .tack, so the formatter leaves them alone.
    formatter = pkgs.writeShellApplication {
      name = "alejandra";
      runtimeInputs = [pkgs.alejandra];
      text = ''exec alejandra --exclude .tack "$@"'';
    };
  };
}
