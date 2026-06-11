{lib, ...}: let
  inherit (lib.attrsets) mapAttrsToList;
  inherit (lib.strings) concatLines;
  inherit (lib.lists) singleton flatten;
in {
  # CLI flag config format used by bat.
  # true -> --flag, string/int -> --flag 'value'
  toCliFlagList = attrs:
    concatLines (mapAttrsToList
      (
        name: value:
          if value == true
          then "--${name}"
          else "--${name} '${toString value}'"
      )
      attrs);

  # CLI flag config format used by ripgrep.
  # true -> --flag, string/int -> --flag<newline>value
  toCliArgumentList = attrs:
    concatLines (flatten (mapAttrsToList
      (
        name: value:
          if value == true
          then singleton "--${name}"
          else [
            "--${name}"
            (toString value)
          ]
      )
      attrs));
}
