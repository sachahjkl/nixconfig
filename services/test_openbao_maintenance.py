import io
import json
import os
from pathlib import Path
import socket
import subprocess
import tempfile
import time
import unittest
from unittest.mock import patch

import openbao_maintenance


@unittest.skipUnless(
    os.environ.get("BAO_BIN"), "BAO_BIN is required for the Raft integration test"
)
class RaftIntegrationTests(unittest.TestCase):
    def test_real_raft_unseal_and_approle_snapshot(self):
        with tempfile.TemporaryDirectory() as directory:
            with socket.socket() as listener:
                listener.bind(("127.0.0.1", 0))
                port = listener.getsockname()[1]
            with socket.socket() as listener:
                listener.bind(("127.0.0.1", 0))
                cluster_port = listener.getsockname()[1]
            root = Path(directory)
            (root / "raft").mkdir()
            configuration = {
                "audit": [
                    {
                        "type": "file",
                        "path": "host",
                        "options": {"file_path": str(root / "audit.json")},
                    }
                ],
                "api_addr": f"http://127.0.0.1:{port}",
                "cluster_addr": f"https://127.0.0.1:{cluster_port}",
                "storage": {"raft": {"path": str(root / "raft"), "node_id": "test"}},
                "listener": {
                    "tcp": {
                        "address": f"127.0.0.1:{port}",
                        "cluster_address": f"127.0.0.1:{cluster_port}",
                        "tls_disable": True,
                    }
                },
            }
            (root / "config.json").write_text(json.dumps(configuration))
            with (root / "server.log").open("wb") as log:
                server = subprocess.Popen(
                    [
                        os.environ["BAO_BIN"],
                        "server",
                        "-config",
                        str(root / "config.json"),
                    ],
                    stdout=log,
                    stderr=log,
                )
                try:
                    with patch.object(
                        openbao_maintenance, "ADDRESS", f"http://127.0.0.1:{port}/v1/"
                    ):
                        for attempt in range(100):
                            try:
                                with openbao_maintenance.request("sys/seal-status"):
                                    break
                            except OSError:
                                if server.poll() is not None or attempt == 99:
                                    self.fail((root / "server.log").read_text())
                                time.sleep(0.1)

                        def api(path, data=None, token=None):
                            with openbao_maintenance.request(
                                path, data, token
                            ) as response:
                                body = response.read()
                                return json.loads(body) if body else None

                        initial = api(
                            "sys/init", {"secret_shares": 1, "secret_threshold": 1}
                        )
                        with patch.object(
                            openbao_maintenance,
                            "credential",
                            return_value=initial["keys_base64"][0],
                        ):
                            openbao_maintenance.unseal()
                        token = initial["root_token"]
                        for attempt in range(100):
                            try:
                                api("sys/health")
                                break
                            except OSError:
                                if attempt == 99:
                                    raise
                                time.sleep(0.1)
                        api(
                            "sys/policies/acl/raft-snapshot",
                            {
                                "policy": 'path "sys/storage/raft/snapshot" { capabilities = ["read"] }'
                            },
                            token,
                        )
                        self.assertIn("host/", api("sys/audit", token=token)["data"])
                        api("sys/auth/approle", {"type": "approle"}, token)
                        api(
                            "auth/approle/role/raft-snapshot",
                            {
                                "token_policies": ["raft-snapshot"],
                                "token_ttl": "5m",
                                "token_max_ttl": "10m",
                                "secret_id_ttl": 0,
                                "secret_id_num_uses": 0,
                            },
                            token,
                        )
                        role = api(
                            "auth/approle/role/raft-snapshot/role-id", token=token
                        )
                        secret = api(
                            "auth/approle/role/raft-snapshot/secret-id", {}, token
                        )
                        credentials = json.dumps(
                            {
                                "role_id": role["data"]["role_id"],
                                "secret_id": secret["data"]["secret_id"],
                            }
                        )
                        with patch.object(
                            openbao_maintenance, "credential", return_value=credentials
                        ):
                            openbao_maintenance.snapshot(directory)
                        self.assertGreater((root / "raft.snap").stat().st_size, 0)
                finally:
                    server.terminate()
                    server.wait(timeout=10)


class MaintenanceTests(unittest.TestCase):
    def test_failed_snapshot_keeps_previous_snapshot(self):
        with tempfile.TemporaryDirectory() as directory:
            previous = Path(directory) / "raft.snap"
            previous.write_bytes(b"previous")
            responses = [
                io.BytesIO(b'{"auth": {"client_token": "test-token"}}'),
                OSError("Snapshot request failed"),
                io.BytesIO(b""),
            ]
            with patch.object(openbao_maintenance, "credential", return_value="{}"):
                with patch.object(
                    openbao_maintenance, "request", side_effect=responses
                ):
                    with self.assertRaises(OSError):
                        openbao_maintenance.snapshot(directory)
            self.assertEqual(previous.read_bytes(), b"previous")

    def test_unsealed_server_does_not_read_key(self):
        response = io.BytesIO(
            json.dumps({"initialized": True, "sealed": False}).encode()
        )
        with patch.object(openbao_maintenance, "request", return_value=response):
            with patch.object(openbao_maintenance, "credential") as credential:
                openbao_maintenance.unseal()
                credential.assert_not_called()

    def test_uninitialized_server_is_not_initialized(self):
        response = io.BytesIO(
            json.dumps({"initialized": False, "sealed": True}).encode()
        )
        with patch.object(
            openbao_maintenance, "request", return_value=response
        ) as request:
            with self.assertRaises(RuntimeError):
                openbao_maintenance.unseal()
            request.assert_called_once_with("sys/seal-status")

    def test_snapshot_is_replaced_and_token_is_revoked(self):
        responses = [
            io.BytesIO(b'{"auth": {"client_token": "test-token"}}'),
            io.BytesIO(b"snapshot"),
            io.BytesIO(b""),
        ]
        with tempfile.TemporaryDirectory() as directory:
            with patch.object(
                openbao_maintenance,
                "credential",
                return_value='{"role_id": "role", "secret_id": "secret"}',
            ):
                with patch.object(
                    openbao_maintenance, "request", side_effect=responses
                ) as request:
                    openbao_maintenance.snapshot(directory)
                    request.assert_called_with(
                        "auth/token/revoke-self", {}, token="test-token"
                    )
            self.assertEqual((Path(directory) / "raft.snap").read_bytes(), b"snapshot")
            self.assertFalse((Path(directory) / "raft.snap.tmp").exists())


if __name__ == "__main__":
    unittest.main()
