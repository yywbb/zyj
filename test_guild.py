"""公会新增玩法：仅使用临时多账号存档及原生协议。"""

from contextlib import redirect_stdout
import copy
import io
import json
from pathlib import Path
import struct
import tempfile
import threading
import unittest
import zipfile
from unittest.mock import patch

from zyj_server import accounts, guide, guild, player, protocol, replay, storage


ROOT = Path(__file__).parent


def setUpModule():
    global TABLES, CONFIG, COUNTS, SAVE
    with redirect_stdout(io.StringIO()), tempfile.TemporaryDirectory() as directory:
        COUNTS = guide.load_guide_step_counts(ROOT / "configs_sec5.zip")
        CONFIG = player.load_role_config(ROOT / "configs_sec5.zip")
        frames = replay.load_recordings(ROOT / "recorded_frames.json")
        TABLES = replay.build_routing_tables(frames)
        session = accounts.Session(TABLES, Path(directory) / "role_save.json", COUNTS, CONFIG)
        for frame in replay.split_recordings(frames)[0]:
            if frame["c2s"] and frame["opcode"] != 1000:
                session.handle(frame["opcode"], frame["seq"], bytes.fromhex(frame["hex"]))
        SAVE = session.save


class GuildFeatureTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name)
        self.now = 1793430000
        self.clock = patch("time.time", return_value=self.now).start()
        self.addCleanup(patch.stopall)
        quiet = redirect_stdout(io.StringIO())
        quiet.__enter__()
        self.addCleanup(quiet.__exit__, None, None, None)
        self.store = accounts.AccountStore(self.root / "role_save.json", TABLES, COUNTS, CONFIG)
        patch.object(self.store, "authenticate", return_value=None).start()
        self.sessions, self.seq = {}, 40000
        for account in (1, 2, 3):
            save = copy.deepcopy(SAVE)
            save.update(created_at=self.now - 10 * 86400 + account, role_name=f"公会测试{account}")
            save["role_state"].update(level=80, vip=5, coin=10000000, gold=10000000)
            player.save_role(save, self.store.path(account), COUNTS)
            self.sessions[account] = self.store.open_session(account, "test-password", ("test", account))
            self.addCleanup(self.store.close_session, account)
        self.success(1, 2231, text="本地公会")
        self.success(1, 2265, values=[1, 19])
        self.success(2, 2233, values=[1])

    def request(self, account, opcode, values=(), text=None, raw=None):
        if raw is None:
            raw = (guild.params([text]) if text is not None else
                   b"".join(protocol.encode_pb_field(1, 0, v) for v in values))
        self.seq += 1
        return [(struct.unpack(">IIII", p[:16])[2], p[16:])
                for p in self.sessions[account].handle(opcode, self.seq, raw)]

    def success(self, account, opcode, **kwargs):
        packets = self.request(account, opcode, **kwargs)
        self.assertEqual(packets[0][0], opcode, packets)
        return packets[0][1]

    def shared(self):
        return json.loads((self.root / "guilds.json").read_bytes())

    def update_guild(self, **updates):
        state = self.shared()
        state["guilds"]["1"].update(updates)
        guild.write(self.root / "guilds.json", state)

    def contribution(self, amount, account=1):
        self.success(account, 2250)
        self.sessions[account].save["guild_daily_state"].update(contribution=amount, total_contribution=amount)
        player.save_role(self.sessions[account].save, self.store.path(account), COUNTS)

    def level(self, level):
        self.update_guild(experience=sum(CONFIG["gang2_level"][str(i)]["gang_exp"] for i in range(1, level)))

    def count(self, cid, account=1):
        return next((protocol.pb_get_varint(v, 2) for n, w, v in protocol.iter_pb_fields(
            bytes.fromhex(self.sessions[account].save["world_state"]["1200"]))
            if (n, w) == (1, 2) and protocol.pb_get_varint(v, 1) == cid), 0)

    def give(self, cid, count, account=1):
        player.change_item_count(self.sessions[account].save, cid, count, CONFIG, self.now)
        player.save_role(self.sessions[account].save, self.store.path(account), COUNTS)

    def reconnect(self, account=1):
        self.store.close_session(account)
        self.sessions[account] = self.store.open_session(account, "test-password", ("reconnect", account))

    def assert_rejected_unchanged(self, account, opcode, **kwargs):
        before = copy.deepcopy(self.sessions[account].save)
        disk = self.store.path(account).read_bytes()
        shared = (self.root / "guilds.json").read_bytes()
        self.assertEqual(self.request(account, opcode, **kwargs)[0][0], 999999)
        self.assertEqual(self.sessions[account].save, before)
        self.assertEqual(self.store.path(account).read_bytes(), disk)
        self.assertEqual((self.root / "guilds.json").read_bytes(), shared)

    def test_shop_costs_counts_and_lifetime_contribution_survive_reconnect(self):
        self.contribution(1500000)
        before = self.count(193205)
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 2252)), [0] * 19)
        self.success(1, 2253, values=[19, 2])
        self.assertEqual(self.count(193205) - before, 2)
        self.reconnect()
        state = self.sessions[1].save["guild_daily_state"]
        self.assertEqual((state["contribution"], state["total_contribution"]), (500000, 1500000))
        rows = dict(protocol.get_comb_messages(self.success(1, 2230)))
        self.assertEqual(protocol.parse_ids_pb(rows[2])[:2], [500000, 1500000])
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 2252))[-1], 2)
        self.assert_rejected_unchanged(1, 2253, values=[19, 1])

    def test_shop_all_configured_rows_can_be_bought_with_their_real_rewards(self):
        self.level(15)
        self.contribution(100000000)
        for index in range(1, 20):
            with self.subTest(index=index):
                self.assertTrue(self.success(1, 2253, values=[index, 1]))
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 2252)), [1] * 19)

    def test_shop_invalid_prices_limits_and_role_locks_do_not_mutate(self):
        self.contribution(499999)
        for values in ((), [19], [19, 0], [19, 3], [19, 1], [0, 1], [20, 1], [1, 1], [19, 1, 1]):
            self.assert_rejected_unchanged(1, 2253, values=values)
        self.assert_rejected_unchanged(3, 2252)
        self.assert_rejected_unchanged(1, 2252, values=[1])

    def test_shop_midnight_resets_counts_only_forward_and_not_by_switching_guilds(self):
        self.contribution(2000000)
        self.success(1, 2253, values=[19, 2])
        self.clock.return_value += 86400
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 2252))[-1], 0)
        self.success(1, 2253, values=[19, 1])
        self.clock.return_value = self.now
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 2252))[-1], 1)
        self.assertEqual(self.sessions[1].save["guild_daily_state"]["contribution"], 500000)

    def test_shop_save_failure_and_inventory_overflow_leave_contribution_untouched(self):
        self.contribution(2000000)
        before = copy.deepcopy(self.sessions[1].save)
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 2253, values=[19, 1])
        self.assertEqual(self.sessions[1].save, before)
        self.give(193205, (1 << 31) - 1 - self.count(193205))
        self.assert_rejected_unchanged(1, 2253, values=[19, 1])

    def test_pool_uses_all_four_configured_soap_costs_rewards_and_shared_growth(self):
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 2256)), [1, 0, 1, 0, 0, 0, 0, 0, 0])
        for cid in range(20162, 20166):
            self.give(cid, 2)
        before = copy.deepcopy(self.sessions[1].save)
        reply = self.success(1, 2257, values=[20162, 1, 20163, 2, 20164, 1, 20165, 2])
        reward = dict(self.business_rows(reply))[3]
        self.assertEqual([v for n, w, v in protocol.iter_pb_fields(reward) if (n, w) == (1, 0)], [28000])
        daily = self.sessions[1].save["guild_daily_state"]
        self.assertEqual((daily["soap_used"], daily["contribution"], daily["total_contribution"]), (6, 25000, 25000))
        self.assertEqual(self.sessions[1].save["role_state"]["coin"] - before["role_state"]["coin"], 28000)
        self.assertEqual([self.count(cid) for cid in range(20162, 20166)], [1, 0, 1, 0])
        status = protocol.parse_ids_pb(self.success(2, 2256))
        self.assertEqual(status[:4], [1, 120, 1, 1800])
        self.assertEqual(status[-1], 0)
        self.assertEqual(self.shared()["guilds"]["1"]["experience"], 180000)
        rank = self.success(2, 2261)
        first = next(v for n, w, v in protocol.iter_pb_fields(rank) if (n, w) == (1, 2))
        self.assertEqual(protocol.pb_get_varint(first, 1), 1000001)
        self.assertEqual(protocol.pb_get_varint(first, 7), 25000)

    def test_pool_claims_require_shared_progress_and_are_personal_once_per_day(self):
        self.update_guild(fishpond={"day": (self.now + 28800) // 86400, "experience": 100000, "progress": 24000})
        for account in (1, 2):
            self.assertEqual(protocol.parse_ids_pb(self.success(account, 2256))[4:8], [1] * 4)
            for box in range(1, 5):
                self.assertTrue(self.success(account, 2258, values=[box]))
                self.assert_rejected_unchanged(account, 2258, values=[box])
        self.reconnect()
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 2256))[4:8], [2] * 4)
        self.clock.return_value += 86400
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 2256))[2:8], [4, 0, 0, 0, 0, 0])

    def test_pool_invalid_pairs_limits_and_missing_inventory_are_atomic(self):
        self.give(20162, 11)
        for values in ((), [20162], [20162, 0], [20162, 11], [20162, 1, 20162, 1], [20162, 1, 20163, 1], [20073, 1]):
            self.assert_rejected_unchanged(1, 2257, values=values)
        for box in (0, 1, 4, 5):
            self.assert_rejected_unchanged(1, 2258, values=[box])
        self.success(1, 2257, values=[20162, 10])
        self.assert_rejected_unchanged(1, 2257, values=[20162, 1])

    def test_pool_pending_commit_recovers_once_and_failed_role_save_drops_draft(self):
        self.give(20165, 3)
        before = copy.deepcopy(self.sessions[1].save)
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 2257, values=[20165, 1])
        self.assertEqual(self.sessions[1].save, before)
        self.success(1, 2256)
        self.assertEqual(self.shared()["guilds"]["1"].get("experience", 0), 0)
        original = storage.atomic_write
        def fail_publish(path, raw):
            state = json.loads(raw) if Path(path).name == "guilds.json" else {}
            row = state.get("guilds", {}).get("1", {})
            if row.get("experience") and "pending_action" not in row:
                raise OSError("publish failed")
            return original(path, raw)
        with patch.object(storage, "atomic_write", side_effect=fail_publish), self.assertRaises(OSError):
            self.request(1, 2257, values=[20165, 1])
        self.reconnect()
        for _ in range(2):
            self.success(1, 2256)
        self.assertEqual(self.shared()["guilds"]["1"]["experience"], 50000)
        self.assertEqual(self.count(20165), 2)
        self.assertEqual(self.sessions[1].save["guild_daily_state"]["contribution"], 8000)

    def test_pool_concurrent_members_accumulate_instead_of_overwriting(self):
        for account in (1, 2):
            self.give(20165, 1, account)
        barrier, results = threading.Barrier(2), []
        def feed(account):
            barrier.wait(5)
            results.append(self.request(account, 2257, values=[20165, 1])[0][0])
        threads = [threading.Thread(target=feed, args=(account,)) for account in (1, 2)]
        for thread in threads:
            thread.start()
        for thread in threads:
            thread.join(10)
            self.assertFalse(thread.is_alive())
        self.assertEqual(results, [2257, 2257])
        self.assertEqual(self.shared()["guilds"]["1"]["experience"], 100000)
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 2256))[3], 1000)

    def test_rename_charges_leader_only_and_recovers_paid_name(self):
        before = self.sessions[1].save["role_state"]["gold"]
        self.assert_rejected_unchanged(2, 2259, text="不能改名")
        self.success(1, 2259, text="改名公会")
        self.assertEqual(self.shared()["guilds"]["1"]["name"], "改名公会")
        self.assertEqual(self.sessions[1].save["role_state"]["gold"], before - 300)
        self.assert_rejected_unchanged(1, 2259, text="改名公会")
        self.success(3, 2231, text="另一公会")
        self.assert_rejected_unchanged(1, 2259, text="另一公会")

    def test_management_events_are_real_paginated_and_members_only(self):
        self.success(1, 2239, values=[0, 1000002])
        self.success(1, 2239, values=[1, 1000002])
        rows = dict(self.business_rows(self.success(1, 2254, values=[0, 1])))
        self.assertEqual(protocol.parse_ids_pb(rows[-1]), [0])
        self.assertEqual(len(rows), 2)
        page2 = dict(self.business_rows(self.success(1, 2254, values=[1, 1])))
        self.assertEqual(protocol.parse_ids_pb(page2[-1]), [1])
        self.assertNotEqual(rows[1], page2[2])
        self.assert_rejected_unchanged(3, 2254, values=[0, 20])

    def business_rows(self, body):
        for n, w, raw in protocol.iter_pb_fields(body):
            fields = list(protocol.iter_pb_fields(raw))
            mid = fields[0][2]
            yield mid - (1 << 64) if mid >= (1 << 63) else mid, fields[1][2]

    def test_impeach_requires_offline_leader_and_configured_inactivity(self):
        self.assert_rejected_unchanged(2, 2255)
        self.clock.return_value += 2 * 86400
        self.assert_rejected_unchanged(2, 2255)
        self.store.close_session(1)
        members = dict(self.business_rows(self.success(2, 2236)))
        values = [v for n, w, v in protocol.iter_pb_fields(members[1]) if (n, w) == (1, 2)]
        self.assertEqual(protocol.pb_get_varint(values[6], 1), 1)
        self.assert_rejected_unchanged(2, 2255)
        self.clock.return_value += int(CONFIG["global_kv"]["gang_impeach_limit"]["value"]) + 1
        self.success(2, 2255)
        posts = self.shared()["guilds"]["1"]["members"]
        self.assertEqual((posts["1"]["post"], posts["2"]["post"]), (0, 1))
        self.assert_rejected_unchanged(2, 2255)

    def test_same_sequence_mutations_reuse_latest_reply_but_not_after_shared_changes(self):
        self.give(20165, 3)
        body = guild.ids([20165, 1])
        packets = self.sessions[1].handle(2257, 60000, body)
        self.assertEqual(self.sessions[1].handle(2257, 60000, body), packets)
        self.assertEqual(self.count(20165), 2)
        self.give(20165, 1, 2)
        self.success(2, 2257, values=[20165, 1])
        rejected = self.sessions[1].handle(2257, 60000, body)
        self.assertEqual(struct.unpack(">IIII", rejected[0][:16])[2], 999999)
        self.assertEqual(self.count(20165), 2)

    def chat_body(self, text, account=1, rid=None):
        if rid is None:
            rid = protocol.pb_get_varint(bytes.fromhex(self.sessions[account].save["role_snapshot"]), 1)
        return protocol.encode_pb_field(2, 2, protocol.encode_pb_field(1, 0, rid)
                                        + protocol.encode_pb_field(2, 2, text.encode("utf-8")))

    def chats(self, body):
        return [(protocol.pb_get_varint(raw, 1), next(v.decode("utf-8") for n, w, v in protocol.iter_pb_fields(raw) if (n, w) == (2, 2)))
                for n, w, raw in protocol.iter_pb_fields(body) if (n, w) == (2, 2)]

    def test_chat_history_incremental_queries_identity_and_guild_isolation(self):
        text = "本地公会你好🙂"
        self.success(1, 3011, raw=self.chat_body(text))
        history = self.success(2, 3010, values=[0])
        self.assertEqual(self.chats(history), [(1000001, text)])
        self.assertEqual(self.success(2, 3010), b"")
        self.assertEqual(self.chats(self.success(2, 3010, values=[0])), [(1000001, text)])
        self.assertEqual(self.success(3, 3010), b"")
        self.assert_rejected_unchanged(3, 3011, raw=self.chat_body("不能越权", 3))
        self.reconnect(2)
        self.assertEqual(self.chats(self.success(2, 3010)), [(1000001, text)])
        own = protocol.pb_get_varint(bytes.fromhex(self.sessions[1].save["role_snapshot"]), 1)
        self.assertEqual(self.chats(self.success(1, 3010, values=[0])), [(own, text)])
        self.success(2, 2242)
        self.assertEqual(self.success(2, 3010), b"")

    def test_chat_rejects_forgery_bad_text_and_spam_without_changing_history(self):
        for raw in (self.chat_body("假冒", rid=1000002), self.chat_body(""), self.chat_body("\n"), self.chat_body("x" * 201),
                    self.chat_body("假的活动&&&1"), self.chat_body("<script>"), self.chat_body("消息") * 2):
            self.assert_rejected_unchanged(1, 3011, raw=raw)
        body = self.chat_body("只发一次")
        packets = self.sessions[1].handle(3011, 60001, body)
        self.assertEqual(self.sessions[1].handle(3011, 60001, body), packets)
        self.assert_rejected_unchanged(1, 3011, raw=body)
        self.clock.return_value += 5
        self.success(1, 3011, raw=body)
        self.assertEqual(len(self.shared()["guilds"]["1"]["chats"]), 2)

    def test_chat_does_not_attribute_old_identity_messages_to_recreated_account(self):
        self.success(1, 3011, raw=self.chat_body("旧角色消息"))
        self.store.close_session(1)
        self.clock.return_value += 10
        save = copy.deepcopy(SAVE)
        save.update(created_at=self.now + 10, role_name="重建角色")
        save["role_state"].update(level=80, gold=1000000)
        player.save_role(save, self.store.path(1), COUNTS)
        self.sessions[1] = self.store.open_session(1, "test-password", ("new-role", 1))
        self.success(1, 2233, values=[1])
        self.success(1, 3011, raw=self.chat_body("新角色消息"))
        self.assertEqual(self.chats(self.success(2, 3010, values=[0])), [(1000001, "新角色消息")])

    def test_chat_persist_failure_does_not_consume_query_cursor_or_expose_message(self):
        body = self.chat_body("保存失败")
        with patch.object(storage, "atomic_write", side_effect=OSError("disk full")), self.assertRaises(OSError):
            self.request(1, 3011, raw=body)
        self.assertNotIn("chats", self.shared()["guilds"]["1"])
        self.assertEqual(self.success(2, 3010), b"")
        self.success(1, 3011, raw=body)
        self.assertEqual(self.chats(self.success(2, 3010)), [(1000001, "保存失败")])

    def test_disconnect_write_failure_releases_login_without_early_impeachment(self):
        self.clock.return_value += 2 * 86400
        with patch.object(storage, "atomic_write", side_effect=OSError("disk full")):
            self.store.close_session(1)
        self.assertNotIn(1, self.store.active)
        self.assert_rejected_unchanged(2, 2255)
        self.clock.return_value += int(CONFIG["global_kv"]["gang_impeach_limit"]["value"]) + 1
        self.success(2, 2255)

    def test_corrupt_feature_states_and_pending_after_rows_fail_closed_before_reset(self):
        self.success(1, 2256)
        shared = self.shared()
        path = self.root / "guilds.json"
        raw = path.read_bytes()
        for replacement in ({"fishpond": {"day": 0, "experience": -1, "progress": 0}},
                            {"events": [{}]}, {"chats": [{}]}, {"pending_action": {"account": "1", "identity": self.sessions[1].save["created_at"],
                                "token": "0" * 32, "after": {}}}):
            state = copy.deepcopy(shared)
            state["guilds"]["1"].update(replacement)
            path.write_text(json.dumps(state))
            self.assert_rejected_unchanged(1, 2256)
        path.write_bytes(raw)
        for replacement in ({"total_contribution": -1}, {"fish_claimed": [True]}, {"shop": {"19": -1}}, {"soap_used": True}):
            original = copy.deepcopy(self.sessions[1].save)
            self.sessions[1].save["guild_daily_state"].update(replacement)
            self.assert_rejected_unchanged(1, 2252)
            self.sessions[1].save = original

    def test_packaged_network_callbacks_decode_live_shop_and_pool_without_ui_globals(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("原生公会回调验证需 lupa.lua51")
        from build_local_apk import get_patched_lua_scripts, read_script, xxtea_decrypt, XXTEA_KEY
        if not (ROOT / "z7_7_4.apk").exists():
            self.skipTest("原始 APK 未提供")
        patched = get_patched_lua_scripts()
        def source(path):
            raw = xxtea_decrypt(patched[path], XXTEA_KEY)
            return raw[:struct.unpack("<I", raw[-4:])[0]].decode("utf-8")
        lua = LuaRuntime()
        for path in ("GameGang", "GameChat", "UIGang", "Layer_chat", "window_chat_guildnew", "window_guild2_xianchi"):
            lua.compile(source(f"assets/scripts/{path}.so"))
        def decode(kind, raw):
            body = bytes.fromhex(raw)
            fields = list(protocol.iter_pb_fields(body))
            if kind == "Ids":
                data = {"ids": protocol.parse_ids_pb(body)}
            elif kind == "CombMessages":
                data = {"messages": [{"id": mid, "data": value.hex()} for mid, value in self.business_rows(body)]}
            elif kind == "ParamS":
                data = {"params": [{"i" if w == 0 else "s": v if w == 0 else v.decode() for n, w, v in protocol.iter_pb_fields(value)}
                                   for _, _, value in fields]}
            elif kind == "SomeThings":
                data = {"coin": protocol.pb_get_varint(body, 1) or 0, "props": {"idnums": []}}
                for n, w, value in fields:
                    if (n, w) == (5, 2):
                        data["props"]["idnums"].extend({"id": protocol.pb_get_varint(v, 1), "num": protocol.pb_get_varint(v, 2)}
                            for f, t, v in protocol.iter_pb_fields(value) if (f, t) == (1, 2))
            else:
                raise AssertionError(kind)
            return lua.table_from(data, recursive=True)
        lua.globals().decode = decode
        lua.execute('''
            print, printT, cclog, printf = function() end, function() end, function() end, function() end
            for mod,kind in pairs({ids_pb="Ids",params_pb="ParamS",combmessages_pb="CombMessages",somethings_pb="SomeThings"}) do
                local name=kind
                package.preload[mod]=function() return {[name]=function() return {ids={},
                    ParseFromString=function(self,raw) for k,v in pairs(decode(name,raw)) do self[k]=v end end,
                    SerializeToString=function(self) return self.ids end} end} end
            end
            for _,mod in ipairs({"result_pb","gangstatus_pb","gangbroadcasts_pb","stringcontent_pb","gangs_pb","gangmembers_pb",
                "players_pb","worldboss1_pb","worldboss1realnotify_pb","PickBattleResultReport","error_pb"}) do
                package.preload[mod]=function() return {} end
            end
            package.preload.logError=function() return {errorMessage={}} end
            gamedata={ext={},cache={role={gold=10000000,coin=0},gang2status={},gang2xianchi={},props={}}}
            function gamedata:SomethingProcess(data) return data end
            function gamedata:updateRoleGold(value) self.cache.role.gold=self.cache.role.gold+value end
            function gamedata:updateRoleCoin(value) self.cache.role.coin=self.cache.role.coin+value end
            function initPb(_,fd) return decode("Ids",fd.rbuf) end
        ''')
        native = read_script("gamedata").decode()
        lua.execute(native[native.index("function gamedata.Gang2Status("):native.index("function gamedata.gangData(")])
        lua.execute(native[native.index("function gamedata.GangShopGoods("):native.index("function gamedata.GuildWarTakeWarPointData(")])
        lua.execute(source("assets/scripts/GameGang.so"))
        lua.execute(source("assets/common_lua/GameErrorMessage.so"))
        def callback(name, body):
            return lua.globals()[name](lua.table_from({"rbuf": body.hex()}))
        self.contribution(1000000)
        callback("NetUserGang2CallBack", self.success(1, 2230))
        lua.execute('''
            local remote,opcode=UIGuideShopBuyGoodsCallBack({id=19,num=1,contribution=500000})
            assert(remote==1 and opcode==2253)
            local remote=UIGuideShopBuyGoodsCallBack({id=19,num=2,contribution=1})
            assert(remote==0 and gamedata.ext.shopContribution==500000 and gamedata.ext.shopContributionNum==1)
        ''')
        callback("NetGuideShopBuyGoodsCallBack", self.success(1, 2253, values=[19, 1]))
        self.assertEqual(lua.globals().gamedata.cache.gang2status.contribution, 500000)
        self.assertIsNone(lua.globals().gamedata.ext.localGuildBusy)
        lua.execute("gamedata.ext.localGuildBusy=2253")
        callback("NetErrorMessageCallback9", guild.ids([2253, 0]))
        self.assertIsNone(lua.globals().gamedata.ext.localGuildBusy)
        for cid in (20162, 20165):
            self.give(cid, 1)
        lua.execute('gamedata.cache.props[20162]={num=1}; gamedata.cache.props[20165]={num=1}')
        callback("NetUserGang2FishpondCallBack", self.success(1, 2256))
        lua.execute('UIUserGang2FishpondFeedCallBack({changedata={{cid=20162,num=1},{cid=20165,num=1}}})')
        reply = self.success(1, 2257, values=[20162, 1, 20165, 1])
        result = callback("NetUserGang2FishpondFeedCallBack", reply)
        self.assertEqual((result.reward.coin, result.xianchidata.xc_dayprogress, result.xianchidata.eattimesnum), (10000, 600, 2))
        self.assertEqual(lua.globals().gamedata.cache.gang2status.contribution, 509000)
        self.assertEqual(lua.globals().gamedata.cache.gang2status.totalcontribution, 1009000)
        self.assertEqual(lua.globals().gamedata.cache.props[20165].num, 0)
        self.assertIsNone(lua.globals().gameConfig)
        lua.globals().gamedata.ext = None
        self.assertEqual(callback("NetErrorMessageCallback9", guild.ids([1000, 0])).type, 9997)

        ui_lua = LuaRuntime()
        ui_lua.execute('''
            print=function() end
            gameTouch={UnrigistFunc=function() end}
            local now,requests,cancelled,task=0,0,false,nil
            os.time=function() return now end
            UIRequest=function(t) assert(t.type==3010); requests=requests+1 end
            GameScene={layers={chat={show=true}}}
            local scheduler={scheduleScriptFunc=function(_,f) task=f; return 123 end,
                unscheduleScriptEntry=function(_,id) assert(id==123); cancelled=true end}
            CCDirector={sharedDirector=function() return {getScheduler=function() return scheduler end} end}
            self={rootNode={removeAllChildrenWithCleanup=function() end,removeFromParentAndCleanup=function() end},selectpage="guild"}
            function tick(value) now=value; task() end
            function counts() return requests,cancelled end
        ''')
        layer = source("assets/scripts/Layer_chat.so")
        start = layer.index("    local nextGuildPoll = os.time() + 5\n")
        end = layer.index("    end, 1, false)", start) + len("    end, 1, false)")
        ui_lua.execute(layer[start:end])
        for _ in range(50):
            ui_lua.globals().tick(4)
        self.assertEqual(ui_lua.globals().counts(), (0, False))
        for _ in range(50):
            ui_lua.globals().tick(5)
        self.assertEqual(ui_lua.globals().counts(), (1, False))
        ui_lua.globals().tick(10)
        self.assertEqual(ui_lua.globals().counts(), (2, False))
        start, end = layer.index("function chat.clear(self)"), layer.index("function chat.getSizeTable(")
        ui_lua.execute("chat={}")
        ui_lua.execute(layer[start:end])
        ui_lua.execute("chat.clear(self)")
        self.assertEqual(ui_lua.globals().counts(), (2, True))

        shop = ui_lua.execute(source("assets/scripts/Layer_guild_shop2.so"))
        ui_lua.globals().gamedata = ui_lua.table_from({"config": {"gang2_shop": CONFIG["gang2_shop"]}}, recursive=True)
        shop.gangdata = ui_lua.table_from({"level": 15})
        shop.makeConfig(shop)
        self.assertEqual(len(shop.configdata), 19)
        shop.gangdata.level = 1
        shop.makeConfig(shop)
        self.assertEqual(len(shop.configdata), 3)
        ui_lua.execute(source("assets/scripts/UIGang.so"))
        ui_lua.execute('''
            printT=function() end
            local shifted,reloaded=0,0
            GameScene={layers={gang_main={show=true,module={reloaddata=function(_,data)
                assert(data.id==1); reloaded=reloaded+1 end}},gang_xianchi={show=false},
                activity={module={pageTable={}}},main={show=false}},
                shiftLayer=function(_,name) assert(name=="gang_list"); shifted=shifted+1 end}
            UIGangUserGang2({gang2status={}})
            assert(shifted==1 and reloaded==0)
            UIGangUserGang2({gang2status={id=1}})
            assert(shifted==1 and reloaded==1)
        ''')


    def aged(self):
        self.level(15)
        state = self.shared()
        row = state["guilds"]["1"]
        row["created_at"] = self.now - 4 * 86400
        for member in row["members"].values():
            member["joined_at"] = self.now - 3 * 86400
        guild.write(self.root / "guilds.json", state)

    def test_technology_applies_real_stats_and_fixed_damage_without_double_application(self):
        from zyj_server import battle, guild_skill
        self.aged()
        self.contribution(1000000)
        before, _ = battle.rosters(self.sessions[1].save, CONFIG["copy"]["42101"]["1"], CONFIG)
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 2262)), [0] * 4)
        for index in range(1, 5):
            self.success(1, 2263, values=[index])
        after, _ = battle.rosters(self.sessions[1].save, CONFIG["copy"]["42101"]["1"], CONFIG)
        for pos in before:
            self.assertEqual(after[pos]["hp"] - before[pos]["hp"], CONFIG["gang2_skill_level"]["1"]["hp"])
            self.assertEqual(after[pos]["atk"] - before[pos]["atk"], CONFIG["gang2_skill_level"]["1"]["atk"])
            self.assertEqual(after[pos]["flat_out"] - before[pos]["flat_out"], CONFIG["gang2_skill_level"]["1"]["adddmg"])
        self.reconnect()
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 2262)), [1] * 4)
        self.assertEqual(guild_skill.bonuses(self.sessions[1].save, CONFIG)[1], 125)
        self.assert_rejected_unchanged(1, 2263, values=[5])

    def test_boss_real_damage_shared_hp_and_personal_limits(self):
        self.aged()
        status = self.success(1, 4840)
        self.assertTrue(status)
        initial = self.shared()["guilds"]["1"]["boss"]["hp"]
        self.success(1, 4843)
        self.assertEqual(self.shared()["guilds"]["1"]["boss"]["inspire"], 1)
        result = self.success(1, 4844)
        battle_raw = next(v for n, w, v in protocol.iter_pb_fields(result) if (n, w) == (6, 2))
        report = json.loads(next(v for n, w, v in protocol.iter_pb_fields(battle_raw) if (n, w) == (5, 2)))
        remaining = sum(u["h"] for u in report["endmeta"]["defense"].values())
        self.assertEqual(self.shared()["guilds"]["1"]["boss"]["hp"], remaining)
        self.assertEqual(self.sessions[1].save["last_guild_boss"]["damage"], initial - remaining)
        for _ in range(2):
            self.success(2, 4844)
        self.assertEqual(self.sessions[2].save["guild_boss"]["used"], 2)
        self.success(2, 4841)
        self.success(2, 4842)

    def test_guard_server_targets_timing_repeated_hits_and_forged_totals(self):
        self.aged()
        # 周二、四、六开放；固定到下一个周二。
        day = (self.now + 28800) // 86400
        self.clock.return_value += (2 - ((day + 3) % 7 + 1)) % 7 * 86400
        self.success(1, 5151, values=[0])
        data = protocol.parse_ids_pb(self.success(1, 5152))
        self.assertEqual(data[1], 1)
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 5152))[1], 0)
        pos, kind, token = data[2:5]
        self.success(1, 5153, values=[pos, 1, token])
        score = self.sessions[1].save["guild_guard"]["run"]["score"]
        self.success(1, 5153, values=[pos, 1, token])
        self.assertEqual(self.sessions[1].save["guild_guard"]["run"]["score"], score)
        self.assert_rejected_unchanged(1, 5156, values=[99999999, 4, 4, 4, 4, 4])
        self.success(1, 5156)
        self.assertEqual(self.sessions[1].save["guild_guard"]["total"], score)
        self.reconnect()
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 5150))[1], score)

    def test_room_status_projects_only_own_active_tiers_without_writing_or_granting(self):
        self.aged()
        self.give(20073, 20)
        for opcode in (2272, 2282):
            self.success(1, opcode, values=[1, 2, 0])
        before = copy.deepcopy(self.sessions[1].save)
        shared = (self.root / "guilds.json").read_bytes()
        disk = self.store.path(1).read_bytes()
        status = protocol.parse_ids_pb(dict(protocol.get_comb_messages(self.success(1, 2230)))[2])
        self.assertEqual(status[4:], [0, 1, 0, 0, 1, 0])
        self.assertEqual(self.sessions[1].save, before)
        self.assertEqual(self.store.path(1).read_bytes(), disk)
        self.assertEqual((self.root / "guilds.json").read_bytes(), shared)
        other = protocol.parse_ids_pb(dict(protocol.get_comb_messages(self.success(2, 2230)))[2])
        self.assertEqual(other[4:], [0] * 6)
        self.reconnect()
        status = protocol.parse_ids_pb(dict(protocol.get_comb_messages(self.success(1, 2230)))[2])
        self.assertEqual(status[4:], [0, 1, 0, 0, 1, 0])

    def test_room_status_projects_unsettled_finished_rewards_then_clears_after_claim(self):
        self.aged()
        for base, count in ((2270, 10), (2280, 5)):
            self.give(20073, count)
            self.success(1, base + 2, values=[1, 2, 0])
            self.clock.return_value += 60
            self.success(1, base + 5)
            self.clock.return_value += 31
            self.reconnect()
            before = copy.deepcopy(self.sessions[1].save)
            shared = (self.root / "guilds.json").read_bytes()
            disk = self.store.path(1).read_bytes()
            status = protocol.parse_ids_pb(dict(protocol.get_comb_messages(self.success(1, 2230)))[2])
            offset = 4 if base == 2270 else 7
            self.assertEqual(status[offset:offset + 3], [1, 0, 0])
            self.assertEqual(self.sessions[1].save, before)
            self.assertEqual(self.store.path(1).read_bytes(), disk)
            self.assertEqual((self.root / "guilds.json").read_bytes(), shared)
            self.success(1, base + 3)
            status = protocol.parse_ids_pb(dict(protocol.get_comb_messages(self.success(1, 2230)))[2])
            self.assertEqual(status[offset:offset + 3], [0, 0, 0])

    def test_room_status_never_exposes_another_identity_or_stale_room(self):
        self.aged()
        self.give(20073, 10)
        self.success(1, 2272, values=[1, 2, 0])
        from zyj_server import guild_rooms
        row = self.shared()["guilds"]["1"]
        save = copy.deepcopy(self.sessions[1].save)
        saves = {a: s.save for a, s in self.sessions.items()}
        original = copy.deepcopy((row, save))
        self.assertEqual(guild_rooms.status(row, save, 1, saves, CONFIG, self.now), [0, 1, 0, 0, 0, 0])
        self.assertEqual((row, save), original)
        row["rooms"]["1"]["members"]["1"]["identity"] += 1
        self.assertEqual(guild_rooms.status(row, save, 1, saves, CONFIG, self.now), [0] * 6)
        row = original[0]
        save["guild_room_state"]["feast"]["room"] = 999
        self.assertEqual(guild_rooms.status(row, save, 1, saves, CONFIG, self.now), [0] * 6)

    def test_actual_activity_page_restores_rooms_and_requests_finished_rewards(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("原生公会活动界面验证需 lupa.lua51")
        from build_local_apk import read_script
        self.aged()
        self.give(20073, 20)
        for opcode in (2272, 2282):
            self.success(1, opcode, values=[1, 2, 0])
        lua = LuaRuntime()
        lua.execute('''
            print=function() end
            requests={}
            UIRequest=function(t) requests[#requests+1]=t end
            gameWindows={openWindow=function() error("active room must be restored") end}
            local node={setSwallowsTouch=function() end,setTouchPriority=function() end,
                addHandleOfControlEvent=function() end,setVisible=function() end,setString=function() end}
            items=setmetatable({},{__index=function() return node end})
            setSpriteFrameByName=function() end
            ui={ccbNameEx=function(a,b) return a..b end}
            gamedata={cache={gang2status={}},config={global_kv={}}}
        ''')
        native = read_script("gamedata").decode()
        lua.execute(native[native.index("function gamedata.Gang2Status2("):native.index("--公会军团动态的数据", native.index("function gamedata.Gang2Status2("))])
        page = lua.execute(read_script("Layer_guildActivity").decode())
        page.rootItems = lua.globals()["items"]
        def load():
            values = protocol.parse_ids_pb(dict(protocol.get_comb_messages(self.success(1, 2230)))[2])
            lua.globals().gamedata.Gang2Status2(lua.globals().gamedata, lua.table_from(values))
            page.gang = lua.globals().gamedata.cache.gang2status
        load()
        page.skip(page, 1)
        page.skip(page, 2)
        requests = lua.globals().requests
        self.assertEqual([(requests[i].type, requests[i].roomid) for i in (1, 2)], [(2272, 1), (2282, 1)])
        self.clock.return_value += 60
        for opcode in (2275, 2285):
            self.success(1, opcode)
        self.clock.return_value += 31
        load()
        page.reload(page, page.gang)
        self.assertEqual([requests[i].type for i in (3, 4)], [2273, 2283])

    def test_feast_and_bonfire_real_members_elapsed_rewards_and_no_repeat_claim(self):
        self.aged()
        for base, cid, count in ((2270, 20073, 10), (2280, 20073, 5)):
            with self.subTest(base=base):
                self.give(cid, count)
                self.success(1, base + 2, values=[1, 2, 0])
                self.success(2, base + 2, values=[1, 1, 0])
                self.clock.return_value += 60
                self.success(1, base + 5)
                before = copy.deepcopy(self.sessions[1].save)
                self.clock.return_value += 5
                self.success(1, base + 4)
                self.success(1, base + 3)
                if base == 2270:
                    self.assertGreater(self.sessions[1].save["role_state"]["exp"], before["role_state"]["exp"])
                else:
                    self.assertGreater(self.sessions[1].save["guild_daily_state"]["contribution"], before["guild_daily_state"]["contribution"])
                after = copy.deepcopy(self.sessions[1].save)
                self.success(1, base + 3)
                self.assertEqual(self.sessions[1].save["role_state"], after["role_state"])
                self.success(2, base + 7)
                self.clock.return_value += 30
                self.success(2, base + 3)

    def test_activity_invitation_validates_room_type_and_sender_membership(self):
        self.aged()
        self.assert_rejected_unchanged(1, 2290, values=[1, 1, 1])
        self.give(20073, 10)
        self.success(1, 2272, values=[1, 2, 0])
        self.assertTrue(self.success(1, 2290, values=[1, 1, 1]))
        self.assertIn("&&&1", self.chats(self.success(2, 3010, values=[0]))[0][1])
        self.assert_rejected_unchanged(2, 2290, values=[1, 1, 1])
        self.assert_rejected_unchanged(1, 2290, values=[6, 1, 1])

    def war_time(self, hour):
        from zyj_server import guild_war
        day, base = guild_war.schedule(CONFIG, self.now)
        if base + hour * 3600 < self.now:
            base += 7 * 86400
        self.clock.return_value = base + hour * 3600
        return base

    def test_war_signup_roster_real_npc_reports_ownership_and_persisted_rewards(self):
        self.aged()
        base = self.war_time(9)
        self.success(1, 2130)
        self.success(1, 2132, values=[7])
        self.assert_rejected_unchanged(2, 2132, values=[8])
        self.clock.return_value = base + 20 * 3600
        self.success(1, 2135, values=[7, 1])
        self.success(1, 2136)
        self.success(1, 2137)
        self.clock.return_value = base + 22 * 3600
        self.success(1, 2138, values=[7])
        war = self.shared()["war"]
        self.assertEqual(war["stage"], 2)
        self.assertTrue(war["fights"])
        fight = war["fights"][0]
        self.assertTrue(fight["reports"])
        report = self.success(1, 2141, values=[7, fight["id"], 1])
        self.assertTrue(next(v for n, w, v in protocol.iter_pb_fields(report) if (n, w) == (5, 2)))
        self.assertEqual(war["owners"]["7"], fight["winner"])
        self.reconnect()
        self.success(1, 2144)
        if fight["winner"] == 1:
            self.success(1, 2142, values=[7])
            self.assert_rejected_unchanged(1, 2142, values=[7])

    def test_shared_activity_commit_recovers_paid_inspire_and_war_root_once(self):
        self.aged()
        self.success(1, 4840)
        original = storage.atomic_write
        def fail_publish(path, raw):
            data = json.loads(raw) if Path(path).name == "guilds.json" else {}
            row = data.get("guilds", {}).get("1", {})
            if row.get("boss", {}).get("inspire") and "pending_action" not in row:
                raise OSError("shared publish failed")
            return original(path, raw)
        gold = self.sessions[1].save["role_state"]["gold"]
        with patch.object(storage, "atomic_write", side_effect=fail_publish), self.assertRaises(OSError):
            self.request(1, 4843)
        self.reconnect()
        self.success(1, 4840)
        self.assertEqual(self.shared()["guilds"]["1"]["boss"]["inspire"], 1)
        self.assertEqual(self.sessions[1].save["role_state"]["gold"], gold - 200)
        self.war_time(9)
        self.success(1, 2130)
        before = copy.deepcopy(self.sessions[1].save)
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 2132, values=[1])
        self.assertEqual(self.sessions[1].save, before)
        self.success(1, 2130)
        self.assertEqual(self.shared()["war"]["signups"], {})
        self.success(1, 2132, values=[1])
        self.assertEqual(self.shared()["war"]["signups"], {"1": [1]})

    def test_rooms_partial_material_price_quote_chain_conversion_and_reconnect_settlement(self):
        self.aged()
        self.give(20073, 3)
        self.assert_rejected_unchanged(1, 2272, values=[1, 2, 34])
        self.success(1, 2272, values=[1, 2, 35])
        self.assertEqual(self.count(20073), 0)
        self.assert_rejected_unchanged(1, 2275)
        self.clock.return_value += 60
        self.success(1, 2275)
        self.give(20073, 10)
        self.success(1, 2276, values=[0])
        self.assertEqual(self.sessions[1].save["guild_room_state"]["feast"]["hosted"], 2)
        self.sessions[1].save["role_state"]["level"] = 130
        self.success(1, 2278, values=[1])
        self.clock.return_value += 60
        self.reconnect()
        self.success(1, 2271)
        state = copy.deepcopy(self.sessions[1].save)
        self.success(1, 2271)
        self.assertEqual(self.sessions[1].save["role_state"], state["role_state"])
        self.assertGreater(self.sessions[1].save["guild_room_state"]["converted_exp"], 0)
        self.success(1, 2272, values=[2, 2, 100])

    def test_guard_daily_score_boxes_and_rank_prizes_are_durable(self):
        self.aged()
        self.success(1, 5150)
        state = self.sessions[1].save["guild_guard"]
        state.update(total=500, high=500)
        player.save_role(self.sessions[1].save, self.store.path(1), COUNTS)
        self.success(1, 5154, values=[1])
        self.assert_rejected_unchanged(1, 5154, values=[1])
        row = self.shared()["guilds"]["1"]
        row["guard_scores"] = {str((self.now + 28800) // 86400): {"1": {"identity": self.sessions[1].save["created_at"], "score": 500}}}
        self.update_guild(guard_scores=row["guard_scores"])
        before = self.sessions[1].save["role_state"]["gold"]
        self.clock.return_value += 86400
        self.success(1, 5150)
        self.assertEqual(self.sessions[1].save["role_state"]["gold"] - before, 300)
        self.reconnect()
        self.success(1, 5150)
        self.assertEqual(self.sessions[1].save["role_state"]["gold"] - before, 300)
        self.assertEqual(self.sessions[1].save["guild_guard"]["total"], 0)

    def test_technology_all_configured_levels_and_formation_projection_preserve_bonuses(self):
        from zyj_server import battle, formation, guild_skill
        self.aged()
        save = self.sessions[1].save
        save["role_state"]["level"] = 150
        for level in range(1, 151):
            self.contribution(100000000)
            for index in range(1, 5):
                self.success(1, 2263, values=[index])
        self.assertEqual(save["guild_skills"] if "guild_skills" in save else self.sessions[1].save["guild_skills"], [150] * 4)
        before = copy.deepcopy(self.sessions[1].save)
        slots = formation.records(bytes.fromhex(before["world_state"]["1002"]), 4, 1)
        temporary = copy.deepcopy(before)
        formation.apply_slots(temporary, slots, CONFIG)
        self.assertEqual(temporary["role_state"]["power"], before["role_state"]["power"])
        self.assertEqual(guild_skill.bonuses(before, CONFIG)[1], CONFIG["gang2_skill_level"]["150"]["adddmg"])
        self.assert_rejected_unchanged(1, 2263, values=[1])

    @classmethod
    def all_client_sources(cls):
        if not hasattr(cls, "_all_sources"):
            import build_local_apk as builder
            with redirect_stdout(io.StringIO()):
                scripts = builder.get_patched_lua_scripts()
            cls._all_sources = {}
            for path, raw in scripts.items():
                data = builder.xxtea_decrypt(raw, builder.XXTEA_KEY)
                cls._all_sources[path] = data[:struct.unpack("<I", data[-4:])[0]]
        return cls._all_sources

    def test_actual_packaged_protobuf_callbacks_for_technology_guard_rooms_boss_and_war(self):
        import build_local_apk as builder
        import test_activity_copy
        self.config = CONFIG
        lua = test_activity_copy.ActivityCopyTests.network_lua(self)
        for name in ("params_pb", "gangstatus_pb", "gangbroadcasts_pb", "stringcontent_pb", "gangs_pb", "players_pb", "gangmembers_pb", "combmessages_pb", "worldboss1_pb", "worldboss1realnotify_pb"):
            lua.execute(builder.read_script(name, "pb"))
        native = builder.read_script("gamedata").decode().replace("\r\n", "\n")
        for first, last in (("GangBoss", "CangjinggeData"), ("gangSkill", "DevilFotressStatus"), ("GangGuardData", "ActivityShare"),
                            ("GuildWarTakeWarPointData", "GangSkill"), ("GuildWarInspire", "FavoriteCheck"), ("playerdata", "chatData")):
            start = native.index(f"function gamedata.{first}(")
            end = native.index(f"function gamedata.{last}(", start) if last != "GangSkill" else native.index("--工会技能", start)
            lua.execute(native[start:end].encode())
        lua.execute(b'''gamedata.cache.gang2skill={};gamedata.cache.gang2status={contribution=1000000};gamedata.cache.guildwarmain={}
            gamedata.cache.guildwarpointquery={};gamedata.cache.guildwarjionconfirm={};gamedata.cache.guildchecklist={}
            gamedata.cache.GuildWarMembers={};gamedata.cache.GuildWarPrepare={};gamedata.cache.GuildWarInspire={}
            gamedata.cache.role.gold=10000000;gamedata.cache.role.coin=10000000
            gamedata.updateRoleGold=function(self,n) self.cache.role.gold=self.cache.role.gold+n end
            gamedata.updateRoleCoin=function(self,n) self.cache.role.coin=self.cache.role.coin+n end
            gamedata.time=function() return 1793430000 end
            gamedata.SomethingProcess=function(self,p) return {} end''')
        scripts = self.all_client_sources()
        for name in ("GameGang", "GameGuildWar"):
            lua.execute(scripts[f"assets/scripts/{name}.so"])
        def callback(name, body):
            return lua.globals()[name.encode()](lua.table_from({b"rbuf": body}))
        self.aged()
        self.contribution(1000000)
        callback("NetGangSkillQuery", self.success(1, 2262))
        callback("NetGang2BossCallBack", self.success(1, 4840))
        response = callback("NetGang2BossBattleCallBack", self.success(1, 4844))
        self.assertTrue(json.loads(response[b"battlereport"]))
        self.give(20073, 10)
        room = callback("NetGangCreateJoinFeastCallBack", self.success(1, 2272, values=[1, 2, 0]))
        self.assertEqual(room[b"data"][b"feastPlayers"][1][b"params"][1][b"i"], 1)
        self.assertEqual(room[b"data"][b"feastPlayers"][1][b"params"][2][b"i"], 1)
        lua.globals().UIGangGetFeastRewardCallBack(lua.table_from({b"beinum": 1, b"roomid": 1, b"personnum": 1}))
        reply = callback("NetGangGetFeastRewardCallBack", self.success(1, 2273))
        self.assertEqual((reply[b"roomid"], reply[b"personNum"]), (1, 1))
        self.assertIsNone(lua.globals().gameConfig)
        base = self.war_time(9)
        callback("NetGuildWarPointCatalogueCallBack", self.success(1, 2130))
        self.assertEqual(lua.globals().gamedata[b"cache"][b"guildwarmain"][b"allpointsdata"][1][b"id"], 0)
        self.success(1, 2132, values=[7])
        self.clock.return_value = base + 20 * 3600
        callback("NetGangPointEnterBattlefieldCallBack", self.success(1, 2134, values=[7]))
        self.success(1, 2135, values=[7, 1])
        prepare = dict(self.business_rows(self.success(1, 2134, values=[8])))
        self.assertEqual(protocol.parse_ids_pb(prepare[0])[0], 7)
        self.clock.return_value = base + 22 * 3600
        callback("NetGangPointBattleStatusQueryCallBack", self.success(1, 2138, values=[7]))
        fight = self.shared()["war"]["fights"][0]
        callback("NetGangPointBraBattlePlayCallBack", self.success(1, 2141, values=[7, fight["id"], 1]))
        day = (int(self.clock.return_value) + 28800) // 86400
        self.clock.return_value += (2 - ((day + 3) % 7 + 1)) % 7 * 86400
        self.success(1, 5151, values=[0])
        data = callback("NetGang2GroundGetHogsCallBack", self.success(1, 5152))
        self.assertEqual(data[b"mouseNum"], 1)
        callback("NetGang2GroundCatchHogCallBack", self.success(1, 5153, values=[data[b"mouseTab"][1][b"point"], 1, data[b"mouseTab"][1][b"token"]]))

    def test_all_boss_profiles_and_nine_strongholds_convert_actual_animation_assets(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("实际动画验证需要lupa.lua51")
        import build_local_apk as builder
        from zyj_server import arena, battle, guild_boss
        self.aged()
        config = dict(CONFIG)
        with zipfile.ZipFile(ROOT / "configs_sec5.zip") as archive:
            for name in ("generalanimation", "skillanimation"):
                config[name] = json.loads(archive.read("5/" + name + ".json"))
        lua = LuaRuntime()
        lua.globals().gamedata = lua.table_from({"config": config}, recursive=True)
        lua.execute('''print=function() end;printT=print;battleScene={slotNum=7}
            table.getTableLength=function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
            CCFileUtils={sharedFileUtils=function(self) return self end,fullPathForFilename=function(self,p) return p end}
            ui={Split=function(s,sep) local t={} for v in string.gmatch(s,'[^'..sep..']+') do t[#t+1]=v end return t end}''')
        lua.execute(self.all_client_sources()["assets/scripts/battleReportConvert.so"])
        lua.execute(builder.read_script("BattleReportAbbToKey"))
        before = copy.deepcopy(self.sessions[1].save)
        with zipfile.ZipFile(builder.SRC_APK) as archive:
            names, cache = archive.namelist(), {}
            lua.globals().CCFileUtils.isFileExist = lambda _, path: any(n.endswith("/" + path) for n in names)
            def asset(path):
                if path not in cache:
                    matches = [n for n in names if n.endswith("/" + path)]
                    self.assertEqual(len(matches), 1, path)
                    cache[path] = json.loads(archive.read(matches[0]))
                return lua.table_from(cache[path], recursive=True)
            lua.globals().LoadJsonFileToTable = asset
            def convert(report):
                native = lua.table_from(json.loads(lua.globals().ReplaceAbbToKey(json.dumps(report))), recursive=True)
                attack, defense = lua.globals().getBattleInitSlotInfo(native)
                animations, ext = lua.globals().convertBattleReportToAnimationSub(native, attack, defense, None, "worldboss")
                self.assertGreater(len(animations), 0)
                for side, key in (("attack", "atk"), ("defense", "def")):
                    for pos, unit in report["endmeta"][side].items():
                        self.assertEqual(ext.endinfo[key][pos].hp, unit["h"])
            for cid, row in config["gang2_boss"].items():
                save, shared = copy.deepcopy(before), copy.deepcopy(self.shared())
                shared["guilds"]["1"]["boss"] = {"cid": int(cid), "hp": row["hp"], "born": self.now,
                    "revive": 0, "round": 1, "inspire": 0, "damage": {}, "pending": {}}
                with patch("secrets.randbits", return_value=7):
                    raw, _, _ = guild_boss.prepare(4844, b"", shared, "1", save, {1: save}, 1, config, self.now)
                data = next(v for n, w, v in protocol.iter_pb_fields(raw) if (n, w) == (6, 2))
                convert(json.loads(next(v for n, w, v in protocol.iter_pb_fields(data) if (n, w) == (5, 2))))
            for city in config["gang2_cityaward"].values():
                for npc in city["npc"].strip(";").split(";"):
                    attack, defense = arena.rosters(before, config["athletics_copy2"][npc], config)
                    convert(battle.simulate(attack, defense, config, 7))
        self.assertEqual(self.sessions[1].save, before)

    def test_nine_city_rewards_real_multiplayer_winners_and_effects_do_not_duplicate(self):
        from zyj_server import battle, guild_war
        self.aged()
        self.success(3, 2231, text="对手公会")
        for a in (1, 3):
            save = self.sessions[a].save
            world = bytes.fromhex(save["world_state"]["1002"])
            values = []
            for n, w, raw in protocol.iter_pb_fields(world):
                if (n, w) == (1, 2):
                    for f, value in ((6, 10000000 if a == 1 else 100), (7, 10000000 if a == 1 else 10), (8, 100000000 if a == 1 else 1000), (9, 300 if a == 1 else 50)):
                        raw = protocol.pb_set_varint(raw, f, value)
                values.append(protocol.encode_pb_field(n, w, raw))
            save["world_state"]["1002"] = b"".join(values).hex()
            player.save_role(save, self.store.path(a), COUNTS)
        state = self.shared()
        row = state["guilds"]["2"]
        row["created_at"] = self.now - 4 * 86400
        row["experience"] = state["guilds"]["1"]["experience"]
        row["members"]["3"]["joined_at"] = self.now - 3 * 86400
        base = self.war_time(9)
        war, _, _ = guild_war.get_state(state, CONFIG, int(self.clock.return_value))
        for city in range(1, 10):
            with self.subTest(city=city):
                war.update(signups={"1": [city], "2": [city]}, teams={
                    str(a): {"guild": 1 if a == 1 else 2, "point": city, "identity": self.sessions[a].save["created_at"],
                             "snapshot": guild_war.freeze(self.sessions[a].save)} for a in (1, 3)},
                    stage=0, finalists={}, fights=[], owners={}, inspire={})
                shared = copy.deepcopy(state)
                guild_war.settle(shared, {a: s.save for a, s in self.sessions.items()}, CONFIG, base + 22 * 3600)
                result = shared["war"]
                self.assertEqual(result["owners"][str(city)], 1)
                self.assertTrue(result["fights"][0]["reports"])
                self.assertEqual(guild_war.benefit(shared, 1, CONFIG, base + 22 * 3600), CONFIG["gang2_cityaward"][str(city)]["bonus_id"])
                before = copy.deepcopy(result["pending"])
                guild_war.settle(shared, {a: s.save for a, s in self.sessions.items()}, CONFIG, base + 22 * 3600 + 1)
                self.assertEqual(shared["war"]["pending"], before)

    def test_guard_expired_target_nonce_cannot_hit_reused_position(self):
        self.aged()
        day = (self.now + 28800) // 86400
        self.clock.return_value += (2 - ((day + 3) % 7 + 1)) % 7 * 86400
        self.success(1, 5151, values=[0])
        with patch("secrets.randbits", return_value=7):
            first = protocol.parse_ids_pb(self.success(1, 5152))
            self.clock.return_value += 2.5
            second = protocol.parse_ids_pb(self.success(1, 5152))
        self.assertEqual(first[2], second[2])
        self.assertNotEqual(first[4], second[4])
        self.assert_rejected_unchanged(1, 5153, values=[first[2], 1, first[4]])
        self.success(1, 5153, values=[second[2], 1, second[4]])

    def test_guard_target_nonce_is_not_reused_after_new_run_and_reconnect(self):
        self.aged()
        day = (self.now + 28800) // 86400
        self.clock.return_value += (2 - ((day + 3) % 7 + 1)) % 7 * 86400
        self.success(1, 5151, values=[0])
        with patch("secrets.randbits", return_value=7):
            first = protocol.parse_ids_pb(self.success(1, 5152))
            for elapsed in (0, 2 * 86400):
                self.success(1, 5156)
                self.clock.return_value += elapsed
                self.reconnect()
                self.success(1, 5151, values=[0])
                second = protocol.parse_ids_pb(self.success(1, 5152))
                self.assertEqual(first[2], second[2])
                self.assert_rejected_unchanged(1, 5153, values=[first[2], 1, first[4]])
                self.assertNotEqual(first[4], second[4])
                self.success(1, 5153, values=[second[2], 1, second[4]])
                first = second

    def test_boss_kill_prizes_survive_reconnect_and_revive_advances_one_profile(self):
        self.aged()
        self.success(1, 4840)
        row = self.shared()["guilds"]["1"]
        row["boss"]["hp"] = 1
        self.update_guild(boss=row["boss"])
        self.success(1, 4844)
        self.assertEqual(self.shared()["guilds"]["1"]["boss"]["hp"], 0)
        self.assertIn("1", self.shared()["guilds"]["1"]["boss"]["pending"])
        coin = self.sessions[1].save["role_state"]["coin"]
        self.reconnect()
        self.success(1, 4840)
        self.assertEqual(self.sessions[1].save["role_state"]["coin"] - coin, 2000000)
        self.success(1, 4840)
        self.assertEqual(self.sessions[1].save["role_state"]["coin"] - coin, 2000000)
        self.clock.return_value += 1800
        self.success(1, 4840)
        self.assertEqual(self.shared()["guilds"]["1"]["boss"]["cid"], 32002)

    def test_occupation_benefits_change_real_campaign_and_strengthening_not_snapshots(self):
        from zyj_server import guild_war, training
        self.aged()
        self.success(1, 2130)
        shared = self.shared()
        shared["war"]["owners"] = {"1": 1}
        guild.write(self.root / "guilds.json", shared)
        self.assertEqual(self.store.guild_profit(1, self.now), 19000)
        self.assertEqual(self.store.guild_profit(2, self.now), 19000)
        self.assertEqual(self.store.guild_profit(3, self.now), 0)
        base = copy.deepcopy(self.sessions[1].save)
        world = bytes.fromhex(base["world_state"]["1002"])
        iid = next(protocol.parse_ids_pb(raw)[0] for n, w, raw in protocol.iter_pb_fields(world) if (n, w) == (2, 2)
                   and CONFIG["equip"][str(protocol.parse_ids_pb(raw)[1])]["type"] in ("weapon", "armor", "head", "accessory"))
        normal, discounted = copy.deepcopy(base), copy.deepcopy(base)
        discounted["guild_profit"] = 19000
        body = protocol.encode_pb_field(1, 0, iid)
        raw, _ = training.strengthen(normal, 1101, body, CONFIG, 7)
        reduced, _ = training.strengthen(discounted, 1101, body, CONFIG, 7)
        def paid(data):
            value = protocol.pb_get_varint(data, 1)
            return (1 << 64) - value
        self.assertEqual(paid(reduced), paid(raw) * 80 // 100)
        for cid, kind, amount in ((19001, 1, 15), (19002, 4, 15), (19003, 2, 20), (19004, 3, 15), (19005, 1, 10),
                                  (19006, 4, 5), (19007, 3, 10), (19008, 1, 5)):
            self.assertEqual(guild_war.effect({"guild_profit": cid}, CONFIG, kind), amount)

    def test_live_room_ui_has_single_validated_invite_real_poll_and_target_tokens(self):
        sources = self.all_client_sources()
        for name, opcode in (("Layer_guild_feast", 2274), ("Layer_guild_zaotang", 2284)):
            source = sources[f"assets/scripts/{name}.so"].decode()
            self.assertNotIn('type = 3011, content = ', source)
            self.assertIn(f"type={opcode},roomid=self.roomId", source)
            self.assertIn("os.time()>=nextPoll", source)
            self.assertIn("unscheduleScriptEntry(self.localRoomPoll)", source)
        source = sources["assets/scripts/Layer_guild2_guard.so"].decode()
        self.assertIn("token=targetToken", source)
        self.assertIn("self.mouseHoleData[i].token=targetToken", source)
        servers = sources["assets/scripts/gameserver.so"].decode()
        self.assertIn("[5152] = NetGang2GroundGetHogsCallBack", servers)
        self.assertIn("[5153] = NetGang2GroundCatchHogCallBack", servers)

    def test_room_guest_decay_resets_at_real_midnight_without_regranting_old_seconds(self):
        self.aged()
        day = (self.now + 28800) // 86400
        midnight = (day + 1) * 86400 - 28800
        self.clock.return_value = midnight - 70
        self.give(20073, 10)
        self.success(1, 2272, values=[1, 2, 0])
        self.success(2, 2272, values=[1, 1, 0])
        self.clock.return_value += 60
        self.success(1, 2275)
        self.clock.return_value = midnight + 5
        self.success(2, 2273)
        self.assertEqual(self.sessions[2].save["guild_room_state"]["feast"]["seconds"], 5)
        role = copy.deepcopy(self.sessions[2].save["role_state"])
        self.success(2, 2273)
        self.assertEqual(self.sessions[2].save["role_state"], role)




if __name__ == "__main__":
    unittest.main()
