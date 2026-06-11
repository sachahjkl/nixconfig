let
  inherit
    (builtins)
    attrNames
    attrValues
    concatMap
    elem
    filter
    foldl'
    listToAttrs
    match
    readDir
    readFileType
    ;

  singleton = value: [value];
  optional = condition: consequence:
    if condition
    then [consequence]
    else [];
  uniq = list:
    foldl' (acc: item:
      if elem item acc
      then acc
      else acc ++ singleton item) []
    list;

  listFilesRecursive = base: directory:
    if readFileType directory != "directory"
    then singleton base
    else let
      entries = readDir directory;
      names = attrNames entries;
    in
      concatMap
      (
        name:
          if entries.${name} == "directory"
          then listFilesRecursive "${base}/${name}" /${directory}/${name}
          else if entries.${name} == "regular"
          then singleton "${base}/${name}"
          else []
      )
      names;

  isAge = name: match ".*\\.age$" name != null;

  keysModule =
    (import ./modules/keys.mod.nix {
      self = keysModule;
    }).flake;

  inherit (keysModule) keys keys-admin;

  hostSecrets =
    concatMap
    (
      host:
        map
        (path: {
          name = path;
          value.publicKeys = uniq (optional (keys ? ${host}) keys.${host} ++ keys-admin);
        })
        (filter isAge (listFilesRecursive "hosts/${host}" ./hosts/${host}))
    )
    (attrNames (readDir ./hosts));

  moduleSecrets =
    map
    (path: {
      name = path;
      value.publicKeys = uniq (attrValues keys);
    })
    (filter isAge (listFilesRecursive "modules" ./modules));
in
  listToAttrs (hostSecrets ++ moduleSecrets)
