"""Maintain OpenBao through its host-only HTTP listener."""

import json
import os
from pathlib import Path
import shutil
import sys
import urllib.request


ADDRESS = "http://127.0.0.1:8202/v1/"


def request(path, data=None, token=None):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["X-Vault-Token"] = token
    body = None if data is None else json.dumps(data).encode()
    return urllib.request.build_opener(urllib.request.ProxyHandler({})).open(
        urllib.request.Request(ADDRESS + path, data=body, headers=headers),
        timeout=120,
    )


def credential(name):
    return (Path(os.environ["CREDENTIALS_DIRECTORY"]) / name).read_text().strip()


def unseal():
    with request("sys/seal-status") as response:
        status = json.load(response)
    if not status["initialized"]:
        raise RuntimeError("OpenBao requires operator initialization.")
    if status["sealed"]:
        with request("sys/unseal", {"key": credential("unseal-key")}) as response:
            if json.load(response)["sealed"]:
                raise RuntimeError("The local key did not unseal OpenBao.")


def snapshot(directory):
    with request(
        "auth/approle/login", json.loads(credential("snapshot-approle.json"))
    ) as response:
        token = json.load(response)["auth"]["client_token"]
    target_dir = Path(directory)
    temporary = target_dir / "raft.snap.tmp"
    try:
        with request("sys/storage/raft/snapshot", token=token) as response:
            with temporary.open("wb") as output:
                shutil.copyfileobj(response, output)
                output.flush()
                os.fsync(output.fileno())
        if temporary.stat().st_size == 0:
            raise RuntimeError("OpenBao returned an empty Raft snapshot.")
        temporary.replace(target_dir / "raft.snap")
        dir_fd = os.open(target_dir, os.O_RDONLY)
        try:
            os.fsync(dir_fd)
        finally:
            os.close(dir_fd)
    finally:
        temporary.unlink(missing_ok=True)
        try:
            with request("auth/token/revoke-self", {}, token=token):
                pass
        except Exception as exc:
            print(f"Warning: failed to revoke snapshot token: {exc}", file=sys.stderr)


if __name__ == "__main__":
    if sys.argv[1:] == ["unseal"]:
        unseal()
    elif len(sys.argv) == 3 and sys.argv[1] == "snapshot":
        snapshot(sys.argv[2])
    else:
        raise SystemExit("Usage: openbao-maintenance.py unseal | snapshot DIRECTORY")
