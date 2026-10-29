import contextlib
import io
import json
import os
from pathlib import Path
import shutil
import struct
import tempfile
import unittest
from unittest.mock import patch
import zipfile

import build_local_apk as builder
from zyj_server import configuration, player


class LanBuildTests(unittest.TestCase):
    def test_account_list_uses_one_lan_endpoint_and_preserves_extra_fields(self):
        original = json.dumps({"9": {"id": 9, "name": "old", "ip": "old", "port": 1, "extra": True}}).encode()
        with contextlib.redirect_stdout(io.StringIO()):
            result = builder.patch_game_server_json(original, "192.168.1.20", 3)
        servers = json.loads(result)
        self.assertEqual(list(servers), ["1", "2", "3"])
        for account, row in servers.items():
            self.assertEqual((row["id"], row["name"]), (int(account), f"账号 {account}"))
            self.assertEqual((row["ip"], row["port"]), ("192.168.1.20", 14600))
            self.assertTrue(row["extra"])

    def test_server_address_must_be_a_lan_ipv4_not_loopback_or_public(self):
        for address in ("192.168.1.20", "10.1.2.3", "172.16.0.20"):
            self.assertEqual(builder.parse_server_ip(address), address)
        for address in ("127.0.0.1", "0.0.0.0", "8.8.8.8", "224.0.0.1", "169.254.1.2", "::1", "not-an-ip"):
            with self.subTest(address=address), self.assertRaises(ValueError):
                builder.parse_server_ip(address)

    def test_invalid_build_arguments_do_not_start_packaging(self):
        cases = ([], ["--server-ip", "127.0.0.1"], ["--server-ip", "192.168.1.20", "--accounts", "0"],
                 ["--server-ip", "192.168.1.20", "--accounts", "1001"], ["--unknown"])
        with patch.object(builder, "get_patched_lua_scripts") as build, contextlib.redirect_stderr(io.StringIO()):
            for args in cases:
                with self.subTest(args=args), self.assertRaises(SystemExit) as error:
                    builder.main(args)
                self.assertEqual(error.exception.code, 2)
            build.assert_not_called()

    def test_client_patches_select_and_remember_account_without_loopback(self):
        sources = Path(__file__).parent / "scripts_clean"

        def read_reference_script(relative):
            return (sources / (relative + ".lua")).read_text(encoding="utf-8").encode("utf-8")

        with tempfile.TemporaryDirectory() as directory:
            fixture = Path(directory) / "fixture.apk"
            log = b"function echo(...)\n    if gamedata and not gamedata.isshowlog then return end\nend\n"
            with zipfile.ZipFile(fixture, "w") as archive:
                archive.writestr("assets/common_lua/log.so", builder.xxtea_encrypt(log, builder.XXTEA_KEY))
            with patch.object(builder, "SRC_APK", str(fixture)), patch.object(builder, "read_script", side_effect=read_reference_script), contextlib.redirect_stdout(io.StringIO()):
                patched = builder.get_patched_lua_scripts()

        def decrypted(path):
            raw = builder.xxtea_decrypt(patched[path], builder.XXTEA_KEY)
            length = struct.unpack("<I", raw[-4:])[0]
            self.assertLessEqual(length, len(raw) - 4)
            self.assertEqual(raw[length:-4], b"\0" * (len(raw) - 4 - length))
            return raw[:length].decode("utf-8")

        login = decrypted("assets/scripts/accbyhttp/service_ui.so")
        enter = decrypted("assets/scripts/accbyhttp/http_entergame.so")
        network = decrypted("assets/scripts/gameserver.so")
        self.assertIn('fullPathForFilename("GameServer.json")', login)
        self.assertIn('getIntegerForKey("local_account", 1)', login)
        self.assertIn('recentlist = { ["1"] = selected }', login)
        self.assertIn('uuid = "local_account_" .. tostring(account), section = 1', enter)
        self.assertIn('tonumber(params.sid)', enter)
        self.assertIn('defaults:flush()', enter)
        self.assertNotIn("local_mock_uuid_10001", enter)
        self.assertNotIn("127.0.0.1", login + network)
        self.assertIn("host = gamedata.serverlist[tonumber(gamedata.selectserver)].ip", network)
        self.assertIn("port = gamedata.serverlist[tonumber(gamedata.selectserver)].port", network)
        self.assertNotIn("999898", network)

    def test_find_tool_supports_native_and_windows_sdk_names(self):
        for name, filename in (("zipalign", "zipalign"), ("zipalign", "zipalign.exe"),
                               ("apksigner", "apksigner"), ("apksigner", "apksigner.bat")):
            with self.subTest(filename=filename), tempfile.TemporaryDirectory() as directory:
                path = Path(directory) / "build-tools" / "35.0.0" / filename
                path.parent.mkdir(parents=True)
                path.touch()
                with patch.object(builder.shutil, "which", return_value=None), patch.dict(os.environ, {"ANDROID_HOME": directory}):
                    self.assertEqual(builder.find_tool(name), str(path))

    def test_find_tool_prefers_path(self):
        with patch.object(builder.shutil, "which", return_value="/sdk/bin/zipalign"):
            self.assertEqual(builder.find_tool("zipalign"), "/sdk/bin/zipalign")

    def test_apk_and_server_use_same_overrides_in_both_config_sections(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            config_path = root / "configs_sec5.zip"
            shutil.copyfile(Path(__file__).parent / "configs_sec5.zip", config_path)
            configs = configuration.ConfigStore(config_path)
            configs.update("props", "20014", {"param1": "37"}, configs.status()["revision"])
            with zipfile.ZipFile(root / "z7_7_4.apk", "w") as archive:
                archive.writestr("assets/GameServer.json", '{"1":{"id":1}}')
                for section in (1, 5):
                    archive.writestr(f"assets/config/{section}/props.json", "old config")
                    archive.writestr(f"assets/config/{section}/client_only.json", "{}")

            def tool(name, args):
                if name == "zipalign":
                    shutil.copyfile(args[-2], args[-1])

            with patch.object(builder, "__file__", str(root / "build_local_apk.py")), \
                    patch.object(builder, "get_patched_lua_scripts", return_value={}), \
                    patch.object(builder, "find_tool", side_effect=lambda name: name), \
                    patch.object(builder, "run_tool", side_effect=tool), \
                    patch.object(builder.subprocess, "run"), contextlib.redirect_stdout(io.StringIO()):
                builder.main(["--server-ip", "192.168.1.20", "--accounts", "2"])
            runtime = player.load_role_config(config_path)
            with zipfile.ZipFile(root / "zyj_local.apk") as archive:
                for section in (1, 5):
                    name = f"assets/config/{section}/props.json"
                    self.assertEqual(archive.namelist().count(name), 1)
                    self.assertEqual(json.loads(archive.read(name)), runtime["props"])
                    self.assertEqual(archive.read(f"assets/config/{section}/client_only.json"), b"{}")
                    with zipfile.ZipFile(config_path) as source:
                        with contextlib.redirect_stdout(io.StringIO()):
                            guide_config = builder.patch_guide_step(source.read("5/guide_step.json"))
                        self.assertEqual(archive.read(f"assets/config/{section}/guide_step.json"), guide_config)
                self.assertEqual(list(json.loads(archive.read("assets/GameServer.json"))), ["1", "2"])


if __name__ == "__main__":
    unittest.main()
