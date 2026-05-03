# Secrets

This directory stores Age-encrypted secrets committed to the repo for Sacha's
Home Manager configuration.

Do not keep raw private key material in this directory. Only the encrypted
`.age` file should be committed here.

## GPG private keys

The encrypted export for Sacha's GPG secret keys is:

- `users/sacha/secrets/sacha-gpg-private-keys.asc.age`

This secret is configured with ASCII armor, so it uses the
`-----BEGIN AGE ENCRYPTED FILE-----` format.

Create or update it with:

```sh
cd /home/sacha/Devel/dotfiles/users/sacha/secrets
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
agenix -d users/sacha/secrets/sacha-gpg-private-keys.asc.age | gpg --import
```

Or, to decrypt it manually for import:

```sh
cd /home/sacha/Devel/dotfiles/users/sacha/secrets
RULES=./secrets.nix agenix -d sacha-gpg-private-keys.asc.age > /tmp/sacha-gpg-private.key
```

Import it into your GPG keyring:

```sh
gpg --import /tmp/sacha-gpg-private.key
rm /tmp/sacha-gpg-private.key
```

## Age recipients

Recipients are declared in `users/sacha/secrets/secrets.nix`.

This setup uses your own SSH public key as the recipient used to decrypt/edit
the secret.

## Git signing

Configured in `users/sacha/home.nix`:

- `programs.git.settings.user.email`
- `programs.git.signing.key`

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

`users/sacha/home.nix` also exports `SSH_AUTH_SOCK` in Fish using:

```sh
gpgconf --list-dirs agent-ssh-socket
```

## Reference

Useful external guide/reference:

- <https://saylesss88.github.io/nix/gpg-agent.html>

This was used as a general reference for the GPG agent, SSH support, and shell
environment setup.
