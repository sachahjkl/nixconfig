{lib, ...}: {
  isAddressV4 = address: !(lib.strings.hasInfix ":" address);
  isAddressV6 = lib.strings.hasInfix ":";
}
