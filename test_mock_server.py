from contextlib import redirect_stderr, redirect_stdout
import copy
from fractions import Fraction
import io
import json
import os
from pathlib import Path
import struct
import subprocess
import sys
import tempfile
import threading
import socket
import unittest
import zipfile
from unittest.mock import patch

import mock_server as server
import build_local_apk as apk_builder
from zyj_server import accounts, activities, battle, blackmarket, daily_events, development, diagnostics, formation, guide, mieshendian, pets, player, protocol, qiankun, ranking, recharge, recruit, replay, rob, secret_shop, shop, star_copy, training, welfare
from zyj_server.session import Session


LOGIN_PASSWORD = "test-password-123"


def login_request(account, seq=0, password=LOGIN_PASSWORD):
    identity = protocol.encode_pb_field(2, 2, f"local_account_{account}".encode("ascii"))
    body = protocol.encode_pb_field(1, 2, identity)
    if password is not None:
        body += protocol.encode_pb_field(1, 2, protocol.encode_pb_field(2, 2, password.encode("ascii")))
    return {"opcode": 1000, "seq": seq, "hex": body.hex()}


class ReplayConnection:
    def __init__(self, requests, chunk_size, account=1, login=True):
        self.hide_login_reply = bool(login and requests and requests[0]["opcode"] != 1000)
        if login:
            requests = [login_request(account, f["seq"]) if f["opcode"] == 1000 else f for f in requests]
            if self.hide_login_reply:
                requests.insert(0, login_request(account))
        stream = b"".join(protocol.pack_frame(f["opcode"], f["seq"], bytes.fromhex(f["hex"])) for f in requests)
        self.chunks = iter(stream[i:i + chunk_size] for i in range(0, len(stream), chunk_size))
        self.responses = []
        self.closed = False

    def settimeout(self, timeout):
        self.timeout = timeout

    def setsockopt(self, level, option, value):
        pass

    def recv(self, size):
        chunk = next(self.chunks, b"")
        assert len(chunk) <= size
        return chunk

    def sendall(self, data):
        magic, length, opcode, seq = struct.unpack(">IIII", data[:16])
        assert magic == 0xEE1C and len(data) == 16 + length
        if self.hide_login_reply and opcode == 1000 and seq == 0:
            self.hide_login_reply = False
            return
        self.responses.append({"opcode": opcode, "seq": seq, "hex": data[16:].hex()})

    def close(self):
        self.closed = True


class ProtagonistBattleTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.config = player.load_role_config(server.CONFIG_ZIP)

    def unit(self, cid=10101, **values):
        return {"cid": cid, "iid": cid, "level": 1, "advance": 0, "exp": 0, "atk": 100,
                "def": values.pop("defense", 200), "hp": 1000, "speed": 100, "skill": self.config["general"][str(cid)]["skillid"], **values}

    def test_high_lead_passives_apply_ap_self_core_and_other_member_auras_on_both_sides(self):
        for direct in (True, False):
            for stage in (21, 22, 23):
                teams = {True: {2: self.unit(10201)}, False: {2: self.unit(10201)}}
                teams[direct] = {2: self.unit(advance=stage), 8: self.unit(10201, atk=10, defense=10, hp=100)}
                battle._prepare_teams(teams, self.config)
                lead, ally = teams[direct][2], teams[direct][8]
                self.assertEqual(lead["ap"], 5)
                self.assertEqual((lead["atk"], lead["def"], lead["hp"]), (130, 260, 1300) if stage == 23 else (100, 200, 1000))
                self.assertEqual((ally["atk"], ally["def"], ally["hp"]), (16, 23, 165) if stage == 23 else (10, 20 if stage == 22 else 10, 150))
                for unit in teams[direct].values():
                    self.assertEqual(unit["in_multiplier"], Fraction(4, 5) if stage >= 22 else 1)

    def test_initial_ap_caps_at_ten_and_ally_auras_do_not_feed_back_into_the_lead(self):
        teams = {True: {2: self.unit(advance=23, initial_ap=9)}, False: {2: self.unit(10201)}}
        battle._prepare_teams(teams, self.config)
        self.assertEqual(teams[True][2]["ap"], 10)
        self.assertEqual((teams[True][2]["atk"], teams[True][2]["def"], teams[True][2]["hp"]), (130, 260, 1300))

    def test_dead_allies_increase_actual_lead_attack_once_without_counting_the_lead(self):
        cid = next(int(cid) for cid, row in self.config["general"].items() if row["battle"] and row["init_cid"]
                   and self.config["skill"].get(str(row["skillid"]), {}).get("range") == "all"
                   and self.config["skill"][str(row["skillid"])]["kind"] == "attack")
        for count in (1, 2):
            totals = []
            for stage in (5, 11):
                team = {14: self.unit(advance=stage, atk=1000, defense=0, hp=1000000, speed=100, initial_ap=0)}
                team.update({pos: self.unit(10201, iid=pos, hp=1, defense=0, speed=1) for pos in (2, 4)[:count]})
                enemy = self.unit(cid, atk=100, defense=0, hp=1000000, speed=300, initial_ap=10)
                report = battle.simulate(team, {2: enemy}, self.config, 7, max_rounds=1)
                hit = next(action for action in report["b"]["a"] if action["s"].get("r") is True and action["s"].get("p") == [14])
                totals.append(next(e["m"]["m"] for e in hit["e"] if e.get("r") is False and isinstance(e.get("m"), dict)))
            self.assertEqual(totals, [1000, 1000+count*100])

    def test_fifth_round_full_heal_happens_once_not_earlier_or_on_a_dead_lead(self):
        lead = self.unit(advance=20, atk=1, defense=0, hp=10000, speed=200, initial_ap=0)
        enemy = self.unit(10201, atk=100, defense=0, hp=1000000, initial_ap=0)
        for rounds in (4, 5, 6):
            report = battle.simulate({2: lead}, {2: enemy}, self.config, 0, max_rounds=rounds)
            hp = report["endmeta"]["attack"]["2"]["h"]
            self.assertEqual(hp == 10000, rounds == 5)
            heals = [e for action in report["b"]["a"] for e in action["e"]
                     if e.get("r") is True and e.get("p") == 2 and isinstance(e.get("m"), dict) and e["m"]["m"] < 0]
            self.assertEqual(len(heals), int(rounds >= 5))
        report = battle.simulate({2: {**lead, "hp": 1}, 8: self.unit(10201, hp=1000000, atk=1, defense=0)},
                                 {2: {**enemy, "speed": 300}}, self.config, 0, max_rounds=5)
        self.assertEqual(report["endmeta"]["attack"]["2"]["h"], 0)

    def test_unknown_dynamic_static_attributes_and_scopes_still_fail_closed(self):
        config = copy.deepcopy(self.config)
        config["general"]["10201"]["break1"] = 9999991
        for changes in ({"type": 1}, {"type": 0, "attr": "unknown", "target": "1"}, {"type": 0, "attr": "atk", "target": "999"}):
            config["breakskill"]["9999991"] = {**config["breakskill"]["9100003"], "id": 9999991, **changes}
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                battle.simulate({2: self.unit(10201, advance=1)}, {2: self.unit()}, config, 0)

    def test_advanced_lead_report_is_deterministic_without_changing_persistable_inputs(self):
        attack = {2: self.unit(advance=23), 8: self.unit(10201)}
        defense = {2: self.unit(10201, hp=100000)}
        original = copy.deepcopy((attack, defense))
        report = battle.simulate(attack, defense, self.config, 7, max_rounds=6)
        self.assertEqual((attack, defense), original)
        self.assertEqual(report, battle.simulate(attack, defense, self.config, 7, max_rounds=6))
        self.assertEqual(json.loads(json.dumps(report))["meta"], report["meta"])

    def test_advanced_leads_convert_actual_animation_assets_and_preserve_healed_end_hp(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("主角高阶被动动画验证需要 lupa.lua51")
        lua = LuaRuntime()
        config = dict(self.config)
        with zipfile.ZipFile(server.CONFIG_ZIP) as archive:
            for name in ("generalanimation", "skillanimation"):
                config[name] = json.loads(archive.read("5/"+name+".json"))
        lua.globals().gamedata = lua.table_from({"config": config}, recursive=True)
        lua.execute('''print=function() end;printT=print;battleScene={slotNum=7}
            table.getTableLength=function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
            CCFileUtils={sharedFileUtils=function(self) return self end,fullPathForFilename=function(self,p) return p end}
            ui={Split=function(s,sep) local t={} for v in string.gmatch(s,'[^'..sep..']+') do t[#t+1]=v end return t end}''')
        with zipfile.ZipFile(apk_builder.SRC_APK) as archive:
            names = archive.namelist()
            lua.globals().CCFileUtils.isFileExist = lambda _, path: any(n.endswith("/"+path) for n in names)
            def asset(path):
                matches = [n for n in names if n.endswith("/"+path)]
                self.assertEqual(len(matches), 1, path)
                return lua.table_from(json.loads(archive.read(matches[0])), recursive=True)
            lua.globals().LoadJsonFileToTable = asset
            lua.execute(apk_builder.patch_combo_animation_script(apk_builder.read_script("battleReportConvert").decode().replace("\r\n", "\n")))
            lua.execute(apk_builder.read_script("BattleReportAbbToKey").decode())
            for choice in (1, 2, 3):
                cid = self.config["protagonist_grow"]["23"][f"general{choice}"]
                attack = {14: self.unit(cid, advance=23, atk=1, defense=0, hp=10000, speed=200),
                          2: self.unit(10201, hp=1, defense=0, speed=1)}
                report = battle.simulate(attack, {2: self.unit(10201, atk=1000, defense=0, hp=1000000, speed=300)}, self.config, 7, max_rounds=6)
                native = lua.table_from(json.loads(lua.globals().ReplaceAbbToKey(json.dumps(report))), recursive=True)
                allies, enemies = lua.globals().getBattleInitSlotInfo(native)
                animations, ext = lua.globals().convertBattleReportToAnimationSub(native, allies, enemies)
                self.assertGreater(len(animations), 1)
                for side, key in (("attack", "atk"), ("defense", "def")):
                    for pos, unit in report["endmeta"][side].items():
                        self.assertEqual(ext.endinfo[key][pos].hp, unit["h"])
                        self.assertEqual(ext.endinfo[key][pos].ap, unit["ap"])


class ReplayRoutingTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with redirect_stdout(io.StringIO()):
            cls.step_counts = guide.load_guide_step_counts(server.CONFIG_ZIP)
            cls.role_config = player.load_role_config(server.CONFIG_ZIP)
            cls.all_frames = replay.load_recordings(server.RECORD_PATH)
            cls.recordings = replay.split_recordings(cls.all_frames)
            cls.frames = cls.recordings[0]
            cls.tables = replay.build_routing_tables(cls.all_frames)
        cls.requests = [f for f in cls.frames if f["c2s"]]
        cls.by_seq = {f["seq"]: f for f in cls.requests}
        cls.recorded = {(f["seq"], f["opcode"]): f for f in cls.frames if not f["c2s"] and f["seq"] != 0}
        cls.activity_frames = json.loads((Path(server.BASE_DIR) / "test_activity_frames.json").read_text())

    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.save_path = Path(temp.name) / "role_save.json"
        password_work = patch.object(accounts, "PASSWORD_ITERATIONS", 1)
        password_work.start()
        self.addCleanup(password_work.stop)
        store = accounts.AccountStore(self.save_path, self.tables, self.step_counts, self.role_config)
        store.register(1, LOGIN_PASSWORD, store.snapshot(1)["revision"])
        self.now = 1800000000
        clock_patch = patch.object(player.time, "time", return_value=self.now)
        self.clock = clock_patch.start()
        self.addCleanup(clock_patch.stop)

    def run_client(self, conn):
        sendall = conn.sendall
        def send_after_login(packet):
            if conn.hide_login_reply:
                return ReplayConnection.sendall(conn, packet)
            return sendall(packet)
        with patch.object(conn, "sendall", side_effect=send_after_login):
            store = accounts.AccountStore(self.save_path, self.tables, self.step_counts, self.role_config)
            server.handle_client(conn, ("test", 0), store)

    def replay(self, requests, chunk_size=4096):
        conn = ReplayConnection(requests, chunk_size)
        with redirect_stdout(io.StringIO()) as log:
            self.run_client(conn)
        self.assertTrue(conn.closed)
        errors = [line for line in log.getvalue().splitlines() if "连接异常" in line or "载入玩家状态失败" in line]
        self.assertEqual(errors, [])
        return conn.responses

    def assert_rejected(self, request, reason):
        original = self.save_path.read_bytes()
        conn = ReplayConnection([request], 7)
        with redirect_stdout(io.StringIO()) as log:
            self.run_client(conn)
        self.assertTrue(conn.closed)
        if "载入玩家状态失败" in log.getvalue():
            self.assertEqual([(f["opcode"], f["seq"]) for f in conn.responses], [(999999, 0)])
        else:
            self.assertEqual(len(conn.responses), 0)
        self.assertEqual(self.save_path.read_bytes(), original)
        self.assertIn(reason, log.getvalue())

    def assert_recorded_response(self, response, recorded_seq, live_seq=None):
        expected = self.recorded[(recorded_seq, response["opcode"])]
        self.assertEqual(response["seq"], recorded_seq if live_seq is None else live_seq)
        if response["opcode"] in (1032, 2000):
            self.assert_replayed_payload(response["opcode"], response["hex"], expected["hex"])
        else:
            self.assertEqual(response["hex"], expected["hex"])

    def assert_replayed_payload(self, opcode, actual, expected):
        if opcode == 999900:
            actual_messages = protocol.get_comb_messages(bytes.fromhex(actual))
            expected_messages = protocol.get_comb_messages(bytes.fromhex(expected))
            self.assertEqual([mid for mid, _ in actual_messages], [mid for mid, _ in expected_messages])
            for (mid, data), (_, recorded) in zip(actual_messages, expected_messages):
                self.assert_replayed_payload(mid, data.hex(), recorded.hex())
        elif opcode == 3610:
            groups = self.begin7day_groups(bytes.fromhex(actual))
            recorded = self.begin7day_groups(bytes.fromhex(expected))
            self.assertEqual(set(groups), set(recorded))
            self.assertEqual(groups[0], recorded[0])
            self.assertEqual((groups[1][0], groups[1][29]), (recorded[1][0], recorded[1][29]))
            # This fresh day-one replay has no confirmed recharge or later-day gifts.
            self.assertTrue(all(value == 0 for i, value in enumerate(groups[1]) if i not in (0, 29)))
        elif opcode == 100:
            fields = list(protocol.iter_pb_fields(bytes.fromhex(actual)))
            self.assertEqual([(n, w) for n, w, _ in fields], [(1, 2)])
            self.assertTrue(fields[0][2].decode("utf-8"))
        elif opcode == 999905:
            values = protocol.parse_ids_pb(bytes.fromhex(actual))
            self.assertEqual(values, [int(self.clock.return_value), protocol.parse_ids_pb(bytes.fromhex(expected))[1]])
        elif opcode == 1032:
            live_ids = set(activities.HINT_IDS)
            actual_fields = list(protocol.iter_pb_fields(bytes.fromhex(actual)))
            expected_fields = list(protocol.iter_pb_fields(bytes.fromhex(expected)))
            self.assertEqual([f for f in actual_fields if not (f[:2] == (1, 0) and f[2] // 100 in live_ids)],
                             [f for f in expected_fields if not (f[:2] == (1, 0) and f[2] // 100 in live_ids)])
            self.assertTrue(all(value % 100 in (0, 1) for n, w, value in actual_fields
                                if n == 1 and w == 0 and value // 100 in live_ids))
        elif opcode == 3200:
            self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(actual)), [0] * len(self.role_config["shop"]))
        elif opcode == 2037:
            # 教程回归冻结时间，不能继承录制中已到期的在线奖励倒计时。
            self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(actual)), [1, 60])
        elif opcode == 2300:
            # 本地新号没有录制中的假好友；公开查找ID不改变自己的原生RID。
            raw = bytes.fromhex(actual)
            self.assertFalse(any((n, w) == (1, 2) for n, w, _ in protocol.iter_pb_fields(raw)))
            self.assertEqual((protocol.pb_get_varint(raw, 2), protocol.pb_get_varint(raw, 3)), (0, 1000001))
        elif opcode == 1350:
            # 这里比较新号初始化的历史应答，不能拿后续教程通关后的存档当期望。
            self.assertEqual(self.star_copy_groups(bytes.fromhex(actual)),
                             {0: [0], **{mid: [mid, -1] for mid in range(42101, 42106)}})
        elif opcode == 3730:
            raw = bytes.fromhex(actual)
            self.assertEqual(protocol.parse_ids_pb(raw), [0] * 21)
            extra = {n: v for n, w, v in protocol.iter_pb_fields(raw) if w == 2}
            self.assertEqual(set(extra), {100, 101})
            self.assertEqual(protocol.parse_ids_pb(extra[100]), [0] * 21)
            self.assertEqual(protocol.parse_ids_pb(extra[101]), [0] * 7)
        elif opcode == 1044:
            # 魔宠碎片来自当前库存，不继承录制初始化中独立赠送的50片。
            saved = json.loads(self.save_path.read_text())
            props = self.entity_records(bytes.fromhex(saved["world_state"]["1200"]), 1, 1)
            rows = self.entity_records(bytes.fromhex(actual), 1, 1)
            self.assertEqual(set(rows), set(map(int, self.role_config["pet3_fragment"])))
            for cid, raw in rows.items():
                self.assertEqual(protocol.pb_get_varint(raw, 2), protocol.pb_get_varint(props.get(cid, b""), 2) or 0)
        elif opcode == 2000:
            saved = json.loads(self.save_path.read_text())
            body = daily_events.rewrite_periods(welfare.rewrite_activities(bytes.fromhex(expected)), saved,
                                               self.role_config, int(self.clock.return_value))
            state = json.loads(self.save_path.with_name("rankings.json").read_text())
            self.assertEqual(bytes.fromhex(actual), ranking.rewrite_activities(body, state, self.role_config, int(self.clock.return_value)))
        elif opcode == 3210:
            rows = self.entity_records(bytes.fromhex(actual), 1, 1)
            self.assertEqual(set(rows), set(map(int, self.role_config["gift_bag"])))
            for cid, raw in rows.items():
                config = self.role_config["gift_bag"][str(cid)]
                self.assertEqual([protocol.pb_get_varint(raw, n) for n in (2, 3, 4)],
                                 [config["personallimit"], config["gold"], config["discount"]])
        elif opcode in (1001, 1054):
            values = {n: value for n, wire, value in protocol.iter_pb_fields(bytes.fromhex(actual))}
            recorded = {n: value for n, wire, value in protocol.iter_pb_fields(bytes.fromhex(expected))}
            # Role timers/stamina now follow local operations, not captured wall-clock regeneration.
            fields = (1, 3, 5, 6, 7, 8, 9, 11, 12, 13, 14, 21, 26, 27) if opcode == 1001 else range(1, 10)
            for field in fields:
                self.assertEqual(values.get(field, 0), recorded.get(field, 0), (opcode, field))
            if opcode == 1054:
                if 10 in recorded:
                    self.assertEqual(values.get(10), recorded[10])
                elif 10 in values:
                    # Reconnect replies may now include the last known general instead of relying on client cache.
                    general = {n: v for n, w, v in protocol.iter_pb_fields(values[10])}
                    self.assertEqual((general[2], general[3]), (values[1], values[2]))
        else:
            self.assertEqual(actual, expected)

    def role_data(self, response):
        body = bytes.fromhex(response["hex"])
        if response["opcode"] == 999900:
            body = next(data for mid, data in protocol.get_comb_messages(body) if mid == 1001)
        return {n: value for n, wire, value in protocol.iter_pb_fields(body)}

    def query_world(self, opcode):
        responses = self.replay([{"opcode": opcode, "seq": 20000, "hex": ""}])
        self.assertEqual(len(responses), 1)
        self.assertEqual((responses[0]["opcode"], responses[0]["seq"]), (opcode, 20000))
        return bytes.fromhex(responses[0]["hex"])

    def activity_request(self, opcode, values=()):
        body = b"".join(protocol.encode_pb_field(1, 0, value) for value in values)
        return {"opcode": opcode, "seq": 20000, "hex": body.hex()}

    def shop_request(self, opcode, cid, count=1):
        item = protocol.encode_pb_field(1, 0, cid) + protocol.encode_pb_field(2, 0, count)
        return {"opcode": opcode, "seq": 20000, "hex": protocol.encode_pb_field(1, 2, item).hex()}

    def test_online_reward_keeps_online_time_but_excludes_offline_time(self):
        self.complete_tutorial()
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            self.assertEqual(session.handle(2037, 1, b""), [protocol.pack_frame(2037, 1, b"\x08\x01\x08\x3c")])
            self.clock.return_value = self.now + 30
            session.handle(999904, 2, b"")
            self.assertEqual(json.loads(self.save_path.read_text())["online_reward_state"]["seconds"], 30)
            self.clock.return_value = self.now + 300
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            self.assertEqual(session.handle(2037, 3, b""), [protocol.pack_frame(2037, 3, b"\x08\x01\x08\x1e")])
            self.clock.return_value = self.now + 329
            memory, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
            error = session.handle(2038, 4, b"")
            self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in error], [999999, 1999])
            self.assertEqual((session.save, self.save_path.read_bytes()), (memory, disk))
            self.clock.return_value += 1
            before = session.save["role_state"]["coin"]
            reply = session.handle(2038, 5, b"")
            self.assertEqual(struct.unpack(">IIII", reply[0][:16])[2:], (2038, 5))
            self.assertEqual(session.save["role_state"]["coin"], before + 30000)
            self.assertEqual(session.save["online_reward_state"]["claimed"], 1)
            self.assertEqual(session.handle(2037, 6, b""), [protocol.pack_frame(2037, 6, b"\x08\x05\x08\xf0\x01")])
            self.clock.return_value += 600
            restored = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            self.assertEqual(restored.handle(2037, 7, b""), [protocol.pack_frame(2037, 7, b"\x08\x05\x08\xf0\x01")])

    def test_online_reward_all_tiers_save_once_and_finish_with_empty_query(self):
        self.complete_tutorial()
        before = json.loads(self.save_path.read_text())
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            session.handle(2037, 1, b"")
            for index, minute in enumerate((1, 5, 10, 15), 1):
                self.clock.return_value = self.now + minute * 60
                packets = session.handle(2038, index + 1, b"")
                saved = json.loads(self.save_path.read_text())
                self.assertEqual(saved["online_reward_state"]["claimed"], index)
                self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 2038)
                self.assertEqual(session.handle(2038, index + 1, b""), packets)
                self.assertEqual(json.loads(self.save_path.read_text()), saved)
            self.assertEqual(session.save["role_state"]["coin"], before["role_state"]["coin"] + 130000)
            self.assertEqual(session.save["role_state"]["gold"], before["role_state"]["gold"] + 100)
            old_props = self.entity_records(bytes.fromhex(before["world_state"]["1200"]), 1, 1)
            props = self.entity_records(bytes.fromhex(session.save["world_state"]["1200"]), 1, 1)
            for cid, count in ((20001, 2), (20005, 2), (20002, 2), (20006, 2), (20014, 1),
                               (20003, 2), (20007, 2), (20100, 20), (20019, 1)):
                self.assertEqual(protocol.pb_get_varint(props[cid], 2),
                                 (protocol.pb_get_varint(old_props.get(cid, b""), 2) or 0) + count)
            self.assertEqual(session.handle(2037, 10, b""), [protocol.pack_frame(2037, 10, b"")])
            self.assertEqual(struct.unpack(">IIII", session.handle(2038, 11, b"")[0][:16])[2], 999999)
        self.assertEqual(self.query_world(2037), b"")

    def test_online_reward_midnight_and_clock_rollback_do_not_duplicate_claims(self):
        self.complete_tutorial()
        midnight = ((self.now + 28800) // 86400 + 1) * 86400 - 28800
        self.clock.return_value = midnight - 120
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            session.handle(2037, 1, b"")
            self.clock.return_value = midnight - 60
            session.handle(2038, 2, b"")
            self.assertEqual(session.save["online_reward_state"]["claimed"], 1)
            self.clock.return_value = midnight - 90
            self.assertEqual(session.handle(2037, 3, b""), [protocol.pack_frame(2037, 3, b"\x08\x05\x08\xf0\x01")])
            self.clock.return_value = midnight + 10
            self.assertEqual(session.handle(2037, 4, b""), [protocol.pack_frame(2037, 4, b"\x08\x01\x08\x32")])
            self.assertEqual(session.save["online_reward_state"]["claimed"], 0)
            self.clock.return_value = midnight - 1
            session.handle(2037, 5, b"")
            self.clock.return_value = midnight + 15
            self.assertEqual(session.handle(2037, 6, b""), [protocol.pack_frame(2037, 6, b"\x08\x01\x08\x2d")])
            self.clock.return_value = midnight + 86400 + 100
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            self.assertEqual(session.handle(2037, 7, b""), [protocol.pack_frame(2037, 7, b"\x08\x01\x08\x3c")])

    def test_online_reward_queries_rewrite_every_main_page_comb(self):
        self.complete_tutorial()
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            session.handle(2037, 1, b"")
            self.clock.return_value = self.now + 20
            session.handle(999904, 2, b"")
        refresh = {"opcode": 999900, "seq": 28,
                   "hex": "0a030889120a0308c0250a0308ff350a03088a190a0308da360a0308f50f0a0308f70f0a0308e5320a03089a35"}
        for request in (self.by_seq[27], self.by_seq[122], refresh):
            reply = self.replay([request])[0]
            messages = dict(protocol.get_comb_messages(bytes.fromhex(reply["hex"])))
            self.assertEqual(protocol.parse_ids_pb(messages[2037]), [1, 40])

    def test_online_reward_invalid_claims_and_failed_saves_are_atomic(self):
        self.complete_tutorial()
        before = self.save_path.read_bytes()
        for opcode in (2037, 2038):
            for body in ("08", "0801", "1001", "0a00"):
                request = {"opcode": opcode, "seq": 66, "hex": body}
                self.assert_unavailable_response(self.replay([request]), opcode, 66, "参数")
                self.assertEqual(self.save_path.read_bytes(), before)
        comb = protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 2038))
        self.assert_unavailable_response(self.replay([{"opcode": 999900, "seq": 67, "hex": comb.hex()}]),
                                         999900, 67, "尚未")
        self.assertEqual(self.save_path.read_bytes(), before)
        baseline = json.loads(before)
        for overflow in (False, True):
            with self.subTest(overflow=overflow), redirect_stdout(io.StringIO()):
                saved = copy.deepcopy(baseline)
                saved["online_reward_state"]["seconds"] = 60
                if overflow:
                    saved["role_state"]["coin"] = (1 << 63) - 1
                self.save_path.write_text(json.dumps(saved))
                session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
                memory, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
                if overflow:
                    packets = session.handle(2038, 68, b"")
                    self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 999999)
                else:
                    with patch.object(player.os, "replace", side_effect=OSError("disk full")):
                        with self.assertRaises(OSError):
                            session.handle(2038, 68, b"")
                self.assertEqual((session.save, self.save_path.read_bytes()), (memory, disk))
        self.save_path.write_text(json.dumps(player.get_default_save()))
        before = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([self.activity_request(2038)]), 2038, 20000, "角色")
        self.assertEqual(self.save_path.read_bytes(), before)

    def test_online_reward_corrupt_progress_is_not_reset(self):
        self.complete_tutorial()
        saved = json.loads(self.save_path.read_text())
        for key, value in (("day", True), ("seconds", -1), ("seconds", 901),
                           ("claimed", 5), ("claimed", False), ("checked_at", -1)):
            with self.subTest(key=key, value=value):
                broken = copy.deepcopy(saved)
                broken["online_reward_state"][key] = value
                self.save_path.write_text(json.dumps(broken))
                self.assert_rejected(self.activity_request(2037), "在线奖励存档无效")

    def test_shop_tabs_query_current_account_without_recorded_sequence(self):
        self.complete_tutorial()
        for opcode in (3200, 3210, 4890, 1070, 1075, 1076):
            with self.subTest(opcode=opcode):
                frames = self.replay([self.activity_request(opcode)])
                self.assertEqual(frames[0]["opcode"], opcode)
                self.assertTrue(frames[0]["hex"])
        self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(frames[0]["hex"])), [0, 80001, 1])

    def seed_welfare_account(self):
        self.now = 1793336400  # 2026-10-30 13:00 UTC+8，有真实月签到配置。
        self.clock.return_value = self.now
        self.seed_stamina(20)
        saved = json.loads(self.save_path.read_text())
        player.get_role_state(saved, self.role_config)
        saved["role_state"].update(vip=6, level=8, gold=30000, coin=10000)
        self.save_path.write_text(json.dumps(saved))
        return saved

    def test_welfare_login_rewards_reconnect_gap_and_completion(self):
        self.seed_welfare_account()
        self.assertEqual(protocol.parse_ids_pb(self.query_world(214)), [1] + [0] * 7)
        self.replay([self.activity_request(215)])
        self.assertEqual((self.query_role()[8], self.query_role()[9]), (20000, 30020))
        original = self.save_path.read_bytes()
        self.assertEqual(self.replay([self.activity_request(215)])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), original)
        for day in range(1, 5):
            self.clock.return_value = self.now + day * 86400
            self.assertEqual(protocol.parse_ids_pb(self.query_world(214))[0], day + 1)
            self.assertEqual(self.replay([self.activity_request(215)])[0]["opcode"], 215)
        self.clock.return_value += 3 * 86400
        self.assertEqual(protocol.parse_ids_pb(self.query_world(214))[:6], [5, 1, 1, 1, 1, 1])
        self.assertEqual(self.replay([self.activity_request(215)])[0]["opcode"], 999999)
        self.seed_welfare_account()
        self.replay([self.activity_request(215)])
        self.clock.return_value += 2 * 86400
        self.assertEqual(protocol.parse_ids_pb(self.query_world(214)), [1] + [0] * 7)

    def test_welfare_peach_windows_daily_reset_and_clock_rollback(self):
        self.seed_welfare_account()
        self.assertEqual(protocol.parse_ids_pb(self.query_world(2010)), [0, 1, 1])
        self.replay([self.activity_request(2011)])
        self.assertEqual(self.query_role()[9], 30050)
        self.assertEqual(self.query_role()[10], 70)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(2010)), [2, 1, 1])
        self.assertEqual(self.replay([self.activity_request(2011)])[0]["opcode"], 999999)
        self.clock.return_value += 3600
        self.assertEqual(self.replay([self.activity_request(2011)])[0]["opcode"], 999999)
        for hour in (18, 21):
            self.clock.return_value = self.now + (hour - 13) * 3600
            self.assertEqual(self.replay([self.activity_request(2011)])[0]["opcode"], 2011)
        self.assertEqual(self.query_role()[9], 30150)
        self.assertEqual(self.query_role()[10], 170)
        self.clock.return_value = self.now + 86400
        self.assertEqual(protocol.parse_ids_pb(self.query_world(2010)), [0, 1, 1])
        before = self.save_path.read_bytes()
        self.clock.return_value = self.now
        self.assertEqual(self.replay([self.activity_request(2011)])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), before)

    def test_welfare_mammon_net_gain_limits_and_cached_retry(self):
        self.seed_welfare_account()
        with redirect_stdout(io.StringIO()), patch.object(welfare.random, "randint", side_effect=lambda lo, hi: lo):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            total = 30000
            for index in range(1, 6):
                row = self.role_config["mammon"][str(index)]
                reply = session.handle(2016, index, b"")
                gain = int(row["gold"] * row["min"]) - row["gold"]
                total += gain
                self.assertEqual(protocol.pb_get_varint(reply[0][16:], 2), gain)
                self.assertEqual(session.save["role_state"]["gold"], total)
                self.assertEqual(session.handle(2016, index, b""), reply)
            self.assertEqual(struct.unpack(">IIII", session.handle(2016, 6, b"")[0][:16])[2], 999999)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(2015))[0], 6)
        self.seed_welfare_account()
        saved = json.loads(self.save_path.read_text())
        saved["role_state"]["gold"] = 17
        self.save_path.write_text(json.dumps(saved))
        before = self.save_path.read_bytes()
        self.assertEqual(self.replay([self.activity_request(2016)])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), before)
        self.seed_welfare_account()
        self.clock.return_value += 3 * 86400
        self.assertEqual(protocol.parse_ids_pb(self.query_world(2015)), [1, 0])
        self.assertEqual(self.replay([self.activity_request(2016)])[0]["opcode"], 999999)

    def test_welfare_native_sign_comb_rewards_guide_and_daily_task_atomically(self):
        self.seed_welfare_account()
        # 官方请求省略空 data，Guide 字段顺序与描述符相反。
        request = {"opcode": 999900, "seq": 23456, "hex": "0a0308ba1c0a0908c901120410010833"}
        conn = ReplayConnection([request, request], 7)
        send = conn.sendall
        def committed(packet):
            saved = json.loads(self.save_path.read_text())
            self.assertEqual(saved["role_state"]["gold"], 30200)
            self.assertEqual(saved["welfare_state"]["sign_count"], 1)
            self.assertEqual(saved["guide"]["sections"]["51"]["status"], 2)
            send(packet)
        conn.sendall = committed
        with redirect_stdout(io.StringIO()):
            self.run_client(conn)
        self.assertEqual([f["opcode"] for f in conn.responses], [999900, 1034] * 2)
        self.assertEqual(self.replay([request])[0]["opcode"], 999999)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(3641)), [1, 1])
        flags = protocol.parse_ids_pb(self.query_world(2410))
        self.assertEqual((flags[6], flags[max(map(int, self.role_config["liveness"])) + 6]), (1, 1))
        self.replay([self.activity_request(2411)])
        self.assertEqual(self.query_role()[8], 12000)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(6517))[0], 5)
        self.assertEqual(self.replay([self.activity_request(2411, [107])])[0]["opcode"], 999999)
        self.clock.return_value += 86400
        self.assertEqual(protocol.parse_ids_pb(self.query_world(3641)), [1, 0])
        self.assertEqual(protocol.parse_ids_pb(self.query_world(2410))[6], 0)
        self.replay([self.activity_request(3642), self.activity_request(2411, [107])])
        self.assertEqual(protocol.parse_ids_pb(self.query_world(6517))[0], 10)
        self.clock.return_value += 86400  # 11月1日，月累计归零。
        self.assertEqual(protocol.parse_ids_pb(self.query_world(3641)), [0, 0])
        self.clock.return_value += 86400  # 星期一，签到周积分归零。
        self.assertEqual(protocol.parse_ids_pb(self.query_world(6517))[0], 0)

    def test_welfare_sign_comb_rejects_extra_duplicate_and_wrong_fields(self):
        self.seed_welfare_account()
        sign = protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 3642))
        guide_message = protocol.encode_pb_field(1, 0, 201)
        for data in (b"\x08\x33\x10\x02", b"\x08\x01\x10\x01", b"\x08\x33\x10\x01\x18\x00",
                     b"\x08\x33\x08\x33\x10\x01"):
            body = sign + protocol.encode_pb_field(1, 2, guide_message + protocol.encode_pb_field(2, 2, data))
            before = self.save_path.read_bytes()
            self.assertEqual(self.replay([{"opcode": 999900, "seq": 45, "hex": body.hex()}])[0]["opcode"], 999999)
            self.assertEqual(self.save_path.read_bytes(), before)
        valid = bytes.fromhex("0a0308ba1c0a0908c901120410010833")
        for body in (valid + sign, valid + b"\x10\x00", valid.replace(sign, sign + sign)):
            self.assertEqual(self.replay([{"opcode": 999900, "seq": 45, "hex": body.hex()}])[0]["opcode"], 999999)

    def test_welfare_luxury_requires_today_confirmed_payment_and_persists_reward(self):
        self.seed_welfare_account()
        self.assertEqual(protocol.parse_ids_pb(self.query_world(3643)), [0, 20200, 500, 1000, 50000])
        order = self.recharge_order(3)
        self.assertEqual(self.replay([self.activity_request(3644)])[0]["opcode"], 999999)
        self.replay([self.activity_request(116, [order])])
        self.assertEqual(protocol.parse_ids_pb(self.query_world(3643))[0], 1)
        self.replay([self.activity_request(3644)])
        self.assertEqual(self.query_role()[8], 60000)
        props = self.entity_records(self.query_world(1200), 1, 1)
        self.assertEqual(protocol.pb_get_varint(props[20200], 2), 500)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(3643))[0], 2)
        self.assertEqual(self.replay([self.activity_request(3644)])[0]["opcode"], 999999)
        self.clock.return_value += 86400
        self.assertEqual(protocol.parse_ids_pb(self.query_world(3643))[0], 0)
        self.replay([self.activity_request(116, [order])])
        self.assertEqual(protocol.parse_ids_pb(self.query_world(3643))[0], 0)

    def test_welfare_vip_and_period_gifts_charge_once_and_reject_locked_tiers(self):
        self.seed_welfare_account()
        self.replay([self.activity_request(4611, [1])])
        self.assertEqual(protocol.parse_ids_pb(self.query_world(300))[24:26], [1, 0])
        self.assertEqual(self.replay([self.activity_request(4611, [0, 100])])[0]["opcode"], 999999)
        row = self.role_config["vip_welfare"]["6"]["10"]
        before_gold = self.query_role()[9]
        self.replay([self.activity_request(4611, [0, 10])])
        self.assertEqual(self.query_role()[9], before_gold - int(row["discount"].strip(";").split(",")[1]))
        self.assertEqual(protocol.parse_ids_pb(self.query_world(300))[24:26], [1, 1])
        for opt, cost in ((1, 2000), (2, 6000)):
            before_gold = self.query_role()[9]
            reply = self.replay([self.activity_request(4616, [opt])])[0]
            self.assertEqual(reply["opcode"], 4616)
            self.assertIsNone(protocol.pb_get_varint(bytes.fromhex(reply["hex"]), 2))
            self.assertEqual(self.query_role()[9], before_gold - cost)
            self.assertEqual(self.replay([self.activity_request(4616, [opt])])[0]["opcode"], 999999)
        self.clock.return_value += 2 * 86400  # 周日，月更换但周礼包仍限购。
        status = protocol.parse_ids_pb(self.query_world(4615))
        self.assertEqual((status[0], status[2]), (1, 0))
        self.assertEqual(protocol.parse_ids_pb(self.query_world(300))[24:26], [0, 0])
        self.clock.return_value += 86400
        self.assertEqual(protocol.parse_ids_pb(self.query_world(4615))[0], 0)

    def test_daily_heartbeat_notifies_once_even_after_another_query_settles_the_day(self):
        self.seed_welfare_account()
        midnight = ((self.now + 28800) // 86400 + 1) * 86400 - 28800
        self.clock.return_value = midnight - 1
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            session.handle(4611, 1, recharge.ids([1]))
            session.handle(4611, 2, recharge.ids([0, 10]))
            original = copy.deepcopy(session.save["world_state"])
            self.clock.return_value = midnight
            reply = session.handle(300, 3, b"")
            self.assertEqual(protocol.parse_ids_pb(reply[0][16:])[24:26], [0, 0])
            packets = session.handle(999904, 4, b"")
            self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in packets], [999904, 110])
            self.assertEqual(packets[-1], protocol.pack_frame(110, 0, b""))
            for key in ("1002", "1012", "1107", "1200"):
                self.assertEqual(session.save["world_state"][key], original[key])
            for now in (midnight, midnight - 1, midnight + 60):
                self.clock.return_value = now
                self.assertEqual(session.handle(999904, 5, b""), [protocol.pack_frame(999904, 5, b"")])
            session.handle(4611, 6, recharge.ids([1]))
            self.assertEqual(struct.unpack(">IIII", session.handle(4611, 7, recharge.ids([1]))[0][:16])[2], 999999)
            reconnected = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            self.assertEqual(reconnected.handle(999904, 8, b""), [protocol.pack_frame(999904, 8, b"")])
            self.assertTrue(reconnected.save["welfare_state"]["vip_free"])

    def test_daily_heartbeat_failed_save_and_malformed_request_do_not_advance_refresh(self):
        self.seed_welfare_account()
        midnight = ((self.now + 28800) // 86400 + 1) * 86400 - 28800
        self.clock.return_value = midnight - 1
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            session.handle(4611, 1, recharge.ids([1]))
            memory, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
            self.clock.return_value = midnight
            with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
                session.handle(999904, 2, b"")
            self.assertEqual((session.save, self.save_path.read_bytes()), (memory, disk))
            self.assertEqual(session.refresh_day, (midnight - 1 + 28800) // 86400)
            self.assertEqual(struct.unpack(">IIII", session.handle(999904, 3, b"\x08\x01")[0][:16])[2], 999999)
            self.assertEqual((session.save, self.save_path.read_bytes()), (memory, disk))

    def test_campaign_daily_attempts_preserve_stars_boxes_unknown_fields_and_legacy_history(self):
        self.complete_tutorial()
        saved = json.loads(self.save_path.read_text())
        original = bytes.fromhex(saved["world_state"]["1300"]) + protocol.encode_pb_field(99, 0, 77)
        unknown_point = b"\x08\x7f\x20\x09\x98\x06\x4d"
        maps = self.entity_records(original, 1, 1)
        original = player.merge_pb_records(original, protocol.encode_pb_field(1, 2,
            maps[42101] + protocol.encode_pb_field(7, 2, unknown_point)), {1: 1})
        original += protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 99999) +
                                             protocol.encode_pb_field(7, 2, unknown_point))
        saved["world_state"]["1300"] = original.hex()
        self.save_path.write_text(json.dumps(saved))
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            self.assertEqual(session.handle(1300, 1, b"")[0][16:], original)
            self.clock.return_value += 86400
            response = session.handle(1300, 2, b"")[0][16:]
            maps = self.entity_records(response, 1, 1)
            for mid, raw in self.entity_records(original, 1, 1).items():
                updated = self.entity_records(maps[mid], 7, 1)
                for pid, point in self.entity_records(raw, 7, 1).items():
                    expected = protocol.pb_set_varint(point, 4, 0) if str(pid) in self.role_config["copy"].get(str(mid), {}) else point
                    self.assertEqual(updated[pid], expected)
                for field in (2, 3, 4, 5, 6):
                    self.assertEqual(protocol.pb_get_varint(maps[mid], field), protocol.pb_get_varint(raw, field))
            self.assertEqual(protocol.pb_get_varint(response, 99), 77)
            self.assertEqual(session.handle(1300, 3, b"")[0][16:], response)
            session.handle(1307, 4, recharge.ids([42101, 1, 0, 0]))
            after = copy.deepcopy(session.save["world_state"]["1300"])
            self.clock.return_value -= 86400
            self.assertEqual(session.handle(1300, 5, b"")[0][16:].hex(), after)
            reconnected = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            self.assertEqual(reconnected.handle(1300, 6, b"")[0][16:].hex(), after)

    def test_campaign_daily_attempts_settle_before_direct_sweep_and_failed_save_is_atomic(self):
        self.complete_tutorial()
        saved = json.loads(self.save_path.read_text())
        raw = bytes.fromhex(saved["world_state"]["1300"])
        map_body = self.entity_records(raw, 1, 1)[42101]
        point = self.entity_records(map_body, 7, 1)[1]
        point = protocol.pb_set_varint(point, 4, self.role_config["copy"]["42101"]["1"]["challenge"])
        map_body = player.merge_pb_records(map_body, protocol.encode_pb_field(7, 2, point), {7: 1})
        saved["world_state"]["1300"] = player.merge_pb_records(raw, protocol.encode_pb_field(1, 2, map_body), {1: 1}).hex()
        saved["campaign_day"] = (self.now + 28800) // 86400
        self.save_path.write_text(json.dumps(saved))
        body = recharge.ids([42101, 1, 0, 0])
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            self.assertEqual(struct.unpack(">IIII", session.handle(1307, 1, body)[0][:16])[2], 999999)
            self.clock.return_value += 86400
            disk, memory = self.save_path.read_bytes(), copy.deepcopy(session.save)
            with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
                session.handle(1307, 2, body)
            self.assertEqual((self.save_path.read_bytes(), session.save), (disk, memory))
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            self.assertEqual(struct.unpack(">IIII", session.handle(1307, 3, body)[0][:16])[2], 1307)
            maps = self.entity_records(bytes.fromhex(session.save["world_state"]["1300"]), 1, 1)
            updated = self.entity_records(maps[42101], 7, 1)[1]
            self.assertEqual(protocol.pb_get_varint(updated, 4), 1)
            self.assertEqual(protocol.pb_get_varint(updated, 3), protocol.pb_get_varint(point, 3))

    def seed_exhausted_campaign_point(self):
        if not self.save_path.exists():
            self.complete_tutorial()
        saved = json.loads(self.save_path.read_text())
        saved["role_state"]["gold"] = 10000
        saved["campaign_day"] = (self.now + 28800) // 86400
        copies = bytes.fromhex(saved["world_state"]["1300"])
        current = self.entity_records(copies, 1, 1)[42101]
        point = self.entity_records(current, 7, 1)[1]
        point = protocol.pb_set_varint(point, 4, self.role_config["copy"]["42101"]["1"]["challenge"])
        point += protocol.encode_pb_field(99, 0, 77)
        current = player.merge_pb_records(current, protocol.encode_pb_field(7, 2, point), {7: 1})
        saved["world_state"]["1300"] = player.merge_pb_records(copies, protocol.encode_pb_field(1, 2, current), {1: 1}).hex()
        self.save_path.write_text(json.dumps(saved))
        with redirect_stdout(io.StringIO()):
            return Session(self.tables, self.save_path, self.step_counts, self.role_config)

    def test_campaign_manual_reset_native_scalars_charge_once_and_preserve_progress(self):
        session = self.seed_exhausted_campaign_point()
        before = copy.deepcopy(session.save)
        body = protocol.encode_pb_field(2, 0, 1) + protocol.encode_pb_field(1, 0, 42101)
        with redirect_stdout(io.StringIO()):
            packets = session.handle(1305, 901, body)
            self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in packets[:3]], [1305, 1300, 1001])
            self.assertEqual(session.handle(1305, 901, body), packets)
            current = Session(self.tables, self.save_path, self.step_counts, self.role_config)
        self.assertEqual(current.save["role_state"]["gold"], before["role_state"]["gold"] - 50)
        original = bytes.fromhex(before["world_state"]["1300"])
        row = self.entity_records(original, 1, 1)[42101]
        point = self.entity_records(row, 7, 1)[1]
        expected_map = player.merge_pb_records(row, protocol.encode_pb_field(7, 2, protocol.pb_set_varint(point, 4, 0)), {7: 1})
        expected = player.merge_pb_records(original, protocol.encode_pb_field(1, 2, expected_map), {1: 1})
        self.assertEqual(bytes.fromhex(current.save["world_state"]["1300"]), expected)
        for key in ("1002", "1012", "1107", "1200"):
            self.assertEqual(current.save["world_state"][key], before["world_state"][key])
        for key in ("level", "exp", "stamina", "energy", "coin"):
            self.assertEqual(current.save["role_state"][key], before["role_state"][key])
        with redirect_stdout(io.StringIO()):
            self.assertEqual(struct.unpack(">IIII", current.handle(1305, 902, body)[0][:16])[2], 999999)

    def test_campaign_manual_reset_bad_locked_and_unmatched_comb_requests_are_atomic(self):
        session = self.seed_exhausted_campaign_point()
        valid = protocol.encode_pb_field(1, 0, 42101) + protocol.encode_pb_field(2, 0, 1)
        bodies = (b"", b"\x08", recharge.ids([42101, 1]), valid + b"\x18\x01", valid + b"\x10\x01",
                  protocol.encode_pb_field(1, 0, 0) + b"\x10\x01",
                  protocol.encode_pb_field(1, 0, 99999) + b"\x10\x01",
                  protocol.encode_pb_field(1, 0, 42410) + b"\x10\x01",
                  protocol.encode_pb_field(1, 0, 42101) + b"\x10\x7f")
        with redirect_stdout(io.StringIO()):
            for i, body in enumerate(bodies):
                before, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
                self.assertEqual(struct.unpack(">IIII", session.handle(1305, 910 + i, body)[0][:16])[2], 999999)
                self.assertEqual((session.save, self.save_path.read_bytes()), (before, disk))
            comb = protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 1305) + protocol.encode_pb_field(2, 2, valid))
            self.assertEqual(struct.unpack(">IIII", session.handle(999900, 930, comb)[0][:16])[2], 999999)

    def test_campaign_manual_reset_insufficient_gold_and_save_failure_never_charge(self):
        body = protocol.encode_pb_field(1, 0, 42101) + protocol.encode_pb_field(2, 0, 1)
        for failure in ("funds", "save", "rollback"):
            session = self.seed_exhausted_campaign_point()
            if failure == "funds":
                session.save["role_state"]["gold"] = 49
            if failure == "rollback":
                self.clock.return_value = self.now - 86400
            before, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
            with redirect_stdout(io.StringIO()):
                if failure == "save":
                    with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
                        session.handle(1305, 940, body)
                else:
                    self.assertEqual(struct.unpack(">IIII", session.handle(1305, 940, body)[0][:16])[2], 999999)
            self.assertEqual((session.save, self.save_path.read_bytes()), (before, disk))
            self.clock.return_value = self.now

    def test_campaign_midnight_recovery_prevents_stale_reset_from_spending_gold(self):
        session = self.seed_exhausted_campaign_point()
        self.clock.return_value += 86400
        body = protocol.encode_pb_field(1, 0, 42101) + protocol.encode_pb_field(2, 0, 1)
        before, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
        with redirect_stdout(io.StringIO()):
            self.assertEqual(struct.unpack(">IIII", session.handle(1305, 950, body)[0][:16])[2], 999999)
            self.assertEqual((session.save, self.save_path.read_bytes()), (before, disk))
            session.handle(1300, 951, b"")
        point = self.entity_records(self.entity_records(bytes.fromhex(session.save["world_state"]["1300"]), 1, 1)[42101], 7, 1)[1]
        self.assertEqual(protocol.pb_get_varint(point, 4), 0)
        self.assertEqual(session.save["role_state"]["gold"], before["role_state"]["gold"])

    def test_campaign_manual_reset_covers_all_configured_maps_and_point_limits(self):
        working = self.seed_exhausted_campaign_point().save
        count = 0
        for mid, points in self.role_config["copy"].items():
            if mid not in self.role_config["map"]:
                continue
            for pid, row in points.items():
                index = int(pid)
                point = protocol.encode_pb_field(1, 0, index) + protocol.encode_pb_field(3, 0, 3) + protocol.encode_pb_field(4, 0, row["challenge"])
                previous = protocol.encode_pb_field(7, 2, protocol.encode_pb_field(1, 0, index - 1) + protocol.encode_pb_field(3, 0, 3)) if index > 1 else b""
                raw = protocol.encode_pb_field(1, 0, int(mid)) + previous + protocol.encode_pb_field(7, 2, point)
                working["world_state"]["1300"] = protocol.encode_pb_field(1, 2, raw).hex()
                working["role_state"]["gold"] = 10000
                body = protocol.encode_pb_field(1, 0, int(mid)) + protocol.encode_pb_field(2, 0, index)
                self.assertEqual(player.reset_campaign_attempts(working, body, self.role_config, self.now), b"\x08\x01")
                self.assertEqual(working["role_state"]["gold"], 10000 - 5 * row["challenge"])
                count += 1
        self.assertEqual(count, 3061)

    def test_welfare_growth_order_is_distinct_from_gold_recharge_and_counts_real_accounts(self):
        self.seed_welfare_account()
        old_order = self.recharge_order(5)
        body = b"\x0a\x02\x08\x05\x0a\x02\x08\x02"
        reply = self.replay([{"opcode": 115, "seq": 100, "hex": body.hex()}])[0]
        order = protocol.pb_get_varint(next(v for _, _, v in protocol.iter_pb_fields(bytes.fromhex(reply["hex"]))), 1)
        self.assertNotEqual(order, old_order)
        self.assertEqual(self.replay([self.activity_request(116, [old_order])])[0]["opcode"], 999999)
        self.replay([self.activity_request(116, [order])])
        self.assertEqual(self.query_role()[9], 30000)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(7091))[:3], [1, 1, 0])
        self.assertEqual(protocol.parse_ids_pb(self.query_world(7094)), [1] + [0] * 12)
        self.assertEqual(self.replay([self.activity_request(7095, [1])])[0]["opcode"], 999999)
        self.replay([self.activity_request(7093, [1])])
        self.assertEqual(self.query_role()[9], 30588)
        self.assertEqual(self.replay([self.activity_request(7093, [1])])[0]["opcode"], 999999)
        self.assertEqual(self.replay([self.activity_request(7093, [2])])[0]["opcode"], 999999)
        self.assertEqual(self.replay([{"opcode": 115, "seq": 101, "hex": body.hex()}])[0]["opcode"], 999999)
        self.replay([self.activity_request(116, [self.recharge_order(5)])])
        self.assertEqual(self.query_role()[9], 32088)  # 购买计划没有消耗充值档位的首次翻倍。
        saved = json.loads(self.save_path.read_text())
        store = accounts.AccountStore(self.save_path, self.tables, self.step_counts, self.role_config)
        for account in range(2, 6):
            path = store.path(account)
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(json.dumps(saved))
        self.assertEqual(protocol.parse_ids_pb(self.query_world(7094))[:2], [5, 1])
        self.replay([self.activity_request(7095, [1])])
        self.assertEqual(self.query_role()[8], 11000)
        self.assertEqual(self.replay([self.activity_request(7095, [1])])[0]["opcode"], 999999)
        self.assertEqual(json.loads(store.path(2).read_text())["welfare_state"]["growth_global_claimed"], [])
        store.path(2).write_text("broken")
        before = self.save_path.read_bytes()
        self.assertEqual(self.replay([self.activity_request(7094)])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), before)

    def test_welfare_invalid_requests_balance_overflow_and_failed_save_are_atomic(self):
        self.seed_welfare_account()
        before = self.save_path.read_bytes()
        for opcode in welfare.OPCODES + (7094, 7095):
            for body in (b"\x08", b"\x10\x00", b"\x0a\x00", b"\x08\x01" * 3):
                reply = self.replay([{"opcode": opcode, "seq": 10, "hex": body.hex()}])
                self.assertEqual(reply[0]["opcode"], 999999)
                self.assertEqual(self.save_path.read_bytes(), before)
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            for opcode, body in ((215, b""), (3642, b""), (4611, b"\x08\x01"), (4616, b"\x08\x01")):
                memory = copy.deepcopy(session.save)
                with patch.object(player.os, "replace", side_effect=OSError("disk full")):
                    with self.assertRaises(OSError):
                        session.handle(opcode, 20, body)
                self.assertEqual((session.save, self.save_path.read_bytes()), (memory, before))
            session.save["role_state"]["gold"] = (1 << 31) - 1
            memory = copy.deepcopy(session.save)
            self.assertEqual(struct.unpack(">IIII", session.handle(215, 21, b"")[0][:16])[2], 999999)
            self.assertEqual((session.save, self.save_path.read_bytes()), (memory, before))
            session.save["role_state"]["gold"] = 0
            memory = copy.deepcopy(session.save)
            self.assertEqual(struct.unpack(">IIII", session.handle(4616, 22, b"\x08\x01")[0][:16])[2], 999999)
            self.assertEqual((session.save, self.save_path.read_bytes()), (memory, before))

    def seed_shop_account(self):
        saved = self.seed_training_account(coin=1000000, vip=27)
        saved["role_state"]["gold"] = 1000000
        self.save_path.write_text(json.dumps(saved))
        return saved

    def test_shop_queries_match_official_20261029_capture(self):
        self.complete_tutorial()
        capture = json.loads((Path(server.BASE_DIR) / "official_interaction_capture_20261029_2312.json").read_text())
        checked = []
        for frame in capture["connections"][0]["frames"]:
            if frame["c2s"] or not frame["seq"]:
                continue
            body = bytes.fromhex(frame["hex"])
            messages = protocol.get_comb_messages(body) if frame["opcode"] == 999900 else [(frame["opcode"], body)]
            for opcode, expected in messages:
                if opcode not in (1070, 1076, 3210, 4890):
                    continue
                with self.subTest(seq=frame["seq"], opcode=opcode):
                    actual = bytes.fromhex(self.replay([self.activity_request(opcode)])[0]["hex"])
                    if opcode == 3210:
                        # 商品排列不影响原生按 CID 缓存；所有字段仍须与官方一致。
                        rows = lambda data: sorted(sorted(protocol.iter_pb_fields(v))
                                                   for n, w, v in protocol.iter_pb_fields(data))
                        self.assertEqual(rows(actual), rows(expected))
                    else:
                        self.assertEqual(actual, expected)
                    checked.append(opcode)
        self.assertCountEqual(checked, [1070, 1076, 3210, 4890, 4890, 4890, 4890])

    def test_main_page_refresh_comb_restores_current_gifts_after_purchase(self):
        self.seed_shop_account()
        refresh = {"opcode": 999900, "seq": 28,
                   "hex": "0a030889120a0308c0250a0308ff350a03088a190a0308da360a0308f50f0a0308f70f0a0308e5320a03089a35"}
        requests = [self.by_seq[27], dict(refresh, seq=122), dict(self.by_seq[122], seq=28), refresh]
        tables = copy.deepcopy(self.tables)
        for bought in (False, True):
            with self.subTest(bought=bought):
                if bought:
                    self.replay([self.shop_request(3211, 20101)])
                gifts = self.query_world(3210)
                online = self.query_world(2037)
                self.assertEqual(20101 in self.entity_records(gifts, 1, 1), not bought)
                before = self.save_path.read_bytes()
                responses = self.replay(requests, chunk_size=7)
                self.assertEqual([(f["opcode"], f["seq"]) for f in responses],
                                 [(999900, f["seq"]) for f in requests])
                for request, response, source in zip(requests, responses, (27, 122, 122, 163)):
                    recorded = dict(protocol.get_comb_messages(bytes.fromhex(self.recorded[(source, 999900)]["hex"])))
                    recorded.update({3210: gifts, 2037: online})
                    ids = [mid for mid, _ in protocol.get_comb_messages(bytes.fromhex(request["hex"]))]
                    messages = protocol.get_comb_messages(bytes.fromhex(response["hex"]))
                    self.assertEqual(messages, [(mid, recorded[mid]) for mid in ids])
                self.assertEqual(self.save_path.read_bytes(), before)
                self.assertEqual(self.replay([refresh]), [dict(responses[1], seq=refresh["seq"])])
        self.assertEqual(self.tables, tables)

    def test_main_page_guild_preload_adds_only_new_account_membership_query(self):
        self.seed_shop_account()
        saved = json.loads(self.save_path.read_text())
        saved["role_state"].update(level=19, nextexp=self.role_config["role_exp"]["19"]["nextexp"])
        self.save_path.write_text(json.dumps(saved))
        previous = self.replay([self.by_seq[27]])[0]
        expected = protocol.get_comb_messages(bytes.fromhex(previous["hex"]))
        baseline = next(dict(protocol.get_comb_messages(bytes.fromhex(f["hex"])))[2230]
                        for f in self.tables[2] if f["opcode"] == 999900)
        expected.insert(7, (2230, baseline))
        ids = (2313, 4800, 2880, 5511, 6911, 3210, 7002, 2230, 2037, 2039, 6501, 6810)
        body = b"".join(protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, mid)) for mid in ids)
        request = {"opcode": 999900, "seq": 24000, "hex": body.hex()}
        before = self.save_path.read_bytes()
        for seq in (24000, 24001):
            responses = self.replay([dict(request, seq=seq)], chunk_size=7)
            self.assertEqual([(f["opcode"], f["seq"]) for f in responses], [(999900, seq)])
            self.assertEqual(protocol.get_comb_messages(bytes.fromhex(responses[0]["hex"])), expected)
            self.assertEqual(self.save_path.read_bytes(), before)

    def test_main_page_guild_preload_requires_complete_source_and_membership_baseline(self):
        ids = (2313, 4800, 2880, 5511, 6911, 3210, 7002, 2230, 2037, 2039, 6501, 6810)
        body = b"".join(protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, mid)) for mid in ids)
        unknown = protocol.encode_pb_field(9, 2, b"keep")
        initial = [self.by_seq[12], self.recorded[(12, 999900)]]
        request = self.by_seq[27]
        response = dict(self.recorded[(27, 999900)], hex=self.recorded[(27, 999900)]["hex"] + unknown.hex())
        frames = [*initial, request, response]
        original = copy.deepcopy(frames)
        with redirect_stdout(io.StringIO()):
            tables = replay.build_routing_tables(frames)
            result = replay.Replay(tables).match(999900, 24000, body)
            self.assertIsNotNone(result)
            self.assertTrue(bytes.fromhex(result[0]["hex"]).endswith(unknown))
            for source in ([], [dict(response, seq=0)], [dict(response, hex="")]):
                tables = replay.build_routing_tables([*initial, request, *source])
                self.assertIsNone(replay.Replay(tables).match(999900, 24000, body))
            missing = b"".join(protocol.encode_pb_field(n, w, value)
                               for n, w, value in protocol.iter_pb_fields(bytes.fromhex(initial[1]["hex"]))
                               if not ((n, w) == (1, 2) and protocol.pb_get_varint(value, 1) == 2230))
            tables = replay.build_routing_tables([initial[0], dict(initial[1], hex=missing.hex()), request, response])
            self.assertIsNone(replay.Replay(tables).match(999900, 24000, body))
        self.assertEqual(frames, original)

    def test_main_page_comb_compatibility_keeps_full_parameter_validation(self):
        self.seed_shop_account()
        before = self.save_path.read_bytes()
        self.clock.return_value = self.now + 360
        refresh = bytes.fromhex("0a030889120a0308c0250a0308ff350a03088a190a0308da360a0308f50f0a0308f70f0a0308e5320a03089a35")
        guild = b"".join(protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, mid))
                         for mid in (2313, 4800, 2880, 5511, 6911, 3210, 7002, 2230, 2037, 2039, 6501, 6810))
        for raw in (bytes.fromhex(self.by_seq[27]["hex"]), bytes.fromhex(self.by_seq[122]["hex"]), refresh, guild):
            fields = list(protocol.iter_pb_fields(raw))
            bodies = [raw + b"\x10\x01", raw + protocol.encode_pb_field(*fields[0]),
                      b"".join(protocol.encode_pb_field(*f) for f in reversed(fields))]
            for index, field in enumerate(fields):
                for extra in (b"\x12\x02\x08\x01", b"\x18\x01", field[2], b"\x12\x00\x12\x00"):
                    changed = fields[:index] + [(1, 2, field[2] + extra)] + fields[index + 1:]
                    bodies.append(b"".join(protocol.encode_pb_field(*f) for f in changed))
            purchase = protocol.encode_pb_field(1, 0, 3211) + protocol.encode_pb_field(2, 2, bytes.fromhex(self.shop_request(3211, 20101)["hex"]))
            bodies.append(raw + protocol.encode_pb_field(1, 2, purchase))
            for body in bodies:
                with self.subTest(body=body.hex()):
                    request = {"opcode": 999900, "seq": 27, "hex": body.hex()}
                    self.assert_unavailable_response(self.replay([request]), 999900, 27, "尚未实现")
                    self.assertEqual(self.save_path.read_bytes(), before)

    def test_main_page_refresh_alias_requires_reply_and_preserves_source(self):
        request = self.by_seq[122]
        unknown = protocol.encode_pb_field(9, 2, b"keep")
        response = dict(self.recorded[(122, 999900)], hex=self.recorded[(122, 999900)]["hex"] + unknown.hex())
        refresh = bytes.fromhex("0a030889120a0308c0250a0308ff350a03088a190a0308da360a0308f50f0a0308f70f0a0308e5320a03089a35")
        frames = [request, response]
        original = copy.deepcopy(frames)
        with redirect_stdout(io.StringIO()):
            tables = replay.build_routing_tables(frames)
            result = replay.Replay(tables).match(999900, 10000, refresh)
            self.assertIsNotNone(result)
            self.assertEqual(len(result), 1)
            self.assertTrue(bytes.fromhex(result[0]["hex"]).endswith(unknown))
            self.assertEqual(replay.Replay(tables).match(999900, 27, bytes.fromhex(request["hex"])), [response])
            partial = protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 6911))
            for incomplete in ([request], [request, dict(response, seq=0)],
                               [request, dict(response, hex="")], [request, dict(response, hex=partial.hex())]):
                self.assertIsNone(replay.Replay(replay.build_routing_tables(incomplete)).match(999900, 27, refresh))
        self.assertEqual(frames, original)

    def test_shop_incremental_prices_daily_reset_and_clock_rollback(self):
        self.seed_shop_account()
        self.replay([self.shop_request(3201, 21, 4)])
        frames = self.replay([self.shop_request(3201, 21, 2)])
        reward = bytes.fromhex(frames[0]["hex"])
        self.assertIsNone(protocol.pb_get_varint(reward, 2))
        self.assertEqual(self.query_role()[9], 1000000 - 4800 - 2700)
        props = self.entity_records(self.query_world(1200), 1, 1)
        self.assertEqual(protocol.pb_get_varint(props[20090], 2), 6)
        query = self.activity_request(3200)
        counts = lambda: protocol.parse_ids_pb(bytes.fromhex(self.replay([query])[0]["hex"]))
        self.assertEqual(counts()[20], 6)
        self.clock.return_value = ((self.now + 28800) // 86400 + 1) * 86400 - 28800
        self.assertEqual(counts(), [0] * 29)
        self.replay([self.shop_request(3201, 21)])
        self.clock.return_value = self.now
        self.assertEqual(counts()[20], 1)

    def test_shop_gifts_open_and_weekly_limits_survive_reconnect(self):
        self.seed_shop_account()
        self.replay([self.shop_request(3211, 20101)])
        rows = self.entity_records(bytes.fromhex(self.replay([self.activity_request(3210)])[0]["hex"]), 1, 1)
        self.assertNotIn(20101, rows)
        before = self.query_role()[8]
        reply = self.replay([self.activity_request(1201, [20101, 1])])[0]
        self.assertEqual(reply["opcode"], 1201)
        self.assertEqual(self.query_role()[8], before + 50000)
        self.assertNotIn(20101, self.entity_records(self.query_world(1200), 1, 1))
        self.assertTrue(any(protocol.pb_get_varint(r, 1) == 10203 for r in self.entity_records(self.query_world(1002), 1, 2).values()))
        self.replay([self.activity_request(4891, [1])])
        self.assertIn(20431, self.entity_records(self.query_world(1200), 1, 1))
        request = self.activity_request(4891, [1])
        original = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([request]), 4891, request["seq"], "本周已购买")
        self.assertEqual(self.save_path.read_bytes(), original)
        day = (self.now + 28800) // 86400
        self.clock.return_value = (((day + 3) // 7 + 1) * 7 - 3) * 86400 - 28800
        query = self.activity_request(4890)
        self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(self.replay([query])[0]["hex"]))[0], 0)
        self.replay([request])
        self.clock.return_value = self.now
        self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(self.replay([query])[0]["hex"]))[0], 1)
        self.assert_unavailable_response(self.replay([self.shop_request(3211, 20101)]), 3211, 20000, "已购买")

    def test_every_catalog_gift_can_be_bought_opened_and_restored(self):
        baseline = self.seed_shop_account()
        types = set()
        for table, opcode in (("gift_bag", 3211), ("vip_weekgift", 4891)):
            for key, row in self.role_config[table].items():
                with self.subTest(table=table, key=key):
                    self.save_path.write_text(json.dumps(baseline))
                    buy = self.shop_request(opcode, int(key)) if opcode == 3211 else self.activity_request(opcode, [int(key)])
                    self.assertEqual(self.replay([buy])[0]["opcode"], opcode)
                    reply = self.replay([self.activity_request(1201, [row["id"], 1])])[0]
                    self.assertEqual(reply["opcode"], 1201)
                    reward = bytes.fromhex(reply["hex"])
                    self.assertNotIn(row["id"], self.entity_records(self.query_world(1200), 1, 1))
                    roster = self.query_world(1002)
                    for n, w, value in protocol.iter_pb_fields(reward):
                        if w != 2 or n not in (6, 7, 8, 11) or not value:
                            continue
                        types.add(n)
                        slot_field, identity = {6: (2, 1), 7: (3, 1), 8: (1, 2), 11: (7, 1)}[n]
                        records = list(self.entity_records(value, 1, 1).values()) if n == 7 else [value]
                        stored = self.entity_records(roster, slot_field, identity)
                        for record in records:
                            self.assertEqual(stored[protocol.pb_get_varint(record, identity)], record)
        self.assertEqual(types, {6, 7, 8, 11})

    def test_shop_sigil_iids_and_box_batch_costs_are_not_duplicated(self):
        self.seed_shop_account()
        self.replay([self.shop_request(3201, 10, 2)])
        self.replay([self.shop_request(3201, 10, 2)])
        gems = self.entity_records(self.query_world(1002), 7, 1)
        owned = [protocol.parse_ids_pb(r) for r in gems.values() if protocol.parse_ids_pb(r)[1] == 33017]
        self.assertEqual(len(owned), 4)
        self.assertEqual(len({r[0] for r in owned}), 4)
        self.give_props({20088: 3})
        before = self.query_role()[8]
        request = self.activity_request(1201, [20088, 3])
        frames = self.replay([request, request])
        self.assertEqual(frames[0], frames[1])
        self.assertEqual(self.query_role()[8], before + 300000)
        self.assertNotIn(20088, self.entity_records(self.query_world(1200), 1, 1))

    def test_shop_invalid_transactions_are_atomic(self):
        baseline = self.seed_shop_account()
        self.give_props({20088: 1})
        baseline = json.loads(self.save_path.read_text())
        cases = [self.shop_request(3201, 999), self.shop_request(3201, 21, 9999),
                 self.shop_request(3201, 27), self.shop_request(3211, 20101, 2),
                 self.activity_request(4891, [28]), self.activity_request(1201, [20088, 2]),
                 self.activity_request(1201, [20088, 101]), self.activity_request(1201, [20088, 1, 1])]
        malformed = self.shop_request(3201, 21)
        malformed["hex"] *= 2
        cases.append(malformed)
        for request in cases:
            with self.subTest(request=request):
                self.save_path.write_text(json.dumps(baseline))
                original = self.save_path.read_bytes()
                frames = self.replay([request])
                self.assertEqual([f["opcode"] for f in frames], [999999, 1999])
                self.assertEqual(self.save_path.read_bytes(), original)
        for values, request in (({"gold": 0}, self.shop_request(3201, 21)),
                                ({"vip": 0}, self.shop_request(3211, 20101)),
                                ({"vip": 0}, self.activity_request(4891, [1])),
                                ({"coin": (1 << 63) - 1}, self.activity_request(1201, [20088, 1]))):
            saved = copy.deepcopy(baseline)
            saved["role_state"].update(values)
            self.save_path.write_text(json.dumps(saved))
            original = self.save_path.read_bytes()
            self.assertEqual(self.replay([request])[0]["opcode"], 999999)
            self.assertEqual(self.save_path.read_bytes(), original)

    def test_fashion_purchase_dress_hide_strengthen_and_restore(self):
        baseline = self.seed_shop_account()
        protagonist = bytes.fromhex(baseline["protagonist_snapshot"])
        iid = protocol.pb_get_varint(protagonist, 1)
        original = self.entity_records(bytes.fromhex(baseline["world_state"]["1002"]), 1, 2)[iid]
        buy = self.activity_request(1074, [80001])
        frames = self.replay([buy, buy])
        self.assertEqual([f["opcode"] for f in frames], [1074, 205, 1034] * 2)
        self.assertEqual(self.hint_changes(frames[2]), {40: 1})
        self.assertEqual(frames[:3], frames[3:])
        self.assertEqual(self.query_role()[9], 1000000 - 3999)
        self.assertNotIn(80001, self.entity_records(self.query_world(1200), 1, 1))
        bought = self.entity_records(self.query_world(1002), 1, 2)[iid]
        self.assertEqual(protocol.pb_get_varint(bought, 8), protocol.pb_get_varint(original, 8) + 5040)
        self.assertEqual(protocol.pb_get_varint(bought, 6), protocol.pb_get_varint(original, 6))
        self.replay([self.activity_request(1073, [80001])])
        dressed = self.entity_records(self.query_world(1002), 1, 2)[iid]
        base_cid = protocol.pb_get_varint(original, 1)
        coat_cid = self.role_config["fashioncoat"]["80001"][str(base_cid)]["coat_id"]
        self.assertEqual(protocol.pb_get_varint(dressed, 1), coat_cid)
        for shown, cid, train in ((0, base_cid, 1), (1, coat_cid, 2)):
            self.replay([self.activity_request(1071)])
            state = json.loads(self.save_path.read_text())
            self.assertEqual(state["fashion_state"]["show"], shown)
            self.assertEqual(protocol.pb_get_varint(bytes.fromhex(state["protagonist_snapshot"]), 7), train)
            general = self.entity_records(self.query_world(1002), 1, 2)[iid]
            self.assertEqual(protocol.pb_get_varint(general, 1), cid)
            self.assertEqual(protocol.pb_get_varint(general, 8), protocol.pb_get_varint(bought, 8))
        self.give_props({20281: 3})
        before = self.query_role()[8]
        frames = self.replay([self.activity_request(1072, [80001, 5])])
        groups = self.begin7day_groups(bytes.fromhex(frames[0]["hex"]))
        self.assertEqual(groups[1], [1, 300, 3])
        self.assertEqual(self.query_role()[8], before - 300)
        self.assertNotIn(20281, self.entity_records(self.query_world(1200), 1, 1))
        grown = self.entity_records(self.query_world(1002), 1, 2)[iid]
        self.assertEqual(protocol.pb_get_varint(grown, 8), protocol.pb_get_varint(original, 8) + 5190)
        response = self.replay([self.activity_request(1070)])[0]
        self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(response["hex"])), [80001, 1, 80001, 2])
        state = json.loads(self.save_path.read_text())
        self.assertEqual(state["role_state"]["power"], baseline["role_state"]["power"] + 519)

    def test_fashion_invalid_or_failed_save_never_charges(self):
        baseline = self.seed_shop_account()
        for request in (self.activity_request(1073, [80001]), self.activity_request(1071),
                        self.activity_request(1072, [80001]), self.activity_request(1074, [80002]),
                        self.activity_request(1074, [80001, 1])):
            original = self.save_path.read_bytes()
            self.assertEqual(self.replay([request])[0]["opcode"], 999999)
            self.assertEqual(self.save_path.read_bytes(), original)
        for request in (self.activity_request(1074, [80001]), self.shop_request(3201, 21),
                        self.shop_request(3211, 20101), self.activity_request(4891, [1])):
            with patch.object(player, "save_role", return_value=False):
                self.assert_rejected(request, "角色状态保存失败")
        baseline["role_state"]["gold"] = 3998
        self.save_path.write_text(json.dumps(baseline))
        original = self.save_path.read_bytes()
        self.assertEqual(self.replay([self.activity_request(1074, [80001])])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), original)

    def test_fashion_appearance_changes_do_not_emit_zero_power_animations(self):
        self.seed_shop_account()
        bought = self.replay([self.activity_request(1074, [80001])])
        self.assertTrue(any(f["opcode"] == 205 for f in bought))
        before = json.loads(self.save_path.read_text())
        for opcode, values in ((1073, [80001]), (1071, []), (1071, []), (1073, [80001])):
            replies = self.replay([self.activity_request(opcode, values)])
            self.assertEqual([f["opcode"] for f in replies], [opcode])
            saved = json.loads(self.save_path.read_text())
            for key in ("power", "power_all", "g_power"):
                self.assertEqual(saved["role_state"][key], before["role_state"][key])
        self.give_props({20281: 10})
        strengthened = self.replay([self.activity_request(1072, [80001])])
        push = next(f for f in strengthened if f["opcode"] == 205)
        self.assertGreater(protocol.parse_ids_pb(bytes.fromhex(push["hex"]))[4], 0)

    def test_rankings_use_local_saves_pagination_and_unique_viewer_ids_without_writes(self):
        self.seed_shop_account()
        store = accounts.AccountStore(self.save_path, self.tables, self.step_counts, self.role_config)
        baseline = json.loads(self.save_path.read_text())
        for account, level, power in ((1, 11, 5000), (2, 12, 4000), (3, 11, 5000)):
            saved = copy.deepcopy(baseline)
            saved["role_name"] = f"本地角色{account}"
            saved["role_state"].update(level=level, power=power, power_all=power)
            path = store.path(account)
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(json.dumps(saved))
        files = {path: path.read_bytes() for path in self.save_path.parent.glob("**/*.json")}
        rows = list(self.entity_records(self.query_world_for_values(3500, [1, 1, 50]), 1, 1).values())
        names = lambda records: [next(v.decode() for n, w, v in protocol.iter_pb_fields(row) if n == 2) for row in records]
        self.assertEqual(names(rows), ["本地角色2", "本地角色1", "本地角色3"])
        self.assertEqual(protocol.pb_get_varint(rows[1], 1), protocol.pb_get_varint(bytes.fromhex(baseline["role_snapshot"]), 1))
        self.assertEqual(names(self.entity_records(self.query_world_for_values(3500, [2, 2, 1]), 1, 1).values()), ["本地角色3"])
        self.assertEqual(self.query_world_for_values(3500, [1, 20, 50]), b"")
        for method in (6, 8, 19):
            self.assertTrue(self.query_world_for_values(3500, [method, 1, 50]))
        for path, raw in files.items():
            self.assertEqual(path.read_bytes(), raw)

    def test_rankings_reject_bad_requests_and_corrupt_saves(self):
        self.seed_shop_account()
        before = self.save_path.read_bytes()
        for values in ([], [1, 0, 50], [1, 1, 0], [1, 1, 1001], [10, 1, 50], [1, 1, 50, 1]):
            self.assertEqual(self.replay([self.activity_request(3500, values)])[0]["opcode"], 999999)
            self.assertEqual(self.save_path.read_bytes(), before)
        path = self.save_path.parent / "accounts" / "2" / "role_save.json"
        path.parent.mkdir(parents=True)
        path.write_text("broken")
        self.assertEqual(self.replay([self.activity_request(3500, [1, 1, 50])])[0]["opcode"], 999999)
        self.assertEqual(path.read_text(), "broken")
        self.assertEqual(self.save_path.read_bytes(), before)

    def test_artifact_rank_uses_highest_owned_score_and_preserves_full_native_details(self):
        saved = self.seed_shop_account()
        saved["world_state"]["1002"] += b"".join(protocol.encode_pb_field(16, 2,
            b"".join(protocol.encode_pb_field(1, 2, protocol.encode_pb_field(2, 2, f"铸造者{iid}".encode()) if i == 3
                      else protocol.encode_pb_field(1, 0, value)) for i, value in enumerate(
                          [iid, 110001, 0] + [0] * 10 + [7] + [0] * 14 + [score], 1)))
            for iid, score in ((5000001, 777), (5000002, 999))).hex()
        self.save_path.write_text(json.dumps(saved))
        original = self.save_path.read_bytes()
        rows = self.entity_records(self.query_world_for_values(3500, [0, 1, 50]), 1, 1)
        self.assertEqual(len(rows), 1)
        raw = next(iter(rows.values()))
        params = next(v for n, w, v in protocol.iter_pb_fields(raw) if n == 8)
        values = [v for n, w, v in protocol.iter_pb_fields(params) if n == 1][4:]
        self.assertEqual(protocol.pb_get_varint(values[0], 1), 5000002)
        self.assertEqual(protocol.pb_get_varint(values[13], 1), 7)
        self.assertEqual(protocol.pb_get_varint(values[28], 1), 999)
        self.assertEqual(self.save_path.read_bytes(), original)

    def test_event_rank_growth_baseline_frozen_history_and_clock_rollback(self):
        saved = self.seed_shop_account()
        self.save_path.with_name("rankings.json").unlink()
        store = accounts.AccountStore(self.save_path, self.tables, self.step_counts, self.role_config)
        initial = store.observe_rankings()
        self.assertEqual(store.rank_query(1, bytes.fromhex(self.activity_request(3503, [11, 1, 50, 106])["hex"]), 3503), b"")
        baseline = saved["role_state"]["power"]
        saved["role_state"]["power"] += 500
        self.save_path.write_text(json.dumps(saved))
        store.observe_rankings()
        summary = store.rank_query(1, bytes.fromhex(self.activity_request(5601, [11, 1])["hex"]), 5601)
        groups = dict(protocol.get_comb_messages(summary))
        self.assertEqual(protocol.parse_ids_pb(groups[2]), [baseline])
        params = [v for n, w, v in protocol.iter_pb_fields(groups[1]) if n == 1]
        self.assertEqual(protocol.pb_get_varint(params[-1], 1), 500)
        self.clock.return_value = ranking.end_at(initial, 11, self.role_config)
        frozen = store.observe_rankings()["closed"]["11"]
        saved["role_state"]["power"] += 5000
        self.save_path.write_text(json.dumps(saved))
        store.observe_rankings()
        self.assertEqual(store.observe_rankings()["closed"]["11"], frozen)
        self.clock.return_value = self.now
        self.assertEqual(store.observe_rankings()["closed"]["11"], frozen)
        old = store.rank_query(1, bytes.fromhex(self.activity_request(3503, [11, 1, 50, 106])["hex"]), 3503)
        self.assertTrue(old)
        self.assertEqual(self.save_path.read_text(), json.dumps(saved))

    def test_rank_reward_mail_claim_is_persisted_once_and_unclaimed_mail_cannot_be_deleted(self):
        saved = self.seed_shop_account()
        self.save_path.with_name("rankings.json").unlink()
        store = accounts.AccountStore(self.save_path, self.tables, self.step_counts, self.role_config)
        state = store.observe_rankings()
        self.assertEqual(self.query_world(3100), b"")
        self.clock.return_value = ranking.end_at(state, 1, self.role_config)
        mails = self.entity_records(self.query_world(3100), 2, 1)
        mail = 700000001
        self.assertIn(mail, mails)
        attachment = json.loads(next(v.decode() for n, w, v in protocol.iter_pb_fields(mails[mail]) if n == 7))
        self.assertEqual(attachment["91008"], 10)
        before = self.save_path.read_bytes()
        self.assertEqual(self.replay([self.activity_request(3102, [mail])])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), before)
        request = self.activity_request(3101, [mail])
        replies = self.replay([request, request])
        self.assertEqual(replies[0], replies[1])
        self.assertEqual(replies[0]["opcode"], 3101)
        after = json.loads(self.save_path.read_text())
        self.assertEqual(after["role_state"]["coin"], saved["role_state"]["coin"] + 5000000)
        props = self.entity_records(self.query_world(1200), 1, 1)
        self.assertEqual(protocol.pb_get_varint(props[91008], 2), 10)
        original = self.save_path.read_bytes()
        self.assertEqual(self.replay([request])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), original)
        self.assertEqual(self.replay([self.activity_request(3102, [mail])])[0]["opcode"], 3102)
        self.assertNotIn(mail, self.entity_records(self.query_world(3100), 2, 1))

    def test_rank_reward_mail_failed_save_does_not_leak_claims_or_costume_bonuses(self):
        saved = self.seed_shop_account()
        self.save_path.with_name("rankings.json").unlink()
        store = accounts.AccountStore(self.save_path, self.tables, self.step_counts, self.role_config)
        state = store.observe_rankings()
        self.clock.return_value = ranking.end_at(state, 6, self.role_config)
        self.query_world(3100)
        original = self.save_path.read_bytes()
        with redirect_stdout(io.StringIO()):
            session = store.open_session(1, LOGIN_PASSWORD, ("test", 0))
            baseline = copy.deepcopy(session.save)
            with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
                session.handle(3101, 213, bytes.fromhex(self.activity_request(3101, [700000006])["hex"]))
        self.assertEqual(session.save, baseline)
        self.assertEqual(self.save_path.read_bytes(), original)
        store.close_session(1)
        reply = self.replay([self.activity_request(3101, [700000006])])
        self.assertEqual(reply[0]["opcode"], 3101)
        after = json.loads(self.save_path.read_text())
        self.assertEqual(after["fashion_state"]["levels"]["80007"], 1)
        self.assertEqual(after["role_state"]["power"], saved["role_state"]["power"] + 882)
        self.assertTrue(any(f["opcode"] == 1070 for f in reply))
        self.assertTrue(any(f["opcode"] == 205 for f in reply))

    def test_event_rank_rejects_ambiguous_context_and_corrupt_journal_without_overwrite(self):
        self.seed_shop_account()
        for opcode, values in ((5601, [99, 1]), (5601, [1, 3]), (3503, [1, 1, 50]),
                               (3500, [2, 1, 50, 11]), (5602, [1])):
            self.assertEqual(self.replay([self.activity_request(opcode, values)])[0]["opcode"], 999999)
        path = self.save_path.with_name("rankings.json")
        path.write_text("broken")
        self.assertEqual(self.replay([self.activity_request(5601, [1, 1])])[0]["opcode"], 999999)
        self.assertEqual(path.read_text(), "broken")

    def test_event_rank_removes_deleted_roles_before_freezing_standings(self):
        self.seed_shop_account()
        store = accounts.AccountStore(self.save_path, self.tables, self.step_counts, self.role_config)
        state = store.observe_rankings()
        self.assertIn("1", state["players"])
        self.save_path.unlink()
        self.assertEqual(store.observe_rankings()["players"], {})
        self.clock.return_value = ranking.end_at(state, 1, self.role_config)
        self.assertEqual(store.observe_rankings()["closed"]["1"], [])

    def seed_rob_account(self):
        self.seed_shop_account()
        saved = json.loads(self.save_path.read_text())
        saved["role_state"]["level"] = 11
        saved["guide"]["sections"]["52"] = {"status": 1, "step": 2, "steps": [1, 2]}
        self.save_path.write_text(json.dumps(saved))
        return saved

    def test_random_boxes_use_configured_weights_and_cache_only_same_connection_retries(self):
        self.seed_shop_account()
        entries = [tuple(map(int, entry.split(","))) for entry in self.role_config["props"]["20350"]["param1"].split(";") if entry]
        for count in (1, 10, 100):
            self.give_props({20350: count})
            before = json.loads(self.save_path.read_text())
            gets = shop.random.Random(42).choices(entries, weights=[e[2] for e in entries], k=count)
            expected = recruit.build_reward(before, [(cid, num) for cid, num, _ in gets], self.role_config)
            request = self.activity_request(1201, [20350, count])
            with patch.object(player.random, "getrandbits", return_value=42):
                replies = self.replay([request, request])
            self.assertEqual([reply["opcode"] for reply in replies], [1201, 1201])
            self.assertEqual(replies[0], replies[1])
            self.assertEqual(bytes.fromhex(replies[0]["hex"]), expected)
            self.assertFalse(any(n == 10 and v for n, w, v in protocol.iter_pb_fields(expected)))
            self.assertNotIn(20350, self.entity_records(self.query_world(1200), 1, 1))
            after = json.loads(self.save_path.read_text())
            for cid in {entry[0] for entry in gets}:
                key = "1107" if str(cid) in self.role_config["equip_fragment"] else "1200"
                old = self.entity_records(bytes.fromhex(before["world_state"][key]), 1, 1).get(cid, b"")
                new = self.entity_records(bytes.fromhex(after["world_state"][key]), 1, 1)[cid]
                self.assertEqual(protocol.pb_get_varint(new, 2) - (protocol.pb_get_varint(old, 2) or 0),
                                 sum(num for item, num, _ in gets if item == cid))
            for key in ("guide", "protagonist_snapshot", "role_state"):
                self.assertEqual(after[key], before[key])
            self.assertEqual(after["world_state"]["1300"], before["world_state"]["1300"])
            disk = self.save_path.read_bytes()
            self.assertEqual(self.replay([request])[0]["opcode"], 999999)
            self.assertEqual(self.save_path.read_bytes(), disk)

    def test_choice_boxes_grant_only_the_configured_selection_with_unique_equipment_iids(self):
        self.seed_shop_account()
        for cid in (20623, 20666):
            specification = self.role_config["props"][str(cid)]["param1"]
            entries = ([(int(entry), 1) for entry in specification.split(";") if entry] if cid == 20623 else
                       [tuple(map(int, entry.split(","))) for entry in specification.split(";") if entry])
            for index, (chosen, quantity) in enumerate(entries):
                count = 100 if index == len(entries) - 1 else 1
                self.give_props({cid: count})
                before = self.entity_records(self.query_world(1002), 2, 1)
                request = self.activity_request(1201, [cid, count, chosen])
                replies = self.replay([request, request])
                self.assertEqual([reply["opcode"] for reply in replies], [1201, 1201])
                self.assertEqual(replies[0], replies[1])
                reward = bytes.fromhex(replies[0]["hex"])
                equipment = [protocol.parse_ids_pb(v) for n, w, v in protocol.iter_pb_fields(reward) if (n, w) == (6, 2)]
                self.assertEqual([row[1] for row in equipment], [chosen] * (count * quantity))
                self.assertEqual(len({row[0] for row in equipment}), count * quantity)
                self.assertFalse(any(n == 10 and v for n, w, v in protocol.iter_pb_fields(reward)))
                stored = self.entity_records(self.query_world(1002), 2, 1)
                self.assertEqual(set(stored) - set(before), {row[0] for row in equipment})
                for row in equipment:
                    self.assertGreater(row[0], 1000000)
                    self.assertEqual(protocol.parse_ids_pb(stored[row[0]]), row)
                self.assertNotIn(cid, self.entity_records(self.query_world(1200), 1, 1))

    def test_random_and_choice_boxes_reject_bad_quantities_selections_and_comb_requests(self):
        self.seed_shop_account()
        self.give_props({20350: 1, 20623: 1, 20666: 1})
        original = self.save_path.read_bytes()
        for values in ([20350, 2], [20350, 101], [20350, 1, 27051], [20666, 1],
                       [20666, 2, 26417], [20666, 101, 26417], [20666, 1, 20100], [20666, 1, 1001],
                       [20623, 1], [20623, 2, 26402], [20623, 101, 26402], [20623, 1, 25403], [20623, 1, 1001]):
            with self.subTest(values=values):
                self.assertEqual(self.replay([self.activity_request(1201, values)])[0]["opcode"], 999999)
                self.assertEqual(self.save_path.read_bytes(), original)
        for values in ([20350, 0], [20666, 1, 0], [20666, 1, 26417, 1], [20623, 1, 0], [20623, 1, 26402, 1]):
            self.assert_rejected(self.activity_request(1201, values), "道具使用请求格式错误")
        for values in ([20350, 1], [20666, 1, 26417], [20623, 1, 26402]):
            body = protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 1201)
                                            + protocol.encode_pb_field(2, 2, bytes.fromhex(self.activity_request(1201, values)["hex"])))
            self.assertEqual(self.replay([{"opcode": 999900, "seq": 20000, "hex": body.hex()}])[0]["opcode"], 999999)
            self.assertEqual(self.save_path.read_bytes(), original)

    def test_random_boxes_allow_disabled_weights_but_reject_invalid_reward_configuration(self):
        self.seed_shop_account()
        self.give_props({20350: 10, 20623: 1, 20666: 1})
        original = self.save_path.read_bytes()
        cases = [(20350, specification, [20350, 1]) for specification in
                 ("", "27051,1,-1", "27051,1,0", "27051,0,1", "27051,1", "27051,1,1,1", "bad", "999999,1,1",
                  "20274,5,10000000;999999,1,1")]
        cases += [(20666, specification, [20666, 1, 26417]) for specification in
                  ("", "26417,0", "26417,1;26417,2", "26417,1,1", "bad")]
        cases += [(20623, specification, [20623, 1, 26402]) for specification in
                  ("", "26402,1", "26402;26402;", "bad")]
        cases += [(20623, "999999;", [20623, 1, 999999])]
        for cid, specification, values in cases:
            with self.subTest(cid=cid, specification=specification), patch.dict(self.role_config["props"][str(cid)], param1=specification):
                self.assertEqual(self.replay([self.activity_request(1201, values)])[0]["opcode"], 999999)
                self.assertEqual(self.save_path.read_bytes(), original)
        with patch.dict(self.role_config["props"]["20350"], param1="27051,1,0;20274,5,10"):
            reply = self.replay([self.activity_request(1201, [20350, 10])])[0]
        self.assertEqual(reply["opcode"], 1201)
        props = next(v for n, w, v in protocol.iter_pb_fields(bytes.fromhex(reply["hex"])) if n == 5)
        self.assertEqual({cid: protocol.pb_get_varint(raw, 2) for cid, raw in self.entity_records(props, 1, 1).items()}, {20274: 50})

    def test_boxes_allow_full_stack_counts_and_coin_rewards_keep_int64_range(self):
        self.seed_shop_account()
        self.give_props({20350: 501})
        reply = self.replay([self.activity_request(1201, [20350, 501])])[0]
        self.assertEqual(reply["opcode"], 1201)
        self.assertNotIn(20350, self.entity_records(self.query_world(1200), 1, 1))

    def test_coin_balances_allow_int64_while_gold_stays_int32(self):
        saved = self.seed_shop_account()
        saved["role_state"]["coin"] = (1 << 31) - 1
        player.apply_reward(saved, protocol.encode_pb_field(1, 0, 100000000), self.role_config)
        self.assertEqual(saved["role_state"]["coin"], (1 << 31) - 1 + 100000000)
        saved["role_state"]["gold"] = (1 << 31) - 1
        with self.assertRaisesRegex(ValueError, "gold 超出范围"):
            player.apply_reward(saved, protocol.encode_pb_field(2, 0, 1), self.role_config)

    def test_coin_reward_builders_keep_int64_without_widening_other_rewards(self):
        saved = self.seed_shop_account()
        for count in ((1 << 31) + 1, (1 << 63) - 1):
            self.assertEqual(protocol.pb_get_varint(activities.build_reward(saved, f"1000,{count}", self.role_config), 1), count)
            self.assertEqual(protocol.pb_get_varint(recruit.build_reward(saved, [(1000, count)], self.role_config), 1), count)
        for cid, count in ((1000, 0), (1000, -1), (1000, 1 << 63), (1001, 1 << 31),
                           (1002, 1 << 31), (1003, 1 << 31), (20019, 1 << 31)):
            with self.subTest(cid=cid, count=count):
                with self.assertRaises(ValueError):
                    activities.build_reward(saved, f"{cid},{count}", self.role_config)
                with self.assertRaises(ValueError):
                    recruit.build_reward(saved, [(cid, count)], self.role_config)

    def test_random_and_choice_box_save_failures_and_overflow_do_not_publish_partial_rewards(self):
        self.seed_shop_account()
        self.give_props({20350: 1, 20623: 1, 20666: 1})
        original = self.save_path.read_bytes()
        for values in ([20350, 1], [20666, 1, 26417], [20623, 1, 26402]):
            with redirect_stdout(io.StringIO()):
                session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
                memory = copy.deepcopy(session.save)
                with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
                    session.handle(1201, 234, bytes.fromhex(self.activity_request(1201, values)["hex"]))
            self.assertEqual(session.save, memory)
            self.assertEqual(session.random_replies, {})
            self.assertEqual(self.save_path.read_bytes(), original)
        saved = json.loads(original)
        saved["role_state"]["coin"] = (1 << 63) - 1
        self.save_path.write_text(json.dumps(saved))
        original = self.save_path.read_bytes()
        for cid, specification, values in ((20350, "1000,1,1", [20350, 1]), (20666, "1000,1", [20666, 1, 1000]),
                                           (20623, "1000;", [20623, 1, 1000])):
            with patch.dict(self.role_config["props"][str(cid)], param1=specification):
                self.assertEqual(self.replay([self.activity_request(1201, values)])[0]["opcode"], 999999)
                self.assertEqual(self.save_path.read_bytes(), original)

    def test_actual_apk_box_callbacks_send_choice_cids_and_deduct_boxes_once(self):
        import test_activity_copy
        self.seed_shop_account()
        self.give_props({20350: 11, 20623: 11, 20666: 2})
        self.config = self.role_config
        lua = test_activity_copy.ActivityCopyTests.network_lua(self)
        lua.execute(apk_builder.read_script("idnums_pb", "pb"))
        lua.execute(b'''table.copy=function(t) local c={} for k,v in pairs(t) do c[k]=v end return c end
            gamedata.cache.props={[20350]={cid=20350,num=11},[20623]={cid=20623,num=11},[20666]={cid=20666,num=2}}
            gamedata.sortData=function() end
            function gamedata:updateprops(t)
                local row=self.cache.props[t.cid];row.num=row.num+t.num
            end''')
        lua.execute(apk_builder.read_script("GamePropList"))
        remaining = {20350: 11, 20623: 11, 20666: 2}
        for values in ([20350, 1], [20350, 10], [20666, 1, 26417], [20666, 1, 26420],
                       [20623, 1, 26402], [20623, 10, 26406]):
            request = {b"cid": values[0], b"num": values[1]}
            if len(values) == 3:
                request[b"choose"] = values[2]
            remote, opcode, body = lua.globals().UIPropUseCallback(lua.table_from(request))
            self.assertEqual((remote, opcode, body), (1, 1201, bytes.fromhex(self.activity_request(1201, values)["hex"])))
            packet = self.replay([self.activity_request(opcode, values)])[0]
            self.assertEqual(packet["opcode"], 1201)
            reply = lua.globals().NetPropUseCallback(lua.table_from({b"rbuf": bytes.fromhex(packet["hex"])}))
            remaining[values[0]] -= values[1]
            self.assertEqual(reply[b"propscachedata"][values[0]][b"num"], remaining[values[0]])
            self.assertEqual(len(reply[b"rewards"][b"usedcidnums"]), 0)
            if len(values) == 3:
                self.assertEqual([row[b"ids"][2] for _, row in reply[b"rewards"][b"equips"].items()], [values[2]] * values[1])

    def test_key_boxes_use_configured_weights_and_consume_matching_keys_once(self):
        self.seed_shop_account()
        self.give_props({cid: 100 for cid in range(20001, 20009)})
        for cid in range(20001, 20005):
            before = json.loads(self.save_path.read_text())
            request = self.activity_request(1201, [cid, 100])
            with patch.object(player.random, "getrandbits", return_value=42):
                replies = self.replay([request, request])
            self.assertEqual(replies[0], replies[1])
            self.assertEqual(replies[0]["opcode"], 1201)
            reward = bytes.fromhex(replies[0]["hex"])
            self.assertFalse(any(n == 10 and w == 2 and v for n, w, v in protocol.iter_pb_fields(reward)))
            expected = shop.open_box(before, [cid, 100], self.role_config, 42)
            self.assertEqual(reward, expected)
            props = self.entity_records(self.query_world(1200), 1, 1)
            self.assertNotIn(cid, props)
            self.assertNotIn(cid + 4, props)
            fragments = self.entity_records(self.query_world(1107), 1, 1)
            for raw in self.entity_records(next(v for n, w, v in protocol.iter_pb_fields(reward) if n == 5), 1, 1).values():
                item = protocol.pb_get_varint(raw, 1)
                if str(item) in self.role_config["treasure2_fragment"]:
                    self.assertIn(item, fragments)

    def test_key_box_invalid_keys_quantities_and_failed_save_leave_inventory_untouched(self):
        self.seed_shop_account()
        self.give_props({20004: 2, 20008: 1})
        original = self.save_path.read_bytes()
        for values in ([20004, 2], [20004, 101], [20004, 1, 1], [20008, 1]):
            self.assertEqual(self.replay([self.activity_request(1201, values)])[0]["opcode"], 999999)
            self.assertEqual(self.save_path.read_bytes(), original)
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            baseline = copy.deepcopy(session.save)
            with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
                session.handle(1201, 234, bytes.fromhex(self.activity_request(1201, [20004, 1])["hex"]))
        self.assertEqual(session.save, baseline)
        self.assertEqual(self.save_path.read_bytes(), original)

    def test_all_configured_treasure_fragments_have_npcs_and_atomic_compounds(self):
        saved = self.seed_rob_account()
        saved["world_state"]["1107"] = ""
        for cid, row in self.role_config["treasure2_fragment"].items():
            body = bytes.fromhex(self.activity_request(1110, [int(cid)])["hex"])
            reply, _, _ = rob.prepare(1110, copy.deepcopy(saved), body, self.role_config, 42)
            self.assertEqual(len(self.entity_records(reply, 1, 1)), 3)
        equips = {row["equip"] for row in self.role_config["treasure2_fragment"].values()}
        for equip in sorted(equips):
            working = copy.deepcopy(saved)
            fragments = [row["id"] for row in self.role_config["treasure2_fragment"].values() if row["equip"] == equip]
            working["world_state"]["1107"] = b"".join(protocol.encode_pb_field(1, 2,
                protocol.encode_pb_field(1, 0, cid) + protocol.encode_pb_field(2, 0, 1)) for cid in fragments).hex()
            reply, costs, _ = rob.prepare(1108, working, bytes.fromhex(self.activity_request(1108, [equip])["hex"]), self.role_config, 42)
            self.assertEqual(costs, [(cid, 1) for cid in sorted(fragments)])
            if str(equip) in self.role_config["props"]:
                props = self.entity_records(next(v for n, w, v in protocol.iter_pb_fields(reply) if n == 5), 1, 1)
                self.assertEqual(protocol.pb_get_varint(props[equip], 2), 1)
            else:
                self.assertEqual([protocol.parse_ids_pb(v)[1] for n, w, v in protocol.iter_pb_fields(reply) if n == 6], [equip])
        saved["guide"]["sections"]["52"] = {"status": 2, "step": 7, "steps": list(range(1, 8))}
        self.save_path.write_text(json.dumps(saved))
        self.give_props({28001: 1, 28002: 1, 28003: 1})
        self.assertEqual(self.replay([self.activity_request(1108, [25101])])[0]["opcode"], 1108)
        self.assertFalse(any(cid in self.entity_records(self.query_world(1107), 1, 1) for cid in (28001, 28002, 28003)))

    def test_treasure_batches_use_real_results_stop_on_fragment_and_return_actual_costs(self):
        self.seed_rob_account()
        before = json.loads(self.save_path.read_text())
        rid = rob.NPC_BASE + 28001 * 3
        request = self.activity_request(1114, [rid])
        with patch.object(player.random, "getrandbits", return_value=42):
            replies = self.replay([request, request])
        self.assertEqual(replies[0], replies[1])
        self.assertEqual(replies[0]["opcode"], 1114)
        messages = protocol.get_comb_messages(bytes.fromhex(replies[0]["hex"]))
        attempts = protocol.parse_ids_pb(messages[0][1])[0]
        self.assertTrue(1 <= attempts <= 10)
        self.assertEqual(len(messages), attempts + 1)
        saved = json.loads(self.save_path.read_text())
        self.assertEqual(saved["role_state"]["energy"], before["role_state"]["energy"] - attempts)
        self.assertEqual(saved["role_state"]["stamina"], before["role_state"]["stamina"])
        self.assertEqual(saved["last_rob"]["attempts"], attempts)
        self.assertIn(28001, self.entity_records(self.query_world(1107), 1, 1))

    def test_one_key_restores_energy_only_when_needed_and_rolls_back_bad_batches(self):
        saved = self.seed_rob_account()
        saved["role_state"]["energy"] = 0
        self.save_path.write_text(json.dumps(saved))
        self.give_props({20015: 2, 20020: 1})
        original = self.save_path.read_bytes()
        for values in ([0, 28001, 28002], [1, 28001, 28001], [1, 28001, 28010], [2, 28001], [1, 29999]):
            self.assertEqual(self.replay([self.activity_request(1125, values)])[0]["opcode"], 999999)
            self.assertEqual(self.save_path.read_bytes(), original)
        with patch.object(player.random, "getrandbits", return_value=42):
            response = self.replay([self.activity_request(1125, [1, 28001, 28002, 28003])])[0]
        self.assertEqual(response["opcode"], 1125)
        messages = protocol.get_comb_messages(bytes.fromhex(response["hex"]))
        attempts, large, small = protocol.parse_ids_pb(messages[0][1])
        self.assertGreater(attempts, 0)
        self.assertEqual((large, small), (0, 1))
        saved = json.loads(self.save_path.read_text())
        self.assertEqual(saved["role_state"]["energy"], 10 - attempts)
        props = self.entity_records(self.query_world(1200), 1, 1)
        self.assertEqual(protocol.pb_get_varint(props[20015], 2), 1)
        previous = self.entity_records(bytes.fromhex(json.loads(original)["world_state"]["1200"]), 1, 1)
        self.assertEqual(protocol.pb_get_varint(props[20020], 2), protocol.pb_get_varint(previous[20020], 2))
        fragments = self.entity_records(self.query_world(1107), 1, 1)
        self.assertTrue(all(cid in fragments for cid in (28001, 28002, 28003)))

    def test_treasure_batch_losses_cost_energy_and_failed_save_rolls_back_every_attempt(self):
        saved = self.seed_rob_account()
        for raw in self.entity_records(bytes.fromhex(saved["world_state"]["1002"]), 1, 2).values():
            for field, value in ((6, 1), (7, 0), (8, 1), (9, 1)):
                raw = protocol.pb_set_varint(raw, field, value)
            player.record_slot_update(saved, protocol.encode_pb_field(1, 2, raw))
            player.record_protagonist_general(saved, raw)
        self.save_path.write_text(json.dumps(saved))
        request = self.activity_request(1114, [rob.NPC_BASE + 28001 * 3])
        response = self.replay([request])[0]
        self.assertEqual(response["opcode"], 1114)
        groups = protocol.get_comb_messages(bytes.fromhex(response["hex"]))
        self.assertEqual(protocol.parse_ids_pb(groups[0][1]), [10])
        after = json.loads(self.save_path.read_text())
        self.assertEqual(after["role_state"]["energy"], saved["role_state"]["energy"] - 10)
        self.assertEqual(after["world_state"], saved["world_state"])
        self.assertEqual(after["last_rob"]["wins"], 0)
        original = self.save_path.read_bytes()
        for opcode, values in ((1114, [rob.NPC_BASE + 28001 * 3]), (1125, [1, 28001, 28002, 28003])):
            with redirect_stdout(io.StringIO()):
                session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
                baseline = copy.deepcopy(session.save)
                with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
                    session.handle(opcode, 324, bytes.fromhex(self.activity_request(opcode, values)["hex"]))
            self.assertEqual(session.save, baseline)
            self.assertEqual(self.save_path.read_bytes(), original)

    def rob_guide_request(self, rid):
        return {"opcode": 999900, "seq": 12345, "hex": b"".join(
            protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, mid) + protocol.encode_pb_field(2, 2, data))
            for mid, data in ((1111, bytes.fromhex(self.activity_request(1111, [rid, 999])["hex"])),
                              (201, b"\x08\x34\x10\x03"))).hex()}

    def test_rob_guide_battle_rewards_fragments_and_compound_survive_reconnect(self):
        self.seed_rob_account()
        self.assertEqual(protocol.parse_ids_pb(self.query_world(1112)), [0])
        players = list(self.entity_records(self.query_world_for_values(1110, [28010]), 1, 1).values())
        self.assertEqual(len(players), 3)
        rid = protocol.pb_get_varint(players[0], 1)
        self.assertGreater(rid, 2146483648)
        before = json.loads(self.save_path.read_text())
        request = self.rob_guide_request(rid)
        replies = self.replay([request, request])
        self.assertEqual(replies[0], replies[1])
        result = dict(protocol.get_comb_messages(bytes.fromhex(replies[0]["hex"])))[1111]
        self.assertEqual(protocol.pb_get_varint(result, 1), 1)
        report = json.loads(next(v for n, w, v in protocol.iter_pb_fields(result) if n == 5))
        self.assert_battle_report(report)
        saved = json.loads(self.save_path.read_text())
        self.assertEqual(saved["role_state"]["energy"], before["role_state"]["energy"] - 1)
        self.assertEqual(saved["role_state"]["stamina"], before["role_state"]["stamina"])
        self.assertEqual(saved["guide"]["sections"]["52"]["step"], 3)
        fragments = self.entity_records(self.query_world(1107), 1, 1)
        self.assertEqual(protocol.pb_get_varint(fragments[28010], 2), 1)
        compound = self.replay([self.activity_request(1108, [26102])])[0]
        self.assertEqual(compound["opcode"], 1108)
        equipment = self.entity_records(self.query_world(1002), 2, 1)
        self.assertEqual(sum(protocol.parse_ids_pb(raw)[1] == 26102 for raw in equipment.values()), 1)
        fragments = self.entity_records(self.query_world(1107), 1, 1)
        self.assertTrue(all(cid not in fragments for cid in (28010, 28011, 28012)))
        initial = self.replay([dict(self.by_seq[12], seq=23456)])[0]
        restored = self.entity_records(dict(protocol.get_comb_messages(bytes.fromhex(initial["hex"])))[1107], 1, 1)
        self.assertTrue(all(cid not in restored for cid in (28010, 28011, 28012)))
        self.assertEqual(self.replay([self.activity_request(1108, [26102])])[0]["opcode"], 999999)

    def test_rob_invalid_requests_and_save_failure_do_not_charge_or_advance_guide(self):
        self.seed_rob_account()
        players = list(self.entity_records(self.query_world_for_values(1110, [28010]), 1, 1).values())
        rid = protocol.pb_get_varint(players[0], 1)
        original = self.save_path.read_bytes()
        for request in (self.activity_request(1107, [1]), self.activity_request(1110, [28011]), self.activity_request(1110, [29999]),
                        self.activity_request(1111, [250, 0]), self.activity_request(1111, [rid, 1]),
                        self.activity_request(1111, [rid, 0, 0]), self.activity_request(1108, [26102])):
            self.assertEqual(self.replay([request])[0]["opcode"], 999999)
            self.assertEqual(self.save_path.read_bytes(), original)
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            baseline = copy.deepcopy(session.save)
            with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
                session.handle(999900, 12345, bytes.fromhex(self.rob_guide_request(rid)["hex"]))
        self.assertEqual(session.save, baseline)
        self.assertEqual(self.save_path.read_bytes(), original)

    def test_rob_guide_comb_rejects_unmatched_fields_and_saves_before_reply(self):
        self.seed_rob_account()
        rows = self.entity_records(self.query_world_for_values(1110, [28010]), 1, 1)
        rid = next(iter(rows))
        request = self.rob_guide_request(rid)
        original = self.save_path.read_bytes()
        raw = bytes.fromhex(request["hex"])
        for invalid in (raw + b"\x10\x01", raw + raw[:raw[1] + 2], raw.replace(b"\x08\x34\x10\x03", b"\x08\x34\x10\x04")):
            self.assertEqual(self.replay([dict(request, hex=invalid.hex())])[0]["opcode"], 999999)
            self.assertEqual(self.save_path.read_bytes(), original)
        self.assertEqual(self.replay([self.rob_guide_request(rob.NPC_BASE + 28001 * 3)])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), original)
        conn = ReplayConnection([request], 7)
        send = conn.sendall
        def check_saved(packet):
            saved = json.loads(self.save_path.read_text())
            self.assertEqual(saved["guide"]["sections"]["52"]["step"], 3)
            self.assertEqual(saved["role_state"]["energy"], 19)
            self.assertEqual(protocol.pb_get_varint(self.entity_records(bytes.fromhex(saved["world_state"]["1107"]), 1, 1)[28010], 2), 1)
            send(packet)
        conn.sendall = check_saved
        with redirect_stdout(io.StringIO()):
            self.run_client(conn)
        self.assertEqual([f["opcode"] for f in conn.responses], [999900])

    def test_rob_real_loss_spends_energy_without_rewards_or_stat_changes(self):
        saved = self.seed_rob_account()
        world = bytes.fromhex(saved["world_state"]["1002"])
        for raw in self.entity_records(world, 1, 2).values():
            for field, value in ((6, 1), (7, 0), (8, 1), (9, 1)):
                raw = protocol.pb_set_varint(raw, field, value)
            player.record_slot_update(saved, protocol.encode_pb_field(1, 2, raw))
            player.record_protagonist_general(saved, raw)
        self.save_path.write_text(json.dumps(saved))
        players = list(self.entity_records(self.query_world_for_values(1110, [28010]), 1, 1).values())
        rid = protocol.pb_get_varint(players[0], 1)
        before = json.loads(self.save_path.read_text())
        reply = self.replay([self.activity_request(1111, [rid, 0])])[0]
        self.assertEqual(reply["opcode"], 1111)
        self.assertEqual(protocol.pb_get_varint(bytes.fromhex(reply["hex"]), 1), 0)
        saved = json.loads(self.save_path.read_text())
        self.assertEqual(saved["world_state"], before["world_state"])
        for key, value in before["role_state"].items():
            self.assertEqual(saved["role_state"][key], value - 1 if key == "energy" else value)
        before = self.save_path.read_bytes()
        self.assertEqual(self.replay([self.rob_guide_request(rid)])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), before)

    def test_latest_missing_read_queries_reports_and_hint_retrieval(self):
        self.seed_shop_account()
        self.query_world(1032)
        before = self.save_path.read_bytes()
        self.assertEqual(protocol.parse_ids_pb(self.query_world(204)), [1])
        self.assertEqual(self.query_world(6911), b"")
        rows = self.begin7day_groups(self.query_world(4016))
        self.assertEqual(set(rows), set(range(1, 6)))
        for group, counts in rows.items():
            self.assertEqual(counts, [0] * max(map(int, self.role_config["exchange_shop"].get(str(group), {})), default=0))
        self.assertEqual(self.query_world_for_values(999901, [12]), b"\x08\x0c")
        reply = self.replay([self.activity_request(999989, [1032])])[0]
        self.assertEqual((reply["opcode"], reply["hex"]), (1032, self.query_world(1032).hex()))
        self.assertEqual(self.save_path.read_bytes(), before)
        for request in (self.activity_request(204, [1]), self.activity_request(6911, [1]),
                        self.activity_request(4016, [1]), self.activity_request(4017, [1, 1]),
                        self.activity_request(999901), self.activity_request(999901, [12, 12]),
                        self.activity_request(999989, [1111])):
            self.assertEqual(self.replay([request])[0]["opcode"], 999999)
            self.assertEqual(self.save_path.read_bytes(), before)

    def test_shop_purchase_is_saved_before_reply_and_retry_is_not_recharged(self):
        self.seed_shop_account()
        request = self.shop_request(3201, 21)
        conn = ReplayConnection([request, request], 7)
        send = conn.sendall

        def check_saved(packet):
            saved = json.loads(self.save_path.read_text())
            self.assertEqual(saved["role_state"]["gold"], 998800)
            self.assertEqual(saved["shop_state"]["props"]["21"], 1)
            send(packet)

        conn.sendall = check_saved
        with redirect_stdout(io.StringIO()):
            self.run_client(conn)
        self.assertEqual([f["opcode"] for f in conn.responses], [3201, 1034] * 2)
        self.assertEqual(self.hint_changes(conn.responses[1]), {40: 1})
        self.assertEqual(conn.responses[:2], conn.responses[2:])

    def test_fashion_discount_ownership_and_level_gate(self):
        self.seed_shop_account()
        self.clock.return_value = 1478620800  # 2016-11-09 00:00 UTC+8，配置活动开始。
        response = self.replay([self.activity_request(1076)])[0]
        self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(response["hex"])), [80001, 80001, 1])
        self.replay([self.activity_request(1074, [80001])])
        self.assertEqual(self.query_role()[9], 998001)
        response = self.replay([self.activity_request(1076)])[0]
        self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(response["hex"])), [80001, 80001, 2])
        original = self.save_path.read_bytes()
        self.assertEqual(self.replay([self.activity_request(1074, [80001])])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), original)
        self.give_props({20281: 100})
        saved = json.loads(self.save_path.read_text())
        saved["role_state"]["level"] = 1
        self.save_path.write_text(json.dumps(saved))
        self.replay([self.activity_request(1072, [80001, 5])])
        self.assertEqual(json.loads(self.save_path.read_text())["fashion_state"]["levels"], {"80001": 2})
        original = self.save_path.read_bytes()
        self.assertEqual(self.replay([self.activity_request(1072, [80001])])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), original)

    def begin7day_groups(self, body):
        groups = {}
        for n, w, row in protocol.iter_pb_fields(body):
            if n == 1 and w == 2:
                data = next(v for f, t, v in protocol.iter_pb_fields(row) if f == 2 and t == 2)
                groups[protocol.pb_get_varint(row, 1)] = protocol.parse_ids_pb(data)
        return groups

    def hint_map(self, body):
        return {value // 100: value % 100 for n, w, value in protocol.iter_pb_fields(body) if n == 1 and w == 0}

    def hint_changes(self, response):
        self.assertEqual((response["opcode"], response["seq"]), (1034, 0))
        return {mid: protocol.pb_get_varint(row, 2)
                for mid, row in self.entity_records(bytes.fromhex(response["hex"]), 1, 1).items()}

    def seed_stamina(self, amount):
        saved = player.get_default_save()
        saved["has_role"] = True
        saved["role_snapshot"] = self.recorded[(41, 1001)]["hex"]
        saved["role_state"] = {"level": 1, "exp": 0, "stamina": amount, "maxstamina": 50}
        self.save_path.write_text(json.dumps(saved))

    def give_props(self, amounts):
        saved = json.loads(self.save_path.read_text())
        with redirect_stdout(io.StringIO()):
            player.initialize_world_state(saved, self.tables[2])
            for cid, count in amounts.items():
                player.change_item_count(saved, cid, count, self.role_config)
        self.save_path.write_text(json.dumps(saved))

    def query_role(self):
        response = self.replay([dict(self.by_seq[41], seq=20000)])
        self.assertEqual(len(response), 1)
        return self.role_data(response[0])

    def entity_records(self, body, field, key_field):
        return {protocol.pb_get_varint(value, key_field): value for n, wire, value in protocol.iter_pb_fields(body) if n == field and wire == 2}

    def replay_through(self, seq):
        return self.replay([f for f in self.requests if f["seq"] <= seq])

    def expected_group(self, recorded_seq, live_seq=None):
        request = self.by_seq[recorded_seq]
        start = self.frames.index(request) + 1
        end = next((i for i in range(start, len(self.frames)) if self.frames[i]["c2s"]), len(self.frames))
        result = []
        for index, frame in enumerate(self.frames):
            if frame["c2s"]:
                continue
            reply = frame["seq"] == recorded_seq and frame["opcode"] == request["opcode"]
            push = start <= index < end and frame["seq"] == 0 and frame["opcode"] in (205, 1024, 1027) and frame["hex"]
            if reply or push:
                seq = (recorded_seq if live_seq is None else live_seq) if reply else 0
                result.append({"opcode": frame["opcode"], "seq": seq, "hex": frame["hex"]})
        return result

    def test_select_does_not_receive_city_init_at_same_sequence(self):
        request = dict(self.by_seq[11], seq=12)
        responses = self.replay([request], chunk_size=7)
        self.assertEqual(len(responses), 1)
        self.assert_recorded_response(responses[0], 11, 12)

    def test_recruit_does_not_receive_battle_at_same_sequence(self):
        request = dict(self.by_seq[49], seq=36)
        responses = self.replay([request])
        self.assert_recorded_response(responses[0], 49, 36)

    def test_second_battle_uses_its_parameters_after_exact_first_battle(self):
        requests = [self.by_seq[36], dict(self.by_seq[61], seq=10000)]
        responses = [f for f in self.replay(requests) if f["seq"] != 0]
        self.assertEqual(len(responses), 2)
        self.assert_recorded_response(responses[0], 36)
        self.assert_recorded_response(responses[1], 61, 10000)

    def test_second_battle_can_resume_without_replaying_first_battle(self):
        responses = [f for f in self.replay([dict(self.by_seq[61], seq=10000)]) if f["seq"] != 0]
        self.assert_recorded_response(responses[0], 61, 10000)

    def test_phone_field_order_starts_first_battle_and_survives_reconnect(self):
        self.replay_through(35)
        request = dict(self.by_seq[36], seq=30, hex="0a0b089a0a120608f5c80208010a0908c901120410080801")
        responses = self.replay([request], chunk_size=7)
        self.assertEqual(responses[:-1], self.expected_group(36, 30))
        self.assertEqual(self.hint_changes(responses[-1]), {44: 1})
        saved = json.loads(self.save_path.read_text())
        self.assertEqual([saved[k] for k in ("level", "silver", "gold")], [2, 2960, 10])
        self.assertEqual(saved["guide"]["sections"]["1"], {"status": 1, "step": 8, "steps": list(range(1, 9))})
        responses = self.replay([{"opcode": 200, "seq": 2, "hex": ""}, dict(self.by_seq[12], seq=5)])
        self.assertEqual(responses[0], {"opcode": 200, "seq": 2, "hex": "0a06080110011808"})
        self.assertEqual([self.role_data(responses[1])[n] for n in (5, 8, 9, 10)], [2, 2960, 10, 49])
        self.assert_rejected(request, "已通关关卡不支持重复录制战斗")

    def test_equivalent_comb_encodings_share_recordings_and_counters(self):
        request = self.by_seq[36]
        phone = dict(request, hex="0a0b089a0a120608f5c80208010a0908c901120410080801")
        first = {"c2s": False, "opcode": 999900, "seq": 36, "hex": "0a0708c90112020801"}
        second = dict(first, hex="0a0708c90112020800")
        with redirect_stdout(io.StringIO()):
            tables = replay.build_routing_tables([request, first, phone, second])
            routing = replay.Replay(tables)
            for body, seq, expected in ((request, 36, first), (phone, 10000, second),
                                        (phone, 36, first), (request, 10001, second)):
                self.assertEqual(routing.match(999900, seq, bytes.fromhex(body["hex"])), [expected])
        self.assertEqual(len(tables[1]), 1)
        self.assertEqual(list(tables[3].values()), [[[first], [second]]])

    def test_comb_field_order_variants_match_all_recorded_requests(self):
        for request in self.requests:
            if request["opcode"] != 999900:
                continue
            body = bytes.fromhex(request["hex"])
            fields = []
            for field, wire, value in protocol.iter_pb_fields(body):
                subfields = list(protocol.iter_pb_fields(value))
                if protocol.pb_get_varint(value, 1) in (201, 1003):
                    subfields = [(n, w, b"".join(protocol.encode_pb_field(*f) for f in reversed(list(protocol.iter_pb_fields(v)))))
                                 if (n, w) == (2, 2) else (n, w, v) for n, w, v in subfields]
                value = b"".join(protocol.encode_pb_field(*f) for f in reversed(subfields))
                fields.append(protocol.encode_pb_field(field, wire, value))
            with self.subTest(seq=request["seq"]), redirect_stdout(io.StringIO()):
                expected = replay.Replay(self.tables).match(999900, request["seq"], body)
                actual = replay.Replay(self.tables).match(999900, 10000, b"".join(fields))
                self.assertIsNotNone(expected)
                self.assertEqual(actual, expected)

    def test_comb_normalization_preserves_full_parameters_and_repeated_order(self):
        self.replay_through(35)
        before = self.save_path.read_bytes()
        self.clock.return_value = self.now + 360
        battle = bytes.fromhex("08f5c8020801")
        report = bytes.fromhex("10080801")

        def comb(battle_data, guide_data):
            return b"".join(protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, mid)
                            + protocol.encode_pb_field(2, 2, data)) for mid, data in ((1306, battle_data), (201, guide_data)))

        body = comb(battle, report)
        first, second = [v for n, w, v in protocol.iter_pb_fields(body)]
        bodies = [comb(bytes.fromhex("08f6c8020801"), report),
                  comb(bytes.fromhex("08f5c8020802"), report),
                  comb(bytes.fromhex("080108f5c802"), report),
                  comb(battle, b"\x10\x09\x08\x01"),
                  comb(battle, b"\x10\x08\x08\x02"),
                  comb(battle, report + b"\x08\x01"),
                  comb(battle, report + b"\x18\x01"),
                  comb(battle + b"\x18\x01", report),
                  protocol.encode_pb_field(1, 2, second) + protocol.encode_pb_field(1, 2, first),
                  body + protocol.encode_pb_field(1, 2, second),
                  body + b"\x10\x01"]
        for extra in (b"\x18\x01", protocol.encode_pb_field(1, 0, 1306), protocol.encode_pb_field(2, 2, battle)):
            bodies.append(protocol.encode_pb_field(1, 2, first + extra) + protocol.encode_pb_field(1, 2, second))
        for changed in bodies:
            with self.subTest(body=changed.hex()):
                for seq in (36, 10000):
                    responses = self.replay([dict(self.by_seq[36], seq=seq, hex=changed.hex())])
                    self.assert_unavailable_response(responses, 999900, seq, "关卡")
                    self.assertEqual(self.save_path.read_bytes(), before)
        malformed = comb(battle, b"\x10\x80")
        self.assert_rejected(dict(self.by_seq[36], hex=malformed.hex()), "截断的 Protobuf varint")

    def test_unknown_battle_parameters_do_not_receive_a_different_battle(self):
        body = bytes.fromhex(self.by_seq[61]["hex"])
        point_two = b"\x08" + protocol.encode_varint(42101) + b"\x08\x02"
        self.assertEqual(body.count(point_two), 1)
        body = body.replace(point_two, b"\x08" + protocol.encode_varint(42101) + b"\x08\x63")
        responses = self.replay([dict(self.by_seq[61], seq=10000, hex=body.hex())])
        self.assert_unavailable_response(responses, 999900, 10000, "关卡")
        self.assertFalse(self.save_path.exists())

    def assert_unavailable_response(self, responses, opcode, seq, message):
        self.assertEqual([(f["opcode"], f["seq"]) for f in responses], [(999999, seq), (1999, 0)])
        self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(responses[0]["hex"])), [opcode, 0])
        fields = list(protocol.iter_pb_fields(bytes.fromhex(responses[1]["hex"])))
        self.assertEqual([(n, w) for n, w, _ in fields], [(1, 2)])
        self.assertIn(message, fields[0][2].decode("utf-8"))

    def test_out_of_scope_standalone_battle_does_not_spend_or_start_empty_battle(self):
        self.replay(self.requests)
        before = self.save_path.read_bytes()
        request = dict(self.activity_request(1306, [99999, 1]), seq=36)
        responses = self.replay([request, dict(request, seq=37), self.activity_request(1300)], chunk_size=7)
        self.assert_unavailable_response(responses[:2], 1306, 36, "关卡")
        self.assert_unavailable_response(responses[2:4], 1306, 37, "关卡")
        self.assertEqual(responses[4]["opcode"], 1300)
        self.assertEqual(self.save_path.read_bytes(), before)

    def test_unrecorded_battle_payloads_do_not_mutate_current_progress(self):
        self.replay(self.requests)
        before = self.save_path.read_bytes()
        for body in ("", "08", "0800", "08f6c8020863", "08f6c80208021001", "08f6c80208020801"):
            with self.subTest(body=body):
                responses = self.replay([{"opcode": 1306, "seq": 36, "hex": body}])
                self.assert_unavailable_response(responses, 1306, 36, "关卡")
                self.assertEqual(self.save_path.read_bytes(), before)

    def test_unrecorded_selection_does_not_create_a_role(self):
        body = bytes.fromhex(self.by_seq[11]["hex"])
        self.assertEqual(body.count(b"\x12\x02\x08\x03"), 1)
        body = body.replace(b"\x12\x02\x08\x03", b"\x12\x02\x08\x01")
        responses = self.replay([dict(self.by_seq[11], hex=body.hex())])
        self.assert_unavailable_response(responses, 999900, 11, "尚未实现")
        self.assertFalse(self.save_path.exists())

    def test_exact_ordinary_reply_advances_fallback_counter(self):
        hints = [f for f in self.requests if f["opcode"] == 1032 and not f["hex"]]
        responses = self.replay([hints[0], dict(hints[1], seq=10000)])
        self.assert_recorded_response(responses[0], hints[0]["seq"])
        self.assert_recorded_response(responses[1], hints[1]["seq"], 10000)

    def test_sessions_share_recordings_but_not_replay_counters(self):
        hints = [f for f in self.requests if f["opcode"] == 1032 and not f["hex"]]
        conn = ReplayConnection([], 4096)
        with redirect_stdout(io.StringIO()):
            first = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            second = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            for session in (first, first, second):
                for packet in session.handle(1032, 10000, bytes.fromhex(hints[0]["hex"])):
                    conn.sendall(packet)
        self.assertEqual(len(conn.responses), 3)
        for response, hint in zip(conn.responses, (hints[0], hints[1], hints[0])):
            self.assert_recorded_response(response, hint["seq"], 10000)

    def test_session_uses_explicit_save_path_without_entrypoint_patches(self):
        other_path = self.save_path.with_name("other_role.json")
        with redirect_stdout(io.StringIO()):
            first = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            second = Session(self.tables, other_path, self.step_counts, self.role_config)
            self.assertEqual(first.handle(201, 1, b"\x08\x01\x10\x03"),
                             [protocol.pack_frame(201, 1, b"\x08\x01")])
            self.assertEqual(second.handle(200, 2, b""), [protocol.pack_frame(200, 2, b"")])
        self.assertEqual(json.loads(self.save_path.read_text())["guide"]["sections"]["1"]["step"], 3)
        self.assertFalse(other_path.exists())

    def test_ordinary_sequence_hit_must_match_request_payload(self):
        self.assertNotEqual(self.by_seq[28]["hex"], self.by_seq[31]["hex"])
        responses = self.replay([dict(self.by_seq[28], seq=10000), dict(self.by_seq[31], seq=28)])
        self.assert_recorded_response(responses[0], 28, 10000)
        self.assert_recorded_response(responses[1], 31, 28)

    def test_ordinary_parameters_match_without_replaying_other_parameters_first(self):
        responses = self.replay([dict(self.by_seq[31], seq=10000), dict(self.by_seq[28], seq=10001)])
        self.assertEqual(len(responses), 2)
        self.assert_recorded_response(responses[0], 31, 10000)
        self.assert_recorded_response(responses[1], 28, 10001)
        self.assertFalse(self.save_path.exists())

    def test_ordinary_payload_counters_are_independent(self):
        responses = self.replay([self.by_seq[28], self.by_seq[31],
                                 dict(self.by_seq[124], seq=10000), dict(self.by_seq[52], seq=10001)])
        self.assertEqual(len(responses), 4)
        for response, recorded_seq, live_seq in zip(responses, (28, 31, 124, 52), (28, 31, 10000, 10001)):
            self.assert_recorded_response(response, recorded_seq, live_seq)

    def test_unknown_ordinary_payload_returns_error_without_advancing_known_payload(self):
        requests = [dict(self.by_seq[31], seq=10000)]
        requests.extend({"opcode": 1032, "seq": seq, "hex": "08c404"} for seq in (28, 31, 10001))
        requests.append(dict(self.by_seq[52], seq=10002))
        responses = self.replay(requests, chunk_size=7)
        self.assertEqual(len(responses), 8)
        self.assert_recorded_response(responses[0], 31, 10000)
        for i, seq in enumerate((28, 31, 10001)):
            self.assert_unavailable_response(responses[1 + i * 2:3 + i * 2], 1032, seq, "尚未实现")
        self.assert_recorded_response(responses[-1], 52, 10002)
        self.assertFalse(self.save_path.exists())

    def test_unknown_ordinary_mutation_does_not_apply_pushes_or_spend(self):
        self.replay_through(131)
        original = self.save_path.read_bytes()
        self.clock.return_value = self.now + 360
        responses = self.replay([dict(self.by_seq[133], hex="0801")])
        self.assert_unavailable_response(responses, 1057, 133, "尚未实现")
        self.assertEqual(self.save_path.read_bytes(), original)

    def test_ordinary_routes_match_each_recorded_payload_from_a_new_replay(self):
        checked = set()
        for request in self.requests:
            opcode, body = request["opcode"], bytes.fromhex(request["hex"])
            key = opcode, body
            if opcode in (1000, 101, 200, 201, 999900) or key in checked:
                continue
            checked.add(key)
            with self.subTest(opcode=opcode, body=body), redirect_stdout(io.StringIO()):
                actual = replay.Replay(self.tables).match(opcode, 10000, body)
                self.assertEqual(actual, self.tables[3][(request["seq"], opcode, body)][0])

    def test_imported_recordings_are_separated_at_sequence_restart(self):
        self.assertGreaterEqual(len(self.recordings), 2)
        self.assertEqual([f for recording in self.recordings for f in recording], self.all_frames)
        self.assertEqual(len(self.frames), 410)
        self.assertEqual(len(self.requests), 167)
        for recording in self.recordings:
            sequences = [f["seq"] for f in recording if f["c2s"]]
            self.assertEqual(sequences, sorted(set(sequences)))

    def test_mixed_library_does_not_duplicate_login_or_config_acknowledgements(self):
        requests = [self.by_seq[1], self.by_seq[4]]
        responses = self.replay(requests, chunk_size=7)
        self.assertEqual([(f["opcode"], f["seq"]) for f in responses], [(1000, 1), (999907, 4)])
        self.assertFalse(self.save_path.exists())

    def test_reused_sequence_payloads_keep_separate_reply_groups(self):
        request = {"c2s": True, "opcode": 9001, "seq": 1, "hex": "0801"}
        first = {"c2s": False, "opcode": 9001, "seq": 1, "hex": "080a"}
        second = dict(first, hex="0814")
        frames = [request, first, dict(request), second]
        with redirect_stdout(io.StringIO()):
            tables = replay.build_routing_tables(frames)
            routing = replay.Replay(tables)
            self.assertEqual(routing.match(9001, 1, b"\x08\x01"), [first])
            self.assertEqual(routing.match(9001, 1, b"\x08\x01"), [second])
        self.assertEqual(len(tables[3][(1, 9001, b"\x08\x01")]), 2)

    def test_reused_sequence_with_different_payload_is_not_overwritten(self):
        request = {"c2s": True, "opcode": 9001, "seq": 1, "hex": "0801"}
        first = {"c2s": False, "opcode": 9001, "seq": 1, "hex": "080a"}
        other_request = dict(request, hex="0802")
        second = dict(first, hex="0814")
        with redirect_stdout(io.StringIO()):
            tables = replay.build_routing_tables([request, first, other_request, second])
            self.assertEqual(replay.Replay(tables).match(9001, 1, b"\x08\x01"), [first])
            self.assertEqual(replay.Replay(tables).match(9001, 1, b"\x08\x02"), [second])

    def test_cross_request_reply_matching_stops_at_recording_boundary(self):
        first_request = {"c2s": True, "opcode": 9001, "seq": 1, "hex": "0801"}
        later_request = dict(first_request, opcode=9002, seq=2, hex="")
        late_reply = {"c2s": False, "opcode": 9001, "seq": 1, "hex": "080a"}
        next_recording = dict(first_request, hex="0802")
        next_reply = dict(late_reply, hex="0814")
        with redirect_stdout(io.StringIO()):
            tables = replay.build_routing_tables([first_request, later_request, late_reply, next_recording, next_reply])
            self.assertEqual(replay.Replay(tables).match(9001, 10000, b"\x08\x01"), [late_reply])
            tables = replay.build_routing_tables([first_request, later_request, next_recording, next_reply])
            self.assertIsNone(replay.Replay(tables).match(9001, 10000, b"\x08\x01"))

    def test_new_initialization_returns_all_modules_without_completed_account_state(self):
        frames = self.recordings[1]
        request = next(f for f in frames if f["c2s"] and f["opcode"] == 999900
                       and 8110 in protocol.get_comb_ids(bytes.fromhex(f["hex"])))
        recorded = next(f for f in frames if not f["c2s"] and f["opcode"] == 999900 and f["seq"] == request["seq"])
        responses = self.replay([dict(request, seq=30000)])
        self.assertEqual(len(responses), 1)
        self.assertEqual((responses[0]["opcode"], responses[0]["seq"]), (999900, 30000))
        messages = protocol.get_comb_messages(bytes.fromhex(responses[0]["hex"]))
        recorded_messages = protocol.get_comb_messages(bytes.fromhex(recorded["hex"]))
        self.assertEqual([mid for mid, _ in messages], [mid for mid, _ in recorded_messages])
        self.assertEqual({mid: body for mid, body in messages if mid in (8101, 8105, 8109, 8110)},
                         dict.fromkeys((8101, 8105, 8109, 8110), b""))
        role = self.role_data(responses[0])
        self.assertEqual([role[n] for n in (5, 6, 8, 9, 10)], [1, 0, 0, 0, 50])
        baseline_role = self.role_data(self.recorded[(12, 999900)])
        self.assertEqual(role[21], baseline_role[21])
        protagonist = dict(messages)[1054]
        self.assertEqual(protagonist, dict(protocol.get_comb_messages(bytes.fromhex(self.recorded[(12, 999900)]["hex"])))[1054])
        saved = json.loads(self.save_path.read_text())
        self.assertEqual(saved["world_state"]["1002"], self.query_world(1002).hex())
        self.assertNotIn(8927, self.entity_records(self.query_world(1002), 1, 2))

    def test_new_initialization_restores_current_saved_progress(self):
        self.replay(self.requests)
        self.replay([dict(self.by_seq[12], seq=29999)])
        before = json.loads(self.save_path.read_text())
        request = next(f for f in self.recordings[1] if f["c2s"] and f["opcode"] == 999900
                       and 8110 in protocol.get_comb_ids(bytes.fromhex(f["hex"])))
        response = self.replay([dict(request, seq=30000)])[0]
        self.assertEqual([self.role_data(response)[n] for n in (5, 6, 8, 9, 27)], [6, 1000, 123040, 100, 5862])
        self.assertEqual(json.loads(self.save_path.read_text()), before)
        messages = dict(protocol.get_comb_messages(bytes.fromhex(response["hex"])))
        for opcode in player.WORLD_QUERY_IDS:
            self.assertEqual(messages[opcode].hex(), before["world_state"][str(opcode)])

    def test_unrecorded_initialization_parameters_do_not_reuse_generic_template(self):
        self.replay_through(12)
        request = self.by_seq[12]
        raw = bytes.fromhex(request["hex"])
        extra_module = protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 8999) + protocol.encode_pb_field(2, 2, b""))
        fields = list(protocol.iter_pb_fields(raw))
        fields[0] = (1, 2, protocol.pb_set_field(fields[0][2], 2, 2, b"\x08\x01"))
        changed_data = b"".join(protocol.encode_pb_field(*field) for field in fields)
        self.assertEqual(protocol.get_comb_ids(changed_data), protocol.get_comb_ids(raw))
        before = self.save_path.read_bytes()
        self.clock.return_value = self.now + 360
        for body in (raw + extra_module, changed_data, raw + protocol.encode_pb_field(2, 0, 1)):
            with self.subTest(body=body):
                self.assert_unavailable_response(self.replay([dict(request, seq=30000, hex=body.hex())]),
                                                 999900, 30000, "尚未实现")
                self.assertEqual(self.save_path.read_bytes(), before)

    def test_new_account_template_does_not_depend_on_capture_order(self):
        frames = [*self.recordings[1], *self.frames]
        with redirect_stdout(io.StringIO()):
            self.tables = replay.build_routing_tables(frames)
        self.replay([self.by_seq[11], self.by_seq[12]])
        role = self.query_role()
        self.assertEqual([role[n] for n in (5, 8, 9, 10)], [1, 0, 0, 50])

    def test_new_capture_ordinary_requests_match_one_reply_each(self):
        frames = self.recordings[1]
        with redirect_stdout(io.StringIO()):
            for request in frames:
                if not request["c2s"] or request["opcode"] == 999900:
                    continue
                opcode, seq, body = request["opcode"], request["seq"], bytes.fromhex(request["hex"])
                expected = next(f for f in frames if not f["c2s"] and f["opcode"] == opcode and f["seq"] == seq)
                responses = replay.Replay(self.tables).match(opcode, seq, body)
                replies = [f for f in responses if f["seq"] != 0]
                self.assertEqual(len(replies), 1, (opcode, seq))
                self.assertEqual(replies[0]["opcode"], opcode)
                candidates = self.tables[0][(opcode, b"" if opcode == 1000 else body)]
                self.assertIn(responses, candidates)
                self.assertIn([expected], candidates)

    def test_initialization_without_new_account_baseline_is_rejected(self):
        with redirect_stdout(io.StringIO()), self.assertRaisesRegex(ValueError, "一级新号初始化基础"):
            replay.build_routing_tables(self.recordings[1])

    def test_nonempty_unimplemented_initialization_extension_is_rejected(self):
        response = next(f for f in self.recordings[1] if not f["c2s"] and f["opcode"] == 999900 and f["seq"] == 5)
        body = b"".join(protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, mid)
                       + protocol.encode_pb_field(2, 2, b"\x08\x01" if mid == 8110 else data))
                        for mid, data in protocol.get_comb_messages(bytes.fromhex(response["hex"])))
        frames = [dict(f, hex=body.hex()) if f is response else f for f in self.all_frames]
        with redirect_stdout(io.StringIO()), self.assertRaisesRegex(ValueError, "初始化扩展 8110 非空"):
            replay.build_routing_tables(frames)

    def test_initialization_rewrite_preserves_unknown_fields_and_source_frames(self):
        response = next(f for f in self.recordings[1] if not f["c2s"] and f["opcode"] == 999900 and f["seq"] == 5)
        unknown = protocol.encode_pb_field(9, 2, b"keep")
        body = bytes.fromhex(response["hex"]) + unknown
        frames = [dict(f, hex=body.hex()) if f is response else f for f in self.all_frames]
        before = json.dumps(frames)
        request = next(f for f in self.recordings[1] if f["c2s"] and f["opcode"] == 999900 and f["seq"] == 5)
        with redirect_stdout(io.StringIO()):
            tables = replay.build_routing_tables(frames)
            actual = replay.Replay(tables).match(999900, 30000, bytes.fromhex(request["hex"]))
        self.assertEqual(len(actual), 1)
        self.assertTrue(bytes.fromhex(actual[0]["hex"]).endswith(unknown))
        self.assertEqual(json.dumps(frames), before)

    def test_repeated_local_login_uses_bound_account_without_recording(self):
        responses = self.replay([login_request(1, 10000), login_request(1, 10001)])
        self.assertEqual(responses, [{"opcode": 1000, "seq": seq, "hex": "080010001800"}
                                     for seq in (10000, 10001)])
        self.assertFalse(self.save_path.exists())

    def test_city_init_embeds_saved_role_without_stale_initial_role(self):
        snapshot = self.recorded[(41, 1001)]["hex"]
        save = player.get_default_save()
        save["role_snapshot"] = snapshot
        self.save_path.write_text(json.dumps(save))
        responses = self.replay([self.by_seq[12]])
        self.assertEqual(len(responses), 1)
        role = next(data for mid, data in protocol.get_comb_messages(bytes.fromhex(responses[0]["hex"])) if mid == 1001)
        actual = {n: v for n, w, v in protocol.iter_pb_fields(role) if n not in (17, 18)}
        expected = {n: v for n, w, v in protocol.iter_pb_fields(bytes.fromhex(snapshot)) if n not in (17, 18)}
        self.assertEqual(actual, expected)
        self.assertEqual((protocol.pb_get_varint(role, 17), protocol.pb_get_varint(role, 18)), (360, 1080))

    def test_custom_name_reaches_city_init_and_role_query(self):
        name = "本地玩家".encode("utf-8")
        body = b"\x0a" + protocol.encode_varint(len(name)) + name
        responses = self.replay([{"opcode": 101, "seq": 10000, "hex": body.hex()}, self.by_seq[11], self.by_seq[12]])
        self.assertEqual(self.role_data(responses[-1])[3], name)
        responses = self.replay([dict(self.by_seq[41], seq=20000)])
        self.assertEqual(self.role_data(responses[0])[3], name)

    def test_random_names_use_config_for_all_three_profiles(self):
        first = {"name1": "唐", "name2": "尔岚", "name3": "忻云", "name4": "钦豪"}
        second = {"name1": "景", "name2": "初夏", "name3": "函韵", "name4": "善瀚"}
        self.role_config = dict(self.role_config, rollname={"1": first, "2": second})
        requests = [{"opcode": 100, "seq": seq, "hex": protocol.encode_pb_field(1, 0, profile).hex()}
                    for profile in (3, 1, 2) for seq in (9, 10000)]
        with patch("random.choice", side_effect=[first, second, second, first] * 3):
            responses = self.replay(requests, chunk_size=7)
        self.assertEqual([(r["opcode"], r["seq"]) for r in responses], [(100, r["seq"]) for r in requests])
        self.assertEqual([player.parse_set_name(bytes.fromhex(r["hex"])) for r in responses],
                         ["唐善瀚", "景钦豪", "唐初夏", "景尔岚", "唐函韵", "景忻云"])
        self.assertFalse(self.save_path.exists())

    def test_random_name_does_not_rename_or_change_saved_role(self):
        self.replay_through(12)
        original = self.save_path.read_bytes()
        response = self.replay([dict(self.by_seq[9], seq=20000)])[0]
        self.assertTrue(player.parse_set_name(bytes.fromhex(response["hex"])))
        self.assertEqual(self.save_path.read_bytes(), original)

    def test_malformed_random_name_request_does_not_change_save(self):
        self.replay_through(12)
        for body in ("", "08", "0800", "0804", "0a0103", "1003", "08030801", "08031001"):
            with self.subTest(body=body):
                self.assert_rejected({"opcode": 100, "seq": 20000, "hex": body}, "随机名字请求格式错误")

    def test_accepted_selection_persists_actual_requested_id(self):
        self.replay([self.by_seq[11]])
        saved = json.loads(self.save_path.read_text())
        self.assertEqual(saved["selected_general_id"], 3)
        self.assertTrue(saved["has_role"])

    def test_zero_role_values_override_recorded_nonzero_values(self):
        save = player.get_default_save()
        save["role_snapshot"] = self.recorded[(41, 1001)]["hex"]
        save["role_state"] = {"level": 2, "exp": 0, "coin": 0, "gold": 0, "power": 0}
        self.save_path.write_text(json.dumps(save))
        responses = self.replay([self.by_seq[12]])
        values = self.role_data(responses[0])
        self.assertEqual(values[5], 2)
        self.assertEqual([values[n] for n in (6, 8, 9, 14)], [0, 0, 0, 0])

    def test_first_battle_persists_role_progress_without_client_report(self):
        self.replay([self.by_seq[12], self.by_seq[36]])
        saved = json.loads(self.save_path.read_text())
        self.assertEqual(saved["level"], 2)
        self.assertEqual(saved["silver"], 2960)
        self.assertEqual(saved["gold"], 10)
        values = {n: v for n, w, v in protocol.iter_pb_fields(bytes.fromhex(saved["role_snapshot"]))}
        self.assertEqual([values[n] for n in (5, 6, 8, 9, 10)], [2, 0, 2960, 10, 49])

    def test_reconnect_role_queries_cannot_change_progress_by_recording_sequence(self):
        self.replay([self.by_seq[12], self.by_seq[36]])
        responses = self.replay([self.by_seq[111], dict(self.by_seq[63], seq=20000)])
        for response in responses:
            self.assertEqual([self.role_data(response)[n] for n in (5, 8, 9)], [2, 2960, 10])

    def test_strengthen_spending_can_reach_zero_and_survive_reconnect(self):
        save = player.get_default_save()
        save["role_snapshot"] = self.recorded[(90, 1001)]["hex"]
        save["role_state"] = {"level": 4, "exp": 0, "coin": 11200, "gold": 0}
        self.save_path.write_text(json.dumps(save))
        self.replay([self.by_seq[99]])
        saved = json.loads(self.save_path.read_text())
        self.assertEqual(saved["silver"], 0)
        responses = self.replay([dict(self.by_seq[12], seq=20000)])
        self.assertEqual(self.role_data(responses[0])[8], 0)

    def test_unimplemented_training_returns_error_instead_of_empty_success(self):
        self.replay(self.requests)
        before = self.save_path.read_bytes()
        for opcode in (1026, 1028, 1029, 1102, 1105, 1106):
            with self.subTest(opcode=opcode):
                request = self.activity_request(opcode, [7060])
                self.assert_unavailable_response(self.replay([request]), opcode, 20000, "尚未实现")
                self.assertEqual(self.save_path.read_bytes(), before)

    def test_exp_pills_update_general_and_inventory_after_reconnect(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        saved["role_state"]["level"] = 8
        self.save_path.write_text(json.dumps(saved))
        self.give_props({20196: 2, 20197: 1})
        world = self.query_world(1002)
        previous = self.entity_records(world, 1, 2)[7060]
        inventory = self.entity_records(self.query_world(1200), 1, 1)
        body = protocol.encode_pb_field(1, 0, 7060) + b"".join(protocol.encode_pb_field(2, 0, v) for v in (2, 1, 0, 0))
        replies = self.replay([{"opcode": 1038, "seq": 20000, "hex": body.hex()}])
        self.assertEqual(replies[0]["opcode"], 1038)
        updated = self.entity_records(bytes.fromhex(replies[0]["hex"]), 8, 2)[7060]
        self.assertGreater(protocol.pb_get_varint(updated, 3), protocol.pb_get_varint(previous, 3))
        self.assertGreater(protocol.pb_get_varint(updated, 6), protocol.pb_get_varint(previous, 6))
        self.assertEqual(self.entity_records(self.query_world(1002), 1, 2)[7060], updated)
        after_inventory = self.entity_records(self.query_world(1200), 1, 1)
        for cid, count in ((20196, 2), (20197, 1)):
            self.assertEqual(protocol.pb_get_varint(after_inventory.get(cid, b""), 2) or 0,
                             protocol.pb_get_varint(inventory[cid], 2) - count)
        self.assertFalse(any(n == 10 and v for n, w, v in protocol.iter_pb_fields(bytes.fromhex(replies[0]["hex"]))))

    def seed_training_account(self, coin=100000, vip=0):
        self.complete_tutorial()
        saved = json.loads(self.save_path.read_text())
        saved["role_state"].update(level=8, coin=coin, vip=vip)
        saved["activity_state"]["strengthen_count"] = 0
        self.save_path.write_text(json.dumps(saved))
        self.give_props({20196: 20, 20197: 10, 20198: 5, 20199: 2})
        return json.loads(self.save_path.read_text())

    def test_development_magic_crystals_change_only_requested_attribute_and_commit_once(self):
        self.seed_training_account()
        self.give_props({20161: 2000})
        saved = json.loads(self.save_path.read_text())
        old = bytes.fromhex(saved["protagonist_snapshot"])
        iid = protocol.pb_get_varint(old, 1)
        raw = self.entity_records(bytes.fromhex(saved["world_state"]["1002"]), 1, 2)[iid]
        request = self.activity_request(1055, [1, 10])
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            reply = session.handle(1055, 30000, bytes.fromhex(request["hex"]))
            self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in reply], [1055, 205])
            self.assertEqual(session.handle(1055, 30000, bytes.fromhex(request["hex"])), reply)
        changed = self.entity_records(self.query_world(1002), 1, 2)[iid]
        self.assertEqual(protocol.pb_get_varint(changed, 6), protocol.pb_get_varint(raw, 6) + 10)
        self.assertEqual(protocol.pb_get_varint(changed, 7), protocol.pb_get_varint(raw, 7))
        self.assertEqual(protocol.pb_get_varint(bytes.fromhex(json.loads(self.save_path.read_text())["protagonist_snapshot"]), 4), 10)
        inventory = self.entity_records(self.query_world(1200), 1, 1)
        old_props = self.entity_records(bytes.fromhex(saved["world_state"]["1200"]), 1, 1)
        self.assertEqual(protocol.pb_get_varint(inventory[20161], 2), protocol.pb_get_varint(old_props[20161], 2) - 30)
        self.assertEqual(self.query_role()[14], saved["role_state"]["power"] + 10)

    def test_development_protagonist_preview_keeps_inventory_roster_and_counters(self):
        self.seed_training_account()
        self.replay([self.activity_request(1054)])
        before = json.loads(self.save_path.read_text())
        rows = self.entity_records(self.query_world(1056), 1, 4)
        stage = protocol.pb_get_varint(bytes.fromhex(before["protagonist_snapshot"]), 3)
        self.assertEqual(sorted(rows), list(range(stage + 1, 24)))
        self.assertEqual(protocol.pb_get_varint(rows[stage + 1], 1), self.role_config["protagonist_grow"][str(stage + 1)][f"general{before['selected_general_id']}"])
        after = json.loads(self.save_path.read_text())
        for key in ("world_state", "protagonist_snapshot", "role_state", "guide"):
            self.assertEqual(after[key], before[key])

    def test_development_protagonist_advances_current_stage_and_reconnects(self):
        self.seed_training_account()
        self.give_props({20161: 1000})
        for kind, count in ((1, 55), (2, 30), (3, 160)):
            self.replay([self.activity_request(1055, [kind, count])])
        before = json.loads(self.save_path.read_text())
        old = bytes.fromhex(before["protagonist_snapshot"])
        iid = protocol.pb_get_varint(old, 1)
        previous = self.entity_records(bytes.fromhex(before["world_state"]["1002"]), 1, 2)[iid]
        preview = self.entity_records(self.query_world(1056), 1, 4)[3]
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            packets = session.handle(1057, 30002, b"\x08\x00")
            self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in packets], [1057, 205])
            self.assertEqual(session.handle(1057, 30002, b"\x08\x00"), packets)
            self.assertEqual(json.loads(self.save_path.read_text()), session.save)
        body = packets[0][16:]
        changed = self.entity_records(body, 1, 2)[iid]
        snapshot = next(v for n, w, v in protocol.iter_pb_fields(body) if (n, w) == (6, 2))
        self.assertEqual(changed, preview)
        self.assertEqual([protocol.pb_get_varint(snapshot, n) for n in (3, 4, 5, 6)], [3, 0, 0, 0])
        self.assertEqual(next(v for n, w, v in protocol.iter_pb_fields(snapshot) if (n, w) == (10, 2)), changed)
        for field, delta in ((6, 490), (7, 272), (8, 1406), (9, 0)):
            self.assertEqual(protocol.pb_get_varint(changed, field), protocol.pb_get_varint(previous, field) + delta)
        for field in (2, 3, 5, 17):
            self.assertEqual(protocol.pb_get_varint(changed, field), protocol.pb_get_varint(previous, field))
        after = json.loads(self.save_path.read_text())
        self.assertEqual(after["role_state"]["coin"], before["role_state"]["coin"] - 50000)
        self.assertEqual(after["world_state"]["1200"], before["world_state"]["1200"])
        self.assertEqual(after["guide"], before["guide"])
        self.assertEqual(self.query_world(1054), snapshot)
        self.assertEqual(self.entity_records(self.query_world(1002), 1, 2)[iid], changed)
        initial = self.replay([dict(self.by_seq[12], seq=30003)])[0]
        self.assertEqual(self.entity_records(dict(protocol.get_comb_messages(bytes.fromhex(initial["hex"])))[1002], 1, 2)[iid], changed)
        disk = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([self.activity_request(1057, [0])]), 1057, 20000, "培养")
        self.assertEqual(self.save_path.read_bytes(), disk)

    def test_development_protagonist_advance_rejects_invalid_state_and_is_atomic(self):
        self.seed_training_account()
        self.give_props({20161: 1000})
        for kind, count in ((1, 55), (2, 30), (3, 160)):
            self.replay([self.activity_request(1055, [kind, count])])
        ready = json.loads(self.save_path.read_text())
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            memory, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
            for body in (b"", b"\x08\x01", b"\x08\x00\x08\x00", b"\x10\x00", b"\x08\x00\x18\x00", b"\x08\x80"):
                packets = session.handle(1057, 30004, body)
                self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in packets], [999999, 1999])
                self.assertEqual((session.save, self.save_path.read_bytes()), (memory, disk))
        for problem in ("training", "coin", "stage", "advanced", "shape", "attribute_overflow", "power_overflow"):
            saved = copy.deepcopy(ready)
            snapshot = bytes.fromhex(saved["protagonist_snapshot"])
            raw = self.entity_records(bytes.fromhex(saved["world_state"]["1002"]), 1, 2)[protocol.pb_get_varint(snapshot, 1)]
            if problem == "training":
                snapshot = protocol.pb_set_varint(snapshot, 4, 54)
            elif problem == "coin":
                saved["role_state"]["coin"] = 49999
            elif problem == "stage":
                snapshot = protocol.pb_set_varint(snapshot, 3, 23)
            elif problem == "advanced":
                raw = protocol.pb_set_varint(raw, 23, 1)
            elif problem == "shape":
                raw = protocol.pb_set_varint(raw, 1, 10111)
            elif problem == "attribute_overflow":
                raw = protocol.pb_set_varint(raw, 6, (1 << 31) - 1)
            else:
                saved["role_state"]["power_all"] = (1 << 31) - 1
            saved["protagonist_snapshot"] = protocol.pb_set_field(snapshot, 10, 2, raw).hex()
            player.record_slot_update(saved, protocol.encode_pb_field(1, 2, raw))
            self.save_path.write_text(json.dumps(saved))
            with self.subTest(problem=problem), redirect_stdout(io.StringIO()):
                session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
                memory, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
                self.assertEqual(struct.unpack(">IIII", session.handle(1057, 30005, b"\x08\x00")[0][:16])[2], 999999)
                self.assertEqual((session.save, self.save_path.read_bytes()), (memory, disk))
                self.assertEqual(struct.unpack(">IIII", session.handle(1054, 30006, b"")[0][:16])[2], 1054)
        self.save_path.write_text(json.dumps(ready))
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            memory, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
            with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
                session.handle(1057, 30007, b"\x08\x00")
            self.assertEqual((session.save, self.save_path.read_bytes(), session.random_replies), (memory, disk, {}))

    def test_development_protagonist_advance_changes_shape_and_preserves_fashion(self):
        saved = self.seed_training_account(coin=2000000)
        saved["role_state"]["gold"] = 10000
        self.save_path.write_text(json.dumps(saved))
        self.give_props({20161: 10000})
        self.replay([self.activity_request(1074, [80001]), self.activity_request(1073, [80001])])
        for target in (3, 4, 5):
            row = self.role_config["protagonist_grow"][str(target)]
            for kind, name in ((1, "atk"), (2, "def"), (3, "hp")):
                self.replay([self.activity_request(1055, [kind, row[name]])])
            if target < 5:
                self.assertEqual(self.replay([self.activity_request(1057, [0])])[0]["opcode"], 1057)
        disk = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([self.activity_request(1057, [0])]), 1057, 20000, "20167")
        self.assertEqual(self.save_path.read_bytes(), disk)
        self.give_props({20167: 10})
        before = json.loads(self.save_path.read_text())
        preview = self.entity_records(self.query_world(1056), 1, 4)[5]
        packets = self.replay([self.activity_request(1057, [0])])
        self.assertEqual(packets[0]["opcode"], 1057)
        after = json.loads(self.save_path.read_text())
        snapshot = bytes.fromhex(after["protagonist_snapshot"])
        iid = protocol.pb_get_varint(snapshot, 1)
        changed = self.entity_records(bytes.fromhex(after["world_state"]["1002"]), 1, 2)[iid]
        self.assertEqual(protocol.pb_get_varint(changed, 1), 10128)
        self.assertEqual(protocol.pb_set_varint(changed, 1, 10113), preview)
        self.assertEqual(after["fashion_state"], before["fashion_state"])
        self.assertEqual(protocol.pb_get_varint(snapshot, 7), 2)
        self.assertEqual(after["role_state"]["profile"], 10128)
        self.assertEqual(after["role_state"]["coin"], before["role_state"]["coin"] - 500000)
        self.assertEqual(protocol.pb_get_varint(self.entity_records(self.query_world(1200), 1, 1).get(20167, b""), 2) or 0, 0)
        slot = self.entity_records(bytes.fromhex(after["world_state"]["1002"]), 4, 2)[iid]
        old_slot = self.entity_records(bytes.fromhex(before["world_state"]["1002"]), 4, 2)[iid]
        self.assertEqual([v for n, w, v in protocol.iter_pb_fields(slot) if n != 3],
                         [v for n, w, v in protocol.iter_pb_fields(old_slot) if n != 3])
        self.replay([self.activity_request(1071)])
        hidden = self.entity_records(self.query_world(1002), 1, 2)[iid]
        self.assertEqual(hidden, protocol.pb_set_varint(changed, 1, 10113))
        self.replay([self.activity_request(1071)])
        self.assertEqual(self.entity_records(self.query_world(1002), 1, 2)[iid], changed)

    def test_development_protagonist_growth_matches_recorded_first_advance(self):
        self.replay_through(132)
        saved = json.loads(self.save_path.read_text())
        # 官方1055刚增加的1点培养在Protagonist里，不能用更早的世界快照作基线。
        raw = next(v for n, w, v in protocol.iter_pb_fields(bytes.fromhex(saved["protagonist_snapshot"])) if (n, w) == (10, 2))
        player.record_slot_update(saved, protocol.encode_pb_field(1, 2, raw))
        body, costs, update = development.prepare(1057, saved, b"\x08\x00", self.role_config)
        self.assertEqual(costs, [(1000, 10000)])
        self.assertEqual(body, update)
        actual = self.entity_records(body, 1, 2)[7059]
        expected = self.entity_records(bytes.fromhex(self.recorded[(133, 1057)]["hex"]), 1, 2)[7059]
        for field in range(1, 20):
            self.assertEqual(protocol.pb_get_varint(actual, field), protocol.pb_get_varint(expected, field), field)

    def test_development_protagonist_all_ordinary_stages_and_choices_preserve_unknown_fields(self):
        baseline = self.seed_training_account(coin=2000000000)
        unknown = protocol.encode_pb_field(50, 2, b"keep")
        for choice in (1, 2, 3):
            saved = copy.deepcopy(baseline)
            saved["selected_general_id"] = choice
            snapshot = bytes.fromhex(saved["protagonist_snapshot"]) + unknown
            iid = protocol.pb_get_varint(snapshot, 1)
            raw = self.entity_records(bytes.fromhex(saved["world_state"]["1002"]), 1, 2)[iid] + unknown
            raw = protocol.pb_set_varint(raw, 1, self.role_config["protagonist_grow"]["2"][f"general{choice}"])
            for cid in (20167, 20286):
                player.change_item_count(saved, cid, 100000, self.role_config, self.now)
            for target in range(3, 24):
                with self.subTest(choice=choice, target=target):
                    row = self.role_config["protagonist_grow"][str(target)]
                    raw, _ = development.adjust(raw, {field: row[name] for field, name in ((6, "atk"), (7, "def"), (8, "hp"))})
                    for field, name in ((4, "atk"), (5, "def"), (6, "hp")):
                        snapshot = protocol.pb_set_varint(snapshot, field, row[name])
                    saved["protagonist_snapshot"] = protocol.pb_set_field(snapshot, 10, 2, raw).hex()
                    player.record_slot_update(saved, protocol.encode_pb_field(1, 2, raw))
                    preview, _, _ = development.prepare(1056, copy.deepcopy(saved), b"", self.role_config)
                    expected = self.entity_records(preview, 1, 4)[target]
                    reply = player.prepare_recorded_response(1057, b"", saved, b"\x08\x00", self.step_counts, self.role_config, self.now)
                    changed = self.entity_records(reply, 1, 2)[iid]
                    self.assertEqual(changed, expected)
                    self.assertEqual(protocol.pb_get_varint(changed, 1), row[f"general{choice}"])
                    self.assertTrue(changed.endswith(unknown))
                    snapshot = bytes.fromhex(saved["protagonist_snapshot"])
                    self.assertEqual([protocol.pb_get_varint(snapshot, n) for n in (3, 4, 5, 6)], [target, 0, 0, 0])
                    self.assertIn((50, 2, b"keep"), list(protocol.iter_pb_fields(snapshot)))
                    raw = changed
            with self.assertRaisesRegex(ValueError, "高级进阶"):
                development.prepare(1057, saved, b"\x08\x00", self.role_config)

    def seed_break_account(self):
        saved = self.seed_training_account()
        saved["role_state"]["level"] = 9
        raw = recruit.new_general(10404, 2000001, self.role_config)
        raw, _, _ = training.grow_general(raw, 1000, b"", set(), {}, self.role_config)
        player.record_slot_update(saved, protocol.encode_pb_field(1, 2, raw))
        player.change_item_count(saved, 20017, 100, self.role_config)
        self.save_path.write_text(json.dumps(saved))
        self.replay([self.change_general_request(2, 2000001)])
        return json.loads(self.save_path.read_text())

    def test_development_partner_preview_and_native_guide_comb_commit_together(self):
        saved = self.seed_break_account()
        preview = self.query_world_for_values(1023, [2000001])
        general = self.entity_records(preview, 1, 2)[2000001]
        self.assertEqual(protocol.pb_get_varint(general, 4), 1)
        request = protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 1017) + protocol.encode_pb_field(2, 2, b"\x08\xa4\x51\x08\x00"))
        # CID10404来自当前账号，201的字段顺序与官方一致。
        request += protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 201) + protocol.encode_pb_field(2, 2, b"\x10\x04\x08\x05"))
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            packets = session.handle(999900, 30001, request)
            self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in packets], [999900, 205])
            self.assertEqual(session.handle(999900, 30001, request), packets)
        after = json.loads(self.save_path.read_text())
        self.assertEqual(after["guide"]["sections"]["5"]["step"], 4)
        self.assertEqual(self.entity_records(bytes.fromhex(after["world_state"]["1002"]), 1, 2)[2000001], general)
        self.assertEqual(after["role_state"]["coin"], saved["role_state"]["coin"] - 10000)
        old_props = self.entity_records(bytes.fromhex(saved["world_state"]["1200"]), 1, 1)
        new_props = self.entity_records(bytes.fromhex(after["world_state"]["1200"]), 1, 1)
        self.assertEqual(protocol.pb_get_varint(new_props[20017], 2), protocol.pb_get_varint(old_props[20017], 2) - 10)
        self.assertEqual(self.replay([self.activity_request(1017, [10404, 0])])[0]["opcode"], 999999)

    def query_world_for_values(self, opcode, values):
        reply = self.replay([self.activity_request(opcode, values)])[0]
        self.assertEqual(reply["opcode"], opcode)
        return bytes.fromhex(reply["hex"])

    def test_development_breakthrough_delta_matches_official_leigong(self):
        frames = json.loads((Path(server.BASE_DIR) / "official_battle_capture_20261028_2210.json").read_text())["connections"][0]["frames"]
        saved = {"world_state": {"1002": ""}, "has_role": True, "role_state": {"level": 9, "power": 0, "power_all": 0}}
        for frame in frames:
            messages = protocol.get_comb_messages(bytes.fromhex(frame["hex"])) if frame["opcode"] == 999900 else [(frame["opcode"], bytes.fromhex(frame["hex"]))]
            if frame["c2s"] and any(mid == 1017 for mid, _ in messages):
                break
            if frame["c2s"]:
                continue
            for mid, body in messages:
                if mid == 1002:
                    saved["world_state"]["1002"] = body.hex()
                elif mid in (1024, 1027, 1057):
                    player.record_slot_update(saved, body)
                elif mid in (1306, 1038):
                    for n, w, raw in protocol.iter_pb_fields(body):
                        if w == 2 and n == (6 if mid == 1306 else 8):
                            player.record_slot_update(saved, protocol.encode_pb_field(1, 2, raw))
        iid = next(i for i, raw in self.entity_records(bytes.fromhex(saved["world_state"]["1002"]), 1, 2).items() if protocol.pb_get_varint(raw, 1) == 10213)
        reply, _, _ = development.prepare(1023, saved, protocol.encode_pb_field(1, 0, iid), self.role_config)
        raw = self.entity_records(reply, 1, 2)[iid]
        self.assertEqual([protocol.pb_get_varint(raw, n) for n in (6, 7, 8, 9)], [1290, 508, 2959, 114])

    def test_development_self_stat_passives_are_added_on_breakthrough_and_preview(self):
        for cid, level, target, field, bonus in ((10595, 20, 2, 6, 1000), (10596, 30, 3, 6, None),
                                                  (10213, 30, 3, 10, 10)):
            with self.subTest(cid=cid):
                config = copy.deepcopy(self.role_config)
                if cid == 10213:
                    config["general"][str(cid)].update(break1=0, break2=0)
                    config["general"][str(cid)]["break3"] = 9000112
                row = config["general"][str(cid)]
                raw = recruit.new_general(cid, 2000001, config)
                raw = protocol.pb_set_varint(protocol.pb_set_varint(raw, 3, level), 4, target - 1)
                for name, number in (("atk", 6), ("def", 7), ("hp", 8), ("speed", 9)):
                    raw = protocol.pb_set_varint(raw, number, int(battle.general_base(row, name, level, target - 1, config)))
                saved = {"has_role": True, "role_state": {"level": 23},
                         "world_state": {"1002": protocol.encode_pb_field(1, 2, raw).hex()}}
                original = copy.deepcopy(saved)
                preview, _, update = development.prepare(1023, saved, protocol.encode_pb_field(1, 0, 2000001), config)
                self.assertEqual((saved, update), (original, b""))
                reply, _, update = development.prepare(1017, saved, protocol.encode_pb_field(1, 0, cid), config)
                self.assertEqual(reply, preview)
                changed = self.entity_records(update, 1, 2)[2000001]
                expected = int(battle.general_base(row, "atk", level, target, config)) if field == 6 else row["critical"]
                expected += int(battle.general_base(row, "atk", level, target, config) * 15 / 100) if bonus is None else bonus
                self.assertEqual(protocol.pb_get_varint(changed, field), expected)
                actor = {name: protocol.pb_get_varint(changed, number) or 0 for name, number in battle.GENERAL_FIELDS.items()}
                actor["skill"] = row["skillid"]
                teams = {True: {2: actor}, False: {2: self.combat_unit(10213)}}
                battle._prepare_teams(teams, config)
                self.assertEqual(teams[True][2]["atk" if field == 6 else "critical"], expected)

    def test_self_stat_percentage_growth_preserves_training_and_batch_rounding(self):
        row = self.role_config["general"]["10596"]
        raw = recruit.new_general(10596, 2000001, self.role_config)
        raw = protocol.pb_set_varint(protocol.pb_set_varint(raw, 3, 30), 4, 3)
        for name, field in (("atk", 6), ("def", 7), ("hp", 8), ("speed", 9)):
            value = int(battle.general_base(row, name, 30, 3, self.role_config))
            raw = protocol.pb_set_varint(raw, field, value + (value * 15 // 100 if field == 6 else 0) + 37)
        quality = row["quality"]
        gains = [self.role_config["general_exp"][str(level)][f"{quality}exp"] for level in range(30, 34)]
        batch, _, _ = training.grow_general(raw, sum(gains), b"", set(), {}, self.role_config)
        split = raw
        for gain in gains:
            split, _, _ = training.grow_general(split, gain, b"", set(), {}, self.role_config)
        self.assertEqual(batch, split)
        base = int(battle.general_base(row, "atk", 34, 3, self.role_config))
        self.assertEqual(protocol.pb_get_varint(batch, 6), base + base * 15 // 100 + 37)

    def test_self_stats_use_rate_points_and_ignore_combat_only_passives(self):
        config = copy.deepcopy(self.role_config)
        row = dict(config["general"]["10213"])
        ids = (9000139, 9000094, 9000112, 9000112, 9000009, 9000014, 9000024)
        row.update({f"break{i}": pid for i, pid in enumerate(ids, 1)})
        values = battle.self_stats(row, 30, len(ids), config)
        self.assertEqual(values[6], 200)
        self.assertEqual(values[7], int(int(battle.general_base(row, "def", 30, len(ids), config)) * Fraction(1, 10)))
        self.assertEqual(values[10], 10)
        self.assertEqual(sum(values[field] for field in values if field not in (6, 7, 10)), 0)
        config["breakskill"]["9000139"]["method"] = "unknown"
        with self.assertRaisesRegex(ValueError, "配置"):
            battle.self_stats(row, 30, len(ids), config)

    def seed_legacy_self_stat_account(self):
        saved = self.seed_training_account(coin=2000000000)
        saved["role_state"].update(level=23, gold=100000)
        for cid, iid, advance in ((10595, 2000001, 2), (10596, 2000002, 3)):
            row = self.role_config["general"][str(cid)]
            raw = recruit.new_general(cid, iid, self.role_config)
            raw = protocol.pb_set_varint(protocol.pb_set_varint(raw, 3, 30), 4, advance)
            for name, field in (("atk", 6), ("def", 7), ("hp", 8), ("speed", 9)):
                raw = protocol.pb_set_varint(raw, field, int(battle.general_base(row, name, 30, advance, self.role_config)))
            raw += protocol.encode_pb_field(50, 2, b"keep-self-stat")
            player.record_slot_update(saved, protocol.encode_pb_field(1, 2, raw))
        update = formation.change(saved, 1003, protocol.encode_pb_field(1, 0, 2) + protocol.encode_pb_field(3, 0, 2000001), self.role_config)
        player.record_slot_update(saved, update)
        saved.pop("self_stats_version", None)
        self.save_path.write_text(json.dumps(saved))
        return saved

    def test_legacy_self_stats_migrate_once_commit_before_push_and_preserve_progress(self):
        before = self.seed_legacy_self_stat_account()
        old = self.entity_records(bytes.fromhex(before["world_state"]["1002"]), 1, 2)
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            packets = session.handle(1002, 31000, b"")
            self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in packets], [1002, 1027, 205])
            self.assertEqual(json.loads(self.save_path.read_text()), session.save)
            changed = self.entity_records(packets[0][16:], 1, 2)
            self.assertEqual(changed, self.entity_records(packets[1][16:], 1, 2))
            self.assertEqual(protocol.pb_get_varint(changed[2000001], 6), protocol.pb_get_varint(old[2000001], 6) + 1000)
            extra = int(battle.general_base(self.role_config["general"]["10596"], "atk", 30, 3, self.role_config)) * 15 // 100
            self.assertEqual(protocol.pb_get_varint(changed[2000002], 6), protocol.pb_get_varint(old[2000002], 6) + extra)
            for iid in (2000001, 2000002):
                self.assertIn((50, 2, b"keep-self-stat"), list(protocol.iter_pb_fields(changed[iid])))
            after = copy.deepcopy(session.save)
            self.assertEqual(after["self_stats_version"], 1)
            self.assertEqual(after["role_state"]["power"], before["role_state"]["power"] + 1000)
            self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in session.handle(1002, 31001, b"")], [1002])
            again = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in again.handle(1002, 31002, b"")], [1002])
        for key in ("guide", "last_battle"):
            self.assertEqual(after.get(key), before.get(key))
        for key in ("1200", "1012", "1107", "1300"):
            self.assertEqual(after["world_state"][key], before["world_state"][key])
        for key in ("coin", "gold", "level", "exp", "energy"):
            self.assertEqual(after["role_state"][key], before["role_state"][key])
        self.assertEqual(again.save["world_state"]["1002"], after["world_state"]["1002"])

    def test_legacy_self_stats_failures_do_not_leak_migration_or_charge(self):
        before = self.seed_legacy_self_stat_account()
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            memory, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
            self.assertEqual(struct.unpack(">IIII", session.handle(1017, 31003, b"\x08\x00")[0][:16])[2], 999999)
            self.assertEqual((session.save, self.save_path.read_bytes()), (memory, disk))
            with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
                session.handle(1002, 31004, b"")
            self.assertEqual((session.save, self.save_path.read_bytes()), (memory, disk))
        for problem in ("overflow", "version"):
            saved = copy.deepcopy(before)
            if problem == "overflow":
                raw = self.entity_records(bytes.fromhex(saved["world_state"]["1002"]), 1, 2)[2000001]
                player.record_slot_update(saved, protocol.encode_pb_field(1, 2, protocol.pb_set_varint(raw, 6, (1 << 31) - 500)))
            else:
                saved["self_stats_version"] = "1"
            self.save_path.write_text(json.dumps(saved))
            with self.subTest(problem=problem), redirect_stdout(io.StringIO()):
                session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
                memory, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
                self.assertEqual(struct.unpack(">IIII", session.handle(1002, 31005, b"")[0][:16])[2], 999999)
                self.assertEqual((session.save, self.save_path.read_bytes()), (memory, disk))

    def test_legacy_self_stats_keep_receipted_rebirth_and_skip_recorded_iids(self):
        saved = self.seed_legacy_self_stat_account()
        raw = self.entity_records(bytes.fromhex(saved["world_state"]["1002"]), 1, 2)[2000002]
        baseline = recruit.new_general(10596, 2000002, self.role_config)
        saved["qiankun_state"]["receipts"]["general:2000002"] = {"before": baseline.hex(), "after": raw.hex(), "costs": [[20017, 10]]}
        recorded = protocol.pb_set_varint(raw, 2, 1500)
        player.record_slot_update(saved, protocol.encode_pb_field(1, 2, recorded))
        self.save_path.write_text(json.dumps(saved))
        with redirect_stdout(io.StringIO()):
            Session(self.tables, self.save_path, self.step_counts, self.role_config).handle(1002, 31006, b"")
        after = json.loads(self.save_path.read_text())
        generals = self.entity_records(bytes.fromhex(after["world_state"]["1002"]), 1, 2)
        self.assertEqual(generals[1500], recorded)
        receipt = after["qiankun_state"]["receipts"]["general:2000002"]
        self.assertEqual(receipt, {"before": baseline.hex(), "after": generals[2000002].hex(), "costs": [[20017, 10]]})
        reward, _, _ = qiankun.prepare(1035, after, protocol.encode_pb_field(1, 0, 2000002), self.role_config)
        self.assertEqual(self.entity_records(reward, 8, 2)[2000002], baseline)

    def test_migrated_self_stats_survive_formation_changes_and_queries_stay_read_only(self):
        from zyj_server.admin import views
        saved = self.seed_legacy_self_stat_account()
        original = copy.deepcopy(saved)
        snapshot = {"id": 1, "save": saved, "error": None}
        views.detail(snapshot, self.step_counts, self.role_config)
        self.assertEqual(saved, original)
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            session.handle(1002, 31007, b"")
            before = copy.deepcopy(session.save)
            for seq, iid in ((31008, 2000002), (31009, 2000001)):
                body = protocol.encode_pb_field(1, 0, 2) + protocol.encode_pb_field(3, 0, iid)
                self.assertEqual(struct.unpack(">IIII", session.handle(1003, seq, body)[0][:16])[2], 1003)
            for iid, raw in self.entity_records(bytes.fromhex(before["world_state"]["1002"]), 1, 2).items():
                changed = self.entity_records(bytes.fromhex(session.save["world_state"]["1002"]), 1, 2)[iid]
                self.assertEqual(changed, raw)
            self.assertEqual(session.save["role_state"], before["role_state"])

    def test_legacy_self_stats_are_settled_before_live_battle_and_cached_once(self):
        before = self.seed_legacy_self_stat_account()
        raw = self.entity_records(bytes.fromhex(before["world_state"]["1002"]), 1, 2)[2000001]
        body = protocol.encode_pb_field(1, 0, 42102) + protocol.encode_pb_field(1, 0, 1)
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            with patch.object(battle, "simulate", wraps=battle.simulate) as simulate:
                packets = session.handle(1306, 31010, body)
            self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 1306)
            attack = simulate.call_args.args[0]
            queen = next(unit for unit in attack.values() if unit["iid"] == 2000001)
            self.assertEqual(queen["atk"], protocol.pb_get_varint(raw, 6) + 1000)
            self.assertIn(1027, [struct.unpack(">IIII", packet[:16])[2] for packet in packets])
            memory, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
            self.assertEqual(session.handle(1306, 31010, body), packets)
            self.assertEqual((session.save, self.save_path.read_bytes()), (memory, disk))

    def test_legacy_self_stats_initialization_rewrites_role_and_roster_atomically(self):
        before = self.seed_legacy_self_stat_account()
        request = bytes.fromhex(self.by_seq[12]["hex"])
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            memory, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
            with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
                session.handle(999900, 31011, request)
            self.assertEqual((session.save, self.save_path.read_bytes()), (memory, disk))
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            packets = session.handle(999900, 31012, request)
        initial = dict(protocol.get_comb_messages(packets[0][16:]))
        world = bytes.fromhex(session.save["world_state"]["1002"])
        self.assertEqual(initial[1002], world)
        self.assertEqual(protocol.pb_get_varint(initial[1001], 14), before["role_state"]["power"] + 1000)
        self.assertEqual(protocol.parse_ids_pb(next(packet[16:] for packet in packets if struct.unpack(">IIII", packet[:16])[2] == 205))[1],
                         session.save["role_state"]["power"])
        self.assertEqual(json.loads(self.save_path.read_text()), session.save)

    def test_development_rejects_bad_parameters_and_save_failures_without_cost(self):
        self.seed_break_account()
        self.give_props({20161: 100})
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            original = self.save_path.read_bytes()
            memory = copy.deepcopy(session.save)
            for opcode, values in ((1023, [99999]), (1017, [10404, 1]), (1055, [0, 1]), (1055, [1, 0]),
                                   (1055, [1, 1001]), (1055, [1, 56]), (1056, [1])):
                reply = session.handle(opcode, 30000, bytes.fromhex(self.activity_request(opcode, values)["hex"]))
                self.assertEqual(struct.unpack(">IIII", reply[0][:16])[2], 999999)
                self.assertEqual((session.save, self.save_path.read_bytes()), (memory, original))
            for opcode, values in ((1017, [10404, 0]), (1055, [1, 10])):
                with patch.object(player.os, "replace", side_effect=OSError("disk full")):
                    with self.assertRaises(OSError):
                        session.handle(opcode, 30001, bytes.fromhex(self.activity_request(opcode, values)["hex"]))
                self.assertEqual((session.save, self.save_path.read_bytes()), (memory, original))

    def training_request(self, opcode, iid, values):
        body = protocol.encode_pb_field(1, 0, iid) + b"".join(protocol.encode_pb_field(2, 0, v) for v in values)
        return {"opcode": opcode, "seq": 20000, "hex": body.hex()}

    def test_exp_growth_matches_official_1038_attributes_and_potential(self):
        frames = json.loads((Path(server.BASE_DIR) / "official_battle_capture_20261028_2210.json").read_text())["connections"][0]["frames"]
        saved = {"world_state": {"1002": ""}, "has_role": True, "role_state": {"level": 8}}
        for frame in frames:
            if frame["c2s"]:
                if frame["opcode"] == 1038:
                    request = frame
                    break
                continue
            body = bytes.fromhex(frame["hex"])
            messages = protocol.get_comb_messages(body) if frame["opcode"] == 999900 else [(frame["opcode"], body)]
            for opcode, body in messages:
                if opcode in (1002, 1024, 1027):
                    player.record_slot_update(saved, body)
                elif opcode in (1306, 1017):
                    for raw in self.entity_records(body, 6 if opcode == 1306 else 1, 2).values():
                        player.record_slot_update(saved, protocol.encode_pb_field(1, 2, raw))
        expected = next(f for f in frames if not f["c2s"] and f["opcode"] == 1038 and f["seq"] == request["seq"])
        before = copy.deepcopy(saved)
        body, costs, _ = training.use_exp(saved, bytes.fromhex(request["hex"]), self.role_config)
        self.assertEqual(saved, before)
        self.assertEqual(costs, [(20196, 2), (20197, 1)])
        actual = self.entity_records(body, 8, 2)[7060]
        recorded = self.entity_records(bytes.fromhex(expected["hex"]), 8, 2)[7060]
        for field in (3, 5, 6, 7, 8, 9, 17):
            self.assertEqual(protocol.pb_get_varint(actual, field), protocol.pb_get_varint(recorded, field), field)

    def test_exp_cap_preserves_last_pill_overflow_and_rejects_more(self):
        saved = self.seed_training_account()
        raw = recruit.new_general(10213, 2000001, self.role_config)
        raw = protocol.pb_set_varint(protocol.pb_set_varint(raw, 3, 15), 5, 1199)
        player.record_slot_update(saved, protocol.encode_pb_field(1, 2, raw))
        self.save_path.write_text(json.dumps(saved))
        before_power = saved["role_state"]["power"]
        request = self.training_request(1038, 2000001, (0, 0, 0, 1))
        reply = self.replay([request])[0]
        raw = self.entity_records(bytes.fromhex(reply["hex"]), 8, 2)[2000001]
        self.assertEqual(protocol.pb_get_varint(raw, 3), 16)
        self.assertEqual(protocol.pb_get_varint(raw, 5), 1199 + 20000 - self.role_config["general_exp"]["15"]["4exp"])
        self.assertEqual(json.loads(self.save_path.read_text())["role_state"]["power"], before_power)
        before = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([request]), 1038, 20000, "上限")
        self.assertEqual(self.save_path.read_bytes(), before)

    def test_growth_batching_keeps_attributes_potential_and_power_identical(self):
        raw = recruit.new_general(10213, 2000001, self.role_config)
        combined, _, _ = training.grow_general(raw, 5000, b"", set(), {}, self.role_config)
        for _ in range(50):
            raw, _, _ = training.grow_general(raw, 100, b"", set(), {}, self.role_config)
        self.assertEqual(raw, combined)

    def test_exp_upgraded_relation_survives_removal_and_level_cap_survives_battle(self):
        saved = self.seed_training_account()
        raw = recruit.new_general(10213, 2000001, self.role_config)
        player.record_slot_update(saved, protocol.encode_pb_field(1, 2, raw))
        self.save_path.write_text(json.dumps(saved))
        self.replay([self.change_general_request(2, 2000001)])
        replies = self.replay([self.training_request(1038, 2000001, (0, 1, 0, 0))])
        self.assertEqual(replies[0]["opcode"], 1038)
        self.replay([self.change_general_request(2, 7060)])
        raw = self.entity_records(self.query_world(1002), 1, 2)[2000001]
        level = protocol.pb_get_varint(raw, 3)
        self.assertEqual(protocol.pb_get_varint(raw, 6), 420 + 42 * (level - 1))
        self.assertEqual(protocol.pb_get_varint(raw, 17), 30 + 80 * (level - 1))
        self.replay([self.change_general_request(2, 2000001)])
        self.replay([self.training_request(1038, 2000001, (0, 0, 0, 1))])
        raw = self.entity_records(self.query_world(1002), 1, 2)[2000001]
        self.assertEqual(protocol.pb_get_varint(raw, 3), 16)
        with patch.object(player.random, "getrandbits", return_value=42):
            result = self.replay([self.activity_request(1306, [42102, 2])])[0]
        self.assertEqual(result["opcode"], 1306)
        self.assertEqual(protocol.pb_get_varint(bytes.fromhex(result["hex"]), 1), 1)
        after = self.entity_records(self.query_world(1002), 1, 2)[2000001]
        self.assertEqual(protocol.pb_get_varint(after, 3), 16)
        self.assertGreater(protocol.pb_get_varint(after, 5), protocol.pb_get_varint(raw, 5))

    def seed_treasure_training(self, kind="treasure", level=8):
        saved = self.seed_training_account(coin=1000000)
        saved["role_state"]["level"] = level
        target_cid, food_cid = (26201, 26302) if kind == "treasure" else (25203, 25305)
        for iid, cid in ((1000100, target_cid), (1000101, food_cid), (1000102, food_cid)):
            raw = recharge.ids([iid, cid, 1] + [0] * 10)
            player.record_slot_update(saved, protocol.encode_pb_field(2, 2, raw))
        self.save_path.write_text(json.dumps(saved))
        self.give_props({cid: 10 for cid in range(26407, 26415)})
        gear = [1, 1, 0, 0, 0, 0, 1000100 if kind == "treasure" else 0, 1000100 if kind == "horse" else 0]
        self.assertEqual(self.replay([self.activity_request(1007, gear)])[0]["opcode"], 1007)
        return json.loads(self.save_path.read_text())

    def treasure_feed_request(self, target, foods, seq=32000):
        body = protocol.encode_pb_field(1, 0, target)
        body += b"".join(protocol.encode_pb_field(2, 0, iid) for iid in foods)
        return {"opcode": 1118, "seq": seq, "hex": body.hex()}

    def test_treasure_training_props_save_once_and_restore_equipment_exp(self):
        before = self.seed_treasure_training()
        previous = self.entity_records(bytes.fromhex(before["world_state"]["1002"]), 1, 2)[7059]
        request = self.activity_request(1210, [1000100, 26410, 1])
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            packets = session.handle(1210, 32000, bytes.fromhex(request["hex"]))
            self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in packets], [1210, 205])
            self.assertEqual(session.handle(1210, 32000, bytes.fromhex(request["hex"])), packets)
            self.assertEqual(json.loads(self.save_path.read_text()), session.save)
        fields = list(protocol.iter_pb_fields(packets[0][16:]))
        self.assertFalse(any(n in (1, 2, 10) for n, w, v in fields))
        changed = self.entity_records(packets[0][16:], 6, 1)[1000100]
        self.assertEqual(protocol.parse_ids_pb(changed), [1000100, 26201, 4, 0, 100] + [0] * 8)
        after = json.loads(self.save_path.read_text())
        self.assertEqual(after["role_state"]["coin"], before["role_state"]["coin"] - 3000)
        props = self.entity_records(self.query_world(1200), 1, 1)
        self.assertEqual(protocol.pb_get_varint(props[26410], 2), 9)
        general = self.entity_records(self.query_world(1002), 1, 2)[7059]
        self.assertEqual(protocol.pb_get_varint(general, 8), protocol.pb_get_varint(previous, 8) + 480)
        self.assertEqual(protocol.pb_get_varint(general, 6), protocol.pb_get_varint(previous, 6))
        self.assertEqual(after["role_state"]["power"], before["role_state"]["power"] + 48)
        self.assertEqual(after["guide"], before["guide"])
        snapshot = bytes.fromhex(after["protagonist_snapshot"])
        self.assertEqual(next(v for n, w, v in protocol.iter_pb_fields(snapshot) if (n, w) == (10, 2)), general)
        initial = self.replay([dict(self.by_seq[12], seq=32001)])[0]
        roster = dict(protocol.get_comb_messages(bytes.fromhex(initial["hex"])))[1002]
        self.assertEqual(self.entity_records(roster, 2, 1)[1000100], changed)

    def test_treasure_training_consumes_only_selected_idle_items_and_reconnects(self):
        before = self.seed_treasure_training()
        request = self.treasure_feed_request(1000100, [1000101, 1000102])
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            packets = session.handle(1118, 32002, bytes.fromhex(request["hex"]))
            self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 1118)
            self.assertEqual(session.handle(1118, 32002, bytes.fromhex(request["hex"])), packets)
        food = self.role_config["equip"]["26302"]
        after = json.loads(self.save_path.read_text())
        self.assertEqual(after["role_state"]["coin"], before["role_state"]["coin"] - 2 * int(self.role_config["global_kv"][f'treasure_strengthen_coin{food["quality"]}']["value"]))
        equips = self.entity_records(self.query_world(1002), 2, 1)
        old_equips = self.entity_records(bytes.fromhex(before["world_state"]["1002"]), 2, 1)
        self.assertEqual(set(equips), set(old_equips) - {1000101, 1000102})
        self.assertEqual(protocol.parse_ids_pb(equips[1000100])[2:5], [4, 0, 100])
        self.assertEqual(after["world_state"]["1200"], before["world_state"]["1200"])
        self.assertFalse(any(n in (1, 2, 10) for n, w, v in protocol.iter_pb_fields(packets[0][16:])))
        disk = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([request]), 1118, 32000, "不存在")
        self.assertEqual(self.save_path.read_bytes(), disk)
        initial = self.replay([dict(self.by_seq[12], seq=32003)])[0]
        roster = dict(protocol.get_comb_messages(bytes.fromhex(initial["hex"])))[1002]
        self.assertFalse({1000101, 1000102} & set(self.entity_records(roster, 2, 1)))

    def test_treasure_training_horse_and_unworn_targets_keep_power_accurate(self):
        before = self.seed_treasure_training("horse")
        previous = self.entity_records(bytes.fromhex(before["world_state"]["1002"]), 1, 2)[7059]
        reply = self.replay([self.activity_request(1210, [1000100, 26407, 1])])
        self.assertEqual(reply[0]["opcode"], 1210)
        current = self.entity_records(self.query_world(1002), 1, 2)[7059]
        gain = int(self.role_config["equip"]["25203"]["grow_1"]) * 3
        self.assertEqual(protocol.pb_get_varint(current, 6), protocol.pb_get_varint(previous, 6) + gain)
        self.assertEqual(protocol.pb_get_varint(current, 8), protocol.pb_get_varint(previous, 8))
        self.assertEqual(json.loads(self.save_path.read_text())["role_state"]["power"], before["role_state"]["power"] + gain)
        power = self.query_role()[14]
        reply = self.replay([self.activity_request(1210, [1000101, 26407, 1])])
        self.assertEqual([f["opcode"] for f in reply], [1210])
        self.assertFalse(any(n == 8 for n, w, v in protocol.iter_pb_fields(bytes.fromhex(reply[0]["hex"]))))
        self.assertEqual(self.query_role()[14], power)

    def test_treasure_training_exp_survives_other_training_and_round_trip_equipping(self):
        self.seed_treasure_training()
        self.replay([self.activity_request(1210, [1000100, 26410, 1])])
        before = self.entity_records(self.query_world(1002), 1, 2)[7059]
        self.replay([self.activity_request(1007, [1, 1, 0, 0, 0, 0, 1000101, 0])])
        self.replay([self.activity_request(1007, [1, 1, 0, 0, 0, 0, 1000100, 0])])
        self.assertEqual(self.entity_records(self.query_world(1002), 1, 2)[7059], before)
        self.assertEqual(self.replay([self.training_request(1038, 7059, (1, 0, 0, 0))])[0]["opcode"], 1038)
        world = self.query_world(1002)
        weapon = protocol.pb_get_varint(self.entity_records(world, 4, 1)[1], 4)
        self.assertEqual(self.replay([self.training_request(1101, weapon, (0,))])[0]["opcode"], 1101)
        self.assertEqual(protocol.parse_ids_pb(self.entity_records(self.query_world(1002), 2, 1)[1000100])[2:5], [4, 0, 100])

    def test_treasure_training_retains_last_material_overflow_but_rejects_excess(self):
        self.seed_treasure_training(level=2)
        disk = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([self.activity_request(1210, [1000100, 26410, 2])]), 1210, 20000, "超过")
        self.assertEqual(self.save_path.read_bytes(), disk)
        self.assertEqual(self.replay([self.activity_request(1210, [1000100, 26410, 1])])[0]["opcode"], 1210)
        self.assertEqual(protocol.parse_ids_pb(self.entity_records(self.query_world(1002), 2, 1)[1000100])[2:5], [2, 0, 800])
        disk = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([self.activity_request(1210, [1000100, 26410, 1])]), 1210, 20000, "上限")
        self.assertEqual(self.save_path.read_bytes(), disk)
        saved = json.loads(self.save_path.read_text())
        saved["role_state"]["level"] = 3
        self.save_path.write_text(json.dumps(saved))
        self.assertEqual(self.replay([self.activity_request(1210, [1000100, 26410, 1])])[0]["opcode"], 1210)
        self.assertEqual(protocol.parse_ids_pb(self.entity_records(self.query_world(1002), 2, 1)[1000100])[2:5], [3, 0, 1500])

    def test_treasure_training_mixed_props_charge_each_quality_and_keep_overflow(self):
        before = self.seed_treasure_training()
        request = self.activity_request(1210, [1000100, 26410, 1, 26411, 1, 26412, 1])
        self.assertEqual(self.replay([request])[0]["opcode"], 1210)
        after = json.loads(self.save_path.read_text())
        self.assertEqual(after["role_state"]["coin"], before["role_state"]["coin"] - 33000)
        self.assertEqual(protocol.parse_ids_pb(self.entity_records(self.query_world(1002), 2, 1)[1000100])[2:5], [8, 0, 2000])
        props = self.entity_records(self.query_world(1200), 1, 1)
        for cid in (26410, 26411, 26412):
            self.assertEqual(protocol.pb_get_varint(props[cid], 2), 9)

    def test_treasure_training_rejects_malformed_requests_without_mutation(self):
        self.seed_treasure_training()
        requests = [self.activity_request(1210, values) for values in
                    ([], [1000100], [1000100, 26410], [1000100, 26410, 0], [1000100, 26407, 1],
                     [1000100, 20196, 1], [1000100, 26410, 1, 26410, 1], [9999999, 26410, 1],
                     [1000100, 26410, 11], [1000100, 26410, (1 << 31)])]
        requests += [self.treasure_feed_request(1000100, foods) for foods in
                     ([], [1000100], [1000101, 1000101], [9999999], list(range(1, 7)))]
        requests += [{"opcode": 1118, "seq": 32000, "hex": "0894b43d0894b43d1095b43d"},
                     {"opcode": 1118, "seq": 32000, "hex": "0894b43d1095b43d1801"},
                     {"opcode": 1210, "seq": 32000, "hex": "0894b43d08aace0108011801"},
                     {"opcode": 1210, "seq": 32000, "hex": "0880"}]
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            memory, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
            for request in requests:
                with self.subTest(request=request):
                    packets = session.handle(request["opcode"], request["seq"], bytes.fromhex(request["hex"]))
                    self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in packets], [999999, 1999])
                    self.assertEqual((session.save, self.save_path.read_bytes()), (memory, disk))

    def test_treasure_training_protects_worn_advanced_and_foreign_materials(self):
        baseline = self.seed_treasure_training()
        for problem in ("worn", "cheer", "target_cheer", "refined_food", "starred_target",
                        "wrong_type", "coin", "props", "power", "experience"):
            saved = copy.deepcopy(baseline)
            equips = self.entity_records(bytes.fromhex(saved["world_state"]["1002"]), 2, 1)
            foods = [1000101]
            if problem == "worn":
                slot = protocol.encode_pb_field(1, 0, 2) + protocol.encode_pb_field(2, 0, 7060) + protocol.encode_pb_field(8, 0, 1000101)
                player.record_slot_update(saved, protocol.encode_pb_field(4, 2, slot))
            elif problem in ("cheer", "target_cheer"):
                slot = (protocol.encode_pb_field(1, 0, 1) + protocol.encode_pb_field(2, 0, 0)
                        + protocol.encode_pb_field(8, 0, 1000100 if problem == "target_cheer" else 1000101))
                player.record_slot_update(saved, protocol.encode_pb_field(5, 2, slot))
            elif problem in ("refined_food", "starred_target", "wrong_type", "experience"):
                iid = 1000101 if problem in ("refined_food", "wrong_type") else 1000100
                item = protocol.parse_ids_pb(equips[iid])
                item[{"refined_food": 3, "starred_target": 11, "wrong_type": 1, "experience": 4}[problem]] = (
                    25203 if problem == "wrong_type" else (1 << 31) - 1 if problem == "experience" else 1)
                player.record_slot_update(saved, protocol.encode_pb_field(2, 2, recharge.ids(item)))
            elif problem == "coin":
                saved["role_state"]["coin"] = 0
            elif problem == "props":
                player.change_item_count(saved, 26410, -10, self.role_config, self.now)
            else:
                saved["role_state"]["power_all"] = (1 << 31) - 1
            self.save_path.write_text(json.dumps(saved))
            disk = self.save_path.read_bytes()
            with self.subTest(problem=problem):
                request = self.activity_request(1210, [1000100, 26410, 1]) if problem == "props" else self.treasure_feed_request(1000100, foods)
                self.assertEqual(self.replay([request])[0]["opcode"], 999999)
                self.assertEqual(self.save_path.read_bytes(), disk)

    def test_treasure_training_food_exp_matches_native_preview_and_invalidates_receipts(self):
        saved = self.seed_treasure_training()
        raw = recharge.ids([1000101, 26302, 2, 0, 30] + [0] * 8)
        player.record_slot_update(saved, protocol.encode_pb_field(2, 2, raw))
        saved["qiankun_state"]["receipts"]["equip:1000101"] = {"before": "", "after": raw.hex(), "costs": [[1000, 10000]]}
        self.save_path.write_text(json.dumps(saved))
        self.assertEqual(self.replay([self.treasure_feed_request(1000100, [1000101])])[0]["opcode"], 1118)
        equips = self.entity_records(self.query_world(1002), 2, 1)
        # 紫书500基础经验+升到2级的400经验，与客户端setexp_up预览一致。
        self.assertEqual(protocol.parse_ids_pb(equips[1000100])[2:5], [4, 0, 0])
        self.assertNotIn("equip:1000101", json.loads(self.save_path.read_text())["qiankun_state"]["receipts"])
        self.assertIn(1000102, equips)

    def test_treasure_training_save_failure_keeps_materials_currency_and_memory(self):
        self.seed_treasure_training()
        for request in (self.treasure_feed_request(1000100, [1000101]), self.activity_request(1210, [1000100, 26410, 1])):
            with self.subTest(opcode=request["opcode"]), redirect_stdout(io.StringIO()):
                session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
                memory, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
                with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
                    session.handle(request["opcode"], 32004, bytes.fromhex(request["hex"]))
                self.assertEqual((session.save, self.save_path.read_bytes(), session.random_replies), (memory, disk, {}))

    def test_treasure_training_all_configured_plain_targets_and_unknown_fields(self):
        unknown = protocol.encode_pb_field(50, 2, b"keep")
        for cid, row in self.role_config["equip"].items():
            if row["type"] not in training.TREASURE_PROPS or not row["adorn"]:
                continue
            for prop in training.TREASURE_PROPS[row["type"]]:
                with self.subTest(cid=cid, prop=prop):
                    raw = recharge.ids([1000100, int(cid), 1, 0, 0]) + unknown
                    saved = {"has_role": True, "role_state": {"level": 150},
                             "world_state": {"1002": protocol.encode_pb_field(2, 2, raw).hex()}}
                    reply, costs, power = training.strengthen_treasure(saved, 1210, recharge.ids([1000100, prop, 1]), self.role_config)
                    changed = self.entity_records(reply, 6, 1)[1000100]
                    self.assertIn((50, 2, b"keep"), list(protocol.iter_pb_fields(changed)))
                    values = protocol.parse_ids_pb(changed)
                    total = values[4] + sum(self.role_config["treasure2_strengthen"][str(lv)][f'quality{row["quality"]}'] for lv in range(2, values[2] + 1))
                    self.assertEqual(total, self.role_config["equip"][str(prop)]["exp"])
                    quality = self.role_config["equip"][str(prop)]["quality"]
                    coin = int(self.role_config["global_kv"][f"treasure_strengthen_coin{quality}"]["value"])
                    self.assertEqual((costs, power), ([(1000, coin), (prop, 1)], 0))

    def test_strengthening_charges_once_updates_protagonist_and_reconnects(self):
        saved = self.seed_training_account(coin=560)
        raw = self.entity_records(bytes.fromhex(saved["world_state"]["1002"]), 1, 2)[7059]
        request = self.training_request(1101, 10726, (0,))
        responses = self.replay([request, request], chunk_size=7)
        self.assertEqual(responses[:2], responses[2:])
        self.assertEqual([r["opcode"] for r in responses[:2]], [1101, 205])
        body = bytes.fromhex(responses[0]["hex"])
        self.assertEqual(protocol.pb_get_varint(body, 1), (1 << 64) - 560)
        after = json.loads(self.save_path.read_text())
        self.assertEqual(after["role_state"]["coin"], 0)
        world = self.query_world(1002)
        changed = self.entity_records(world, 1, 2)[7059]
        self.assertEqual(protocol.parse_ids_pb(self.entity_records(world, 2, 1)[10726])[2], 9)
        self.assertEqual(protocol.pb_get_varint(changed, 6), protocol.pb_get_varint(raw, 6) + 20)
        self.assertEqual(after["role_state"]["power"], saved["role_state"]["power"] + 20)
        protagonist = bytes.fromhex(after["protagonist_snapshot"])
        self.assertEqual(next(v for n, w, v in protocol.iter_pb_fields(protagonist) if n == 10), changed)
        self.assertEqual(after["activity_state"]["strengthen_count"], 1)
        self.assertEqual(self.query_role()[8], 0)

    def test_strengthen_five_levels_and_quick_all_follow_costs_and_limits(self):
        saved = self.seed_training_account()
        request = self.training_request(1101, 10726, (1,))
        replies = self.replay([request])
        self.assertEqual(replies[0]["opcode"], 1101)
        after = json.loads(self.save_path.read_text())
        self.assertEqual(saved["role_state"]["coin"] - after["role_state"]["coin"], 560 + 640 + 680 + 720 + 760)
        self.assertEqual(protocol.parse_ids_pb(self.entity_records(self.query_world(1002), 2, 1)[10726])[2], 13)
        old_items = self.entity_records(self.query_world(1002), 2, 1)
        cost = 0
        for iid in (10720, 10721, 10723, 10726):
            item = protocol.parse_ids_pb(old_items[iid])
            cost += sum(self.role_config["equip_strengthen"][str(lv)]["quality2"] for lv in range(item[2], 16))
        response = self.replay([self.activity_request(1109, [7059])])
        self.assertEqual(response[0]["opcode"], 1109)
        final = json.loads(self.save_path.read_text())
        self.assertEqual(after["role_state"]["coin"] - final["role_state"]["coin"], cost)
        items = self.entity_records(self.query_world(1002), 2, 1)
        for iid in (10720, 10721, 10723, 10726):
            self.assertEqual(protocol.parse_ids_pb(items[iid])[2], 16)
        self.assertEqual(final["activity_state"]["strengthen_count"], self.role_config["liveness"]["16"]["num"])
        self.assertTrue(any(f["opcode"] == 1034 and self.hint_changes(f).get(40) == 1 for f in replies))

    def test_strengthening_vip_critical_is_charged_per_attempt(self):
        self.seed_training_account(coin=560, vip=3)
        with patch.object(player.random, "getrandbits", return_value=0):
            replies = self.replay([self.training_request(1101, 10726, (0,))])
        body = bytes.fromhex(replies[0]["hex"])
        self.assertEqual(protocol.parse_ids_pb(self.entity_records(body, 6, 1)[10726])[2], 10)
        self.assertEqual(protocol.pb_get_varint(body, 1), (1 << 64) - 560)
        self.assertEqual(protocol.parse_ids_pb(next(v for n, w, v in protocol.iter_pb_fields(body) if n == 12)), [1])
        self.assertEqual(json.loads(self.save_path.read_text())["activity_state"]["strengthen_count"], 1)

    def test_old_tutorial_strengthening_cannot_overwrite_live_progress(self):
        self.seed_training_account()
        self.replay([self.training_request(1101, 10726, (1,))])
        before = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([self.by_seq[99]]), 999900, 99, "已过期")
        self.assertEqual(self.save_path.read_bytes(), before)

    def test_recording_without_own_reply_cannot_apply_pushes(self):
        self.seed_training_account()
        before = self.save_path.read_bytes()
        pushes = [f for f in self.expected_group(99) if f["seq"] == 0]
        with patch.object(replay.Replay, "match", return_value=pushes):
            self.assert_unavailable_response(self.replay([self.activity_request(1028, [1, 7060])]), 1028, 20000, "缺少完整应答")
        self.assertEqual(self.save_path.read_bytes(), before)

    def test_training_invalid_insufficient_and_save_failure_leave_no_partial_state(self):
        saved = self.seed_training_account(coin=1)
        good_exp = self.training_request(1038, 7060, (2, 1, 0, 0))
        invalid = [self.training_request(1038, 7060, (0, 0, 0, 0)),
                   self.training_request(1038, 7060, (1, 1, 1)),
                   self.training_request(1038, 999999, (1, 0, 0, 0)),
                   self.training_request(1038, 7060, (0, 0, 0, 100)),
                   self.training_request(1101, 10726, (0,)),
                   self.training_request(1101, 10726, (2,)),
                   self.training_request(1101, 10726, (0, 0)),
                   self.training_request(1101, 999999, (0,)),
                   self.activity_request(1109, [7059, 7059]), self.activity_request(1109, [999999])]
        invalid += [dict(good_exp, hex=good_exp["hex"] + suffix) for suffix in ("18", "1801", "089437")]
        inventory = self.entity_records(bytes.fromhex(saved["world_state"]["1200"]), 1, 1)
        for cid in training.EXP_PROPS:
            player.change_item_count(saved, cid, -(protocol.pb_get_varint(inventory.get(cid, b""), 2) or 0), self.role_config)
        # A valid first deduction followed by a missing second item must roll back too.
        player.change_item_count(saved, 20196, 2, self.role_config)
        self.save_path.write_text(json.dumps(saved))
        invalid.append(good_exp)
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            memory, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
            for request in invalid:
                with self.subTest(request=request):
                    packet = session.handle(request["opcode"], request["seq"], bytes.fromhex(request["hex"]))[0]
                    self.assertEqual(struct.unpack(">IIII", packet[:16])[2], 999999)
                    self.assertEqual(session.save, memory)
                    self.assertEqual(self.save_path.read_bytes(), disk)
            request = self.training_request(1038, 7060, (2, 0, 0, 0))
            with patch.object(player.os, "replace", side_effect=OSError("disk full")):
                with self.assertRaises(OSError):
                    session.handle(1038, 20001, bytes.fromhex(request["hex"]))
            self.assertEqual(session.save, memory)
            self.assertEqual(self.save_path.read_bytes(), disk)

    def test_all_recorded_role_rewards_and_costs_are_persisted(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        self.assertEqual([saved[k] for k in ("level", "silver", "gold")], [6, 123040, 100])
        self.assertEqual(saved["role_state"]["exp"], 1000)
        self.assertEqual(saved["role_state"]["power_all"], 5862)

    def test_insufficient_funds_do_not_change_save_or_emit_success(self):
        save = player.get_default_save()
        save["role_state"] = {"level": 4, "exp": 0, "coin": 1, "gold": 0}
        original = json.dumps(save)
        self.save_path.write_text(original)
        conn = ReplayConnection([self.by_seq[99]], 4096)
        with redirect_stdout(io.StringIO()):
            self.run_client(conn)
        self.assertTrue(conn.closed)
        self.assertEqual(conn.responses, [])
        self.assertEqual(self.save_path.read_text(), original)

    def test_failed_save_keeps_original_and_emits_no_success(self):
        save = player.get_default_save()
        save["role_state"] = {"level": 4, "exp": 0, "coin": 11200, "gold": 0}
        original = json.dumps(save)
        self.save_path.write_text(original)
        conn = ReplayConnection([self.by_seq[99]], 4096)
        with redirect_stdout(io.StringIO()), patch.object(player.os, "replace", side_effect=OSError("disk failure")):
            self.run_client(conn)
        self.assertTrue(conn.closed)
        self.assertEqual(conn.responses, [])
        self.assertEqual(self.save_path.read_text(), original)
        self.assertEqual(sorted(p.name for p in self.save_path.parent.iterdir() if not p.name.startswith('._')), ["accounts", "role_save.json"])

    def test_entire_recorded_group_is_saved_before_first_push(self):
        conn = ReplayConnection([self.by_seq[36]], 7)
        sendall = conn.sendall

        def check_saved_before_send(packet):
            if struct.unpack(">I", packet[8:12])[0] == 1000:
                return sendall(packet)
            saved = json.loads(self.save_path.read_text())
            self.assertEqual((saved["level"], saved["silver"], saved["gold"]), (2, 2960, 10))
            self.assertEqual(saved["guide"]["sections"]["1"]["step"], 8)
            sendall(packet)

        conn.sendall = check_saved_before_send
        with redirect_stdout(io.StringIO()):
            self.run_client(conn)
        self.assertTrue(conn.closed)
        self.assertEqual(conn.responses, self.expected_group(36))

    def test_live_updates_do_not_acknowledge_failed_saves(self):
        original = json.dumps(player.get_default_save())
        self.save_path.write_text(original)
        for opcode, body in ((101, "0a046e616d65"), (201, "08011003"), (999898, "08010800080008000800")):
            with self.subTest(opcode=opcode):
                conn = ReplayConnection([{"opcode": opcode, "seq": 10000, "hex": body}], 7)
                with redirect_stdout(io.StringIO()), patch.object(player.os, "replace", side_effect=OSError("disk failure")):
                    self.run_client(conn)
                self.assertTrue(conn.closed)
                self.assertEqual(conn.responses, [])
                self.assertEqual(self.save_path.read_text(), original)

    def test_corrupt_save_is_not_silently_replaced(self):
        original = '{"unfinished":'
        self.save_path.write_text(original)
        self.assert_rejected(self.by_seq[12], "存档读取失败")
        self.assertEqual(self.save_path.read_text(), original)

    def test_malformed_name_does_not_change_existing_save(self):
        save = player.get_default_save()
        save["role_name"] = "已保存的名字"
        original = json.dumps(save)
        self.save_path.write_text(original)
        conn = ReplayConnection([{"opcode": 101, "seq": 10000, "hex": "0a05e69cac"}], 7)
        with redirect_stdout(io.StringIO()):
            self.run_client(conn)
        self.assertEqual(conn.responses, [])
        self.assertEqual(self.save_path.read_text(), original)

    def test_legacy_client_report_preserves_extended_fields_and_zero_balances(self):
        self.replay([self.by_seq[12], self.by_seq[36]])
        values = (2, 0, 0, 0, 0)
        body = b"".join(b"\x08" + protocol.encode_varint(value) for value in values)
        self.replay([{"opcode": 999898, "seq": 10000, "hex": body.hex()}])
        saved = json.loads(self.save_path.read_text())
        self.assertEqual([saved["role_state"][k] for k in ("coin", "gold", "power", "power_all", "stamina")], [0, 0, 0, 0, 49])

    def test_legacy_client_lower_experience_does_not_change_save(self):
        self.replay([self.by_seq[12], self.by_seq[36]])
        original = self.save_path.read_text()
        body = b"".join(b"\x08" + protocol.encode_varint(value) for value in (1, 0, 100, 10, 20))
        responses = self.replay([{"opcode": 999898, "seq": 10000, "hex": body.hex()}])
        self.assertEqual(responses, [{"opcode": 999898, "seq": 10000, "hex": "0801"}])
        self.assertEqual(self.save_path.read_text(), original)

    def test_field_replacement_preserves_unknown_fields_and_zero(self):
        raw = b"\x08\x05\x1a\x03old" + protocol.encode_pb_field(50, 5, b"1234")
        updated = protocol.pb_set_field(raw, 3, 2, "新名字".encode("utf-8"))
        updated = protocol.pb_set_varint(updated, 1, 0)
        self.assertEqual(list(protocol.iter_pb_fields(updated)), [(1, 0, 0), (3, 2, "新名字".encode("utf-8")), (50, 5, b"1234")])

    def test_protagonist_growth_is_not_general_level2(self):
        self.replay([self.by_seq[11], self.by_seq[12], self.by_seq[36]])
        saved = json.loads(self.save_path.read_text())
        values = {n: v for n, w, v in protocol.iter_pb_fields(bytes.fromhex(saved["protagonist_snapshot"]))}
        general = {n: v for n, w, v in protocol.iter_pb_fields(values[10])}
        self.assertEqual((values[3], general[4]), (1, 0))

    def test_recruit_and_slot_updates_survive_reconnect_and_init(self):
        self.replay_through(55)
        request = dict(self.by_seq[56], seq=44, hex="0a0a08eb07120518943708020a0908c901120410130801")
        self.assertEqual(self.replay([request], chunk_size=7), self.expected_group(56, 44))
        self.assertEqual(json.loads(self.save_path.read_text())["guide"]["sections"]["1"]["step"], 19)
        roster = self.query_world(1002)
        generals = self.entity_records(roster, 1, 2)
        slots = self.entity_records(roster, 4, 1)
        self.assertTrue({7059, 7060}.issubset(generals))
        self.assertEqual(protocol.pb_get_varint(slots[2], 2), 7060)
        responses = self.replay([dict(self.by_seq[12], seq=30000)])
        restored = dict(protocol.get_comb_messages(bytes.fromhex(responses[0]["hex"])))[1002]
        self.assertEqual(restored, roster)

    def test_unrecorded_slot_parameters_remain_non_mutating(self):
        self.replay_through(55)
        before = self.save_path.read_bytes()
        body = bytes.fromhex(self.by_seq[56]["hex"])
        for data in (b"\x18\x94\x37\x08\x03", b"\x18\x95\x37\x08\x02",
                     b"\x18\x94\x37\x08\x02\x10\x00", b"\x18\x94\x37\x08\x02\x08\x02"):
            changed = b"".join(protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, mid)
                              + protocol.encode_pb_field(2, 2, data if mid == 1003 else payload))
                               for mid, payload in protocol.get_comb_messages(body))
            with self.subTest(data=data.hex()):
                self.assert_unavailable_response(self.replay([dict(self.by_seq[56], hex=changed.hex())]),
                                                 999900, 56, "尚未实现")
                self.assertEqual(self.save_path.read_bytes(), before)

    def test_equipment_updates_merge_without_deleting_old_equipment(self):
        self.replay_through(99)
        roster = self.query_world(1002)
        equips = self.entity_records(roster, 2, 1)
        self.assertTrue({10719, 10720, 10721}.issubset(equips))
        reward = dict(protocol.get_comb_messages(bytes.fromhex(self.recorded[(99, 999900)]["hex"])))[1109]
        updated = [v for n, w, v in protocol.iter_pb_fields(reward) if n == 6 and w == 2]
        self.assertTrue(updated)
        for equip in updated:
            self.assertEqual(equips[protocol.pb_get_varint(equip, 1)], equip)

    def test_recruit_token_is_spent_and_starter_gift_is_preserved(self):
        self.replay_through(76)
        props = self.entity_records(self.query_world(1200), 1, 1)
        self.assertEqual(protocol.pb_get_varint(props[20111], 2), 1)
        self.assertNotIn(20100, props)

    def test_gift_rewards_consumption_and_training_cost_survive_reconnect(self):
        self.replay_through(148)
        props = self.entity_records(self.query_world(1200), 1, 1)
        self.assertNotIn(20111, props)
        self.assertEqual(protocol.pb_get_varint(props[20100], 2), 5)
        self.assertEqual(protocol.pb_get_varint(props[20161], 2), 47)
        fragments = self.entity_records(self.query_world(1012), 1, 1)
        self.assertEqual(protocol.pb_get_varint(fragments[10204], 2), 20)

    def test_resource_props_use_configured_delta_and_persist_batch_consumption(self):
        for cid, field, initial, delta in ((20014, 3, 0, 25), (20019, 3, 0, 50),
                                           (20015, 4, 20, 10), (20020, 4, 20, 20)):
            with self.subTest(cid=cid):
                self.seed_stamina(0)
                self.give_props({cid: 3})
                response = self.replay([self.activity_request(1201, (cid, 2))])[0]
                fields = list(protocol.iter_pb_fields(bytes.fromhex(response["hex"])))
                self.assertEqual(fields, [(field, 0, 2 * delta), (5, 2, b""), (7, 2, b""), (10, 2, b"")])
                role = self.query_role()
                self.assertEqual(role[{3: 10, 4: 12}[field]], initial + 2 * delta)
                props = self.entity_records(self.query_world(1200), 1, 1)
                self.assertEqual(protocol.pb_get_varint(props[cid], 2), 1)
                init = self.replay([dict(self.by_seq[12], seq=30000)])[0]
                self.assertEqual(self.role_data(init)[{3: 10, 4: 12}[field]], initial + 2 * delta)

    def test_claimed_daily_stamina_prop_is_usable_at_recorded_gift_sequence(self):
        self.replay(self.requests)
        self.replay([self.activity_request(3611, (80001,))])
        before = json.loads(self.save_path.read_text())["role_state"]
        request = dict(self.activity_request(1201, (20014, 1)), seq=148)
        response = self.replay([request])[0]
        self.assertEqual((response["opcode"], response["seq"]), (1201, 148))
        self.assertEqual(protocol.pb_get_varint(bytes.fromhex(response["hex"]), 3), 25)
        self.assertNotIn(20014, self.entity_records(self.query_world(1200), 1, 1))
        after = json.loads(self.save_path.read_text())["role_state"]
        self.assertEqual(after, {**before, "stamina": before["stamina"] + 25})
        self.assert_rejected(request, "道具 20014 数量不足")

    def test_resource_prop_reward_survives_later_tutorial_recordings(self):
        self.replay(self.requests)
        baseline = json.loads(self.save_path.read_text())["role_state"]
        self.save_path.unlink()
        self.replay_through(12)
        self.replay([self.activity_request(3611, (80001,)), self.activity_request(1201, (20014, 1))])
        self.replay([f for f in self.requests if f["seq"] > 12])
        saved = json.loads(self.save_path.read_text())["role_state"]
        self.assertEqual(saved, {**baseline, "coin": baseline["coin"] + 20000,
                                "gold": baseline["gold"] + 100, "stamina": baseline["stamina"] + 25})

    def test_resource_prop_use_settles_recovery_and_preserves_partial_interval(self):
        for elapsed, amount, remaining in ((100, 25, 260), (360, 26, 360)):
            with self.subTest(elapsed=elapsed):
                self.clock.return_value = self.now
                self.seed_stamina(0)
                self.give_props({20014: 1})
                self.query_role()
                self.clock.return_value = self.now + elapsed
                self.replay([self.activity_request(1201, (20014, 1))])
                role = self.query_role()
                self.assertEqual((role[10], role[17]), (amount, remaining))

    def test_resource_prop_can_exceed_soft_cap_and_stops_recovery(self):
        self.seed_stamina(49)
        self.give_props({20014: 1})
        self.query_role()
        self.clock.return_value = self.now + 100
        self.replay([self.activity_request(1201, (20014, 1))])
        self.clock.return_value = self.now + 100 * 360
        role = self.query_role()
        self.assertEqual((role[10], role[17], role[18]), (74, 0, 0))

    def test_resource_prop_consumes_once_per_request_in_same_session(self):
        self.seed_stamina(0)
        self.give_props({20015: 3})
        conn = ReplayConnection([self.activity_request(1201, (20015, 1)),
                                 self.activity_request(1201, (20015, 2))], 7)
        with redirect_stdout(io.StringIO()):
            self.run_client(conn)
        self.assertTrue(conn.closed)
        self.assertEqual([protocol.pb_get_varint(bytes.fromhex(f["hex"]), 4) for f in conn.responses], [10, 20])
        self.assertEqual(self.query_role()[12], 50)
        self.assertNotIn(20015, self.entity_records(self.query_world(1200), 1, 1))

    def test_resource_prop_batch_allows_client_limit_of_100(self):
        self.seed_stamina(0)
        self.give_props({20020: 101})
        self.replay([self.activity_request(1201, (20020, 100))])
        self.assertEqual(self.query_role()[12], 2020)
        self.assert_rejected(self.activity_request(1201, (20020, 101)), "恢复道具使用参数无效")

    def test_resource_prop_insufficient_quantity_does_not_partially_consume(self):
        self.seed_stamina(0)
        self.give_props({20014: 1})
        self.assert_rejected(self.activity_request(1201, (20014, 2)), "道具 20014 数量不足")

    def test_resource_prop_integer_overflow_keeps_inventory_and_role(self):
        for cid, name in ((20014, "stamina"), (20020, "energy")):
            with self.subTest(cid=cid):
                self.seed_stamina(0)
                self.give_props({cid: 1})
                saved = json.loads(self.save_path.read_text())
                saved["role_state"][name] = (1 << 31) - 10
                self.save_path.write_text(json.dumps(saved))
                self.assert_rejected(self.activity_request(1201, (cid, 1)), "恢复资源超出范围")

    def test_resource_prop_save_failure_is_atomic_with_due_recovery(self):
        self.seed_stamina(0)
        self.give_props({20014: 1})
        self.query_role()
        self.clock.return_value = self.now + 360
        with patch.object(player.os, "replace", side_effect=OSError("disk failure")):
            self.assert_rejected(self.activity_request(1201, (20014, 1)), "保存失败")
        self.assertEqual(self.query_role()[10], 1)
        self.assertEqual(protocol.pb_get_varint(self.entity_records(self.query_world(1200), 1, 1)[20014], 2), 1)

    def test_malformed_resource_prop_use_does_not_change_save(self):
        self.seed_stamina(0)
        self.give_props({20014: 2})
        valid = bytes.fromhex(self.activity_request(1201, (20014, 1))["hex"])
        for body in (b"", valid[:-2], valid[:-1], valid + b"\x08\x01", valid + b"\x10\x01",
                     valid[:-1] + b"\x00", valid[:-2] + b"\x0a\x01\x01",
                     valid[:-1] + protocol.encode_varint((1 << 64) - 1)):
            with self.subTest(body=body):
                self.assert_rejected({"opcode": 1201, "seq": 20000, "hex": body.hex()}, "道具")

    def test_resource_prop_use_without_created_role_is_rejected(self):
        self.save_path.write_text(json.dumps(player.get_default_save()))
        self.assert_rejected(self.activity_request(1201, (20014, 1)), "角色尚未创建")

    def test_unsupported_resource_prop_is_not_silently_consumed(self):
        self.seed_stamina(0)
        self.give_props({20013: 1})
        self.assert_rejected(self.activity_request(1201, (20013, 1)), "暂不支持的恢复道具")

    def test_item_and_fragment_deltas_add_consume_and_remove_zero(self):
        self.replay_through(12)
        saved = json.loads(self.save_path.read_text())
        for cid, query, key in ((20100, "1200", 20100), (11204, "1012", 10204), (10204, "1012", 10204)):
            with self.subTest(cid=cid):
                player.change_item_count(saved, cid, 2, self.role_config)
                record = protocol.encode_pb_field(1, 0, cid) + protocol.encode_pb_field(2, 0, 1)
                used = protocol.encode_pb_field(10, 2, protocol.encode_pb_field(1, 2, record))
                player.apply_reward(saved, used, self.role_config)
                records = self.entity_records(bytes.fromhex(saved["world_state"][query]), 1, 1)
                self.assertEqual(protocol.pb_get_varint(records[key], 2), 1)
                player.change_item_count(saved, cid, -1, self.role_config)
                self.assertNotIn(key, self.entity_records(bytes.fromhex(saved["world_state"][query]), 1, 1))
                for delta in (-1, 1 << 31):
                    with self.assertRaises(ValueError):
                        player.change_item_count(saved, cid, delta, self.role_config)

    def test_cleared_maps_and_claimed_box_survive_reconnect(self):
        self.replay_through(138)
        maps = self.entity_records(self.query_world(1300), 1, 1)
        self.assertTrue({42101, 42102}.issubset(maps))
        self.assertEqual(protocol.pb_get_varint(maps[42101], 2), 3)
        self.assertEqual(protocol.pb_get_varint(maps[42101], 6), 3)
        points = self.entity_records(maps[42101], 7, 1)
        self.assertEqual(set(points), {1, 2, 3, 4, 5})
        self.assertTrue(all(protocol.pb_get_varint(p, 3) == 3 and protocol.pb_get_varint(p, 4) == 1 for p in points.values()))
        point = self.entity_records(maps[42102], 7, 1)[1]
        self.assertEqual(protocol.pb_get_varint(point, 3), 3)

    def test_consumed_gift_cannot_grant_rewards_twice(self):
        self.replay_through(148)
        self.assert_rejected(self.by_seq[148], "道具 20111 数量不足")

    def test_replayed_old_battle_cannot_overwrite_newer_state(self):
        self.replay_through(61)
        self.assert_rejected(self.by_seq[36], "已通关关卡不支持重复录制战斗")

    def test_missing_legacy_world_history_does_not_allow_old_battle(self):
        self.replay_through(138)
        saved = json.loads(self.save_path.read_text())
        del saved["world_state"]
        self.save_path.write_text(json.dumps(saved))
        self.assert_rejected(self.by_seq[36], "战斗录制经验已过期")

    def test_existing_role_cannot_be_recreated_by_old_selection(self):
        self.replay_through(61)
        self.assert_rejected(self.by_seq[11], "角色已创建")

    def test_empty_saved_inventory_is_not_reseeded_on_reconnect(self):
        self.replay_through(12)
        saved = json.loads(self.save_path.read_text())
        saved["world_state"]["1200"] = ""
        saved["world_state"]["1012"] = ""
        self.save_path.write_text(json.dumps(saved))
        for _ in range(2):
            self.assertEqual(self.query_world(1200), b"")
            self.assertEqual(self.query_world(1012), b"")
        self.assert_rejected(self.by_seq[148], "道具 20111 数量不足")

    def test_invalid_world_cache_is_not_sent_or_overwritten(self):
        self.replay_through(12)
        valid = json.loads(self.save_path.read_text())
        cases = (("1002", []), ("1200", "zz"), ("1300", "0a"),
                 ("1200", "0a03080180"), ("1002", "0a020801"),
                 ("1300", "0a0508013a0180"), ("1200", "0a020801"))
        for opcode, invalid in cases:
            with self.subTest(opcode=opcode, invalid=invalid):
                saved = json.loads(json.dumps(valid))
                saved["world_state"][opcode] = invalid
                self.save_path.write_text(json.dumps(saved))
                self.assert_rejected(self.by_seq[12], "载入玩家状态失败")

    def test_partial_slot_updates_preserve_other_entities_and_unknown_fields(self):
        extra = protocol.encode_pb_field(50, 2, b"keep")
        first = b"\x08\x01\x10\x09"
        second = b"\x08\x02\x10\x08"
        base = protocol.encode_pb_field(4, 2, first) + extra + protocol.encode_pb_field(4, 2, second)
        cleared = b"\x08\x01\x10\x00"
        merged = player.merge_pb_records(base, protocol.encode_pb_field(4, 2, cleared), player.SLOT_RECORD_KEYS)
        self.assertEqual(self.entity_records(merged, 4, 1), {1: cleared, 2: second})
        self.assertIn((50, 2, b"keep"), list(protocol.iter_pb_fields(merged)))

    def test_locked_copy_box_cannot_grant_rewards(self):
        self.replay_through(12)
        self.assert_rejected(self.by_seq[119], "副本宝箱未解锁或已领取")

    def test_claimed_copy_box_cannot_grant_rewards_twice(self):
        self.replay_through(119)
        self.assert_rejected(self.by_seq[119], "副本宝箱未解锁或已领取")

    def test_live_copy_boxes_return_rewards_and_save_before_popup(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        for pid, stars in ((2, 3), (3, 3), (4, 3), (5, 2)):
            player.record_copy_win(saved, bytes.fromhex(self.activity_request(1306, [42102, pid])["hex"]),
                                   stars, self.role_config, allow_repeat=True)
        self.save_path.write_text(json.dumps(saved))
        for method, field, expected in ((0, 4, {20017: 2, 20161: 20}), (3, 5, {20017: 2, 20161: 30})):
            before = self.entity_records(bytes.fromhex(saved["world_state"]["1200"]), 1, 1)
            request = self.activity_request(1304, [42102, method])
            conn = ReplayConnection([request], 7)
            send = conn.sendall

            def check_saved_before_send(packet):
                committed = json.loads(self.save_path.read_text())
                copies = self.entity_records(bytes.fromhex(committed["world_state"]["1300"]), 1, 1)
                self.assertEqual(protocol.pb_get_varint(copies[42102], field), 3)
                props = self.entity_records(bytes.fromhex(committed["world_state"]["1200"]), 1, 1)
                for cid, count in expected.items():
                    self.assertEqual(protocol.pb_get_varint(props[cid], 2), (protocol.pb_get_varint(before.get(cid, b""), 2) or 0) + count)
                send(packet)

            conn.sendall = check_saved_before_send
            with redirect_stdout(io.StringIO()):
                self.run_client(conn)
            self.assertEqual([r["opcode"] for r in conn.responses], [1304])
            fields = {n: v for n, w, v in protocol.iter_pb_fields(bytes.fromhex(conn.responses[0]["hex"]))}
            self.assertEqual({cid: protocol.pb_get_varint(raw, 2) for cid, raw in self.entity_records(fields[5], 1, 1).items()}, expected)
            saved = json.loads(self.save_path.read_text())
            self.assertEqual(self.query_world(1200).hex(), saved["world_state"]["1200"])
            self.assertEqual(self.query_world(1300).hex(), saved["world_state"]["1300"])
            committed = self.save_path.read_bytes()
            self.assert_unavailable_response(self.replay([request]), 1304, request["seq"], "已领取")
            self.assertEqual(self.save_path.read_bytes(), committed)

    def test_live_copy_boxes_reject_invalid_locked_and_uncreated_without_changes(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        valid = bytes.fromhex(self.activity_request(1304, [42102, 0])["hex"])
        invalid = [b"", b"\x08", valid + b"\x10\x01", valid + b"\x08\x00", valid + b"\x80"]
        invalid += [bytes.fromhex(self.activity_request(1304, ids)["hex"])
                    for ids in ([42102, 1], [42102, 3], [42102, 6], [42103, 0], [42105, 0], [0, 0], [42102, (1 << 31)])]
        for body in invalid:
            with self.subTest(hex=body.hex()), redirect_stdout(io.StringIO()):
                session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
                memory, original = copy.deepcopy(session.save), self.save_path.read_bytes()
                packets = session.handle(1304, 21000, body)
                self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in packets], [999999, 1999])
                self.assertEqual(session.save, memory)
                self.assertEqual(self.save_path.read_bytes(), original)
        comb = protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 1304) + protocol.encode_pb_field(2, 2, valid))
        before = self.save_path.read_bytes()
        replies = self.replay([{"opcode": 999900, "seq": 21000, "hex": comb.hex()}])
        self.assert_unavailable_response(replies, 999900, 21000, "副本宝箱")
        self.assertEqual(self.save_path.read_bytes(), before)
        saved["has_role"] = False
        self.save_path.write_text(json.dumps(saved))
        before = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([self.activity_request(1304, [42102, 0])]), 1304, 20000, "角色")
        self.assertEqual(self.save_path.read_bytes(), before)

    def test_live_copy_box_failure_rolls_back_items_flags_and_stamina(self):
        self.replay(self.requests)
        body = bytes.fromhex(self.activity_request(1304, [42102, 0])["hex"])
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            before, memory = self.save_path.read_bytes(), copy.deepcopy(session.save)
            self.clock.return_value += player.STAMINA_INTERVAL
            with patch.object(player.os, "replace", side_effect=OSError("disk full")):
                with self.assertRaises(OSError):
                    session.handle(1304, 21000, body)
            self.assertEqual(self.save_path.read_bytes(), before)
            self.assertEqual(session.save, memory)
        props = self.entity_records(bytes.fromhex(memory["world_state"]["1200"]), 1, 1)
        self.give_props({20161: (1 << 31) - 1 - (protocol.pb_get_varint(props.get(20161, b""), 2) or 0)})
        before = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([self.activity_request(1304, [42102, 0])]), 1304, 20000, "范围")
        self.assertEqual(self.save_path.read_bytes(), before)

    def test_gift_save_failure_keeps_items_rewards_and_guide_atomic(self):
        self.replay_through(138)
        rankings = self.save_path.with_name("rankings.json").read_bytes()
        with patch.object(player.os, "replace", side_effect=OSError("disk failure")):
            self.assert_rejected(self.by_seq[148], "保存失败")
        self.assertEqual(sorted(p.name for p in self.save_path.parent.iterdir() if not p.name.startswith('._')), ["accounts", "rankings.json", "role_save.json"])
        self.assertEqual(self.save_path.with_name("rankings.json").read_bytes(), rankings)

    def test_recruit_requires_a_token_and_cannot_reset_owned_generals(self):
        self.replay_through(12)
        self.assert_rejected(self.by_seq[76], "道具 20100 数量不足")
        self.replay([f for f in self.requests if 12 < f["seq"] <= 148])
        for seq in (49, 76):
            with self.subTest(seq=seq):
                self.assert_rejected(self.by_seq[seq], "不支持重复录制招募")

    def complete_tutorial(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        for step in range(saved["guide"]["sections"]["1"]["step"] + 1, self.step_counts[1] + 1):
            body = protocol.encode_pb_field(1, 0, 1) + protocol.encode_pb_field(2, 0, step)
            self.replay([{"opcode": 201, "seq": 20000 + step, "hex": body.hex()}])

    def test_live_recruit_free_paid_duplicate_and_cooldown_survive_reconnect(self):
        self.complete_tutorial()
        gold = self.query_role()[9]
        before = self.entity_records(self.query_world(1002), 1, 2)
        response = self.replay([self.activity_request(1403, [2, 1])])[0]
        reward = dict(protocol.get_comb_messages(bytes.fromhex(response["hex"])))
        self.assertEqual(protocol.parse_ids_pb(reward[2]), [10401, 1])
        generals = [v for n, w, v in protocol.iter_pb_fields(reward[1]) if n == 8 and w == 2]
        self.assertEqual(len(generals), 1)
        iid = protocol.pb_get_varint(generals[0], 2)
        self.assertGreater(iid, 2000000)
        roster = self.entity_records(self.query_world(1002), 1, 2)
        self.assertEqual(roster[iid], generals[0])
        self.assertTrue(all(roster[k] == v for k, v in before.items()))
        self.assertEqual(self.query_role()[9], gold)
        self.clock.return_value += 100
        response = self.replay([dict(self.activity_request(1403, [2, 1]), seq=20001)])[0]
        reward = dict(protocol.get_comb_messages(bytes.fromhex(response["hex"])))
        self.assertEqual(protocol.parse_ids_pb(reward[2]), [10401, 1])
        self.assertFalse(any(n == 8 for n, w, v in protocol.iter_pb_fields(reward[1])))
        fragment = self.entity_records(self.query_world(1012), 1, 1)[10401]
        self.assertEqual(protocol.pb_get_varint(fragment, 2), self.role_config["general_fragment"]["11401"]["recruit"])
        self.assertEqual(self.query_role()[9], gold - 100)
        query = self.replay([self.activity_request(1402)])[0]
        self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(query["hex"]))[5:10], [100, 1, 1, 0, 43100])
        self.clock.return_value = self.now + 43200
        self.replay([self.activity_request(1403, [2, 1])])
        self.assertEqual(self.query_role()[9], gold - 100)
        saved = json.loads(self.save_path.read_text())
        self.assertEqual(saved["recruit_state"]["2"]["freetimes"], 2)
        self.assertEqual(saved["recruit_state"]["2"]["next_free_at"], self.now + 86400)

    def test_live_recruit_ten_and_hundred_costs_first_guarantee_and_unique_ids(self):
        self.complete_tutorial()
        original = json.loads(self.save_path.read_text())
        for pos, method, cid, cost, count in ((1, 2, 20100, 10, 10), (2, 2, 1001, 900, 10),
                                             (3, 2, 20619, 10, 10), (1, 3, 20100, 100, 100)):
            with self.subTest(pos=pos, method=method):
                saved = copy.deepcopy(original)
                player.change_item_count(saved, cid, cost * 2, self.role_config, self.now)
                self.save_path.write_text(json.dumps(saved))
                config = copy.deepcopy(self.role_config)
                base = str(config["recruit_basic"][str(pos)]["freecardgroupid"])
                guarantee = str(config["recruit_basic"][str(pos)]["firsttentavern"])
                config["recruit_deck"][base]["resourceid"] = "10213,1;"
                config["recruit_deck"][guarantee]["resourceid"] = "10409,1;"
                with patch.object(self, "role_config", config):
                    for first in (True, False):
                        response = self.replay([self.activity_request(1403, [pos, method])])[0]
                        rewards = dict(protocol.get_comb_messages(bytes.fromhex(response["hex"])))
                        gets = protocol.parse_ids_pb(rewards[2])
                        self.assertEqual(len(gets), count * 2)
                        self.assertEqual(gets[:2], [10409 if first else 10213, 1])
                        self.assertEqual(gets[2:], [10213, 1] * (count - 1))
                        generals = [v for n, w, v in protocol.iter_pb_fields(rewards[1]) if n == 8 and w == 2]
                        self.assertEqual(len(generals), int(first))
                committed = json.loads(self.save_path.read_text())
                self.assertEqual(committed["recruit_state"][str(pos)]["tentimes"], 20 if method == 3 else 2)
                self.assertEqual(committed["recruit_state"][str(pos)]["consum"], original["recruit_state"][str(pos)]["consum"] + 2 * cost)
                for key in ("gold", "coin", "stamina"):
                    self.assertEqual(committed["role_state"][key], original["role_state"][key])
                self.assertEqual(committed["world_state"]["1200"], original["world_state"]["1200"])
                roster = self.entity_records(self.query_world(1002), 1, 2)
                self.assertEqual(sum(protocol.pb_get_varint(v, 1) == 10409 for v in roster.values()), 1)

    def test_live_recruit_saves_before_reply_and_retry_does_not_charge_twice(self):
        self.complete_tutorial()
        self.give_props({20100: 2})
        request = self.activity_request(1403, [1, 1])
        conn = ReplayConnection([request, request], 7)
        send = conn.sendall
        before = json.loads(self.save_path.read_text())

        def check_saved(packet):
            saved = json.loads(self.save_path.read_text())
            self.assertEqual(saved["recruit_state"]["1"]["consumtimes"], before["recruit_state"]["1"]["consumtimes"] + 1)
            props = self.entity_records(bytes.fromhex(saved["world_state"]["1200"]), 1, 1)
            old = self.entity_records(bytes.fromhex(before["world_state"]["1200"]), 1, 1)
            self.assertEqual(protocol.pb_get_varint(props[20100], 2), protocol.pb_get_varint(old[20100], 2) - 1)
            send(packet)

        conn.sendall = check_saved
        with redirect_stdout(io.StringIO()):
            self.run_client(conn)
        self.assertEqual(len(conn.responses), 2)
        self.assertEqual(conn.responses[0], conn.responses[1])

    def test_live_recruit_rejects_bad_requests_and_rolls_back_failed_settlement(self):
        self.complete_tutorial()
        body = bytes.fromhex(self.activity_request(1403, [1, 1])["hex"])
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            original, memory = self.save_path.read_bytes(), copy.deepcopy(session.save)
            for data in (b"", b"\x08", body + b"\x08\x01", body + b"\x10\x01", body + b"\x80",
                         b"\x08\x05\x08\x01", b"\x08\x02\x08\x03", b"\x08\x01\x08\x00"):
                replies = session.handle(1403, 20000, data)
                self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in replies], [999999, 1999])
                self.assertEqual(session.save, memory)
                self.assertEqual(self.save_path.read_bytes(), original)
            self.clock.return_value += 360
            with patch.object(player.os, "replace", side_effect=OSError("disk full")):
                with self.assertRaises(OSError):
                    session.handle(1403, 20000, body)
            self.assertEqual(session.save, memory)
            self.assertEqual(self.save_path.read_bytes(), original)
        self.assert_unavailable_response(self.replay([self.activity_request(1403, [1, 3])]), 1403, 20000, "数量不足")
        self.assertEqual(self.save_path.read_bytes(), original)

    def test_recruit_query_validates_state_and_preserves_pool_order(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        saved["recruit_state"] = dict(reversed(list(saved["recruit_state"].items())))
        self.save_path.write_text(json.dumps(saved))
        reply = self.replay([self.activity_request(1402)])[0]
        values = protocol.parse_ids_pb(bytes.fromhex(reply["hex"]))
        self.assertEqual(values[:5], [1, 0, 1, 0, 0])
        self.assertEqual(values[10:15], [0, 1, 0, 0, 86400])
        before = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([self.activity_request(1402, [1])]), 1402, 20000, "不接受参数")
        self.assertEqual(self.save_path.read_bytes(), before)
        for invalid in ([], {}, {"1": {}}, dict(saved["recruit_state"], **{"2": {"next_free_at": -1}})):
            saved["recruit_state"] = invalid
            self.save_path.write_text(json.dumps(saved))
            self.assert_rejected(self.activity_request(1402), "招募")

    def test_live_recruit_discount_boundary_and_token_only_payment(self):
        self.complete_tutorial()
        saved = json.loads(self.save_path.read_text())
        opened = self.now - self.now % 86400 - 8 * 3600
        saved["role_snapshot"] = protocol.pb_set_varint(bytes.fromhex(saved["role_snapshot"]), 22, opened).hex()
        start = opened + 5 * 86400
        for now, expected in ((start, 10), (start + 1, 8), (start + 5 * 86400 - 1, 8), (start + 5 * 86400, 10)):
            self.assertEqual(recruit.discount(saved, self.role_config, now), expected)
        self.clock.return_value = start + 1
        player.change_item_count(saved, 20619, 8, self.role_config, self.now)
        self.save_path.write_text(json.dumps(saved))
        gold = saved["role_state"]["gold"]
        response = self.replay([self.activity_request(1403, [3, 2])])[0]
        self.assertEqual(response["opcode"], 1403)
        self.assertNotIn(20619, self.entity_records(self.query_world(1200), 1, 1))
        self.assertEqual(self.query_role()[9], gold)
        before = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([self.activity_request(1403, [3, 2])]), 1403, 20000, "20619")
        self.assertEqual(self.save_path.read_bytes(), before)

    def test_live_recruit_overflow_uncreated_and_guide_lock_are_nonmutating(self):
        self.complete_tutorial()
        original = json.loads(self.save_path.read_text())
        for kind in ("uncreated", "guide", "fragments", "iid", "counter", "gold"):
            with self.subTest(kind=kind):
                saved = copy.deepcopy(original)
                pos = 3
                saved["recruit_state"]["3"]["consumtimes"] = 0
                player.change_item_count(saved, 20619, 1, self.role_config, self.now)
                if kind == "uncreated":
                    saved["has_role"] = False
                elif kind == "guide":
                    saved["guide"]["sections"]["1"] = {"status": 1, "step": 30, "steps": [13, 30]}
                elif kind == "fragments":
                    player.change_item_count(saved, 11213, (1 << 31) - 1, self.role_config, self.now)
                elif kind == "iid":
                    pos = 2
                    general = recruit.new_general(10201, (1 << 31) - 1, self.role_config)
                    player.record_slot_update(saved, protocol.encode_pb_field(1, 2, general))
                elif kind == "counter":
                    saved["recruit_state"]["3"]["consumtimes"] = (1 << 31) - 1
                else:
                    pos = 2
                    saved["role_state"]["gold"] = 0
                    saved["recruit_state"]["2"]["next_free_at"] = self.now + 10
                self.save_path.write_text(json.dumps(saved))
                before = self.save_path.read_bytes()
                response = self.replay([self.activity_request(1403, [pos, 1])])
                self.assertEqual([r["opcode"] for r in response], [999999, 1999])
                self.assertEqual(self.save_path.read_bytes(), before)

    def test_live_recruit_determinism_legacy_migration_and_changed_retry(self):
        self.complete_tutorial()
        saved = json.loads(self.save_path.read_text())
        del saved["recruit_state"]
        self.assertEqual(recruit.get_state(saved)["3"]["freetimes"], 1)
        self.assertEqual(recruit.get_state(saved)["1"]["consumtimes"], 1)
        self.assertEqual(recruit.get_state(saved)["3"]["next_free_at"], 0)
        request = bytes.fromhex(self.activity_request(1403, [1, 2])["hex"])
        first, second = copy.deepcopy(saved), copy.deepcopy(saved)
        self.assertEqual(recruit.draw(first, request, self.role_config, self.now, 73),
                         recruit.draw(second, request, self.role_config, self.now, 73))
        self.assertEqual(first, second)
        self.save_path.write_text(json.dumps(saved))
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            body = bytes.fromhex(self.activity_request(1403, [2, 1])["hex"])
            session.handle(1403, 21000, body)
            self.clock.return_value += 1
            session.handle(1001, 21001, b"")
            before = self.save_path.read_bytes()
            reply = session.handle(1403, 21000, body)
            self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in reply], [999999, 1999])
            self.assertEqual(self.save_path.read_bytes(), before)

    def test_invalid_recharge_recruit_and_unsupported_comb_return_native_errors(self):
        self.replay(self.requests)
        before = self.save_path.read_bytes()
        for opcode in (115, 116, 20000, 1401, 7111, 7112, 7113):
            request = self.activity_request(opcode, [1])
            self.assert_unavailable_response(self.replay([request]), opcode, 20000, "充值" if opcode in (115, 116, 20000) else "招募")
            comb = protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, opcode)
                                           + protocol.encode_pb_field(2, 2, bytes.fromhex(request["hex"])))
            response = self.replay([{"opcode": 999900, "seq": 21000, "hex": comb.hex()}])
            self.assert_unavailable_response(response, 999900, 21000, "充值" if opcode in (115, 116, 20000) else "招募")
            self.assertEqual(self.save_path.read_bytes(), before)

    def recharge_order(self, cid, bagid=None):
        body = protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, cid))
        if bagid is not None:
            body += protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, bagid))
        response = self.replay([{"opcode": 115, "seq": 20000, "hex": body.hex()}])[0]
        self.assertEqual(response["opcode"], 115)
        param = next(v for n, w, v in protocol.iter_pb_fields(bytes.fromhex(response["hex"])) if n == 1)
        return protocol.pb_get_varint(param, 1)

    def seed_daily_event_account(self):
        saved = self.seed_welfare_account()
        saved["role_snapshot"] = protocol.pb_set_varint(bytes.fromhex(saved["role_snapshot"]), 22, self.now).hex()
        self.save_path.write_text(json.dumps(saved))
        return saved

    def confirm_event_order(self, cid, bagid=None):
        return self.replay([self.activity_request(116, [self.recharge_order(cid, bagid)])])[0]

    def test_daily_event_tabs_query_real_periods_and_unpaid_state(self):
        saved = self.seed_daily_event_account()
        zero = dict(saved, role_snapshot=protocol.pb_set_varint(bytes.fromhex(saved["role_snapshot"]), 22, 0).hex())
        self.assertEqual(daily_events.month_end(zero, self.role_config), 5 * 86400 - 28800)
        for opcode, expected in ((3680, [0, 0, 0, 0]), (3682, [0, 0]), (5000, [1, 1, 0] + [0] * 11),
                                 (8075, [0] * 8), (8077, [0] * 8)):
            with self.subTest(opcode=opcode):
                self.assertEqual(protocol.parse_ids_pb(self.query_world(opcode)), expected)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(8026)), [v for i in range(190501, 190507) for v in (i, 0, 0)])
        self.assertEqual(protocol.parse_ids_pb(self.query_world(5034))[:2], [1, 0])
        body = self.query_world(2000)
        data = dict(protocol.get_comb_messages(body))[2]
        values = protocol.parse_ids_pb(data)
        periods = {values[i]: values[i+1:i+3] for i in range(0, len(values), 3)}
        self.assertEqual(periods[87], [1, 0])
        self.assertEqual(periods[170], [1, 1])

    def test_daily_event_cumulative_rewards_only_confirmed_orders_and_reconnect(self):
        self.seed_daily_event_account()
        order = self.recharge_order(5)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(5000))[2], 0)
        self.assertEqual(self.replay([self.activity_request(5001, [1])])[0]["opcode"], 999999)
        self.replay([self.activity_request(116, [order])])
        self.assertEqual(protocol.parse_ids_pb(self.query_world(5000))[2:4], [68, 1])
        reward = self.query_world_for_values(5001, [1])
        self.assertTrue(any(n == 8 for n, w, v in protocol.iter_pb_fields(reward)))
        self.assertEqual(protocol.parse_ids_pb(self.query_world(5000))[3], 2)
        before = self.save_path.read_bytes()
        self.assertEqual(self.replay([self.activity_request(5001, [1])])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), before)
        self.clock.return_value += 7 * 86400
        self.confirm_event_order(8)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(5000))[2], 68)

    def test_daily_event_closed_periods_clear_only_their_activity_flags(self):
        saved = self.seed_daily_event_account()
        rows = {rid: protocol.encode_pb_field(1, 0, rid) + protocol.encode_pb_field(2, 0, 1)
                     + protocol.encode_pb_field(9, 2, b"unknown") for rid in (78, 87, 153, 169, 170, 101, 999)}
        data = b"".join(protocol.encode_pb_field(1, 2, row) for row in rows.values())
        message = protocol.encode_pb_field(1, 0, 1) + protocol.encode_pb_field(2, 2, data)
        message += protocol.encode_pb_field(8, 0, 42)
        body = protocol.encode_pb_field(1, 2, message) + protocol.encode_pb_field(7, 2, b"outer")
        for days, active in ((0, {78, 153, 169, 170}), (3, {78, 87, 153, 169, 170}),
                             (4, {78, 153, 169, 170}), (7, {153}), (35, set())):
            with self.subTest(days=days):
                reply = daily_events.rewrite_periods(body, saved, self.role_config, self.now + days * 86400)
                envelope = next(v for n, w, v in protocol.iter_pb_fields(reply) if (n, w) == (1, 2))
                self.assertEqual(protocol.pb_get_varint(envelope, 8), 42)
                actual = self.entity_records(dict(protocol.get_comb_messages(reply))[1], 1, 1)
                for rid, row in rows.items():
                    self.assertEqual(actual[rid], protocol.pb_set_varint(row, 2, int(rid in active or rid in (101, 999))))
                self.assertIn((7, 2, b"outer"), list(protocol.iter_pb_fields(reply)))

    def test_daily_event_week_funds_buy_independently_and_unlock_by_event_day(self):
        self.seed_daily_event_account()
        gold = self.query_role()[9]
        for cid, bagid, query, claim in ((4, 7, 8075, 8076), (6, 8, 8077, 8078)):
            self.assertEqual(self.confirm_event_order(cid, bagid)["opcode"], 116)
            self.assertEqual(self.query_role()[9], gold)
            self.assertEqual(protocol.parse_ids_pb(self.query_world(query)), [1, 1] + [0] * 6)
            self.assertEqual(self.replay([self.activity_request(claim, [2])])[0]["opcode"], 999999)
            self.assertEqual(self.replay([self.activity_request(claim, [1])])[0]["opcode"], claim)
            self.assertEqual(self.replay([self.activity_request(claim, [1])])[0]["opcode"], 999999)
        self.clock.return_value += 86400
        self.assertEqual(protocol.parse_ids_pb(self.query_world(8075)), [1, 2, 1] + [0] * 5)
        self.assertEqual(self.replay([self.activity_request(8076, [2])])[0]["opcode"], 8076)
        self.clock.return_value += 6 * 86400
        self.assertEqual(self.replay([self.activity_request(8078, [2])])[0]["opcode"], 999999)

    def test_daily_event_speed_gift_payment_claim_daily_limit_and_midnight(self):
        self.seed_daily_event_account()
        gold = self.query_role()[9]
        self.confirm_event_order(4, 190501)
        self.assertEqual(self.query_role()[9], gold)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(8026))[:3], [190501, 1, 0])
        self.assertEqual(self.replay([self.activity_request(8027, [190501])])[0]["opcode"], 8027)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(8026))[:3], [190501, 2, 1])
        before = self.save_path.read_bytes()
        for opcode, values in ((8027, [190501]), (8027, [190507])):
            self.assertEqual(self.replay([self.activity_request(opcode, values)])[0]["opcode"], 999999)
            self.assertEqual(self.save_path.read_bytes(), before)
        self.clock.return_value += 86400
        self.assertEqual(protocol.parse_ids_pb(self.query_world(8026))[:3], [190501, 0, 0])
        self.confirm_event_order(4, 190501)
        self.assertEqual(self.replay([self.activity_request(8027, [190501])])[0]["opcode"], 8027)
        before = self.save_path.read_bytes()
        self.clock.return_value = self.now
        self.assertEqual(self.replay([self.activity_request(8027, [190501])])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), before)

    def test_daily_event_month_funds_card_requirements_welfare_and_twenty_daily_rewards(self):
        self.seed_daily_event_account()
        self.confirm_event_order(5)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(3680)), [0, 0, 0, 0])
        self.confirm_event_order(1)
        self.confirm_event_order(2)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(3680)), [1, 0, 0, 0])
        self.confirm_event_order(6)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(3682)), [1, 1])
        for i in (1, 2):
            self.assertEqual(self.replay([self.activity_request(3683, [i])])[0]["opcode"], 3683)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(3682)), [2, 2])
        self.assertEqual(self.replay([self.activity_request(3681, [1])])[0]["opcode"], 999999)
        for day in range(20):
            self.clock.return_value = self.now + (5 + day) * 86400
            for i in (1, 2):
                self.assertEqual(self.replay([self.activity_request(3681, [i])])[0]["opcode"], 3681)
                self.assertEqual(self.replay([self.activity_request(3681, [i])])[0]["opcode"], 999999)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(3680)), [3, 20, 3, 20])

    def test_daily_event_double_recharge_is_capped_not_stacked_and_no_extra_for_gifts(self):
        self.seed_daily_event_account()
        self.clock.return_value += 3 * 86400
        gold = self.query_role()[9]
        for multiple in (2, 2, 1):
            self.confirm_event_order(3)
            gold += 66 * multiple
            self.assertEqual(self.query_role()[9], gold)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(5034))[4], 2)
        self.confirm_event_order(5, 2)
        self.assertEqual(self.query_role()[9], gold)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(5034))[6], 0)
        self.clock.return_value += 86400
        self.confirm_event_order(3)
        self.assertEqual(self.query_role()[9], gold + 66)

    def test_daily_event_invalid_orders_parameters_and_failed_saves_are_atomic(self):
        self.seed_daily_event_account()
        self.confirm_event_order(5)
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            memory, original = copy.deepcopy(session.save), self.save_path.read_bytes()
            for opcode in daily_events.QUERIES + daily_events.CLAIMS:
                for body in (b"\x08", b"\x10\x01", b"\x08\x01" * 3):
                    result = session.handle(opcode, 10, body)
                    self.assertEqual(struct.unpack(">IIII", result[0][:16])[2], 999999)
                    self.assertEqual((session.save, self.save_path.read_bytes()), (memory, original))
            for cid, bagid in ((5, 7), (4, 8), (4, 190504), (6, 999), (5, 190999)):
                body = protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, cid))
                body += protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, bagid))
                result = session.handle(115, 11, body)
                self.assertEqual(struct.unpack(">IIII", result[0][:16])[2], 999999)
                self.assertEqual((session.save, self.save_path.read_bytes()), (memory, original))
            with patch.object(player.os, "replace", side_effect=OSError("disk full")):
                with self.assertRaises(OSError):
                    session.handle(5001, 12, b"\x08\x01")
            self.assertEqual((session.save, self.save_path.read_bytes()), (memory, original))

    def test_simulated_recharge_persists_order_and_confirms_only_once(self):
        self.complete_tutorial()
        gold = self.query_role()[9]
        self.assertEqual(protocol.parse_ids_pb(self.query_world(117)), [1, 0, 0])
        order = self.recharge_order(3)
        self.assertEqual(self.recharge_order(3), order)
        self.assertEqual(self.query_role()[9], gold)
        request = self.activity_request(116, [order])
        conn = ReplayConnection([request, request], 7)
        send = conn.sendall

        def check_committed(packet):
            saved = json.loads(self.save_path.read_text())
            self.assertTrue(saved["recharge_state"]["paid"])
            self.assertEqual(saved["role_state"]["gold"], gold + 132)
            send(packet)

        conn.sendall = check_committed
        with redirect_stdout(io.StringIO()):
            self.run_client(conn)
        self.assertEqual([r["opcode"] for r in conn.responses], [116, 116])
        self.assertIsNone(protocol.pb_get_varint(bytes.fromhex(conn.responses[1]["hex"]), 2))
        self.replay([request])  # A new connection must not grant the same payment again.
        self.assertEqual(self.query_role()[9], gold + 132)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(117)), [2, 6, 1])
        self.assertEqual(protocol.parse_ids_pb(self.query_world(2099))[2], 1)
        next_order = self.recharge_order(3)
        self.assertGreater(next_order, order)
        self.replay([self.activity_request(116, [next_order])])
        self.assertEqual(self.query_role()[9], gold + 198)
        before = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([request]), 116, 20000, "过期")
        self.assertEqual(self.save_path.read_bytes(), before)

    def test_recharge_followup_queries_cannot_change_paid_save(self):
        self.complete_tutorial()
        self.replay([self.activity_request(116, [self.recharge_order(3)])])
        before = self.save_path.read_bytes()
        self.assertEqual(protocol.parse_ids_pb(self.query_world(3680)), [0, 0, 0, 0])
        self.assertEqual(self.save_path.read_bytes(), before)
        requests = [self.activity_request(opcode) for opcode in (3684, 5531, 2039)]
        requests.append({"opcode": 999900, "seq": 20000, "hex": "0a0308f50f0a0308f70f0a0308e5320a03089a35"})
        for request in requests:
            with self.subTest(opcode=request["opcode"]):
                self.assert_unavailable_response(self.replay([request]), request["opcode"], 20000, "尚未实现")
                self.assertEqual(self.save_path.read_bytes(), before)

    def test_simulated_recharge_first_gift_deduplicates_owned_general(self):
        self.complete_tutorial()
        saved = json.loads(self.save_path.read_text())
        player.apply_reward(saved, recruit.build_reward(saved, [(10405, 1)], self.role_config), self.role_config, self.now)
        self.save_path.write_text(json.dumps(saved))
        self.replay([self.activity_request(116, [self.recharge_order(8)])])
        role = self.query_role()
        self.assertEqual(role[9], saved["role_state"]["gold"] + 23340)
        self.assertEqual(role[4], recharge.vip({"rmb": 648}, self.role_config))
        response = self.replay([self.activity_request(2098)])[0]
        reward = bytes.fromhex(response["hex"])
        self.assertEqual(response["opcode"], 2098)
        self.assertEqual(protocol.pb_get_varint(reward, 1), 1000000)
        self.assertFalse(any(n == 8 for n, _, _ in protocol.iter_pb_fields(reward)))
        fragments = self.entity_records(self.query_world(1012), 1, 1)
        self.assertEqual(protocol.pb_get_varint(fragments[10405], 2), self.role_config["general_fragment"]["11405"]["recruit"])
        self.assertEqual(protocol.parse_ids_pb(self.query_world(117))[2], 2)
        before = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([self.activity_request(2098)]), 2098, 20000, "已领取")
        self.assertEqual(self.save_path.read_bytes(), before)

    def test_simulated_month_cards_renew_daily_at_utc8_and_keep_claims(self):
        self.complete_tutorial()
        midnight = (self.now + 8 * 3600) // 86400 * 86400 - 8 * 3600 + 86400
        self.clock.return_value = midnight - 1
        for cid in (1, 2):
            self.replay([self.activity_request(116, [self.recharge_order(cid)])])
        self.assertEqual(protocol.parse_ids_pb(self.query_world(2090)), [30, 1, 1, 1])
        self.assertEqual(protocol.parse_ids_pb(self.query_world(2092)), [1, 1, 0, 0])
        for cid in (1, 2):
            self.assertEqual(self.replay([self.activity_request(2091, [cid])])[0]["opcode"], 2091)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(2090)), [30, 2, 1, 2])
        before = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([self.activity_request(2091, [1])]), 2091, 20000, "已领取")
        self.assertEqual(self.save_path.read_bytes(), before)
        self.clock.return_value = midnight
        self.assertEqual(protocol.parse_ids_pb(self.query_world(2090)), [29, 1, 1, 1])
        self.assertEqual(self.replay([self.activity_request(2091, [1])])[0]["opcode"], 2091)
        self.clock.return_value -= 2
        self.assert_unavailable_response(self.replay([self.activity_request(2091, [1])]), 2091, 20000, "已领取")
        self.clock.return_value = midnight
        self.replay([self.activity_request(116, [self.recharge_order(1)])])
        self.assertEqual(protocol.parse_ids_pb(self.query_world(2090)), [59, 2, 1, 1])
        self.assertEqual(self.replay([self.activity_request(2093, [2])])[0]["opcode"], 2093)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(2092)), [1, 2, 0, 0])
        self.clock.return_value = midnight + 59 * 86400
        self.assertEqual(protocol.parse_ids_pb(self.query_world(2090)), [0, 0, 1, 1])
        self.assert_unavailable_response(self.replay([self.activity_request(2091, [1])]), 2091, 20000, "未生效")

    def test_simulated_recharge_invalid_overflow_and_failed_save_are_atomic(self):
        self.complete_tutorial()
        for opcode, body in ((115, b""), (115, b"\x0a\x02\x08\x09"), (115, b"\x0a\x02\x08\x03\x10\x01"),
                             (116, b"\x08\x01"), (117, b"\x08\x01"), (2098, b""), (2093, b"\x08\x01")):
            before = self.save_path.read_bytes()
            response = self.replay([{"opcode": opcode, "seq": 20000, "hex": body.hex()}])
            self.assertEqual([r["opcode"] for r in response], [999999, 1999])
            self.assertEqual(self.save_path.read_bytes(), before)
        order = self.recharge_order(3)
        body = bytes.fromhex(self.activity_request(116, [order])["hex"])
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            memory, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
            with patch.object(player.os, "replace", side_effect=OSError("disk full")):
                with self.assertRaises(OSError):
                    session.handle(116, 20001, body)
            self.assertEqual(session.save, memory)
            self.assertEqual(self.save_path.read_bytes(), disk)
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            session.save["role_state"]["gold"] = (1 << 31) - 1
            memory = copy.deepcopy(session.save)
            self.assertEqual(struct.unpack(">IIII", session.handle(116, 20001, body)[0][:16])[2], 999999)
            self.assertEqual(session.save, memory)
            self.assertEqual(self.save_path.read_bytes(), disk)

    def test_fengshen_single_spends_token_then_gold_and_grants_fragments(self):
        self.complete_tutorial()
        self.give_props({20618: 1, 1001: 1000})
        gold = self.query_role()[9]
        config = copy.deepcopy(self.role_config)
        config["recruit_deck"]["10000017"]["resourceid"] = "11595,2,1;"
        with patch.object(self, "role_config", config):
            for expected in (gold, gold - 500):
                reply = self.replay([self.activity_request(1403, [4, 1])])[0]
                self.assertEqual(reply["opcode"], 1403)
                result = dict(protocol.get_comb_messages(bytes.fromhex(reply["hex"])))
                self.assertEqual(protocol.parse_ids_pb(result[2]), [11595, 2])
                self.assertEqual(self.query_role()[9], expected)
        self.assertNotIn(20618, self.entity_records(self.query_world(1200), 1, 1))
        self.assertEqual(protocol.pb_get_varint(self.entity_records(self.query_world(1012), 1, 1)[10595], 2), 4)

    def test_fengshen_preview_refresh_claim_and_reconnect(self):
        self.complete_tutorial()
        self.give_props({1001: 8000})
        original = json.loads(self.save_path.read_text())
        request = self.activity_request(7111)
        response = self.replay([request, request])
        self.assertEqual(response[0], response[1])
        initial = protocol.parse_ids_pb(bytes.fromhex(response[0]["hex"]))
        self.assertEqual(len(initial), 20)
        self.assertIn(str(initial[0]), self.role_config["general"])
        saved = json.loads(self.save_path.read_text())
        self.assertEqual(saved["world_state"], original["world_state"])
        self.assertEqual(saved["role_state"]["gold"], original["role_state"]["gold"] - 5000)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(7110)), [0, 0] + initial)
        self.assert_unavailable_response(self.replay([request]), 7111, 20000, "先领取")
        refresh = self.replay([self.activity_request(7112)])[0]
        pending = protocol.parse_ids_pb(bytes.fromhex(refresh["hex"]))
        self.assertEqual(protocol.parse_ids_pb(self.query_world(7110)), [0, 1] + pending)
        self.assertEqual(self.query_role()[9], original["role_state"]["gold"] - 5998)
        self.assertEqual(json.loads(self.save_path.read_text())["world_state"], original["world_state"])
        claim = self.activity_request(7113)
        replies = self.replay([claim, claim])
        self.assertEqual(replies[0], replies[1])
        self.assertEqual(protocol.parse_ids_pb(self.query_world(7110)), [1])
        roster = self.entity_records(self.query_world(1002), 1, 2)
        self.assertIn(pending[0], [protocol.pb_get_varint(v, 1) for v in roster.values()])
        self.assert_unavailable_response(self.replay([claim]), 7113, 20000, "没有待领取")
        self.give_props({20618: 10})
        gold = self.query_role()[9]
        self.assertEqual(self.replay([request])[0]["opcode"], 7111)
        self.assertEqual(self.query_role()[9], gold)
        self.assertNotIn(20618, self.entity_records(self.query_world(1200), 1, 1))

    def test_fengshen_failed_refresh_or_save_preserves_previous_preview(self):
        self.complete_tutorial()
        self.give_props({20618: 10})
        self.replay([self.activity_request(7111)])
        before = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([self.activity_request(7112)]), 7112, 20000, "不足")
        self.assertEqual(self.save_path.read_bytes(), before)
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            memory = copy.deepcopy(session.save)
            with patch.object(player.os, "replace", side_effect=OSError("disk full")):
                with self.assertRaises(OSError):
                    session.handle(7113, 20001, b"")
            self.assertEqual(session.save, memory)
            self.assertEqual(self.save_path.read_bytes(), before)

    def change_general_request(self, sid, iid):
        body = protocol.encode_pb_field(1, 0, sid) + protocol.encode_pb_field(3, 0, iid)
        return {"opcode": 1003, "seq": 20000, "hex": body.hex()}

    def seed_godstone_account(self, fragments=10000):
        saved = self.seed_training_account()
        saved["role_state"]["level"] = 22
        self.save_path.write_text(json.dumps(saved))
        self.give_props({20223: fragments})
        return json.loads(self.save_path.read_text())

    def test_godstone_single_upgrade_commits_cost_stats_protagonist_and_retry_once(self):
        before = self.seed_godstone_account()
        raw = self.entity_records(bytes.fromhex(before["world_state"]["1002"]), 1, 2)[7059]
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            packets = session.handle(1130, 34000, recharge.ids([1, 0]))
            self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in packets], [1130, 205])
            self.assertEqual(session.handle(1130, 34000, recharge.ids([1, 0])), packets)
        changed = self.entity_records(packets[0][16:], 1, 2)[7059]
        slot = self.entity_records(packets[0][16:], 4, 1)[1]
        self.assertEqual([protocol.pb_get_varint(slot, n) or 0 for n in range(18, 26)], [1] + [0] * 7)
        self.assertEqual(protocol.pb_get_varint(changed, 6), protocol.pb_get_varint(raw, 6) + 150)
        after = json.loads(self.save_path.read_text())
        self.assertEqual(after["role_state"]["power"], before["role_state"]["power"] + 150)
        self.assertEqual(after["guide"], before["guide"])
        snapshot = bytes.fromhex(after["protagonist_snapshot"])
        self.assertEqual(next(v for n, w, v in protocol.iter_pb_fields(snapshot) if (n, w) == (10, 2)), changed)
        props = self.entity_records(self.query_world(1200), 1, 1)
        self.assertEqual(protocol.pb_get_varint(props[20223], 2), 10000 - 13)
        self.assertEqual(self.entity_records(self.query_world(1002), 1, 2)[7059], changed)

    def test_godstone_quick_upgrade_finishes_one_cycle_and_stops_at_material_or_level_cap(self):
        self.seed_godstone_account(20)
        self.assertEqual(self.replay([self.activity_request(1130, [1, 1])])[0]["opcode"], 1130)
        slots = self.entity_records(self.query_world(1002), 4, 1)
        self.assertEqual([protocol.pb_get_varint(slots[1], n) or 0 for n in range(18, 26)], [1, 1] + [0] * 6)
        self.assertNotIn(20223, self.entity_records(self.query_world(1200), 1, 1))
        self.give_props({20223: 10000})
        for levels in ([1] * 8, [2] * 8):
            self.assertEqual(self.replay([self.activity_request(1130, [1, 1])])[0]["opcode"], 1130)
            slot = self.entity_records(self.query_world(1002), 4, 1)[1]
            self.assertEqual([protocol.pb_get_varint(slot, n) or 0 for n in range(18, 26)], levels)
        disk = self.save_path.read_bytes()
        self.assertEqual(self.replay([self.activity_request(1130, [1, 0])])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), disk)
        attack, _ = battle.rosters(json.loads(disk), self.role_config["copy"]["42102"]["1"], self.role_config)
        self.assertEqual(attack[2]["pet_rates"]["dodge"], Fraction(2, 5))
        self.assertEqual(attack[2]["pet_rates"]["arp"], Fraction(3, 5))

    def test_godstone_bad_requests_and_save_failure_are_atomic(self):
        self.seed_godstone_account()
        bodies = [recharge.ids(v) for v in ([], [1], [1, 0, 0], [0, 0], [8, 0], [7, 0], [1, 2])]
        bodies += [b"\x08", recharge.ids([1, 0]) + b"\x10\x00"]
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            memory, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
            for body in bodies:
                self.assertEqual(struct.unpack(">IIII", session.handle(1130, 34001, body)[0][:16])[2], 999999)
                self.assertEqual((session.save, self.save_path.read_bytes()), (memory, disk))
            with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
                session.handle(1130, 34002, recharge.ids([1, 0]))
            self.assertEqual((session.save, self.save_path.read_bytes(), session.random_replies), (memory, disk, {}))

    def test_godstone_bonus_follows_slot_replacement_without_stacking(self):
        before = self.seed_godstone_account()
        player.apply_reward(before, recruit.build_reward(before, [(10401, 1)], self.role_config), self.role_config, self.now)
        self.save_path.write_text(json.dumps(before))
        self.replay([self.activity_request(1130, [3, 0])])
        original = json.loads(self.save_path.read_text())
        old = self.entity_records(bytes.fromhex(original["world_state"]["1002"]), 1, 2)
        slot = self.entity_records(bytes.fromhex(original["world_state"]["1002"]), 4, 1)[3]
        old_iid = protocol.pb_get_varint(slot, 2)
        iid = next(k for k, raw in old.items() if protocol.pb_get_varint(raw, 1) == 10401)
        for target in (iid, old_iid):
            self.assertEqual(self.replay([self.change_general_request(3, target)])[0]["opcode"], 1003)
        restored = self.entity_records(self.query_world(1002), 1, 2)
        for key in old:
            self.assertEqual(dict((n, v) for n, w, v in protocol.iter_pb_fields(restored[key])),
                             dict((n, v) for n, w, v in protocol.iter_pb_fields(old[key])))

    def test_godstone_all_configured_levels_charge_in_order_and_keep_fractional_rates(self):
        from zyj_server import godstone
        slot = recharge.ids([1])
        for level in range(1, 76):
            row = self.role_config["godstonestrengthening"][str(level)]
            for index in range(8):
                slot, cost = godstone.strengthen(slot, 0, row["teamlv"], 100000, self.role_config)
                name = self.role_config["godstone"][str(index + 1)]["attribute"]
                self.assertEqual(cost, row[name + "_number"])
                self.assertEqual(godstone.levels(slot, self.role_config), [level] * (index + 1) + [level - 1] * (7 - index))
                amount = godstone.attributes(slot, self.role_config)[godstone.ATTR_FIELDS[name]]
                self.assertEqual(amount, Fraction(str(row[name])) * (100 if name in ("dodge", "parry", "resilience", "hit", "arp") else 1))
        with self.assertRaises(ValueError):
            godstone.strengthen(slot, 0, 150, 100000, self.role_config)

    def test_godstone_native_callback_deducts_only_the_actual_changed_stones(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("神石回调验证需本机已有 lupa.lua51")
        self.seed_godstone_account()
        lua = LuaRuntime()
        lua.globals().gamedata = lua.table_from({"config": self.role_config}, recursive=True)
        lua.execute('''print=function() end
            table.copy=function(t) local n={} for k,v in pairs(t) do n[k]=v end return n end
            gamedata.cache={slots={[1]={}},props={[20223]={num=10000}}}
            gamedata.ext={MagicstoneUp={sid=1}}
            for i=1,8 do gamedata.cache.slots[1]["g"..i]=0 end
            function gamedata:SlotInfoProcess(info) self.cache.slots[1]=info.slot end
            function gamedata:updateprops(data) self.cache.props[data.cid].num=self.cache.props[data.cid].num+data.num end
            slots_pb={SlotS=function() return {ParseFromString=function(self,raw) self.slot=decodeSlot(raw) end} end}''')
        def decode_slot(raw):
            slot = self.entity_records(bytes.fromhex(raw), 4, 1)[1]
            return lua.table_from({"g" + str(i): protocol.pb_get_varint(slot, 17 + i) or 0 for i in range(1, 9)})
        lua.globals().decodeSlot = decode_slot
        code = apk_builder.read_script("GameSlots").decode().replace("\r\n", "\n")
        lua.execute(code[code.index("function NetMagicstoneUpCallBack("):code.index("function UIChangeSlotCallBack(")])
        for method in (0, 1, 1):
            reply = self.replay([self.activity_request(1130, [1, method])])[0]
            lua.globals().NetMagicstoneUpCallBack(lua.table_from({"rbuf": reply["hex"]}))
            props = self.entity_records(self.query_world(1200), 1, 1)
            self.assertEqual(lua.globals().gamedata.cache.props[20223].num, protocol.pb_get_varint(props[20223], 2))
        self.assertIsNone(lua.globals().gameConfig)

    def change_equip_request(self, sid, iid):
        body = protocol.encode_pb_field(1, 0, sid) + protocol.encode_pb_field(2, 0, iid)
        return {"opcode": 1005, "seq": 20000, "hex": body.hex()}

    def test_change_equip_replaces_all_six_parts_and_preserves_progress(self):
        saved = self.seed_training_account()
        cids = (21204, 22204, 23204, 24204, 26201, 25201)
        player.apply_reward(saved, activities.build_reward(saved, ";".join(f"{cid},1" for cid in cids), self.role_config), self.role_config, self.now)
        self.save_path.write_text(json.dumps(saved))
        inventory = self.entity_records(bytes.fromhex(saved["world_state"]["1002"]), 2, 1)
        for field, cid in zip(range(4, 10), cids):
            with self.subTest(cid=cid):
                before = json.loads(self.save_path.read_text())
                iid = max(key for key, raw in inventory.items() if protocol.parse_ids_pb(raw)[1] == cid)
                items = [0] * 6
                items[field - 4] = iid
                expected = copy.deepcopy(before)
                update = formation.change(expected, 1007, recharge.ids([1, 1, *items]), self.role_config)
                request = self.change_equip_request(1, iid)
                replies = self.replay([request, request], chunk_size=7)
                self.assertEqual([row["opcode"] for row in replies], [1005, 205, 1005, 205])
                self.assertEqual(replies[:2], replies[2:])
                self.assertEqual(bytes.fromhex(replies[0]["hex"]), update)
                after = json.loads(self.save_path.read_text())
                self.assertEqual(after["role_state"], expected["role_state"])
                self.assertEqual(after["guide"], before["guide"])
                self.assertEqual({k: v for k, v in after["world_state"].items() if k != "1002"},
                                 {k: v for k, v in before["world_state"].items() if k != "1002"})
                protagonist = bytes.fromhex(after["protagonist_snapshot"])
                general = self.entity_records(bytes.fromhex(after["world_state"]["1002"]), 1, 2)[7059]
                self.assertEqual(next(v for n, w, v in protocol.iter_pb_fields(protagonist) if (n, w) == (10, 2)), general)
                old_protagonist = bytes.fromhex(before["protagonist_snapshot"])
                self.assertEqual([protocol.pb_get_varint(protagonist, n) for n in range(1, 10)],
                                 [protocol.pb_get_varint(old_protagonist, n) for n in range(1, 10)])
                self.assertEqual([row["opcode"] for row in self.replay([request])], [1005])
                self.assertEqual(self.entity_records(self.query_world(1002), 2, 1), inventory)
                self.assertEqual(json.loads(self.save_path.read_text())["world_state"], after["world_state"])

    def test_change_equip_swaps_worn_items_and_moves_to_empty_parts_without_duplicates(self):
        self.complete_tutorial()
        before = json.loads(self.save_path.read_text())
        world = bytes.fromhex(before["world_state"]["1002"])
        slots = self.entity_records(world, 4, 1)
        armors = {sid: protocol.pb_get_varint(slot, 5) or 0 for sid, slot in slots.items()}
        for sid, iid in ((1, armors[3]), (1, armors[1]), (2, armors[1]), (1, armors[1])):
            previous = self.entity_records(self.query_world(1002), 4, 1)
            origin = next(index for index, slot in previous.items() if protocol.pb_get_varint(slot, 5) == iid)
            replies = self.replay([self.change_equip_request(sid, iid)])
            self.assertEqual([row["opcode"] for row in replies], [1005])
            current = self.entity_records(self.query_world(1002), 4, 1)
            self.assertEqual(protocol.pb_get_varint(current[sid], 5), iid)
            self.assertEqual(protocol.pb_get_varint(current[origin], 5), protocol.pb_get_varint(previous[sid], 5) or 0)
            equipped = [protocol.pb_get_varint(slot, field) for slot in current.values() for field in range(4, 10)
                        if protocol.pb_get_varint(slot, field)]
            self.assertEqual(len(equipped), len(set(equipped)))
        after = self.entity_records(self.query_world(1002), 1, 2)
        for iid, raw in self.entity_records(world, 1, 2).items():
            self.assertEqual(dict((n, v) for n, w, v in protocol.iter_pb_fields(after[iid])),
                             dict((n, v) for n, w, v in protocol.iter_pb_fields(raw)))
        self.assertEqual(self.entity_records(self.query_world(1002), 2, 1), self.entity_records(world, 2, 1))
        self.assertEqual(json.loads(self.save_path.read_text())["role_state"]["power"], before["role_state"]["power"])

    def test_change_equip_invalid_requests_and_failed_save_are_atomic(self):
        self.complete_tutorial()
        valid = bytes.fromhex(self.change_equip_request(2, 10740)["hex"])
        bodies = [bytes.fromhex(self.change_equip_request(sid, iid)["hex"])
                  for sid, iid in ((0, 10740), (4, 10740), (8, 10740), (2, 0), (2, 987654), (2, 1 << 31))]
        bodies += [b"", b"\x08", b"\x08\x02", b"\x0a\x00\x10\x01", valid + b"\x10\x01", valid + b"\x18\x00",
                   b"\x08\x02\x08\x02", valid + b"\x08\x02"]
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            memory, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
            for body in bodies:
                with self.subTest(body=body.hex()):
                    packets = session.handle(1005, 20000, body)
                    self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in packets], [999999, 1999])
                    self.assertEqual((session.save, self.save_path.read_bytes(), session.random_replies), (memory, disk, {}))
            with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
                session.handle(1005, 20001, valid)
            self.assertEqual((session.save, self.save_path.read_bytes(), session.random_replies), (memory, disk, {}))

    def test_change_equip_rejects_advanced_cheer_and_tutorial_requests(self):
        self.complete_tutorial()
        baseline = json.loads(self.save_path.read_text())
        item = self.entity_records(bytes.fromhex(baseline["world_state"]["1002"]), 2, 1)[10740]
        for reason in ("advanced", "cheer", "tutorial", "empty", "duplicate", "wrong_part", "locked_source", "unknown_cid", "short_item"):
            with self.subTest(reason=reason):
                saved = copy.deepcopy(baseline)
                if reason == "advanced":
                    values = protocol.parse_ids_pb(item)
                    values[3] = 1
                    player.record_slot_update(saved, protocol.encode_pb_field(2, 2, recharge.ids(values)))
                elif reason == "cheer":
                    cheer = protocol.encode_pb_field(1, 0, 1) + protocol.encode_pb_field(5, 0, 10740)
                    player.record_slot_update(saved, protocol.encode_pb_field(5, 2, cheer))
                elif reason == "tutorial":
                    saved["guide"]["sections"]["1"]["status"] = 1
                    saved["guide"]["sections"]["1"]["step"] = 1
                elif reason == "empty":
                    saved["role_state"]["level"] = 14
                elif reason in ("duplicate", "wrong_part", "locked_source"):
                    slots = self.entity_records(bytes.fromhex(saved["world_state"]["1002"]), 4, 1)
                    for sid in ((1, 3) if reason == "duplicate" else (4,) if reason == "locked_source" else (1,)):
                        slot = protocol.pb_set_varint(slots[sid], 4 if reason == "wrong_part" else 5, 10740)
                        player.record_slot_update(saved, protocol.encode_pb_field(4, 2, slot))
                else:
                    values = [10740, 999999, 1] if reason == "unknown_cid" else [10740]
                    player.record_slot_update(saved, protocol.encode_pb_field(2, 2, recharge.ids(values)))
                self.save_path.write_text(json.dumps(saved))
                before = self.save_path.read_bytes()
                request = self.change_equip_request(4 if reason == "empty" else 2, 10740)
                self.assertEqual(self.replay([request])[0]["opcode"], 999999)
                self.assertEqual(self.save_path.read_bytes(), before)
        self.save_path.write_text(json.dumps(baseline))
        body = bytes.fromhex(self.change_equip_request(2, 10740)["hex"])
        comb = protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 1005) + protocol.encode_pb_field(2, 2, body))
        self.assertEqual(self.replay([{"opcode": 999900, "seq": 20000, "hex": comb.hex()}])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), json.dumps(baseline).encode())

    def test_actual_apk_manual_equip_callbacks_accept_native_request_and_slot_reply(self):
        import test_activity_copy
        self.complete_tutorial()
        self.config = self.role_config
        lua = test_activity_copy.ActivityCopyTests.network_lua(self)
        for name in ("slotchangeequip_pb", "slots_pb"):
            lua.execute(apk_builder.read_script(name, "pb"))
        lua.execute(b'''gamedata.cache.equips={[10740]={cid=22102}}
            function gamedata:SlotInfoProcess(info) self.lastSlots=info end''')
        lua.execute(apk_builder.read_script("GameSlotChangeEquip"))
        remote, opcode, body = lua.globals().UISlotChangeEquipCallBack(lua.table_from({b"slot": 2, b"equipeid": 10740}))
        self.assertEqual((remote, opcode, body), (1, 1005, bytes.fromhex(self.change_equip_request(2, 10740)["hex"])))
        replies = self.replay([{"opcode": opcode, "seq": 20000, "hex": body.hex()}])
        self.assertEqual(replies[0]["opcode"], 1005)
        result = lua.globals().NetSlotChangeEquipCallBack(lua.table_from({b"rbuf": bytes.fromhex(replies[0]["hex"])}))
        self.assertEqual((result[b"type"], result[b"equipCID"]), (1005, 22102))
        slots = {row[b"sid"]: row for _, row in lua.globals().gamedata[b"lastSlots"][b"slots"].items()}
        self.assertEqual(slots[2][b"armor"], 10740)
        self.assertIsNone(lua.globals().gameConfig)

    def test_quick_equip_uses_owned_inventory_and_survives_reconnect(self):
        self.complete_tutorial()
        saved = json.loads(self.save_path.read_text())
        player.apply_reward(saved, activities.build_reward(saved, "22204,1;", self.role_config), self.role_config, self.now)
        self.save_path.write_text(json.dumps(saved))
        world = self.query_world(1002)
        inventory = self.entity_records(world, 2, 1)
        armor = max(inventory)
        before = self.entity_records(world, 1, 2)[7060]
        request = self.activity_request(1007, [2, 1, 10719, armor, 10741, 10742, 0, 0])
        replies = self.replay([request, request], chunk_size=7)
        self.assertEqual([r["opcode"] for r in replies], [1007, 205, 1007, 205])
        self.assertEqual(replies[:2], replies[2:])
        response = bytes.fromhex(replies[0]["hex"])
        slot = self.entity_records(response, 4, 1)[2]
        self.assertEqual([protocol.pb_get_varint(slot, f) or 0 for f in range(4, 10)],
                         [10719, armor, 10741, 10742, 0, 0])
        after = self.entity_records(response, 1, 2)[7060]
        self.assertEqual(protocol.pb_get_varint(after, 6), protocol.pb_get_varint(before, 6) + 240 + 130)
        self.assertEqual(protocol.pb_get_varint(after, 7), protocol.pb_get_varint(before, 7) + 240)
        self.assertEqual(protocol.pb_get_varint(after, 8), protocol.pb_get_varint(before, 8) + 1000)
        world = self.query_world(1002)
        self.assertEqual(self.entity_records(world, 4, 1)[2], slot)
        self.assertEqual(self.entity_records(world, 1, 2)[7060], after)
        self.assertEqual(self.entity_records(world, 2, 1), inventory)
        self.assertEqual(json.loads(self.save_path.read_text())["role_state"]["coin"], saved["role_state"]["coin"])
        self.replay([request])
        self.assertEqual(self.entity_records(self.query_world(1002), 1, 2)[7060], after)

    def test_quick_equip_replacement_preserves_training_and_protagonist(self):
        saved = self.seed_training_account()
        player.apply_reward(saved, activities.build_reward(saved, "22204,1;", self.role_config), self.role_config, self.now)
        self.save_path.write_text(json.dumps(saved))
        world = self.query_world(1002)
        inventory = self.entity_records(world, 2, 1)
        previous = self.entity_records(world, 1, 2)[7059]
        old_armor = protocol.pb_get_varint(self.entity_records(world, 4, 1)[1], 5)
        armor = max(inventory)
        self.replay([self.activity_request(1007, [1, 1, 0, armor, 0, 0, 0, 0])])
        current = self.entity_records(self.query_world(1002), 1, 2)[7059]
        self.assertNotEqual(current, previous)
        snapshot = bytes.fromhex(json.loads(self.save_path.read_text())["protagonist_snapshot"])
        self.assertEqual(next(v for n, w, v in protocol.iter_pb_fields(snapshot) if n == 10), current)
        self.replay([self.activity_request(1007, [1, 1, 0, old_armor, 0, 0, 0, 0])])
        restored = self.entity_records(self.query_world(1002), 1, 2)[7059]
        self.assertEqual(dict((n, v) for n, w, v in protocol.iter_pb_fields(restored)),
                         dict((n, v) for n, w, v in protocol.iter_pb_fields(previous)))
        final = json.loads(self.save_path.read_text())
        self.assertEqual(final["role_state"]["power"], saved["role_state"]["power"])
        self.assertEqual(self.entity_records(self.query_world(1002), 2, 1), inventory)

    def test_quick_equip_invalid_batch_and_failed_save_are_atomic(self):
        self.complete_tutorial()
        valid = [2, 1, 10719, 10740, 10741, 10742, 0, 0]
        cases = [[], valid[:-1], valid + [0], [2, 2] + valid[2:],
                 [4, 1] + valid[2:], [0, 1] + valid[2:],
                 [2, 1, 987654] + valid[3:], [2, 1, 10726] + valid[3:],
                 [2, 1, 10719, 10719, 10741, 10742, 0, 0],
                 [2, 1, 10719, 10740, 10741, 10742, 10744, 0]]
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            memory, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
            bodies = [bytes.fromhex(self.activity_request(1007, ids)["hex"]) for ids in cases]
            bodies += [b"\x08", b"\x0a\x01\x02", bytes.fromhex(self.activity_request(1007, valid)["hex"]) + b"\x10\x01"]
            for body in bodies:
                with self.subTest(body=body.hex()):
                    packet = session.handle(1007, 20000, body)[0]
                    self.assertEqual(struct.unpack(">IIII", packet[:16])[2], 999999)
                    self.assertEqual(session.save, memory)
                    self.assertEqual(self.save_path.read_bytes(), disk)
            with patch.object(player.os, "replace", side_effect=OSError("disk full")):
                with self.assertRaises(OSError):
                    session.handle(1007, 20001, bytes.fromhex(self.activity_request(1007, valid)["hex"]))
            self.assertEqual(session.save, memory)
            self.assertEqual(self.save_path.read_bytes(), disk)

    def test_quick_equip_rejects_advanced_items_and_obsolete_tutorial(self):
        self.complete_tutorial()
        saved = json.loads(self.save_path.read_text())
        item = self.entity_records(bytes.fromhex(saved["world_state"]["1002"]), 2, 1)[10719]
        ids = protocol.parse_ids_pb(item)
        ids[3] = 1
        advanced = b"".join(protocol.encode_pb_field(1, 0, v) for v in ids)
        player.record_slot_update(saved, protocol.encode_pb_field(2, 2, advanced))
        self.save_path.write_text(json.dumps(saved))
        before = self.save_path.read_bytes()
        reply = self.replay([self.activity_request(1007, [2, 1, 10719, 0, 0, 0, 0, 0])])
        self.assert_unavailable_response(reply, 1007, 20000, "进阶")
        for request in self.requests:
            if request["opcode"] == 999900 and 1007 in protocol.get_comb_ids(bytes.fromhex(request["hex"])):
                self.assert_unavailable_response(self.replay([request]), 999900, request["seq"], "录制已过期")
        self.assertEqual(self.save_path.read_bytes(), before)

    def test_formation_replacement_inherits_equipment_and_is_reversible(self):
        self.complete_tutorial()
        saved = json.loads(self.save_path.read_text())
        player.apply_reward(saved, recruit.build_reward(saved, [(10401, 1)], self.role_config), self.role_config, self.now)
        self.save_path.write_text(json.dumps(saved))
        before = self.entity_records(self.query_world(1002), 1, 2)
        slots = self.entity_records(self.query_world(1002), 4, 1)
        iid = next(k for k, v in before.items() if protocol.pb_get_varint(v, 1) == 10401)
        old_iid = protocol.pb_get_varint(slots[3], 2)
        replies = self.replay([self.change_general_request(3, iid)])
        self.assertEqual([r["opcode"] for r in replies[:2]], [1003, 205])
        current = self.entity_records(self.query_world(1002), 4, 1)
        self.assertEqual(protocol.pb_get_varint(current[3], 2), iid)
        self.assertEqual([protocol.pb_get_varint(current[3], i) for i in range(4, 10)],
                         [protocol.pb_get_varint(slots[3], i) for i in range(4, 10)])
        self.assertGreater(protocol.pb_get_varint(self.entity_records(self.query_world(1002), 1, 2)[iid], 6),
                           protocol.pb_get_varint(before[iid], 6))
        self.replay([self.change_general_request(3, old_iid)])
        after = self.entity_records(self.query_world(1002), 1, 2)
        for key in before:
            self.assertEqual(dict((n, v) for n, w, v in protocol.iter_pb_fields(after[key])),
                             dict((n, v) for n, w, v in protocol.iter_pb_fields(before[key])))
        self.replay([self.activity_request(1009, [2, 1, 0, 0, 0, 0, 0])])
        current = self.entity_records(self.query_world(1002), 4, 1)
        self.assertEqual(protocol.pb_get_varint(current[2], 2), protocol.pb_get_varint(slots[1], 2))
        self.assertEqual(protocol.pb_get_varint(current[2], 4), protocol.pb_get_varint(slots[1], 4))
        self.assertEqual(self.entity_records(self.query_world(1002), 1, 2), after)

    def test_formation_invalid_locked_duplicate_and_failed_save_are_atomic(self):
        self.complete_tutorial()
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            memory, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
            requests = [self.change_general_request(1, 0), self.change_general_request(2, 987654),
                        self.change_general_request(4, 7060), self.activity_request(1009, [2, 2, 0, 0, 0, 0, 0]),
                        self.activity_request(1009, [2, 1]), {"opcode": 1003, "seq": 20000, "hex": "080210011800"}]
            for request in requests:
                packet = session.handle(request["opcode"], request["seq"], bytes.fromhex(request["hex"]))[0]
                self.assertEqual(struct.unpack(">IIII", packet[:16])[2], 999999)
                self.assertEqual(session.save, memory)
                self.assertEqual(self.save_path.read_bytes(), disk)
            with patch.object(player.os, "replace", side_effect=OSError("disk full")):
                with self.assertRaises(OSError):
                    session.handle(1009, 20001, bytes.fromhex(self.activity_request(1009, [2, 1, 0, 0, 0, 0, 0])["hex"]))
            self.assertEqual(session.save, memory)
            self.assertEqual(self.save_path.read_bytes(), disk)

    def test_formation_relation_growth_survives_battle_and_unequip(self):
        self.complete_tutorial()
        saved = json.loads(self.save_path.read_text())
        raw = recruit.new_general(10213, 2000001, self.role_config)
        # Replace the tutorial thunder general with a fresh one to measure exact growth.
        player.record_slot_update(saved, protocol.encode_pb_field(1, 2, raw))
        self.save_path.write_text(json.dumps(saved))
        self.replay([self.change_general_request(2, 2000001)])
        with patch.object(player.random, "getrandbits", return_value=42):
            result = self.replay([self.activity_request(1306, [42102, 2])])[0]
        self.assertEqual(result["opcode"], 1306)
        self.assertEqual(protocol.pb_get_varint(bytes.fromhex(result["hex"]), 1), 1)
        self.replay([self.change_general_request(2, 7060)])
        changed = self.entity_records(self.query_world(1002), 1, 2)[2000001]
        level = protocol.pb_get_varint(changed, 3)
        self.assertGreater(level, 1)
        row = self.role_config["general"]["10213"]
        self.assertEqual(protocol.pb_get_varint(changed, 6), row["atk"] + row["atk-grow"] * (level - 1))

    def test_old_training_and_advancement_cannot_revert_newer_growth(self):
        self.replay_through(138)
        self.assert_rejected(self.by_seq[131], "已过期的主角培养")
        self.assert_rejected(self.by_seq[133], "已过期的主角进阶")

    def test_tutorial_reconnect_after_every_request_keeps_world_state(self):
        self.replay(self.requests)
        expected = {opcode: self.query_world(opcode) for opcode in player.WORLD_QUERY_IDS}
        expected_role = json.loads(self.save_path.read_text())["role_state"]
        self.save_path.unlink()
        for request in self.requests:
            self.replay([request], chunk_size=7)
            self.replay([dict(self.by_seq[12], seq=30000)])
        for opcode, body in expected.items():
            with self.subTest(opcode=opcode):
                self.assertEqual(self.query_world(opcode), body)
        self.assertEqual(json.loads(self.save_path.read_text())["role_state"], expected_role)

    def test_first_battle_restores_state_pushes_in_recorded_order(self):
        responses = self.replay([dict(self.by_seq[36], seq=10000)], chunk_size=7)
        self.assertEqual([f["opcode"] for f in responses], [1027, 205, 1024, 999900])
        self.assertEqual(responses, self.expected_group(36, 10000))

    def test_state_push_after_response_stays_after_response(self):
        responses = self.replay([dict(self.by_seq[97], seq=10000)])
        self.assertEqual([f["opcode"] for f in responses], [999900, 205])
        self.assertEqual(responses, self.expected_group(97, 10000))

    def test_ordinary_exact_and_fallback_restore_state_pushes(self):
        for seq in (133, 10000):
            with self.subTest(seq=seq):
                save = player.get_default_save()
                save["role_snapshot"] = self.recorded[(111, 1001)]["hex"]
                self.save_path.write_text(json.dumps(save))
                responses = self.replay([dict(self.by_seq[133], seq=seq)])
                self.assertEqual([f["opcode"] for f in responses], [205, 1057])
                self.assertEqual(responses, self.expected_group(133, seq))
                self.assertEqual(json.loads(self.save_path.read_text())["silver"], 6720)

    def test_reply_after_another_request_is_not_lost(self):
        self.assertEqual([self.by_seq[seq]["opcode"] for seq in (91, 92)], [2000, 201])
        responses = self.replay([self.by_seq[91], self.by_seq[92]])
        self.assertEqual(len(responses), 2)
        self.assert_recorded_response(responses[0], 91)
        self.assert_recorded_response(responses[1], 92)

    def test_state_push_without_matching_reply_is_not_attached_to_request(self):
        push = self.expected_group(36)[1]
        frames = [self.by_seq[12], self.recorded[(12, 999900)], self.by_seq[36],
                  dict(push, c2s=False), dict(self.recorded[(36, 999900)], seq=999)]
        with redirect_stdout(io.StringIO()):
            self.tables = replay.build_routing_tables(frames)
        responses = self.replay([dict(self.by_seq[36], seq=10000)])
        self.assert_unavailable_response(responses, 999900, 10000, "关卡")
        self.assertFalse(self.save_path.exists())

    def test_combination_guide_progress_is_saved_and_returned_after_reconnect(self):
        self.replay([dict(self.by_seq[36], seq=10000)])
        self.assertTrue(self.save_path.exists())
        saved = json.loads(self.save_path.read_text())
        self.assertEqual(saved["guide"]["sections"]["1"], {"status": 1, "step": 8, "steps": [8]})
        responses = self.replay([{"opcode": 200, "seq": 20000, "hex": ""}])
        self.assertEqual(responses, [{"opcode": 200, "seq": 20000, "hex": "0a06080110011808"}])

    def test_standalone_and_combination_reports_share_step_history(self):
        self.replay([{"opcode": 201, "seq": 10000, "hex": "08011003"}, self.by_seq[11]])
        saved = json.loads(self.save_path.read_text())
        self.assertTrue(saved["has_role"])
        self.assertEqual(saved["guide"]["sections"]["1"], {"status": 1, "step": 4, "steps": [3, 4]})

    def test_combination_progress_preserves_legacy_save_history(self):
        save = player.get_default_save()
        save["guide"] = {"section": 1, "status": 0, "step": 7}
        self.save_path.write_text(json.dumps(save))
        self.replay([self.by_seq[36]])
        saved = json.loads(self.save_path.read_text())
        self.assertEqual(saved["guide"]["sections"]["1"], {"status": 1, "step": 8, "steps": [7, 8]})

    def test_completion_uses_configured_step_count(self):
        total = self.step_counts[1]
        for step, status in ((total - 1, 1), (total, 2)):
            body = b"\x08\x01\x10" + protocol.encode_varint(step)
            self.replay([{"opcode": 201, "seq": 10000, "hex": body.hex()}])
            saved = json.loads(self.save_path.read_text())
            self.assertEqual(saved["guide"]["sections"]["1"]["status"], status)

    def test_guide_tail_requires_both_display_steps_and_survives_reconnect(self):
        self.replay(self.requests)
        for step, status in ((81, 1), (82, 1), (83, 2)):
            with self.subTest(step=step):
                body = protocol.encode_pb_field(1, 0, 1) + protocol.encode_pb_field(2, 0, step)
                self.replay([{"opcode": 201, "seq": 20000, "hex": body.hex()}])
                response = self.replay([{"opcode": 200, "seq": 20001, "hex": ""}])[0]
                self.assertEqual(bytes.fromhex(response["hex"]), guide.build_guide_query_pb({"1": {"status": status, "step": step}}))

    def test_server_time_is_live_and_keeps_captured_timezone(self):
        timezone = protocol.parse_ids_pb(bytes.fromhex(self.recorded[(3, 999905)]["hex"]))[1]
        for offset, seq in ((0, 3), (17, 10000)):
            with self.subTest(offset=offset):
                self.clock.return_value = self.now + offset
                responses = self.replay([{"opcode": 999905, "seq": seq, "hex": ""}])
                self.assertEqual((responses[0]["opcode"], responses[0]["seq"]), (999905, seq))
                self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(responses[0]["hex"])), [self.now + offset, timezone])
        self.assertFalse(self.save_path.exists())

    def test_stamina_interval_is_consistent_with_all_captured_countdowns(self):
        samples = []
        for frame in self.frames:
            if frame["c2s"]:
                continue
            body = bytes.fromhex(frame["hex"])
            messages = protocol.get_comb_messages(body) if frame["opcode"] == 999900 else [(frame["opcode"], body)]
            for opcode, raw in messages:
                if opcode == 1001:
                    values = {n: v for n, w, v in protocol.iter_pb_fields(raw)}
                    missing = values[11] - values[10]
                    if missing > 1:
                        self.assertEqual(values[18] - values[17], (missing - 1) * 360)
                        samples.append(raw)
        self.assertTrue(samples)

    def test_legacy_stamina_does_not_recover_from_recorded_wall_clock(self):
        self.seed_stamina(0)
        role = self.query_role()
        self.assertEqual((role[10], role[17], role[18]), (0, 360, 50 * 360))
        snapshot = bytes.fromhex(self.recorded[(41, 1001)]["hex"])
        for field in (15, 16, 22):
            self.assertEqual(role.get(field), protocol.pb_get_varint(snapshot, field))

    def test_stamina_recovers_at_boundary_and_preserves_partial_interval(self):
        self.seed_stamina(0)
        self.query_role()
        for elapsed, amount, remaining in ((359, 0, 1), (360, 1, 360), (731, 2, 349)):
            with self.subTest(elapsed=elapsed):
                self.clock.return_value = self.now + elapsed
                role = self.query_role()
                self.assertEqual((role[10], role[17], role[18]), (amount, remaining, remaining + (50 - amount - 1) * 360))
                self.assertEqual(json.loads(self.save_path.read_text())["role_state"]["stamina"], amount)

    def test_stamina_offline_recovery_survives_reconnect_without_double_credit(self):
        self.seed_stamina(5)
        self.query_role()
        self.clock.return_value = self.now + 4 * 360 + 21
        first = self.query_role()
        second = self.query_role()
        self.assertEqual((first[10], first[17]), (9, 339))
        self.assertEqual((second[10], second[17]), (9, 339))
        init = self.replay([dict(self.by_seq[12], seq=30000)])[0]
        role = self.role_data(init)
        self.assertEqual((role[10], role[17], role[18]), (9, 339, 339 + 40 * 360))

    def test_stamina_recovery_caps_without_clamping_reward_overflow(self):
        for amount in (49, 50, 65):
            with self.subTest(amount=amount):
                self.clock.return_value = self.now
                self.seed_stamina(amount)
                self.query_role()
                self.clock.return_value = self.now + 100 * 360
                role = self.query_role()
                self.assertEqual((role[10], role[17], role[18]), (max(50, amount), 0, 0))

    def test_full_stamina_does_not_bank_recovery_before_battle(self):
        self.seed_stamina(50)
        self.query_role()
        self.clock.return_value = self.now + 100 * 360
        self.replay([self.by_seq[36]])
        role = self.query_role()
        self.assertEqual((role[10], role[11], role[17], role[18]), (49, 52, 360, 1080))

    def test_stamina_recovery_is_settled_before_battle_cost(self):
        self.seed_stamina(0)
        self.query_role()
        self.clock.return_value = self.now + 359
        self.assert_rejected(self.by_seq[36], "体力不足")
        self.clock.return_value = self.now + 360
        self.replay([self.by_seq[36]])
        role = self.query_role()
        self.assertEqual((role[10], role[17]), (0, 360))

    def test_stamina_deadline_survives_spending_in_same_session(self):
        self.seed_stamina(5)
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            session.handle(1001, 20000, b"")
            self.clock.return_value = self.now + 100
            request = self.by_seq[36]
            session.handle(request["opcode"], request["seq"], bytes.fromhex(request["hex"]))
            for elapsed, amount, remaining in ((100, 4, 260), (360, 5, 360), (360, 5, 360)):
                self.clock.return_value = self.now + elapsed
                packet = session.handle(1001, 20001, b"")[0]
                role = {n: v for n, w, v in protocol.iter_pb_fields(packet[16:])}
                self.assertEqual((role[10], role[17]), (amount, remaining))

    def test_recovered_stamina_and_battle_are_saved_before_first_push(self):
        self.seed_stamina(0)
        self.query_role()
        self.clock.return_value = self.now + 360
        conn = ReplayConnection([self.by_seq[36]], 7)
        sendall = conn.sendall

        def check_saved_before_send(packet):
            if struct.unpack(">I", packet[8:12])[0] == 1000:
                return sendall(packet)
            saved = json.loads(self.save_path.read_text())
            self.assertEqual((saved["role_state"]["stamina"], saved["level"]), (0, 2))
            self.assertEqual(saved["stamina_clock"]["next_at"], self.now + 720)
            self.assertEqual(saved["guide"]["sections"]["1"]["step"], 8)
            self.assertIn(50001, saved["achievement_state"]["completed"])
            self.assertEqual(protocol.pb_get_varint(bytes.fromhex(saved["role_snapshot"]), 17), 360)
            sendall(packet)

        conn.sendall = check_saved_before_send
        with redirect_stdout(io.StringIO()):
            self.run_client(conn)
        self.assertTrue(conn.closed)
        self.assertEqual(conn.responses[:-1], self.expected_group(36))
        self.assertEqual(self.hint_changes(conn.responses[-1]), {44: 1})

    def test_clock_rollback_does_not_grant_stamina_or_shorten_next_recovery(self):
        self.seed_stamina(0)
        self.query_role()
        self.clock.return_value = self.now + 400
        self.assertEqual(self.query_role()[10], 1)
        self.clock.return_value = self.now - 100
        role = self.query_role()
        self.assertEqual((role[10], role[17]), (1, 820))
        self.clock.return_value = self.now + 720
        self.assertEqual(self.query_role()[10], 2)

    def test_stamina_recovery_save_failure_keeps_original_and_emits_no_success(self):
        self.seed_stamina(0)
        self.query_role()
        self.clock.return_value = self.now + 360
        for request in (dict(self.by_seq[41], seq=20000), self.by_seq[36]):
            with self.subTest(opcode=request["opcode"]), patch.object(player.os, "replace", side_effect=OSError("disk failure")):
                self.assert_rejected(request, "保存失败")
        self.assertEqual(self.query_role()[10], 1)

    def test_invalid_stamina_clock_is_not_overwritten(self):
        self.seed_stamina(0)
        original = json.loads(self.save_path.read_text())
        for invalid in ([], {}, None, {"next_at": self.now + 360},
                        {"next_at": -1, "checked_at": self.now},
                        {"next_at": self.now + 360, "checked_at": True},
                        {"next_at": "old", "checked_at": self.now}):
            with self.subTest(invalid=invalid):
                saved = json.loads(json.dumps(original))
                saved["stamina_clock"] = invalid
                self.save_path.write_text(json.dumps(saved))
                self.assert_rejected(dict(self.by_seq[41], seq=20000), "体力计时存档无效")

    def test_malformed_time_query_does_not_change_save(self):
        self.seed_stamina(0)
        self.query_role()
        self.clock.return_value = self.now + 360
        self.assert_rejected({"opcode": 999905, "seq": 20000, "hex": "0801"}, "时间查询不接受参数")

    def test_late_guide_reports_do_not_rewind_or_reopen_completed_sections(self):
        for saved_step, saved_status in ((82, 1), (83, 2), (81, 2)):
            with self.subTest(saved_step=saved_step, saved_status=saved_status):
                saved = player.get_default_save()
                saved["guide"]["sections"]["1"] = {"status": saved_status, "step": saved_step, "steps": [saved_step]}
                self.save_path.write_text(json.dumps(saved))
                self.replay([{"opcode": 201, "seq": 20000, "hex": "08011050"}])
                section = json.loads(self.save_path.read_text())["guide"]["sections"]["1"]
                self.assertEqual((section["step"], section["status"]), (saved_step, saved_status))
                self.assertIn(80, section["steps"])

    def test_guide_report_outside_config_cannot_complete_section(self):
        self.replay_through(12)
        for section, step in ((1, self.step_counts[1] + 1), (99999, 1)):
            with self.subTest(section=section, step=step):
                body = protocol.encode_pb_field(1, 0, section) + protocol.encode_pb_field(2, 0, step)
                self.assert_rejected({"opcode": 201, "seq": 20000, "hex": body.hex()}, "引导上报超出配置")

    def test_recorded_activity_rewards_are_generated_and_persisted(self):
        self.replay(self.requests)
        previous = json.loads(self.save_path.read_text())
        for frame in self.activity_frames["rewards"]:
            request = {"opcode": frame["opcode"], "seq": frame["seq"], "hex": frame["request"]}
            response = self.replay([request])[0]
            actual = bytes.fromhex(response["hex"])
            expected = bytes.fromhex(frame["response"])
            if frame["opcode"] == 3611 and protocol.parse_ids_pb(bytes.fromhex(frame["request"])) == [80030]:
                actual_equip = next(v for n, w, v in protocol.iter_pb_fields(actual) if n == 6)
                expected_equip = next(v for n, w, v in protocol.iter_pb_fields(expected) if n == 6)
                self.assertEqual(protocol.parse_ids_pb(actual_equip)[1:], protocol.parse_ids_pb(expected_equip)[1:])
                self.assertGreater(protocol.parse_ids_pb(actual_equip)[0], 1000000)
                self.assertEqual([(n,w,v) for n,w,v in protocol.iter_pb_fields(actual) if n != 6],
                                 [(n,w,v) for n,w,v in protocol.iter_pb_fields(expected) if n != 6])
            else:
                self.assertEqual(actual, expected)
        saved = json.loads(self.save_path.read_text())
        self.assertEqual(saved["silver"] - previous["silver"], 32000)
        self.assertEqual(saved["gold"] - previous["gold"], 150)
        props = self.entity_records(self.query_world(1200), 1, 1)
        self.assertEqual(protocol.pb_get_varint(props[20014], 2), 1)
        equips = self.entity_records(self.query_world(1002), 2, 1)
        self.assertTrue(any(protocol.parse_ids_pb(equip)[1] == 22204 and iid > 1000000 for iid, equip in equips.items()))

    def test_activity_fixture_frames_match_raw_capture(self):
        capture = (Path(server.BASE_DIR) / self.activity_frames["source"]).read_bytes()
        # These selected replies each fit in one captured TCP segment.
        for frame in self.activity_frames["queries"] + self.activity_frames["rewards"]:
            with self.subTest(opcode=frame["opcode"], seq=frame["seq"]):
                packet = protocol.pack_frame(frame["opcode"], frame["seq"], bytes.fromhex(frame["response"]))
                self.assertTrue(packet in capture, "fixture does not match its source capture")

    def test_activity_claims_are_rejected_when_locked_or_repeated(self):
        self.replay_through(12)
        for values in ((80030,), (80015,), (80002,)):
            with self.subTest(values=values):
                before = self.save_path.read_bytes()
                self.assert_unavailable_response(self.replay([self.activity_request(3611, values)]),
                                                 3611, 20000, "活动奖励未解锁或不支持")
                self.assertEqual(self.save_path.read_bytes(), before)
        for values in ((), (116,)):
            before = self.save_path.read_bytes()
            self.assert_unavailable_response(self.replay([self.activity_request(2411, values)]),
                                             2411, 20000, "活动奖励未解锁或不支持")
            self.assertEqual(self.save_path.read_bytes(), before)
        self.replay([self.activity_request(3611, (80001,))])
        before = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([self.activity_request(3611, [80001])]), 3611, 20000, "已领取")
        self.assertEqual(self.save_path.read_bytes(), before)
        self.replay([f for f in self.requests if f["seq"] > 12])
        self.replay([self.activity_request(3611, [80030]), self.activity_request(2411, [116])])
        before = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([self.activity_request(3611, [80030])]), 3611, 20000, "已领取")
        self.assertEqual(self.save_path.read_bytes(), before)
        for values in ((), (116,)):
            self.assert_unavailable_response(self.replay([self.activity_request(2411, values)]),
                                             2411, 20000, "活动奖励已领取")
            self.assertEqual(self.save_path.read_bytes(), before)

    def liveness_task(self, task):
        values = protocol.parse_ids_pb(self.query_world(2410))
        return values[task - 1], values[len(values) // 2 + task - 1]

    def prepare_liveness(self):
        self.save_path.unlink(missing_ok=True)
        saved = self.seed_shop_account()
        day = (self.now + 28800) // 86400
        saved["role_state"].update(level=21, vip=3, stamina=1000, energy=30)
        saved["activity_state"].update(liveness_day=day, liveness_week=(day + 3) // 7, liveness_week_score=0,
                                       liveness_counts={}, liveness_claimed=[], liveness_boxes=[], strengthen_count=0)
        self.save_path.write_text(json.dumps(saved))
        return saved

    def test_liveness_stamina_battle_and_sweep_count_actual_cost_once(self):
        saved = self.prepare_liveness()
        with redirect_stdout(io.StringIO()), patch.object(player.random, "getrandbits", return_value=42):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            body = recharge.ids([42102, 2])
            packets = session.handle(1306, 31000, body)
            self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 1306)
            self.assertEqual(session.handle(1306, 31000, body), packets)
        self.assertEqual(self.liveness_task(1), (0, 2))
        player.record_copy_win(saved, recharge.ids([42102, 1]), 3, self.role_config, allow_repeat=True)
        saved["role_state"]["stamina"] = 7
        self.save_path.write_text(json.dumps(saved))
        self.assertEqual(self.replay([self.activity_request(1307, [42102, 1, 1, 0])])[0]["opcode"], 1307)
        self.assertEqual(self.liveness_task(1), (0, 6))
        self.clock.return_value += 360
        self.query_role()
        self.give_props({20014: 1})
        self.replay([self.activity_request(1201, [20014, 1])])
        self.assertEqual(self.liveness_task(1), (0, 6))

    def test_liveness_tutorial_stamina_uses_every_actual_battle_cost(self):
        self.replay(self.requests)
        total = 0
        for request in self.requests:
            raw = bytes.fromhex(request["hex"])
            messages = protocol.get_comb_messages(raw) if request["opcode"] == 999900 else [(request["opcode"], raw)]
            for opcode, body in messages:
                if opcode == 1306:
                    map_id, point_id = protocol.parse_ids_pb(body)
                    total += self.role_config["copy"][str(map_id)][str(point_id)]["physical"]
        self.assertGreater(total, 0)
        self.assertEqual(self.liveness_task(1), (0, total))

    def test_liveness_batch_strengthening_counts_paid_attempts_not_critical_levels(self):
        self.seed_training_account(vip=3)
        with patch.dict(self.role_config["liveness"]["16"], num=100), patch.object(player.random, "getrandbits", return_value=0):
            response = self.replay([self.training_request(1101, 10726, (1,))])[0]
            body = bytes.fromhex(response["hex"])
            critical = sum(protocol.parse_ids_pb(next(v for n, w, v in protocol.iter_pb_fields(body) if n == 12)))
            self.assertGreater(critical, 0)
            self.assertEqual(self.liveness_task(16), (0, 5 - critical))

    def test_liveness_watchstar_counts_collections_not_queries_or_rerolls(self):
        self.prepare_watchstar()
        self.query_world(2062)
        self.assertEqual(self.liveness_task(8), (0, 0))
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            for index in range(3):
                session.handle(2063, 31000 + index * 2, b"")
                packets = session.handle(2065, 31001 + index * 2, b"")
                self.assertEqual(session.handle(2065, 31001 + index * 2, b""), packets)
            memory = copy.deepcopy(session.save)
            self.assertEqual(struct.unpack(">IIII", session.handle(2065, 31010, b"")[0][:16])[2], 999999)
            self.assertEqual(session.save, memory)
        self.assertEqual(self.liveness_task(8), (1, 3))

    def test_liveness_shop_purchases_count_but_refreshes_do_not(self):
        for prepare, query, purchase, refresh, task in ((self.prepare_qiankun, 3650, 3651, 3652, 37),
                                                        (self.prepare_blackmarket, 3630, 3631, 3632, 48)):
            with self.subTest(task=task):
                self.save_path.unlink(missing_ok=True)
                prepare()
                self.query_world(query)
                self.assertEqual(self.liveness_task(task), (0, 0))
                self.assertEqual(self.replay([self.activity_request(purchase, [1, 1])])[0]["opcode"], purchase)
                self.replay([self.activity_request(refresh)])
                self.assertEqual(self.liveness_task(task), (1, 1))

    def test_liveness_recruit_counts_draws_and_fengshen_only_after_claim(self):
        self.prepare_liveness()
        self.give_props({20100: 100})
        self.replay([self.activity_request(1403, [1, 2])])
        self.assertEqual(self.liveness_task(11), (1, 10))
        self.prepare_liveness()
        self.replay([self.activity_request(7111), self.activity_request(7112)])
        self.assertEqual(self.liveness_task(11), (0, 0))
        self.replay([self.activity_request(7113)])
        self.assertEqual(self.liveness_task(11), (1, 10))

    def test_liveness_gold_spend_counts_outside_consumption_event(self):
        saved = self.prepare_liveness()
        saved["role_snapshot"] = protocol.pb_set_varint(bytes.fromhex(saved["role_snapshot"]), 22,
                                                        self.now - 40 * 86400).hex()
        saved["activity_state"]["gold_spent"] = 0
        self.save_path.write_text(json.dumps(saved))
        self.replay([self.activity_request(1403, [4, 1])])
        self.assertEqual(self.liveness_task(14), (1, 500))
        self.assertEqual(json.loads(self.save_path.read_text())["activity_state"]["gold_spent"], 0)

    def test_liveness_mieshendian_counts_real_battles_and_completed_sweep(self):
        self.prepare_mieshendian()
        self.query_world(3620)
        self.assertEqual(self.liveness_task(3), (0, 0))
        self.replay([self.activity_request(3621, [1])])
        self.assertEqual(self.liveness_task(3), (1, 1))
        saved = json.loads(self.save_path.read_text())
        saved["activity_state"]["liveness_counts"].pop("3")
        saved["mieshendian_state"].update(floor=1, failcount=0, star=0, earned=0, maxfloor=5, maxstar=5,
                                         best={str(i): 1 for i in range(1, 6)}, sweep=None)
        saved["role_state"]["vip"] = 3
        self.save_path.write_text(json.dumps(saved))
        self.assertEqual(self.replay([self.activity_request(3623)])[0]["opcode"], 3623)
        self.assertEqual(self.liveness_task(3), (0, 0))
        self.clock.return_value += 5 * int(self.role_config["global_kv"]["mieshendian_saodang_time"]["value"])
        self.assertEqual(self.replay([self.activity_request(3620)])[0]["opcode"], 3620)
        self.assertEqual(self.liveness_task(3), (1, 1))

    def test_liveness_treasure_ten_counts_actual_losses_not_button_taps(self):
        saved = self.prepare_liveness()
        for raw in self.entity_records(bytes.fromhex(saved["world_state"]["1002"]), 1, 2).values():
            for field, value in ((6, 1), (7, 0), (8, 1), (9, 1)):
                raw = protocol.pb_set_varint(raw, field, value)
            player.record_slot_update(saved, protocol.encode_pb_field(1, 2, raw))
            player.record_protagonist_general(saved, raw)
        saved["role_state"]["energy"] = 3
        self.save_path.write_text(json.dumps(saved))
        target = rob.NPC_BASE + 28001 * 3
        request = self.activity_request(1114, [target])
        replies = self.replay([request, request])
        self.assertEqual(replies[0], replies[1])
        self.assertEqual(json.loads(self.save_path.read_text())["last_rob"]["attempts"], 3)
        self.assertEqual(self.liveness_task(9), (0, 3))
        disk = self.save_path.read_bytes()
        self.assertEqual(self.replay([self.activity_request(1114, [target])])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), disk)

    def test_liveness_legacy_migration_preserves_claims_without_backfilling(self):
        saved = self.prepare_liveness()
        state = saved["activity_state"]
        for key in ("liveness_day", "liveness_week", "liveness_week_score", "liveness_counts", "liveness_boxes"):
            state.pop(key)
        state.update(strengthen_count=4, liveness_claimed=[16])
        self.save_path.write_text(json.dumps(saved))
        self.assertEqual(self.liveness_task(16), (2, 4))
        self.assertEqual(self.liveness_task(1), (0, 0))
        self.assertEqual(protocol.parse_ids_pb(self.query_world(6517))[0], 5)
        disk = self.save_path.read_bytes()
        self.assertEqual(self.replay([self.activity_request(2411, [116])])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), disk)
        self.clock.return_value += 86400
        self.assertEqual(self.liveness_task(16), (0, 0))
        self.assertEqual(protocol.parse_ids_pb(self.query_world(6517))[0], 5)

    def test_liveness_queries_and_claims_failed_saves_are_atomic(self):
        baseline = self.prepare_liveness()
        for task in (1, 3, 8, 9):
            activities.record_liveness(baseline, task, self.role_config["liveness"][str(task)]["num"], self.role_config, self.now)
        for opcode, body, claimed, tomorrow in ((2411, b"", False, False), (2411, recharge.ids([101]), False, False),
                                                (2411, recharge.ids([1]), True, False), (2410, b"", True, True),
                                                (6517, b"", True, True)):
            with self.subTest(opcode=opcode, body=body, tomorrow=tomorrow), redirect_stdout(io.StringIO()):
                saved = copy.deepcopy(baseline)
                if claimed:
                    saved["activity_state"].update(liveness_claimed=[1, 3, 8, 9], liveness_week_score=25)
                self.save_path.write_text(json.dumps(saved))
                self.clock.return_value = self.now + 86400 if tomorrow else self.now
                session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
                memory, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
                with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
                    session.handle(opcode, 31000, body)
                self.assertEqual((session.save, self.save_path.read_bytes()), (memory, disk))

    def test_liveness_corrupt_progress_and_score_overflow_fail_closed(self):
        baseline = self.prepare_liveness()
        for key, value in (("liveness_day", True), ("liveness_week", -1), ("liveness_week_score", 1 << 31),
                           ("liveness_counts", {"2": 1}), ("liveness_counts", {"1": -1}),
                           ("liveness_counts", []), ("liveness_boxes", [1, 1]), ("liveness_boxes", [0])):
            with self.subTest(key=key, value=value), redirect_stdout(io.StringIO()):
                saved = copy.deepcopy(baseline)
                saved["activity_state"][key] = value
                self.save_path.write_text(json.dumps(saved))
                disk = self.save_path.read_bytes()
                with self.assertRaises(ValueError):
                    Session(self.tables, self.save_path, self.step_counts, self.role_config)
                self.assertEqual(self.save_path.read_bytes(), disk)
        baseline["activity_state"].update(liveness_counts={"1": 100}, liveness_week_score=(1 << 31) - 1)
        self.save_path.write_text(json.dumps(baseline))
        disk = self.save_path.read_bytes()
        self.assertEqual(self.replay([self.activity_request(2411, [101])])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), disk)

    def test_liveness_reward_overflow_rolls_back_all_tasks_and_boxes(self):
        baseline = self.prepare_liveness()
        for task in (1, 3, 8, 9):
            activities.record_liveness(baseline, task, self.role_config["liveness"][str(task)]["num"], self.role_config, self.now)
        baseline["role_state"]["coin"] = (1 << 63) - 1
        for body in (b"", recharge.ids([101]), recharge.ids([1])):
            with self.subTest(body=body), redirect_stdout(io.StringIO()):
                saved = copy.deepcopy(baseline)
                if body == recharge.ids([1]):
                    saved["activity_state"].update(liveness_claimed=[1, 3, 8, 9], liveness_week_score=25)
                self.save_path.write_text(json.dumps(saved))
                session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
                before, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
                self.assertEqual(struct.unpack(">IIII", session.handle(2411, 31000, body)[0][:16])[2], 999999)
                self.assertEqual((session.save, self.save_path.read_bytes()), (before, disk))

    def test_liveness_projection_does_not_mutate_or_settle_role(self):
        saved = self.prepare_liveness()
        saved["activity_state"].update(strengthen_count=4, liveness_claimed=[16])
        before = copy.deepcopy(saved)
        flags, counts, _ = activities.liveness_statuses(saved, self.role_config, self.now + 86400)
        self.assertEqual((flags[16], counts[16]), (0, 0))
        self.assertEqual(saved, before)

    def test_liveness_claim_all_includes_sign_and_rejects_unsupported_or_malformed_claims(self):
        self.seed_welfare_account()
        self.replay([self.activity_request(3642)])
        saved = json.loads(self.save_path.read_text())
        activities.record_liveness(saved, 1, 100, self.role_config, self.now)
        activities.record_liveness(saved, 16, 4, self.role_config, self.now)
        self.save_path.write_text(json.dumps(saved))
        self.replay([self.activity_request(2411)])
        self.assertEqual(protocol.parse_ids_pb(self.query_world(6517))[0], 20)
        for task in (1, 7, 16):
            self.assertEqual(self.liveness_task(task)[0], 2)
        disk = self.save_path.read_bytes()
        for body in (recharge.ids([102]), recharge.ids([3]), recharge.ids([100]), recharge.ids([101, 116]), b"\x0a\x01\x01"):
            self.assertEqual(self.replay([{"opcode": 2411, "seq": 31000, "hex": body.hex()}])[0]["opcode"], 999999)
            self.assertEqual(self.save_path.read_bytes(), disk)

    def test_liveness_daily_claims_boxes_and_week_reset(self):
        saved = self.prepare_liveness()
        for task in (1, 3, 8, 9, 11, 14, 16, 23, 37, 48):
            activities.record_liveness(saved, task, self.role_config["liveness"][str(task)]["num"], self.role_config, self.now)
        self.save_path.write_text(json.dumps(saved))
        self.replay([self.activity_request(2411)])
        self.assertEqual(protocol.parse_ids_pb(self.query_world(6517))[0], 60)
        flags = [v for n, w, v in protocol.iter_pb_fields(self.query_world(2410)) if (n, w) == (2, 0)]
        self.assertEqual(flags, [1, 1, 0, 0, 0])
        for box in (1, 2):
            request = self.activity_request(2411, [box])
            before = json.loads(self.save_path.read_text())
            self.assertEqual(self.replay([request])[0]["opcode"], 2411)
            after = json.loads(self.save_path.read_text())
            expected = activities.build_reward(before, self.role_config["liveness_reward"][str(box)]["reward"], self.role_config)
            player.apply_reward(before, expected, self.role_config, self.now)
            self.assertEqual((after["world_state"], after["role_state"]), (before["world_state"], before["role_state"]))
            disk = self.save_path.read_bytes()
            self.assertEqual(self.replay([request])[0]["opcode"], 999999)
            self.assertEqual(self.save_path.read_bytes(), disk)
        self.assertEqual(self.hint_map(self.query_world(1032))[40], 0)
        self.clock.return_value += 86400
        self.assertEqual(self.liveness_task(16), (0, 0))
        self.assertEqual(self.liveness_task(1), (0, 0))
        self.assertEqual(protocol.parse_ids_pb(self.query_world(6517))[0], 60)
        self.clock.return_value = self.now
        self.assertEqual(self.liveness_task(16), (0, 0))
        self.assertEqual(self.replay([self.activity_request(2411, [116])])[0]["opcode"], 999999)
        self.clock.return_value = self.now + 7 * 86400
        self.assertEqual(protocol.parse_ids_pb(self.query_world(6517))[0], 0)

    def test_liveness_empty_claim_saves_once_and_restores_queries(self):
        self.replay(self.requests)
        before = self.query_role()[8]
        expected = next(f["response"] for f in self.activity_frames["rewards"] if f["opcode"] == 2411)
        coin = protocol.pb_get_varint(bytes.fromhex(expected), 1)
        request = self.activity_request(2411)
        conn = ReplayConnection([request, request, self.activity_request(2410), self.activity_request(6517)], 7)
        send = conn.sendall

        def check_committed(packet):
            saved = json.loads(self.save_path.read_text())
            self.assertEqual(saved["activity_state"]["liveness_claimed"], [16])
            self.assertEqual(saved["role_state"]["coin"], before + coin)
            send(packet)

        conn.sendall = check_committed
        with redirect_stdout(io.StringIO()):
            self.run_client(conn)
        self.assertTrue(conn.closed)
        self.assertEqual([f["opcode"] for f in conn.responses], [2411, 1034, 999999, 1999, 2410, 6517])
        self.assertEqual(conn.responses[0]["hex"], expected)
        self.assertEqual(self.hint_changes(conn.responses[1]), {40: 0})
        self.assert_unavailable_response(conn.responses[2:4], 2411, 20000, "已领取")
        liveness = [v for n, w, v in protocol.iter_pb_fields(bytes.fromhex(conn.responses[4]["hex"])) if n == 1]
        self.assertEqual(liveness[15], 2)
        self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(conn.responses[5]["hex"])), [5, 0, 0, 0, 0])
        for response in conn.responses[4:]:
            self.assertEqual(self.query_world(response["opcode"]).hex(), response["hex"])
        self.assertEqual(self.query_role()[8], before + coin)
        disk = self.save_path.read_bytes()
        for values in ((), (116,)):
            self.assert_unavailable_response(self.replay([self.activity_request(2411, values)]),
                                             2411, 20000, "已领取")
            self.assertEqual(self.save_path.read_bytes(), disk)

    def test_liveness_empty_claim_overflow_and_save_failure_are_atomic(self):
        self.replay(self.requests)
        baseline = json.loads(self.save_path.read_text())
        for overflow in (False, True):
            with self.subTest(overflow=overflow), redirect_stdout(io.StringIO()):
                saved = copy.deepcopy(baseline)
                if overflow:
                    saved["role_state"]["coin"] = (1 << 63) - 1
                self.save_path.write_text(json.dumps(saved))
                session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
                memory, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
                if overflow:
                    packets = session.handle(2411, 20000, b"")
                    self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in packets], [999999, 1999])
                else:
                    with patch.object(player.os, "replace", side_effect=OSError("disk full")):
                        with self.assertRaises(OSError):
                            session.handle(2411, 20000, b"")
                self.assertEqual(session.save, memory)
                self.assertEqual(self.save_path.read_bytes(), disk)

    def test_activity_queries_restore_claim_flags_and_liveness_score(self):
        self.replay(self.requests)
        before = self.begin7day_groups(self.query_world(3610))
        recorded_before = self.begin7day_groups(bytes.fromhex(self.activity_frames["queries"][0]["response"]))
        self.assertEqual((before[0], before[1][0], before[1][29]), (recorded_before[0], 1, 1))
        for opcode, values in ((3611, (80001,)), (3611, (80030,)), (2411, (116,))):
            self.replay([self.activity_request(opcode, values)])
        after = self.begin7day_groups(self.query_world(3610))
        self.assertEqual((after[1][0], after[1][29]), (2, 2))
        liveness = [v for n,w,v in protocol.iter_pb_fields(self.query_world(2410)) if n == 1]
        recorded = [v for n,w,v in protocol.iter_pb_fields(bytes.fromhex(self.activity_frames["queries"][3]["response"])) if n == 1]
        self.assertEqual(len(liveness), len(recorded))
        self.assertEqual((liveness[15], liveness[len(liveness)//2+15]), (2, 4))
        self.assertEqual(self.query_world(6517).hex(), self.activity_frames["queries"][5]["response"])
        init = self.replay([dict(self.by_seq[12], seq=30000)])[0]
        restored = dict(protocol.get_comb_messages(bytes.fromhex(init["hex"])))[3610]
        self.assertEqual(restored, self.query_world(3610))

    def test_begin7day_uses_local_calendar_day_and_confirmed_recharge(self):
        self.complete_tutorial()
        self.replay([self.activity_request(3611, [80001])])
        order = self.recharge_order(1)
        self.assertEqual(self.begin7day_groups(self.query_world(3610))[2][0], 0)
        self.replay([self.activity_request(116, [order])])
        groups = self.begin7day_groups(self.query_world(3610))
        self.assertEqual((groups[2][0], groups[1][7]), (25, 0))
        order = self.recharge_order(1)
        paid = self.replay([self.activity_request(116, [order])])
        self.assertEqual([self.hint_changes(f) for f in paid if f["opcode"] == 1034], [{82: 1}])
        self.replay([self.activity_request(116, [order])])
        groups = self.begin7day_groups(self.query_world(3610))
        self.assertEqual((groups[0], groups[2][0], groups[1][7]), ([1], 50, 1))
        midnight = (self.now + 8 * 3600) // 86400 * 86400 - 8 * 3600 + 86400
        self.clock.return_value = midnight - 1
        self.assertEqual(self.begin7day_groups(self.query_world(3610))[1][1], 0)
        self.clock.return_value = midnight
        groups = self.begin7day_groups(self.query_world(3610))
        self.assertEqual((groups[0], groups[1][:3], groups[2][0]), ([2], [2, 1, 0], 50))
        self.assertEqual(self.hint_map(self.query_world(1032))[86], 1)

    def test_begin7day_daily_generals_and_claims_survive_reconnect(self):
        self.complete_tutorial()
        before = self.query_role()
        for day, reward_id, cid, gold in ((2, 80002, 10404, 100), (7, 80007, 10616, 400)):
            with self.subTest(day=day):
                self.clock.return_value = self.now + (day - 1) * 86400
                reply = self.replay([self.activity_request(3611, [reward_id])])[0]
                self.assertEqual(reply["opcode"], 3611)
                reward = bytes.fromhex(reply["hex"])
                general = next(v for n, w, v in protocol.iter_pb_fields(reward) if n == 8)
                self.assertEqual(protocol.pb_get_varint(general, 1), cid)
                iid = protocol.pb_get_varint(general, 2)
                self.assertGreater(iid, 2000000)
                self.assertEqual(self.entity_records(self.query_world(1002), 1, 2)[iid], general)
                self.assertEqual(protocol.pb_get_varint(reward, 2), gold)
                disk = self.save_path.read_bytes()
                self.assert_unavailable_response(self.replay([self.activity_request(3611, [reward_id])]),
                                                 3611, 20000, "已领取")
                self.assertEqual(self.save_path.read_bytes(), disk)
        self.assertEqual(self.query_role()[9], before[9] + 500)
        groups = self.begin7day_groups(self.query_world(3610))
        self.assertEqual((groups[1][1], groups[1][6]), (2, 2))

    def test_begin7day_native_batch_saves_rewards_once_and_deduplicates_general(self):
        self.complete_tutorial()
        saved = json.loads(self.save_path.read_text())
        player.apply_reward(saved, recruit.build_reward(saved, [(10404, 1)], self.role_config), self.role_config, self.now)
        self.save_path.write_text(json.dumps(saved))
        self.clock.return_value = self.now + 86400
        self.replay([self.activity_request(116, [self.recharge_order(6)])])
        before = self.query_role()
        pills = protocol.pb_get_varint(self.entity_records(self.query_world(1200), 1, 1)[20197], 2)
        request = self.activity_request(3611, [80002, 80009])
        conn = ReplayConnection([request, request, self.activity_request(3610)], 7)
        send = conn.sendall

        def check_committed(packet):
            saved = json.loads(self.save_path.read_text())
            self.assertEqual(saved["activity_state"]["begin7day_claimed"], [80002, 80009])
            self.assertEqual(saved["role_state"]["gold"], before[9] + 100)
            props = self.entity_records(bytes.fromhex(saved["world_state"]["1200"]), 1, 1)
            self.assertEqual(protocol.pb_get_varint(props[20197], 2), pills + 50)
            send(packet)

        conn.sendall = check_committed
        with redirect_stdout(io.StringIO()):
            self.run_client(conn)
        self.assertEqual([r["opcode"] for r in conn.responses], [3611, 1034, 999999, 1999, 3610])
        self.assertEqual(self.hint_changes(conn.responses[1]), {86: 0})
        self.assert_unavailable_response(conn.responses[2:4], 3611, 20000, "已领取")
        reward = bytes.fromhex(conn.responses[0]["hex"])
        self.assertFalse(any(n == 8 for n, _, _ in protocol.iter_pb_fields(reward)))
        fragments = self.entity_records(self.query_world(1012), 1, 1)
        self.assertEqual(protocol.pb_get_varint(fragments[10404], 2), self.role_config["general_fragment"]["11404"]["recruit"])
        groups = self.begin7day_groups(self.query_world(3610))
        self.assertEqual((groups[1][1], groups[1][8], groups[2][0]), (2, 2, 198))

    def test_begin7day_invalid_or_failed_batch_keeps_memory_disk_and_hints(self):
        self.complete_tutorial()
        self.clock.return_value = self.now + 86400
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            memory, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
            for ids in ([80001, 80001], [80001, 80007], [80001, 80008], [80001, 80015]):
                with self.subTest(ids=ids):
                    packets = session.handle(3611, 20000, bytes.fromhex(self.activity_request(3611, ids)["hex"]))
                    self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in packets], [999999, 1999])
                    self.assertEqual(session.save, memory)
                    self.assertEqual(self.save_path.read_bytes(), disk)
            body = bytes.fromhex(self.activity_request(3611, [80001, 80002])["hex"])
            with patch.object(player.os, "replace", side_effect=OSError("disk full")):
                with self.assertRaises(OSError):
                    session.handle(3611, 20000, body)
            self.assertEqual(session.save, memory)
            self.assertEqual(self.save_path.read_bytes(), disk)
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            session.save["role_state"]["gold"] = (1 << 31) - 1
            memory = copy.deepcopy(session.save)
            self.assertEqual(struct.unpack(">IIII", session.handle(3611, 20000, body)[0][:16])[2], 999999)
            self.assertEqual(session.save, memory)
            self.assertEqual(self.save_path.read_bytes(), disk)

    def test_begin7day_recharge_stops_after_day_seven_and_claims_after_day_ten(self):
        self.complete_tutorial()
        day_one = (self.now + 8 * 3600) // 86400 * 86400 - 8 * 3600
        self.clock.return_value = day_one + 7 * 86400 - 1
        self.replay([self.activity_request(116, [self.recharge_order(5)])])
        self.clock.return_value += 1
        self.replay([self.activity_request(116, [self.recharge_order(5)])])
        groups = self.begin7day_groups(self.query_world(3610))
        self.assertEqual((groups[0], groups[2][0], groups[1][7:9]), ([8], 68, [1, 0]))
        self.assertEqual(protocol.parse_ids_pb(self.query_world(117))[1], 136)
        self.replay([self.activity_request(3611, [80008])])
        self.clock.return_value = day_one + 10 * 86400 - 1
        self.assertEqual(self.replay([self.activity_request(3611, [80002])])[0]["opcode"], 3611)
        self.clock.return_value += 1
        groups = self.begin7day_groups(self.query_world(3610))
        self.assertEqual(groups[0], [11])
        self.assertTrue(all(v in (0, 2) for v in groups[1]))
        disk = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([self.activity_request(3611, [80007])]), 3611, 20000, "未解锁")
        self.assertEqual(self.save_path.read_bytes(), disk)
        self.assertTrue(all(self.hint_map(self.query_world(1032))[mid] == 0 for mid in range(82, 110)))

    def test_begin7day_legacy_recharge_migrates_once_and_all_tiers_can_claim(self):
        self.complete_tutorial()
        saved = json.loads(self.save_path.read_text())
        saved["activity_state"].pop("begin7day_rmb")
        saved["activity_state"]["begin7day_claimed"] = [80001]
        saved["recharge_state"]["rmb"] = 2975
        self.save_path.write_text(json.dumps(saved))
        self.clock.return_value = self.now + 6 * 86400
        self.assertEqual(self.begin7day_groups(self.query_world(3610))[2][0], 2975)
        self.assertEqual(self.begin7day_groups(self.query_world(3610))[1][13], 0)
        self.replay([self.activity_request(116, [self.recharge_order(1)])])
        self.assertEqual(self.begin7day_groups(self.query_world(3610))[2][0], 3000)
        reply = self.replay([self.activity_request(3611, list(range(80008, 80015)))])[0]
        self.assertEqual(reply["opcode"], 3611)
        equips = [protocol.parse_ids_pb(v) for n, w, v in protocol.iter_pb_fields(bytes.fromhex(reply["hex"])) if n == 6]
        self.assertEqual({v[1] for v in equips}, {21403, 22404, 23402, 24403})
        self.assertEqual(len({v[0] for v in equips}), 4)
        self.assertTrue(all(v[0] > 1000000 for v in equips))
        groups = self.begin7day_groups(self.query_world(3610))
        self.assertEqual((groups[1][0], groups[1][7:14], groups[2][0]), (2, [2] * 7, 3000))

    def test_activity_hints_follow_created_role_and_hide_unsupported_pages(self):
        fresh = self.hint_map(self.query_world(1032))
        self.assertEqual({mid: fresh[mid] for mid in (40, 82, 83, 84, 85, 542)}, dict.fromkeys((40, 82, 83, 84, 85, 542), 0))
        self.assertFalse(self.save_path.exists())
        self.replay(self.requests)
        hints = self.hint_map(self.query_world(1032))
        self.assertEqual({mid: hints[mid] for mid in (40, 82, 84)}, {40: 1, 82: 1, 84: 1})
        self.assertTrue(all(hints[mid] == 0 for mid in (83, *range(85, 110), 542)))

    def test_activity_hint_subset_preserves_requested_order_and_duplicates(self):
        self.replay_through(12)
        request = dict(self.activity_request(1032, (84, 82, 40, 82, 85, 542, 83)), seq=31)
        responses = self.replay([request])
        self.assertEqual(len(responses), 1)
        self.assertEqual((responses[0]["opcode"], responses[0]["seq"]), (1032, 31))
        self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(responses[0]["hex"])), [0, 1, 0, 1, 0, 0, 0])

    def test_mixed_unrecorded_hint_parameters_remain_non_mutating(self):
        self.replay_through(12)
        original = self.save_path.read_bytes()
        request = self.activity_request(1032, (82, 579))
        self.clock.return_value = self.now + 360
        self.assert_unavailable_response(self.replay([request]), 1032, 20000, "尚未实现")
        self.assertEqual(self.save_path.read_bytes(), original)

    def test_activity_hint_changes_activate_and_clear_on_eligible_operations(self):
        self.replay_through(98)
        responses = self.replay([self.by_seq[99]])
        self.assertEqual([self.hint_changes(f) for f in responses if f["opcode"] == 1034], [{40: 1}])
        responses = self.replay([f for f in self.requests if 99 < f["seq"] <= 107])
        self.assertEqual([self.hint_changes(f) for f in responses if f["opcode"] == 1034], [{84: 1}])
        for opcode, reward, hint in ((3611, 80001, 82), (3611, 80030, 84), (2411, 116, 40)):
            responses = self.replay([self.activity_request(opcode, (reward,))])
            self.assertEqual([(f["opcode"], f["seq"]) for f in responses], [(opcode, 20000), (1034, 0)])
            self.assertEqual(self.hint_changes(responses[-1]), {hint: 0})
        hints = self.hint_map(self.query_world(1032))
        self.assertEqual([hints[mid] for mid in (40, 82, 84)], [0, 0, 0])

    def test_activity_hint_refresh_in_same_connection_does_not_repeat_push(self):
        self.replay_through(12)
        query = self.activity_request(1032, (82,))
        responses = self.replay([query, self.activity_request(3611, (80001,)), query, query], chunk_size=7)
        self.assertEqual([f["opcode"] for f in responses], [1032, 3611, 1034, 1032, 1032])
        self.assertEqual([protocol.parse_ids_pb(bytes.fromhex(f["hex"])) for f in responses if f["opcode"] == 1032],
                         [[1], [0], [0]])
        self.assertEqual(self.hint_changes(responses[2]), {82: 0})

    def test_reconnect_init_hints_do_not_restore_claimed_activity_notifications(self):
        self.replay(self.requests)
        for opcode, reward in ((3611, 80001), (3611, 80030), (2411, 116)):
            self.replay([self.activity_request(opcode, (reward,))])
        init = self.replay([dict(self.by_seq[12], seq=30000)])
        self.assertEqual(len(init), 1)
        body = dict(protocol.get_comb_messages(bytes.fromhex(init[0]["hex"])))[1032]
        hints = self.hint_map(body)
        self.assertEqual([hints[mid] for mid in (40, 82, 84)], [0, 0, 0])
        subset = self.replay([self.activity_request(1032, (82, 84, 40))])[0]
        self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(subset["hex"])), [0, 0, 0])

    def test_failed_activity_save_does_not_clear_or_push_hints(self):
        self.replay(self.requests)
        for opcode, reward in ((3611, 80001), (3611, 80030), (2411, 116)):
            with patch.object(player.os, "replace", side_effect=OSError("disk failure")):
                self.assert_rejected(self.activity_request(opcode, (reward,)), "保存失败")
        hints = self.hint_map(self.query_world(1032))
        self.assertEqual([hints[mid] for mid in (40, 82, 84)], [1, 1, 1])

    def test_activity_hint_push_is_sent_only_after_entire_claim_is_saved(self):
        self.replay_through(12)
        before = json.loads(self.save_path.read_text())
        conn = ReplayConnection([self.activity_request(3611, (80001,))], 7)
        sendall = conn.sendall

        def check_saved_before_send(packet):
            saved = json.loads(self.save_path.read_text())
            self.assertIn(80001, saved["activity_state"]["begin7day_claimed"])
            self.assertEqual(saved["silver"], before["silver"] + 20000)
            props = self.entity_records(bytes.fromhex(saved["world_state"]["1200"]), 1, 1)
            self.assertEqual(protocol.pb_get_varint(props[20014], 2), 1)
            sendall(packet)

        conn.sendall = check_saved_before_send
        with redirect_stdout(io.StringIO()):
            self.run_client(conn)
        self.assertTrue(conn.closed)
        self.assertEqual([f["opcode"] for f in conn.responses], [3611, 1034])
        self.assertEqual(self.hint_changes(conn.responses[-1]), {82: 0})

    def test_activity_hint_rewrite_preserves_unrelated_and_unknown_fields(self):
        request = next(f for f in self.requests if f["opcode"] == 1032 and not f["hex"])
        extra = protocol.encode_pb_field(50, 2, b"keep")
        body = b"".join(protocol.encode_pb_field(1, 0, v) for v in (12345, 8201, 8200)) + extra
        response = dict(self.recorded[(request["seq"], 1032)], hex=body.hex())
        with redirect_stdout(io.StringIO()):
            self.tables = replay.build_routing_tables([self.by_seq[12], self.recorded[(12, 999900)], request, response])
        actual = self.query_world(1032)
        fields = list(protocol.iter_pb_fields(actual))
        self.assertIn((50, 2, b"keep"), fields)
        self.assertIn((1, 0, 12345), fields)
        self.assertEqual([v for n, w, v in fields if n == 1 and w == 0 and v // 100 == 82], [8200, 8200])
        self.assertTrue(all(self.hint_map(actual)[mid] == 0 for mid in (40, 84, 542)))

    def test_malformed_hint_query_does_not_mutate_save(self):
        self.replay_through(12)
        for body in ("08", "0800", "0a0152", "1052", "08521001", "08" + "ff" * 9 + "01"):
            with self.subTest(body=body):
                self.assert_rejected({"opcode": 1032, "seq": 20000, "hex": body}, "红点查询格式错误")

    def test_activity_save_failure_is_atomic(self):
        self.replay(self.requests)
        for opcode, values in ((3611, (80001,)), (3611, (80030,)), (2411, (116,))):
            with self.subTest(opcode=opcode, values=values), patch.object(player.os, "replace", side_effect=OSError("disk failure")):
                self.assert_rejected(self.activity_request(opcode, values), "保存失败")

    def test_anniversary_query_supplies_every_configured_count_and_status(self):
        response = self.replay([self.activity_request(4600)])[0]
        values = protocol.parse_ids_pb(bytes.fromhex(response["hex"]))
        self.assertEqual(len(values), 30)
        for row in self.role_config["mid_autumn_exchange"].values():
            # Lua 用 ID 作数组下标，然后计算 limit - 已兑次数。
            count, status = values[2 * row["id"] - 2:2 * row["id"]]
            self.assertEqual((count, status), (0, 0))
            self.assertEqual(row["limit"] - count, row["limit"])
        self.assertFalse(self.save_path.exists())

    def test_anniversary_query_can_reopen_after_tutorial_and_reconnect(self):
        self.replay(self.requests)
        before = self.save_path.read_bytes()
        first = self.replay([self.activity_request(4600)])[0]
        second = self.replay([self.activity_request(4600)])[0]
        self.assertEqual(first, second)
        self.assertEqual(len(protocol.parse_ids_pb(bytes.fromhex(first["hex"]))), 30)
        self.assertEqual(self.save_path.read_bytes(), before)

    def test_anniversary_query_matches_official_capture(self):
        capture = json.loads((Path(server.BASE_DIR) / "official_battle_capture_20261028_2014.json").read_text())
        frames = capture["connections"][0]["frames"]
        request = next(f for f in frames if f["c2s"] and f["opcode"] == 4600)
        reply = next(f for f in frames if not f["c2s"] and f["opcode"] == 4600 and f["seq"] == request["seq"])
        raw = (Path(server.BASE_DIR) / capture["source"]).read_bytes()
        self.assertIn(protocol.pack_frame(4600, reply["seq"], bytes.fromhex(reply["hex"])), raw)
        self.assertEqual(self.replay([request])[0]["hex"], reply["hex"])

    def seed_activity_account(self, gold=5000):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        snapshot = bytes.fromhex(saved["role_snapshot"])
        saved["role_snapshot"] = protocol.pb_set_varint(snapshot, 22, self.now - 4 * 86400).hex()
        saved["role_state"]["gold"] = gold
        self.save_path.write_text(json.dumps(saved))
        return saved

    def test_battle_math_matches_every_hit_and_experience_in_official_samples(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        samples = []
        for name in ("2014", "2017"):
            capture = json.loads((Path(server.BASE_DIR) / f"official_battle_capture_20261028_{name}.json").read_text())
            for connection in capture["connections"]:
                for reply in connection["frames"]:
                    if not reply["c2s"] and reply["opcode"] == 1306:
                        request = next(f for f in connection["frames"]
                                       if f["c2s"] and f["opcode"] == 1306 and f["seq"] == reply["seq"])
                        samples.append((request, reply))
        self.assertEqual(len(samples), 3)
        for request, reply in samples:
            with self.subTest(seq=reply["seq"]):
                location = protocol.parse_ids_pb(bytes.fromhex(request["hex"]))
                point = self.role_config["copy"][str(location[0])][str(location[1])]
                attack, defense = battle.rosters(saved, point, self.role_config)
                values = {n: v for n, w, v in protocol.iter_pb_fields(bytes.fromhex(reply["hex"]))}
                report = json.loads(values[5])
                for side, units in (("attack", attack), ("defense", defense)):
                    for pos, unit in units.items():
                        self.assertEqual(report["b"]["init"][side][str(pos)]["i"], unit["iid"])
                        meta = report["meta"][side]["g"][str(unit["iid"])]
                        self.assertEqual((meta["c"], meta["h"], meta["d"]["i"]), (unit["cid"], unit["hp"], unit["skill"]))
                for action in report["b"]["a"]:
                    source = action["s"]
                    if not source:
                        continue
                    attacker = (attack if source["r"] else defense)[source["p"][0]]
                    for dest in action["e"]:
                        if "m" not in dest:
                            continue
                        defender = (attack if dest["r"] else defense)[dest["p"]]
                        amount = battle.damage(attacker, defender, self.role_config, source.get("S"), dest["m"]["u"] == "C")
                        self.assertEqual(amount, dest["m"]["m"], (source, dest))
                        defender["hp"] -= amount
                for side, units in (("attack", attack), ("defense", defense)):
                    for pos, unit in units.items():
                        self.assertEqual(unit["hp"], report["endmeta"][side][str(pos)]["h"])
                result = battle.victory_role_reward(saved["role_state"], point, 3 if location[1] == 1 else 0, values[2], self.role_config)
                exp = {n: v for n, w, v in protocol.iter_pb_fields(values[3])}
                self.assertEqual((result["gained"], result["level"], result["exp"]), (exp[1], exp[2], exp[3]))
                self.assertEqual((result["coin"], result["gold"]), (protocol.pb_get_varint(values[4], 1), protocol.pb_get_varint(values[4], 2)))
                expected = self.entity_records(bytes.fromhex(reply["hex"]), 6, 2)
                for unit in attack.values():
                    level, experience, up = battle.general_experience(unit, point["xp"], self.role_config)
                    self.assertEqual((level, experience), (protocol.pb_get_varint(expected[unit["iid"]], 3), protocol.pb_get_varint(expected[unit["iid"]], 5)))
                    gained = next(v for n, w, v in protocol.iter_pb_fields(values[3]) if n == 4 and protocol.pb_get_varint(v, 1) == unit["iid"])
                    self.assertEqual(up, protocol.pb_get_varint(gained, 3))
                saved["role_state"].update(level=result["level"], exp=result["exp"])
                # 测试中用本场官方结算建立下一场的战前属性；生产路由不会载入这些样本。
                update = b"".join(protocol.encode_pb_field(1, 2, raw) for raw in expected.values())
                player.record_slot_update(saved, update)

    def test_battle_challenge_validation_uses_current_progress(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        body = bytes.fromhex(self.activity_request(1306, [42102, 2])["hex"])
        point, star = battle.challenge(saved, body, self.role_config)
        self.assertEqual((point["name"], star), ("望乡台", 0))
        for invalid in (b"", body + b"\x10\x01", body + b"\x08\x01", b"\x08"):
            with self.assertRaises(ValueError):
                battle.challenge(saved, invalid, self.role_config)
        with self.assertRaisesRegex(ValueError, "未解锁"):
            battle.challenge(saved, bytes.fromhex(self.activity_request(1306, [42102, 3])["hex"]), self.role_config)
        saved["role_state"]["stamina"] = 1
        with self.assertRaisesRegex(ValueError, "体力不足"):
            battle.challenge(saved, body, self.role_config)

    def test_battle_damage_uses_current_stats_and_caps_lethal_hits(self):
        attacker, defender = {"atk": 1756}, {"def": 694, "hp": 4410}
        self.assertEqual(battle.damage(attacker, defender, self.role_config, 12618, True), 1178)
        attacker["atk"] = 100
        self.assertEqual(battle.damage(attacker, defender, self.role_config), 5)
        attacker["atk"] = 99999
        self.assertEqual(battle.damage(attacker, defender, self.role_config, 12618, True), 4410)

    def test_live_battle_is_deterministic_and_report_replays_to_its_end(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        point = self.role_config["copy"]["42103"]["2"]
        attack, defense = battle.rosters(saved, point, self.role_config)
        before = copy.deepcopy((attack, defense))
        report = battle.simulate(attack, defense, self.role_config, 45)
        self.assertEqual(report, battle.simulate(attack, defense, self.role_config, 45))
        self.assertEqual((attack, defense), before)
        self.assert_battle_report(report)
        self.assertLessEqual(report["round"], 30)

    def assert_battle_report(self, report, condition=True):
        units = {}
        for side, direct in (("attack", True), ("defense", False)):
            for pos, unit in report["b"]["init"][side].items():
                meta = report["meta"][side]["pet" if pos == "0" else "g"][str(unit["i"])]
                units[direct, int(pos)] = {"hp": meta["h"], "maxhp": meta["j"], "ap": meta["ap"], "dizzy": False,
                                           "cover": meta.get("cover_d", 0)}
        for action in report["b"]["a"]:
            if action["s"]:
                for pos in action["s"]["p"]:
                    self.assertGreater(units[action["s"]["r"], pos]["hp"], 0)
                    self.assertFalse(units[action["s"]["r"], pos]["dizzy"])
            for dest in action["e"]:
                unit = units[dest["r"], dest["p"]]
                if isinstance(dest.get("m"), dict):
                    unit["hp"] -= dest["m"]["m"]
                    unit["cover"] -= dest["m"].get("M", 0)
                    self.assertGreaterEqual(unit["hp"], 0)
                    self.assertGreaterEqual(unit["cover"], 0)
                    self.assertLessEqual(unit["hp"], unit["maxhp"])
                if "ap" in dest:
                    self.assertGreaterEqual(dest["ap"], 0)
                    unit["ap"] = dest["ap"]
                if dest.get("u", {}).get("u") == "dizzy":
                    unit["dizzy"] = dest["u"]["w"]
        for side, direct in (("attack", True), ("defense", False)):
            for pos, unit in report["endmeta"][side].items():
                self.assertEqual((unit["h"], unit["ap"]), (units[direct, int(pos)]["hp"], units[direct, int(pos)]["ap"]))
                self.assertEqual(unit.get("cover_d", 0), units[direct, int(pos)]["cover"])
        won = all(v["h"] == 0 for v in report["endmeta"]["defense"].values()) and any(v["h"] > 0 for v in report["endmeta"]["attack"].values())
        self.assertEqual(report["result"], won and condition)
        self.assertEqual(bool(report["star"]), won and condition)

    def test_live_battle_saves_rewards_growth_and_repeat_before_reply(self):
        self.replay(self.requests)
        before = json.loads(self.save_path.read_text())
        request = self.activity_request(1306, [42102, 2])
        conn = ReplayConnection([request], 7)
        send = conn.sendall

        def check_saved_before_send(packet):
            committed = json.loads(self.save_path.read_text())
            self.assertEqual(committed["last_battle"]["point"], 2)
            self.assertEqual(committed["role_state"]["stamina"], before["role_state"]["stamina"] - 2)
            send(packet)

        conn.sendall = check_saved_before_send
        with redirect_stdout(io.StringIO()), patch.object(player.random, "getrandbits", return_value=42):
            self.run_client(conn)
        replies = conn.responses
        self.assertEqual([r["opcode"] for r in replies[:3]], [1306, 205, 1001])
        result = next(r for r in replies if r["opcode"] == 1306)
        fields = {n: v for n, w, v in protocol.iter_pb_fields(bytes.fromhex(result["hex"]))}
        self.assertEqual(fields[1], 1)
        self.assert_battle_report(json.loads(fields[5]))
        after = json.loads(self.save_path.read_text())
        self.assertEqual(after["role_state"]["stamina"], before["role_state"]["stamina"] - 2)
        self.assertGreater((after["role_state"]["level"], after["role_state"]["exp"]), (before["role_state"]["level"], before["role_state"]["exp"]))
        old = self.entity_records(bytes.fromhex(before["world_state"]["1002"]), 1, 2)
        for iid, raw in self.entity_records(bytes.fromhex(after["world_state"]["1002"]), 1, 2).items():
            if protocol.pb_get_varint(raw, 3) > protocol.pb_get_varint(old[iid], 3):
                self.assertGreater(protocol.pb_get_varint(raw, 6), protocol.pb_get_varint(old[iid], 6))
                self.assertGreater(protocol.pb_get_varint(raw, 20), protocol.pb_get_varint(old[iid], 20))
        self.assertEqual(self.query_world(1002).hex(), after["world_state"]["1002"])
        with patch.object(player.random, "getrandbits", return_value=42):
            self.replay([dict(request, seq=20001)])
        copies = self.entity_records(self.query_world(1300), 1, 1)
        point = self.entity_records(copies[42102], 7, 1)[2]
        self.assertEqual(protocol.pb_get_varint(point, 4), 2)
        self.assertEqual(protocol.pb_get_varint(point, 3), 3)

    def test_live_battle_retry_and_failed_save_are_atomic(self):
        self.replay(self.requests)
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            body = bytes.fromhex(self.activity_request(1306, [42102, 2])["hex"])
            original, memory = self.save_path.read_bytes(), copy.deepcopy(session.save)
            with patch.object(player.os, "replace", side_effect=OSError("disk full")):
                with self.assertRaises(OSError):
                    session.handle(1306, 20000, body)
            self.assertEqual(self.save_path.read_bytes(), original)
            self.assertEqual(session.save, memory)
            # A failed connection is discarded; retry on a new session.
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            first = session.handle(1306, 20000, body)
            committed = self.save_path.read_bytes()
            self.assertEqual(first, session.handle(1306, 20000, body))
            self.assertEqual(self.save_path.read_bytes(), committed)
            session.handle(101, 20001, protocol.encode_pb_field(1, 2, "新名字".encode()))
            changed = self.save_path.read_bytes()
            retry = session.handle(1306, 20000, body)
            self.assertEqual(struct.unpack(">IIII", retry[0][:16])[2], 999999)
            self.assertEqual(self.save_path.read_bytes(), changed)

    def test_live_battle_loss_has_no_rewards_and_does_not_unlock(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        for raw in self.entity_records(bytes.fromhex(saved["world_state"]["1002"]), 1, 2).values():
            for field in (6, 7, 8, 9):
                raw = protocol.pb_set_varint(raw, field, 1)
            player.record_slot_update(saved, protocol.encode_pb_field(1, 2, raw))
            player.record_protagonist_general(saved, raw)
        self.save_path.write_text(json.dumps(saved))
        replies = self.replay([self.activity_request(1306, [42102, 2])])
        fields = {n: v for n, w, v in protocol.iter_pb_fields(bytes.fromhex(replies[0]["hex"]))}
        self.assertEqual((fields[1], fields[2]), (0, 0))
        self.assert_battle_report(json.loads(fields[5]))
        after = json.loads(self.save_path.read_text())
        self.assertEqual(after["world_state"], saved["world_state"])
        for key in ("coin", "gold", "level", "exp"):
            self.assertEqual(after["role_state"][key], saved["role_state"][key])
        self.assertEqual(after["role_state"]["stamina"], saved["role_state"]["stamina"] - 2)
        self.assertEqual(after["activity_state"]["liveness_counts"]["1"], saved["activity_state"]["liveness_counts"]["1"] + 2)

    def combat_unit(self, cid, **values):
        return {"cid": cid, "iid": cid, "level": 1, "advance": 0, "exp": 0,
                "atk": 100, "def": 0, "hp": 10000, "speed": 100,
                "skill": self.role_config["general"][str(cid)]["skillid"], **values}

    def passive_config(self, cid, *ids):
        row = dict(self.role_config["general"][str(cid)])
        row.update({f"break{i}": pid for i, pid in enumerate(ids, 1)})
        return {**self.role_config, "general": {**self.role_config["general"], str(cid): row}}

    def test_campaign_static_passives_do_not_double_player_snapshot_stats(self):
        config = self.passive_config(10201, 9000139, 9000094)
        teams = {True: {2: self.combat_unit(10201, advance=2, npc=True, **{"def": 100})},
                 False: {2: self.combat_unit(10201, advance=2, **{"def": 100})}}
        battle._prepare_teams(teams, config)
        self.assertEqual((teams[True][2]["atk"], teams[True][2]["def"]), (300, 110))
        self.assertEqual((teams[False][2]["atk"], teams[False][2]["def"]), (100, 100))

    def test_campaign_initial_ap_aura_does_not_stack_duplicate_providers(self):
        config = self.passive_config(10201, 9000288)
        report = battle.simulate({2: self.combat_unit(10201, advance=1), 8: self.combat_unit(10201, iid=2, advance=1)},
                                 {2: self.combat_unit(10201, iid=3)}, config, 7)
        self.assert_battle_report(report)
        self.assertEqual([v["ap"] for v in report["meta"]["attack"]["g"].values()], [4, 4])

    def test_campaign_clan_aura_keeps_each_providers_conditional_self_bonus(self):
        config = self.passive_config(10201, 9000656)
        config["general"]["10201"]["region"] = "14"
        teams = {True: {pos: self.combat_unit(10201, iid=pos, advance=1, npc=True) for pos in (2, 8)},
                 False: {2: self.combat_unit(10213)}}
        battle._prepare_teams(teams, config)
        self.assertEqual([u["atk"] for u in teams[True].values()], [126, 126])

    def test_campaign_ap_and_damage_modifiers_multiply_in_the_same_pipeline(self):
        config = self.passive_config(10201, 9000009)
        report = battle.simulate({2: self.combat_unit(10201, advance=1, speed=200, adddmgpct=0.5)},
                                 {2: self.combat_unit(10201, iid=1, atk=1, subdmgpct=1)}, config, 7)
        self.assert_battle_report(report)
        hit = report["b"]["a"][0]["e"][0]["m"]["m"]
        self.assertEqual(hit, 165)  # 100 × 技能2 × 增伤1.5 ÷ 减伤2 × 多怒1.1。

    def test_campaign_role_level_cap_banks_exp_without_inventing_level_151(self):
        maximum = max(map(int, self.role_config["role_exp"]))
        state = {"level": maximum, "exp": self.role_config["role_exp"][str(maximum)]["nextexp"] - 1}
        point = self.role_config["copy"]["42410"]["10"]
        reward = battle.victory_role_reward(state, point, 3, 3, self.role_config)
        self.assertEqual((reward["level"], reward["exp"]), (maximum, state["exp"] + reward["gained"]))
        self.assertEqual(reward["coin"], point["coin"])
        state["exp"] = (1 << 31) - 1
        with self.assertRaisesRegex(ValueError, "经验超出范围"):
            battle.victory_role_reward(state, point, 3, 3, self.role_config)

    def test_campaign_first_hit_bonus_and_death_revenge_have_real_damage(self):
        config = self.passive_config(10201, 9000029)
        report = battle.simulate({2: self.combat_unit(10201, advance=1, speed=200)},
                                 {2: self.combat_unit(10201, iid=1, atk=1)}, config, 7)
        self.assert_battle_report(report)
        self.assertEqual(report["b"]["a"][0]["e"][0]["m"]["m"], 160)
        config = self.passive_config(10201, 9000263)
        for cid, advance, expected in ((10201, 0, 250), (10224, 1, 100)):
            report = battle.simulate({2: self.combat_unit(10201, advance=1, hp=50)},
                                     {2: self.combat_unit(cid, iid=1, advance=advance, atk=1000, speed=200)}, config, 7)
            self.assert_battle_report(report)
            revenge = report["b"]["a"][1]
            self.assertEqual(revenge["s"], {})
            self.assertEqual(revenge["e"][0]["m"]["m"], expected)

    def test_campaign_kill_recovery_heals_without_reviving_dead_units(self):
        config = self.passive_config(10201, 9000255)
        report = battle.simulate({2: self.combat_unit(10201, advance=1, hp=200, speed=200)},
                                 {2: self.combat_unit(10201, iid=1, hp=50, atk=30, speed=300),
                                  8: self.combat_unit(10201, iid=2, atk=1)}, config, 7)
        self.assert_battle_report(report)
        heals = [d["m"]["m"] for a in report["b"]["a"] for d in a["e"]
                 if isinstance(d.get("m"), dict) and d["m"]["m"] < 0]
        self.assertEqual(heals[0], -20)

    def test_campaign_cleanse_removes_poison_before_healing(self):
        config = self.passive_config(10305, 9000337)
        config["skill"] = {**config["skill"], "12302": {**config["skill"]["12302"], "effect-trigger": 1}}
        report = battle.simulate({2: self.combat_unit(10201, atk=1, speed=50),
                                  8: self.combat_unit(10305, advance=1, speed=200)},
                                 {2: self.combat_unit(10302, atk=100, speed=300)}, config, 7)
        self.assert_battle_report(report)
        heal = next(a for a in report["b"]["a"] if a["s"].get("S") == 12305)
        self.assertEqual(heal["e"][0].get("u"), {"u": "dot", "w": False})
        self.assertLess(heal["e"][1]["m"]["m"], 0)

    def test_campaign_firing_ticks_and_duration_reduction_are_not_ignored(self):
        cid = next(int(cid) for cid, row in self.role_config["general"].items() if row["skillid"] == 12476)
        config = self.passive_config(10201, 9000662)
        config["skill"] = {**config["skill"], "12476": {**config["skill"]["12476"], "effect-trigger": 1}}
        report = battle.simulate({2: self.combat_unit(cid, speed=200)},
                                 {2: self.combat_unit(10201, iid=1, advance=1, atk=1)}, config, 7)
        self.assert_battle_report(report)
        ticks = [d["m"]["m"] for a in report["b"]["a"] for d in a["e"]
                 if isinstance(d.get("m"), dict) and d["m"]["u"] == "firing"]
        self.assertTrue(ticks)
        self.assertEqual(set(ticks), {6})
        self.assertTrue(any(d.get("u") == {"u": "firing", "w": False} for a in report["b"]["a"] for d in a["e"]))

    def test_live_combo_uses_each_initiator_and_zero_ap_partner(self):
        config = copy.deepcopy(self.role_config)
        config["combskillprobability"]["12622"] = dict.fromkeys((f"bout{i}" for i in range(1, 11)), 1)
        report = battle.simulate({8: self.combat_unit(10213, atk=100, speed=200),
                                 10: self.combat_unit(10214, atk=200, speed=190)},
                                {2: self.combat_unit(10201, iid=1, atk=1), 8: self.combat_unit(10201, iid=2, atk=1)}, config, 1)
        self.assert_battle_report(report)
        combos = [a for a in report["b"]["a"] if a["s"].get("S") == 12622]
        self.assertEqual([a["s"]["p"] for a in combos[:2]], [[8, 10], [10, 8]])
        self.assertEqual([a["e"][0]["m"]["m"] for a in combos[:2]], [84, 168])
        self.assertEqual([[d["p"] for d in a["e"] if "ap" in d] for a in combos[:2]], [[8], [10]])

    def combo_teams(self, skill_id, initiator=0, **leader):
        row = self.role_config["combskill"][str(skill_id)]
        members = [row[f"cid{i}"] for i in (1, 2, 3) if row[f"cid{i}"]]
        attack = {battle.POSITIONS[i]: self.combat_unit(cid, initial_ap=4 if i == initiator else 0,
                  speed=1000 if i == initiator else 50, **(leader if i == initiator else {}))
                  for i, cid in enumerate(members)}
        defense = {pos: self.combat_unit(10201, iid=50 + i, atk=1, speed=10, initial_ap=0)
                   for i, pos in enumerate(battle.POSITIONS)}
        config = {**self.role_config, "combskillprobability": {**self.role_config["combskillprobability"],
                  str(skill_id): dict.fromkeys((f"bout{i}" for i in range(1, 11)), 1)}}
        return attack, defense, config

    def test_multicombo_taoyuan_uses_current_id_and_restores_lowest_shu_ap(self):
        attack, defense, config = self.combo_teams(12990)
        attack[4] = self.combat_unit(10201, iid=1, initial_ap=0, speed=1)
        with patch.object(battle, "MAX_ROUNDS", 1):
            report = battle.simulate(attack, defense, config, 1)
        first = report["b"]["a"][0]
        self.assertEqual(first["s"], {"r": True, "p": [2, 8, 10], "t": "x", "S": 12990})
        self.assertEqual([d["m"]["m"] for d in first["e"] if not d["r"]], [62] * 7)
        restores = [d for a in report["b"]["a"][:2] for d in a["e"] if d.get("E")]
        self.assertEqual(restores, [{"r": True, "p": 8, "ap": 4, "E": True}])
        self.assertFalse(any(a["s"].get("S") == 12605 for a in report["b"]["a"]))
        self.assert_battle_report(report)

    def test_multicombo_all_current_ids_each_initiator_and_both_sides_replay(self):
        unchanged = copy.deepcopy(self.role_config)
        referenced = {row["combskillid"] for row in self.role_config["general"].values()}
        expected = {row["id"] for row in self.role_config["combskill"].values() if row["cid2"] and row["id"] in referenced}
        self.assertEqual((len(expected), set(battle.MULTI_COMBOS)), (37, expected))
        self.assertFalse({12603, 12605} & expected)
        for sid in sorted(expected):
            row = self.role_config["combskill"][str(sid)]
            for initiator in range(3 if row["cid3"] else 2):
                for direct in (True, False):
                    with self.subTest(skill=sid, initiator=initiator, direct=direct), patch.object(battle, "MAX_ROUNDS", 1):
                        attack, defense, config = self.combo_teams(sid, initiator)
                        before = copy.deepcopy((attack, defense))
                        report = battle.simulate(attack if direct else defense, defense if direct else attack, config, 7)
                        self.assertEqual((attack, defense), before)
                        actions = [a for a in report["b"]["a"] if a["s"].get("S") == sid]
                        self.assertTrue(actions)
                        self.assertEqual(actions[0]["s"]["r"], direct)
                        self.assertEqual(actions[0]["s"]["p"][0], battle.POSITIONS[initiator])
                        self.assertEqual(set(actions[0]["s"]["p"]), set(attack))
                        self.assert_battle_report(report)
        self.assertEqual(self.role_config, unchanged)

    def test_multicombo_missing_partner_insufficient_ap_and_failed_roll_fall_back(self):
        for problem in ("missing", "ap", "probability", "dizzy", "dead"):
            attack, defense, config = self.combo_teams(12990, 1)
            if problem == "missing":
                del attack[2]
            elif problem == "ap":
                attack[8]["initial_ap"] = 3
            elif problem == "probability":
                config["combskillprobability"]["12990"] = dict.fromkeys((f"bout{i}" for i in range(1, 11)), 0)
            else:
                config = {**config, "skill": {**config["skill"], "12201": {**config["skill"]["12201"],
                          "effect": "dizzy", "effect-trigger": 1}}}
                defense[2].update(initial_ap=4, speed=2000, atk=1000000 if problem == "dead" else 1)
            with self.subTest(problem=problem), patch.object(battle, "MAX_ROUNDS", 1):
                report = battle.simulate(attack, defense, config, 1)
                self.assertFalse(any(a["s"].get("S") == 12990 for a in report["b"]["a"]))
                leader = next(a for a in report["b"]["a"] if a["s"].get("r") and a["s"]["p"] == [8])
                self.assertEqual(leader["s"].get("S"), None if problem == "ap" else 12405)
                self.assert_battle_report(report)

    def test_multicombo_promoted_identities_use_current_combo_without_duplicates(self):
        attack, defense, config = self.combo_teams(12990)
        for unit in attack.values():
            cid = next(int(cid) for cid, row in config["general"].items()
                       if row["init_cid"] == unit["cid"] and int(cid) != unit["cid"])
            unit.update(cid=cid, skill=config["general"][str(cid)]["skillid"])
        with patch.object(battle, "MAX_ROUNDS", 1):
            report = battle.simulate(attack, defense, config, 1)
        self.assertEqual(report["b"]["a"][0]["s"]["S"], 12990)
        self.assertEqual(report["b"]["a"][0]["s"]["p"], [2, 8, 10])
        self.assert_battle_report(report)

    def test_multicombo_probability_uses_round_table_and_not_effect_trigger(self):
        attack, defense, config = self.combo_teams(12604)
        config["combskillprobability"]["12604"] = self.role_config["combskillprobability"]["12604"]
        base = attack[2]["skill"]
        config = {**config, "skill": {**config["skill"], str(base): {**config["skill"][str(base)], "ap": 100}}}
        with patch.object(battle.random.Random, "random", return_value=.32), patch.object(battle, "MAX_ROUNDS", 2):
            report = battle.simulate(attack, defense, config, 1)
        round_number, rounds = 1, []
        for action in report["b"]["a"]:
            if not action["s"] and not action["e"]:
                round_number += 1
            if action["s"].get("S") == 12604:
                rounds.append(round_number)
        self.assertTrue(rounds)
        self.assertEqual(set(rounds), {2})

    def test_multicombo_attack_buffs_defense_debuffs_and_recovery_have_real_values(self):
        for sid, attr, kind, count in ((12602, "atk", "promote", 2), (12623, "def", "weaken", 3),
                                       (12630, "def", "weaken", 3), (12632, "atk", "promote", 1),
                                       (12841, "def", "weaken", 3)):
            attack, defense, config = self.combo_teams(sid)
            for unit in defense.values():
                unit["def"] = 50
            with self.subTest(skill=sid), patch.object(battle, "MAX_ROUNDS", 1):
                report = battle.simulate(attack, defense, config, 1)
                applied = [d for d in report["b"]["a"][1]["e"] if d.get("B") == {"R": attr, "u": kind, "w": True}]
                self.assertEqual(len(applied), count)
                if sid == 12632:
                    self.assertEqual(report["b"]["a"][0]["e"][0]["m"]["m"], 157)
                self.assert_battle_report(report)
        attack, defense, config = self.combo_teams(12624)
        defense[2].update(speed=2000, atk=1000)
        with patch.object(battle, "MAX_ROUNDS", 1):
            report = battle.simulate(attack, defense, config, 1)
        heals = [d["m"]["m"] for a in report["b"]["a"] for d in a["e"]
                 if isinstance(d.get("m"), dict) and d["m"]["m"] < 0]
        self.assertIn(-100, heals)
        self.assert_battle_report(report)

    def test_multicombo_hp_threshold_stuns_are_post_damage_and_strict(self):
        for sid, ratio in ((12601, Fraction(1, 2)), (12625, Fraction(4, 5)), (12636, Fraction(1, 2))):
            for extra in (0, 1):
                attack, defense, config = self.combo_teams(sid)
                damage = battle.damage(attack[2], defense[2], config, sid, combo=True)
                current = int(10000 * ratio) + damage + (extra if sid == 12625 else -extra)
                before = battle._prepare_teams
                def prepare(teams, role_config):
                    before(teams, role_config)
                    for unit in teams[False].values():
                        unit["hp"] = current
                with self.subTest(skill=sid, extra=extra), patch.object(battle, "_prepare_teams", side_effect=prepare), patch.object(battle, "MAX_ROUNDS", 1):
                    report = battle.simulate(attack, defense, config, 1)
                    stunned = [d for a in report["b"]["a"][:2] for d in a["e"] if d.get("u") == {"u": "dizzy", "w": True}]
                    if sid == 12636:
                        self.assertTrue(all(d["p"] > 7 for d in stunned))
                    else:
                        self.assertEqual(any(d["p"] == 2 for d in stunned), bool(extra))

    def test_multicombo_variable_damage_depends_on_target_count_and_precast_hp(self):
        for count in (1, 4):
            attack, defense, config = self.combo_teams(13076)
            defense = dict(list(defense.items())[:count])
            with self.subTest(targets=count), patch.object(battle, "MAX_ROUNDS", 1):
                report = battle.simulate(attack, defense, config, 1)
                expected = int(100 * (Fraction(395, 100) - Fraction(45, 100) * count) / 8) * 8
                self.assertEqual([d["m"]["m"] for d in report["b"]["a"][0]["e"] if not d["r"]], [expected] * count)
                self.assert_battle_report(report)
        attack, defense, config = self.combo_teams(12629)
        with patch.object(battle, "MAX_ROUNDS", 1):
            report = battle.simulate(attack, defense, config, 1)
        self.assertEqual(report["b"]["a"][0]["e"][0]["m"]["m"], 147)

    def test_multicombo_ap_selection_seals_and_kill_refund(self):
        for sid, count in ((12836, 2), (12989, 2), (13018, 1), (13124, 2)):
            attack, defense, config = self.combo_teams(sid)
            defense[8]["initial_ap"] = 8
            defense[10]["initial_ap"] = 7
            defense[10]["atk"] = 500
            with self.subTest(skill=sid), patch.object(battle, "MAX_ROUNDS", 1):
                report = battle.simulate(attack, defense, config, 1)
                effects = report["b"]["a"][1]["e"]
                self.assertEqual(len([d for d in effects if "ap" in d]), count)
                self.assertEqual([d["p"] for d in effects if "ap" in d], [10] if sid == 13018 else [8, 10])
                if sid in (12989, 13124):
                    self.assertEqual(len([d for d in effects if d.get("u", {}).get("u") == "skilllock"]), 2)
                    self.assertFalse(any(a["s"].get("S") for a in report["b"]["a"] if a["s"].get("r") is False and a["s"]["p"][0] in (8, 10)))
                self.assert_battle_report(report)

    def test_multicombo_repeats_are_bounded_and_charge_ap_only_once(self):
        for sid in (12604, 12943):
            attack, defense, config = self.combo_teams(sid)
            config = {**config, "combskill": {**config["combskill"], str(sid): {**config["combskill"][str(sid)], "trigger": 1}}}
            with self.subTest(skill=sid), patch.object(battle, "MAX_ROUNDS", 1):
                report = battle.simulate(attack, defense, config, 1)
                combos = [a for a in report["b"]["a"] if a["s"].get("S") == sid]
                self.assertEqual(len(combos), 5)
                self.assertEqual([d["ap"] for a in combos for d in a["e"] if d["r"] and d["p"] == 2 and "ap" in d],
                                 [0] * 5 if sid == 12604 else [0, 2, 2, 2, 2, 2])
                self.assert_battle_report(report)

    def test_multicombo_all_reports_convert_with_actual_apk_animation_assets(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("合体战报转换需本机已有 lupa.lua51")
        package = Path(server.BASE_DIR) / "zyj_local.apk"
        if not package.exists():
            self.skipTest("合体动画验证需要本地APK")
        with patch.object(apk_builder, "SRC_APK", str(package)):
            converter = apk_builder.read_script("battleReportConvert").decode("utf-8")
            abbreviations = apk_builder.read_script("BattleReportAbbToKey").decode("utf-8")
        converter = converter.replace("\r\n", "\n")
        if "local function localBattleSkillAnimation" not in converter:
            converter = apk_builder.patch_combo_animation_script(converter)
        lua = LuaRuntime()
        config = dict(self.role_config)
        with zipfile.ZipFile(Path(server.BASE_DIR) / "configs_sec5.zip") as archive:
            for name in ("generalanimation", "skillanimation", "personalboss_att"):
                config[name] = json.loads(archive.read("5/" + name + ".json"))
        lua.globals().gamedata = lua.table_from({"config": config}, recursive=True)
        lua.execute('''print=function() end;printT=print;battleScene={slotNum=7}
            table.getTableLength=function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
            CCFileUtils={sharedFileUtils=function(self) return self end,fullPathForFilename=function(self,p) return p end}
            ui={Split=function(s,sep) local t={} for v in string.gmatch(s,'[^'..sep..']+') do t[#t+1]=v end return t end}''')
        with zipfile.ZipFile(package) as archive:
            assets = {}
            names = archive.namelist()
            lua.globals().CCFileUtils.isFileExist = lambda _, path: any(n.endswith("/" + path) for n in names)
            def load_asset(path):
                if path not in assets:
                    matches = [n for n in names if n.endswith("/" + path)]
                    self.assertEqual(len(matches), 1, path)
                    assets[path] = json.loads(archive.read(matches[0]))
                return lua.table_from(assets[path], recursive=True)
            lua.globals().LoadJsonFileToTable = load_asset
            lua.execute(converter)
            lua.execute(abbreviations)
            for sid in battle.MULTI_COMBOS:
                for initiator in range(3 if self.role_config["combskill"][str(sid)]["cid3"] else 2):
                    with self.subTest(skill=sid, initiator=initiator), patch.object(battle, "MAX_ROUNDS", 3):
                        attack, defense, role_config = self.combo_teams(sid, initiator)
                        report = battle.simulate(attack, defense, role_config, 3)
                        native = lua.table_from(json.loads(lua.globals().ReplaceAbbToKey(json.dumps(report))), recursive=True)
                        atk, enemy = lua.globals().getBattleInitSlotInfo(native)
                        animations, ext = lua.globals().convertBattleReportToAnimationSub(native, atk, enemy)
                        self.assertGreater(len(animations), 1)
                        for side, key in (("attack", "atk"), ("defense", "def")):
                            for pos, unit in report["endmeta"][side].items():
                                self.assertEqual(ext.endinfo[key][pos].hp, unit["h"])
                                self.assertEqual(ext.endinfo[key][pos].ap, unit["ap"])

            for sid in (13124, 13125):
                attack, defense, role_config = self.combo_teams(sid)
                role_config["combskillprobability"][str(sid)] = dict.fromkeys((f"bout{i}" for i in range(1, 11)), 0)
                with self.subTest(personal_skills=sid), patch.object(battle, "MAX_ROUNDS", 3):
                    report = battle.simulate(attack, defense, role_config, 3)
                    native = lua.table_from(json.loads(lua.globals().ReplaceAbbToKey(json.dumps(report))), recursive=True)
                    atk, enemy = lua.globals().getBattleInitSlotInfo(native)
                    for _, unit in atk.items():
                        name = unit.animation.name
                        self.assertTrue(any(n.endswith('/' + name + '/' + name + '_time.json') for n in names))
                    animations, ext = lua.globals().convertBattleReportToAnimationSub(native, atk, enemy)
                    for side, key in (("attack", "atk"), ("defense", "def")):
                        for pos, unit in report["endmeta"][side].items():
                            self.assertEqual(ext.endinfo[key][pos].hp, unit["h"])

    def test_multicombo_invulnerability_and_seal_expire_without_losing_turns(self):
        attack, defense, config = self.combo_teams(12631)
        defense = {2: self.combat_unit(10201, initial_ap=4, atk=100, speed=100)}
        with patch.object(battle, "MAX_ROUNDS", 2):
            report = battle.simulate(attack, defense, config, 1)
        hits = [d["m"] for a in report["b"]["a"] if a["s"].get("r") is False
                for d in a["e"] if d["r"] and isinstance(d.get("m"), dict)]
        self.assertEqual((hits[0]["m"], hits[0]["u"], hits[1]["m"]), (0, "proof", 100))
        self.assertTrue(any(d.get("u") == {"u": "invincible", "w": False} for a in report["b"]["a"] for d in a["e"]))
        self.assert_battle_report(report)
        attack, _, config = self.combo_teams(12990)
        defense, _, other = self.combo_teams(12989)
        defense[2]["speed"] = 2000
        config["combskillprobability"]["12989"] = other["combskillprobability"]["12989"]
        with patch.object(battle, "MAX_ROUNDS", 2):
            report = battle.simulate(attack, defense, config, 1)
        round_number, rounds = 1, []
        for action in report["b"]["a"]:
            if not action["s"] and not action["e"]:
                round_number += 1
            if action["s"].get("S") == 12990:
                rounds.append(round_number)
        self.assertTrue(rounds)
        self.assertEqual(set(rounds), {2})
        self.assert_battle_report(report)

    def test_multicombo_xiyin_prevents_stun_only_during_its_duration(self):
        attack, _, config = self.combo_teams(13078)
        defense = {2: self.combat_unit(10214, initial_ap=4, speed=100, atk=1)}
        config = {**config, "skill": {**config["skill"], "12214": {**config["skill"]["12214"], "effect-trigger": 1, "ap_give": 4}}}
        with patch.object(battle, "MAX_ROUNDS", 2):
            report = battle.simulate(attack, defense, config, 1)
        round_number, rounds = 1, []
        for action in report["b"]["a"]:
            if not action["s"] and not action["e"]:
                round_number += 1
            if any(d.get("u") == {"u": "dizzy", "w": True} for d in action["e"]):
                rounds.append(round_number)
        self.assertEqual(rounds, [2])
        self.assertTrue(any(d.get("B") == {"R": "xiyin", "u": "promote", "w": False} for a in report["b"]["a"] for d in a["e"]))
        self.assert_battle_report(report)

    def test_multicombo_fire_mark_doubles_next_skill_but_not_normal_attacks(self):
        attack, defense, config = self.combo_teams(13125)
        config = {**config, "combskill": {**config["combskill"], "13125": {**config["combskill"]["13125"], "trigger": 1}}}
        with patch.object(battle, "MAX_ROUNDS", 4):
            report = battle.simulate(attack, defense, config, 1)
        actions = [a for a in report["b"]["a"] if a["s"].get("r") and a["s"]["p"][0] == 2]
        damage = lambda a: next(d["m"]["m"] for d in a["e"] if not d["r"] and isinstance(d.get("m"), dict))
        self.assertEqual([damage(a) for a in actions[:4]], [84, 100, 100, 180])
        self.assertTrue(any(d.get("B") == {"R": "fire", "u": "break", "w": False} for d in actions[3]["e"]))
        self.assert_battle_report(report)

    def test_multicombo_free_personal_skill_does_not_spend_ap_or_recurse(self):
        attack, defense, config = self.combo_teams(13017)
        with patch.object(battle.random.Random, "random", return_value=0), patch.object(battle, "MAX_ROUNDS", 1):
            report = battle.simulate(attack, defense, config, 1)
        actions = [a for a in report["b"]["a"] if a["s"].get("r") and a["s"]["p"][0] == 2]
        self.assertEqual([a["s"]["S"] for a in actions], [13017, attack[2]["skill"]])
        self.assertEqual([d["ap"] for a in actions for d in a["e"] if d["r"] and d["p"] == 2 and "ap" in d], [0, 0])
        self.assert_battle_report(report)

    def test_multicombo_forced_criticals_and_actual_kill_refund(self):
        attack, defense, config = self.combo_teams(13077)
        with patch.object(battle, "MAX_ROUNDS", 1):
            report = battle.simulate(attack, defense, config, 1)
        self.assertEqual(sum(d.get("m", {}).get("u") == "C" for d in report["b"]["a"][0]["e"]), 4)
        attack, defense, config = self.combo_teams(13018)
        for pos in (2, 4, 6):
            defense[pos]["hp"] = 10
        with patch.object(battle, "MAX_ROUNDS", 1):
            report = battle.simulate(attack, defense, config, 1)
        self.assertIn({"r": True, "p": 2, "ap": 4, "E": True}, report["b"]["a"][1]["e"])
        self.assert_battle_report(report)

    def test_multicombo_critical_bonus_is_thirty_percentage_points_not_seventy_five(self):
        for draw, expected in ((.29, True), (.30, False)):
            attack, defense, config = self.combo_teams(12627)
            with self.subTest(draw=draw), patch.object(battle.random.Random, "random", return_value=draw), patch.object(battle, "MAX_ROUNDS", 1):
                report = battle.simulate(attack, defense, config, 1)
            hits = [d["m"] for d in report["b"]["a"][0]["e"] if not d["r"]]
            self.assertEqual([d["u"] == "C" for d in hits], [expected] * 7)
            self.assertEqual([d["m"] for d in hits], [116 if expected else 58] * 7)
            self.assert_battle_report(report)

        attack, defense, config = self.combo_teams(12627)
        protected = self.passive_config(10201, 9000030)
        config = {**config, "general": protected["general"]}
        for unit in defense.values():
            unit["advance"] = 1
        with patch.object(battle.random.Random, "random", return_value=.1), patch.object(battle, "MAX_ROUNDS", 1):
            report = battle.simulate(attack, defense, config, 1)
        self.assertFalse(any(d.get("m", {}).get("u") == "C" for d in report["b"]["a"][0]["e"]))

    def test_multicombo_damage_uses_combo_table_when_normal_skill_id_collides(self):
        actor, target = {"atk": 100}, {"def": 0, "hp": 10000}
        self.assertEqual(battle.damage(actor, target, self.role_config, 12601, combo=True), 85)
        with self.assertRaisesRegex(ValueError, "伤害技能"):
            battle.damage(actor, target, self.role_config, 12601)
        self.assertEqual(battle.damage(actor, target, self.role_config, 12602, combo=True), 72)
        self.assertNotEqual(battle.damage(actor, target, self.role_config, 12602), 72)

    def test_multicombo_stat_effects_change_following_attacks_not_only_the_icons(self):
        for sid, expected in ((12602, 82), (12623, 66), (12630, 76), (12841, 66)):
            attack, defense, config = self.combo_teams(sid)
            for unit in defense.values():
                unit["def"] = 50
            with self.subTest(skill=sid), patch.object(battle.random.Random, "sample", side_effect=lambda population, count: list(population)[:count]), patch.object(battle, "MAX_ROUNDS", 1):
                report = battle.simulate(attack, defense, config, 1)
            partner = next(a for a in report["b"]["a"] if a["s"].get("r") and a["s"]["p"] == [8])
            self.assertEqual(partner["e"][0]["m"]["m"], expected)
            self.assert_battle_report(report)

    def test_multicombo_ranked_stuns_do_not_replace_already_stunned_top_targets(self):
        for sid, expected in ((12988, []), (13075, [8])):
            attack, _, config = self.combo_teams(sid)
            attack[4] = self.combat_unit(10214, initial_ap=4, speed=2000)
            defense = {pos: self.combat_unit(10201, iid=pos, atk=amount, initial_ap=0, speed=10)
                       for pos, amount in ((2, 500), (4, 400), (8, 300))}
            config = {**config, "skill": {**config["skill"], "12214": {**config["skill"]["12214"], "range": "first", "effect-trigger": 1}}}
            with self.subTest(skill=sid), patch.object(battle, "MAX_ROUNDS", 1):
                report = battle.simulate(attack, defense, config, 1)
            actions = report["b"]["a"]
            index = next(i for i, a in enumerate(actions) if a["s"].get("S") == sid)
            changed = actions[index + 1]["e"] if index + 1 < len(actions) and not actions[index + 1]["s"] else []
            self.assertEqual([d["p"] for d in changed if d.get("u") == {"u": "dizzy", "w": True}], expected)
            self.assert_battle_report(report)

    def test_multicombo_burning_uses_current_debuffed_defense_for_its_tick(self):
        attack, defense, config = self.combo_teams(12633)
        for unit in defense.values():
            unit["def"] = 50
        prepare = battle._prepare_teams
        def with_debuff(teams, role_config):
            prepare(teams, role_config)
            for unit in teams[False].values():
                unit["buffs"]["weaken", "def"] = (Fraction(1, 2), 3)
        with patch.object(battle, "_prepare_teams", side_effect=with_debuff), patch.object(battle, "MAX_ROUNDS", 1):
            report = battle.simulate(attack, defense, config, 1)
        ticks = [d["m"]["m"] for a in report["b"]["a"] for d in a["e"]
                 if isinstance(d.get("m"), dict) and d["m"].get("u") == "firing"]
        self.assertEqual(ticks, [7, 7, 7])
        self.assert_battle_report(report)

    def test_multicombo_dead_count_is_frozen_before_aoe_not_empty_slots_or_new_kills(self):
        attack, defense, config = self.combo_teams(13122)
        attack[10] = self.combat_unit(10201, iid=1, initial_ap=0, speed=2000, atk=10000)
        defense[2]["hp"] = 10
        defense[4]["hp"] = 50
        with patch.object(battle.random.Random, "sample", side_effect=lambda population, count: list(population)[:count]), patch.object(battle, "MAX_ROUNDS", 1):
            report = battle.simulate(attack, defense, config, 1)
        action = next(a for a in report["b"]["a"] if a["s"].get("S") == 13122)
        self.assertEqual([d["m"]["m"] for d in action["e"] if not d["r"]], [50, 224, 224, 224])
        self.assert_battle_report(report)

    def test_multicombo_campaign_commit_retry_and_save_failure_keep_real_guide(self):
        saved = self.seed_training_account()
        saved["role_state"].update(level=20, nextexp=self.role_config["role_exp"]["20"]["nextexp"])
        world = bytes.fromhex(saved["world_state"]["1002"])
        slot = self.entity_records(world, 4, 1)[1]
        saved["world_state"]["1002"] = b"".join(protocol.encode_pb_field(n, w, v) for n, w, v in protocol.iter_pb_fields(world) if (n, w) != (4, 2)).hex()
        player.record_slot_update(saved, protocol.encode_pb_field(4, 2, slot))
        for index, cid in enumerate((10404, 10405, 10502), 2):
            unit = self.combat_unit(cid, iid=2000200 + index, hp=100000, atk=100, speed=200)
            raw = b"".join(protocol.encode_pb_field(field, 0, unit.get(name, 0)) for name, field in battle.GENERAL_FIELDS.items())
            raw += protocol.encode_pb_field(20, 0, 10300)
            player.record_slot_update(saved, protocol.encode_pb_field(1, 2, raw))
            slot = protocol.encode_pb_field(1, 0, index) + protocol.encode_pb_field(2, 0, unit["iid"])
            player.record_slot_update(saved, protocol.encode_pb_field(4, 2, slot))
        self.save_path.write_text(json.dumps(saved))
        config = {**self.role_config, "combskillprobability": {**self.role_config["combskillprobability"],
                  "12990": dict.fromkeys((f"bout{i}" for i in range(1, 11)), 1)}}
        body = recharge.ids([42102, 2])
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, config)
            disk, memory = self.save_path.read_bytes(), copy.deepcopy(session.save)
            with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
                session.handle(1306, 45000, body)
            self.assertEqual((self.save_path.read_bytes(), session.save, session.random_replies), (disk, memory, {}))
            session = Session(self.tables, self.save_path, self.step_counts, config)
            packets = session.handle(1306, 45000, body)
            committed = self.save_path.read_bytes()
            self.assertEqual(session.handle(1306, 45000, body), packets)
            self.assertEqual(self.save_path.read_bytes(), committed)
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 1306)
        fields = {n: v for n, w, v in protocol.iter_pb_fields(packets[0][16:])}
        report = json.loads(fields[5])
        self.assertTrue(any(a["s"].get("S") == 12990 for a in report["b"]["a"]))
        self.assert_battle_report(report)
        after = json.loads(committed)
        self.assertEqual(after["guide"], saved["guide"])
        self.assertEqual(after["role_state"]["stamina"], saved["role_state"]["stamina"] - self.role_config["copy"]["42102"]["2"]["physical"])

    def test_live_stun_skips_one_turn_and_then_releases(self):
        config = copy.deepcopy(self.role_config)
        config["skill"]["12214"]["effect-trigger"] = 1
        report = battle.simulate({2: self.combat_unit(10214, speed=200)}, {2: self.combat_unit(10201, atk=1)}, config, 1)
        self.assert_battle_report(report)
        turns, rounds, releases = [], 1, []
        for a in report["b"]["a"]:
            if not a["s"] and not a["e"]:
                rounds += 1
            if a["s"] and not a["s"]["r"]:
                turns.append(rounds)
            if any(d.get("u") == {"u": "dizzy", "w": False} for d in a["e"]):
                releases.append(rounds)
        self.assertNotIn(2, turns)
        self.assertIn(3, turns)
        self.assertIn(2, releases)

    def test_live_guard_counts_attacks_and_low_hp_action_is_once(self):
        report = battle.simulate({2: self.combat_unit(10201, speed=200)},
                                {2: self.combat_unit(10224, atk=1, advance=1)}, self.role_config, 1)
        hits = [a["e"][0]["m"]["m"] for a in report["b"]["a"] if a["s"].get("r")]
        self.assertEqual(hits[:3], [40, 80, 100])
        report = battle.simulate({2: self.combat_unit(10112, hp=100, atk=5, advance=2)},
                                {2: self.combat_unit(10201, atk=90, speed=200)}, self.role_config, 1)
        self.assert_battle_report(report)
        sources = [a["s"] for a in report["b"]["a"] if a["s"]]
        self.assertEqual([s["r"] for s in sources[:4]], [False, True, True, False])

    def test_protagonist_plus_five_stuns_only_surviving_ordinary_hit_targets(self):
        cases = ((5, 10000, 0, 2, .29, True), (5, 10000, 0, 2, .3, False),
                 (4, 10000, 0, 2, 0, False), (5, 100, 0, 2, 0, False),
                 (5, 10000, 75, 2, 0, False), (5, 10000, 0, 4, 0, False))
        for advance, hp, dodge, ap, draw, expected in cases:
            with self.subTest(advance=advance, hp=hp, dodge=dodge, ap=ap, draw=draw):
                attack = {2: self.combat_unit(10128, advance=advance, initial_ap=ap, speed=200)}
                defense = {2: self.combat_unit(10201, iid=1, hp=hp, dodge=dodge, atk=1)}
                with patch.object(battle.random.Random, "random", return_value=draw):
                    report = battle.simulate(attack, defense, self.role_config, 42)
                self.assert_battle_report(report)
                hit = next(d for d in report["b"]["a"][0]["e"] if not d["r"] and "m" in d)
                self.assertEqual(hit.get("u"), {"u": "dizzy", "w": True} if expected else None)

    def test_live_lifesteal_poison_and_round_limit(self):
        report = battle.simulate({2: self.combat_unit(10201, atk=200, speed=200)},
                                {2: self.combat_unit(10303)}, self.role_config, 1)
        self.assert_battle_report(report)
        i = next(i for i, a in enumerate(report["b"]["a"]) if a["s"].get("S") == 12303)
        self.assertEqual(report["b"]["a"][i + 1]["e"][0]["m"]["m"], -64)
        config = copy.deepcopy(self.role_config)
        config["skill"]["12302"]["effect-trigger"] = 1
        report = battle.simulate({2: self.combat_unit(10302, speed=200)},
                                {2: self.combat_unit(10201, atk=1)}, config, 1)
        self.assert_battle_report(report)
        ticks = [d["m"]["m"] for a in report["b"]["a"] for d in a["e"]
                 if isinstance(d.get("m"), dict) and d["m"]["u"] == "dot"]
        self.assertTrue(ticks)
        self.assertEqual(set(ticks), {10})
        unit = self.combat_unit(10201, atk=1, **{"def": 10000})
        report = battle.simulate({2: unit}, {2: unit}, config, 1)
        self.assertEqual((report["round"], report["result"], report["star"]), (30, False, 0))
        self.assert_battle_report(report)

    def test_live_battle_all_supported_points_generate_consistent_reports(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        for mid, points in self.role_config["copy"].items():
            for pid, point in points.items():
                with self.subTest(map=mid, point=pid):
                    attack, defense = battle.rosters(saved, point, self.role_config)
                    self.assert_battle_report(battle.simulate(attack, defense, self.role_config, 7))

    def test_all_recruitable_generals_generate_replayable_battles(self):
        ids = set()
        for row in self.role_config["recruit_basic"].values():
            for key in ("freecardgroupid", "freefirstcardgroupid", "normalfirstcardgroupid", "firsttentavern"):
                if row[key]:
                    ids.update(int(e.split(",")[0]) for e in self.role_config["recruit_deck"][str(row[key])]["resourceid"].split(";") if e)
        ids.add(self.role_config["firstpay"]["1"]["goods2"])
        for cid in sorted(ids):
            if str(cid) not in self.role_config["general"] or not self.role_config["general"][str(cid)]["battle"]:
                continue
            with self.subTest(cid=cid):
                attack = {2: self.combat_unit(cid, speed=200), 8: self.combat_unit(10213, iid=2)}
                defense = {2: self.combat_unit(10201, iid=3, parry=50), 8: self.combat_unit(10201, iid=4)}
                report = battle.simulate(attack, defense, self.role_config, 7)
                self.assert_battle_report(report)
                self.assertEqual(report["rules"], "zyj-v2")

    def prepare_mieshendian(self, strong=True):
        saved = self.prepare_star_copy(strong)
        saved["role_state"].update(level=15, nextexp=self.role_config["role_exp"]["15"]["nextexp"])
        self.save_path.write_text(json.dumps(saved))
        return saved

    def prepare_blackmarket(self):
        saved = self.prepare_mieshendian()
        saved["role_state"].update(level=16, gold=100000, coin=10000000,
                                    nextexp=self.role_config["role_exp"]["16"]["nextexp"])
        self.save_path.write_text(json.dumps(saved))
        return saved

    def prepare_watchstar(self):
        saved = self.prepare_blackmarket()
        saved["role_state"].update(level=17, nextexp=self.role_config["role_exp"]["17"]["nextexp"])
        self.save_path.write_text(json.dumps(saved))
        return saved

    def test_resource_purchase_uses_quoted_config_price_and_survives_reconnect(self):
        self.prepare_watchstar()
        # 非周三，前两次每次50元宝。
        while ((self.clock.return_value + 28800) // 86400 + 3) % 7 + 1 == 3:
            self.clock.return_value += 86400
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            before = copy.deepcopy(session.save["role_state"])
            body = recharge.ids([2, 2, 100])
            packets = session.handle(301, 32001, body)
            self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 301)
            self.assertEqual(protocol.pb_get_varint(packets[0][16:], 1), 1)
            self.assertEqual(session.save["role_state"]["gold"], before["gold"] - 100)
            self.assertEqual(session.save["role_state"]["stamina"], before["stamina"] + 100)
            self.assertEqual(session.handle(301, 32001, body), packets)
            self.assertEqual(json.loads(self.save_path.read_text()), session.save)
        status = protocol.parse_ids_pb(self.query_world(300))
        self.assertEqual(status[1:3], [2, 0])
        initialization = self.replay([dict(self.by_seq[12], seq=32003)])[0]
        modules = dict(protocol.get_comb_messages(bytes.fromhex(initialization["hex"])))
        self.assertEqual(protocol.parse_ids_pb(modules[300])[1:3], [2, 0])
        self.assertEqual(self.replay([self.activity_request(301, [3, 1, 50])])[0]["opcode"], 301)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(300))[1:3], [2, 1])

    def test_resource_purchase_discounts_limits_rollback_and_stale_price(self):
        self.prepare_watchstar()
        while ((self.clock.return_value + 28800) // 86400 + 3) % 7 + 1 != 3:
            self.clock.return_value += 86400
        self.assertEqual(self.replay([self.activity_request(301, [2, 1, 25])])[0]["opcode"], 301)
        for values in ([2], [2, 1], [2, 1, 50], [3, 0, 0], [1, 1, 25], [2, 1, 25, 0]):
            disk = self.save_path.read_bytes()
            with self.subTest(values=values):
                self.assertEqual(self.replay([self.activity_request(301, values)])[0]["opcode"], 999999)
                self.assertEqual(self.save_path.read_bytes(), disk)
        saved = json.loads(self.save_path.read_text())
        saved["role_state"]["gold"] = 0
        self.save_path.write_text(json.dumps(saved))
        disk = self.save_path.read_bytes()
        self.assertEqual(self.replay([self.activity_request(301, [3, 1, 25])])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), disk)
        saved["role_state"].update(gold=100000, vip=0)
        saved["resource_purchase_state"]["physical"] = self.role_config["vip"]["0"]["b_physical"]
        self.save_path.write_text(json.dumps(saved))
        self.assertEqual(self.replay([self.activity_request(301, [2, 1, 50])])[0]["opcode"], 999999)
        self.clock.return_value += 86400
        self.assertEqual(protocol.parse_ids_pb(self.query_world(300))[1:3], [0, 0])
        fresh = json.loads(self.save_path.read_text())["resource_purchase_state"]
        self.clock.return_value -= 86400
        self.query_world(300)
        self.assertEqual(json.loads(self.save_path.read_text())["resource_purchase_state"], fresh)

    def test_resource_purchase_save_failure_keeps_balances_and_counts(self):
        self.prepare_watchstar()
        while ((self.clock.return_value + 28800) // 86400 + 3) % 7 + 1 == 3:
            self.clock.return_value += 86400
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            disk, memory = self.save_path.read_bytes(), copy.deepcopy(session.save)
            with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
                session.handle(301, 32002, recharge.ids([2, 1, 50]))
            self.assertEqual(session.save, memory)
            self.assertEqual(self.save_path.read_bytes(), disk)

    def test_resource_purchase_overflow_and_corrupt_counts_fail_closed(self):
        saved = self.prepare_watchstar()
        saved["role_state"]["stamina"] = (1 << 31) - 1
        self.save_path.write_text(json.dumps(saved))
        disk = self.save_path.read_bytes()
        self.assertEqual(self.replay([self.activity_request(301, [2, 1, 50])])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), disk)
        saved["resource_purchase_state"] = {"day": 0, "physical": True, "energy": 0}
        self.save_path.write_text(json.dumps(saved))
        with redirect_stdout(io.StringIO()), self.assertRaisesRegex(ValueError, "购买存档"):
            Session(self.tables, self.save_path, self.step_counts, self.role_config)

    def prepare_qiankun(self):
        saved = self.prepare_watchstar()
        saved["role_state"].update(level=18, vip=4, nextexp=self.role_config["role_exp"]["18"]["nextexp"])
        raw = recruit.new_general(10213, 2000001, self.role_config)
        gear = recharge.ids([1000100, 21301, 1] + [0] * 10)
        player.record_slot_update(saved, protocol.encode_pb_field(1, 2, raw) + protocol.encode_pb_field(2, 2, gear))
        player.change_item_count(saved, 11402, 10, self.role_config, self.now)
        player.change_item_count(saved, 27001, 10, self.role_config, self.now)
        player.change_item_count(saved, 20196, 10, self.role_config, self.now)
        player.change_item_count(saved, 20200, 100000, self.role_config, self.now)
        self.save_path.write_text(json.dumps(saved))
        return saved

    def furnace_request(self, opcode, pairs):
        body = b"".join(protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, iid)
                        + protocol.encode_pb_field(2, 0, count & ((1 << 64) - 1))) for iid, count in pairs)
        return {"opcode": opcode, "seq": 33000, "hex": body.hex()}

    def test_qiankun_queries_use_actual_roster_and_preserve_guide(self):
        saved = self.prepare_qiankun()
        protected = protocol.parse_ids_pb(self.query_world(3704))
        self.assertIn(7059, protected)
        self.assertNotIn(2000001, protected)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(7030)), [0] * 24)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(3850)), [4])
        self.replay([self.activity_request(3850, [3])])
        self.assertEqual(protocol.parse_ids_pb(self.query_world(3850)), [3])
        self.assertEqual(json.loads(self.save_path.read_text())["guide"], saved["guide"])

    def test_qiankun_red_query_keeps_zero_baseline_rows_and_unknown_fields(self):
        saved = self.prepare_qiankun()
        player.change_item_count(saved, 18801, 3, self.role_config, self.now)
        baseline = recharge.ids([18801, 0, 18802, 0]) + protocol.encode_pb_field(9, 2, b"unknown")
        expected = recharge.ids([18801, 3, 18802, 0]) + protocol.encode_pb_field(9, 2, b"unknown")
        self.assertEqual(qiankun.red_query(saved, b"", baseline), expected)

    def test_qiankun_fragment_and_idle_general_refining_deduct_once(self):
        self.prepare_qiankun()
        request = self.furnace_request(1039, [(11402, 2), (2000001, -1)])
        replies = self.replay([request, request])
        self.assertEqual(replies[0], replies[1])
        self.assertEqual(replies[0]["opcode"], 1039)
        saved = json.loads(self.save_path.read_text())
        props = self.entity_records(bytes.fromhex(saved["world_state"]["1200"]), 1, 1)
        fragment = self.role_config["general_fragment"]["11213"]
        self.assertEqual(protocol.pb_get_varint(props[20200], 2), 100000 + 300 + fragment["stovestone"] * fragment["num"])
        self.assertNotIn(2000001, self.entity_records(self.query_world(1002), 1, 2))
        disk = self.save_path.read_bytes()
        self.assertEqual(self.replay([request])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), disk)

    def test_qiankun_equipment_refine_and_atomic_invalid_batch(self):
        saved = self.prepare_qiankun()
        invalid = self.furnace_request(1104, [(27001, 1), (10726, -1)])
        disk = self.save_path.read_bytes()
        self.assertEqual(self.replay([invalid])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), disk)
        request = self.furnace_request(1104, [(27001, 2), (1000100, -1)])
        self.assertEqual(self.replay([request])[0]["opcode"], 1104)
        after = json.loads(self.save_path.read_text())
        self.assertEqual(after["role_state"]["coin"] - saved["role_state"]["coin"], 1400)
        self.assertNotIn(1000100, self.entity_records(self.query_world(1002), 2, 1))

    def test_qiankun_new_equipment_receipt_refunds_actual_critical_cost(self):
        self.prepare_qiankun()
        with patch.object(player.random, "getrandbits", return_value=0):
            reply = self.replay([self.training_request(1101, 1000100, (1,))])[0]
        spent = (1 << 64) - protocol.pb_get_varint(bytes.fromhex(reply["hex"]), 1)
        before = json.loads(self.save_path.read_text())
        request = self.activity_request(1117, [1000100])
        self.assertEqual(self.replay([request])[0]["opcode"], 1117)
        after = json.loads(self.save_path.read_text())
        self.assertEqual(after["role_state"]["coin"], before["role_state"]["coin"] + spent)
        self.assertEqual(protocol.parse_ids_pb(self.entity_records(self.query_world(1002), 2, 1)[1000100])[2], 1)
        self.assertEqual(self.replay([request])[0]["opcode"], 999999)

    def test_qiankun_general_receipt_refunds_pills_and_blocks_unproven_old_growth(self):
        before = self.prepare_qiankun()
        original = self.entity_records(bytes.fromhex(before["world_state"]["1200"]), 1, 1)
        self.replay([self.training_request(1038, 2000001, (2, 0, 0, 0))])
        request = self.activity_request(1035, [2000001])
        self.assertEqual(self.replay([request])[0]["opcode"], 1035)
        raw = self.entity_records(self.query_world(1002), 1, 2)[2000001]
        self.assertTrue(qiankun.pristine_general(raw, self.role_config))
        props = self.entity_records(self.query_world(1200), 1, 1)
        self.assertEqual(protocol.pb_get_varint(props[20196], 2), protocol.pb_get_varint(original[20196], 2))
        saved = json.loads(self.save_path.read_text())
        player.record_slot_update(saved, protocol.encode_pb_field(1, 2, protocol.pb_set_varint(raw, 3, 2)))
        self.save_path.write_text(json.dumps(saved))
        disk = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([request]), 1035, 20000, "安全保护")
        self.assertEqual(self.save_path.read_bytes(), disk)

    def test_qiankun_rejects_ambiguous_cid_duplicate_foreign_and_active_objects(self):
        self.prepare_qiankun()
        cases = [self.furnace_request(1039, [(10213, 1)]), self.furnace_request(1039, [(2000001, -1)] * 2),
                 self.furnace_request(1039, [(7059, -1)]), self.furnace_request(1104, [(9999999, -1)]),
                 self.furnace_request(1036, [(11402, 9999)]), self.activity_request(1117, [10726]),
                 self.activity_request(3704, [1]), self.activity_request(3850, [9])]
        for req in cases:
            disk = self.save_path.read_bytes()
            with self.subTest(opcode=req["opcode"], body=req["hex"]):
                self.assertEqual(self.replay([req])[0]["opcode"], 999999)
                self.assertEqual(self.save_path.read_bytes(), disk)

    def test_qiankun_save_failure_does_not_delete_items(self):
        self.prepare_qiankun()
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            disk, memory = self.save_path.read_bytes(), copy.deepcopy(session.save)
            body = bytes.fromhex(self.furnace_request(1039, [(2000001, -1)])["hex"])
            with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
                session.handle(1039, 33001, body)
            self.assertEqual(session.save, memory)
            self.assertEqual(self.save_path.read_bytes(), disk)

    def test_qiankun_fashion_rebirth_preserves_ownership_and_base_bonus(self):
        self.prepare_qiankun()
        self.replay([self.activity_request(1074, [80001])])
        saved = json.loads(self.save_path.read_text())
        player.change_item_count(saved, 20281, 100, self.role_config, self.now)
        self.save_path.write_text(json.dumps(saved))
        original = json.loads(self.save_path.read_text())
        self.replay([self.activity_request(1072, [80001, 5])])
        trained = json.loads(self.save_path.read_text())
        self.assertGreater(trained["fashion_state"]["levels"]["80001"], 1)
        replies = self.replay([self.activity_request(1077, [80001])])
        self.assertEqual(replies[0]["opcode"], 1077)
        self.assertTrue(any(f["opcode"] == 205 for f in replies))
        after = json.loads(self.save_path.read_text())
        self.assertEqual(after["fashion_state"]["levels"], {"80001": 1})
        self.assertEqual(after["role_state"]["coin"], original["role_state"]["coin"])
        self.assertEqual(after["role_state"]["power"], original["role_state"]["power"])
        self.assertEqual(self.replay([self.activity_request(1077, [80001])])[0]["opcode"], 999999)

    def test_qiankun_general_receipt_mismatch_is_not_estimated(self):
        self.prepare_qiankun()
        self.replay([self.training_request(1038, 2000001, (2, 0, 0, 0))])
        saved = json.loads(self.save_path.read_text())
        raw = self.entity_records(bytes.fromhex(saved["world_state"]["1002"]), 1, 2)[2000001]
        player.record_slot_update(saved, protocol.encode_pb_field(1, 2, protocol.pb_set_varint(raw, 5, 123)))
        self.save_path.write_text(json.dumps(saved))
        disk = self.save_path.read_bytes()
        self.assertEqual(self.replay([self.activity_request(1035, [2000001])])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), disk)

    def test_qiankun_red_essence_uses_native_query_and_claims_once(self):
        saved = self.prepare_qiankun()
        player.change_item_count(saved, 18801, 3, self.role_config, self.now)
        self.save_path.write_text(json.dumps(saved))
        self.assertEqual(protocol.parse_ids_pb(self.query_world(3780)), [18801, 3])
        request = self.furnace_request(6901, [(18801, 3)])
        self.assertEqual(self.replay([request])[0]["opcode"], 6901)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(3780)), [18801, 0])
        props = self.entity_records(self.query_world(1200), 1, 1)
        self.assertEqual(protocol.pb_get_varint(props[20778], 2), 15)
        self.assertEqual(self.replay([request])[0]["opcode"], 999999)

    def test_secret_shop_query_purchase_refresh_and_reconnect(self):
        before = self.prepare_qiankun()
        values = protocol.parse_ids_pb(self.query_world(3650))
        self.assertEqual(len(values), 13)
        self.assertEqual(values[0], self.role_config["vip"]["4"]["mystery_shop_times"])
        self.assertEqual(len(set(values[1::2])), 6)
        self.assertEqual(self.query_world(3650), recharge.ids(values))
        row = self.role_config["mystery_shop"][str(values[1])]
        cost = int(row["consume"].strip(";").split(",")[1])
        self.assertEqual(self.replay([self.activity_request(3651, [1, 1])])[0]["opcode"], 3651)
        after = json.loads(self.save_path.read_text())
        props = self.entity_records(bytes.fromhex(after["world_state"]["1200"]), 1, 1)
        self.assertEqual(protocol.pb_get_varint(props[20200], 2), 100000 - cost)
        self.assertEqual(self.replay([self.activity_request(3651, [1, 1])])[0]["opcode"], 999999)
        self.assertEqual(self.replay([self.activity_request(3652)])[0]["opcode"], 3652)
        after = json.loads(self.save_path.read_text())
        self.assertEqual(after["role_state"]["gold"], before["role_state"]["gold"])
        self.assertEqual(protocol.parse_ids_pb(self.query_world(3650))[0], values[0] - 1)

    def test_secret_shop_scheduled_refresh_and_daily_clock_rollback(self):
        self.prepare_qiankun()
        self.query_world(3650)
        self.replay([self.activity_request(3652)])
        self.clock.return_value += 7200
        disk = self.save_path.read_bytes()
        self.assertEqual(self.replay([self.activity_request(3651, [1, 1])])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), disk)
        self.query_world(3650)
        state = json.loads(self.save_path.read_text())["secret_shop_state"]
        self.assertEqual(state["refreshes"], 1)
        self.clock.return_value += 86400
        self.query_world(3650)
        state = json.loads(self.save_path.read_text())["secret_shop_state"]
        self.assertEqual(state["refreshes"], 0)
        self.clock.return_value -= 86400
        self.query_world(3650)
        self.assertEqual(json.loads(self.save_path.read_text())["secret_shop_state"], state)

    def test_secret_shop_token_then_gold_refresh_and_insufficient_currency(self):
        self.prepare_qiankun()
        self.query_world(3650)
        saved = json.loads(self.save_path.read_text())
        saved["secret_shop_state"]["refreshes"] = self.role_config["vip"]["4"]["mystery_shop_times"]
        props = self.entity_records(bytes.fromhex(saved["world_state"]["1200"]), 1, 1)
        current = protocol.pb_get_varint(props.get(20221, b""), 2) or 0
        player.change_item_count(saved, 20221, 1 - current, self.role_config, self.now)
        self.save_path.write_text(json.dumps(saved))
        self.replay([self.activity_request(3652)])
        after = json.loads(self.save_path.read_text())
        self.assertEqual(after["role_state"]["gold"], saved["role_state"]["gold"])
        self.assertNotIn(20221, self.entity_records(self.query_world(1200), 1, 1))
        self.replay([self.activity_request(3652)])
        after = json.loads(self.save_path.read_text())
        self.assertEqual(after["role_state"]["gold"], saved["role_state"]["gold"] - 50)
        after["role_state"]["gold"] = 0
        self.save_path.write_text(json.dumps(after))
        disk = self.save_path.read_bytes()
        self.assertEqual(self.replay([self.activity_request(3652)])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), disk)

    def test_secret_shop_save_failure_preserves_prices_offers_and_inventory(self):
        self.prepare_qiankun()
        self.query_world(3650)
        for opcode, body in ((3651, recharge.ids([1, 1])), (3652, b"")):
            with self.subTest(opcode=opcode), redirect_stdout(io.StringIO()):
                session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
                disk, memory = self.save_path.read_bytes(), copy.deepcopy(session.save)
                with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
                    session.handle(opcode, 33500, body)
                self.assertEqual(session.save, memory)
                self.assertEqual(self.save_path.read_bytes(), disk)

    def test_secret_shop_all_reward_types_and_levels_are_supported(self):
        saved = self.prepare_qiankun()
        for row in self.role_config["mystery_shop"].values():
            with self.subTest(item=row["id"]):
                gets = [tuple(map(int, entry.split(","))) for entry in row["good"].split(";") if entry]
                working = copy.deepcopy(saved)
                reward = recruit.build_reward(working, gets, self.role_config)
                player.apply_reward(working, reward, self.role_config, self.now)
        for level in (18, 50, 75, 100, 150):
            saved["role_state"]["level"] = level
            secret_shop.refresh(saved, secret_shop.get_state(saved, self.role_config), self.role_config, self.now, 42)
            self.assertEqual(len(saved["secret_shop_state"]["slots"]), 6)

    def seed_level21_account(self):
        saved = self.seed_shop_account()
        saved["role_state"].update(level=21, nextexp=self.role_config["role_exp"]["21"]["nextexp"])
        self.save_path.write_text(json.dumps(saved))
        return saved

    def pet_guide_body(self):
        return (protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 1049)
                                        + protocol.encode_pb_field(2, 2, recharge.ids([91001])))
                + protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 201)
                                           + protocol.encode_pb_field(2, 2, b"\x10\x03\x08\x3b")))

    def test_level21_pet_starter_is_once_only_and_queries_keep_progress(self):
        saved = self.seed_level21_account()
        self.give_props({91001: 10})
        self.assertEqual(protocol.parse_ids_pb(self.query_world(1047)), [21, 0, 0] + [0] * 20)
        replies = self.replay([self.activity_request(1040)])
        self.assertEqual([f["opcode"] for f in replies], [1044, 1040])
        self.assertEqual(protocol.pb_get_varint(self.entity_records(bytes.fromhex(replies[0]["hex"]), 1, 1)[91001], 2), 50)
        self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(replies[1]["hex"])), [0])
        current = json.loads(self.save_path.read_text())
        self.assertTrue(current["pet_state"]["starter_claimed"])
        self.assertEqual(current["guide"], saved["guide"])
        self.assertEqual(current["role_state"], saved["role_state"])
        self.assertEqual(protocol.parse_ids_pb(self.query_world(1040)), [0])
        self.assertEqual(self.query_world(1044), bytes.fromhex(replies[0]["hex"]))
        self.assertEqual(protocol.pb_get_varint(self.entity_records(self.query_world(1200), 1, 1)[91001], 2), 50)

    def test_level21_pet_native_guide_compound_and_set_survive_reconnect(self):
        self.seed_level21_account()
        self.replay([self.activity_request(1040)])
        for step in (1, 2):
            self.replay([{"opcode": 201, "seq": 31010 + step, "hex": (b"\x08\x3b" + protocol.encode_pb_field(2, 0, step)).hex()}])
        before = json.loads(self.save_path.read_text())
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            packets = session.handle(999900, 31013, self.pet_guide_body())
            self.assertEqual(session.handle(999900, 31013, self.pet_guide_body()), packets)
        self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in packets], [999900, 1027, 205])
        messages = protocol.get_comb_messages(packets[0][16:])
        self.assertEqual([mid for mid, _ in messages], [1049, 201])
        iid, cid, phase, update, collected = protocol.parse_ids_pb(messages[0][1])
        self.assertEqual((cid, phase, update, collected), (90001, 0, 1, 1))
        self.assertEqual(protocol.parse_ids_pb(self.query_world(1040)), [0, iid, cid, phase, collected])
        self.assertNotIn(91001, self.entity_records(self.query_world(1200), 1, 1))
        self.assertEqual(json.loads(self.save_path.read_text())["guide"]["sections"]["59"]["step"], 3)
        self.assertEqual(self.replay([{"opcode": 999900, "seq": 31014, "hex": self.pet_guide_body().hex()}])[0]["opcode"], 999999)
        skills = self.query_world_for_values(1043, [iid])
        self.assertEqual(protocol.parse_ids_pb(skills), [21, 0, 0] + [0, 2, 0, 0] * 2 + [0] * 12)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(1040)), [iid, iid, cid, phase, collected])
        for step in (6, 7, 8, 9):
            self.replay([{"opcode": 201, "seq": 31020 + step, "hex": (b"\x08\x3b" + protocol.encode_pb_field(2, 0, step)).hex()}])
        after = json.loads(self.save_path.read_text())
        self.assertEqual(after["guide"]["sections"]["59"]["status"], 2)
        self.assertEqual(after["role_state"]["gold"], before["role_state"]["gold"])
        self.assertGreater(after["role_state"]["power"], before["role_state"]["power"])

    def test_level21_pet_rejects_malformed_comb_and_unowned_or_locked_mutations(self):
        self.seed_level21_account()
        self.replay([self.activity_request(1040)])
        raw = self.pet_guide_body()
        fields = list(protocol.iter_pb_fields(raw))
        bodies = [raw + b"\x10\x00", raw + protocol.encode_pb_field(*fields[0]),
                  b"".join(protocol.encode_pb_field(*f) for f in reversed(fields)),
                  raw.replace(b"\x10\x03\x08\x3b", b"\x10\x04\x08\x3b"),
                  raw.replace(b"\x10\x03\x08\x3b", b"\x10\x03\x08\x3a")]
        for body in bodies:
            disk = self.save_path.read_bytes()
            self.assertEqual(self.replay([{"opcode": 999900, "seq": 31040, "hex": body.hex()}])[0]["opcode"], 999999)
            self.assertEqual(self.save_path.read_bytes(), disk)
        for opcode, values in ((1043, [5000001]), (1049, [91001, 91001]), (1049, [1]), (1048, []), (1046, [1])):
            disk = self.save_path.read_bytes()
            self.assertEqual(self.replay([self.activity_request(opcode, values)])[0]["opcode"], 999999)
            self.assertEqual(self.save_path.read_bytes(), disk)
        saved = json.loads(self.save_path.read_text())
        saved["role_state"]["level"] = 20
        self.save_path.write_text(json.dumps(saved))
        disk = self.save_path.read_bytes()
        self.assertEqual(self.replay([self.activity_request(1049, [91001])])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), disk)

    def test_level21_pet_save_failures_never_commit_starter_compound_or_set(self):
        self.seed_level21_account()
        for opcode, body in ((1040, b""), (999900, self.pet_guide_body()), (1043, recharge.ids([5000001]))):
            with redirect_stdout(io.StringIO()):
                session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
                if opcode != 1040:
                    session.handle(1040, 31050, b"")
                if opcode == 999900:
                    session.handle(201, 31051, b"\x08\x3b\x10\x02")
                if opcode == 1043:
                    session.handle(1049, 31051, recharge.ids([91001]))
                memory, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
                with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
                    session.handle(opcode, 31052, body)
            self.assertEqual(session.save, memory)
            self.assertEqual(self.save_path.read_bytes(), disk)

    def test_level21_pet_starter_preserves_surplus_and_never_refills_spent_fragments(self):
        self.seed_level21_account()
        self.give_props({91001: 80})
        self.assertEqual(protocol.parse_ids_pb(self.query_world(1040)), [0])
        self.give_props({91001: -31})
        disk = self.save_path.read_bytes()
        self.assertEqual(self.replay([self.activity_request(1049, [91001])])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), disk)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(1040)), [0])
        self.assertEqual(protocol.pb_get_varint(self.entity_records(self.query_world(1200), 1, 1)[91001], 2), 49)

    def test_level21_pet_corrupt_ownership_fails_closed(self):
        saved = self.seed_level21_account()
        for state in ({"active": 1, "pets": [], "starter_claimed": False},
                      {"active": 0, "pets": [[5000001, 90001, 0, 1]] * 2, "starter_claimed": True},
                      {"active": 0, "pets": [], "starter_claimed": 1},
                      {"active": 0, "pets": [[5000001, 90001, 99, 1]], "starter_claimed": True}):
            self.save_path.write_text(json.dumps(dict(saved, pet_state=state)))
            disk = self.save_path.read_bytes()
            with redirect_stdout(io.StringIO()), self.assertRaises(ValueError):
                Session(self.tables, self.save_path, self.step_counts, self.role_config)
            self.assertEqual(self.save_path.read_bytes(), disk)

    def seed_level21_pet(self):
        self.seed_level21_account()
        self.replay([self.activity_request(1040)])
        reply = self.replay([self.activity_request(1049, [91001])])[0]
        iid = protocol.parse_ids_pb(bytes.fromhex(reply["hex"]))[0]
        self.replay([self.activity_request(1043, [iid])])
        return json.loads(self.save_path.read_text())

    def test_pet_reentry_gift_trigger_is_persistent_and_never_grants_free_items(self):
        before = self.seed_level21_pet()
        self.replay([{"opcode": 201, "seq": 31900, "hex": "083b1009"}])
        self.clock.return_value += 1
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            reply = session.handle(2882, 31901, bytes.fromhex("08dcf707"))
            self.assertEqual(struct.unpack(">IIII", reply[0][:16])[2], 2882)
            values = protocol.parse_ids_pb(reply[0][16:])
            self.assertEqual(values[:2], [130012, 0])
            started = session.save["pet_gift_state"]["triggered_at"]
            self.assertEqual(started, self.clock.return_value)
            self.assertEqual(session.save["pet_gift_state"]["checked_at"], started)
            self.assertEqual(session.save["world_state"], before["world_state"])
            self.assertEqual(session.save["role_state"], before["role_state"])
            self.clock.return_value += 30
            later = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            reply = later.handle(2882, 31902, bytes.fromhex("08dcf707"))
            self.assertEqual(protocol.parse_ids_pb(reply[0][16:]), [130012, 0, values[2] - 30])
            self.assertEqual(later.save["pet_gift_state"]["triggered_at"], started)
            self.assertEqual(later.save["pet_state"], session.save["pet_state"])
            disk, memory = self.save_path.read_bytes(), copy.deepcopy(later.save)
            self.assertEqual(struct.unpack(">IIII", later.handle(2881, 31903, recharge.ids([130012]))[0][:16])[2], 999999)
            self.assertEqual((later.save, self.save_path.read_bytes()), (memory, disk))

    def test_pet_gift_first_trigger_without_query_or_after_clock_rollback(self):
        self.seed_level21_pet()
        self.replay([{"opcode": 201, "seq": 31900, "hex": "083b1009"}])
        saved = json.loads(self.save_path.read_text())
        self.clock.return_value = self.now + 30
        for checked_at in (0, self.now + 60):
            with self.subTest(checked_at=checked_at), redirect_stdout(io.StringIO()):
                saved["pet_gift_state"] = {"triggered_at": 0, "checked_at": checked_at, "paid": False, "claimed": False}
                self.save_path.write_text(json.dumps(saved))
                session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
                reply = session.handle(2882, 31901, recharge.ids([130012]))
                self.assertEqual(struct.unpack(">IIII", reply[0][:16])[2], 2882)
                self.assertEqual(protocol.parse_ids_pb(reply[0][16:]),
                                 [130012, 0, self.role_config["trigger_gift2"]["130012"]["time"] * 60])
                start = max(self.clock.return_value, checked_at)
                expected = {"triggered_at": start, "checked_at": start, "paid": False, "claimed": False}
                self.assertEqual(session.save["pet_gift_state"], expected)
                self.assertEqual(json.loads(self.save_path.read_text())["pet_gift_state"], expected)
                for key in ("pet_state", "guide", "role_state", "world_state"):
                    self.assertEqual(session.save[key], saved[key])

    def test_pet_gift_payment_claim_and_expiration_are_atomic(self):
        self.seed_level21_pet()
        self.replay([{"opcode": 201, "seq": 31910, "hex": "083b1009"}])
        self.replay([self.activity_request(2882, [130012])])
        before = json.loads(self.save_path.read_text())
        request = protocol.encode_pb_field(1, 2, recharge.ids([4])) + protocol.encode_pb_field(1, 2, recharge.ids([130012]))
        order_reply = self.replay([{"opcode": 115, "seq": 31911, "hex": request.hex()}])[0]
        order = protocol.pb_get_varint(next(v for n, w, v in protocol.iter_pb_fields(bytes.fromhex(order_reply["hex"])) if (n, w) == (1, 2)), 1)
        self.replay([self.activity_request(116, [order])])
        paid = json.loads(self.save_path.read_text())
        self.assertTrue(paid["pet_gift_state"]["paid"])
        self.assertEqual(paid["role_state"]["gold"], before["role_state"]["gold"])
        self.assertEqual(paid["recharge_state"]["bought"], before["recharge_state"]["bought"])
        self.replay([self.activity_request(116, [order])])
        replies = self.replay([self.activity_request(2881, [130012])])
        self.assertEqual(replies[0]["opcode"], 2881)
        after = json.loads(self.save_path.read_text())
        self.assertEqual(pets.fragments(after, self.role_config)[91001], pets.fragments(before, self.role_config)[91001] + 20)
        disk = self.save_path.read_bytes()
        self.assertEqual(self.replay([self.activity_request(2881, [130012])])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), disk)

    def test_stone_gift_payment_claim_preserves_pet_gift_and_never_grants_regular_gold(self):
        self.seed_godstone_account()
        self.replay([{"opcode": 201, "seq": 34010, "hex": "08681001"}])
        before = json.loads(self.save_path.read_text())
        self.clock.return_value += 1
        trigger = self.replay([self.activity_request(2882, [130013])])[0]
        self.assertEqual(trigger["opcode"], 2882)
        self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(trigger["hex"])), [130013, 0, 43200])
        request = protocol.encode_pb_field(1, 2, recharge.ids([3])) + protocol.encode_pb_field(1, 2, recharge.ids([130013]))
        order_reply = self.replay([{"opcode": 115, "seq": 34011, "hex": request.hex()}])[0]
        order = protocol.pb_get_varint(next(v for n, w, v in protocol.iter_pb_fields(bytes.fromhex(order_reply["hex"])) if (n, w) == (1, 2)), 1)
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            memory, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
            with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
                session.handle(116, 34011, recharge.ids([order]))
            self.assertEqual((session.save, self.save_path.read_bytes()), (memory, disk))
        replies = self.replay([self.activity_request(116, [order])])
        push = next(r for r in replies if r["opcode"] == 2882)
        self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(push["hex"]))[:2], [130013, 1])
        paid = json.loads(self.save_path.read_text())
        self.assertEqual(paid["pet_gift_state"], before["pet_gift_state"])
        self.assertEqual(paid["role_state"]["gold"], before["role_state"]["gold"])
        self.assertEqual(paid["recharge_state"]["bought"], before["recharge_state"]["bought"])
        self.clock.return_value += 43201
        self.replay([self.activity_request(116, [order])])
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            memory, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
            with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
                session.handle(2881, 34011, recharge.ids([130013]))
            self.assertEqual((session.save, self.save_path.read_bytes()), (memory, disk))
        reply = self.replay([self.activity_request(2881, [130013])])[0]
        self.assertEqual(reply["opcode"], 2881)
        after = json.loads(self.save_path.read_text())
        self.assertEqual(after["role_state"]["coin"], before["role_state"]["coin"] + 100000)
        props = self.entity_records(bytes.fromhex(after["world_state"]["1200"]), 1, 1)
        old_props = self.entity_records(bytes.fromhex(before["world_state"]["1200"]), 1, 1)
        for cid, count in ((20223, 300), (20262, 5), (20014, 1)):
            self.assertEqual(protocol.pb_get_varint(props[cid], 2), (protocol.pb_get_varint(old_props.get(cid, b""), 2) or 0) + count)
        disk = self.save_path.read_bytes()
        self.assertEqual(self.replay([self.activity_request(2881, [130013])])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), disk)

    def test_stone_gift_rejects_locked_expired_unknown_and_failed_save_without_mutation(self):
        self.seed_godstone_account()
        disk = self.save_path.read_bytes()
        self.assertEqual(self.replay([self.activity_request(2882, [130013])])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), disk)
        self.replay([{"opcode": 201, "seq": 34010, "hex": "08681001"}])
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            memory, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
            with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
                session.handle(2882, 34012, recharge.ids([130013]))
            self.assertEqual((session.save, self.save_path.read_bytes()), (memory, disk))
        self.replay([self.activity_request(2882, [130013])])
        request = protocol.encode_pb_field(1, 2, recharge.ids([4])) + protocol.encode_pb_field(1, 2, recharge.ids([130013]))
        disk = self.save_path.read_bytes()
        self.assertEqual(self.replay([{"opcode": 115, "seq": 34013, "hex": request.hex()}])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), disk)
        self.clock.return_value += 43200
        expired = self.replay([self.activity_request(2882, [130013])])[0]
        self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(expired["hex"])), [130013, (1 << 64) - 2, 0])
        self.clock.return_value -= 1
        expired = self.replay([self.activity_request(2882, [130013])])[0]
        self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(expired["hex"]))[1:], [(1 << 64) - 2, 0])

    def test_pet_advancement_and_collection_charge_config_and_restore_on_reconnect(self):
        saved = self.seed_level21_pet()
        self.give_props({91001: 100, 20166: 100})
        before = json.loads(self.save_path.read_text())
        reply = self.replay([self.activity_request(1046, [5000001])])
        self.assertEqual(reply[0]["opcode"], 1046)
        self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(reply[0]["hex"]))[3:23:4], [0] * 5)
        after = json.loads(self.save_path.read_text())
        self.assertEqual(after["pet_state"]["pets"][0][2], 1)
        self.assertEqual(after["role_state"]["coin"], before["role_state"]["coin"] - 100000)
        self.assertEqual(pets.fragments(after, self.role_config)[91001], 95)
        self.assertEqual(pets.skill_slots(after["pet_state"], self.role_config), 3)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(1040))[3:], [1, 1])
        # 图鉴第一笔要求39级，不能只凭足够材料放行。
        disk = self.save_path.read_bytes()
        self.assertEqual(self.replay([self.activity_request(1062, [5000001])])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), disk)
        after["role_state"]["level"] = 39
        self.save_path.write_text(json.dumps(after))
        reply = self.replay([self.activity_request(1062, [5000001])])
        self.assertEqual(reply[0]["opcode"], 1062)
        result = json.loads(self.save_path.read_text())
        self.assertEqual(result["pet_state"]["pets"][0][3], 2)
        self.assertEqual(result["role_state"]["coin"], after["role_state"]["coin"] - 30000)
        self.assertEqual(pets.fragments(result, self.role_config)[91001], 75)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(1040))[-1], 2)
        self.assertEqual(result["guide"], saved["guide"])

    def test_pet_locked_reset_refunds_only_unlocked_points_and_bonuses(self):
        self.seed_level21_pet()
        with patch.object(player.random, "getrandbits", return_value=1):
            for _ in range(3):
                self.replay([self.activity_request(1048)])
        before = json.loads(self.save_path.read_text())
        first = before["pet_state"]["skills"][0]
        self.replay([self.activity_request(1060, [1])])
        locked = json.loads(self.save_path.read_text())
        self.assertEqual(locked["pet_state"]["locks"], [1, 0, 0, 0, 0])
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            result = session.handle(1061, 31920, b"")
            self.assertEqual(session.handle(1061, 31920, b""), result)
        after = json.loads(self.save_path.read_text())
        self.assertEqual(after["role_state"]["gold"], before["role_state"]["gold"] - 150)
        self.assertEqual(after["pet_state"]["skills"], [first] + [[0, 0]] * 4)
        self.assertEqual(after["pet_state"]["spent_points"], first[1])
        disk = self.save_path.read_bytes()
        self.assertEqual(self.replay([self.activity_request(1061)])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), disk)
        self.replay([self.activity_request(1060, [1])])
        self.replay([self.activity_request(1061)])
        final = json.loads(self.save_path.read_text())
        self.assertEqual(final["pet_state"]["spent_points"], 0)
        self.assertEqual(final["pet_state"]["skills"], [[0, 0]] * 5)
        self.assertEqual(final["pet_state"]["locks"], [0] * 5)

    def test_pet_quality_promotions_require_earned_points_and_reset_returns_them(self):
        saved = self.seed_level21_pet()
        saved["role_state"]["level"] = 150
        # 测试专用已养成角色，旧外部记录不产生可退款收据。
        saved["pet_state"]["pets"][0][2] = 26
        saved["pet_state"].update(skills=[[92004, 3], [0, 0], [0, 0], [0, 0], [0, 0]], spent_points=3)
        self.save_path.write_text(json.dumps(saved))
        self.assertEqual(protocol.parse_ids_pb(self.query_world(1047))[:3], [147, 1, 1])
        self.assertEqual(self.replay([self.activity_request(1064, [1])])[0]["opcode"], 1064)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(1047))[:3], [147, 0, 1])
        self.replay([self.activity_request(1064, [1])])
        final = json.loads(self.save_path.read_text())
        self.assertEqual(final["pet_state"]["skills"][0], [92031, 3])
        self.assertEqual(protocol.parse_ids_pb(self.query_world(1047))[:3], [147, 0, 0])
        disk = self.save_path.read_bytes()
        self.assertEqual(self.replay([self.activity_request(1064, [1])])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), disk)
        self.replay([self.activity_request(1061)])
        self.assertEqual(protocol.parse_ids_pb(self.query_world(1047))[:3], [150, 1, 1])

    def test_pet_rebirth_refunds_receipt_once_and_keeps_owned_pet(self):
        self.seed_level21_pet()
        self.give_props({91001: 100, 20166: 100})
        before = json.loads(self.save_path.read_text())
        self.replay([self.activity_request(1046, [5000001])])
        disk = self.save_path.read_bytes()
        self.assertEqual(self.replay([self.activity_request(1065, [5000001])])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), disk)
        self.replay([self.activity_request(1043, [0])])
        self.replay([self.activity_request(1065, [5000001])])
        after = json.loads(self.save_path.read_text())
        self.assertEqual(after["pet_state"]["pets"], [[5000001, 90001, 0, 1]])
        self.assertEqual(after["pet_state"]["receipts"], {})
        self.assertEqual(after["role_state"]["coin"], before["role_state"]["coin"])
        self.assertEqual(after["world_state"]["1200"], before["world_state"]["1200"])
        self.assertEqual(after["role_state"]["gold"], before["role_state"]["gold"] - self.role_config["renascence"]["1"]["pet_reborn"])
        disk = self.save_path.read_bytes()
        self.assertEqual(self.replay([self.activity_request(1065, [5000001])])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), disk)

    def test_pet_owned_stats_migrate_once_without_erasing_learned_skills(self):
        saved = self.seed_level21_pet()
        saved["pet_state"]["owned_stats"] = False
        # 构造补丁前只有被动属性、没有图鉴/基础加成的旧档。
        bonus = pets.attributes({**saved, "pet_state": {**saved["pet_state"], "owned_stats": True}}, self.role_config)
        world = bytes.fromhex(saved["world_state"]["1002"])
        units = self.entity_records(world, 1, 2)
        for iid in self.entity_records(world, 4, 2):
            if iid:
                raw, _ = development.adjust(units[iid], {field: -int(n) for field, n in bonus.items()})
                player.record_slot_update(saved, protocol.encode_pb_field(1, 2, raw))
                player.record_protagonist_general(saved, raw)
        saved["pet_state"].update(skills=[[92010, 2], [92014, 1], [0, 0], [0, 0], [0, 0]], spent_points=3)
        self.save_path.write_text(json.dumps(saved))
        reply = self.replay([self.activity_request(1040)])
        self.assertIn(1027, [r["opcode"] for r in reply])
        after = json.loads(self.save_path.read_text())
        self.assertEqual(after["pet_state"]["skills"], saved["pet_state"]["skills"])
        self.assertEqual(after["pet_state"]["spent_points"], 3)
        self.query_world(1040)
        final = json.loads(self.save_path.read_text())
        self.assertEqual(final["world_state"], after["world_state"])
        self.assertEqual(final["role_state"], after["role_state"])

    def test_pet_all_configured_phases_and_collection_levels_are_valid(self):
        saved = self.seed_level21_account()
        saved["role_state"]["level"] = 150
        for row in self.role_config["pet3_fragment"].values():
            player.change_item_count(saved, row["debris"], row["number"], self.role_config, self.now)
            result, _ = pets.prepare(1049, saved, recharge.ids([row["debris"]]), self.role_config)
            iid = protocol.parse_ids_pb(result)[0]
            pet = next(p for p in saved["pet_state"]["pets"] if p[0] == iid)
            while str(pet[2] + 1) in self.role_config["pet3_attr"][str(pet[1])]:
                with self.subTest(cid=pet[1], phase=pet[2]):
                    _, costs = pets.prepare(1046, saved, recharge.ids([iid]), self.role_config)
                    self.assertTrue(all(n > 0 for _, n in costs))
            while str(pet[3] + 1) in self.role_config["pet3_illustrated"][str(pet[1])]:
                with self.subTest(cid=pet[1], collect=pet[3]):
                    _, costs = pets.prepare(1062, saved, recharge.ids([iid]), self.role_config)
                    self.assertTrue(all(n > 0 for _, n in costs))
        self.assertEqual(len(saved["pet_state"]["pets"]), 7)
        self.assertTrue(all(n >= 0 for n in pets.attributes(saved, self.role_config).values()))

    def test_pet_battle_heals_lost_hp_and_does_not_change_its_inputs(self):
        attack = {2: self.combat_unit(10201, hp=1000, atk=1, speed=100)}
        defense = {2: self.combat_unit(10201, iid=2, hp=10000, atk=100, speed=200)}
        pet = {"iid": 5000001, "cid": 90001, "phase": 0, "level": 1}
        before = copy.deepcopy((attack, defense, pet))
        report = battle.simulate(attack, defense, self.role_config, 1, attack_pet=pet)
        self.assertEqual(report, battle.simulate(attack, defense, self.role_config, 1, attack_pet=pet))
        self.assertEqual((attack, defense, pet), before)
        actions = [a for a in report["b"]["a"] if a["s"].get("S") == 12801]
        self.assertEqual(actions[0]["s"]["p"], [0])
        self.assertEqual(actions[0]["e"][0]["m"]["m"], 0)
        self.assertEqual(actions[1]["e"][0]["m"]["m"], -10)
        self.assert_battle_report(report)

    def test_pet_all_configured_active_skills_produce_consistent_reports(self):
        for cid, rows in self.role_config["pet3_attr"].items():
            checked = set()
            for row in rows.values():
                if row["skillid"] in checked:
                    continue
                checked.add(row["skillid"])
                with self.subTest(cid=cid, phase=row["phase"], skill=row["skillid"]):
                    attack = {pos: self.combat_unit(10201, iid=i, hp=5000, atk=100, speed=100) for i, pos in enumerate(battle.POSITIONS, 1)}
                    defense = {pos: self.combat_unit(10201, iid=i + 10, hp=5000, atk=100, speed=100) for i, pos in enumerate(battle.POSITIONS, 1)}
                    pet = {"iid": 5000001, "cid": int(cid), "phase": row["phase"], "level": 1}
                    report = battle.simulate(attack, defense, self.role_config, 3, attack_pet=pet)
                    self.assertTrue(any(a["s"].get("S") == row["skillid"] for a in report["b"]["a"]))
                    self.assert_battle_report(report)

    def test_pet_battle_buff_debuff_and_damage_use_real_targets(self):
        for cid, expected in ((90002, 90), (90003, 119)):
            with self.subTest(cid=cid):
                attack = {2: self.combat_unit(10201, atk=200, hp=10000, speed=200, **{"def": 100})}
                defense = {2: self.combat_unit(10201, iid=2, atk=200, hp=10000, speed=100, **{"def": 100})}
                report = battle.simulate(attack, defense, self.role_config, 1,
                                        attack_pet={"iid": 5000001, "cid": cid, "phase": 0, "level": 1})
                first = next(a for a in report["b"]["a"] if a["s"].get("p") == [2] and a["s"]["r"] == (cid == 90003))
                self.assertEqual(first["e"][0]["m"]["m"], expected)
                self.assert_battle_report(report)
        with patch.object(battle.random.Random, "random", return_value=0):
            report = battle.simulate({2: self.combat_unit(10201, atk=200)}, {2: self.combat_unit(10201, iid=2, hp=1000)},
                                    self.role_config, 1, attack_pet={"iid": 5000001, "cid": 90008, "phase": 0, "level": 1})
        self.assertEqual(report["b"]["a"][0]["s"]["p"], [0])
        self.assertEqual(report["b"]["a"][0]["e"][0]["m"]["m"], 400)
        self.assert_battle_report(report)

    def test_pet_reports_convert_using_real_apk_animations(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("魔宠战报播放转换需本机已有 lupa.lua51")
        package = Path(server.BASE_DIR) / "zyj_local.apk"
        if not package.exists():
            self.skipTest("魔宠动画验证需要本地APK")
        with patch.object(apk_builder, "SRC_APK", str(package)):
            converter = apk_builder.read_script("battleReportConvert").decode("utf-8")
            abbreviations = apk_builder.read_script("BattleReportAbbToKey").decode("utf-8")
        config = dict(self.role_config)
        with zipfile.ZipFile(Path(server.BASE_DIR) / "configs_sec5.zip") as archive:
            for name in ("generalanimation", "skillanimation", "personalboss_att"):
                config[name] = json.loads(archive.read("5/" + name + ".json"))
        lua = LuaRuntime()
        lua.globals().gamedata = lua.table_from({"config": config}, recursive=True)
        lua.execute('''print=function() end;printT=print
            table.getTableLength=function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
            CCFileUtils={sharedFileUtils=function(self) return self end,fullPathForFilename=function(self,p) return p end}
            ui={Split=function(s,sep) local t={} for v in string.gmatch(s,'[^'..sep..']+') do t[#t+1]=v end return t end}''')
        with zipfile.ZipFile(package) as archive:
            assets = {}
            def load_asset(path):
                if path not in assets:
                    matches = [n for n in archive.namelist() if n.endswith("/" + path)]
                    self.assertEqual(len(matches), 1, path)
                    assets[path] = json.loads(archive.read(matches[0]))
                return lua.table_from(assets[path], recursive=True)
            lua.globals().LoadJsonFileToTable = load_asset
            lua.execute(converter)
            lua.execute(abbreviations)
            for cid, rows in config["pet3_attr"].items():
                checked = set()
                for row in rows.values():
                    if row["skillid"] in checked:
                        continue
                    checked.add(row["skillid"])
                    with self.subTest(cid=cid, skill=row["skillid"]):
                        team = {pos: self.combat_unit(10201, iid=i, hp=5000, atk=100) for i, pos in enumerate(battle.POSITIONS, 1)}
                        report = battle.simulate(team, team, config, 3,
                            attack_pet={"iid": 5000001, "cid": int(cid), "phase": row["phase"], "level": 1})
                        decoded = json.loads(lua.globals().ReplaceAbbToKey(json.dumps(report)))
                        native = lua.table_from(decoded, recursive=True)
                        attack, defense = lua.globals().getBattleInitSlotInfo(native)
                        animations, ext = lua.globals().convertBattleReportToAnimationSub(native, attack, defense)
                        self.assertGreater(len(animations), 1)
                        for side, key in (("attack", "atk"), ("defense", "def")):
                            for pos, unit in report["endmeta"][side].items():
                                self.assertEqual(ext.endinfo[key][pos].hp, unit["h"])

    def test_pet_learning_points_accumulate_after_level21(self):
        saved = self.seed_level21_pet()
        saved["pet_state"].update(skills=[[92001, 10], [92005, 10], [0, 0], [0, 0], [0, 0]], spent_points=20)
        for level in (21, 22, 39, 60, 150):
            with self.subTest(level=level):
                saved["role_state"]["level"] = level
                self.assertEqual(protocol.parse_ids_pb(pets.skills(saved, saved["pet_state"], self.role_config))[0], level - 20)

    def test_pet_new_transactions_save_failure_keeps_all_resources_and_progress(self):
        saved = self.seed_level21_pet()
        saved["role_state"].update(level=150, coin=2000000000, gold=2000000000)
        for cid in (91001, 91004, 20166, 20390):
            player.change_item_count(saved, cid, 100000, self.role_config, self.now)
        saved["pet_state"]["pets"][0][2] = 26
        saved["pet_state"].update(skills=[[92004, 2], [92010, 2], [0, 0], [0, 0], [0, 0]], spent_points=4)
        pets.prepare(1049, saved, recharge.ids([91004]), self.role_config)
        pets.prepare(1046, saved, recharge.ids([5000002]), self.role_config)
        saved["guide"]["sections"]["59"] = {"status": 2, "step": 9, "steps": list(range(1, 10))}
        self.save_path.write_text(json.dumps(saved))
        for opcode, values in ((1046, [5000001]), (1060, [1]), (1061, []), (1062, [5000001]),
                               (1064, [1]), (1065, [5000002]), (2882, [130012])):
            with self.subTest(opcode=opcode), redirect_stdout(io.StringIO()):
                session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
                memory, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
                with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
                    session.handle(opcode, 31940, recharge.ids(values))
                self.assertEqual((session.save, self.save_path.read_bytes()), (memory, disk))

    def test_pet_new_mutations_reject_unowned_malformed_and_insufficient_resources(self):
        self.seed_level21_pet()
        self.give_props({91001: 100, 20166: 100})
        saved = json.loads(self.save_path.read_text())
        saved["role_state"]["coin"] = 0
        self.save_path.write_text(json.dumps(saved))
        cases = [(1046, recharge.ids([5000001])), (1046, recharge.ids([5000002])),
                 (1062, recharge.ids([5000001])), (1064, recharge.ids([1])),
                 (1060, recharge.ids([0])), (1065, recharge.ids([5000002])),
                 (1065, recharge.ids([5000001, 5000001]))]
        cases += [(op, recharge.ids([5000001]) + b"\x10\x00") for op in (1046, 1060, 1062, 1064, 1065)]
        cases += [(op, recharge.ids([1])) for op in (1048, 1061, 1040, 1044, 1047)]
        for opcode, body in cases:
            with self.subTest(opcode=opcode, body=body.hex()), redirect_stdout(io.StringIO()):
                session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
                memory, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
                self.assertEqual(struct.unpack(">IIII", session.handle(opcode, 31950, body)[0][:16])[2], 999999)
                self.assertEqual((session.save, self.save_path.read_bytes()), (memory, disk))

    def test_pet_gift_deadline_cannot_restart_on_reentry_or_clock_rollback(self):
        self.seed_level21_pet()
        self.replay([{"opcode": 201, "seq": 31960, "hex": "083b1009"}])
        self.replay([self.activity_request(2882, [130012])])
        before = json.loads(self.save_path.read_text())
        start = before["pet_gift_state"]["triggered_at"]
        deadline = start + self.role_config["trigger_gift2"]["130012"]["time"] * 60
        with patch.object(player.time, "time", return_value=deadline):
            reply = self.replay([self.activity_request(2882, [130012])])[0]
        self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(reply["hex"]))[1:], [(1 << 64) - 2, 0])
        with patch.object(player.time, "time", return_value=start + 1):
            reply = self.replay([self.activity_request(2882, [130012])])[0]
        self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(reply["hex"]))[1:], [(1 << 64) - 2, 0])
        request = protocol.encode_pb_field(1, 2, recharge.ids([4])) + protocol.encode_pb_field(1, 2, recharge.ids([130012]))
        disk = self.save_path.read_bytes()
        self.assertEqual(self.replay([{"opcode": 115, "seq": 31961, "hex": request.hex()}])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), disk)
        for values in ([130012, 130012], [130014], []):
            self.assertEqual(self.replay([self.activity_request(2882, values)])[0]["opcode"], 999999)
            self.assertEqual(self.save_path.read_bytes(), disk)

    def test_pet_rebirth_rejects_unknown_history_and_skill_point_loss(self):
        saved = self.seed_level21_pet()
        saved["role_state"]["level"] = 150
        saved["pet_state"].update(active=0, pets=[[5000001, 90001, 14, 1]])
        self.save_path.write_text(json.dumps(saved))
        disk = self.save_path.read_bytes()
        self.assertEqual(self.replay([self.activity_request(1065, [5000001])])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), disk)
        saved["pet_state"].update(skills=[[92025, 1], [0, 0], [0, 0], [0, 0], [0, 0]], spent_points=1,
                                  receipts={"5000001": {"pet": [5000001, 90001, 14, 1], "costs": [[1000, 100000]]}})
        self.save_path.write_text(json.dumps(saved))
        disk = self.save_path.read_bytes()
        self.assertEqual(self.replay([self.activity_request(1065, [5000001])])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), disk)
        saved["pet_state"]["receipts"]["5000001"]["pet"][2] = 13
        self.save_path.write_text(json.dumps(saved))
        with redirect_stdout(io.StringIO()), self.assertRaises(ValueError):
            Session(self.tables, self.save_path, self.step_counts, self.role_config)

    def test_level21_pet_study_spends_points_once_and_updates_current_generals(self):
        before = self.seed_level21_pet()
        with redirect_stdout(io.StringIO()), patch.object(player.random, "getrandbits", return_value=1):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            packets = session.handle(1048, 32000, b"")
            self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in packets], [1048, 1027, 205])
            self.assertEqual(session.handle(1048, 32000, b""), packets)
        saved = json.loads(self.save_path.read_text())
        self.assertEqual(saved["pet_state"]["skills"][0], [92002, 1])
        self.assertEqual(protocol.parse_ids_pb(self.query_world(1047))[0], 20)
        self.assertEqual(saved["pet_state"]["spent_points"], 1)
        old = self.entity_records(bytes.fromhex(before["world_state"]["1002"]), 1, 2)
        new = self.entity_records(bytes.fromhex(saved["world_state"]["1002"]), 1, 2)
        active = {i for i in self.entity_records(bytes.fromhex(saved["world_state"]["1002"]), 4, 2) if i}
        for iid, raw in new.items():
            self.assertEqual(protocol.pb_get_varint(raw, 6), protocol.pb_get_varint(old[iid], 6) + (140 if iid in active else 0))
        self.assertEqual(saved["role_state"]["power"] - before["role_state"]["power"], 140 * len(active))
        for key in ("coin", "gold", "stamina", "energy"):
            self.assertEqual(saved["role_state"][key], before["role_state"][key])
        self.assertEqual(saved["guide"], before["guide"])
        self.assertEqual(bytes.fromhex(saved["world_state"]["1200"]), bytes.fromhex(before["world_state"]["1200"]))

    def test_level21_pet_study_fills_then_upgrades_and_rejects_exhausted_points(self):
        self.seed_level21_pet()
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            for seq in range(21):
                self.assertEqual(struct.unpack(">IIII", session.handle(1048, 32100 + seq, b"")[0][:16])[2], 1048)
            state = session.save["pet_state"]
            self.assertEqual(sum(level for _, level in state["skills"]), 21)
            self.assertEqual(sum(bool(cid) for cid, _ in state["skills"]), 2)
            self.assertEqual(len({cid for cid, _ in state["skills"] if cid}), 2)
            memory, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
            self.assertEqual(struct.unpack(">IIII", session.handle(1048, 32200, b"")[0][:16])[2], 999999)
            self.assertEqual((session.save, self.save_path.read_bytes()), (memory, disk))
            self.assertEqual(struct.unpack(">IIII", session.handle(1048, 32201, b"\x08\x01")[0][:16])[2], 999999)
            self.assertEqual((session.save, self.save_path.read_bytes()), (memory, disk))
            session.save["role_state"]["level"] = 150
            state["skills"] = [[92001, 30], [92005, 30], [0, 0], [0, 0], [0, 0]]
            state["spent_points"] = 60
            memory = copy.deepcopy(session.save)
            self.assertEqual(struct.unpack(">IIII", session.handle(1048, 32202, b"")[0][:16])[2], 999999)
            self.assertEqual((session.save, self.save_path.read_bytes()), (memory, disk))

    def test_level21_pet_learned_bonuses_follow_replacement_without_stacking(self):
        baseline = self.seed_level21_pet()
        player.apply_reward(baseline, recruit.build_reward(baseline, [(10401, 1)], self.role_config), self.role_config, self.now)
        self.save_path.write_text(json.dumps(baseline))
        with patch.object(player.random, "getrandbits", return_value=1):
            self.replay([self.activity_request(1048)])
        learned = json.loads(self.save_path.read_text())
        world = bytes.fromhex(baseline["world_state"]["1002"])
        generals, slots = self.entity_records(world, 1, 2), self.entity_records(world, 4, 1)
        idle = next(i for i, raw in generals.items() if protocol.pb_get_varint(raw, 1) == 10401)
        old = protocol.pb_get_varint(slots[3], 2)
        for iid in (idle, old, idle, old):
            body = bytes.fromhex(self.change_general_request(3, iid)["hex"])
            for save in (baseline, learned):
                player.record_slot_update(save, formation.change(save, 1003, body, self.role_config))
            current = bytes.fromhex(learned["world_state"]["1002"])
            active = {i for i in self.entity_records(current, 4, 2) if i}
            plain = self.entity_records(bytes.fromhex(baseline["world_state"]["1002"]), 1, 2)
            for general, raw in self.entity_records(current, 1, 2).items():
                self.assertEqual(protocol.pb_get_varint(raw, 6) - protocol.pb_get_varint(plain[general], 6), 140 if general in active else 0)

    def test_level21_pet_study_save_failure_and_overflow_keep_points_and_stats(self):
        self.seed_level21_pet()
        with redirect_stdout(io.StringIO()), patch.object(player.random, "getrandbits", return_value=1):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            memory, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
            with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
                session.handle(1048, 32300, b"")
            self.assertEqual((session.save, self.save_path.read_bytes()), (memory, disk))
            world = bytes.fromhex(session.save["world_state"]["1002"])
            iid = next(i for i in self.entity_records(world, 4, 2) if i)
            raw = self.entity_records(world, 1, 2)[iid]
            player.record_slot_update(session.save, protocol.encode_pb_field(1, 2, protocol.pb_set_varint(raw, 6, (1 << 31) - 1)))
            memory = copy.deepcopy(session.save)
            self.assertEqual(struct.unpack(">IIII", session.handle(1048, 32301, b"")[0][:16])[2], 999999)
            self.assertEqual((session.save, self.save_path.read_bytes()), (memory, disk))

    def test_level21_pet_fractional_skill_rates_are_not_rounded_out_of_battle(self):
        saved = self.seed_level21_pet()
        saved["pet_state"].update(skills=[[92021, 1], [0, 0], [0, 0], [0, 0], [0, 0]], spent_points=1)
        bonuses = pets.attributes(saved, self.role_config)
        self.assertEqual(bonuses[11], Fraction(2, 5))
        point = self.role_config["copy"]["42102"]["1"]
        attack, _ = battle.rosters(saved, point, self.role_config)
        self.assertTrue(all(unit["pet_rates"]["dodge"] == Fraction(2, 5) for unit in attack.values()))
        attacker = {2: self.combat_unit(10201, pet_rates={"dodge": Fraction(2, 5)})}
        defender = {2: self.combat_unit(10201, iid=2, speed=200)}
        with patch.object(battle.random.Random, "random", return_value=.002):
            report = battle.simulate(attacker, defender, self.role_config, 1)
        self.assertEqual(report["b"]["a"][0]["e"][0]["m"]["u"], "dodge")

    def test_level21_installed_apk_callbacks_accept_native_pet_and_boss_replies(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("魔宠/屠龙原生Lua回调验证需本机已有 lupa.lua51")
        package = Path(server.BASE_DIR) / "zyj_local.apk"
        if not package.exists():
            self.skipTest("实际包内回调验证需要本地APK")
        with patch.object(apk_builder, "SRC_APK", str(package)):
            scripts = {name: apk_builder.read_script(name).decode("utf-8")
                       for name in ("gamedata", "GameTech", "GameWorldBoss", "GameTimeBag")}
        lua = LuaRuntime()
        def decode_message(kind, raw):
            data = bytes.fromhex(raw)
            if kind == "Ids":
                values = {"ids": [v - (1 << 64) if v >= (1 << 63) else v for v in protocol.parse_ids_pb(data)]}
            elif kind == "IdNums":
                values = {"idnums": [{"id": cid, "num": protocol.pb_get_varint(v, 2)}
                                      for cid, v in self.entity_records(data, 1, 1).items()]}
            elif kind == "Result":
                values = {"result": bool(protocol.pb_get_varint(data, 1))}
            elif kind == "WorldBoss1":
                values = {key: protocol.pb_get_varint(data, n) or 0 for n, key in
                          ((1, "status"), (2, "damage"), (3, "kill"), (4, "cd"), (7, "attackcount"),
                           (8, "damagesum"), (9, "bosshp"), (10, "bosslevel"))}
                values["ranks"] = []
            else:
                values = {"ranks": [], "time": protocol.pb_get_varint(data, 3) or 0}
            return lua.table_from(values, recursive=True)
        lua.globals().decode_message = decode_message
        lua.execute('''
            print=function() end; printT=print; cclog=print
            require=function() return setmetatable({}, {__index=function(_,kind) return function()
                return {ids={},SerializeToString=function(self) return self.ids end,ParseFromString=function(self,raw)
                    for k,v in pairs(decode_message(kind,raw)) do self[k]=v end
                end}
            end end}) end
            gamedata={cache={petsdata={},petsfragment={},petpassiveskill={},petBagCompound={},
                            worldboss={},worldboss2={},worldbossrank={},worldbossrank2={}},ext={}}
            gamedata.time=function() return 1800000000 end
            gamedata.playerwithgeneralsdata=function(_,data) return data end
        ''')
        source = scripts["gamedata"]
        for start, end in (("PetsData", "setPetData"), ("PetBagCompoundData", "setPetSet"), ("WorldBossData", "GuildWarInspire")):
            lua.execute(source[source.index("function gamedata." + start + "("):source.index("function gamedata." + end + "(")])
        lua.execute(scripts["GameTech"])
        lua.execute(scripts["GameWorldBoss"])
        lua.execute(scripts["GameTimeBag"])
        self.seed_level21_account()
        self.give_props({91001: 10})
        for reply in self.replay([self.activity_request(1040)]):
            name = "NetPetQueryCallback" if reply["opcode"] == 1040 else "NetPetFragmentCallback"
            lua.globals()[name](lua.table_from({"rbuf": reply["hex"]}))
        lua.execute('assert(gamedata.cache.petsdata.iid==0 and gamedata.cache.petsfragment[91001].num==50)')
        lua.execute('gamedata.ext.petBagCompound={cid=91001,useNum=50}')
        reply = self.replay([self.activity_request(1049, [91001])])[0]
        lua.globals().NetPetBagCompoundCallback(lua.table_from({"rbuf": reply["hex"]}))
        iid = protocol.parse_ids_pb(bytes.fromhex(reply["hex"]))[0]
        lua.globals().gamedata.ext.petsetiid = iid
        reply = self.replay([self.activity_request(1043, [iid])])[0]
        lua.globals().NetPetSetCallback(lua.table_from({"rbuf": reply["hex"]}))
        lua.execute('''assert(gamedata.cache.petsfragment[91001].num==0)
            assert(gamedata.cache.petsdata.pets[gamedata.cache.petsdata.iid].cid==90001)
            assert(gamedata.cache.petpassiveskill.skill[1].status==2)''')
        reply = self.replay([self.activity_request(1048)])[0]
        lua.globals().NetPetPassiveSkillStudyCallback(lua.table_from({"rbuf": reply["hex"]}))
        lua.execute('assert(gamedata.cache.petpassiveskill.nowskillpoint==20 and gamedata.cache.petpassiveskill.skill[1].cid>0)')
        self.give_props({91001: 100, 20166: 100})
        lua.execute('''gamedata.cache.petsfragment[91001].num=100
            gamedata.cache.props={[20166]={num=100}}
            gamedata.cache.role={coin=1000000,gold=200,level=21}
            function gamedata:updateRoleCoin(n) self.cache.role.coin=self.cache.role.coin+n end
            function gamedata:updateRoleGold(n) self.cache.role.gold=self.cache.role.gold+n end''')
        lua.globals().gamedata.ext.petstageup = lua.table_from({"iid": iid, "spenddata": {
            "1": {"cid": 91001, "num": 5}, "2": {"cid": 20166, "num": 30}, "3": {"cid": 1000, "num": 100000}}}, recursive=True)
        reply = self.replay([self.activity_request(1046, [iid])])[0]
        lua.globals().NetPetStageUpCallback(lua.table_from({"rbuf": reply["hex"]}))
        lua.execute('''assert(gamedata.cache.petsdata.pets[gamedata.cache.petsdata.iid].level==1)
            assert(gamedata.cache.role.coin==900000 and gamedata.cache.props[20166].num==70)
            assert(gamedata.cache.petsfragment[91001].num==95 and gamedata.cache.petpassiveskill.skill[3].status==2)''')
        for lock in (0, 1):
            lua.globals().gamedata.ext.passiveSkillLock = lua.table_from({"id": 1, "lock": lock})
            reply = self.replay([self.activity_request(1060, [1])])[0]
            lua.globals().NetPetPassiveSkillLockCallback(lua.table_from({"rbuf": reply["hex"]}))
            lua.execute(f'assert(gamedata.cache.petpassiveskill.skill[1].lock=={1 - lock})')
        lua.globals().gamedata.ext.petPassiveSkillResetSpend = 50
        reply = self.replay([self.activity_request(1061)])[0]
        lua.globals().NetPetPassiveSkillResetCallback(lua.table_from({"rbuf": reply["hex"]}))
        lua.execute('assert(gamedata.cache.petpassiveskill.nowskillpoint==21 and gamedata.cache.role.gold==150)')
        lua.globals().gamedata.config = lua.table_from(self.role_config, recursive=True)
        lua.globals().NetTimeBagCallback(lua.table_from({"rbuf": self.query_world(2880).hex()}))
        lua.execute('''local net,opcode,ids=UITimeBagTrigCallBack({opt=1,sysID=49})
            assert(net==1 and opcode==2882 and #ids==1 and ids[1]==130012)''')
        self.replay([{"opcode": 201, "seq": 31970, "hex": "083b1009"}])
        reply = self.replay([self.activity_request(2882, [130012])])[0]
        lua.globals().NetTimeBagTrigCallBack(lua.table_from({"rbuf": reply["hex"]}))
        lua.execute('''assert(gamedata.cache.timebag[130012].status==0)
            local net,opcode=UITimeBagTrigCallBack({opt=1,sysID=49})
            assert(net==0 and opcode==2882)''')
        for opcode, name in ((3400, "NetWorldBoss1QueryCallBack"), (3410, "NetWorldBoss2QueryCallBack"),
                             (3404, "NetWorldBoss1PreRankCallBack"), (3414, "NetWorldBoss2PreRankCallBack")):
            result = lua.globals()[name](lua.table_from({"rbuf": self.query_world(opcode).hex()}))
            if opcode in (3400, 3410):
                self.assertEqual(result.worldboss.status, 0)
                self.assertGreater(result.worldboss.bosslevel, 1 << 31)
            else:
                self.assertEqual(result.time, 0)

    def test_level21_worldboss_intro_queries_are_closed_and_do_not_advance_guide(self):
        saved = self.seed_level21_account()
        for opcode in (3400, 3410):
            body = self.query_world(opcode)
            self.assertEqual(protocol.pb_get_varint(body, 1), 0)
            self.assertEqual(protocol.pb_get_varint(body, 9), 0)
            self.assertGreater(protocol.pb_get_varint(body, 10), 1 << 31)
        for opcode in (3404, 3414):
            self.assertEqual(protocol.pb_get_varint(self.query_world(opcode), 3), 0)
        self.assertEqual(json.loads(self.save_path.read_text())["guide"], saved["guide"])
        for opcode in (3400, 3404, 3410, 3414):
            disk = self.save_path.read_bytes()
            self.assertEqual(self.replay([self.activity_request(opcode, [1])])[0]["opcode"], 999999)
            self.assertEqual(self.save_path.read_bytes(), disk)
        for opcode in (3401, 3411):
            disk = self.save_path.read_bytes()
            self.assertEqual(self.replay([self.activity_request(opcode, [10, 1])])[0]["opcode"], 999999)
            self.assertEqual(self.save_path.read_bytes(), disk)
        self.replay([{"opcode": 201, "seq": 31060, "hex": "083c1001"}])
        self.assertEqual(json.loads(self.save_path.read_text())["guide"]["sections"]["60"]["status"], 2)

    def test_watchstar_query_and_exact_guide_comb_commit_once(self):
        baseline = self.prepare_watchstar()
        self.assertEqual(protocol.parse_ids_pb(self.query_world(2062)), [0, 0, 0] + [0] * 18 + [1])
        self.assertEqual(json.loads(self.save_path.read_text())["guide"], baseline["guide"])
        # 空 data 可省略；Guide 的 section/step 顺序可以不同。
        body = bytes.fromhex("0a03088f100a0908c901120410020839")
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            packets = session.handle(999900, 31001, body)
            messages = protocol.get_comb_messages(packets[0][16:])
            self.assertEqual([mid for mid, _ in messages], [2063, 201])
            values = protocol.parse_ids_pb(messages[0][1])
            self.assertEqual(values[1:3], [1, 0])
            self.assertTrue(all(1 <= v <= 8 for v in values[3:11]))
            self.assertEqual(session.save["guide"]["sections"]["57"]["step"], 2)
            self.assertEqual(session.handle(999900, 31001, body), packets)
            self.assertEqual(json.loads(self.save_path.read_text()), session.save)
        self.assertEqual(self.replay([{"opcode": 999900, "seq": 31002, "hex": body.hex()}])[0]["opcode"], 999999)

    def test_watchstar_rejects_bad_comb_and_standalone_parameters(self):
        self.prepare_watchstar()
        sign = protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 2063))
        for data in (b"\x08\x39\x10\x03", b"\x08\x39\x10\x02\x18\x00", b"\x08\x39\x08\x39\x10\x02"):
            body = sign + protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 201) + protocol.encode_pb_field(2, 2, data))
            disk = self.save_path.read_bytes()
            self.assertEqual(self.replay([{"opcode": 999900, "seq": 31003, "hex": body.hex()}])[0]["opcode"], 999999)
            self.assertEqual(self.save_path.read_bytes(), disk)
        for opcode in range(2062, 2069):
            disk = self.save_path.read_bytes()
            self.assertEqual(self.replay([self.activity_request(opcode, [1])])[0]["opcode"], 999999)
            self.assertEqual(self.save_path.read_bytes(), disk)
        saved = json.loads(self.save_path.read_text())
        saved["role_state"]["level"] = 16
        self.save_path.write_text(json.dumps(saved))
        self.assertEqual(self.replay([self.activity_request(2062)])[0]["opcode"], 999999)

    def test_watchstar_empty_data_comb_and_extra_fields(self):
        self.prepare_watchstar()
        valid = bytes.fromhex("0a05088f1012000a0908c901120408391002")
        extra = bytes.fromhex("0a03088f10")
        for body in (valid + extra, valid + b"\x10\x00", extra + valid):
            disk = self.save_path.read_bytes()
            self.assertEqual(self.replay([{"opcode": 999900, "seq": 31004, "hex": body.hex()}])[0]["opcode"], 999999)
            self.assertEqual(self.save_path.read_bytes(), disk)
        self.assertEqual(self.replay([{"opcode": 999900, "seq": 31005, "hex": valid.hex()}])[0]["opcode"], 999900)

    def test_watchstar_change_collect_claim_and_reconnect(self):
        self.prepare_watchstar()
        self.query_world(2062)
        saved = json.loads(self.save_path.read_text())
        state = saved["watchstar_state"]
        state.update(forecasts=1, changes=10, slots=[1, 1, 3, 1, 1, 1, 1, 1])
        self.save_path.write_text(json.dumps(saved))
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            gold = session.save["role_state"]["gold"]
            packets = session.handle(2064, 31010, b"")
            values = protocol.parse_ids_pb(packets[0][16:])
            self.assertEqual(values[2], 11)
            self.assertEqual((values[3], values[5]), (1, 3))
            self.assertEqual(session.save["role_state"]["gold"], gold - 10)
            self.assertEqual(session.handle(2064, 31010, b""), packets)
            self.assertEqual(json.loads(self.save_path.read_text()), session.save)
        saved = json.loads(self.save_path.read_text())
        saved["watchstar_state"]["slots"] = [1, 1, 3, 1, 1, 1, 1, 1]
        self.save_path.write_text(json.dumps(saved))
        reply = self.replay([self.activity_request(2065)])[0]
        self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(reply["hex"]))[:11], [10, 1, 11] + [0] * 8)
        self.assertEqual(self.replay([self.activity_request(2065)])[0]["opcode"], 999999)
        saved = json.loads(self.save_path.read_text())
        saved["watchstar_state"]["stars"] = 45
        self.save_path.write_text(json.dumps(saved))
        self.assertEqual(protocol.parse_ids_pb(self.query_world(2062))[11:21], [1, 1, 1] + [0] * 7)
        self.assertEqual(self.replay([self.activity_request(2066)])[0]["opcode"], 2066)
        after = json.loads(self.save_path.read_text())
        self.assertEqual(after["role_state"]["coin"], saved["role_state"]["coin"] + 10000)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(2062))[11:21], [2, 2, 2] + [0] * 7)
        self.assertEqual(self.replay([self.activity_request(2066)])[0]["opcode"], 999999)

    def test_watchstar_daily_reset_and_clock_rollback_preserve_reward_level(self):
        self.prepare_watchstar()
        self.query_world(2062)
        saved = json.loads(self.save_path.read_text())
        saved["watchstar_state"].update(stars=45, forecasts=1, changes=2, slots=[1] * 8, claimed=[1], reward_level=2)
        self.save_path.write_text(json.dumps(saved))
        self.clock.return_value += 86400
        self.assertEqual(protocol.parse_ids_pb(self.query_world(2062)), [0, 0, 0] + [0] * 18 + [2])
        reset = json.loads(self.save_path.read_text())["watchstar_state"]
        self.clock.return_value -= 86400
        self.query_world(2062)
        self.assertEqual(json.loads(self.save_path.read_text())["watchstar_state"], reset)

    def test_watchstar_onekey_upgrade_and_insufficient_money_are_atomic(self):
        self.prepare_watchstar()
        self.query_world(2062)
        saved = json.loads(self.save_path.read_text())
        saved["watchstar_state"].update(forecasts=1, slots=[1, 1, 3, 1, 1, 1, 1, 1])
        self.save_path.write_text(json.dumps(saved))
        self.assertEqual(self.replay([self.activity_request(2067)])[0]["opcode"], 999999)
        saved["role_state"].update(vip=4, gold=0)
        self.save_path.write_text(json.dumps(saved))
        disk = self.save_path.read_bytes()
        self.assertEqual(self.replay([self.activity_request(2067)])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), disk)
        saved["role_state"].update(gold=1000, level=40)
        self.save_path.write_text(json.dumps(saved))
        self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(self.replay([self.activity_request(2067)])[0]["hex"]))[3:11], list(range(1, 9)))
        after = json.loads(self.save_path.read_text())
        self.assertEqual(after["role_state"]["gold"], 800)
        self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(self.replay([self.activity_request(2068)])[0]["hex"])), [2])
        self.assertEqual(self.replay([self.activity_request(2068)])[0]["opcode"], 999999)
        saved = json.loads(self.save_path.read_text())
        saved["role_state"].update(level=50, gold=99)
        self.save_path.write_text(json.dumps(saved))
        disk = self.save_path.read_bytes()
        self.assertEqual(self.replay([self.activity_request(2068)])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), disk)
        saved["role_state"]["gold"] = 100
        self.save_path.write_text(json.dumps(saved))
        self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(self.replay([self.activity_request(2068)])[0]["hex"])), [3])
        self.assertEqual(json.loads(self.save_path.read_text())["role_state"]["gold"], 0)

    def test_watchstar_forecast_limits_free_changes_and_reconnect(self):
        self.prepare_watchstar()
        self.query_world(2062)
        saved = json.loads(self.save_path.read_text())
        saved["watchstar_state"].update(forecasts=2, changes=9, slots=[2, 1, 4, 3, 6, 5, 8, 7])
        self.save_path.write_text(json.dumps(saved))
        self.assertEqual(self.replay([self.activity_request(2063)])[0]["opcode"], 999999)
        self.assertEqual(self.replay([self.activity_request(2064)])[0]["opcode"], 2064)
        after = json.loads(self.save_path.read_text())
        self.assertEqual(after["role_state"]["gold"], saved["role_state"]["gold"])
        self.assertEqual(after["watchstar_state"]["changes"], 10)
        self.replay([self.activity_request(2065)])
        self.assertEqual(self.replay([self.activity_request(2063)])[0]["opcode"], 2063)
        self.replay([self.activity_request(2065)])
        disk = self.save_path.read_bytes()
        self.assertEqual(self.replay([self.activity_request(2063)])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), disk)

    def test_watchstar_all_configured_reward_levels_and_corrupt_state(self):
        saved = self.prepare_watchstar()
        for level in range(1, 13):
            with self.subTest(level=level):
                specification = "".join(self.role_config["watchstar_reward"][str(i)][f"rewards{level}"] for i in range(1, 11))
                working = copy.deepcopy(saved)
                reward = activities.build_reward(working, specification, self.role_config)
                player.apply_reward(working, reward, self.role_config, self.now)
        self.query_world(2062)
        saved = json.loads(self.save_path.read_text())
        for change in ({"slots": [0] * 7}, {"slots": [0, 1] * 4}, {"stars": True},
                       {"claimed": [1, 1]}, {"claimed": [11]}, {"reward_level": 13}):
            broken = copy.deepcopy(saved)
            broken["watchstar_state"].update(change)
            self.save_path.write_text(json.dumps(broken))
            disk = self.save_path.read_bytes()
            with self.subTest(change=change), redirect_stdout(io.StringIO()), self.assertRaisesRegex(ValueError, "观星台"):
                Session(self.tables, self.save_path, self.step_counts, self.role_config)
            self.assertEqual(self.save_path.read_bytes(), disk)

    def test_watchstar_save_failure_does_not_commit_or_reply(self):
        self.prepare_watchstar()
        self.query_world(2062)
        for opcode, body in ((2063, b""), (999900, bytes.fromhex("0a03088f100a0908c901120410020839"))):
            with self.subTest(opcode=opcode), redirect_stdout(io.StringIO()):
                session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
                disk, memory = self.save_path.read_bytes(), copy.deepcopy(session.save)
                with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
                    session.handle(opcode, 31020, body)
                self.assertEqual(session.save, memory)
                self.assertEqual(self.save_path.read_bytes(), disk)
                self.assertEqual(session.random_replies, {})

    def test_blackmarket_query_populates_nine_saved_slots_without_advancing_guide(self):
        before = self.prepare_blackmarket()
        data = protocol.parse_ids_pb(self.query_world(3630))
        self.assertEqual(len(data), 19)
        self.assertEqual(data[0], 0)
        self.assertEqual(data[2::2], [0] * 9)
        self.assertEqual(self.query_world(3630), recharge.ids(data))
        after = json.loads(self.save_path.read_text())
        for key in ("role_state", "world_state", "guide", "last_battle", "mieshendian_state"):
            self.assertEqual(after.get(key), before.get(key))

    def test_blackmarket_purchase_and_paid_refresh_save_once_without_client_cost_duplication(self):
        self.prepare_blackmarket()
        self.query_world(3630)
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            before = copy.deepcopy(session.save)
            offer = before["blackmarket_state"]["slots"][0][0]
            row = self.role_config["blackmarket_items"][str(offer)]
            cid, price = map(int, row["consume"].rstrip(";").split(","))
            body = recharge.ids([1, 1])
            packets = session.handle(3631, 27000, body)
            self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2:], (3631, 27000))
            self.assertEqual(session.save["role_state"]["gold" if cid == 1001 else "coin"],
                             before["role_state"]["gold" if cid == 1001 else "coin"] - price)
            self.assertEqual(session.save["blackmarket_state"]["slots"][0], [offer, 1])
            self.assertFalse(protocol.pb_get_varint(packets[0][16:], 1))
            self.assertFalse(protocol.pb_get_varint(packets[0][16:], 2))
            self.assertEqual(session.handle(3631, 27000, body), packets)
            oldgold = session.save["role_state"]["gold"]
            packets = session.handle(3632, 27001, b"")
            self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 3632)
            self.assertEqual(session.save["blackmarket_state"]["refreshes"], 1)
            self.assertEqual(session.save["role_state"]["gold"], oldgold - self.role_config["buycount_price"]["1"]["blackmarket_refreshgold"])
            self.assertEqual(session.handle(3632, 27001, b""), packets)
            self.assertEqual(json.loads(self.save_path.read_text()), session.save)

    def test_blackmarket_token_refresh_is_preferred_and_does_not_duplicate_item_cost(self):
        self.prepare_blackmarket()
        self.query_world(3630)
        saved = json.loads(self.save_path.read_text())
        player.change_item_count(saved, 20172, 2, self.role_config, self.now)
        self.save_path.write_text(json.dumps(saved))
        result = self.replay([self.activity_request(3632)])[0]
        self.assertEqual(result["opcode"], 3632)
        after = json.loads(self.save_path.read_text())
        self.assertEqual(after["role_state"]["gold"], saved["role_state"]["gold"])
        props = self.entity_records(bytes.fromhex(after["world_state"]["1200"]), 1, 1)
        self.assertEqual(protocol.pb_get_varint(props[20172], 2), 1)
        self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(result["hex"]))[0], 1)

    def test_blackmarket_scheduled_refreshes_and_day_reset_advance_only_forward(self):
        self.prepare_blackmarket()
        self.clock.return_value = 1793318400  # 2026-10-30 08:00 UTC+8。
        self.query_world(3630)
        self.replay([self.activity_request(3632)])
        before = json.loads(self.save_path.read_text())
        self.clock.return_value += 3600
        disk = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([self.activity_request(3631, [1, 1])]), 3631, 20000, "刷新时间")
        self.assertEqual(self.save_path.read_bytes(), disk)
        self.query_world(3630)
        middle = json.loads(self.save_path.read_text())
        self.assertGreater(middle["blackmarket_state"]["period"], before["blackmarket_state"]["period"])
        self.assertEqual(middle["blackmarket_state"]["refreshes"], 1)
        self.clock.return_value += 15 * 3600
        self.assertEqual(protocol.parse_ids_pb(self.query_world(3630))[0], 0)
        forward = json.loads(self.save_path.read_text())["blackmarket_state"]
        self.clock.return_value -= 86400
        self.query_world(3630)
        self.assertEqual(json.loads(self.save_path.read_text())["blackmarket_state"], forward)

    def test_blackmarket_limits_and_insufficient_resources_roll_back(self):
        self.prepare_blackmarket()
        self.query_world(3630)
        saved = json.loads(self.save_path.read_text())
        first = saved["blackmarket_state"]["slots"][0][0]
        limit = self.role_config["blackmarket_items"][str(first)]["limit"]
        self.assertEqual(self.replay([self.activity_request(3631, [1, limit])])[0]["opcode"], 3631)
        disk = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([self.activity_request(3631, [1, 1])]), 3631, 20000, "次数不足")
        self.assertEqual(self.save_path.read_bytes(), disk)
        saved["role_state"].update(gold=0, coin=0)
        self.save_path.write_text(json.dumps(saved))
        for opcode, values in ((3631, [1, 1]), (3632, [])):
            disk = self.save_path.read_bytes()
            with self.subTest(opcode=opcode):
                self.assertEqual(self.replay([self.activity_request(opcode, values)])[0]["opcode"], 999999)
                self.assertEqual(self.save_path.read_bytes(), disk)

    def test_blackmarket_rejects_locked_malformed_and_prequery_mutations(self):
        baseline = self.prepare_blackmarket()
        cases = [(3630, [1]), (3632, [1]), (3631, []), (3631, [1]), (3631, [1, 1, 1]),
                 (3631, [0, 1]), (3631, [10, 1]), (3631, [1, 0]), (3631, [1, 101])]
        for opcode, values in cases:
            self.save_path.write_text(json.dumps(baseline))
            disk = self.save_path.read_bytes()
            with self.subTest(opcode=opcode, values=values):
                self.assertEqual(self.replay([self.activity_request(opcode, values)])[0]["opcode"], 999999)
                self.assertEqual(self.save_path.read_bytes(), disk)
        baseline["role_state"]["level"] = 15
        self.save_path.write_text(json.dumps(baseline))
        self.assert_unavailable_response(self.replay([self.activity_request(3630)]), 3630, 20000, "尚未解锁")

    def test_blackmarket_save_failure_keeps_slots_and_balances_unchanged(self):
        self.prepare_blackmarket()
        self.query_world(3630)
        for opcode, body in ((3631, recharge.ids([1, 1])), (3632, b"")):
            with self.subTest(opcode=opcode), redirect_stdout(io.StringIO()):
                session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
                disk, memory = self.save_path.read_bytes(), copy.deepcopy(session.save)
                with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
                    session.handle(opcode, 27002, body)
                self.assertEqual(session.save, memory)
                self.assertEqual(self.save_path.read_bytes(), disk)
                self.assertEqual(session.random_replies, {})

    def test_blackmarket_all_configured_rewards_and_weighted_pools_are_supported(self):
        saved = self.prepare_blackmarket()
        for row in self.role_config["blackmarket_items"].values():
            with self.subTest(item=row["id"]):
                gets = [tuple(map(int, entry.split(","))) for entry in row["good"].split(";") if entry]
                reward = recruit.build_reward(copy.deepcopy(saved), gets, self.role_config)
                player.apply_reward(copy.deepcopy(saved), reward, self.role_config, self.now)
        for level in (16, 39, 40, 59, 60, 100, 150):
            for vip in (0, 12, 27):
                for refresh in (0, 10):
                    with self.subTest(level=level, vip=vip, refresh=refresh):
                        saved["role_state"].update(level=level, vip=vip)
                        state = blackmarket.get_state(saved, self.role_config)
                        state["refreshes"] = refresh
                        blackmarket.refresh(saved, self.role_config, state, 42)
                        self.assertEqual(len(state["slots"]), 9)
                        for iid, bought in state["slots"]:
                            row = self.role_config["blackmarket_items"][str(iid)]
                            self.assertLessEqual(row["down_level"], level)
                            self.assertGreaterEqual(row["up_level"], level)
                            self.assertLessEqual(row["vip"], vip)
                            self.assertEqual(bought, 0)

    def test_blackmarket_corrupt_state_fails_closed(self):
        self.prepare_blackmarket()
        self.query_world(3630)
        saved = json.loads(self.save_path.read_text())
        for change in ({"slots": []}, {"refreshes": True}, {"slots": [[999999, 0]] * 9}, {"slots": [[100001, -1]] * 9}):
            broken = copy.deepcopy(saved)
            broken["blackmarket_state"].update(change)
            self.save_path.write_text(json.dumps(broken))
            disk = self.save_path.read_bytes()
            with self.subTest(change=change), redirect_stdout(io.StringIO()), self.assertRaisesRegex(ValueError, "元宝商店"):
                Session(self.tables, self.save_path, self.step_counts, self.role_config)
            self.assertEqual(self.save_path.read_bytes(), disk)

    def test_blackmarket_artifact_jewel_uses_native_roster_inventory_and_reconnect(self):
        self.prepare_blackmarket()
        self.query_world(3630)
        saved = json.loads(self.save_path.read_text())
        saved["role_state"]["level"] = 58
        saved["blackmarket_state"]["slots"][0] = [100130, 0]
        self.save_path.write_text(json.dumps(saved))
        result = self.replay([self.activity_request(3631, [1, 1])])[0]
        self.assertEqual(result["opcode"], 3631)
        after = json.loads(self.save_path.read_text())
        jewels = self.entity_records(bytes.fromhex(after["world_state"]["1002"]), 17, 1)
        self.assertEqual(protocol.parse_ids_pb(jewels[120001]), [120001, 1])
        self.assertEqual(after["world_state"]["1200"], saved["world_state"]["1200"])
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
        self.assertEqual(session.save["world_state"]["1002"], after["world_state"]["1002"])
        after["blackmarket_state"]["slots"][0][1] = 0
        player.change_item_count(after, 120001, (1 << 31) - 2, self.role_config, self.now)
        self.save_path.write_text(json.dumps(after))
        disk = self.save_path.read_bytes()
        self.assertEqual(self.replay([self.activity_request(3631, [1, 1])])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), disk)

    def test_mieshendian_query_populates_the_tutorial_floor_without_rewards(self):
        before = self.prepare_mieshendian()
        values = protocol.parse_ids_pb(self.query_world(3620))
        self.assertEqual(values, [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0])
        after = json.loads(self.save_path.read_text())
        for key in ("role_state", "world_state", "guide", "last_battle", "last_star_battle"):
            self.assertEqual(after.get(key), before.get(key))

    def test_mieshendian_sixth_floor_is_playable_and_legacy_progress_is_preserved(self):
        saved = self.prepare_mieshendian()
        saved["mieshendian_state"] = {"floor": 6, "failcount": 0, "star": 4, "earned": 10,
                                      "day": (self.now + 28800) // 86400, "todaymaxfloor": 5}
        self.save_path.write_text(json.dumps(saved))
        self.assertEqual(protocol.parse_ids_pb(self.query_world(3620)), [5, 5, 0, 0, 6, 4, 0, 0, 1000, 10, 5])
        result = self.replay([self.activity_request(3621, [3])])[0]
        self.assertEqual(result["opcode"], 3621)
        self.assertEqual(protocol.pb_get_varint(bytes.fromhex(result["hex"]), 1), 1)
        after = json.loads(self.save_path.read_text())
        self.assertEqual((after["mieshendian_state"]["floor"], after["mieshendian_state"]["points"]), (7, 1300))

    def test_mieshendian_reset_keeps_historical_max_and_charges_configured_ordinal(self):
        self.prepare_mieshendian()
        self.replay([self.activity_request(3621, [3])])
        before = json.loads(self.save_path.read_text())
        result = self.replay([self.activity_request(3626)])[0]
        self.assertEqual(result["opcode"], 3626)
        after = json.loads(self.save_path.read_text())
        self.assertEqual(after["role_state"]["gold"], before["role_state"]["gold"])
        self.assertEqual(protocol.parse_ids_pb(self.query_world(3620)), [1, 1, 1, 0, 1, 0, 0, 0, 300, 3, 0])
        self.replay([self.activity_request(3621, [1])])
        self.replay([self.activity_request(3626)])
        after = json.loads(self.save_path.read_text())
        self.assertEqual(after["role_state"]["gold"], before["role_state"]["gold"] - self.role_config["buycount_price"]["2"]["mieshendian"])
        self.assertEqual(after["mieshendian_state"]["maxfloor"], 1)

    def test_mieshendian_all_condition_types_use_final_hp_positions_rounds_and_deaths(self):
        report = {"result": True, "round": 3, "endmeta": {"attack": {str(p): {"h": 40, "j": 100}
                                                                  for p in battle.POSITIONS}}}
        for kind, value in ((1, 0), (2, 3), (3, .4), (4, 0), (5, 3), (6, 4), (7, 0), (8, 0)):
            with self.subTest(kind=kind):
                self.assertTrue(mieshendian.condition_met(report, {"condition": kind, "condition_param": value}))
        report["endmeta"]["attack"]["6"]["h"] = 0
        for kind, value in ((3, .1), (4, 0), (5, 3), (7, 0), (2, 2)):
            self.assertFalse(mieshendian.condition_met(report, {"condition": kind, "condition_param": value}))
        self.assertTrue(mieshendian.condition_met(report, {"condition": 4, "condition_param": 1}))
        del report["endmeta"]["attack"]["14"]
        self.assertFalse(mieshendian.condition_met(report, {"condition": 6, "condition_param": 4}))

    def test_mieshendian_three_star_battle_saves_real_rewards_and_next_floor_once(self):
        before = self.prepare_mieshendian()
        body = bytes.fromhex(self.activity_request(3621, [3])["hex"])
        with redirect_stdout(io.StringIO()), patch.object(player.random, "getrandbits", return_value=42):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            with patch.object(player, "save_role", wraps=player.save_role) as persist:
                packets = session.handle(3621, 26000, body)
                self.assertEqual(persist.call_count, 1)
            self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2:], (3621, 26000))
            fields = {n: value for n, w, value in protocol.iter_pb_fields(packets[0][16:])}
            self.assertEqual(fields[1], 1)
            report = json.loads(fields[5])
            self.assert_battle_report(report)
            self.assertTrue(all(unit["level1"] == 2 for unit in report["meta"]["defense"]["g"].values()))
            after = copy.deepcopy(session.save)
            self.assertEqual(json.loads(self.save_path.read_text()), after)
            self.assertEqual(session.handle(3621, 26000, body), packets)
        self.assertEqual(after["role_state"]["coin"] - before["role_state"]["coin"], 400)
        for key in ("gold", "level", "exp", "stamina", "energy", "power"):
            self.assertEqual(after["role_state"][key], before["role_state"][key])
        for key in ("guide", "last_battle", "last_star_battle"):
            self.assertEqual(after.get(key), before.get(key))
        self.assertEqual(after["world_state"]["1300"], before["world_state"]["1300"])
        self.assertEqual(protocol.parse_ids_pb(self.query_world(3620)), [1, 1, 0, 0, 2, 3, 0, 0, 300, 3, 0])

    def test_temporary_hit_and_critical_damage_reductions_survive_battle_preparation(self):
        attack = {2: self.combat_unit(10201, iid=1, speed=200, hit=-20, criticaldmg=-10)}
        defense = {2: self.combat_unit(10201, iid=2)}
        teams = {True: copy.deepcopy(attack), False: copy.deepcopy(defense)}
        battle._prepare_teams(teams, self.role_config)
        unit = teams[True][2]
        self.assertEqual((unit["hit"], unit["criticaldmg"]), (-20, -10))
        self.assertEqual(battle.damage(unit, teams[False][2], self.role_config, critical=True,
                                      critical_multiplier=Fraction(3, 2) + Fraction(unit["criticaldmg"], 100)), 140)
        config = copy.deepcopy(self.role_config)
        config["skill"][str(attack[2]["skill"])]["ap"] = 100
        report = battle.simulate(attack, defense, config, 1)
        self.assertEqual(report["b"]["a"][0]["e"][0]["m"]["u"], "dodge")

    def test_mieshendian_first_five_floors_and_boss_commit_first_clear_rewards_once(self):
        before = self.prepare_mieshendian()
        for floor in range(1, 5):
            result = self.replay([self.activity_request(3621, [3])])[0]
            self.assertEqual(result["opcode"], 3621)
            self.assertEqual(protocol.pb_get_varint(bytes.fromhex(result["hex"]), 1), 1)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(3620))[5], 12)
        result = self.replay([self.activity_request(3622, [1, 1, 1, 1, 2, 3, 4, 5, 6, 7])])[0]
        self.assertEqual(result["opcode"], 3622)
        self.assertEqual(protocol.pb_get_varint(bytes.fromhex(result["hex"]), 1), 1)
        self.assert_battle_report(json.loads(next(v for n, w, v in protocol.iter_pb_fields(bytes.fromhex(result["hex"])) if (n, w) == (5, 2))))
        after = json.loads(self.save_path.read_text())
        self.assertEqual(protocol.parse_ids_pb(self.query_world(3620)), [5, 5, 0, 0, 6, 1, 0, 0, 1300, 13, 5])
        old = self.entity_records(bytes.fromhex(before["world_state"]["1200"]), 1, 1)
        new = self.entity_records(bytes.fromhex(after["world_state"]["1200"]), 1, 1)
        for cid, gained in ((20222, 7), (91001, 10), (20002, 25), (20257, 1)):
            self.assertEqual((protocol.pb_get_varint(new.get(cid, b""), 2) or 0)
                             - (protocol.pb_get_varint(old.get(cid, b""), 2) or 0), gained)
        self.assertEqual(after["world_state"]["1002"], before["world_state"]["1002"])
        self.assertEqual(after["world_state"]["1300"], before["world_state"]["1300"])
        self.assertEqual(after["last_mieshendian_battle"]["star_cost"], 12)
        snapshot = self.save_path.read_bytes()
        result = self.replay([self.activity_request(3622, [1, 1, 1, 1, 2, 3, 4, 5, 6, 7])])
        self.assert_unavailable_response(result, 3622, 20000, "挑战方式")
        self.assertEqual(self.save_path.read_bytes(), snapshot)

    def test_mieshendian_boss_bonuses_and_arrangement_are_temporary_and_charge_on_loss(self):
        before = self.prepare_mieshendian(strong=False)
        before["mieshendian_state"].update(floor=5, star=12, earned=12, todaymaxfloor=4, maxfloor=4, maxstar=12,
                                            best={str(i): 3 for i in range(1, 5)})
        self.save_path.write_text(json.dumps(before))
        row = self.role_config["mieshendian_monster_param"]["5"]["1"]
        attack, defense = battle.rosters(before, {**row, "level": row["monster_level"]}, self.role_config)
        sources = sorted(battle.POSITIONS.index(pos) + 1 for pos in attack)
        arrangement = list(range(1, 8))
        first, second = sources[:2]
        arrangement[first - 1], arrangement[second - 1] = second, first
        body = bytes.fromhex(self.activity_request(3622, [1, 1, 1, *arrangement])["hex"])
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            with patch.object(battle, "simulate", wraps=battle.simulate) as simulate:
                packets = session.handle(3622, 26100, body)
            boosted, weakened = simulate.call_args.args[:2]
            self.assertEqual(boosted[battle.POSITIONS[first - 1]]["iid"], attack[battle.POSITIONS[second - 1]]["iid"])
            for unit in boosted.values():
                original = next(v for v in attack.values() if v["iid"] == unit["iid"])
                self.assertEqual(unit["dodge"], original.get("dodge", 0) + 10)
            for pos, unit in weakened.items():
                self.assertEqual(unit["hit"], defense[pos].get("hit", 0) - 20)
                self.assertEqual(unit["criticaldmg"], defense[pos].get("criticaldmg", 0) - 10)
            self.assertEqual(protocol.pb_get_varint(packets[0][16:], 1), 0)
            after = copy.deepcopy(session.save)
            self.assertEqual((after["mieshendian_state"]["floor"], after["mieshendian_state"]["failcount"],
                              after["mieshendian_state"]["star"], after["mieshendian_state"]["earned"]), (5, 1, 0, 12))
            self.assertEqual(after["role_state"], before["role_state"])
            self.assertEqual(after["world_state"], before["world_state"])
            self.assertEqual(session.handle(3622, 26100, body), packets)
            self.clock.return_value += 1
            session.handle(999904, 26101, b"")
            disk, memory = self.save_path.read_bytes(), copy.deepcopy(session.save)
            self.assertEqual(struct.unpack(">IIII", session.handle(3622, 26100, body)[0][:16])[2], 999999)
            self.assertEqual(session.save, memory)
            self.assertEqual(self.save_path.read_bytes(), disk)

    def test_mieshendian_losses_exhaust_only_the_current_floor_without_rewards(self):
        before = self.prepare_mieshendian(strong=False)
        for _ in range(3):
            response = self.replay([self.activity_request(3621, [1])])[0]
            self.assertEqual(response["opcode"], 3621)
            self.assertEqual(protocol.pb_get_varint(bytes.fromhex(response["hex"]), 1), 0)
        after = json.loads(self.save_path.read_text())
        self.assertEqual(after["role_state"], before["role_state"])
        self.assertEqual(after["world_state"], before["world_state"])
        self.assertEqual(protocol.parse_ids_pb(self.query_world(3620)), [0, 0, 0, 3, 1, 0, 0, 0, 0, 0, 0])
        disk = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([self.activity_request(3621, [3])]), 3621, 20000, "失败次数已用完")
        self.assertEqual(self.save_path.read_bytes(), disk)

    def test_mieshendian_invalid_locked_and_unsupported_requests_do_not_mutate(self):
        baseline = self.prepare_mieshendian()
        cases = [(3620, [1]), (3621, []), (3621, [0]), (3621, [4]), (3621, [3, 1]),
                 (3622, [0, 0, 0, 1, 2, 3, 4, 5, 6, 7])]
        cases += [(opcode, [1, 1]) for opcode in (3623, 3624, 3625, 3626, 3627, 3628)]
        bodies = [(opcode, bytes.fromhex(self.activity_request(opcode, values)["hex"]), "normal") for opcode, values in cases]
        bodies += [(3621, b"\x08", "truncated"), (3621, b"\x08\x03\x10\x01", "wire"),
                   (3621, b"\x08\x03", "level"), (3621, b"\x08\x03", "boss-phase")]
        bodies += [(3622, bytes.fromhex(self.activity_request(3622, values)["hex"]), "boss") for values in
                   ([2, 0, 0, 1, 2, 3, 4, 5, 6, 7], [0, 0, 0, 1, 1, 3, 4, 5, 6, 7],
                    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [1, 1, 1, 1, 2, 3, 4, 5, 6, 7])]
        for opcode, body, kind in bodies:
            saved = copy.deepcopy(baseline)
            if kind == "level":
                saved["role_state"]["level"] = 14
            elif kind in ("boss", "boss-phase"):
                saved["mieshendian_state"].update(floor=5, earned=1, star=1, maxfloor=4, maxstar=1,
                                                  best={str(i): 1 for i in range(1, 5)})
            self.save_path.write_text(json.dumps(saved))
            disk = self.save_path.read_bytes()
            with self.subTest(opcode=opcode, body=body, kind=kind), redirect_stdout(io.StringIO()):
                session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
                memory = copy.deepcopy(session.save)
                packets = session.handle(opcode, 26200, body)
                self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 999999)
                self.assertEqual(session.save, memory)
                self.assertEqual(self.save_path.read_bytes(), disk)

    def test_mieshendian_save_failure_and_overflow_roll_back_the_whole_battle(self):
        baseline = self.prepare_mieshendian()
        body = bytes.fromhex(self.activity_request(3621, [3])["hex"])
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            disk, memory = self.save_path.read_bytes(), copy.deepcopy(session.save)
            with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
                session.handle(3621, 26300, body)
            self.assertEqual(session.save, memory)
            self.assertEqual(self.save_path.read_bytes(), disk)
            self.assertEqual(session.random_replies, {})
        for kind in ("coin", "star", "points"):
            saved = copy.deepcopy(baseline)
            if kind == "coin":
                saved["role_state"]["coin"] = (1 << 63) - 100
            elif kind == "star":
                saved["mieshendian_state"].update(star=(1 << 31) - 1, earned=(1 << 31) - 1, maxstar=(1 << 31) - 1)
            else:
                saved["mieshendian_state"]["points"] = (1 << 31) - 1
            self.save_path.write_text(json.dumps(saved))
            with self.subTest(kind=kind), redirect_stdout(io.StringIO()):
                session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
                disk, memory = self.save_path.read_bytes(), copy.deepcopy(session.save)
                self.assertEqual(struct.unpack(">IIII", session.handle(3621, 26301, body)[0][:16])[2], 999999)
                self.assertEqual(session.save, memory)
                self.assertEqual(self.save_path.read_bytes(), disk)

    def test_mieshendian_daily_statistic_reset_keeps_climb_and_never_reopens_on_rollback(self):
        self.prepare_mieshendian()
        self.replay([self.activity_request(3621, [3])])
        self.clock.return_value += 86400
        self.assertEqual(protocol.parse_ids_pb(self.query_world(3620)), [1, 0, 0, 0, 2, 3, 0, 0, 300, 3, 0])
        self.replay([self.activity_request(3621, [2])])
        self.clock.return_value -= 86400
        self.assertEqual(protocol.parse_ids_pb(self.query_world(3620)), [2, 2, 0, 0, 3, 5, 0, 0, 500, 5, 0])

    def test_mieshendian_all_supported_difficulties_generate_consistent_battles(self):
        baseline = self.prepare_mieshendian()
        protagonist = bytes.fromhex(baseline["protagonist_snapshot"])
        raw = next(v for n, w, v in protocol.iter_pb_fields(protagonist) if (n, w) == (10, 2))
        raw = protocol.pb_set_varint(protocol.pb_set_varint(raw, 1, 10128), 4, 6)
        player.record_protagonist_general(baseline, raw)
        player.record_slot_update(baseline, protocol.encode_pb_field(1, 2, raw))
        checked = 0
        for floor in range(1, max(map(int, self.role_config["mieshendian_monster_param"])) + 1):
            for difficulty in self.role_config["mieshendian_monster_param"][str(floor)]:
                self.save_path.write_text(json.dumps(baseline))
                with redirect_stdout(io.StringIO()):
                    session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
                    session.save["mieshendian_state"].update(floor=floor, star=12, earned=12, maxfloor=floor - 1,
                                                              maxstar=12, best={str(i): 1 for i in range(1, floor)})
                    opcode = 3622 if floor % 5 == 0 else 3621
                    values = [0, 0, 0, 1, 2, 3, 4, 5, 6, 7] if floor % 5 == 0 else [int(difficulty)]
                    with self.subTest(floor=floor, difficulty=difficulty):
                        packets = session.handle(opcode, 26400, bytes.fromhex(self.activity_request(opcode, values)["hex"]))
                        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], opcode)
                        report = next(v for n, w, v in protocol.iter_pb_fields(packets[0][16:]) if (n, w) == (5, 2))
                        report = json.loads(report)
                        killed = all(unit["h"] == 0 for unit in report["endmeta"]["defense"].values())
                        alive = any(unit["h"] > 0 for unit in report["endmeta"]["attack"].values())
                        condition = mieshendian.condition_met({**report, "result": killed and alive}, self.role_config["mieshendian_condition"][str(floor)])
                        self.assert_battle_report(report, condition)
                        checked += 1
        self.assertEqual(checked, 780)

    def seed_mieshendian_history(self, cleared=5):
        saved = self.prepare_mieshendian()
        saved["role_state"].update(vip=3, gold=10000)
        saved["mieshendian_state"] = {"floor": cleared + 1, "failcount": 0, "star": cleared, "earned": cleared,
                                      "day": (self.now + 28800) // 86400, "todaymaxfloor": cleared}
        mieshendian.get_state(saved, self.role_config)
        self.save_path.write_text(json.dumps(saved))
        return saved

    def test_mieshendian_natural_sweep_finishes_after_reconnect_once_and_syncs_assets(self):
        before = self.seed_mieshendian_history()
        self.replay([self.activity_request(3626)])
        start = self.replay([self.activity_request(3623)])[0]
        self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(start["hex"]))[6], 225)
        self.assertEqual(json.loads(self.save_path.read_text())["mieshendian_state"]["floor"], 1)
        disk = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([self.activity_request(3621, [3])]), 3621, 20000, "正在扫荡")
        self.assertEqual(self.save_path.read_bytes(), disk)
        self.clock.return_value += 224
        self.assertEqual(protocol.parse_ids_pb(self.query_world(3620))[6], 1)
        self.clock.return_value += 1
        frames = self.replay([self.activity_request(3620)])
        self.assertEqual(frames[0]["opcode"], 3620)
        self.assertIn(1200, [frame["opcode"] for frame in frames])
        self.assertIn(1001, [frame["opcode"] for frame in frames])
        after = json.loads(self.save_path.read_text())
        self.assertEqual((after["mieshendian_state"]["floor"], after["mieshendian_state"]["maxfloor"],
                          after["mieshendian_state"]["points"], after["mieshendian_state"]["star"]), (6, 5, 1000, 5))
        old = self.entity_records(bytes.fromhex(before["world_state"]["1200"]), 1, 1)
        new = self.entity_records(bytes.fromhex(after["world_state"]["1200"]), 1, 1)
        self.assertEqual(new.get(20257), old.get(20257))
        self.assertEqual(after["world_state"]["1002"], before["world_state"]["1002"])
        for key in ("guide", "last_battle", "last_star_battle", "last_mieshendian_battle"):
            self.assertEqual(after.get(key), before.get(key))
        self.query_world(3620)
        self.assertEqual(json.loads(self.save_path.read_text())["world_state"], after["world_state"])

    def test_mieshendian_force_finish_charges_actual_minutes_and_caches_once(self):
        self.seed_mieshendian_history()
        self.replay([self.activity_request(3626), dict(self.activity_request(3623), seq=20001)])
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            gold = session.save["role_state"]["gold"]
            packets = session.handle(3624, 28000, b"")
            self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 3624)
            self.assertEqual(session.save["role_state"]["gold"], gold - 4)
            self.assertEqual(session.save["mieshendian_state"]["floor"], 6)
            self.assertIsNone(session.save["mieshendian_state"]["sweep"])
            self.assertEqual(session.handle(3624, 28000, b""), packets)
            self.assertEqual(struct.unpack(">IIII", packets[-1][:16])[2], 1001)

    def test_mieshendian_daily_and_lifetime_shop_limits_use_actual_points(self):
        before = self.seed_mieshendian_history(300)
        before["mieshendian_state"].update(points=200000, maxstar=780)
        self.save_path.write_text(json.dumps(before))
        for iid in sorted(map(int, self.role_config["mieshendian_shop"])):
            with self.subTest(iid=iid):
                result = self.replay([self.activity_request(3628, [iid])])[0]
                self.assertEqual(result["opcode"], 3628)
        after = json.loads(self.save_path.read_text())
        self.assertEqual(after["mieshendian_state"]["points"], 140000)
        self.assertEqual(after["role_state"]["gold"], before["role_state"]["gold"])
        self.assertEqual(after["world_state"]["1300"], before["world_state"]["1300"])
        disk = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([self.activity_request(3628, [101])]), 3628, 20000, "次数已用完")
        self.assertEqual(self.save_path.read_bytes(), disk)
        self.clock.return_value += 86400
        self.assertEqual(self.replay([self.activity_request(3628, [1])])[0]["opcode"], 3628)
        self.assertEqual(self.replay([self.activity_request(3628, [101])])[0]["opcode"], 999999)
        self.clock.return_value -= 86400
        state = json.loads(self.save_path.read_text())["mieshendian_state"]
        self.query_world(3627)
        self.assertEqual(json.loads(self.save_path.read_text())["mieshendian_state"]["daily_bought"], state["daily_bought"])

    def test_mieshendian_all_boss_bonuses_and_initial_ap_are_temporary(self):
        for floor, row in self.role_config["mieshendian_attr"].items():
            teams = [{pos: self.combat_unit(10201, iid=pos + i * 100, initial_ap=2) for pos in battle.POSITIONS}
                     for i in range(2)]
            with self.subTest(floor=floor):
                mieshendian.apply_bonuses(*teams, row, [1, 1, 1], self.role_config)
                battle._prepare_teams({True: teams[0], False: teams[1]}, self.role_config)
        attack = {2: self.combat_unit(10201), 8: self.combat_unit(10201, iid=2)}
        defense = {2: self.combat_unit(10201, iid=3, initial_ap=9)}
        mieshendian.apply_bonuses(attack, defense, self.role_config["mieshendian_attr"]["10"], [1, 1, 1], self.role_config)
        battle._prepare_teams({True: attack, False: defense}, self.role_config)
        self.assertEqual((attack[2]["atk"], attack[2]["ap"], defense[2]["ap"]), (140, 3, 9))
        for value in (-1, 11, True, 2.5):
            with self.subTest(initial_ap=value), self.assertRaisesRegex(ValueError, "初始怒气"):
                battle._prepare_teams({True: {2: self.combat_unit(10201, initial_ap=value)}}, self.role_config)

    def test_mieshendian_expired_sweep_is_free_and_only_queries_settle_it(self):
        baseline = self.seed_mieshendian_history()
        for opcode in (3620, 3627, 3624):
            saved = copy.deepcopy(baseline)
            saved["mieshendian_state"].update(floor=1, star=0, earned=0,
                                              sweep={"target": 5, "end_at": self.now})
            self.save_path.write_text(json.dumps(saved))
            with self.subTest(opcode=opcode):
                disk = self.save_path.read_bytes()
                self.assert_unavailable_response(self.replay([self.activity_request(3626)]), 3626, 20000, "正在扫荡")
                self.assertEqual(self.save_path.read_bytes(), disk)
                frames = self.replay([self.activity_request(opcode)])
                self.assertEqual(frames[0]["opcode"], opcode)
                after = json.loads(self.save_path.read_text())
                self.assertEqual(after["role_state"]["gold"], saved["role_state"]["gold"])
                self.assertEqual(after["mieshendian_state"]["floor"], 6)
                self.assertIsNone(after["mieshendian_state"]["sweep"])
                self.assertIn(1001, [frame["opcode"] for frame in frames])
                if opcode == 3624:
                    disk = self.save_path.read_bytes()
                    self.assertEqual(self.replay([self.activity_request(3624)])[0]["opcode"], 999999)
                    self.assertEqual(self.save_path.read_bytes(), disk)

    def test_mieshendian_paid_finish_insufficient_gold_rolls_back_all_sweep_rewards(self):
        saved = self.seed_mieshendian_history()
        saved["role_state"]["gold"] = 3
        saved["mieshendian_state"].update(floor=1, star=0, earned=0,
                                          sweep={"target": 5, "end_at": self.now + 225})
        self.save_path.write_text(json.dumps(saved))
        disk = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([self.activity_request(3624)]), 3624, 20000, "gold 不足")
        self.assertEqual(self.save_path.read_bytes(), disk)

    def test_mieshendian_condition_failure_never_grants_rewards_or_progress(self):
        before = self.prepare_mieshendian()
        config = copy.deepcopy(self.role_config)
        config["mieshendian_condition"]["1"] = {"condition": 2, "condition_param": 0}
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, config)
            packet = session.handle(3621, 28001, recharge.ids([3]))[0]
        self.assertEqual(protocol.pb_get_varint(packet[16:], 1), 0)
        after = json.loads(self.save_path.read_text())
        self.assertEqual(after["world_state"], before["world_state"])
        self.assertEqual(after["role_state"], before["role_state"])
        self.assertEqual(after["mieshendian_state"]["floor"], 1)
        self.assertEqual(after["mieshendian_state"]["failcount"], 1)
        self.assertEqual(after["mieshendian_state"]["points"], 0)

    def test_mieshendian_reset_daily_cap_and_clock_rollback(self):
        self.seed_mieshendian_history()
        for _ in range(2):
            self.assertEqual(self.replay([self.activity_request(3626)])[0]["opcode"], 3626)
            self.replay([self.activity_request(3621, [1])])
        disk = self.save_path.read_bytes()
        self.assertEqual(self.replay([self.activity_request(3626)])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), disk)
        self.clock.return_value += 86400
        self.assertEqual(self.replay([self.activity_request(3626)])[0]["opcode"], 3626)
        self.clock.return_value -= 86400
        self.assertEqual(protocol.parse_ids_pb(self.query_world(3620))[2], 1)

    def test_mieshendian_new_mutations_save_failure_and_insufficient_cost_roll_back(self):
        saved = self.seed_mieshendian_history(5)
        saved["mieshendian_state"]["points"] = 4000
        self.save_path.write_text(json.dumps(saved))
        for opcode, body in ((3626, b""), (3628, recharge.ids([1]))):
            with self.subTest(opcode=opcode), redirect_stdout(io.StringIO()):
                session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
                disk, memory = self.save_path.read_bytes(), copy.deepcopy(session.save)
                with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
                    session.handle(opcode, 28002, body)
                self.assertEqual(session.save, memory)
                self.assertEqual(self.save_path.read_bytes(), disk)
        saved["mieshendian_state"]["points"] = 2999
        self.save_path.write_text(json.dumps(saved))
        disk = self.save_path.read_bytes()
        self.assertEqual(self.replay([self.activity_request(3628, [1])])[0]["opcode"], 999999)
        self.assertEqual(self.save_path.read_bytes(), disk)

    def test_mieshendian_sweep_start_finish_and_natural_settlement_save_failure_are_atomic(self):
        baseline = self.seed_mieshendian_history()
        for opcode in (3623, 3624, 3620):
            saved = copy.deepcopy(baseline)
            saved["mieshendian_state"].update(floor=1, star=0, earned=0)
            if opcode != 3623:
                saved["mieshendian_state"]["sweep"] = {"target": 5, "end_at": self.now + (225 if opcode == 3624 else 0)}
            self.save_path.write_text(json.dumps(saved))
            with self.subTest(opcode=opcode), redirect_stdout(io.StringIO()):
                session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
                disk, memory = self.save_path.read_bytes(), copy.deepcopy(session.save)
                with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
                    session.handle(opcode, 28003, b"")
                self.assertEqual(session.save, memory)
                self.assertEqual(self.save_path.read_bytes(), disk)
                self.assertEqual(session.random_replies, {})

    def test_mieshendian_sweep_eligibility_and_clock_rollback(self):
        saved = self.seed_mieshendian_history()
        saved["role_state"].update(vip=0)
        saved["mieshendian_state"].update(floor=1, star=0, earned=0)
        self.save_path.write_text(json.dumps(saved))
        disk = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([self.activity_request(3623)]), 3623, 20000, "等级或VIP不足")
        self.assertEqual(self.save_path.read_bytes(), disk)
        saved["role_state"]["level"] = 40
        self.save_path.write_text(json.dumps(saved))
        self.assertEqual(self.replay([self.activity_request(3623)])[0]["opcode"], 3623)
        self.clock.return_value += 100
        self.assertEqual(protocol.parse_ids_pb(self.query_world(3620))[6], 125)
        self.clock.return_value -= 86400
        self.assertEqual(protocol.parse_ids_pb(self.query_world(3620))[6], 125)

    def test_mieshendian_ranking_uses_atomic_local_saves_and_never_settles_other_accounts(self):
        saved = self.seed_mieshendian_history(5)
        store = accounts.AccountStore(self.save_path, self.tables, self.step_counts, self.role_config)
        for account, cleared, stars in ((1, 5, 5), (2, 10, 10), (3, 5, 6)):
            role = copy.deepcopy(saved)
            role["role_name"] = f"灭神角色{account}"
            role["mieshendian_state"] = {"floor": cleared + 1, "failcount": 0, "star": stars, "earned": stars,
                                        "day": 0, "todaymaxfloor": 0}
            path = store.path(account)
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(json.dumps(role))
        files = {path: path.read_bytes() for path in self.save_path.parent.glob("**/*.json")}
        raw = self.query_world(3625)
        rows = list(self.entity_records(raw, 1, 1).values())
        names = [next(v.decode() for n, w, v in protocol.iter_pb_fields(row) if n == 2) for row in rows]
        self.assertEqual(names, ["灭神角色2", "灭神角色3", "灭神角色1"])
        self.assertEqual(len({protocol.pb_get_varint(row, 1) for row in rows}), 3)
        for row, expected in zip(rows, (10, 5, 5)):
            params = next(v for n, w, v in protocol.iter_pb_fields(row) if n == 8)
            values = [protocol.pb_get_varint(v, 1) for n, w, v in protocol.iter_pb_fields(params)]
            self.assertEqual(values[4:], [expected])
        for path, data in files.items():
            self.assertEqual(path.read_bytes(), data)
        store.path(2).write_text("broken")
        self.assertEqual(self.replay([self.activity_request(3625)])[0]["opcode"], 999999)

    def test_mieshendian_completed_final_floor_rejects_battle_without_repeating_reward(self):
        self.seed_mieshendian_history(300)
        disk = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([self.activity_request(3621, [3])]), 3621, 20000, "全部层数")
        self.assertEqual(self.save_path.read_bytes(), disk)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(3620))[0:2], [300, 300])

    def test_mieshendian_corrupt_new_fields_fail_closed_without_migration_credit(self):
        baseline = self.seed_mieshendian_history()
        for changes in ({"maxfloor": 4}, {"points": -1}, {"maxstar": 0}, {"resets": True},
                        {"best": {}}, {"bought": {"101": 2}}, {"daily_bought": {"1": 6}},
                        {"sweep": {"target": 6, "end_at": self.now + 45}},
                        {"floor": 1, "sweep": {"target": 4, "end_at": self.now + 45}}):
            saved = copy.deepcopy(baseline)
            saved["mieshendian_state"].update(changes)
            self.save_path.write_text(json.dumps(saved))
            disk = self.save_path.read_bytes()
            with self.subTest(changes=changes), redirect_stdout(io.StringIO()), self.assertRaisesRegex(ValueError, "灭神殿"):
                Session(self.tables, self.save_path, self.step_counts, self.role_config)
            self.assertEqual(self.save_path.read_bytes(), disk)

    def test_mieshendian_all_reward_configurations_can_be_applied_without_discarding_items(self):
        baseline = self.prepare_mieshendian()
        for floor, rows in self.role_config["mieshendian_monster_param"].items():
            for difficulty, row in rows.items():
                specifications = [row["star1reward"]]
                if floor in self.role_config["mieshendian_reward"]:
                    specifications.append(self.role_config["mieshendian_reward"][floor]["rewards"])
                specifications.extend(item["reward"] for item in self.role_config["mieshendian_award"].values()
                                      if item["number"] == int(floor))
                with self.subTest(floor=floor, difficulty=difficulty):
                    save = copy.deepcopy(baseline)
                    reward = activities.build_reward(save, ";".join(specifications), self.role_config)
                    player.apply_reward(save, reward, self.role_config, self.now)

    def test_mieshendian_sequential_300_floor_victory_settlement_preserves_history(self):
        saved = self.prepare_mieshendian()
        before = self.save_path.read_bytes()
        for floor in range(1, 301):
            difficulty = 1 if floor % 5 == 0 else 3
            with self.subTest(floor=floor):
                specifications = mieshendian.victory(saved["mieshendian_state"], floor, difficulty, self.role_config)
                reward = activities.build_reward(saved, ";".join(specifications), self.role_config)
                player.apply_reward(saved, reward, self.role_config, self.now)
                self.assertEqual(saved["mieshendian_state"]["floor"], floor + 1)
        self.assertEqual((saved["mieshendian_state"]["maxfloor"], saved["mieshendian_state"]["maxstar"],
                          saved["mieshendian_state"]["points"]), (300, 780, 78000))
        state = saved["mieshendian_state"]
        state.update(floor=1, star=0, earned=0, sweep={"target": 300, "end_at": self.now})
        reward = mieshendian.finish_sweep(saved, self.role_config, self.now)
        old = self.entity_records(bytes.fromhex(saved["world_state"]["1200"]), 1, 1)
        player.apply_reward(saved, reward, self.role_config, self.now)
        new = self.entity_records(bytes.fromhex(saved["world_state"]["1200"]), 1, 1)
        self.assertEqual(new.get(20257), old.get(20257))
        self.assertEqual((state["floor"], state["maxstar"], state["points"]), (301, 780, 156000))
        self.assertIsNone(state["sweep"])
        self.assertEqual(self.save_path.read_bytes(), before)

    def test_mieshendian_corrupt_progress_fails_closed_without_overwriting(self):
        baseline = self.prepare_mieshendian()
        for changes in ({"floor": 0}, {"floor": 302}, {"star": 1}, {"todaymaxfloor": 1},
                        {"failcount": 4}, {"earned": True}):
            saved = copy.deepcopy(baseline)
            saved["mieshendian_state"].update(changes)
            self.save_path.write_text(json.dumps(saved))
            disk = self.save_path.read_bytes()
            with self.subTest(changes=changes), redirect_stdout(io.StringIO()), self.assertRaisesRegex(ValueError, "灭神殿"):
                Session(self.tables, self.save_path, self.step_counts, self.role_config)
            self.assertEqual(self.save_path.read_bytes(), disk)

    def star_copy_groups(self, body):
        return {mid: [value - (1 << 64) if value >= (1 << 63) else value for value in values]
                for mid, values in self.begin7day_groups(body).items()}

    def prepare_star_copy(self, strong=True):
        self.complete_tutorial()
        saved = json.loads(self.save_path.read_text())
        saved["role_state"].update(level=14, nextexp=self.role_config["role_exp"]["14"]["nextexp"])
        for raw in self.entity_records(bytes.fromhex(saved["world_state"]["1002"]), 1, 2).values():
            for field in (6, 8):
                raw = protocol.pb_set_varint(raw, field, 100000 if strong else 1)
            player.record_slot_update(saved, protocol.encode_pb_field(1, 2, raw))
            player.record_protagonist_general(saved, raw)
        self.save_path.write_text(json.dumps(saved))
        return saved

    def test_star_copy_query_populates_guide_chapter_without_granting_progress(self):
        before = self.prepare_star_copy()
        body = self.query_world(1350)
        groups = self.star_copy_groups(body)
        self.assertEqual(groups[0], [0])
        self.assertEqual(set(groups), {0, 42101, 42102, 42103, 42104, 42105})
        self.assertEqual(groups[42101], [42101, 0, 1, -1, 0])
        self.assertTrue(all(groups[mid] == [mid, -1] for mid in range(42102, 42106)))
        after = json.loads(self.save_path.read_text())
        self.assertEqual(before["guide"], after["guide"])
        self.assertEqual(before["world_state"], after["world_state"])
        self.assertEqual(before["role_state"], after["role_state"])

    def test_star_copy_first_win_is_live_atomic_and_not_a_campaign_clear(self):
        before = self.prepare_star_copy()
        body = bytes.fromhex(self.activity_request(1351, [42101, 1])["hex"])
        with redirect_stdout(io.StringIO()), patch.object(player.random, "getrandbits", return_value=42):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            with patch.object(player, "save_role", wraps=player.save_role) as persist:
                packets = session.handle(1351, 25000, body)
                self.assertEqual(persist.call_count, 1)
            self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2:], (1351, 25000))
            fields = {n: v for n, w, v in protocol.iter_pb_fields(packets[0][16:])}
            self.assertEqual(fields[1], 1)
            report = json.loads(fields[5])
            self.assertTrue(report["result"])
            self.assert_battle_report(report)
            after = copy.deepcopy(session.save)
            self.assertEqual(json.loads(self.save_path.read_text()), after)
            self.assertEqual(session.handle(1351, 25000, body), packets)
        self.assertEqual(after["role_state"]["gold"] - before["role_state"]["gold"], 40)
        for key in ("level", "exp", "coin", "stamina", "energy", "power"):
            self.assertEqual(after["role_state"][key], before["role_state"][key])
        for key in ("guide", "last_battle"):
            self.assertEqual(after.get(key), before.get(key))
        for mid in (1002, 1012, 1107, 1300):
            self.assertEqual(after["world_state"][str(mid)], before["world_state"][str(mid)])
        self.assertEqual(self.star_copy_groups(self.query_world(1350))[42101], [42101, 1, 1, 1, 0])
        result = self.replay([self.activity_request(1351, [42101, 1])])
        self.assertEqual(result[0]["opcode"], 999999)

    def test_star_copy_initial_comb_uses_local_query_instead_of_empty_capture(self):
        self.prepare_star_copy()
        result = self.replay([dict(self.by_seq[12], seq=25100)])[0]
        body = next(data for mid, data in protocol.get_comb_messages(bytes.fromhex(result["hex"])) if mid == 1350)
        self.assertEqual(self.star_copy_groups(body)[42101], [42101, 0, 1, -1, 0])
        self.assertEqual(body, self.query_world(1350))

    def test_star_copy_losses_do_not_grant_rewards_or_consume_success_counts(self):
        before = self.prepare_star_copy(strong=False)
        result = self.replay([self.activity_request(1351, [42101, 1])])[0]
        self.assertEqual(result["opcode"], 1351)
        fields = {n: v for n, w, v in protocol.iter_pb_fields(bytes.fromhex(result["hex"]))}
        self.assertEqual(fields[1], 0)
        self.assert_battle_report(json.loads(fields[5]))
        after = json.loads(self.save_path.read_text())
        self.assertEqual(after["role_state"], before["role_state"])
        self.assertEqual(after["world_state"], before["world_state"])
        self.assertEqual(after["star_copy_state"]["progress"], {})
        self.assertEqual(after["star_copy_state"]["wins"], {})
        self.assertEqual(after["guide"], before["guide"])

    def test_star_copy_day_reset_keeps_first_win_and_never_reopens_on_clock_rollback(self):
        saved = self.prepare_star_copy()
        for pid in self.role_config["copy"]["42102"]:
            player.record_copy_win(saved, bytes.fromhex(self.activity_request(1306, [42102, int(pid)])["hex"]),
                                   3, self.role_config, allow_repeat=True)
        self.save_path.write_text(json.dumps(saved))
        self.replay([self.activity_request(1351, [42101, 1])])
        won = json.loads(self.save_path.read_text())
        self.clock.return_value += 86400
        rows = self.star_copy_groups(self.query_world(1350))
        self.assertEqual(rows[0], [0])
        self.assertEqual(rows[42101], [42101, 1, 1, 0, 0])
        self.assertEqual(rows[42102], [42102, 0, 1, -1, 0])
        self.replay([self.activity_request(1351, [42101, 1])])
        repeated = json.loads(self.save_path.read_text())
        self.assertEqual(repeated["role_state"]["gold"], won["role_state"]["gold"])
        self.clock.return_value -= 86400
        rows = self.star_copy_groups(self.query_world(1350))
        self.assertEqual(rows[0], [1])
        self.assertEqual(rows[42101], [42101, 1, 1, 1, 0])
        result = self.replay([self.activity_request(1351, [42101, 1])])
        self.assertEqual(result[0]["opcode"], 999999)

    def test_star_copy_rejects_malformed_locked_and_exhausted_requests_without_mutation(self):
        baseline = self.prepare_star_copy()
        valid = bytes.fromhex(self.activity_request(1351, [42101, 1])["hex"])
        cases = [(1350, b"\x08\x01", "query"), (1351, b"", "empty"), (1351, b"\x08", "truncated"),
                 (1351, valid + b"\x08\x01", "extra"), (1351, valid + b"\x10\x01", "wire"),
                 (1351, valid, "level"), (1351, valid, "ordinary"), (1351, valid, "limit")]
        cases += [(1351, bytes.fromhex(self.activity_request(1351, values)["hex"]), str(values))
                  for values in ([0, 1], [99999, 1], [42101, 2], [42102, 1], [42104, 2], [42106, 1], [1 << 31, 1])]
        for opcode, body, kind in cases:
            saved = copy.deepcopy(baseline)
            if kind == "level":
                saved["role_state"]["level"] = 13
            elif kind == "ordinary":
                saved["world_state"]["1300"] = ""
            elif kind == "limit":
                saved["star_copy_state"].update(day=(self.now + 8 * 3600) // 86400,
                    progress={str(mid): max(map(int, self.role_config["star_copy"][str(mid)])) for mid in range(42101, 42106)},
                    wins={f"{mid}/1": 1 for mid in range(42101, 42106)})
            self.save_path.write_text(json.dumps(saved))
            original = self.save_path.read_bytes()
            with self.subTest(kind=kind), redirect_stdout(io.StringIO()):
                session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
                memory = copy.deepcopy(session.save)
                packets = session.handle(opcode, 25200, body)
                self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 999999)
                self.assertEqual(session.save, memory)
                self.assertEqual(self.save_path.read_bytes(), original)

    def test_star_copy_save_failure_and_reward_overflow_roll_back_the_whole_win(self):
        baseline = self.prepare_star_copy()
        body = bytes.fromhex(self.activity_request(1351, [42101, 1])["hex"])
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            memory, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
            with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
                session.handle(1351, 25300, body)
            self.assertEqual(session.save, memory)
            self.assertEqual(self.save_path.read_bytes(), disk)
            self.assertEqual(session.random_replies, {})
            self.assertEqual(struct.unpack(">IIII", session.handle(1351, 25300, body)[0][:16])[2], 1351)
            baseline["role_state"]["gold"] = (1 << 31) - 20
            self.save_path.write_text(json.dumps(baseline))
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            memory, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
            self.assertEqual(struct.unpack(">IIII", session.handle(1351, 25301, body)[0][:16])[2], 999999)
            self.assertEqual(session.save, memory)
            self.assertEqual(self.save_path.read_bytes(), disk)

    def test_star_copy_chapter_progress_and_daily_cap_survive_reconnect(self):
        saved = self.prepare_star_copy()
        for mid in range(42101, 42106):
            for pid in self.role_config["copy"][str(mid)]:
                player.record_copy_win(saved, bytes.fromhex(self.activity_request(1306, [mid, int(pid)])["hex"]),
                                       3, self.role_config, allow_repeat=True)
        self.save_path.write_text(json.dumps(saved))
        for mid, pid in ((42101, 1), (42102, 1), (42103, 1), (42104, 1), (42104, 2)):
            result = self.replay([self.activity_request(1351, [mid, pid])])
            self.assertEqual(result[0]["opcode"], 1351)
            self.assertEqual(protocol.pb_get_varint(bytes.fromhex(result[0]["hex"]), 1), 1)
        groups = self.star_copy_groups(self.query_world(1350))
        self.assertEqual(groups[0], [5])
        self.assertEqual(groups[42104], [42104, 1, 1, 1, 0, 2, 1, 0])
        self.assertEqual(groups[42105], [42105, 0, 1, -1, 0])
        before = self.save_path.read_bytes()
        result = self.replay([self.activity_request(1351, [42105, 1])])
        self.assert_unavailable_response(result, 1351, 20000, "次数已用完")
        self.assertEqual(self.save_path.read_bytes(), before)
        self.clock.return_value += 86400
        for pid in (1, 2):
            self.assertEqual(self.replay([self.activity_request(1351, [42105, pid])])[0]["opcode"], 1351)
        groups = self.star_copy_groups(self.query_world(1350))
        self.assertEqual(groups[0], [2])
        self.assertEqual(groups[42105], [42105, 1, 1, 1, 0, 2, 1, 0])
        result = self.replay([self.activity_request(1351, [42106, 1])])
        self.assert_unavailable_response(result, 1351, 20000, "仅开放第一章")

    def test_star_copy_maps_follow_ordinary_conditions_not_an_extra_named_map_gate(self):
        saved = self.prepare_star_copy()
        for pid in self.role_config["copy"]["42105"]:
            player.record_copy_win(saved, bytes.fromhex(self.activity_request(1306, [42105, int(pid)])["hex"]),
                                   3, self.role_config, allow_repeat=True)
        self.save_path.write_text(json.dumps(saved))
        groups = self.star_copy_groups(self.query_world(1350))
        self.assertEqual(groups[42105], [42105, 0, 1, -1, 0])
        result = self.replay([self.activity_request(1351, [42105, 1])])
        self.assertEqual(result[0]["opcode"], 1351)
        self.assertEqual(json.loads(self.save_path.read_text())["star_copy_state"]["progress"], {"42105": 1})

    def test_star_copy_corrupt_progress_fails_closed_without_changing_the_save(self):
        baseline = self.prepare_star_copy()
        bad = [{"day": True, "progress": {}, "wins": {}}, {"day": 0, "progress": {"42101": 2}, "wins": {}},
               {"day": 0, "progress": {}, "wins": {"42101/1": 1}},
               {"day": 0, "progress": {"42101": 1}, "wins": {"42101/1": 2}},
               {"day": 0, "progress": {}, "wins": []}]
        for state in bad:
            baseline["star_copy_state"] = state
            self.save_path.write_text(json.dumps(baseline))
            before = self.save_path.read_bytes()
            with self.subTest(state=state), redirect_stdout(io.StringIO()), self.assertRaisesRegex(ValueError, "名将副本"):
                Session(self.tables, self.save_path, self.step_counts, self.role_config)
            self.assertEqual(self.save_path.read_bytes(), before)

    def test_star_copy_first_chapter_rosters_reports_and_positive_drops_are_supported(self):
        saved = self.prepare_star_copy()
        checked = 0
        for mid, points in self.role_config["star_copy"].items():
            if self.role_config["star_map"][mid]["section"] != star_copy.SECTION:
                continue
            for pid, point in points.items():
                with self.subTest(map=mid, point=pid):
                    checked += 1
                    attack, defense = battle.rosters(saved, point, self.role_config)
                    self.assert_battle_report(battle.simulate(attack, defense, self.role_config, 7))
                    for i in range(1, 6):
                        if point[f"drop{i}"] and point[f"drop{i}prob"]:
                            activities.build_reward(saved, f'{point[f"drop{i}"]},{point[f"drop{i}number"]}', self.role_config)
        self.assertEqual(checked, 7)

    def test_campaign_zero_weight_drops_are_disabled_not_invalid(self):
        point = self.role_config["copy"]["42106"]["1"]
        disabled = {int(row.split(",")[0]) for row in self.role_config["worlddrop"]["29000"]["drop"].split(";")
                    if row and int(row.split(",")[2]) == 0}
        for seed in range(100):
            rewards = battle.drops(point, True, self.role_config, seed)
            self.assertFalse(disabled & rewards.keys())
        forced = dict(point, randdropprob=100, randdropprob1=0)
        for entries in ("", "28001,1,0;", "28001,1,-1;", "0,1,1;", "28001,0,1;", "28001,1;"):
            config = {**self.role_config, "worlddrop": {**self.role_config["worlddrop"], "29000": {"drop": entries}}}
            with self.subTest(entries=entries), self.assertRaisesRegex(ValueError, "掉落配置"):
                battle.drops(forced, True, config, 0)

    def test_every_active_campaign_drop_group_and_positive_reward_is_supported(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        self.assertTrue(all(point["xp"] > 0 for points in self.role_config["copy"].values() for point in points.values()))
        groups = {str(point[f"randdrop{suffix}"]) for points in self.role_config["copy"].values() for point in points.values()
                  for suffix in ("", "1") if point[f"randdropprob{suffix}"] > 0}
        for group in sorted(groups):
            with self.subTest(group=group):
                point = dict(self.role_config["copy"]["42106"]["1"], drop1=0, drop2=0, drop3=0,
                             randdrop=group, randdropprob=100, randdropprob1=0)
                self.assertTrue(battle.drops(point, False, self.role_config, 0))
                for entry in self.role_config["worlddrop"][group]["drop"].split(";"):
                    if entry:
                        cid, count, weight = map(int, entry.split(","))
                        if weight > 0:
                            activities.build_reward(saved, f"{cid},{count}", self.role_config)

    def test_campaign_sweep_batch_matches_singles_and_commits_once_before_reply(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        location = bytes.fromhex(self.activity_request(1306, [42102, 1])["hex"])
        player.record_copy_win(saved, location, 3, self.role_config, allow_repeat=True)
        config = copy.deepcopy(self.role_config)
        point = config["copy"]["42102"]["1"]
        point.update(drop=20014, drop1prob=0, drop2prob=0, drop3prob=0, randdropprob=0, randdropprob1=0)
        saved["role_state"].update(vip=2, stamina=point["physical"] * 3 + 1,
                                   exp=config["role_exp"][str(saved["role_state"]["level"])]["nextexp"] - 1)
        self.save_path.write_text(json.dumps(saved))
        request = bytes.fromhex(self.activity_request(1307, [42102, 1, 1, 0])["hex"])
        with redirect_stdout(io.StringIO()), patch.object(battle, "simulate", side_effect=AssertionError("扫荡不能伪造战报")):
            session = Session(self.tables, self.save_path, self.step_counts, config)
            with patch.object(player, "save_role", wraps=player.save_role) as persist:
                packets = session.handle(1307, 21000, request)
                self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2:], (1307, 21000))
                self.assertEqual(persist.call_count, 1)
            batch = copy.deepcopy(session.save)
            self.assertEqual(json.loads(self.save_path.read_text()), batch)
            self.assertEqual(session.handle(1307, 21000, request), packets)
            self.assertEqual(session.save, batch)
            fields = {n: v for n, w, v in protocol.iter_pb_fields(packets[0][16:])}
            self.assertEqual((fields[1], fields[2]), (1, 3))
            self.assertNotIn(5, fields)
            for n, w, value in protocol.iter_pb_fields(fields[3]):
                if (n, w) == (4, 2):
                    self.assertEqual(protocol.pb_get_varint(value, 2), point["xp"] * 3)
            self.assertIn(1001, [struct.unpack(">IIII", packet[:16])[2] for packet in packets[1:]])
            self.assertEqual(batch["role_state"]["stamina"], 1)
            self.assertEqual(batch["world_state"]["1200"], saved["world_state"]["1200"])
            self.assertEqual(batch.get("last_battle"), saved.get("last_battle"))
            self.save_path.write_text(json.dumps(saved))
            singles = Session(self.tables, self.save_path, self.step_counts, config)
            for seq in range(3):
                body = bytes.fromhex(self.activity_request(1307, [42102, 1, 0, 0])["hex"])
                result = singles.handle(1307, 22000 + seq, body)
                self.assertEqual(struct.unpack(">IIII", result[0][:16])[2], 1307)
            self.assertEqual(singles.save, batch)
        self.assertEqual(self.query_world(1300).hex(), batch["world_state"]["1300"])

    def test_hefei_first_challenge_with_active_random_drop_saves_before_success(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        for mid in (42102, 42103, 42104, 42105):
            for pid in self.role_config["copy"][str(mid)]:
                player.record_copy_win(saved, bytes.fromhex(self.activity_request(1306, [mid, int(pid)])["hex"]),
                                       3, self.role_config, allow_repeat=True)
        for raw in self.entity_records(bytes.fromhex(saved["world_state"]["1002"]), 1, 2).values():
            for field in (6, 8):
                raw = protocol.pb_set_varint(raw, field, 100000)
            player.record_slot_update(saved, protocol.encode_pb_field(1, 2, raw))
            player.record_protagonist_general(saved, raw)
        self.save_path.write_text(json.dumps(saved))
        with patch.object(player.random, "getrandbits", return_value=0xD09):
            packets = self.replay([self.activity_request(1306, [42106, 1])])
        self.assertEqual(packets[0]["opcode"], 1306)
        after = json.loads(self.save_path.read_text())
        self.assertEqual((after["last_battle"]["map"], after["last_battle"]["point"], after["last_battle"]["won"]), (42106, 1, True))
        self.assertEqual(after["role_state"]["stamina"], saved["role_state"]["stamina"] - 4)

    def test_sweep_clips_attempts_and_obeys_level_or_vip_unlock(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        location = bytes.fromhex(self.activity_request(1306, [42102, 1])["hex"])
        player.record_copy_win(saved, location, 3, self.role_config, allow_repeat=True)
        for level, vip, method, expected in ((12, 0, 0, 1), (29, 1, 1, None), (29, 2, 1, 3), (30, 0, 1, 3)):
            saved["role_state"].update(level=level, vip=vip, stamina=self.role_config["copy"]["42102"]["1"]["physical"] * 3 + 1)
            body = bytes.fromhex(self.activity_request(1307, [42102, 1, method, 0])["hex"])
            with self.subTest(level=level, vip=vip, method=method):
                if expected is None:
                    with self.assertRaisesRegex(ValueError, "等级或VIP"):
                        battle.sweep(saved, body, self.role_config)
                else:
                    self.assertEqual(battle.sweep(saved, body, self.role_config)[1], expected)
        copies = self.entity_records(bytes.fromhex(saved["world_state"]["1300"]), 1, 1)
        current = self.entity_records(copies[42102], 7, 1)[1]
        for _ in range(self.role_config["copy"]["42102"]["1"]["challenge"] - protocol.pb_get_varint(current, 4) - 1):
            player.record_copy_win(saved, location, 3, self.role_config, allow_repeat=True)
        self.assertEqual(battle.sweep(saved, body, self.role_config)[1], 1)

    def test_sweep_settles_recovery_before_selecting_batch_size(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        location = bytes.fromhex(self.activity_request(1306, [42102, 1])["hex"])
        player.record_copy_win(saved, location, 3, self.role_config, allow_repeat=True)
        point = self.role_config["copy"]["42102"]["1"]
        saved["role_state"].update(vip=2, stamina=point["physical"] * 3 - 1)
        saved["stamina_clock"] = {"next_at": self.now, "checked_at": self.now - 1}
        self.save_path.write_text(json.dumps(saved))
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            body = bytes.fromhex(self.activity_request(1307, [42102, 1, 1, 0])["hex"])
            packets = session.handle(1307, 23500, body)
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 1307)
        experience = next(v for n, w, v in protocol.iter_pb_fields(packets[0][16:]) if (n, w) == (3, 2))
        self.assertTrue(all(protocol.pb_get_varint(v, 2) == point["xp"] * 3 for n, w, v in protocol.iter_pb_fields(experience) if (n, w) == (4, 2)))
        self.assertEqual(session.save["role_state"]["stamina"], 0)
        self.assertEqual(session.save["stamina_clock"]["next_at"], self.now + 360)

    def test_sweep_invalid_requests_and_state_never_partially_consume(self):
        self.replay(self.requests)
        baseline = json.loads(self.save_path.read_text())
        location = bytes.fromhex(self.activity_request(1306, [42102, 1])["hex"])
        player.record_copy_win(baseline, location, 3, self.role_config, allow_repeat=True)
        baseline["role_state"].update(vip=2, stamina=100)
        bad = [[], [42102, 1, 0], [42102, 1, 0, 0, 0], [42102, 1, 2, 0], [42102, 1, 0, 1],
               [99999, 1, 0, 0], [42102, 0, 0, 0], [42103, 1, 0, 0], [42102, 1, 0, 1 << 31]]
        requests = [(str(values), bytes.fromhex(self.activity_request(1307, values)["hex"])) for values in bad]
        valid = bytes.fromhex(self.activity_request(1307, [42102, 1, 1, 0])["hex"])
        requests += [(kind, valid) for kind in ("stars", "stamina", "limit", "vip", "overflow")]
        requests.append(("wire", valid + protocol.encode_pb_field(2, 0, 1)))
        for kind, body in requests:
            saved = copy.deepcopy(baseline)
            if kind == "stars":
                copies = self.entity_records(bytes.fromhex(saved["world_state"]["1300"]), 1, 1)
                point = self.entity_records(copies[42102], 7, 1)[1]
                current = player.merge_pb_records(copies[42102], protocol.encode_pb_field(7, 2, protocol.pb_set_varint(point, 3, 2)), {7: 1})
                saved["world_state"]["1300"] = player.merge_pb_records(bytes.fromhex(saved["world_state"]["1300"]),
                                                                         protocol.encode_pb_field(1, 2, current), {1: 1}).hex()
            elif kind == "stamina":
                saved["role_state"]["stamina"] = 0
            elif kind == "limit":
                for _ in range(10):
                    player.record_copy_win(saved, location, 3, self.role_config, allow_repeat=True)
            elif kind == "vip":
                saved["role_state"]["vip"] = 0
            elif kind == "overflow":
                saved["role_state"]["coin"] = (1 << 63) - self.role_config["copy"]["42102"]["1"]["coin"] - 1
            self.save_path.write_text(json.dumps(saved))
            original = self.save_path.read_bytes()
            with self.subTest(kind=kind), redirect_stdout(io.StringIO()):
                session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
                memory = copy.deepcopy(session.save)
                packets = session.handle(1307, 23000, body)
                self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 999999)
                self.assertEqual(self.save_path.read_bytes(), original)
                self.assertEqual(session.save, memory)

    def test_sweep_failed_save_and_retry_after_state_change_are_atomic(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        player.record_copy_win(saved, bytes.fromhex(self.activity_request(1306, [42102, 1])["hex"]), 3, self.role_config, allow_repeat=True)
        saved["role_state"].update(vip=2, stamina=20)
        self.save_path.write_text(json.dumps(saved))
        original = self.save_path.read_bytes()
        body = bytes.fromhex(self.activity_request(1307, [42102, 1, 1, 0])["hex"])
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            memory = copy.deepcopy(session.save)
            with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
                session.handle(1307, 24000, body)
            self.assertEqual(self.save_path.read_bytes(), original)
            self.assertEqual(session.save, memory)
            packets = session.handle(1307, 24000, body)
            self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 1307)
            self.clock.return_value += 1
            session.handle(999904, 24001, b"")
            current = self.save_path.read_bytes()
            memory = copy.deepcopy(session.save)
            packets = session.handle(1307, 24000, body)
            self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 999999)
            self.assertEqual(self.save_path.read_bytes(), current)
            self.assertEqual(session.save, memory)

    def test_entire_configured_campaign_progress_rewards_and_boxes_survive_reconnect(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        maximum = max(map(int, self.role_config["role_exp"]))
        saved["role_state"].update(level=maximum, exp=0, stamina=100000,
                                   nextexp=self.role_config["role_exp"][str(maximum)]["nextexp"])
        # 强阵仅传给纯计算器；不写入玩家属性，更不接触真实存档。
        attack = {2: self.combat_unit(10112, atk=10**15, hp=10**15, speed=10**8)}
        count = 0
        for mid, points in sorted(self.role_config["copy"].items(), key=lambda row: int(row[0])):
            for pid, point in sorted(points.items(), key=lambda row: int(row[0])):
                body = bytes.fromhex(self.activity_request(1306, [int(mid), int(pid)])["hex"])
                row, old_star = battle.challenge(saved, body, self.role_config)
                self.assertIs(row, point)
                _, defense = battle.rosters(saved, point, self.role_config)
                report = battle.simulate(attack, defense, self.role_config, 7)
                self.assertTrue(report["result"], (mid, pid))
                self.assertEqual(report["star"], 3, (mid, pid))
                self.assert_battle_report(report)
                reward = battle.victory_role_reward(saved["role_state"], point, old_star, report["star"], self.role_config)
                self.assertEqual(reward["level"], maximum)
                saved["role_state"]["exp"] = reward["exp"]
                rewards = battle.drops(point, old_star == 0, self.role_config, 7 ^ 0xD09)
                rewards[1000] = rewards.get(1000, 0) + reward["coin"]
                player.apply_reward(saved, activities.build_reward(saved, ";".join(f"{cid},{n}" for cid, n in rewards.items()), self.role_config), self.role_config)
                saved["role_state"]["stamina"] -= point["physical"]
                player.record_copy_win(saved, body, report["star"], self.role_config, allow_repeat=True)
                count += 1
            for method in (0, 3, 6):
                copies = self.entity_records(bytes.fromhex(saved["world_state"]["1300"]), 1, 1)
                if protocol.pb_get_varint(copies[int(mid)], 4 + method // 3) == 3:
                    continue
                body = bytes.fromhex(self.activity_request(1304, [int(mid), method])["hex"])
                specification = player.record_copy_box(saved, body, self.role_config)
                player.apply_reward(saved, activities.build_reward(saved, specification, self.role_config), self.role_config)
                with self.assertRaisesRegex(ValueError, "已领取"):
                    player.record_copy_box(saved, body, self.role_config)
        self.assertEqual(count, sum(map(len, self.role_config["copy"].values())))
        self.assertEqual(count, 3061)
        with redirect_stdout(io.StringIO()):
            self.assertTrue(player.save_role(saved, self.save_path, self.step_counts))
        copies = self.entity_records(self.query_world(1300), 1, 1)
        self.assertEqual(set(copies), set(map(int, self.role_config["copy"])))
        for mid, raw in copies.items():
            self.assertEqual([protocol.pb_get_varint(raw, n) for n in (2, 4, 5, 6)], [3, 3, 3, 3])
            self.assertEqual(len(self.entity_records(raw, 7, 1)), len(self.role_config["copy"][str(mid)]))

    def test_campaign_shields_damage_corrections_and_hp_above_int32(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        point = self.role_config["copy"]["42410"]["10"]
        _, defense = battle.rosters(saved, point, self.role_config)
        self.assertGreater(max(u["hp"] for u in defense.values()), (1 << 31) - 1)
        self.assertTrue(all(u["cover_d"] > 0 and u["subdmgpct"] > 0 for u in defense.values()))
        report = battle.simulate({2: self.combat_unit(10201, atk=1000, speed=1000)},
                                 {2: self.combat_unit(10201, iid=1, atk=1, cover_d=300, cover_l=1, cover_p=50,
                                                      adddmgpct=0, subdmgpct=1)}, self.role_config, 7)
        self.assert_battle_report(report)
        hit = next(d["m"] for a in report["b"]["a"] if a["s"].get("r") for d in a["e"] if isinstance(d.get("m"), dict))
        self.assertEqual((hit["m"], hit["M"]), (250, 250))

    def test_campaign_passive_families_generate_consistent_reports(self):
        config = {**self.role_config, "general": {**self.role_config["general"]}}
        general = self.role_config["general"]["10201"]
        ids = set()
        for points in self.role_config["copy"].values():
            for point in points.values():
                for i in range(1, 8):
                    if not point[f"p{i}"]:
                        continue
                    row = self.role_config["general"][str(self.role_config["copy_monster"][str(point[f"p{i}"])]["generalid"])]
                    ids.update(row.get(f"break{j}", 0) for j in range(1, point[f"break{i}-correct"] + 1))
        for pid in sorted(ids - {0}):
            with self.subTest(passive=pid):
                config["general"]["10201"] = {**general, "break1": pid}
                report = battle.simulate({2: self.combat_unit(10201, advance=1, npc=True, atk=1000, hp=4000, speed=200)},
                                         {2: self.combat_unit(10201, iid=1, atk=1100, hp=5000)}, config, 7)
                self.assert_battle_report(report)

    def test_healing_selects_lowest_hp_ally_and_caps_at_maximum(self):
        for enemy_atk, expected in ((400, -150), (1, -3)):
            with self.subTest(enemy_atk=enemy_atk):
                report = battle.simulate({8: self.combat_unit(10305, speed=200), 2: self.combat_unit(10201, atk=1)},
                                         {2: self.combat_unit(10201, iid=1, atk=enemy_atk, speed=300)}, self.role_config, 1)
                self.assert_battle_report(report)
                action = next(a for a in report["b"]["a"] if a["s"].get("S") == 12305)
                self.assertEqual((action["e"][0]["r"], action["e"][0]["p"], action["e"][0]["m"]["m"]), (True, 2, expected))

    def test_defense_buffs_expire_and_reduce_real_damage(self):
        report = battle.simulate({8: self.combat_unit(10610, speed=200), 2: self.combat_unit(10201, speed=50, **{"def": 100})},
                                 {2: self.combat_unit(10201, iid=1, atk=200)}, self.role_config, 1)
        self.assert_battle_report(report)
        hits = [d["m"]["m"] for a in report["b"]["a"] if a["s"] and not a["s"]["r"]
                for d in a["e"] if isinstance(d.get("m"), dict)]
        self.assertEqual(hits[:4], [105, 162, 81, 105])
        switches = [d["B"]["w"] for a in report["b"]["a"] for d in a["e"] if d.get("B", {}).get("R") == "def"]
        self.assertIn(True, switches)
        self.assertIn(False, switches)

    def test_defense_debuff_and_ap_reduction_affect_following_actions(self):
        config = copy.deepcopy(self.role_config)
        config["skill"]["12311"]["effect-trigger"] = 1
        report = battle.simulate({2: self.combat_unit(10311, speed=200), 8: self.combat_unit(10201, iid=2, speed=100)},
                                 {2: self.combat_unit(10201, iid=3, speed=150, **{"def": 100})}, config, 1)
        self.assert_battle_report(report)
        second_round = next(i for i, a in enumerate(report["b"]["a"]) if a["s"].get("S") == 12311)
        skill = report["b"]["a"][second_round]
        self.assertTrue(any(d.get("ap") == 3 and not d["r"] for d in skill["e"]))
        enemy_turn = next(a for a in report["b"]["a"][second_round + 1:] if a["s"] and not a["s"]["r"])
        self.assertEqual(enemy_turn["s"]["t"], "N")
        ally = next(a for a in report["b"]["a"][second_round + 1:] if a["s"].get("r") and a["s"]["p"] == [8])
        self.assertEqual(ally["e"][0]["m"]["m"], 48)

    def test_queen_passive_heals_survivors_but_never_revives(self):
        for hp, expected in ((10000, -412), (100, None)):
            report = battle.simulate({8: self.combat_unit(10595, speed=50), 2: self.combat_unit(10201, hp=hp)},
                                     {2: self.combat_unit(10201, iid=1, atk=1000, speed=200)}, self.role_config, 1)
            self.assert_battle_report(report)
            actions = report["b"]["a"]
            self.assertEqual(actions[0]["s"]["S"], 12859)
            heals = [d["m"]["m"] for a in actions[2:3] for d in a["e"]
                     if isinstance(d.get("m"), dict) and d["p"] == 2 and d["r"] and d["m"]["m"] < 0]
            self.assertEqual(heals, [] if expected is None else [expected])

    def test_live_battle_first_drop_repeat_and_new_map_survive_reconnect(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        for pid in (2, 3, 4):
            body = bytes.fromhex(self.activity_request(1306, [42102, pid])["hex"])
            player.record_copy_win(saved, body, 3, self.role_config, allow_repeat=True)
        self.save_path.write_text(json.dumps(saved))
        config = copy.deepcopy(self.role_config)
        point = config["copy"]["42102"]["5"]
        point.update(drop1prob=0, drop2prob=0, drop3prob=0, randdropprob=0, randdropprob1=0)
        request = bytes.fromhex(self.activity_request(1306, [42102, 5])["hex"])
        original_iids = set(activities._equipment(saved))
        with redirect_stdout(io.StringIO()), patch.object(player.random, "getrandbits", return_value=1):
            session = Session(self.tables, self.save_path, self.step_counts, config)
            session.handle(1306, 21000, request)
            first = copy.deepcopy(session.save)
            self.assertTrue(first["last_battle"]["won"])
            equipment = activities._equipment(first)
            new_iids = set(equipment) - original_iids
            self.assertEqual(len(new_iids), 1)
            self.assertEqual(equipment[next(iter(new_iids))][1], point["drop"])
            session = Session(self.tables, self.save_path, self.step_counts, config)
            session.handle(1306, 21001, request)
            self.assertTrue(session.save["last_battle"]["won"])
            self.assertEqual(activities._equipment(session.save), equipment)
            copies = self.entity_records(bytes.fromhex(session.save["world_state"]["1300"]), 1, 1)
            self.assertIn(42103, copies)
            self.assertEqual(protocol.pb_get_varint(self.entity_records(copies[42102], 7, 1)[5], 4), 2)
            current = copy.deepcopy(session.save)
            player.record_copy_win(current, request, 1, config, allow_repeat=True)
            copies_after = self.entity_records(bytes.fromhex(current["world_state"]["1300"]), 1, 1)
            self.assertEqual(protocol.pb_get_varint(self.entity_records(copies_after[42102], 7, 1)[5], 3),
                             protocol.pb_get_varint(self.entity_records(copies[42102], 7, 1)[5], 3))

    def test_hades_shared_battles_unlock_progress_boxes_and_next_map(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        for mid in (42102, 42103, 42104):
            for pid in self.role_config["copy"][str(mid)]:
                player.record_copy_win(saved, bytes.fromhex(self.activity_request(1306, [mid, int(pid)])["hex"]),
                                       3, self.role_config, allow_repeat=True)
        saved["role_state"]["stamina"] = 100
        for raw in self.entity_records(bytes.fromhex(saved["world_state"]["1002"]), 1, 2).values():
            for field in (6, 8):
                raw = protocol.pb_set_varint(raw, field, 100000)
            player.record_slot_update(saved, protocol.encode_pb_field(1, 2, raw))
            player.record_protagonist_general(saved, raw)
        self.save_path.write_text(json.dumps(saved))
        before = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([self.activity_request(1306, [42105, 2])]), 1306, 20000, "未解锁")
        self.assertEqual(self.save_path.read_bytes(), before)
        for pid, point in sorted(self.role_config["copy"]["42105"].items(), key=lambda row: int(row[0])):
            with self.subTest(point=pid), patch.object(player.random, "getrandbits", return_value=7):
                replies = self.replay([self.activity_request(1306, [42105, int(pid)])])
                self.assertEqual(replies[0]["opcode"], 1306)
                fields = {n: v for n, w, v in protocol.iter_pb_fields(bytes.fromhex(replies[0]["hex"]))}
                self.assertEqual((fields[1], fields[2]), (1, 3))
                report = json.loads(fields[5])
                self.assert_battle_report(report)
                self.assertEqual(report["rules"], "zyj-v2")
                self.assertEqual(report["meta"]["defense"]["n"], point["name"])
                committed = json.loads(self.save_path.read_text())
                self.assertEqual(committed["role_state"]["stamina"], saved["role_state"]["stamina"] - point["physical"])
                self.assertEqual(self.query_world(1300).hex(), committed["world_state"]["1300"])
                saved = committed
        copies = self.entity_records(bytes.fromhex(saved["world_state"]["1300"]), 1, 1)
        self.assertIn(42106, copies)
        self.assertEqual(protocol.pb_get_varint(copies[42105], 2), 3)
        self.assertEqual(len(self.entity_records(copies[42105], 7, 1)), 6)
        for index, method in enumerate((0, 3, 6), 1):
            request = self.activity_request(1304, [42105, method])
            reply = self.replay([request])[0]
            self.assertEqual(reply["opcode"], 1304)
            raw = bytes.fromhex(reply["hex"])
            props = next(v for n, w, v in protocol.iter_pb_fields(raw) if (n, w) == (5, 2))
            actual = {cid: protocol.pb_get_varint(v, 2) for cid, v in self.entity_records(props, 1, 1).items()}
            if protocol.pb_get_varint(raw, 2):
                actual[1001] = protocol.pb_get_varint(raw, 2)
            expected = dict(tuple(map(int, item.split(","))) for item in self.role_config["map"]["42105"][f"award{index}"].split(";") if item)
            self.assertEqual(actual, expected)
            before = self.save_path.read_bytes()
            self.assert_unavailable_response(self.replay([request]), 1304, 20000, "已领取")
            self.assertEqual(self.save_path.read_bytes(), before)
        copies = self.entity_records(self.query_world(1300), 1, 1)
        self.assertEqual([protocol.pb_get_varint(copies[42105], field) for field in (4, 5, 6)], [3, 3, 3])

    def test_hades_loss_and_failed_save_keep_rewards_and_progress_atomic(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        player.record_copy_win(saved, bytes.fromhex(self.activity_request(1306, [42104, 6])["hex"]), 3, self.role_config)
        for raw in self.entity_records(bytes.fromhex(saved["world_state"]["1002"]), 1, 2).values():
            for field in (6, 7, 8, 9):
                raw = protocol.pb_set_varint(raw, field, 1)
            player.record_slot_update(saved, protocol.encode_pb_field(1, 2, raw))
            player.record_protagonist_general(saved, raw)
        self.save_path.write_text(json.dumps(saved))
        request = self.activity_request(1306, [42105, 1])
        with patch.object(player.os, "replace", side_effect=OSError("disk full")):
            self.assert_rejected(request, "保存失败")
        reply = self.replay([request])[0]
        self.assertEqual(reply["opcode"], 1306)
        fields = {n: v for n, w, v in protocol.iter_pb_fields(bytes.fromhex(reply["hex"]))}
        self.assertEqual((fields[1], fields[2]), (0, 0))
        self.assert_battle_report(json.loads(fields[5]))
        committed = json.loads(self.save_path.read_text())
        self.assertEqual(committed["world_state"], saved["world_state"])
        for key in ("coin", "gold", "level", "exp"):
            self.assertEqual(committed["role_state"][key], saved["role_state"][key])
        self.assertEqual(committed["role_state"]["stamina"], saved["role_state"]["stamina"] - 4)

    def test_live_battle_stars_include_threshold_and_order_is_stable(self):
        for incoming, stars in ((30, 3), (31, 2), (70, 2), (71, 1)):
            with self.subTest(damage=incoming):
                report = battle.simulate({2: self.combat_unit(10201, hp=100, atk=100)},
                                         {2: self.combat_unit(10201, hp=100, atk=incoming, speed=200)}, self.role_config, 0)
                self.assertEqual(report["star"], stars)
                self.assert_battle_report(report)
        report = battle.simulate({8: self.combat_unit(10201, iid=2), 2: self.combat_unit(10201, iid=1)},
                                 {2: self.combat_unit(10201, iid=3)}, self.role_config, 0)
        sources = [a["s"] for a in report["b"]["a"] if a["s"]]
        self.assertEqual([(s["r"], s["p"]) for s in sources[:3]], [(True, [2]), (False, [2]), (True, [8])])

    def test_live_battle_rejects_locked_limit_unsupported_and_overflow_atomically(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        body = bytes.fromhex(self.activity_request(1306, [42102, 2])["hex"])
        for kind in ("locked", "stamina", "limit", "roster", "overflow"):
            modified = copy.deepcopy(saved)
            request = body
            if kind == "locked":
                request = bytes.fromhex(self.activity_request(1306, [42103, 1])["hex"])
            elif kind == "stamina":
                modified["role_state"]["stamina"] = 0
            elif kind == "limit":
                for _ in range(10):
                    player.record_copy_win(modified, body, 3, self.role_config, allow_repeat=True)
            elif kind == "roster":
                raw = self.entity_records(bytes.fromhex(modified["world_state"]["1002"]), 1, 2)[7060]
                player.record_slot_update(modified, protocol.encode_pb_field(1, 2, protocol.pb_set_varint(raw, 21, 1)))
            else:
                modified["role_state"]["coin"] = (1 << 63) - 1
            self.save_path.write_text(json.dumps(modified))
            original = self.save_path.read_bytes()
            with self.subTest(kind=kind), redirect_stdout(io.StringIO()), patch.object(player.random, "getrandbits", return_value=42):
                session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
                memory = copy.deepcopy(session.save)
                packets = session.handle(1306, 21000, request)
                self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 999999)
                self.assertEqual(self.save_path.read_bytes(), original)
                self.assertEqual(session.save, memory)

    def test_live_battle_supports_advanced_protagonist_breakthrough_skills(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        # 将主角突破提升至 +23（包含 9100003 '愤怒'、9100004 '魔王战歌' 等高阶突破）
        raw_lead = self.entity_records(bytes.fromhex(saved["world_state"]["1002"]), 1, 2)[7059]
        advanced_lead = protocol.pb_set_varint(raw_lead, 4, 23)
        player.record_slot_update(saved, protocol.encode_pb_field(1, 2, advanced_lead))
        self.save_path.write_text(json.dumps(saved))

        session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
        body = bytes.fromhex(self.activity_request(1306, [42102, 2])["hex"])
        packets = session.handle(1306, 22000, body)
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 1306)
        self.assertEqual(session.save["world_state"]["1300"], self.save_path.read_text().split('"1300": "')[1].split('"')[0])

    def test_unknown_advanced_passive_still_rejects_without_battle_cost_or_saved_changes(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        raw = self.entity_records(bytes.fromhex(saved["world_state"]["1002"]), 1, 2)[7059]
        player.record_slot_update(saved, protocol.encode_pb_field(1, 2, protocol.pb_set_varint(raw, 4, 23)))
        self.save_path.write_text(json.dumps(saved))
        session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
        memory, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
        row = {**self.role_config["breakskill"]["9100003"], "id": 9999991, "type": 1}
        with patch.dict(self.role_config["general"][str(protocol.pb_get_varint(raw, 1))], break23=9999991), patch.dict(self.role_config["breakskill"], {"9999991": row}):
            packets = session.handle(1306, 22001, recharge.ids([42102, 2]))
        self.assertEqual([struct.unpack(">IIII", packet[:16])[2] for packet in packets], [999999, 1999])
        self.assertEqual((session.save, self.save_path.read_bytes()), (memory, disk))

    def test_activity_tabs_match_official_fields_without_account_history(self):
        self.replay(self.requests)
        capture = json.loads((Path(server.BASE_DIR) / "official_battle_capture_20261028_2014.json").read_text())
        frames = capture["connections"][0]["frames"]
        for opcode in (5010, 4810, 4814, 5020, 5030, 5039):
            with self.subTest(opcode=opcode):
                request = next(f for f in frames if f["c2s"] and f["opcode"] == opcode)
                reply = next(f for f in frames if not f["c2s"] and f["opcode"] == opcode and f["seq"] == request["seq"])
                self.clock.return_value = int(request["timestamp"])
                actual = protocol.parse_ids_pb(bytes.fromhex(self.replay([request])[0]["hex"]))
                expected = protocol.parse_ids_pb(bytes.fromhex(reply["hex"]))
                if opcode == 4810:
                    self.assertEqual(actual, [expected[0], 0])
                elif opcode == 5039:
                    self.assertEqual(actual[:2], expected[:2])
                    self.assertLessEqual(abs(actual[2] - expected[2]), 1)
                    self.assertEqual(actual[3:], [0] * (1 + len(self.role_config["consumegift_reward_1"])))
                else:
                    self.assertEqual(actual, expected)

    def test_activity_subpages_and_queries_reject_extra_fields(self):
        self.seed_activity_account()
        for opcode in activities.PAGE_OPCODES:
            with self.subTest(opcode=opcode):
                reply = self.replay([self.activity_request(opcode)])[0]
                self.assertEqual(reply["opcode"], opcode)
                if opcode == 4016:
                    before = self.save_path.read_bytes()
                    self.assertEqual([f["opcode"] for f in self.replay([self.activity_request(opcode, [1])])], [999999, 1999])
                    self.assertEqual(self.save_path.read_bytes(), before)
                else:
                    self.assert_rejected(self.activity_request(opcode, [1]), "活动请求格式错误")
        shop = protocol.parse_ids_pb(bytes.fromhex(self.replay([self.activity_request(5015)])[0]["hex"]))
        self.assertEqual(len(shop), 3 + max(map(int, self.role_config["goddown_exchange_1"])))
        rank = self.replay([self.activity_request(5017)])[0]
        self.assertEqual(self.begin7day_groups(bytes.fromhex(rank["hex"])), {0: [1, 1, 0], 1: []})

    def test_discount_purchase_and_consume_claim_persist_and_do_not_double_charge(self):
        self.seed_activity_account()
        before_props = self.entity_records(self.query_world(1200), 1, 1)
        replies = self.replay([self.activity_request(5031, [1, 1])])
        self.assertEqual(replies[0]["opcode"], 5031)
        reward = bytes.fromhex(replies[0]["hex"])
        self.assertIsNone(protocol.pb_get_varint(reward, 2))
        self.assertEqual(self.query_role()[9], 5000 - 1566)
        after_props = self.entity_records(self.query_world(1200), 1, 1)
        for cid in (20619, 20197):
            self.assertEqual(protocol.pb_get_varint(after_props[cid], 2),
                             (protocol.pb_get_varint(before_props.get(cid, b""), 2) or 0) + 10)
        query = self.replay([self.activity_request(5030), self.activity_request(5039)])
        self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(query[0]["hex"]))[2:4], [1, 0])
        self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(query[1]["hex"]))[3:6], [1566, 1, 0])
        coin = self.query_role()[8]
        self.assertEqual(self.replay([self.activity_request(5040, [1])])[0]["opcode"], 5040)
        self.assertEqual(self.query_role()[8], coin + 100000)
        saved = json.loads(self.save_path.read_text())
        self.assertEqual(saved["activity_state"]["consume_claimed"], [1])
        before = self.save_path.read_bytes()
        for opcode, ids, reason in ((5031, [1, 1], "限购"), (5040, [1], "已领取"), (5040, [2], "未达成")):
            responses = self.replay([self.activity_request(opcode, ids), self.activity_request(5039)])
            self.assert_unavailable_response(responses[:2], opcode, 20000, reason)
            self.assertEqual(responses[2]["opcode"], 5039)
            self.assertEqual(self.save_path.read_bytes(), before)

    def test_discount_fragments_use_inventory_and_enforce_quantity(self):
        self.seed_activity_account()
        self.replay([self.activity_request(5031, [10, 2])])
        fragments = self.entity_records(self.query_world(1012), 1, 1)
        self.assertEqual(protocol.pb_get_varint(fragments[10505], 2), 10)
        self.assertEqual(self.query_role()[9], 5000 - 288 * 2)
        before = self.save_path.read_bytes()
        for ids in ([10, 3], [10, 0], [14, 1], [1], [1, 1, 1]):
            replies = self.replay([self.activity_request(5031, ids)])
            self.assertEqual(replies[0]["opcode"], 999999)
            self.assertEqual(self.save_path.read_bytes(), before)

    def test_activity_transactions_rollback_insufficient_gold_and_reward_overflow(self):
        saved = self.seed_activity_account(gold=0)
        for gold, overflow in ((0, False), (5000, True)):
            saved["role_state"]["gold"] = gold
            if overflow:
                player.change_item_count(saved, 20619, (1 << 31) - 1, self.role_config)
            self.save_path.write_text(json.dumps(saved))
            self.query_role()
            before = self.save_path.read_bytes()
            replies = self.replay([self.activity_request(5031, [1, 1]), self.activity_request(5039)])
            self.assert_unavailable_response(replies[:2], 5031, 20000, "超出范围" if overflow else "不足")
            self.assertEqual(self.save_path.read_bytes(), before)

    def test_activity_first_period_boundary_uses_server_day_and_expires(self):
        saved = self.seed_activity_account()
        opened = protocol.pb_get_varint(bytes.fromhex(saved["role_snapshot"]), 22)
        end_at = ((opened + 28800) // 86400 + 7) * 86400 - 28800
        self.assertEqual(activities.first_period(saved, self.role_config, 85, end_at - 1), (7, 1))
        self.assertEqual(activities.first_period(saved, self.role_config, 85, end_at), (8, 0))
        self.clock.return_value = end_at
        before = self.save_path.read_bytes()
        replies = self.replay([self.activity_request(5031, [1, 1])])
        self.assert_unavailable_response(replies, 5031, 20000, "已结束")
        self.assertEqual(self.save_path.read_bytes(), before)

    def test_activity_purchase_saves_whole_transaction_before_reply(self):
        self.seed_activity_account()
        before = self.save_path.read_bytes()
        conn = ReplayConnection([self.activity_request(5031, [1, 1])], 7)
        with patch.object(player.os, "replace", side_effect=OSError("disk failure")), redirect_stdout(io.StringIO()):
            self.run_client(conn)
        self.assertEqual(conn.responses, [])
        self.assertEqual(self.save_path.read_bytes(), before)
        self.replay([self.activity_request(5031, [1, 1])])
        saved = json.loads(self.save_path.read_text())
        self.assertEqual(saved["role_state"]["gold"], 3434)
        self.assertEqual(saved["activity_state"]["gold_spent"], 1566)
        self.assertEqual(saved["activity_state"]["discount_bought"], {"1": 1})

    def test_unimplemented_activity_operations_return_native_error_without_changes(self):
        self.seed_activity_account()
        before = self.save_path.read_bytes()
        for opcode in activities.UNSUPPORTED_OPCODES:
            for values in ([], [1]):
                replies = self.replay([self.activity_request(opcode, values)])
                self.assert_unavailable_response(replies, opcode, 20000, "未扣除")
                self.assertEqual(self.save_path.read_bytes(), before)

    def test_anniversary_query_rejects_nonempty_payload(self):
        self.replay(self.requests)
        for body in ("0801", "08", "0a00", "1000"):
            with self.subTest(body=body):
                self.assert_rejected({"opcode": 4600, "seq": 20000, "hex": body}, "活动请求格式错误")

    def test_unimplemented_anniversary_exchange_is_nonmutating_and_connection_stays_usable(self):
        self.replay(self.requests)
        before = self.save_path.read_bytes()
        for ids in ((1,), (1, 1), (13, 2), (15, 1), (15, 999), (0,), (16,), ()):
            with self.subTest(ids=ids):
                responses = self.replay([self.activity_request(4601, ids),
                                         dict(self.activity_request(4600), seq=20001)], chunk_size=7)
                self.assert_unavailable_response(responses[:2], 4601, 20000, "兑换")
                self.assertEqual((responses[2]["opcode"], responses[2]["seq"]), (4600, 20001))
                self.assertEqual(len(protocol.parse_ids_pb(bytes.fromhex(responses[2]["hex"]))), 30)
                self.assertEqual(self.save_path.read_bytes(), before)

    def test_activity_equipment_does_not_collide_with_later_recorded_drops(self):
        self.replay_through(107)
        reward = self.replay([self.activity_request(3611, (80030,))])[0]
        equipment = next(v for n, w, v in protocol.iter_pb_fields(bytes.fromhex(reward["hex"])) if n == 6)
        iid = protocol.parse_ids_pb(equipment)[0]
        self.replay([f for f in self.requests if f["seq"] > 107])
        self.assertEqual(self.entity_records(self.query_world(1002), 2, 1)[iid], equipment)

    def test_activity_inventory_overflow_cannot_partially_grant_reward(self):
        self.replay_through(12)
        saved = json.loads(self.save_path.read_text())
        player.change_item_count(saved, 20014, (1 << 31) - 1, self.role_config)
        self.save_path.write_text(json.dumps(saved))
        before = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([self.activity_request(3611, [80001])]), 3611, 20000, "超出范围")
        self.assertEqual(self.save_path.read_bytes(), before)

    def test_invalid_activity_state_is_not_overwritten(self):
        self.replay_through(12)
        original = json.loads(self.save_path.read_text())
        for key, value in (("strengthen_count", -1), ("strengthen_count", True),
                           ("begin7day_rmb", -1), ("begin7day_rmb", True), ("begin7day_rmb", 1 << 31),
                           ("begin7day_claimed", "bad"), ("liveness_claimed", [16, 16])):
            with self.subTest(key=key, value=value):
                saved = json.loads(json.dumps(original))
                saved["activity_state"][key] = value
                self.save_path.write_text(json.dumps(saved))
                self.assert_rejected(self.activity_request(3610), "载入玩家状态失败")

    def test_activity_claim_before_role_creation_is_rejected(self):
        self.save_path.write_text(json.dumps(player.get_default_save()))
        before = self.save_path.read_bytes()
        for opcode, values in ((3611, [80001]), (2411, []), (2411, [116])):
            self.assert_unavailable_response(self.replay([self.activity_request(opcode, values)]), opcode, 20000, "未解锁")
            self.assertEqual(self.save_path.read_bytes(), before)

    def test_malformed_activity_claim_does_not_mutate_save(self):
        self.replay(self.requests)
        for opcode in (3611, 2411):
            for body in ("", "0800", "08", "08010801", "0a0101"):
                with self.subTest(opcode=opcode, body=body):
                    if opcode == 2411 and not body:
                        continue
                    request = {"opcode": opcode, "seq": 20000, "hex": body}
                    before = self.save_path.read_bytes()
                    self.assert_unavailable_response(self.replay([request]), opcode, 20000, "活动请求格式错误")
                    self.assertEqual(self.save_path.read_bytes(), before)

    def test_all_19_combination_guide_steps_are_persisted(self):
        requests = [f for f in self.requests if f["opcode"] == 999900 and 201 in protocol.get_comb_ids(bytes.fromhex(f["hex"]))]
        self.assertEqual(len(requests), 19)
        self.replay(requests)
        self.assertTrue(self.save_path.exists())
        saved = json.loads(self.save_path.read_text())
        expected = [4, 8, 13, 19, 22, 30, 36, 39, 44, 45, 48, 51, 56, 60, 66, 71, 78, 79, 80]
        self.assertEqual(saved["guide"]["sections"]["1"], {"status": 1, "step": 80, "steps": expected})

    def test_failed_combination_guide_ack_does_not_advance_progress(self):
        reply = self.recorded[(36, 999900)]
        self.assertTrue(reply["hex"].endswith("0801"))
        frames = [self.by_seq[12], self.recorded[(12, 999900)], self.by_seq[36], dict(reply, hex=reply["hex"][:-2] + "00")]
        with redirect_stdout(io.StringIO()):
            self.tables = replay.build_routing_tables(frames)
        self.replay([self.by_seq[36]])
        self.assertEqual(json.loads(self.save_path.read_text())["guide"]["sections"], {})

    def test_malformed_guide_report_does_not_overwrite_save(self):
        save = player.get_default_save()
        save["guide"]["sections"] = {"1": {"status": 1, "step": 5, "steps": [5]}}
        original = json.dumps(save)
        self.save_path.write_text(original)
        for body in ("", "0801", "08011080", "08011000", "080110" + "ff" * 10):
            with self.subTest(body=body):
                conn = ReplayConnection([{"opcode": 201, "seq": 10000, "hex": body}], 7)
                with redirect_stdout(io.StringIO()):
                    self.run_client(conn)
                self.assertTrue(conn.closed)
                self.assertEqual(conn.responses, [])
                self.assertEqual(self.save_path.read_text(), original)

    def test_combination_parser_validates_lengths_and_required_ids(self):
        messages = protocol.get_comb_messages(bytes.fromhex(self.by_seq[11]["hex"]))
        self.assertEqual(messages, [(202, b"\x08\x03"), (201, b"\x08\x01\x10\x04")])
        for raw in (b"\x0a\x05\x08\xca", b"\x0a\x02\x12\x00", b"\x0a\x04\x08\xca\x01\x12", b"\x00", b"\x0e", b"\x80" * 11):
            with self.subTest(raw=raw):
                with self.assertRaises(ValueError):
                    protocol.get_comb_messages(raw)

    def test_parser_accepts_optional_data_unknown_fields_and_uint64(self):
        self.assertEqual(protocol.get_comb_messages(b"\x0a\x05\x08\xca\x01\x18\x01\x10\x01"), [(202, b"")])
        maximum = (1 << 64) - 1
        encoded = protocol.encode_varint(maximum)
        self.assertEqual(protocol.parse_varint(encoded, 0), (maximum, len(encoded)))

    def test_recorded_tutorial_responses_survive_combination_sequence_changes(self):
        # The second login is a reconnect; keep the isolated save but reset connection counters.
        sessions = []
        for frame in self.requests:
            if frame["opcode"] == 1000:
                sessions.append([])
            sessions[-1].append(frame)
        for shift in (0, 10000):
            self.save_path.unlink(missing_ok=True)
            push_count = 0
            hint_changes = []
            for session in sessions:
                requests = [dict(f, seq=f["seq"] + shift) if f["opcode"] == 999900 else f for f in session]
                responses = self.replay(requests, chunk_size=31)
                hint_changes.extend(self.hint_changes(f) for f in responses if f["opcode"] == 1034)
                responses = [f for f in responses if f["opcode"] != 1034]
                expected = []
                for original, request in zip(session, requests):
                    expected.extend(self.expected_group(original["seq"], request["seq"]))
                self.assertEqual([(f["opcode"], f["seq"]) for f in responses], [(f["opcode"], f["seq"]) for f in expected])
                for actual, recorded in zip(responses, expected):
                    with self.subTest(shift=shift, seq=actual["seq"], opcode=actual["opcode"]):
                        self.assert_replayed_payload(actual["opcode"], actual["hex"], recorded["hex"])
                replies = [f for f in responses if f["seq"] != 0]
                push_count += len(responses) - len(replies)
                self.assertEqual(len(replies), len(requests))
                for original, request, response in zip(session, requests, replies):
                    with self.subTest(shift=shift, seq=original["seq"], opcode=original["opcode"]):
                        self.assertEqual(response["opcode"], request["opcode"])
                        self.assertEqual(response["seq"], request["seq"])
            self.assertEqual(push_count, 33)
            self.assertEqual(hint_changes, [{44: 1}, {40: 1}, {84: 1}])


class ApkToolTests(unittest.TestCase):
    def test_build_tools_use_platform_names_on_path_and_in_sdk(self):
        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            for platform, names in (("posix", ("zipalign", "apksigner")), ("nt", ("zipalign.exe", "apksigner.bat"))):
                for tool, filename in zip(("zipalign", "apksigner"), names):
                    target = base / filename
                    target.touch()
                    target.chmod(0o755)
                    with patch.dict(os.environ, {"PATH": directory}), patch.object(os, "name", platform):
                        self.assertEqual(apk_builder.find_tool(tool), str(target))
            target = base / "build-tools" / "34.0.0" / "apksigner"
            target.parent.mkdir(parents=True)
            target.touch()
            with patch.dict(os.environ, {"PATH": "", "ANDROID_HOME": directory}), patch.object(os, "name", "posix"):
                self.assertEqual(apk_builder.find_tool("apksigner"), str(target))


class LanAccountTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with redirect_stdout(io.StringIO()):
            cls.step_counts = guide.load_guide_step_counts(server.CONFIG_ZIP)
            cls.role_config = player.load_role_config(server.CONFIG_ZIP)
            frames = replay.load_recordings(server.RECORD_PATH)
            cls.tables = replay.build_routing_tables(frames)
            # 两个教程隔离用例只用原始抓包；ReplayRoutingTests 仍验证完整混合库。
            end = next((i for i, f in enumerate(frames) if i and f["c2s"] and f["opcode"] == 1000 and f["seq"] == 1), len(frames))
            cls.tutorial_tables = replay.build_routing_tables(frames[:end])
        cls.requests = [f for f in frames[:end] if f["c2s"]]
        cls.by_seq = {f["seq"]: f for f in cls.requests}

    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.save_path = Path(temp.name) / "role_save.json"
        self.store = accounts.AccountStore(self.save_path, self.tables, self.step_counts, self.role_config)
        self.diagnostic = diagnostics.DiagnosticLog(Path(temp.name) / "logs" / "diagnostics.log")
        self.addCleanup(self.diagnostic.close)
        for context in (patch.object(accounts, "PASSWORD_ITERATIONS", 1),
                        patch.object(server, "SAVE_PATH", str(self.save_path)),
                        patch.object(server, "start_admin"),
                        patch.object(player.time, "time", return_value=1800000000),
                        redirect_stdout(io.StringIO())):
            context.__enter__()
            self.addCleanup(context.__exit__, None, None, None)
        for account in (1, 2):
            self.store.register(account, LOGIN_PASSWORD, self.store.snapshot(account)["revision"])

    def run_client(self, conn, addr=("same-lan-ip", 1)):
        self.store.tables = self.tables
        server.handle_client(conn, addr, self.store, self.diagnostic)

    def replay(self, requests, chunk_size=4096, account=1):
        conn = ReplayConnection(requests, chunk_size, account=account)
        with redirect_stdout(io.StringIO()) as log:
            self.run_client(conn)
        self.assertTrue(conn.closed)
        self.assertNotIn("连接异常", log.getvalue())
        return conn.responses

    def test_two_accounts_keep_names_guides_and_world_state_after_reconnect(self):
        self.tables = self.tutorial_tables
        name = lambda text: {"opcode": 101, "seq": 20000, "hex": protocol.encode_pb_field(1, 2, text.encode("utf-8")).hex()}
        self.replay([name("手机账号"), self.by_seq[11], self.by_seq[12], self.by_seq[36]], account=1)
        first = self.save_path.read_bytes()
        self.replay([name("模拟器账号"), {"opcode": 201, "seq": 20001, "hex": "08011003"}], account=2)
        second_path = self.store.path(2)
        self.assertEqual(self.save_path.read_bytes(), first)
        self.assertEqual(json.loads(second_path.read_text())["role_name"], "模拟器账号")
        for account, expected_name, expected_step in ((1, "手机账号", 8), (2, "模拟器账号", 3)):
            responses = self.replay([self.by_seq[12], {"opcode": 200, "seq": 30000, "hex": ""}], account=account)
            role = dict(protocol.get_comb_messages(bytes.fromhex(responses[0]["hex"])))[1001]
            self.assertIn((3, 2, expected_name.encode("utf-8")), list(protocol.iter_pb_fields(role)))
            sections = [value for _, _, value in protocol.iter_pb_fields(bytes.fromhex(responses[1]["hex"]))]
            self.assertEqual(protocol.pb_get_varint(sections[0], 3), expected_step)
        self.assertEqual(json.loads(self.save_path.read_text())["level"], 2)
        self.assertEqual(json.loads(second_path.read_text())["level"], 1)

    def test_recorded_tutorial_can_run_independently_for_two_accounts(self):
        self.tables = self.tutorial_tables
        self.replay(self.requests, account=1)
        first = self.save_path.read_bytes()
        self.replay(self.requests, chunk_size=7, account=2)
        self.assertEqual(self.save_path.read_bytes(), first)
        a = json.loads(first)
        b = json.loads(self.store.path(2).read_text())
        for key in ("role_state", "world_state", "guide", "protagonist_snapshot", "activity_state", "stamina_clock"):
            self.assertEqual(a[key], b[key])

    def test_login_parser_accepts_reconnect_flag_but_rejects_invalid_identity(self):
        body = bytes.fromhex(login_request(2)["hex"]) + protocol.encode_pb_field(1, 2, b"\x08\x03")
        self.assertEqual(accounts.parse_login_credentials(body), (2, LOGIN_PASSWORD))
        for account in ("0", "-1", "01", "1001", "../1", "1/../../2", "1\x00"):
            with self.subTest(account=account), self.assertRaises(ValueError):
                accounts.parse_login_credentials(bytes.fromhex(login_request(account)["hex"]))
        for body in (b"", b"\x08\x01", b"\x0a\x04\x12\x05x", b"\x0a\x02\x08\x01"):
            with self.subTest(body=body), self.assertRaises(ValueError):
                accounts.parse_login_credentials(body)

    def test_login_rejects_missing_duplicate_and_malformed_credentials(self):
        valid = bytes.fromhex(login_request(1)["hex"])
        identity, password = [raw for _, _, raw in protocol.iter_pb_fields(valid)]
        wrap = lambda raw: protocol.encode_pb_field(1, 2, raw)
        invalid = [wrap(identity), wrap(password) + wrap(identity), valid + wrap(password),
                   wrap(identity + identity) + wrap(password), wrap(identity) + wrap(password + password),
                   valid + b"\x10\x01", valid + wrap(b"\x08\x01\x08\x02"),
                   wrap(identity) + wrap(b"\x12\x01\xff"), b"x" * 1025]
        for body in invalid:
            with self.subTest(body=body), self.assertRaisesRegex(ValueError, "登录参数无效"):
                accounts.parse_login_credentials(body)

    def test_login_authentication_precedes_save_loading_and_never_logs_password(self):
        self.save_path.write_text('{"role_name":"keep"}')
        before = self.save_path.read_bytes()
        for request in (login_request(1, 1, None), login_request(1, 1, "wrong-password"), login_request(3, 1)):
            conn = ReplayConnection([request, {"opcode": 101, "seq": 2, "hex": "0a03626164"}], 7, login=False)
            with patch.object(accounts, "Session") as load, redirect_stdout(io.StringIO()) as log:
                self.run_client(conn)
            load.assert_not_called()
            self.assertTrue(conn.closed)
            self.assertEqual([(f["opcode"], f["seq"]) for f in conn.responses], [(999999, 1)])
            self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(conn.responses[0]["hex"])), [1000, 0])
            self.assertNotIn("wrong-password", log.getvalue())
            self.assertNotIn(LOGIN_PASSWORD, log.getvalue())
            self.assertNotIn(request["hex"], log.getvalue())
            self.assertEqual(self.store.active, {})
            self.assertEqual(self.save_path.read_bytes(), before)
        text = Path(self.diagnostic.baseFilename).read_text()
        self.assertNotIn(LOGIN_PASSWORD, text)
        self.assertNotIn("wrong-password", text)
        self.assertNotIn("wrong-password".encode().hex(), text)
        entries = [json.loads(line) for line in text.splitlines()]
        self.assertEqual(len(entries), 3)
        for entry in entries:
            self.assertEqual((entry["event"], entry["phase"]), ("exception", "login"))
            self.assertTrue(entry["request"]["redacted"])
            self.assertNotIn("hex", entry["request"])
            self.assertEqual(entry["responses"][0]["ids"], [1000, 0])

    def test_diagnostic_records_activity_rejections_without_changing_save(self):
        self.replay([{"opcode": 201, "seq": 1, "hex": "08011003"}])
        before = self.save_path.read_bytes()
        requests = [{"opcode": op, "seq": i + 20, "hex": ""}
                    for i, op in enumerate((8077, 3680, 3682, 5034, 5000))]
        requests.append({"opcode": 4601, "seq": 25, "hex": "080f0801"})
        responses = self.replay(requests, chunk_size=7)
        entries = [json.loads(line) for line in Path(self.diagnostic.baseFilename).read_text().splitlines()]
        self.assertEqual(len(entries), len(requests))
        self.assertEqual(len(responses), len(requests) * 2)
        for request, entry in zip(requests, entries):
            self.assertEqual((entry["event"], entry["level"]), ("error_response", "WARNING"))
            self.assertEqual((entry["account"], entry["peer"]), (1, ["same-lan-ip", 1]))
            for key in ("opcode", "seq", "hex"):
                self.assertEqual(entry["request"][key], request[key])
            self.assertIn("尚未实现" if request["opcode"] == 4601 else "角色尚未创建", entry["reason"])
            self.assertEqual(entry["responses"][0]["ids"], [request["opcode"], 0])
        self.assertEqual(entries[-1]["request"]["ids"], [15, 1])
        self.assertEqual(self.save_path.read_bytes(), before)

    def test_diagnostic_distinguishes_empty_replies_no_reply_and_heartbeat(self):
        self.replay([{"opcode": op, "seq": i + 1, "hex": ""}
                     for i, op in enumerate((200, 4813, 999904, 999905))])
        comb = protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 4814)
                                         + protocol.encode_pb_field(2, 2, b""))
        request = {"opcode": 999900, "seq": 5, "hex": comb.hex()}
        with patch.object(Session, "handle", return_value=[protocol.pack_frame(999900, 5, comb)]):
            self.replay([request])
        with patch.object(Session, "handle", return_value=[]):
            self.replay([dict(request, seq=6)])
        entries = [json.loads(line) for line in Path(self.diagnostic.baseFilename).read_text().splitlines()]
        self.assertEqual([e["request"]["seq"] for e in entries], [1, 2, 5, 6])
        self.assertEqual([(e["event"], e["level"]) for e in entries],
                         [("empty_response", "INFO")] * 3 + [("no_response", "WARNING")])
        self.assertEqual(entries[2]["empty"], [{"opcode": 4814, "seq": 5, "length": 0, "parent_opcode": 999900}])
        self.assertEqual(entries[2]["request"]["messages"][0]["opcode"], 4814)

    def test_diagnostic_records_parse_save_and_send_failures(self):
        self.replay([{"opcode": 201, "seq": 1, "hex": "08011003"}])
        before = self.save_path.read_bytes()
        malformed = ReplayConnection([{"opcode": 201, "seq": 2, "hex": "ff"}], 7)
        self.run_client(malformed)
        failed_save = ReplayConnection([{"opcode": 201, "seq": 3, "hex": "08011004"}], 7)
        with patch.object(player, "save_role", return_value=False):
            self.run_client(failed_save)
        failed_send = ReplayConnection([{"opcode": 200, "seq": 4, "hex": ""}], 7)
        sendall = failed_send.sendall
        def send(packet):
            if struct.unpack(">IIII", packet[:16])[2] == 200:
                raise OSError("test send failed")
            sendall(packet)
        with patch.object(failed_send, "sendall", side_effect=send):
            self.run_client(failed_send)
        entries = [json.loads(line) for line in Path(self.diagnostic.baseFilename).read_text().splitlines()]
        self.assertEqual([e["phase"] for e in entries], ["handle", "handle", "send"])
        self.assertEqual([e["request"]["seq"] for e in entries], [2, 3, 4])
        self.assertIn("引导进度保存失败", entries[1]["reason"])
        self.assertIn("test send failed", entries[2]["traceback"])
        for conn in (malformed, failed_save, failed_send):
            self.assertTrue(conn.closed)
            self.assertEqual(conn.responses, [])
        self.assertEqual(self.store.active, {})
        self.assertEqual(self.save_path.read_bytes(), before)

    def test_diagnostic_redacts_relogin_and_embedded_credentials(self):
        secret = "diagnostic-secret"
        conn = ReplayConnection([login_request(1, 1), login_request(1, 2, secret)], 7, login=False)
        self.run_client(conn)
        payload = bytes.fromhex(login_request(1, 3, secret)["hex"])
        login = protocol.encode_pb_field(1, 0, 1000) + protocol.encode_pb_field(2, 2, payload)
        for raw in (login, login + protocol.encode_pb_field(1, 0, 101), b"\xff" + payload):
            comb = protocol.encode_pb_field(1, 2, raw)
            self.diagnostic.record(1, ("test", 1), 999900, 3, comb)
        self.diagnostic.record(None, ("test", 1), 101, 4, payload)
        text = Path(self.diagnostic.baseFilename).read_text()
        self.assertNotIn(secret, text)
        self.assertNotIn(secret.encode().hex(), text)
        for line in text.splitlines():
            request = json.loads(line)["request"]
            self.assertTrue(request["redacted"])
            self.assertNotIn("hex", request)

    def test_diagnostic_rotation_failure_does_not_interrupt_replies_or_saves(self):
        request = {"opcode": 5000, "seq": 1, "hex": ""}
        following = {"opcode": 201, "seq": 2, "hex": "08011003"}
        self.diagnostic.maxBytes = 1
        with patch.object(self.diagnostic, "doRollover", side_effect=OSError("disk full")), \
                redirect_stderr(io.StringIO()) as warning:
            replies = self.replay([request, dict(request, seq=3), following])
        self.assertEqual(warning.getvalue().count("诊断日志写入失败"), 1)
        self.assertEqual([r["opcode"] for r in replies], [999999, 1999, 999999, 1999, 201])
        self.assertEqual(json.loads(self.save_path.read_text())["guide"]["sections"]["1"]["step"], 3)
        self.replay([request])
        self.assertEqual(json.loads(Path(self.diagnostic.baseFilename).read_text())["request"]["opcode"], 5000)

    def test_diagnostic_bounds_large_payloads(self):
        body = b"\x08\x01" * (diagnostics.PAYLOAD_LIMIT + 1)
        self.diagnostic.record(1, ("test", 1), 999123, 1, body)
        entry = json.loads(Path(self.diagnostic.baseFilename).read_text())
        self.assertEqual(entry["request"]["length"], len(body))
        self.assertTrue(entry["request"]["truncated"])
        self.assertEqual(len(entry["request"]["hex"]), diagnostics.PAYLOAD_LIMIT * 2)

    def test_diagnostic_keeps_malformed_error_replies_for_debugging(self):
        for opcode in (1999, 999900):
            self.diagnostic.record(1, ("test", 1), 5000, 1, b"", [protocol.pack_frame(opcode, 1, b"\xff")])
        entries = [json.loads(line) for line in Path(self.diagnostic.baseFilename).read_text().splitlines()]
        self.assertEqual(len(entries), 2)
        for entry in entries:
            self.assertEqual(entry["event"], "invalid_response")
            self.assertTrue(entry["parse_errors"])

    def test_repeated_login_still_requires_the_password(self):
        conn = ReplayConnection([login_request(1, 1), login_request(1, 2, "wrong-password")], 7, login=False)
        self.run_client(conn)
        self.assertEqual([(f["opcode"], f["seq"]) for f in conn.responses], [(1000, 1), (999999, 2)])
        self.assertEqual(self.store.active, {})
        self.assertFalse(self.save_path.exists())

    def test_unauthenticated_requests_cannot_read_or_modify_saves(self):
        self.save_path.write_text('{"role_name":"keep"}')
        before = self.save_path.read_bytes()
        for opcode in (1001, 200, 101, 201, 999898, 999900):
            with self.subTest(opcode=opcode):
                conn = ReplayConnection([{"opcode": opcode, "seq": 1, "hex": ""}], 7, login=False)
                with patch.object(server, "print_flush"):
                    self.run_client(conn)
                self.assertTrue(conn.closed)
                self.assertEqual(conn.responses, [])
                self.assertEqual(self.save_path.read_bytes(), before)

    def test_connection_cannot_switch_accounts_after_login(self):
        conn = ReplayConnection([login_request(1, 1), login_request(2, 2)], 7, login=False)
        with patch.object(server, "print_flush"):
            self.run_client(conn)
        self.assertEqual([(f["opcode"], f["seq"]) for f in conn.responses], [(1000, 1), (999999, 2)])
        self.assertFalse(self.store.path(2).exists())
        self.assertEqual(self.store.active, {})

    def test_oversized_frame_is_rejected_without_touching_save(self):
        conn = ReplayConnection([], 4096, login=False)
        conn.chunks = iter([struct.pack(">IIII", 0xEE1C, server.MAX_FRAME_SIZE + 1, 1000, 1)])
        with patch.object(server, "print_flush"):
            self.run_client(conn)
        self.assertEqual(conn.responses, [])
        self.assertTrue(conn.closed)
        self.assertFalse(self.save_path.exists())

    def test_duplicate_account_rejected_while_other_account_can_play(self):
        waiting, release = threading.Event(), threading.Event()

        class HoldingConnection(ReplayConnection):
            def recv(self, size):
                data = super().recv(size)
                if not data:
                    waiting.set()
                    if not release.wait(5):
                        raise TimeoutError("test did not release connection")
                return data

        conn = HoldingConnection([login_request(1, 1)], 4096, login=False)
        worker = threading.Thread(target=self.run_client, args=(conn, ("same-ip", 1)))
        with patch.object(server, "print_flush"):
            worker.start()
            try:
                self.assertTrue(waiting.wait(5))
                duplicate = ReplayConnection([login_request(1, 2)], 7, login=False)
                self.run_client(duplicate, ("same-ip", 2))
                self.assertEqual([(f["opcode"], f["seq"]) for f in duplicate.responses], [(999999, 2)])
                self.assertTrue(duplicate.closed)
                self.assertIn(1, self.store.active)
                self.replay([{"opcode": 201, "seq": 10, "hex": "08011003"}], account=2)
            finally:
                release.set()
                worker.join(5)
        self.assertFalse(worker.is_alive())
        self.assertEqual(self.store.active, {})
        self.replay([{"opcode": 201, "seq": 11, "hex": "08011004"}], account=1)

    def test_failed_login_releases_account_for_retry(self):
        path = self.store.path(2)
        path.write_text('{"unfinished":')
        conn = ReplayConnection([login_request(2, 1)], 4096, login=False)
        with patch.object(server, "print_flush"):
            self.run_client(conn)
        self.assertEqual([(f["opcode"], f["seq"]) for f in conn.responses], [(999999, 1)])
        self.assertEqual(self.store.active, {})
        path.write_text(json.dumps(player.get_default_save()))
        self.replay([{"opcode": 201, "seq": 11, "hex": "08011004"}], account=2)

    def test_startup_uses_one_port_and_never_runs_adb(self):
        with patch.object(server.socket, "socket") as factory, patch("subprocess.run", side_effect=AssertionError("must not run adb")), patch.object(server, "print_flush"):
            factory.return_value.accept.side_effect = KeyboardInterrupt
            server.main([])
            factory.return_value.bind.assert_called_once_with(("0.0.0.0", 14600))
            factory.return_value.close.assert_called_once()

    def test_reset_only_removes_target_account(self):
        self.replay([{"opcode": 201, "seq": 1, "hex": "08011003"}], account=1)
        self.replay([{"opcode": 201, "seq": 1, "hex": "08011004"}], account=2)
        before = self.save_path.read_bytes()
        with patch.object(server.socket, "socket") as factory, patch.object(server, "print_flush"):
            factory.return_value.accept.side_effect = KeyboardInterrupt
            server.main(["--account", "2", "--reset"])
        self.assertEqual(self.save_path.read_bytes(), before)
        self.assertFalse(self.store.path(2).exists())

    def test_occupied_port_prevents_resetting_live_account(self):
        self.save_path.write_text('{"role_name":"keep"}')
        before = self.save_path.read_bytes()
        with patch.object(server.socket, "socket") as factory, patch.object(server, "print_flush"):
            factory.return_value.bind.side_effect = OSError("address in use")
            with self.assertRaises(OSError):
                server.main(["--reset"])
        self.assertEqual(self.save_path.read_bytes(), before)

    def test_reset_guide_preserves_both_accounts_role_data(self):
        for account in (1, 2):
            self.replay([{"opcode": 201, "seq": 1, "hex": "08011003"}], account=account)
        before = self.save_path.read_bytes()
        second = self.store.path(2)
        saved = json.loads(second.read_text())
        with patch.object(server.socket, "socket") as factory, patch.object(server, "print_flush"):
            factory.return_value.accept.side_effect = KeyboardInterrupt
            server.main(["--account", "2", "--reset-guide"])
        current = json.loads(second.read_text())
        self.assertEqual(current["guide"], {"sections": {}})
        for key in ("role_name", "has_role", "world_state"):
            self.assertEqual(current[key], saved[key])
        self.assertEqual(self.save_path.read_bytes(), before)

    def test_tcp_clients_share_one_listener_but_not_saves(self):
        def read_frame(client):
            def read_exact(size):
                data = b""
                while len(data) < size:
                    chunk = client.recv(size - len(data))
                    if not chunk:
                        raise AssertionError("unexpected disconnect")
                    data += chunk
                return data
            magic, length, opcode, seq = struct.unpack(">IIII", read_exact(16))
            self.assertEqual(magic, 0xEE1C)
            return opcode, seq, read_exact(length)

        clients, workers = [], []
        with socket.socket() as listener, patch.object(server, "print_flush"):
            listener.bind(("127.0.0.1", 0))
            listener.listen(2)
            try:
                for account in (1, 2):
                    client = socket.create_connection(listener.getsockname(), timeout=3)
                    clients.append(client)
                    conn, addr = listener.accept()
                    worker = threading.Thread(target=self.run_client, args=(conn, addr))
                    worker.start()
                    workers.append(worker)
                    login = login_request(account, 1)
                    packet = protocol.pack_frame(1000, 1, bytes.fromhex(login["hex"]))
                    packet += protocol.pack_frame(201, 2, bytes((8, 1, 16, account + 2)))
                    for offset in range(0, len(packet), 7):
                        client.sendall(packet[offset:offset + 7])
                    self.assertEqual(read_frame(client), (1000, 1, b"\x08\x00\x10\x00\x18\x00"))
                    self.assertEqual(read_frame(client), (201, 2, b"\x08\x01"))
                self.assertEqual(set(self.store.active), {1, 2})
                for account, client in enumerate(clients, 1):
                    client.sendall(protocol.pack_frame(200, 3, b""))
                    opcode, seq, body = read_frame(client)
                    self.assertEqual((opcode, seq), (200, 3))
                    section = next(value for _, _, value in protocol.iter_pb_fields(body))
                    self.assertEqual(protocol.pb_get_varint(section, 3), account + 2)
            finally:
                for client in clients:
                    client.close()
                for worker in workers:
                    worker.join(5)
                    self.assertFalse(worker.is_alive())
        self.assertEqual(self.store.active, {})


class EntryPointTests(unittest.TestCase):
    def test_import_from_other_directory_does_not_load_assets_or_start_io(self):
        root = Path(server.__file__).parent
        code = (
            "from unittest.mock import patch\n"
            "with patch('zipfile.ZipFile', side_effect=AssertionError('config read')), "
            "patch('socket.socket', side_effect=AssertionError('socket opened')), "
            "patch('subprocess.check_output', side_effect=AssertionError('adb run')):\n"
            "    import mock_server\n"
            "    print(mock_server.BASE_DIR)\n"
            "    print(mock_server.RECORD_PATH)\n"
            "    print(mock_server.CONFIG_ZIP)\n"
            "    print(mock_server.SAVE_PATH)\n"
        )
        with tempfile.TemporaryDirectory() as directory:
            result = subprocess.run([sys.executable, "-B", "-c", code], cwd=directory,
                                    env={**os.environ, "PYTHONPATH": str(root)},
                                    capture_output=True, text=True, check=True, timeout=15)
            self.assertEqual(list(Path(directory).iterdir()), [])
        self.assertEqual(result.stdout.splitlines(), [str(root), str(root / "recorded_frames.json"),
                                                     str(root / "configs_sec5.zip"), str(root / "role_save.json")])
        self.assertEqual(result.stderr, "")

    def test_startup_passes_resources_to_connection_thread(self):
        conn = ReplayConnection([{"opcode": 200, "seq": 1, "hex": ""}], 7)
        with tempfile.TemporaryDirectory() as directory:
            save_path = Path(directory) / "role_save.json"
            with redirect_stdout(io.StringIO()), patch.object(server, "SAVE_PATH", str(save_path)), \
                    patch.object(server, "start_admin") as admin_factory, \
                    patch.object(sys, "argv", ["mock_server.py"]), \
                    patch("subprocess.check_output", side_effect=AssertionError("must not run adb")), \
                    patch.object(server.socket, "socket") as socket_factory, \
                    patch.object(server.threading, "Thread") as thread_factory:
                socket_factory.return_value.accept.side_effect = [(conn, ("test", 0)), KeyboardInterrupt]
                server.main()
                thread_factory.assert_called_once()
                thread_factory.return_value.start.assert_called_once_with()
                options = thread_factory.call_args.kwargs
                self.assertIs(options["target"], server.handle_client)
                self.assertTrue(options["daemon"])
                self.assertIs(options["args"][2], admin_factory.call_args.args[1])
                store = options["args"][2]
                store.register(1, LOGIN_PASSWORD, store.snapshot(1)["revision"])
                admin_factory.return_value.shutdown.assert_called_once_with()
                admin_factory.return_value.server_close.assert_called_once_with()
                options["target"](*options["args"])
                self.assertIsNone(options["args"][3].stream)
            self.assertFalse(save_path.exists())
        self.assertTrue(conn.closed)
        self.assertEqual(conn.responses, [{"opcode": 200, "seq": 1, "hex": ""}])

    def test_startup_preserves_reset_flag_behavior_with_temporary_save(self):
        save = player.get_default_save()
        save.update(role_name="原有玩家", has_role=True, selected_general_id=3)
        save["guide"]["sections"] = {"1": {"status": 1, "step": 5, "steps": [5]}}
        original = json.dumps(save)
        with tempfile.TemporaryDirectory() as directory:
            save_path = Path(directory) / "role_save.json"
            for flags in ([], ["--reset-guide"], ["--reset"]):
                with self.subTest(flags=flags):
                    save_path.write_text(original)
                    with redirect_stdout(io.StringIO()), patch.object(server, "SAVE_PATH", str(save_path)), \
                            patch.object(server, "start_admin"), \
                            patch.object(sys, "argv", ["mock_server.py", *flags]), \
                            patch("subprocess.check_output", side_effect=AssertionError("must not run adb")), \
                            patch.object(server.socket, "socket") as socket_factory:
                        socket_factory.return_value.accept.side_effect = KeyboardInterrupt
                        server.main()
                    socket_factory.return_value.bind.assert_called_once_with(("0.0.0.0", 14600))
                    if flags == ["--reset"]:
                        self.assertFalse(save_path.exists())
                    elif flags == ["--reset-guide"]:
                        saved = json.loads(save_path.read_text())
                        self.assertEqual(saved["guide"], {"sections": {}})
                        for key in ("role_name", "has_role", "selected_general_id", "created_at"):
                            self.assertEqual(saved[key], save[key])
                    else:
                        self.assertEqual(save_path.read_text(), original)


if __name__ == "__main__":
    unittest.main()
