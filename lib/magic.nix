{ lib, ... }:
let
  inherit (lib) hashString;
  inherit (lib.lists) elemAt range singleton;
  inherit (lib.strings) concatStringsSep substring stringLength;
  inherit (lib.trivial) fromHexString mod;
in
{
  mac =
    string:
    let
      CHANGE_IF_YOU_ARE_GOING_TO_COPY = "fEO2zZtXOWa5CPLAweZyjd0LqAd03N2GLuLMmQkDstlcYr8won4FMtP97JxHJ3b";

      hash =
        assert stringLength CHANGE_IF_YOU_ARE_GOING_TO_COPY == 63;
        hashString "sha256" (CHANGE_IF_YOU_ARE_GOING_TO_COPY + string);

      head =
        substring 0 1 hash
        + (elemAt [
          "2"
          "6"
          "a"
          "e"
        ]
          (mod (fromHexString (substring 1 1 hash)) 4));

      tail = map (i: substring (i * 2) 2 hash) (range 1 5);
    in
    concatStringsSep ":" (singleton head ++ tail);

  ula =
    string:
    let
      hash = hashString "sha256" string;
    in
    "fd${substring 0 2 hash}:${substring 2 4 hash}:${substring 6 4 hash}";
}
