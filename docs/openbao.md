# OpenBao on the homelab

OpenBao stores application secrets independently from the host SOPS secrets.
Existing applications keep their current SecretSpec and SOPS configuration until each application is migrated.

## Access and storage

- The private API and UI use `https://bao.sacha.house` on Tailscale.
- DNS resolves `bao.sacha.house` to `100.106.51.80`.
- ACME obtains the TLS certificate through Cloudflare DNS.
- The maintenance API uses HTTP on `127.0.0.1:8202` only.
- Raft data and audit logs reside in `/data/Services/openbao`.
- Root-only maintenance credentials reside in `/data/Secrets/openbao`.
- The latest consistent Raft snapshot resides in `/data/Backups/openbao/raft.snap`.

Do not expose OpenBao through the public reverse proxy or router.
Restrict TCP port 443 on the Tailscale interface before onboarding application identities.

The host holds one Shamir share with a threshold of one.
Root access to the host therefore gives access to the encrypted storage and its unseal key.
This is an accepted constraint for this single-host installation, not external auto-unseal.
The unseal timer checks every 30 seconds and unseals a sealed instance.
Stop `openbao-unseal.timer` before an intentional maintenance seal.

## Deploy and initialize

Deploy the homelab NixOS configuration before initialization.
As `sacha`, preview the DNS changes after deployment.
If the preview contains only expected changes, push the DNS configuration.

```sh
cloudflare-dns-preview
cloudflare-dns-push
```

Run these commands in an interactive root shell on the homelab.
Do not enable shell tracing.

```sh
sudo -i
set -o pipefail
umask 077
export BAO_ADDR=http://127.0.0.1:8202
bao status
```

An uninitialized or sealed instance makes `bao status` exit with status 2.
Initialize only a new instance.
Never initialize over restored storage.

```sh
bao operator init -key-shares=1 -key-threshold=1 -format=json \
  > /data/Secrets/openbao/bootstrap.json
python3 - <<'PY'
import json
from pathlib import Path
directory = Path('/data/Secrets/openbao')
bootstrap = json.loads((directory / 'bootstrap.json').read_text())
key = directory / 'unseal-key'
with key.open('x') as output:
    output.write(bootstrap['unseal_keys_b64'][0] + '\n')
key.chmod(0o400)
PY
systemctl start openbao-unseal.service
export BAO_TOKEN="$(python3 -c 'import json; print(json.load(open("/data/Secrets/openbao/bootstrap.json"))["root_token"])')"
bao secrets enable -path=secret kv-v2
```

The bootstrap file contains both the unseal key and the initial root token.
Store an offline copy of the unseal key before removing the bootstrap file.
Do not commit either file or print its contents into deployment logs.

## Configure snapshots

Create a read-only snapshot policy and a dedicated AppRole.
The host stores the AppRole credentials, not a root token.
Each backup obtains a short-lived token and revokes it after use.

```sh
bao policy write raft-snapshot - <<'HCL'
path "sys/storage/raft/snapshot" {
  capabilities = ["read"]
}
HCL
bao auth enable approle
bao write auth/approle/role/raft-snapshot \
  token_policies=raft-snapshot token_ttl=5m token_max_ttl=10m \
  secret_id_ttl=0 secret_id_num_uses=0
bao read -format=json auth/approle/role/raft-snapshot/role-id \
  > /data/Secrets/openbao/snapshot-role.json
bao write -f -format=json auth/approle/role/raft-snapshot/secret-id \
  > /data/Secrets/openbao/snapshot-secret.json
python3 - <<'PY'
import json
from pathlib import Path
directory = Path('/data/Secrets/openbao')
role = json.loads((directory / 'snapshot-role.json').read_text())
secret = json.loads((directory / 'snapshot-secret.json').read_text())
credentials = directory / 'snapshot-approle.json'
with credentials.open('x') as output:
    json.dump({'role_id': role['data']['role_id'], 'secret_id': secret['data']['secret_id']}, output)
credentials.chmod(0o400)
(directory / 'snapshot-role.json').unlink()
(directory / 'snapshot-secret.json').unlink()
PY
systemctl start openbao-snapshot.service
systemctl status openbao-snapshot.service
```

Snapshots run daily at 03:30 and before each Restic backup.
Restic excludes the live Raft directory and includes the snapshot directory.
Until the AppRole credentials exist, systemd skips snapshot creation.
Do not put application secrets into OpenBao before the first successful snapshot and Restic backup.
Restic also backs up the local unseal key through `/data/Secrets`.
Protect the Restic repository password separately from its stored backups.

## Configure operator access

Create a userpass operator account before revoking the initial root token.
The operator policy grants administrative access with expiring tokens.
The password stays outside command arguments and shell history.

```sh
bao policy write operator - <<'HCL'
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo", "patch"]
}
HCL
bao auth enable userpass
python3 - <<'PY' | bao write auth/userpass/users/sacha -
import getpass
import json
password = getpass.getpass('OpenBao operator password: ')
confirmation = getpass.getpass('Confirm password: ')
if not password or password != confirmation:
    raise SystemExit('Passwords do not match or are empty.')
print(json.dumps({'password': password, 'token_policies': ['operator'], 'token_ttl': '1h', 'token_max_ttl': '8h'}))
PY
```

In another terminal, verify login through the private TLS endpoint.

```sh
export BAO_ADDR=https://bao.sacha.house
bao login -method=userpass username=sacha
bao secrets list
```

After operator access works, revoke the initial root token.
Remove `bootstrap.json` from the host after saving the required offline recovery information.

```sh
bao token revoke -self
unset BAO_TOKEN
```

## Future application integration

SecretSpec can use its `vault` provider against OpenBao's KV v2 API.
Verify that each application's SecretSpec build includes the Vault provider.

```toml
[providers]
bao_production = "vault://bao.sacha.house:443/secret"
```

SecretSpec stores each value under `secret/data/secretspec/PROJECT/PROFILE/KEY`, in the `value` field.
Use separate policies for each project and profile.
Do not give application identities a root token or the snapshot AppRole.

Configure JWT authentication using Nomad workload identities during application onboarding.
Bind each role to the expected audience, namespace, job, and task claims.
This installation does not yet configure Nomad authentication or migrate application secrets.
Remove the age key mount from an application only after its OpenBao authentication and restart tests pass.

## Recovery

Test recovery on an isolated OpenBao instance before relying on this backup.
Keep the restored instance off the application network during the test.
Use the same OpenBao version as the source snapshot initially.
Restore `raft.snap` with `bao operator raft snapshot restore`.
If the target instance has different seal keys, use `-force` and retain the original snapshot's unseal key.
Unseal the restored storage with the original key.
Verify authenticated KV reads before restoring application access.
The snapshot does not contain external audit files or host maintenance credentials.
Restore those files separately from Restic when required.
