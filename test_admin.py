from contextlib import redirect_stdout
import copy
import http.client
import io
import json
import os
from pathlib import Path
import shutil
import struct
import tempfile
import threading
import unittest
from unittest.mock import patch

from zyj_server import accounts, configuration, guide, player, protocol, replay, storage
from zyj_server.admin import views
from zyj_server.admin.http import start_admin
from zyj_server.session import Session

ROOT = Path(__file__).parent
PASSWORD = "test-password-123"


def setUpModule():
    global TABLES, COUNTS, CONFIG, SAVE
    with redirect_stdout(io.StringIO()), tempfile.TemporaryDirectory() as directory:
        COUNTS = guide.load_guide_step_counts(ROOT / "configs_sec5.zip")
        CONFIG = player.load_role_config(ROOT / "configs_sec5.zip")
        frames = replay.load_recordings(ROOT / "recorded_frames.json")
        TABLES = replay.build_routing_tables(frames)
        session = Session(TABLES, Path(directory) / "role_save.json", COUNTS, CONFIG)
        for frame in replay.split_recordings(frames)[0]:
            if frame["c2s"] and frame["opcode"] != 1000:
                session.handle(frame["opcode"], frame["seq"], bytes.fromhex(frame["hex"]))
        SAVE = session.save


class AdminFixture(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name)
        self.store = accounts.AccountStore(self.root / "role_save.json", TABLES, COUNTS, CONFIG)
        self.config_path = self.root / "configs_sec5.zip"
        shutil.copyfile(ROOT / "configs_sec5.zip", self.config_path)
        self.configs = configuration.ConfigStore(self.config_path)
        quiet = redirect_stdout(io.StringIO())
        quiet.__enter__()
        self.addCleanup(quiet.__exit__, None, None, None)

    def save(self, account=1):
        data = copy.deepcopy(SAVE)
        data["role_name"] = f"测试账号{account}"
        self.assertTrue(player.save_role(data, self.store.path(account), COUNTS))
        return self.store.path(account).read_bytes()

    def maintain(self, action, account=1, backup_id=None):
        return self.store.maintain(account, action, self.store.snapshot(account)["revision"], backup_id)


