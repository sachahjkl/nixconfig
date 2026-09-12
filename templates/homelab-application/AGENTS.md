# Repository rules

- Run application checks on `ubuntu-latest` only.
- Never run pull request code on the homelab.
- Keep browser tests outside Nix and CI checks.
- Limit Nix to two concurrent derivations.
- Deploy immutable OCI digests only.
- Promote the exact staging digest to production.
- Keep Cloudflare credentials outside this repository.
- Use dynamic Nomad ingress ports.
- Declare exact domains in `application.yaml`.
- Keep staging responses out of search indexes.
