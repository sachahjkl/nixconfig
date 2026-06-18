_: {
  selectLixPackage = lixPkgs: fallback: name:
    if lixPkgs == null
    then fallback
    else lixPkgs.${name};
}
