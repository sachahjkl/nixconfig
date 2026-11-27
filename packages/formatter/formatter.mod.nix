_: {
  perSystem = {pkgs, ...}: {
    # tack writes the files in .tack, so the formatter leaves them alone.
    formatter = pkgs.writeShellApplication {
      name = "alejandra";
      runtimeInputs = [pkgs.alejandra];
      # alejandra matches excludes against the walked paths, which start with ./
      text = ''exec alejandra --exclude ./.tack "$@"'';
    };
  };
}
