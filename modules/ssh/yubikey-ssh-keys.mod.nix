_: {
  flake.nixosModules.yubikeySshKeys = {
    config,
    lib,
    options,
    ...
  }: let
    hasUserName = lib.hasAttrByPath ["userName"] options;
    hasHomeDirectory = lib.hasAttrByPath ["homeDirectory"] options;
    # These files are the local OpenSSH resident-key stubs created by
    # `ssh-keygen -K`, not an exportable software private key. For
    # `sk-ssh-*` keys, the actual signing/authentication secret is generated
    # and stored inside the YubiKey, and SSH operations still require the
    # hardware token to be present. The stub only contains enough metadata for
    # OpenSSH to reference that resident key again: key type, public key,
    # application string, and a hardware-backed key handle/reference. Committing
    # the stub is acceptable because it does not let someone authenticate or
    # sign without the physical YubiKey; it just saves us from rerunning
    # `ssh-keygen -K` on every fresh install.
    keyDir = ./yubikey-ssh-keys;
  in {
    config = lib.mkIf (hasUserName && hasHomeDirectory) {
      system.activationScripts.yubikeySshKeys.text = ''
        install -d -m 0700 -o ${config.userName} -g users ${config.homeDirectory}/.ssh
        install -m 0600 -o ${config.userName} -g users ${keyDir}/id_ed25519_sk ${config.homeDirectory}/.ssh/id_ed25519_sk
        install -m 0644 -o ${config.userName} -g users ${keyDir}/id_ed25519_sk.pub ${config.homeDirectory}/.ssh/id_ed25519_sk.pub
      '';
    };
  };
}