class GuildTests(AdminFixture):
    def setUp(self):
        super().setUp()
        self.now = 1793430000
        self.clock = patch("time.time", return_value=self.now).start()
        self.addCleanup(patch.stopall)
        patch.object(self.store, "authenticate", return_value=None).start()
        self.sessions = {}
        self.seq = 30000
        for account in (1, 2, 3):
            self.add_account(account)

    def add_account(self, account):
        data = json.loads(self.save(account))
        data["created_at"] = self.now - 3600 + account
        data["role_state"].update(level=19, gold=10000, nextexp=CONFIG["role_exp"]["19"]["nextexp"])
        self.assertTrue(player.save_role(data, self.store.path(account), COUNTS))
        self.sessions[account] = self.store.open_session(account, PASSWORD, ("phone", account))
        self.addCleanup(self.store.close_session, account)

    def request(self, account, opcode, values=None, text=None, raw=None):
        if raw is None:
            raw = (protocol.encode_pb_field(1, 2, protocol.encode_pb_field(2, 2, text.encode())) if text is not None
                   else b"".join(protocol.encode_pb_field(1, 0, v) for v in (values or [])))
        self.seq += 1
        packets = self.sessions[account].handle(opcode, self.seq, raw)
        return [(struct.unpack(">IIII", p[:16])[2], p[16:]) for p in packets]

    def success(self, account, opcode, **kwargs):
        packets = self.request(account, opcode, **kwargs)
        self.assertEqual(packets[0][0], opcode, packets)
        return packets[0][1]

    def guild_id(self, account):
        rows = self.business_rows(self.success(account, 2230))
        if 1 not in rows:
            return 0
        first = next(v for n, w, v in protocol.iter_pb_fields(rows[1]) if (n, w) == (1, 2))
        return protocol.pb_get_varint(first, 1)

    def business_rows(self, body):
        rows = {}
        for n, w, value in protocol.iter_pb_fields(body):
            self.assertEqual((n, w), (1, 2))
            fields = list(protocol.iter_pb_fields(value))
            self.assertEqual([f[:2] for f in fields], [(1, 0), (2, 2)])
            rows[fields[0][2]] = fields[1][2]
        return rows

    def create(self, account=1, name="测试公会"):
        self.assertEqual(protocol.parse_ids_pb(self.success(account, 2231, text=name)), [0])
        return self.guild_id(account)

    def test_entry_create_search_and_reconnect_use_real_membership(self):
        self.assertEqual(self.guild_id(1), 0)
        self.assertEqual(self.success(1, 2232), b"")
        gid = self.create()
        self.assertGreater(gid, 0)
        self.assertEqual(self.store.snapshot(1)["save"]["role_state"]["gold"], 9000)
        self.assertTrue(self.success(2, 2232))
        self.assertTrue(self.success(2, 2243, text="测试公会"))
        self.assertFalse(self.success(2, 2243, text="不存在"))
        self.assertEqual(self.request(1, 2231, text="重复创建")[0][0], 999999)
        self.store.close_session(1)
        self.sessions[1] = self.store.open_session(1, PASSWORD, ("reconnect", 1))
        self.assertEqual(self.guild_id(1), gid)
        self.assertEqual(self.sessions[1].save["role_state"]["gold"], 9000)
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 2265)), [0, 19])

    def test_native_application_approval_cancel_and_rejection(self):
        gid = self.create()
        self.assertEqual(protocol.parse_ids_pb(self.success(2, 2233, values=[gid])), [0])
        self.assertTrue(self.success(1, 2234))
        self.success(2, 2267, values=[gid])
        self.assertFalse(self.success(1, 2234))
        self.success(2, 2233, values=[0])
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 2235, values=[1000002, 1])), [2005])
        self.assertEqual(self.guild_id(2), 0)
        self.success(2, 2233, values=[gid])
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 2235, values=[1000002, 0])), [0])
        self.assertEqual(self.guild_id(2), gid)
        self.assertFalse(self.success(1, 2234))
        self.assertEqual(self.request(1, 2235, values=[1000002, 0])[0][0], 999999)
        self.assertEqual(self.store.snapshot(2)["save"]["role_state"]["gold"], 10000)

    def test_member_permissions_promotion_transfer_kick_and_disband(self):
        gid = self.create()
        self.success(1, 2265, values=[1, 19])
        for account in (2, 3):
            self.assertEqual(protocol.parse_ids_pb(self.success(account, 2233, values=[gid])), [1])
        for op, args in ((2237, {"text": "越权"}), (2239, {"values": [0, 1000003]}),
                         (2240, {"values": [1000003]}), (2241, {"values": [1000003]}), (2266, {})):
            self.assertEqual(self.request(2, op, **args)[0][0], 999999)
        self.success(1, 2239, values=[0, 1000002])
        self.success(2, 2237, text="新公告")
        self.assertEqual(self.request(2, 2240, values=[1000001])[0][0], 999999)
        self.success(2, 2240, values=[1000003])
        self.assertEqual(self.guild_id(3), 0)
        self.assertEqual(self.request(1, 2266)[0][0], 999999)
        self.success(1, 2241, values=[1000002])
        members = self.business_rows(self.success(2, 2236))
        own_rid = protocol.pb_get_varint(bytes.fromhex(self.sessions[2].save["role_snapshot"]), 1)
        self.assertEqual(protocol.parse_ids_pb(members[0])[0], own_rid)
        self.success(1, 2242)
        self.success(2, 2266)
        self.assertEqual(self.guild_id(2), 0)
        self.assertEqual(self.success(3, 2232), b"")

    def test_limits_cooldown_and_identity_survive_restart_and_rollback(self):
        gid = self.create()
        self.success(1, 2265, values=[1, 20])
        self.assertEqual(self.request(2, 2233, values=[gid])[0][0], 999999)
        self.success(1, 2265, values=[1, 19])
        with patch.dict(CONFIG["gang2_level"]["1"], people=1):
            self.assertEqual(self.request(2, 2233, values=[gid])[0][0], 999999)
        self.success(2, 2233, values=[gid])
        self.success(2, 2242)
        self.assertEqual(self.request(2, 2233, values=[gid])[0][0], 999999)
        self.clock.return_value += int(CONFIG["global_kv"]["gang_quit_limit"]["value"])
        self.success(2, 2233, values=[gid])
        self.clock.return_value -= 100
        self.success(2, 2242)
        self.assertEqual(self.request(2, 2233, values=[gid])[0][0], 999999)
        self.sessions[1].save["created_at"] += 1000
        player.save_role(self.sessions[1].save, self.store.path(1), COUNTS)
        self.assertEqual(self.guild_id(1), 0)

    def test_untrusted_parameters_names_and_foreign_targets_never_spend(self):
        for body in (b"", b"\x08\x01", b"\x0a\x00", b"\x0a\x02\x12\xff"):
            self.assertEqual(self.request(1, 2231, raw=body)[0][0], 999999)
        for name in ("", " ", "x" * 13, "bad\nname"):
            self.assertEqual(self.request(1, 2231, text=name)[0][0], 999999)
        self.assertEqual(self.sessions[1].save["role_state"]["gold"], 10000)
        self.create()
        for opcode, raw in ((2230, b"\x08\x00"), (2232, b"\x08\x01"), (2239, b"\x08\x00"),
                            (2240, b"\x08\x01"), (2265, b"\x08\x02\x08\x13")):
            before = (self.root / "guilds.json").read_bytes()
            self.assertEqual(self.request(1, opcode, raw=raw)[0][0], 999999)
            self.assertEqual((self.root / "guilds.json").read_bytes(), before)

    def test_exact_ten_query_preload_and_initialization_refresh_membership(self):
        gid = self.create()
        ids = (2313, 4800, 6911, 3210, 7002, 2230, 2037, 2039, 6501, 6810)
        body = b"".join(protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, mid)) for mid in ids)
        rows = protocol.get_comb_messages(self.success(1, 999900, raw=body))
        self.assertEqual([mid for mid, _ in rows], list(ids))
        self.assertEqual(dict(rows)[2230], self.success(1, 2230))
        initial = next(f for f in replay.load_recordings(ROOT / "recorded_frames.json")
                       if f["c2s"] and f["opcode"] == 999900 and 1001 in protocol.get_comb_ids(bytes.fromhex(f["hex"])))
        rows = dict(protocol.get_comb_messages(self.success(1, 999900, raw=bytes.fromhex(initial["hex"]))))
        self.assertEqual(rows[2230], self.success(1, 2230))
        self.assertEqual(self.guild_id(1), gid)
        for invalid in (body + b"\x10\x01", body + body[:5], body.replace(b"\x0a\x03\x08\xb6\x11", b"\x0a\x05\x08\xb6\x11\x18\x01")):
            self.assertEqual(self.request(1, 999900, raw=invalid)[0][0], 999999)

    def test_failed_creation_save_and_publish_recover_without_free_guild_or_double_charge(self):
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 2231, text="未扣款")
        self.assertEqual(self.sessions[1].save["role_state"]["gold"], 10000)
        self.assertEqual(self.guild_id(1), 0)
        original = storage.atomic_write

        def fail_publish(path, raw):
            state = json.loads(raw) if Path(path).name == "guilds.json" else {}
            if state.get("guilds") and not any(g.get("pending") for g in state["guilds"].values()):
                raise OSError("publish failed")
            return original(path, raw)

        with patch.object(storage, "atomic_write", side_effect=fail_publish), self.assertRaises(OSError):
            self.request(1, 2231, text="已扣款待恢复")
        self.store.close_session(1)
        self.sessions[1] = self.store.open_session(1, PASSWORD, ("reconnect", 1))
        self.assertGreater(self.guild_id(1), 0)
        self.assertEqual(self.sessions[1].save["role_state"]["gold"], 9000)

    def test_concurrent_duplicate_names_and_corrupt_journal_fail_closed(self):
        barrier = threading.Barrier(2)
        result = []
        def create(account):
            barrier.wait(5)
            result.append(self.request(account, 2231, text="同名公会")[0][0])
        threads = [threading.Thread(target=create, args=(a,)) for a in (1, 2)]
        for t in threads:
            t.start()
        for t in threads:
            t.join(10)
            self.assertFalse(t.is_alive())
        self.assertCountEqual(result, [2231, 999999])
        self.assertEqual(sum(self.store.snapshot(a)["save"]["role_state"]["gold"] for a in (1, 2)), 19000)
        (self.root / "guilds.json").write_text('{"guilds": null}')
        self.assertEqual(self.request(3, 2231, text="损坏时不得创建")[0][0], 999999)
        self.assertEqual(self.sessions[3].save["role_state"]["gold"], 10000)

    def test_creation_cost_and_failed_draft_preserve_pending_applications(self):
        gid = self.create()
        self.success(2, 2233, values=[gid])
        data = self.sessions[2].save
        data["role_snapshot"] = protocol.pb_set_varint(bytes.fromhex(data["role_snapshot"]), 22, self.now - 3600).hex()
        self.sessions[2].save["role_state"]["gold"] = 999
        before = copy.deepcopy(self.sessions[2].save)
        journal = (self.root / "guilds.json").read_bytes()
        self.assertEqual(self.request(2, 2231, text="余额不足")[0][0], 999999)
        self.assertEqual(self.sessions[2].save, before)
        self.assertEqual((self.root / "guilds.json").read_bytes(), journal)
        self.sessions[2].save["role_state"]["gold"] = 10000
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(2, 2231, text="失败草稿")
        self.assertTrue(self.success(1, 2234))
        packets = self.request(2, 2231, text="独立公会")
        self.assertEqual([op for op, _ in packets[:2]], [2231, 1001])
        self.assertEqual(protocol.pb_get_varint(packets[1][1], 9), 9000)
        self.assertFalse(self.success(1, 2234))
        self.assertEqual(self.sessions[2].save["activity_state"]["gold_spent"], 1000)

    def test_parallel_approvals_cannot_join_two_guilds(self):
        self.create(1, "第一公会")
        self.create(2, "第二公会")
        self.success(3, 2233, values=[0])
        barrier, results = threading.Barrier(2), []
        def approve(account):
            barrier.wait(5)
            results.append(self.request(account, 2235, values=[1000003, 0])[0][0])
        threads = [threading.Thread(target=approve, args=(a,)) for a in (1, 2)]
        for t in threads:
            t.start()
        for t in threads:
            t.join(10)
            self.assertFalse(t.is_alive())
        self.assertCountEqual(results, [2235, 999999])
        state = json.loads((self.root / "guilds.json").read_bytes())
        self.assertEqual(sum("3" in g["members"] for g in state["guilds"].values()), 1)
        self.assertFalse(self.success(1, 2234))
        self.assertFalse(self.success(2, 2234))

    def test_parallel_auto_join_respects_last_slot_and_failed_membership_write(self):
        gid = self.create()
        self.success(1, 2265, values=[1, 19])
        original = (self.root / "guilds.json").read_bytes()
        with patch.object(storage, "atomic_write", side_effect=OSError("disk full")), self.assertRaises(OSError):
            self.request(2, 2233, values=[gid])
        self.assertEqual((self.root / "guilds.json").read_bytes(), original)
        self.assertEqual(self.guild_id(2), 0)
        barrier, results = threading.Barrier(2), []
        def join(account):
            barrier.wait(5)
            results.append(self.request(account, 2233, values=[gid])[0][0])
        threads = [threading.Thread(target=join, args=(a,)) for a in (2, 3)]
        with patch.dict(CONFIG["gang2_level"]["1"], people=2):
            for t in threads:
                t.start()
            for t in threads:
                t.join(10)
                self.assertFalse(t.is_alive())
        self.assertCountEqual(results, [2233, 999999])

    def test_corrupt_role_or_missing_guild_file_never_erases_membership(self):
        self.create()
        original = self.store.path(1).read_bytes()
        journal = (self.root / "guilds.json").read_bytes()
        for broken in ({}, {"has_role": True}, {**json.loads(original), "created_at": None},
                       {**json.loads(original), "guild_creations": "invalid"}):
            self.store.path(1).write_text(json.dumps(broken))
            self.assertEqual(self.request(2, 2232)[0][0], 999999)
            self.assertEqual((self.root / "guilds.json").read_bytes(), journal)
        self.store.path(1).write_bytes(original)
        (self.root / "guilds.json").unlink()
        self.assertEqual(self.request(2, 2231, text="不能重置数据库")[0][0], 999999)
        self.assertFalse((self.root / "guilds.json").exists())

    def test_process_restart_and_recreated_leader_keep_other_members(self):
        gid = self.create()
        self.success(1, 2265, values=[1, 19])
        self.success(2, 2233, values=[gid])
        self.store.close_session(1)
        self.maintain("reset", 1)
        restarted = accounts.AccountStore(self.store.save_path, TABLES, COUNTS, CONFIG)
        with patch.object(restarted, "authenticate", return_value=None):
            self.sessions[2] = restarted.open_session(2, PASSWORD, ("restarted", 2))
        self.assertEqual(self.guild_id(2), gid)
        self.add_account(1)
        self.assertEqual(self.guild_id(1), 0)
        posts = protocol.parse_ids_pb(self.business_rows(self.success(2, 2236))[0])
        own = protocol.pb_get_varint(bytes.fromhex(self.sessions[2].save["role_snapshot"]), 1)
        self.assertEqual(posts, [own, 0, 0, 0])

    def test_native_lua_callbacks_decode_guild_rows_and_charge_once(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("公会客户端回调验证需本机已有 lupa.lua51")
        if not (ROOT / "z7_7_4.apk").exists():
            self.skipTest("原始 APK 未提供")
        from build_local_apk import read_script
        lua = LuaRuntime()

        def decode(kind, raw):
            fields = list(protocol.iter_pb_fields(bytes.fromhex(raw)))
            if kind == "Ids":
                result = {"ids": [v for n, w, v in fields if (n, w) == (1, 0)]}
            elif kind == "Result":
                result = {"result": bool(dict((n, v) for n, w, v in fields)[1])}
            elif kind == "ParamS":
                result = {"params": [{"i" if w == 0 else "s": v if w == 0 else v.decode()
                                      for n, w, v in protocol.iter_pb_fields(value)} for _, _, value in fields]}
            elif kind == "CombMessages":
                result = {"messages": [{"id": mid, "data": body.hex()} for mid, body in self.business_rows(bytes.fromhex(raw)).items()]}
            else:
                self.assertEqual(kind, "Players")
                names = {1: "rid", 2: "name", 3: "level", 4: "vip", 5: "profile", 7: "param", 8: "params"}
                result = {"players": [{names[n]: decode("ParamS", v.hex()) if n == 8 else v.decode() if n == 2 else v
                                        for n, w, v in protocol.iter_pb_fields(value)} for _, _, value in fields]}
            return lua.table_from(result, recursive=True)

        lua.globals().decode = decode
        lua.execute('''
            print, printT, cclog = function() end, function() end, function() end
            for mod,kind in pairs({ids_pb="Ids",result_pb="Result",params_pb="ParamS",combmessages_pb="CombMessages",
                players_pb="Players",gangstatus_pb="GangStatus",gangbroadcasts_pb="GangBroadcasts",
                stringcontent_pb="StringContent",gangs_pb="Gangs",gangmembers_pb="GangMembers",somethings_pb="SomeThings"}) do
                local name=kind
                package.preload[mod]=function() return {[name]=function() return {
                    ParseFromString=function(self,raw) for k,v in pairs(decode(name,raw)) do self[k]=v end end} end} end
            end
            gamedata={ext={},cache={role={gold=10000,level=19},gang2status={}},
                config={global_kv={gang_establish_coin={value="1000"}}},sortData=function() end}
            function gamedata:updateRoleGold(value) self.cache.role.gold=self.cache.role.gold+value end
            for _,mod in ipairs({"worldboss1_pb","worldboss1realnotify_pb","PickBattleResultReport"}) do
                package.preload[mod]=function() return {} end
            end
        ''')
        source = read_script("gamedata").decode()
        lua.execute(source[source.index("function gamedata.Gang2Status("):source.index("function gamedata.gangData(")])
        lua.execute(source[source.index("function gamedata.playerdata("):source.index("function gamedata.players(")])
        lua.execute(read_script("GameGang").decode())

        def callback(name, body):
            return lua.globals()[name](lua.table_from({"rbuf": body.hex()}))

        callback("NetUserGang2CallBack", self.success(1, 2230))
        self.assertIsNone(lua.globals().gamedata.cache.gang2status.id)
        packets = self.request(1, 2231, text="原生解析公会")
        self.assertEqual(callback("NetUserGang2CreateCallBack", packets[0][1]).result, 0)
        self.assertEqual(lua.globals().gamedata.cache.role.gold, protocol.pb_get_varint(packets[1][1], 9))
        gid = self.guild_id(1)
        callback("NetUserGang2CallBack", self.success(1, 2230))
        self.assertEqual(lua.globals().gamedata.cache.gang2status.id, gid)
        self.assertEqual(callback("NetUserGang2ListCallBack", self.success(2, 2232)).gangs[1].name, "原生解析公会")
        self.assertEqual(len(callback("NetUserGang2SearchCallBack", self.success(2, 2243, text="不存在")).gangs), 0)
        self.success(2, 2233, values=[gid])
        applicants = callback("NetUserGang2ReqQueryCallBack", self.success(1, 2234)).players
        self.assertEqual((applicants[1].rid, applicants[1].name, applicants[1].level), (1000002, "测试账号2", 19))
        self.success(1, 2235, values=[1000002, 0])
        result = callback("NetUserGang2MemberCallBack", self.success(1, 2236))
        self.assertEqual(len(result.gangmembers), 2)
        self.assertEqual(result.gangmembers[1].rid, result.gang2post.post1)
        self.assertEqual(result.gangmembers[2].rid, 1000002)
        self.success(2, 2242)
        self.success(1, 2266)
        callback("NetUserGang2CallBack", self.success(1, 2230))
        self.assertIsNone(lua.globals().gamedata.cache.gang2status.id)


class AccountMaintenanceTests(AdminFixture):
    def test_live_sessions_block_all_maintenance_without_blocking_other_accounts(self):
        before = self.save()
        self.save(2)
        self.store.register(1, PASSWORD, self.store.snapshot(1)["revision"])
        self.store.open_session(1, PASSWORD, ("phone", 1234))
        self.addCleanup(self.store.close_session, 1)
        for action in ("backup", "reset", "reset-guide", "restore"):
            with self.subTest(action=action), self.assertRaisesRegex(ValueError, "在线"):
                self.maintain(action)
        with self.assertRaisesRegex(ValueError, "在线"):
            self.store.open_session(1, PASSWORD, ("emulator", 1235))
        snapshot = self.store.snapshot(1)
        self.assertTrue(snapshot["online"])
        self.assertEqual(snapshot["connection"]["address"], "phone")
        self.assertIsNotNone(self.maintain("backup", 2)["backup_id"])
        self.assertEqual(self.store.path(1).read_bytes(), before)

    def test_login_waits_until_reset_and_its_backup_are_complete(self):
        self.save()
        self.store.register(1, PASSWORD, self.store.snapshot(1)["revision"])
        entered, release, connected = threading.Event(), threading.Event(), threading.Event()
        errors, sessions = [], []
        real_backup = storage.backup

        def blocked_backup(*args):
            entered.set()
            if not release.wait(5):
                raise TimeoutError("maintenance was not released")
            return real_backup(*args)

        def reset():
            try:
                self.maintain("reset")
            except Exception as error:
                errors.append(error)

        def login():
            try:
                sessions.append(self.store.open_session(1, PASSWORD, ("phone", 0)))
                connected.set()
            except Exception as error:
                errors.append(error)

        with patch.object(storage, "backup", side_effect=blocked_backup):
            worker = threading.Thread(target=reset)
            client = threading.Thread(target=login)
            worker.start()
            try:
                self.assertTrue(entered.wait(3))
                client.start()
                self.assertFalse(connected.wait(.05))
            finally:
                release.set()
                worker.join(5)
                if client.ident is not None:
                    client.join(5)
                self.store.close_session(1)
        self.assertFalse(worker.is_alive() or client.is_alive())
        self.assertEqual(errors, [])
        self.assertTrue(connected.is_set())
        self.assertFalse(sessions[0].save["has_role"])

    def test_reset_restore_and_guide_reset_preserve_other_accounts_and_backups(self):
        first, second = self.save(), self.save(2)
        result = self.maintain("reset", 2)
        backup_id = result["backup_id"]
        self.assertEqual((self.root / "backups/accounts/2" / (backup_id + ".json")).read_bytes(), second)
        self.assertFalse(self.store.path(2).exists())
        self.assertIn(2, self.store.account_ids())
        self.maintain("restore", 2, backup_id)
        restored = self.store.snapshot(2)["save"]
        for key in ("world_state", "role_state", "guide", "activity_state", "stamina_clock"):
            self.assertEqual(restored[key], json.loads(second)[key])
        self.maintain("reset-guide", 2)
        current = self.store.snapshot(2)["save"]
        self.assertEqual(current["guide"], {"sections": {}})
        for key in ("world_state", "role_state", "activity_state", "has_role"):
            self.assertEqual(current[key], restored[key])
        self.assertEqual(self.store.path(1).read_bytes(), first)

    def test_stale_revision_bad_backup_and_failed_writes_leave_original_intact(self):
        before = self.save()
        with self.assertRaisesRegex(ValueError, "变化"):
            self.store.maintain(1, "reset", "stale")
        for backup_id in ("../role_save", "0" * 32):
            with self.subTest(backup_id=backup_id), self.assertRaises(ValueError):
                self.maintain("restore", backup_id=backup_id)
        with patch.object(storage, "backup", side_effect=OSError("disk full")), self.assertRaises(OSError):
            self.maintain("reset")
        self.assertEqual(self.store.path(1).read_bytes(), before)
        original_replace = storage.os.replace

        def fail_save(source, target):
            if Path(target) == self.store.path(1):
                raise OSError("save disk full")
            return original_replace(source, target)

        with patch.object(storage.os, "replace", side_effect=fail_save), self.assertRaises(OSError):
            self.maintain("reset-guide")
        self.assertEqual(self.store.path(1).read_bytes(), before)
        self.assertEqual(len(self.store.backups(1)), 1)
        self.assertEqual(sorted(p.name for p in self.root.iterdir()), ["backups", "configs_sec5.zip", "role_save.json"])

    def test_invalid_restores_are_validated_before_replacing_or_backing_up(self):
        before = self.save()
        invalid = json.loads(before)
        invalid["world_state"]["1200"] = "broken"
        backup_id = storage.backup(self.root / "backups/accounts/1", json.dumps(invalid).encode())
        with self.assertRaises(ValueError):
            self.maintain("restore", backup_id=backup_id)
        self.assertEqual(self.store.path(1).read_bytes(), before)
        self.assertEqual(len(self.store.backups(1)), 1)

    def test_dashboard_reads_zero_balances_roster_and_copy_progress_without_settlement(self):
        self.save()
        data = self.store.snapshot(1)["save"]
        data["role_state"]["gold"] = 0
        self.assertTrue(player.save_role(data, self.store.path(1), COUNTS))
        before = self.store.path(1).read_bytes()
        snapshot = self.store.snapshot(1)
        result = views.detail(snapshot, COUNTS, CONFIG)
        self.assertIsNone(result["error"])
        self.assertEqual(result["gold"], 0)
        self.assertTrue(result["generals"] and result["equipment"] and result["inventory"])
        self.assertEqual(len({r["iid"] for r in result["generals"]}), len(result["generals"]))
        self.assertTrue(any(r["position"] == 1 for r in result["generals"]))
        self.assertGreaterEqual(next(r for r in result["copies"] if r["id"] == 42101)["stars"], 15)
        self.assertEqual(self.store.path(1).read_bytes(), before)
        self.assertEqual(snapshot["save"], json.loads(before))

    def test_corrupt_save_is_visible_and_can_be_backed_up_before_restore(self):
        self.store.path(1).write_bytes(b"{")
        snapshot = self.store.snapshot(1)
        self.assertIsNotNone(views.detail(snapshot, COUNTS, CONFIG)["error"])
        backup_id = self.maintain("backup")["backup_id"]
        self.assertEqual((self.root / "backups/accounts/1" / (backup_id + ".json")).read_bytes(), b"{")
        self.store.register(1, PASSWORD, self.store.snapshot(1)["revision"])
        with self.assertRaises(ValueError):
            self.store.open_session(1, PASSWORD, ("phone", 0))
        self.assertEqual(self.store.active, {})


class AccountAuthenticationTests(AdminFixture):
    def register(self, account=1, password=PASSWORD):
        return self.store.register(account, password, self.store.snapshot(account)["revision"])

    def test_binding_preserves_old_progress_and_survives_store_restart(self):
        before = self.save()
        with patch.object(accounts, "Session") as load, self.assertRaisesRegex(ValueError, "未启用"):
            self.store.open_session(1, PASSWORD, ("phone", 0))
        load.assert_not_called()
        self.register()
        self.register(7)
        self.assertIn(7, self.store.account_ids())
        self.assertFalse(self.store.path(7).exists())
        record = json.loads(self.store.credential_path(1).read_bytes())
        other = json.loads(self.store.credential_path(7).read_bytes())
        self.assertEqual(record["iterations"], 600000)
        self.assertNotEqual(record["salt"], other["salt"])
        self.assertNotEqual(record["hash"], other["hash"])
        self.assertNotIn(PASSWORD, self.store.credential_path(1).read_text())
        if os.name != "nt":
            self.assertEqual(self.store.credential_path(1).stat().st_mode & 0o777, 0o600)
        restarted = accounts.AccountStore(self.store.save_path, TABLES, COUNTS, CONFIG)
        session = restarted.open_session(1, PASSWORD, ("phone", 0))
        self.assertEqual(session.save["role_name"], "测试账号1")
        self.assertEqual(self.store.path(1).read_bytes(), before)
        snapshot = restarted.snapshot(1)
        self.assertTrue(snapshot["registered"])
        for secret in (PASSWORD, record["salt"], record["hash"]):
            self.assertNotIn(secret, json.dumps(views.detail(snapshot, COUNTS, CONFIG)))
        restarted.close_session(1)

    def test_invalid_duplicate_stale_and_failed_creation_preserve_data(self):
        before = self.save()
        for password in (None, 12345678, "short", "a" * 65, "space password", "中文密码测试1234"):
            with self.subTest(password=password), self.assertRaises(ValueError):
                self.register(password=password)
        with self.assertRaisesRegex(ValueError, "变化"):
            self.store.register(1, PASSWORD, "stale")
        with patch.object(storage.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
            self.register()
        self.assertFalse(self.store.credential_path(1).exists())
        self.assertEqual(list(self.store.credential_path(1).parent.iterdir()), [])
        self.assertEqual(self.store.active, {})
        self.register()
        credential = self.store.credential_path(1).read_bytes()
        with self.assertRaisesRegex(ValueError, "已设置"):
            self.register(password="another-password")
        self.assertEqual(self.store.credential_path(1).read_bytes(), credential)
        self.assertEqual(self.store.path(1).read_bytes(), before)

    def test_failed_attempt_limit_covers_reconnects_but_not_other_accounts(self):
        self.register()
        self.register(2)
        with patch.object(accounts.time, "monotonic", return_value=100) as clock:
            for _ in range(5):
                with self.assertRaisesRegex(ValueError, "密码错误"):
                    self.store.open_session(1, "wrong-password", ("phone", 0))
            with patch.object(accounts.hashlib, "pbkdf2_hmac") as derive, self.assertRaisesRegex(ValueError, "频繁"):
                self.store.open_session(1, PASSWORD, ("other-device", 0))
            derive.assert_not_called()
            self.store.open_session(2, PASSWORD, ("phone", 0))
            self.store.close_session(2)
            clock.return_value = 160
            self.store.open_session(1, PASSWORD, ("phone", 0))
            self.store.close_session(1)
            for at in (200, 215, 230, 245, 260):
                clock.return_value = at
                with self.assertRaisesRegex(ValueError, "密码错误"):
                    self.store.authenticate(1, "wrong-password")
            clock.return_value = 261
            self.store.authenticate(1, PASSWORD)
        self.assertEqual(self.store.failed_logins, {})

    def test_corrupt_credentials_fail_closed_and_cannot_be_overwritten(self):
        self.register()
        path = self.store.credential_path(1)
        record = json.loads(path.read_bytes())
        for raw in (b"{", b"[]", json.dumps({**record, "iterations": 1}).encode(),
                    json.dumps({**record, "hash": "bad"}).encode()):
            path.write_bytes(raw)
            with patch.object(accounts, "Session") as load, self.assertRaisesRegex(ValueError, "配置损坏"):
                self.store.open_session(1, PASSWORD, ("phone", 0))
            load.assert_not_called()
            with self.assertRaisesRegex(ValueError, "已设置"):
                self.register()
            self.assertEqual(path.read_bytes(), raw)
            self.assertEqual(self.store.active, {})

    def test_credentials_survive_game_progress_reset_and_restore(self):
        self.save()
        self.register()
        credential = self.store.credential_path(1).read_bytes()
        backup = self.maintain("reset")["backup_id"]
        self.store.open_session(1, PASSWORD, ("phone", 0))
        self.store.close_session(1)
        self.maintain("restore", backup_id=backup)
        self.store.open_session(1, PASSWORD, ("phone", 0))
        self.store.close_session(1)
        self.assertEqual(self.store.credential_path(1).read_bytes(), credential)
        self.assertNotIn("credentials", self.store.snapshot(1)["save"])


class ConfigurationTests(AdminFixture):
    def update(self, table, row, changes):
        return self.configs.update(table, row, changes, self.configs.status()["revision"])

    def test_saved_overrides_require_restart_and_feed_server_loading(self):
        initial = self.configs.status()["revision"]
        changed = self.update("props", "20014", {"param1": "37", "desc": "恢复37点体力"})
        self.assertTrue(changed["restart_required"])
        self.assertEqual(CONFIG["props"]["20014"]["param1"], "25")
        self.assertEqual(player.load_role_config(self.config_path)["props"]["20014"]["param1"], "37")
        with self.assertRaisesRegex(ValueError, "修改"):
            self.configs.update("props", "20014", {"param1": "20"}, initial)
        restarted = configuration.ConfigStore(self.config_path)
        self.assertFalse(restarted.status()["restart_required"])
        self.update("props", "20014", None)
        self.assertEqual(player.load_role_config(self.config_path)["props"]["20014"]["param1"], "25")
        self.assertFalse(self.configs.status()["restart_required"])
        self.assertTrue(restarted.status()["restart_required"])

    def test_invalid_fields_rewards_and_types_never_write_overrides(self):
        cases = [("general", "10101", {"name": "no"}), ("props", "20017", {"desc": "no"}),
                 ("props", "20014", {"param2": "gold"}), ("props", "20014", {"param1": 50}),
                 ("props", "20014", {"param1": "100001"}), ("liveness", "16", {"num": True}),
                 ("liveness", "16", {"reward": "9999999999,1;"}), ("liveness", "16", {"reward": "1000,0;"}),
                 ("liveness", "16", {"reward": "1000,1;1000,2;"}), ("liveness", "16", {"reward": "22204,101;"})]
        for table, row, changes in cases:
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                self.update(table, row, changes)
        self.assertFalse(configuration.overrides_path(self.config_path).exists())
        self.assertFalse((self.root / "backups").exists())

    def test_reward_edits_browse_search_and_pagination(self):
        self.update("begin7day_task", "80001", {"rewards": "1000,3;1001,2;20014,1;22204,1;"})
        self.update("liveness", "16", {"num": 8})
        loaded = player.load_role_config(self.config_path)
        self.assertEqual(loaded["liveness"]["16"]["num"], 8)
        self.assertEqual(loaded["begin7day_task"]["80001"]["rewards"], "1000,3;1001,2;20014,1;22204,1;")
        result = self.configs.table("props", "体力丹")
        self.assertTrue({"20014", "20019"} <= {r["id"] for r in result["rows"]})
        self.assertEqual(self.configs.table("props", "20014")["rows"][0]["id"], "20014")
        page1, page2 = self.configs.table("general"), self.configs.table("general", offset=50)
        self.assertEqual(len(page1["rows"]), 50)
        self.assertFalse({r["id"] for r in page1["rows"]} & {r["id"] for r in page2["rows"]})
        self.assertIsNone(page1["editor"])

    def test_failed_override_write_keeps_previous_config_and_backup(self):
        self.update("props", "20014", {"param1": "37"})
        path = configuration.overrides_path(self.config_path)
        before = path.read_bytes()
        real_write = storage.atomic_write

        def fail_override(target, data):
            if Path(target) == path:
                raise OSError("disk full")
            return real_write(target, data)

        with patch.object(storage, "atomic_write", side_effect=fail_override), self.assertRaises(OSError):
            self.update("props", "20014", {"param1": "38"})
        self.assertEqual(path.read_bytes(), before)
        backups = [json.loads(p.read_bytes()) for p in (self.root / "backups/configs").glob("*.json")]
        self.assertIn(json.loads(before), backups)


class AdminHttpTests(AdminFixture):
    def setUp(self):
        super().setUp()
        self.save()
        self.http = start_admin(0, self.store, self.configs)
        self.addCleanup(self.http.server_close)
        self.addCleanup(self.http.shutdown)

    def request(self, path, data=None, headers=None, method=None):
        connection = http.client.HTTPConnection("127.0.0.1", self.http.server_port, timeout=3)
        try:
            body = json.dumps(data) if data is not None else None
            defaults = {"Content-Type": "application/json", "X-Admin-Token": self.http.token}
            connection.request(method or ("POST" if data is not None else "GET"), path, body, {**defaults, **(headers or {})})
            response = connection.getresponse()
            raw = response.read()
            content = json.loads(raw) if response.getheader("Content-Type").startswith("application/json") else raw
            return response.status, dict(response.getheaders()), content
        finally:
            connection.close()

    def test_local_assets_status_and_download_are_available_without_mutating_save(self):
        before = self.store.path(1).read_bytes()
        self.assertEqual(self.http.server_address[0], "127.0.0.1")
        for path in ("/", "/app.js", "/style.css", "/api/status", "/api/accounts", "/api/accounts/1"):
            code, headers, data = self.request(path)
            self.assertEqual(code, 200, data)
            self.assertEqual(headers["Cache-Control"], "no-store")
            self.assertIn("frame-ancestors 'none'", headers["Content-Security-Policy"])
        code, headers, data = self.request("/api/accounts/1/download")
        self.assertEqual((code, data), (200, before))
        self.assertIn("account-1.json", headers["Content-Disposition"])
        self.assertEqual(self.store.path(1).read_bytes(), before)

    def test_bad_host_origin_token_and_request_shape_cannot_write(self):
        before = self.store.path(1).read_bytes()
        payload = {"action": "reset", "revision": self.store.snapshot(1)["revision"]}
        for headers, expected in [({"Host": "evil.example"}, 403), ({"Origin": "https://evil.example"}, 403),
                                  ({"X-Admin-Token": "old-token"}, 403), ({"Content-Type": "text/plain"}, 400),
                                  ({"Content-Length": "40000"}, 400)]:
            with self.subTest(headers=headers):
                self.assertEqual(self.request("/api/accounts/1", payload, headers)[0], expected)
        self.assertEqual(self.request("/api/accounts/1", [payload])[0], 400)
        self.assertEqual(self.request("/api/accounts/1001")[0], 400)
        self.assertEqual(self.request("/../role_save.json")[0], 404)
        self.assertEqual(self.request("/api/accounts", headers={"Host": "evil.example"})[0], 403)
        self.assertEqual(self.store.path(1).read_bytes(), before)

    def test_http_maintenance_and_config_edits_use_shared_live_objects(self):
        self.store.register(1, PASSWORD, self.store.snapshot(1)["revision"])
        self.store.open_session(1, PASSWORD, ("phone", 0))
        payload = {"action": "reset", "revision": self.store.snapshot(1)["revision"]}
        self.assertEqual(self.request("/api/accounts/1", payload)[0], 400)
        self.assertTrue(self.request("/api/accounts/1")[2]["online"])
        self.store.close_session(1)
        self.assertEqual(self.request("/api/accounts/1", payload)[0], 200)
        self.assertFalse(self.store.path(1).exists())
        revision = self.configs.status()["revision"]
        self.assertEqual(self.request("/api/configs/props", {"row_id": "20014", "revision": revision})[0], 400)
        code, _, result = self.request("/api/configs/props", {"row_id": "20014", "changes": {"param1": "37"}, "revision": revision})
        self.assertEqual(code, 200)
        self.assertTrue(result["restart_required"])
        self.assertEqual(self.request("/api/configs/props?q=20014")[2]["rows"][0]["value"]["param1"], "37")

    def test_http_creates_and_binds_accounts_without_exposing_credentials(self):
        before = self.store.path(1).read_bytes()
        for account in (1, 17):
            route = f"/api/accounts/{account}/credentials"
            payload = {"password": PASSWORD, "revision": self.store.snapshot(account)["revision"]}
            for headers in ({"Host": "evil.example"}, {"Origin": "https://evil.example"}, {"X-Admin-Token": "bad"}):
                self.assertEqual(self.request(route, payload, headers)[0], 403)
            self.assertFalse(self.store.credential_path(account).exists())
            self.assertEqual(self.request(route, {**payload, "unexpected": True})[0], 400)
            self.assertEqual(self.request(route, payload)[0], 200)
            self.assertEqual(self.request(route, payload)[0], 400)
            self.assertEqual(self.request(route)[0], 404)
            detail = self.request(f"/api/accounts/{account}")[2]
            self.assertTrue(detail["registered"])
            self.assertNotIn(PASSWORD, json.dumps(detail))
        self.assertEqual([row["id"] for row in self.request("/api/accounts")[2]["accounts"]], [1, 17])
        self.assertEqual(self.request("/api/accounts/1/download")[2], before)
        self.assertFalse(self.store.path(17).exists())


if __name__ == "__main__":
    unittest.main()
