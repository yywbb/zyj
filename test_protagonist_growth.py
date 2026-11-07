"""主角游戏厅与觉醒：原配置、临时账号和实际APK回调。"""

import copy
from fractions import Fraction
import json
from pathlib import Path
import unittest
import zipfile
from unittest.mock import patch

import build_local_apk as builder
import test_hades_battle
import test_soul
from zyj_server import battle, cup, development, formation, gamestar, guild_war, player, protocol, recharge, single_boss, training


def setUpModule():
    test_soul.setUpModule()


class ProtagonistGrowthTests(unittest.TestCase):
    request = test_soul.SoulTests.request
    success = test_soul.SoulTests.success
    reconnect = test_soul.SoulTests.reconnect
    add_account = test_soul.SoulTests.add_account
    assert_rejected = test_soul.SoulTests.assert_rejected
    refresh = test_soul.SoulTests.refresh
    grant = test_soul.SoulTests.grant
    props = test_soul.SoulTests.props
    gen = test_soul.SoulTests.gen
    records = test_soul.SoulTests.records
    groups = test_soul.SoulTests.groups
    client_scripts = classmethod(test_soul.SoulTests.client_scripts.__func__)
    network_lua = test_soul.SoulTests.network_lua
    client_call = test_soul.SoulTests.client_call

    def setUp(self):
        test_soul.SoulTests.setUp(self)
        self.save["role_state"].update(level=150, coin=100000000000, gold=1000000)
        self.set_hero()

    def set_hero(self, growth=23, level=300, awaken=0):
        raw = self.gen()
        cid = self.config["protagonist_grow"][str(growth)][f'general{self.save["selected_general_id"]}']
        for field, value in ((1, cid), (3, level), (4, growth), (18, awaken)):
            raw = protocol.pb_set_varint(raw, field, value)
        protagonist = protocol.pb_set_varint(bytes.fromhex(self.save["protagonist_snapshot"]), 3, growth)
        protagonist = protocol.pb_set_field(protagonist, 10, 2, raw)
        self.save["protagonist_snapshot"] = protagonist.hex()
        player.record_slot_update(self.save, protocol.encode_pb_field(1, 2, raw) + protocol.encode_pb_field(6, 2, protagonist))
        self.save["role_state"]["profile"] = cid

    def pay_materials(self, spec):
        for cid, count in (tuple(map(int, item.split(","))) for item in spec.split(";") if item):
            if cid not in (1000, 1001):
                self.grant(cid, count)

    def test_legacy_game_progress_without_clock_allows_account_loading_without_rewriting_saves(self):
        for account in (1, 10):
            with self.subTest(account=account):
                legacy = copy.deepcopy(self.save)
                legacy["gamestar_state"] = {"stage": 1, "step": 0}
                self.store.close_session(account)
                self.assertTrue(player.save_role(legacy, self.store.path(account), self.sessions[1].step_counts))
                before = self.store.path(account).read_bytes()
                session = self.store.open_session(account, "test-password", ("test-address", account))
                self.sessions[account] = session
                self.addCleanup(self.store.close_session, account)
                self.assertEqual(session.save, legacy)
                self.assertEqual(self.store.path(account).read_bytes(), before)
                self.assertEqual(gamestar.get_state(session.save, self.config), {"stage": 1, "step": 0, "checked_at": 0})
                self.assertEqual(session.save, legacy)

    def test_legacy_game_clock_is_saved_only_with_successful_query_or_paid_activation(self):
        self.save["gamestar_state"] = {"stage": 1, "step": 0}
        self.pay_materials(self.config["hoshimiya_jihuo"]["1"]["1"]["activation_cost"])
        self.assertTrue(player.save_role(self.save, self.store.path(1), self.sessions[1].step_counts))
        for opcode in (3720, 3721):
            values = [] if opcode == 3720 else [1, 0]
            before = copy.deepcopy(self.save)
            disk = self.store.path(1).read_bytes()
            with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
                self.request(1, opcode, values=values)
            self.assertEqual((self.save, self.store.path(1).read_bytes()), (before, disk))
        before = copy.deepcopy(self.save)
        self.success(1, 3720); self.refresh()
        self.assertEqual(self.save["gamestar_state"], {"stage": 1, "step": 0, "checked_at": self.now})
        for key in ("role_state", "world_state", "protagonist_snapshot"):
            self.assertEqual(self.save[key], before[key])
        self.save["gamestar_state"].pop("checked_at")
        self.assertTrue(player.save_role(self.save, self.store.path(1), self.sessions[1].step_counts))
        before = copy.deepcopy(self.save)
        self.success(1, 3721, values=[1, 0]); self.refresh()
        self.assertEqual(self.save["gamestar_state"], {"stage": 1, "step": 1, "checked_at": self.now})
        self.assertEqual(self.save["role_state"]["coin"], before["role_state"]["coin"] - 33300)
        self.assertEqual((self.props(20167), self.props(20285)), (0, 0))
        raw = formation.records(bytes.fromhex(before["world_state"]["1002"]), 1, 2)[protocol.pb_get_varint(self.gen(), 2)]
        self.assertEqual(protocol.pb_get_varint(self.gen(), 6), protocol.pb_get_varint(raw, 6) + 579)
        self.reconnect(); self.refresh()
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 3720)), [1, 1])
        self.clock.return_value -= 1
        self.assert_rejected(3721, values=[1, 1])

    def test_legacy_clock_default_preserves_nonzero_progress_unknown_fields_and_strict_validation(self):
        for stage, step in ((1, 0), (12, 5), (30, 9), (31, 0)):
            state = {"stage": stage, "step": step, "unknown": {"keep": 7}}
            save = {"gamestar_state": state}
            before = copy.deepcopy(save)
            normalized = gamestar.get_state(save, self.config)
            self.assertEqual(normalized, dict(state, checked_at=0))
            self.assertEqual(save, before)
        invalid = [None, [], {}, {"stage": 1}, {"step": 0}, {"stage": 0, "step": 0},
                   {"stage": 31, "step": 1}, {"stage": 1, "step": 10}, {"stage": True, "step": 0}]
        invalid += [{"stage": 1, "step": 0, "checked_at": value} for value in (None, False, "0", -1, 1 << 63)]
        for state in invalid:
            save = {"gamestar_state": state}
            before = copy.deepcopy(save)
            with self.subTest(state=state), self.assertRaises(ValueError):
                gamestar.get_state(save, self.config)
            self.assertEqual(save, before)
        current = {"gamestar_state": {"stage": 12, "step": 5, "checked_at": self.now + 100}}
        self.assertEqual(gamestar.get_state(current, self.config)["checked_at"], self.now + 100)

    def test_game_query_activation_real_costs_stats_and_stale_target_rejection(self):
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 3720)), [1, 0])
        self.refresh()
        row = self.config["hoshimiya_jihuo"]["1"]["1"]
        self.pay_materials(row["activation_cost"])
        before, raw = copy.deepcopy(self.save), self.gen()
        result = self.request(1, 3721, values=[1, 0])
        self.refresh()
        self.assertEqual(result[0][0], 3721)
        self.assertIn(1200, [mid for mid, _ in result])
        self.assertIn(1001, [mid for mid, _ in result])
        self.assertEqual(self.save["gamestar_state"]["step"], 1)
        self.assertEqual(protocol.pb_get_varint(self.gen(), 6), protocol.pb_get_varint(raw, 6) + 579)
        self.assertEqual(self.save["role_state"]["coin"], before["role_state"]["coin"] - 33300)
        self.assertEqual((self.props(20167), self.props(20285)), (0, 0))
        self.assert_rejected(3721, values=[1, 0])
        self.reconnect(); self.refresh()
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 3720)), [1, 1])

    def test_awakening_first_level_uses_real_costs_final_attributes_and_snapshot(self):
        row = self.config["protagonist_awaken"]["1"]
        self.pay_materials(row["consume"])
        before, raw = copy.deepcopy(self.save), self.gen()
        iid = protocol.pb_get_varint(raw, 2)
        frames = self.request(1, 1058, values=[iid, 0])
        self.refresh()
        self.assertEqual(frames[0][0], 1058)
        self.assertEqual(protocol.pb_get_varint(self.gen(), 18), 1)
        for name, field in (("atk", 6), ("def", 7), ("hp", 8)):
            self.assertEqual(protocol.pb_get_varint(self.gen(), field), protocol.pb_get_varint(raw, field) + row[name])
        self.assertEqual(self.save["role_state"]["coin"], before["role_state"]["coin"] - 50000)
        self.assertEqual((self.props(20278), self.props(20200)), (0, 0))
        embedded = next(v for n, w, v in protocol.iter_pb_fields(bytes.fromhex(self.save["protagonist_snapshot"])) if (n, w) == (10, 2))
        self.assertEqual(embedded, self.gen())
        self.assert_rejected(1058, values=[iid, 0])

    def test_all_270_points_and_30_breakthroughs_charge_exact_costs_and_keep_real_achievements(self):
        for cid in (20167, 20285, 20286):
            self.grant(cid, 100000000)
        initial, original = copy.deepcopy(self.save), self.gen()
        costs, attributes = {}, {6: 0, 7: 0, 8: 0}
        for stage in range(1, 31):
            for step in range(10):
                row = (self.config["hoshimiya_jihuo"][str(stage)][str(step + 1)] if step < 9
                       else self.config["hoshimiya_break"][str(stage)])
                spec = row["activation_cost"] if step < 9 else row["break_cost"]
                additions = [row["activation_add"]] if step < 9 else [row[f"break_add{i}"] for i in (1, 2, 3)]
                for entry in spec.split(";"):
                    if entry:
                        cid, count = map(int, entry.split(",")); costs[cid] = costs.get(cid, 0) + count
                for addition in additions:
                    name, amount = addition.split(":"); attributes[{"atk": 6, "def": 7, "hp": 8}[name]] += int(amount)
                self.success(1, 3721 if step < 9 else 3722, values=[stage, step] if step < 9 else [stage]); self.refresh()
            self.assertEqual(self.save["gamestar_state"]["stage"], stage + 1)
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 3720)), [31, 0])
        for field, amount in attributes.items():
            self.assertEqual(protocol.pb_get_varint(self.gen(), field), protocol.pb_get_varint(original, field) + amount)
        self.assertEqual(self.save["role_state"]["coin"], initial["role_state"]["coin"] - costs[1000])
        for cid in (20167, 20285, 20286): self.assertEqual(self.props(cid), 100000000 - costs[cid])
        tasks = {row["id"] for row in self.config["task"].values() if row["type"] == "hoshimiya"}
        self.assertEqual(len(tasks), 20)
        self.assertTrue(tasks <= set(self.save["achievement_state"]["completed"]))
        self.assert_rejected(3721, values=[31, 0]); self.assert_rejected(3722, values=[30])
        self.reconnect(); self.refresh()
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 3720)), [31, 0])

    def test_all_130_awakenings_use_final_not_cumulative_stats_and_preserve_unknown_fields(self):
        for row in self.config["protagonist_awaken"].values():
            for item in row["consume"].split(";"):
                if item:
                    cid, _ = map(int, item.split(","))
                    if cid not in (1000, 1001) and self.props(cid) < 100000000: self.grant(cid, 100000000 - self.props(cid))
        original = self.gen() + protocol.encode_pb_field(50, 2, b"keep")
        player.record_slot_update(self.save, protocol.encode_pb_field(1, 2, original))
        iid = protocol.pb_get_varint(original, 2)
        before, total, materials = self.save["role_state"]["coin"], {}, {}
        for level in range(1, 131):
            row = self.config["protagonist_awaken"][str(level)]
            for entry in row["consume"].split(";"):
                if entry:
                    cid, count = map(int, entry.split(","))
                    if cid != 1000: materials.setdefault(cid, self.props(cid))
                    total[cid] = total.get(cid, 0) + count
            self.success(1, 1058, values=[iid, level - 1]); self.refresh()
            self.assertEqual(protocol.pb_get_varint(self.gen(), 18), level)
            for name, field in (("atk", 6), ("def", 7), ("hp", 8)):
                self.assertEqual(protocol.pb_get_varint(self.gen(), field), protocol.pb_get_varint(original, field) + row[name])
            self.assertIn((50, 2, b"keep"), list(protocol.iter_pb_fields(self.gen())))
        self.assertEqual(self.save["role_state"]["coin"], before - total[1000])
        for cid, initial in materials.items(): self.assertEqual(self.props(cid), initial - total[cid])
        self.assert_rejected(1058, values=[iid, 130])
        self.reconnect(); self.refresh()
        self.assertEqual(protocol.pb_get_varint(self.gen(), 18), 130)

    def test_locked_malformed_legacy_and_unmatched_comb_operations_never_charge(self):
        iid = protocol.pb_get_varint(self.gen(), 2)
        for opcode, values in ((3721, []), (3721, [1, 1]), (3721, [2, 0]), (3722, []), (3722, [1]),
                               (1058, []), (1058, [iid]), (1058, [iid + 1, 0]), (1058, [iid, 1])):
            self.assert_rejected(opcode, values=values)
        for opcode in (3720, 3721, 3722, 1058):
            for raw in (b"\x08", b"\x10\x01", b"\x0a\x00"):
                self.assert_rejected(opcode, raw=raw)
            comb = protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, opcode))
            self.assert_rejected(999900, raw=comb)
        self.save["role_state"]["level"] = 39
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 3720)), [1, 0]); self.refresh()
        self.assertNotIn("gamestar_state", self.save)
        self.assert_rejected(3721, values=[1, 0])
        self.assert_rejected(1058, values=[iid, 0])
        self.save["role_state"]["level"] = 150
        original = self.gen()
        for raw in (protocol.pb_set_varint(original, 21, 1), protocol.pb_set_varint(original, 4, 24),
                    original + protocol.encode_pb_field(41, 2, recharge.ids([1]))):
            player.record_slot_update(self.save, protocol.encode_pb_field(1, 2, raw))
            self.assert_rejected(3721, values=[1, 0])
            self.assert_rejected(1058, values=[iid, 0])
        player.record_slot_update(self.save, protocol.encode_pb_field(1, 2, original))
        self.set_hero(growth=2, level=61)
        self.assert_rejected(1058, values=[iid, 0])

    def test_partial_cost_failure_overflow_and_failed_save_are_atomic_for_both_tracks(self):
        for opcode in (3721, 1058):
            spec = (self.config["hoshimiya_jihuo"]["1"]["1"]["activation_cost"] if opcode == 3721
                    else self.config["protagonist_awaken"]["1"]["consume"])
            values = [1, 0] if opcode == 3721 else [protocol.pb_get_varint(self.gen(), 2), 0]
            self.assert_rejected(opcode, values=values)
            self.pay_materials(spec)
            with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
                self.request(1, opcode, values=values)
            before = copy.deepcopy(self.save)
            for key in ("power", "power_all"): self.save["role_state"][key] = (1 << 31) - 1
            self.assert_rejected(opcode, values=values)
            self.save["role_state"].update(before["role_state"])
            frames = self.request(1, opcode, values=values); self.refresh()
            disk, memory = self.store.path(1).read_bytes(), copy.deepcopy(self.save)
            packets = self.sessions[1].handle(opcode, self.seq, recharge.ids(values))
            self.assertEqual([(int.from_bytes(p[8:12], "big"), p[16:]) for p in packets], frames)
            self.assertEqual((self.save, self.store.path(1).read_bytes()), (memory, disk))

    def test_game_break_requires_nine_points_and_actual_protagonist_growth(self):
        for cid in (20167, 20285, 20286): self.grant(cid, 1000000)
        self.set_hero(growth=4)
        for step in range(9): self.success(1, 3721, values=[1, step]); self.refresh()
        self.assert_rejected(3721, values=[1, 9])
        self.assert_rejected(3722, values=[1])
        self.assert_rejected(2401, values=[55501])
        self.set_hero(growth=5)
        self.success(1, 3722, values=[1]); self.refresh()
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 3720)), [2, 0])
        self.assertIn(55501, self.save["achievement_state"]["completed"])
        self.assert_rejected(3722, values=[1])
        before = self.props(20285)
        self.success(1, 2401, values=[55501]); self.refresh()
        self.assertEqual(self.props(20285), before + 50)
        self.reconnect(); self.assert_rejected(2401, values=[55501])

    def test_awakening_real_damage_rates_follow_protagonist_into_dedicated_team(self):
        self.set_hero(awaken=130)
        point = self.config["copy"]["42102"]["1"]
        attack, _ = battle.rosters(self.save, point, self.config)
        iid = protocol.pb_get_varint(self.gen(), 2)
        unit = next(u for u in attack.values() if u["iid"] == iid)
        self.assertEqual((unit["adddmgpct"], unit["subdmgpct"]), (Fraction(57, 100), Fraction(57, 100)))
        self.assertEqual((unit["awakening"], unit["skilllevel"]), (130, 0))
        before = copy.deepcopy(self.save)
        projected, _ = single_boss.project_team(self.save, [iid, 0, 0, 0, 0, 0, 0, 0], self.config)
        projected_attack, _ = battle.rosters(projected, point, self.config)
        unit = next(u for u in projected_attack.values() if u["iid"] == iid)
        self.assertEqual(unit["adddmgpct"], Fraction(57, 100))
        self.assertEqual(self.save, before)

    def test_awakening_damage_uses_configured_ratios_not_legacy_skill_level_growth(self):
        self.set_hero(awaken=130)
        units, _ = battle.rosters(self.save, self.config["copy"]["42101"]["1"], self.config)
        unit = copy.deepcopy(units[2])
        unit.update(advance=0, atk=1000, hp=1000000, speed=200, initial_ap=4, flat_in=0, flat_out=0,
                    critical=0, dodge=0, parry=0, resilience=0, hit=0, arp=0, pet_rates={})
        unit["def"] = 0
        enemy = dict(unit, awakening=0, iid=2000001, adddmgpct=0, subdmgpct=0, speed=100)
        before = copy.deepcopy(unit)
        report = battle.simulate({2: unit}, {2: enemy}, self.config, 7, max_rounds=1)
        hits = [(action["s"]["r"], sum(e.get("m", {}).get("m", 0) for e in action["e"]))
                for action in report["b"]["a"] if action["s"].get("t") == "k"]
        outgoing = battle.damage(unit, enemy, self.config, unit["skill"], multiplier=Fraction(157, 100))
        incoming = battle.damage(enemy, unit, self.config, enemy["skill"], multiplier=Fraction(100, 157))
        self.assertEqual(hits, [(True, outgoing), (False, incoming)])
        self.assertEqual(report["meta"]["attack"]["g"][str(unit["iid"])]["level3"], 130)
        self.assertEqual(unit, before)

    def test_actual_battle_converter_accepts_all_awakening_visual_tiers_on_both_sides(self):
        from lupa.lua51 import LuaRuntime
        lua = LuaRuntime()
        config = dict(self.config)
        with zipfile.ZipFile(Path(builder.__file__).with_name("configs_sec5.zip")) as archive:
            for name in ("generalanimation", "skillanimation"):
                config[name] = json.loads(archive.read("5/" + name + ".json"))
        lua.globals().gamedata = lua.table_from({"config": config}, recursive=True)
        lua.execute('''print=function() end;printT=print;battleScene={slotNum=7}
            table.getTableLength=function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
            CCFileUtils={sharedFileUtils=function(self) return self end,fullPathForFilename=function(self,p) return p end}
            ui={Split=function(s,sep) local t={} for v in string.gmatch(s,'[^'..sep..']+') do t[#t+1]=v end return t end}''')
        with zipfile.ZipFile(builder.SRC_APK) as archive:
            names, assets = archive.namelist(), {}
            lua.globals().CCFileUtils.isFileExist = lambda _, path: any(n.endswith("/" + path) for n in names)
            def asset(path):
                if path not in assets:
                    matches = [n for n in names if n.endswith("/" + path)]
                    self.assertEqual(len(matches), 1, path)
                    assets[path] = json.loads(archive.read(matches[0]))
                return lua.table_from(assets[path], recursive=True)
            lua.globals().LoadJsonFileToTable = asset
            lua.execute(self.client_scripts()["assets/scripts/battleReportConvert.so"].decode())
            lua.execute(builder.read_script("BattleReportAbbToKey").decode())
            tiers = {row["icon"]: row["id"] for row in self.config["protagonist_awaken"].values()}
            self.assertEqual(len(tiers), 14)
            for level in tiers.values():
                self.set_hero(awaken=level)
                attack, defense = battle.rosters(self.save, self.config["copy"]["42101"]["1"], self.config)
                for direct in (True, False):
                    report = battle.simulate(attack if direct else defense, defense if direct else attack, self.config, 7)
                    native = lua.table_from(json.loads(lua.globals().ReplaceAbbToKey(json.dumps(report))), recursive=True)
                    allies, enemies = lua.globals().getBattleInitSlotInfo(native)
                    animations, ext = lua.globals().convertBattleReportToAnimationSub(native, allies, enemies)
                    self.assertGreater(len(animations), 1)
                    for side, key in (("attack", "atk"), ("defense", "def")):
                        for pos, unit in report["endmeta"][side].items():
                            self.assertEqual((ext.endinfo[key][pos].hp, ext.endinfo[key][pos].ap), (unit["h"], unit["ap"]))

    def test_game_clock_rollback_corrupt_progress_and_query_save_failure_never_grant_growth(self):
        for state in ({"stage": 0, "step": 0, "checked_at": 0}, {"stage": 31, "step": 1, "checked_at": 0},
                      {"stage": 1, "step": 10, "checked_at": 0}, {"stage": True, "step": 0, "checked_at": 0}):
            with self.subTest(state=state), self.assertRaises(ValueError):
                gamestar.get_state({"gamestar_state": state}, self.config)
        before = copy.deepcopy(self.save)
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 3720)
        self.assertEqual(self.save, before)
        self.success(1, 3720); self.refresh()
        self.pay_materials(self.config["hoshimiya_jihuo"]["1"]["1"]["activation_cost"])
        self.clock.return_value -= 1
        self.assert_rejected(3721, values=[1, 0])
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 3720)), [1, 0]); self.refresh()
        self.assertEqual(self.save["gamestar_state"]["checked_at"], self.now)

    def test_game_gift_uses_actual_entry_and_once_only_simulated_payment_without_free_gold(self):
        self.assert_rejected(2882, values=[130018])
        self.success(1, 3720); self.refresh()
        before = self.save["world_state"]["1200"]
        self.success(1, 2882, values=[130018]); self.refresh()
        start = self.save["gamestar_gift_state"]["triggered_at"]
        self.assertEqual(self.save["world_state"]["1200"], before)
        self.assert_rejected(2881, values=[130018])
        self.clock.return_value += 60
        self.success(1, 2882, values=[130018]); self.refresh()
        self.assertEqual(self.save["gamestar_gift_state"]["triggered_at"], start)
        request = lambda tier: b"".join(protocol.encode_pb_field(1, 2, recharge.ids([v])) for v in (tier, 130018))
        self.assert_rejected(115, raw=request(3))
        order = self.records(self.success(1, 115, raw=request(4)))[0]
        gold = self.sessions[1].save["role_state"]["gold"]
        self.success(1, 116, values=[protocol.pb_get_varint(order, 1)])
        self.reconnect(); self.refresh()
        self.assertEqual(self.save["role_state"]["gold"], gold)
        self.clock.return_value += 12 * 3600
        before = copy.deepcopy(self.save)
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 2881, values=[130018])
        self.assertEqual(self.save, before)
        self.success(1, 2881, values=[130018]); self.refresh()
        for cid, count in ((20285, 500), (20286, 100), (20167, 100)):
            self.assertEqual(self.props(cid), count)
        self.assertEqual(self.save["role_state"]["coin"], before["role_state"]["coin"] + 500000)
        self.assert_rejected(2881, values=[130018])
        self.reconnect(); self.assert_rejected(2881, values=[130018])
        self.success(2, 3720)
        self.sessions[2].save["role_state"]["level"] = 40
        self.success(2, 3720)
        self.success(2, 2882, values=[130018])
        self.clock.return_value += 12 * 3600
        self.assertEqual(self.request(2, 115, raw=request(4))[0][0], 999999)

    def test_awakened_game_stats_survive_fashion_growth_and_real_frozen_teams(self):
        self.set_hero(growth=5, level=100)
        self.pay_materials(self.config["hoshimiya_jihuo"]["1"]["1"]["activation_cost"])
        self.pay_materials(self.config["protagonist_awaken"]["1"]["consume"])
        self.success(1, 3721, values=[1, 0]); self.refresh()
        iid = protocol.pb_get_varint(self.gen(), 2)
        self.success(1, 1058, values=[iid, 0]); self.refresh()
        self.success(1, 1074, values=[80001]); self.refresh()
        before = self.gen()
        self.success(1, 1073, values=[80001]); self.refresh()
        self.success(1, 1071); self.refresh()
        self.assertEqual(self.gen(), before)
        world = bytes.fromhex(self.save["world_state"]["1002"])
        slots, equips = formation.records(world, 4, 2), formation.records(world, 2, 1)
        grown, _, _ = training.grow_general(before, 20000, slots[iid], set(), equips, self.config, 300)
        baseline = copy.deepcopy(self.save)
        raw = protocol.pb_set_varint(before, 6, protocol.pb_get_varint(before, 6) - 579)
        for name, field in (("atk", 6), ("def", 7), ("hp", 8)):
            raw = protocol.pb_set_varint(raw, field, protocol.pb_get_varint(raw, field) - self.config["protagonist_awaken"]["1"][name])
        normal, _, _ = training.grow_general(raw, 20000, slots[iid], set(), equips, self.config, 300)
        for name, field in (("atk", 6), ("def", 7), ("hp", 8)):
            self.assertEqual(protocol.pb_get_varint(grown, field) - protocol.pb_get_varint(normal, field),
                             self.config["protagonist_awaken"]["1"][name] + (579 if field == 6 else 0))
        row = self.config["protagonist_grow"]["6"]
        cid = row[f'general{self.save["selected_general_id"]}']
        advanced, _, _ = development.grow_protagonist(before, row, cid, {}, slots[iid], set(), equips, self.config)
        normal, _, _ = development.grow_protagonist(raw, row, cid, {}, slots[iid], set(), equips, self.config)
        self.assertEqual(protocol.pb_get_varint(advanced, 18), 1)
        for name, field in (("atk", 6), ("def", 7), ("hp", 8)):
            self.assertEqual(protocol.pb_get_varint(advanced, field) - protocol.pb_get_varint(normal, field),
                             self.config["protagonist_awaken"]["1"][name] + (579 if field == 6 else 0))
        self.assertEqual(self.save, baseline)
        self.set_hero(growth=23, awaken=130)
        snapshots = [cup.frozen(self.save, 1, self.config)["snapshot"], guild_war.freeze(self.save)]
        self.set_hero(awaken=0)
        for snapshot in snapshots:
            units, _ = battle.rosters(snapshot, self.config["copy"]["42101"]["1"], self.config)
            self.assertEqual(units[2]["awakening"], 130)
            self.assertEqual(units[2]["adddmgpct"], Fraction(57, 100))

    def soar_lead(self, level):
        iid = protocol.pb_get_varint(self.gen(), 2)
        for stage in range(1, level + 1):
            self.pay_materials(self.config["passive_soaring"][str(stage)]["consume"])
            self.success(1, 7001, values=[iid, stage-1])
            self.refresh()
        return iid

    def gold_hero(self, scopes=(1,)):
        """把默认23阶主角按真实顺序推进彩金：每阶先飞升10级再进阶，返回主角IID。"""
        self.save["gamestar_state"] = {"stage": 16, "step": 0, "checked_at": 0}
        iid = protocol.pb_get_varint(self.gen(), 2)
        soared = 0
        for stage, scope in enumerate(scopes, 1):
            for level in range(soared + 1, 10 * stage + 1):
                self.pay_materials(self.config["passive_soaring"][str(level)]["consume"])
                self.success(1, 7001, values=[iid, level - 1])
                self.refresh()
            soared = 10 * stage
            self.pay_materials(self.config["protagonist_grow"][str(23 + stage)]["consume"])
            self.success(1, 1057, values=[scope])
            self.refresh()
        return iid

    def gold_fields(self, stages):
        """按金将配置与飞升等级计算24/25/26字段与阵营的期望值。"""
        soar = self.config["passive_soaring"][str(10 * len(stages))]
        fairy = {24: soar["xianhp"], 25: soar["xiandef"], 26: soar["xianadk"]}
        general = self.config["general"][str(protocol.pb_get_varint(self.gen(), 1))]
        for stage in range(1, len(stages) + 1):
            for entry in general[f"gold{stage}_will_attribute"].split(";"):
                if entry:
                    name, amount = entry.split(",")
                    fairy[development.GOLD_ATTR[name]] += int(amount)
        packed = sum((stages[i] if i < len(stages) else 0) * 10 ** (2 - i) for i in range(3))
        camp = self.config["jinjiangkezhiguanxi"][str(packed)]["camp"] if stages else 0
        return fairy, camp

    def test_gold_advance_chain_uses_real_gates_costs_fields_and_battle_projection(self):
        self.save["gamestar_state"] = {"stage": 16, "step": 0, "checked_at": 0}
        iid = protocol.pb_get_varint(self.gen(), 2)
        choice = self.save["selected_general_id"]
        scopes = (1, 2, 3)
        for stage, scope in enumerate(scopes, 1):
            with self.subTest(stage=stage, scope=scope):
                target = 23 + stage
                for level in range(10 * (stage - 1) + 1, 10 * stage + 1):
                    self.pay_materials(self.config["passive_soaring"][str(level)]["consume"])
                    self.success(1, 7001, values=[iid, level - 1])
                    self.refresh()
                row = self.config["protagonist_grow"][str(target)]
                self.pay_materials(row["consume"])
                # 飞升同样消耗银币，需在本阶进阶前即时取值。
                coin = self.save["role_state"]["coin"]
                costs = development.partner_growth.pairs(row["consume"])
                props_before = {cid: self.props(cid) for cid, count in costs if cid not in (1000, 1001)}
                self.success(1, 1057, values=[scope]); self.refresh()
                raw = self.gen()
                self.assertEqual((protocol.pb_get_varint(raw, 1), protocol.pb_get_varint(raw, 4)),
                                 (row[f"general{choice}"], target))
                for i, selected in enumerate(scopes[:stage], 1):
                    self.assertEqual(protocol.pb_get_varint(raw, 34 + i), selected)
                fairy, camp = self.gold_fields(scopes[:stage])
                self.assertEqual(protocol.pb_get_varint(raw, 40), camp)
                for field, value in fairy.items():
                    self.assertEqual(protocol.pb_get_varint(raw, field), value)
                self.assertEqual(protocol.pb_get_varint(raw, 34), fairy[25] + fairy[26] + fairy[24] // 10)
                snapshot = bytes.fromhex(self.save["protagonist_snapshot"])
                self.assertEqual([protocol.pb_get_varint(snapshot, n) for n in (3, 4, 5, 6)], [target, 0, 0, 0])
                self.assertEqual(next(v for n, w, v in protocol.iter_pb_fields(snapshot) if (n, w) == (10, 2)), raw)
                for cid, count in costs:
                    if cid == 1000:
                        coin -= count
                    elif cid != 1001:
                        self.assertEqual(self.props(cid), props_before[cid] - count)
                self.assertEqual(self.save["role_state"]["coin"], coin)
        attack, _ = battle.rosters(self.save, self.config["copy"]["42101"]["1"], self.config)
        unit = next(u for u in attack.values() if u["iid"] == iid)
        raw = self.gen()
        factor = Fraction(self.config["global_kv"]["fairy_turn_every"]["value"])
        self.assertEqual(unit["partner_skills"], [9001001, 9001005, 9001009])
        self.assertEqual(unit["gold_camp"], camp)
        self.assertEqual(unit["atk"], protocol.pb_get_varint(raw, 6) + int(protocol.pb_get_varint(raw, 26) * factor))
        self.assertEqual(unit["hp"], protocol.pb_get_varint(raw, 8) + int(protocol.pb_get_varint(raw, 24) * factor))
        self.reconnect(); self.refresh()
        self.assertEqual(protocol.pb_get_varint(self.gen(), 4), 26)
        # 彩金满阶后只能停在26阶。
        self.assert_rejected(1057, values=[1])

    def test_gold_soaring_after_advance_preserves_gold_attributes(self):
        iid = self.gold_hero((1,))
        fairy, _ = self.gold_fields((1,))
        step = self.config["passive_soaring"]["11"]
        self.pay_materials(step["consume"])
        self.success(1, 7001, values=[iid, 10]); self.refresh()
        raw = self.gen()
        for field, name in ((24, "xianhp"), (25, "xiandef"), (26, "xianadk")):
            gold = fairy[field] - self.config["passive_soaring"]["10"][name]
            self.assertEqual(protocol.pb_get_varint(raw, field), step[name] + gold)
        total = {f: protocol.pb_get_varint(raw, f) for f in (24, 25, 26)}
        self.assertEqual(protocol.pb_get_varint(raw, 34), total[25] + total[26] + total[24] // 10)
        self.assertEqual((protocol.pb_get_varint(raw, 35), protocol.pb_get_varint(raw, 40)), (1, 1))

    def test_gold_advance_rejects_bad_scope_missing_gates_and_is_atomic(self):
        iid = protocol.pb_get_varint(self.gen(), 2)
        # 默认主角飞升0级，24阶要求10级飞升。
        for values in ([0], [1], [2], [3], [4], [1, 2], []):
            self.assert_rejected(1057, values=values)
        self.save["gamestar_state"] = {"stage": 5, "step": 0, "checked_at": 0}
        self.soar_lead(10)
        # 游戏厅通关4关，不足24阶要求的5关。
        self.assert_rejected(1057, values=[1])
        self.save["gamestar_state"] = {"stage": 16, "step": 0, "checked_at": 0}
        row = self.config["protagonist_grow"]["24"]
        self.assert_rejected(1057, values=[2])
        with patch.dict(self.config["protagonist_grow"], {"24": {**row, "gold_will_skills": "4,9001001;"}}):
            self.assert_rejected(1057, values=[1])
        # 材料不足与落盘失败都不产生任何状态变化。
        self.pay_materials(row["consume"])
        before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 1057, values=[1])
        self.assertEqual((self.save, self.store.path(1).read_bytes()), (before, disk))
        # 形态被篡改时拒绝进阶。
        raw = self.gen()
        player.record_slot_update(self.save, protocol.encode_pb_field(1, 2, protocol.pb_set_varint(raw, 1, 10998)))
        self.assert_rejected(1057, values=[1])

    def test_lead_soaring_charges_real_costs_and_projects_fairy_into_battle(self):
        self.set_hero(growth=21, level=300)
        row = self.config["passive_soaring"]["1"]
        before, raw = copy.deepcopy(self.save), self.gen()
        iid = self.soar_lead(1)
        self.assertEqual(protocol.pb_get_varint(self.gen(), 23), 1)
        for field, name in ((24, "xianhp"), (25, "xiandef"), (26, "xianadk")):
            self.assertEqual(protocol.pb_get_varint(self.gen(), field), row[name])
        self.assertEqual(protocol.pb_get_varint(self.gen(), 34), row["xiandef"]+row["xianadk"]+row["xianhp"]//10)
        self.assertEqual(protocol.pb_get_varint(self.gen(), 9), protocol.pb_get_varint(raw, 9))
        self.assertEqual(self.save["role_state"]["coin"], before["role_state"]["coin"] - 217972)
        self.assertEqual((self.props(20818), self.props(20817)), (0, 0))
        embedded = next(v for n, w, v in protocol.iter_pb_fields(bytes.fromhex(self.save["protagonist_snapshot"])) if (n, w) == (10, 2))
        self.assertEqual(embedded, self.gen())
        factor = Fraction(self.config["global_kv"]["fairy_turn_every"]["value"])
        attack, _ = battle.rosters(self.save, self.config["copy"]["42101"]["1"], self.config)
        unit = next(u for u in attack.values() if u["iid"] == iid)
        self.assertEqual(unit["atk"], protocol.pb_get_varint(self.gen(), 6) + int(row["xianadk"]*factor))
        self.assertEqual(unit["hp"], protocol.pb_get_varint(self.gen(), 8) + int(row["xianhp"]*factor))
        self.assertEqual(unit["fei_sheng_level"], 1)
        self.assert_rejected(7001, values=[iid, 0])
        self.reconnect(); self.refresh()
        self.assertEqual(protocol.pb_get_varint(self.gen(), 23), 1)

    def test_lead_soaring_gates_malformed_and_atomic_failure_never_charge(self):
        self.set_hero(growth=20)
        iid = protocol.pb_get_varint(self.gen(), 2)
        self.assert_rejected(7001, values=[iid, 0])
        self.set_hero(growth=21)
        self.save["role_state"]["level"] = 99
        self.assert_rejected(7001, values=[iid, 0])
        self.save["role_state"]["level"] = 150
        for values in ([], [iid], [iid, 0, 0], [iid, 5], [iid+1, 0]):
            self.assert_rejected(7001, values=values)
        raw = self.gen()
        for mutate in (lambda r: protocol.pb_set_varint(r, 21, 1),
                       lambda r: protocol.pb_set_varint(r, 24, 1)):
            player.record_slot_update(self.save, protocol.encode_pb_field(1, 2, mutate(raw)))
            self.assert_rejected(7001, values=[iid, 0])
        player.record_slot_update(self.save, protocol.encode_pb_field(1, 2, raw))
        self.pay_materials(self.config["passive_soaring"]["1"]["consume"])
        before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 7001, values=[iid, 0])
        self.assertEqual((self.save, self.store.path(1).read_bytes()), (before, disk))
        self.assertEqual(self.props(20818), 130)

    def test_soared_lead_keeps_gamestar_and_awaken_growth(self):
        self.set_hero(growth=21)
        iid = self.soar_lead(1)
        self.pay_materials(self.config["hoshimiya_jihuo"]["1"]["1"]["activation_cost"])
        self.success(1, 3721, values=[1, 0]); self.refresh()
        self.assertEqual(self.save["gamestar_state"]["step"], 1)
        self.pay_materials(self.config["protagonist_awaken"]["1"]["consume"])
        self.success(1, 1058, values=[iid, 0]); self.refresh()
        self.assertEqual((protocol.pb_get_varint(self.gen(), 18), protocol.pb_get_varint(self.gen(), 23)), (1, 1))
        self.reconnect(); self.refresh()
        self.assertEqual((protocol.pb_get_varint(self.gen(), 18), protocol.pb_get_varint(self.gen(), 23)), (1, 1))

    def test_actual_lead_feisheng_network_pb_costs_locks_and_matching_errors(self):
        self.set_hero(growth=21, level=300)
        self.pay_materials(self.config["passive_soaring"]["1"]["consume"])
        lua = self.growth_network_lua()
        lua.eval(b"require")(b"GameGeneralBreak")
        fd = lambda raw: lua.table_from({b"rbuf": raw, b"ser": 7})
        iid = lua.globals().gamedata[b"cache"][b"protagonist"][b"iid"]
        req = lua.table_from({b"type": 7001, b"iid": iid, b"isLead": 1})
        mode, opcode, raw = lua.globals().UIPartnerFeiShengCallBack(req)
        self.assertEqual((mode, opcode, protocol.parse_ids_pb(raw)), (1, 7001, [iid, 0]))
        self.assertEqual(lua.globals().UIPartnerFeiShengCallBack(req)[0], 0)
        lua.globals().NetErrorMessageCallback9(fd(recharge.ids([7001, 0])))
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localLeadGrowthBusy"])
        mode, opcode, raw = lua.globals().UIPartnerFeiShengCallBack(req)
        self.assertEqual((mode, opcode, protocol.parse_ids_pb(raw)), (1, 7001, [iid, 0]))
        result = lua.globals().NetPartnerFeiShengCallBack(fd(self.success(1, opcode, raw=raw)))
        self.refresh()
        self.assertEqual(result[b"isLead"], 1)
        self.assertEqual(result[b"general"][b"level8"], 1)
        self.assertEqual(lua.eval(b"gamedata.getStaffNum(20818).num"), 0)
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localLeadGrowthBusy"])
        mode, opcode, raw = lua.globals().UIPartnerFeiShengCallBack(req)
        self.assertEqual((mode, protocol.parse_ids_pb(raw)), (1, [iid, 1]))
        lua.globals().NetErrorMessageCallback9(fd(recharge.ids([7001, 0])))
        req = lua.table_from({b"type": 7001, b"iid": iid+1, b"isLead": 1})
        self.assertEqual(lua.globals().UIPartnerFeiShengCallBack(req)[0], 0)

    def growth_network_lua(self):
        lua = self.network_lua()
        lua.eval(b"require")(b"GameGameStar")
        lua.globals().growth_props = bytes.fromhex(self.save["world_state"]["1200"])
        lua.execute(b'local p=require("idnums_pb").IdNums();p:ParseFromString(growth_props);gamedata:Props(p.idnums)')
        return lua

    def test_actual_network_pb_strict_targets_real_prices_shared_lock_and_matching_errors(self):
        for spec in (self.config["hoshimiya_jihuo"]["1"]["1"]["activation_cost"], self.config["protagonist_awaken"]["1"]["consume"]):
            self.pay_materials(spec)
        lua = self.growth_network_lua()
        fd = lambda raw: lua.table_from({b"rbuf": raw})
        self.client_call(lua, 1, "UIUserProtagonistGameQuery", "NetUserProtagonistGameQuery", {})
        coin = self.save["role_state"]["coin"]
        mode, opcode, raw = lua.globals().UIUserProtagonistGameEatBeans(lua.table_from({b"_stage": 1, b"_step": 0}))
        self.assertEqual((mode, opcode, protocol.parse_ids_pb(raw)), (1, 3721, [1, 0]))
        iid = protocol.pb_get_varint(self.gen(), 2)
        req = lua.table_from({b"iid": iid, b"level": 0})
        self.assertEqual(lua.globals().UIProtagonistAwakenCallBack(req)[0], 0)
        lua.globals().NetErrorMessageCallback9(fd(recharge.ids([1058, 0])))
        self.assertEqual(lua.globals().gamedata[b"ext"][b"localLeadGrowthBusy"][b"opcode"], 3721)
        packet = self.success(1, opcode, raw=raw)
        result = lua.globals().NetUserProtagonistGameEatBeans(fd(packet)); self.refresh()
        self.assertEqual(result[b"protagonist"][b"general"][b"skilllevel"], 0)
        self.assertEqual(lua.globals().gamedata[b"cache"][b"role"][b"coin"], coin - 33300)
        self.assertEqual(lua.eval(b"gamedata.getStaffNum(20167).num"), self.props(20167))
        self.assertTrue(lua.globals().NetUserProtagonistGameEatBeans(fd(packet))[b"localLeadGrowthIgnored"])
        self.assertEqual(lua.globals().gamedata[b"cache"][b"role"][b"coin"], coin - 33300)
        self.assertEqual(lua.globals().UIUserProtagonistGameEatBeans(lua.table_from({b"_stage": 1, b"_step": 0}))[0], 0)
        mode, opcode, raw = lua.globals().UIProtagonistAwakenCallBack(req)
        self.assertEqual((mode, opcode, protocol.parse_ids_pb(raw)), (1, 1058, [iid, 0]))
        result = lua.globals().NetProtagonistAwakenCallBack(fd(self.success(1, opcode, raw=raw))); self.refresh()
        self.assertEqual(result[b"protagonist"][b"general"][b"skilllevel"], 1)
        self.assertEqual(lua.globals().gamedata[b"cache"][b"role"][b"coin"], coin - 83300)
        for cid in (20278, 20200):
            self.assertEqual(lua.eval(b"function(cid) return gamedata.getStaffNum(cid).num end")(cid), self.props(cid))
        self.assertEqual(lua.globals().UIProtagonistAwakenCallBack(req)[0], 0)
        req[b"level"] = 1
        self.assertEqual(lua.globals().UIProtagonistAwakenCallBack(req)[0], 1)
        lua.globals().NetErrorMessageCallback9(fd(recharge.ids([1058, 0])))
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localLeadGrowthBusy"])
        self.assertIsNone(lua.globals().gameConfig)

    def test_actual_network_query_fifo_error_cleanup_property_context_and_game_breakthrough(self):
        for cid in (20167, 20285, 20286): self.grant(cid, 10000)
        self.save["gamestar_state"] = {"stage": 1, "step": 9, "checked_at": self.now}
        lua = self.growth_network_lua()
        fd = lambda raw: lua.table_from({b"rbuf": raw})
        for generation in (1, 2, 3):
            req = lua.table_from({b"leadGrowthView": lua.table_from({b"lead": generation})})
            self.assertEqual(lua.globals().UIUserProtagonistGameQuery(req)[0], 1)
        lua.globals().NetErrorMessageCallback9(fd(recharge.ids([3720, 0])))
        for generation in (2, 3):
            result = lua.globals().NetUserProtagonistGameQuery(fd(self.success(1, 3720)))
            self.assertEqual(result[b"leadGrowthView"][b"lead"], generation)
        self.assertTrue(lua.globals().NetUserProtagonistGameQuery(fd(self.success(1, 3720)))[b"localLeadGrowthIgnored"])
        before = self.props(20286)
        self.client_call(lua, 1, "UIUserProtagonistGamePopcorn", "NetUserProtagonistGamePopcorn", {"_stage": 1}); self.refresh()
        self.assertEqual(lua.globals().gamedata[b"ext"][b"localLeadGame"][b"stage"], 2)
        self.assertEqual(lua.globals().gamedata[b"cache"][b"props"][20286][b"num"], self.props(20286))
        self.assertLess(self.props(20286), before)
        req = lua.table_from({b"order": 33018, b"cids": lua.table_from([1000, 20278]),
                              b"leadGrowthView": lua.table_from({b"lead": 4})})
        mode, mid, result = lua.globals().UIPropQueryByIdCallback(req)
        self.assertEqual((mode, mid, result[b"leadGrowthView"][b"lead"]), (0, 12001, 4))
        lua.execute(b'''require("GameTimeBag");gamedata.cache.timebag={}
            for _,row in pairs(gamedata.config.trigger_gift2) do gamedata.cache.timebag[row.id]={cid=row.id,status=-1} end''')
        mode, mid, raw = lua.globals().UITimeBagTrigCallBack(lua.table_from({b"opt": 1, b"sysID": 203}))
        self.assertEqual((mode, mid, protocol.parse_ids_pb(raw)), (1, 2882, [130018]))

    def growth_ui_lua(self):
        lua = test_soul.SoulTests.ui_lua(self)
        scripts = self.client_scripts()
        with zipfile.ZipFile(Path(builder.__file__).with_name("configs_sec5.zip")) as archive:
            lua.globals().gamedata.config.generalanimation = lua.table_from(
                json.loads(archive.read("5/generalanimation.json")), recursive=True)
        native = builder.read_script("ui", "common_lua").decode()
        for name in ("getSTRandNUM", "getSTRandNUMs", "getIDandNUMs", "getNeedWithFuhao", "Split", "getAttrValue"):
            start = native.index(f"function ui.{name}(")
            end = native.index("\nfunction ", start + 1)
            lua.execute(native[start:end])
        iid, cid = (protocol.pb_get_varint(self.gen(), n) for n in (2, 1))
        lua.globals().GameScene.protagonist = lua.table_from({"iid": iid, "level2": 23, "train": 0, "w_l": 0, "w_c": 0,
            "general": {"iid": iid, "cid": cid, "level1": 300, "level2": 23, "skilllevel": 0}}, recursive=True)
        lua.execute('''
            delays={};local baseNode=node
            function node() local n=baseNode();n.runAction=function(_,action) delays[#delays+1]=action.callback end;return n end
            CCNode={create=node};CCDelayTime={create=function(_,time) return time end}
            CCCallFunc={create=function(_,callback) return {callback=callback} end}
            CCSequence={createWithTwoActions=function(_,delay,action) return action end}
            ccp=function(x,y) return {x=x or 0,y=y or 0} end
            setSpriteFrameByName=function() end
            ui.itemcache={loadSkeleton=function(_,name) assert(name);return node() end}
            ui.IDconfig=function(cid)
                local row=table.copy(gamedata.config.props[tostring(cid)] or {name="银币"})
                row.staffType="props";return row
            end
            ui.getAttrValue=function(v) return v end
            CCUserDefault={sharedUserDefault=function(self) return self end,getStringForKey=function() return "" end}
            gameConfig.images={};GameScene.roleinfo.id=1;GameScene.roleinfo.coin=100000000000
            guide={controller={addComplete=function(_,system,callback) assert(system==203);callback() end}}
            for _,name in ipairs({"Layer_lead2","Layer_fashion","Layer_wing_main","Layer_generalFeiSheng"}) do
                package.loaded[name]={init=function(self) self.rootNode=node() end,clear=function() end}
            end
        ''')
        for name in ("Layer_gamestar", "Layer_protagonistAwaken", "Layer_lead3"):
            lua.globals().package.loaded[name] = lua.execute(scripts[f"assets/scripts/{name}.so"].decode())
        lua.execute('''lead=package.loaded.Layer_lead3;game=lead.modules.gamestar;awaken=lead.modules.awaken
            GameScene.layers.lead={show=true,module=lead};requests={}''')
        lua.execute(builder.read_script("UIRole").decode())
        lua.execute(scripts["assets/scripts/UIProps.so"].decode())
        lua.execute(scripts["assets/scripts/UIGameStar.so"].decode())
        return lua

    def test_actual_game_page_controls_requery_on_reentry_and_reject_old_properties_and_clicks(self):
        lua = self.growth_ui_lua()
        lua.execute('''
            lead:init(node(),0,{page="gamestar"})
            assert(#requests==2 and requests[1].type==3720 and requests[2].type==2882)
            local query=requests[1]
            UIProtagonistGameQuery({_cellIndex=1,_nowsIndex=0,_selfLevel=23,leadGrowthView=query.leadGrowthView})
            assert(game.m_iRunCellIndex==1 and game.m_iRunNowsIndex==0)
            assert(game.rootItems.up_coin.text==33300 and game.up_needprops["20167"].num==7 and game.up_needprops["20285"].num==30)
            local old_property=requests[#requests]
            assert(old_property.type==12001 and old_property.order==10771)
            UIPropQueryById({order=10771,nums={["20167"]=100,["20285"]=100},leadGrowthView=old_property.leadGrowthView})
            local click=game.rootItems.m_oGameButon.callback
            click();assert(requests[#requests].type==3721 and requests[#requests]._stage==1 and requests[#requests]._step==0)
            local old_reply={_cellIndex=1,_nowsIndex=1,_selfLevel=23,leadGrowthView=query.leadGrowthView}
            lead:shiftPage("fashion")
            local before=#requests;click();UIPropQueryById({order=10771,nums={["20167"]=999},leadGrowthView=old_property.leadGrowthView})
            assert(#requests==before and game.up_needprops["20167"].has==100)
            lead:shiftPage("gamestar")
            assert(requests[before+1].type==3720)
            local fresh=requests[before+1]
            UIProtagonistGameQuery(old_reply);assert(game.m_iRunNowsIndex==0)
            UIProtagonistGameQuery({_cellIndex=1,_nowsIndex=1,_selfLevel=23,leadGrowthView=fresh.leadGrowthView})
            assert(game.m_iRunNowsIndex==1)
            UIPropQueryById({order=10771,nums={["20167"]=999},leadGrowthView=old_property.leadGrowthView})
            assert(game.up_needprops["20167"].has==0)
            for _,req in ipairs(requests) do assert(req.type~=1001) end
        ''')

    def test_actual_awakening_targets_properties_and_delayed_finish_ignore_switched_pages(self):
        lua = self.growth_ui_lua()
        lua.execute('''
            lead:init(node(),0,{page="awaken"})
            local prop=requests[#requests];assert(prop.order==33018 and prop.leadGrowthView.page=="awaken")
            local nums={["1000"]=100000000000,["20278"]=100000,["20200"]=100000}
            UIPropQueryById({order=33018,nums=nums,leadGrowthView=prop.leadGrowthView})
            local click=awaken.rootItems.doButton.callback
            click();local request=requests[#requests]
            assert(request.type==1058 and request.iid==GameScene.protagonist.iid and request.level==0)
            local hero=table.copy(GameScene.protagonist);hero.general=table.copy(hero.general);hero.general.skilllevel=1
            UIProtagonistAwaken({protagonist=hero,leadGrowthView=request.leadGrowthView})
            assert(#delays==1 and not opened)
            local delayed=delays[1]
            lead:shiftPage("fashion");local before=#requests;click();assert(#requests==before)
            lead:shiftPage("awaken")
            prop=requests[#requests];assert(prop.order==33018)
            delayed();assert(not opened)
            local old=awaken.rootItems.doButton.callback
            UIPropQueryById({order=33018,nums=nums,leadGrowthView=request.leadGrowthView})
            assert(awaken.rootItems.doButton.callback==old)
            UIPropQueryById({order=33018,nums=nums,leadGrowthView=prop.leadGrowthView})
            awaken.rootItems.doButton.callback();request=requests[#requests]
            assert(request.type==1058 and request.level==1)
            hero=table.copy(hero);hero.general=table.copy(hero.general);hero.general.skilllevel=2
            UIProtagonistAwaken({protagonist=hero,leadGrowthView=request.leadGrowthView})
            delays[#delays]();assert(opened.name=="protagonistawakenfinish" and awaken.data.general.skilllevel==2)
            local old_button=awaken.rootItems.doButton.callback
            hero.general.skilllevel=130;GameScene.protagonist=hero;awaken:refreshFunc()
            before=#requests;old_button();assert(#requests==before and awaken.rootItems.juexingcontrolnode)
            for _,req in ipairs(requests) do assert(req.type~=1001) end
            lead:clear();UIProtagonistAwaken({protagonist=hero,leadGrowthView=request.leadGrowthView})
            assert(awaken.rootNode==nil)
        ''')

    def test_actual_lead_feisheng_reply_reaches_lead_page_and_refreshes_realm_display(self):
        # 回归：7001 isLead 回包曾只走伙伴页分发，主角页永远停在旧境界名（白莲境0级）但战力已涨。
        lua = self.growth_ui_lua()
        lua.execute(self.client_scripts()["assets/scripts/UIGenerals.so"].decode())
        lua.execute('''
            lead:init(node(),0,{page="feisheng"})
            received={}
            lead.modules.feisheng.feiShengCallback=function(self,t) received[#received+1]=t end
            UIPartnerFeiSheng({type=7001,isLead=1,general={iid=GameScene.protagonist.iid,level8=1}})
            assert(#received==1 and received[1].level8==1)
            UIPartnerFeiSheng({type=7001,isLead=1,general={iid=GameScene.protagonist.iid,level8=2}})
            assert(#received==2 and received[2].level8==2)
            GameScene.layers.lead.show=false
            UIPartnerFeiSheng({type=7001,isLead=1,general={iid=GameScene.protagonist.iid,level8=3}})
            assert(#received==2)
            GameScene.layers.lead.show=true
            UIPartnerFeiSheng({type=7001,partnerIgnored=true})
            assert(#received==2)
        ''')

    def test_actual_game_break_animation_queries_authoritative_progress_and_closed_callbacks_stop(self):
        lua = self.growth_ui_lua()
        lua.execute('''
            lead:init(node(),0,{page="gamestar"})
            UIProtagonistGameQuery({_cellIndex=1,_nowsIndex=9,_selfLevel=23,leadGrowthView=requests[1].leadGrowthView})
            local view=LocalLeadGrowthContext("gamestar")
            UIProtagonistGamePopcorn({protagonist=GameScene.protagonist,leadGrowthView=view})
            assert(#delays==1)
            local delayed,completed=delays[1],game.rootAnimat.callback
            game:changeNextStages();assert(requests[#requests].type==3720 and game.m_iRunCellIndex==1)
            lead:shiftPage("fashion");lead:shiftPage("gamestar")
            local before=#requests;delayed();completed();assert(#requests==before)
            local query=requests[#requests-1];assert(query.type==3720)
            UIProtagonistGameQuery({_cellIndex=31,_nowsIndex=0,_selfLevel=23,leadGrowthView=query.leadGrowthView})
            assert(game.m_iRunCellIndex==31 and not game.rootItems.m_oDownNode.visible)
            for _,req in ipairs(requests) do assert(req.type~=3721 and req.type~=3722 and req.type~=1001) end
        ''')


class LeadGoldBattleTests(unittest.TestCase):
    """主角金将（162001-3）的七个彩金被动与单人合体：真实配置、确定性结算。"""

    unit = test_hades_battle.HadesBattleTests.unit
    hits = test_hades_battle.HadesBattleTests.hits
    assert_replays = test_hades_battle.HadesBattleTests.assert_replays

    @classmethod
    def setUpClass(cls):
        cls.config = player.load_role_config("configs_sec5.zip")

    def isolated(self, breakskill_values=None):
        row = {**self.config["general"]["162001"], **{f"break{i}": 0 for i in range(1, 27)}}
        config = {**self.config, "general": {**self.config["general"], "162001": row}}
        # 默认关闭金将单人合体的随机发动，合体用例自行设定概率。
        probability = copy.deepcopy(config["combskillprobability"])
        for sid in ("13019", "13020", "13021"):
            probability[sid] = {**probability[sid], **{f"bout{i}": 0 for i in range(1, 11)}}
        config["combskillprobability"] = probability
        if breakskill_values:
            config["breakskill"] = dict(config["breakskill"])
        for pid, values in (breakskill_values or {}).items():
            config["breakskill"][str(pid)] = {**config["breakskill"][str(pid)], **values}
        return config

    def gold(self, pid, **values):
        return self.unit(162001, iid=700, advance=26, partner_skills=[pid], **values)

    def combo_chance(self, config, sid, bout1):
        config["combskillprobability"][str(sid)] = {**config["combskillprobability"][str(sid)], "bout1": bout1}
        return config

    def test_focused_strike_reduces_personal_skill_targets_and_doubles_damage(self):
        config = self.isolated()
        enemies = {p: self.unit(iid=i + 1, hp=1000000, speed=1, atk=1) for i, p in enumerate(battle.POSITIONS[:6])}
        caster = dict(iid=700, advance=26, initial_ap=4, speed=300, atk=1000)
        control = battle.simulate({2: self.unit(162001, **caster)}, enemies, config, 7, max_rounds=1)
        self.assertEqual(self.hits(control), [800] * 6)
        report = battle.simulate({2: self.unit(162001, partner_skills=[9001001], **caster)}, enemies, config, 7, max_rounds=1)
        self.assertEqual(self.hits(report), [1600] * 4)
        self.assert_replays(report)

    def test_cold_armor_drains_highest_ap_enemy_twice_per_round_on_basic_hits(self):
        config = self.isolated({9001002: {"value": 1.0}})
        attackers = {p: self.unit(iid=i + 1, speed=speed, atk=1, initial_ap=0)
                     for i, (p, speed) in enumerate(zip(battle.POSITIONS[:3], (500, 400, 300)))}
        defense = {2: self.gold(9001002, hp=1000000, speed=1, atk=1)}
        report = battle.simulate(attackers, defense, config, 7, max_rounds=1)
        # 前两名攻击者各被扣2点怒气，第三次受击超出每回合2次上限。
        self.assertEqual([report["endmeta"]["attack"][str(p)]["ap"] for p in battle.POSITIONS[:3]], [0, 0, 2])
        self.assert_replays(report)
        control = battle.simulate(attackers, {2: self.unit(10201, iid=700, hp=1000000, speed=1, atk=1)}, config, 7, max_rounds=1)
        self.assertEqual([control["endmeta"]["attack"][str(p)]["ap"] for p in battle.POSITIONS[:3]], [2, 2, 2])

    def test_demon_king_combo_without_builtin_dizzy_adds_doubled_roll(self):
        config = self.combo_chance(self.isolated({9001003: {"value": 0.5}}), 13019, 1)
        enemies = {p: self.unit(iid=i + 1, hp=1000000, speed=1, atk=1) for i, p in enumerate(battle.POSITIONS[:2])}
        attack = {2: self.gold(9001003, speed=300, atk=1000, initial_ap=4)}
        report = battle.simulate(attack, enemies, config, 7, max_rounds=1)
        combo = next(a for a in report["b"]["a"] if a["s"].get("S") == 13019)
        # value改为0.5后翻倍为必中：合体技本身无眩晕配置，按本地规则附加眩晕。
        self.assertTrue(combo["e"])
        self.assertTrue(all(d.get("u", {}).get("u") == "dizzy" for d in combo["e"] if isinstance(d.get("m"), dict)))
        control = battle.simulate({2: self.unit(162001, iid=700, advance=26, speed=300, atk=1000, initial_ap=4)},
                                  enemies, config, 7, max_rounds=1)
        combo = next(a for a in control["b"]["a"] if a["s"].get("S") == 13019)
        self.assertFalse(any(d.get("u", {}).get("u") == "dizzy" for d in combo["e"]))
        self.assert_replays(report)

    def test_heart_link_adds_combo_chance_and_solo_combo_is_gold_lead_only(self):
        config = self.isolated({9001006: {"value": 1.0}})
        enemies = {2: self.unit(iid=1, hp=1000000, speed=1, atk=1)}
        # 基础概率为0时，心有灵犀（value改为1.0）仍让金将主角发动单人合体。
        report = battle.simulate({2: self.gold(9001006, speed=300, atk=1000, initial_ap=4)}, enemies, config, 7, max_rounds=1)
        self.assertTrue(any(a["s"].get("S") == 13019 for a in report["b"]["a"]))
        self.assert_replays(report)
        # 没有该被动时概率为0，只释放个人技能。
        control = battle.simulate({2: self.unit(162001, iid=700, advance=26, speed=300, atk=1000, initial_ap=4)},
                                  enemies, config, 7, max_rounds=1)
        self.assertFalse(any(a["s"].get("S") == 13019 for a in control["b"]["a"]))
        self.assertTrue(any(a["s"].get("S") == 180001 for a in control["b"]["a"]))
        # 本地规则：低阶主角形态（actor=lead但quality<7）引用单人合体也不发动。
        config = self.combo_chance(config, 12611, 1)
        legacy = battle.simulate({2: self.unit(10105, iid=700, speed=300, atk=1000, initial_ap=4)}, enemies, config, 7, max_rounds=1)
        self.assertFalse(any(a["s"].get("S") == 12611 for a in legacy["b"]["a"]))
        self.assertTrue(any(a["s"].get("S") == 12105 for a in legacy["b"]["a"]))

    def test_god_might_scales_with_living_heaven_allies_and_caps_at_value2(self):
        config = self.isolated()
        for heaven_allies, expected in ((0, 1150), (3, 1600), (5, 1600)):
            with self.subTest(heaven_allies=heaven_allies):
                team = {2: self.gold(9001007, gold_camp=1, speed=300, atk=1000)}
                for i in range(5):
                    team[battle.POSITIONS[i + 1]] = self.unit(iid=701 + i, gold_camp=1 if i < heaven_allies else 2,
                                                              speed=1, atk=1)
                report = battle.simulate(team, {2: self.unit(iid=1, hp=10000000, speed=1, atk=1)}, config, 7, max_rounds=1)
                self.assertEqual(self.hits(report), [expected])
                self.assert_replays(report)

    def test_earth_blessing_heals_three_earth_allies_and_grants_ap_on_death(self):
        config = self.isolated()
        killer = self.unit(162001, iid=1, advance=0, initial_ap=4, speed=600, atk=50000)
        team = {2: self.gold(9001008, hp=100, speed=1, atk=1)}
        for i, p in enumerate((8, 10, 12)):
            team[p] = self.unit(iid=701 + i, gold_camp=2, hp=100000, speed=1, atk=1, initial_ap=0)
        team[4] = self.unit(iid=704, gold_camp=1, hp=100000, speed=1, atk=1, initial_ap=0)
        team[6] = self.unit(iid=705, gold_camp=3, hp=100000, speed=1, atk=1, initial_ap=0)
        report = battle.simulate(team, {2: killer}, config, 7, max_rounds=1)
        end = report["endmeta"]["attack"]
        self.assertEqual(end["2"]["h"], 0)
        # 地属性友方各恢复30%生命与2点怒气，其他阵营不享受。
        for p in ("8", "10", "12"):
            self.assertEqual((end[p]["h"], end[p]["ap"]), (90000, 4))
        for p in ("4", "6"):
            self.assertEqual((end[p]["h"], end[p]["ap"]), (60000, 2))
        self.assert_replays(report)

    def test_human_soul_restores_ap_when_human_allies_cast_skills(self):
        config = self.isolated()
        enemy = {2: self.unit(iid=1, hp=10000000, speed=1, atk=1)}
        team = {2: self.gold(9001009, speed=1, atk=1, initial_ap=0),
                8: self.unit(iid=701, gold_camp=3, initial_ap=4, speed=300, atk=100),
                10: self.unit(iid=702, gold_camp=2, initial_ap=4, speed=200, atk=100)}
        report = battle.simulate(team, enemy, config, 7, max_rounds=1)
        # 人属性友方放技能回1怒，地属性友方不回；主角随后普攻+2怒。
        self.assertEqual(report["endmeta"]["attack"]["2"]["ap"], 3)
        self.assert_replays(report)
        team[10] = self.unit(iid=702, gold_camp=3, initial_ap=4, speed=200, atk=100)
        report = battle.simulate(team, enemy, config, 7, max_rounds=1)
        self.assertEqual(report["endmeta"]["attack"]["2"]["ap"], 4)
        control = battle.simulate({2: self.unit(10201, iid=700, speed=1, atk=1, initial_ap=0),
                                   8: team[8], 10: team[10]}, enemy, config, 7, max_rounds=1)
        self.assertEqual(control["endmeta"]["attack"]["2"]["ap"], 2)
