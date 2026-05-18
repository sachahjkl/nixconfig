# Secrets

This directory is reserved for Age-encrypted secrets committed to the repo for
Sacha's NixOS/hjem configuration.

## User password hash

`user-password.hash` contains a yescrypt hash of the primary user password.
It is intentionally committed to the repo and used via `lib.fileContents` in
`nixos/base/user.nix`. The hash cannot be reversed to recover the password.

Generate or update it with:

```sh
mkpasswd -m yescrypt
```

Do not keep raw private key material in this directory. Only the encrypted
`.age` file should be committed here.

## GPG private keys

The encrypted export for Sacha's GPG secret keys is:

- `nixos/extra/secrets/sacha-gpg-private-keys.asc.age`

This secret is configured with ASCII armor, so it uses the
`-----BEGIN AGE ENCRYPTED FILE-----` format.

Create or update it with:

```sh
cd /home/sacha/Projects/dotfiles/nixos/extra/secrets
RULES=./secrets.nix agenix -e sacha-gpg-private-keys.asc.age
```

Paste an armored secret-key export into the temporary file, for example:

```sh
gpg --armor --export-secret-keys YOUR_KEY_ID
```

Once the encrypted file exists, remove any raw export you may have used during
setup and keep only the `.age` file in the repo.

If you want to import it in one go:

```sh
agenix -d nixos/extra/secrets/sacha-gpg-private-keys.asc.age | gpg --import
```

Or, to decrypt it manually for import:

```sh
cd /home/sacha/Projects/dotfiles/nixos/extra/secrets
RULES=./secrets.nix agenix -d sacha-gpg-private-keys.asc.age > /tmp/sacha-gpg-private.key
```

Import it into your GPG keyring:

```sh
gpg --import /tmp/sacha-gpg-private.key
rm /tmp/sacha-gpg-private.key
```

## Age recipients

Recipients should be declared in `nixos/extra/secrets/secrets.nix` once
secrets are wired back in.

This setup uses your own SSH public key as the recipient used to decrypt/edit
the secret.

## Git signing

Configured in `nixos/extra/hjem.nix` and the wrapped Git package:

- Git identity and signing settings in `~/.config/git/config`
- Git wrapper environment defaults

After importing the key, verify with:

```sh
gpg --list-secret-keys --with-keygrip
git config --get user.signingkey
```

## SSH via GPG

`gpg-agent` is configured with SSH support enabled.

That means:

- Git commit signing uses GPG normally
- `gpg-agent` also exposes an SSH agent socket

For actual SSH auth through GPG, the imported GPG key must contain an
authentication-capable subkey.

If SSH via GPG is reintroduced, export `SSH_AUTH_SOCK` in the fish config using:

```sh
gpgconf --list-dirs agent-ssh-socket
```

## Reference

Useful external guide/reference:

- <https://saylesss88.github.io/nix/gpg-agent.html>

This was used as a general reference for the GPG agent, SSH support, and shell
environment setup.
