from contextlib import redirect_stdout
import copy
import datetime
import io
import json
from pathlib import Path
import random
import struct
import tempfile
import unittest
from unittest.mock import patch
import zipfile

import build_local_apk as builder
from zyj_server import activities, battle, formation, pets, player, protocol, qiankun, recharge, recruit, single_boss

ROOT = Path(__file__).parent
NOW = int(datetime.datetime(2026, 11, 3, 12, tzinfo=datetime.timezone(datetime.timedelta(hours=8))).timestamp())


class SingleBossTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        import test_penglai
        test_penglai.PenglaiTests.setUpClass()
        cls.config = test_penglai.PenglaiTests.config
        cls.steps, cls.tables = test_penglai.PenglaiTests.steps, test_penglai.PenglaiTests.tables
        cls.baseline = copy.deepcopy(test_penglai.PenglaiTests.baseline)
        cls.baseline["role_state"].update(level=27, gold=10000, vip=0, nextexp=cls.config["role_exp"]["27"]["nextexp"])

    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.path = Path(temporary.name) / "role_save.json"
        self.path.write_text(json.dumps(self.baseline))
        clock = patch("time.time", return_value=NOW)
        self.clock = clock.start()
        self.addCleanup(clock.stop)
        quiet = redirect_stdout(io.StringIO())
        quiet.__enter__()
        self.addCleanup(quiet.__exit__, None, None, None)
        self.session = self.reconnect()
        self.seq = 500

    def reconnect(self):
        from zyj_server.session import Session
        return Session(self.tables, self.path, self.steps, self.config)

    def call(self, opcode, values=(), seed=7):
        self.seq += 1
        with patch("random.getrandbits", return_value=seed):
            packets = self.session.handle(opcode, self.seq, recharge.ids(values))
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], opcode)
        return packets

    def query(self):
        return protocol.parse_ids_pb(self.call(3700)[0][16:])

    def team(self, kind=1):
        return protocol.parse_ids_pb(self.call(3702, [140, kind])[0][16:])

    def report(self, packets):
        return json.loads(next(v for n, w, v in protocol.iter_pb_fields(packets[0][16:]) if (n, w) == (5, 2)))

    def strong(self, weak=False):
        world = bytes.fromhex(self.session.save["world_state"]["1002"])
        for raw in formation.records(world, 1, 2).values():
            for field, value in ((6, 1 if weak else 10000000), (7, 0), (8, 100 if weak else 10000000), (9, 1 if weak else 1000)):
                raw = protocol.pb_set_varint(raw, field, value)
            player.record_slot_update(self.session.save, protocol.encode_pb_field(1, 2, raw))

    def assert_rejected(self, opcode, body):
        before, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        packets = self.session.handle(opcode, 900, body)
        self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in packets], [999999, 1999])
        self.assertEqual((self.session.save, self.path.read_bytes()), (before, disk))

    def test_entry_has_native_fields_and_does_not_skip_real_guide(self):
        before = copy.deepcopy(self.session.save)
        self.assertEqual(self.query(), [0, 1, 1, 0, 100, 0])
        for key in ("world_state", "protagonist_snapshot", "guide", "role_state"):
            self.assertEqual(self.session.save[key], before[key])
        self.assert_rejected(3701, recharge.ids([33001]))
        self.team()
        self.assertEqual(self.query()[2], 0)
        self.assertNotIn("61", self.session.save["guide"]["sections"])
        for step in range(1, self.steps[61] + 1):
            self.session.handle(201, 900 + step, protocol.encode_pb_field(1, 0, 61) + protocol.encode_pb_field(2, 0, step))
        self.session = self.reconnect()
        self.assertEqual(self.session.save["guide"]["sections"]["61"]["status"], 2)

    def test_two_dedicated_formations_reconnect_without_modifying_main_team(self):
        first, second = self.team(), self.team(2)
        self.assertEqual(len(first), 11)
        self.assertEqual(first[-2:], [140, 1])
        before = copy.deepcopy(self.session.save)
        changed = list(first[:8])
        changed[0], changed[1] = changed[1], changed[0]
        self.call(3703, [140, 1, *changed])
        self.assertEqual(self.team()[:8], changed)
        self.assertEqual(self.team(2), second)
        for key in ("world_state", "protagonist_snapshot", "role_state"):
            self.assertEqual(self.session.save[key], before[key])
        self.session = self.reconnect()
        self.assertEqual(self.team()[:8], changed)

    def test_formation_validates_ownership_duplicates_protagonist_and_pet(self):
        team = self.team()[:8]
        for changed in ([99999999, *team[1:]], [team[0], team[0], *team[2:]],
                        [0] * 8, [*team[:7], 99999999]):
            self.assert_rejected(3703, recharge.ids([140, 1, *changed]))
        self.assert_rejected(3703, recharge.ids([141, 1, *team]))
        self.assert_rejected(3702, recharge.ids([140, 3]))

    def test_real_wins_award_first_drop_once_and_preserve_other_gameplay(self):
        self.team()
        self.strong()
        before = copy.deepcopy(self.session.save)
        packets = self.call(3701, [33001])
        report = self.report(packets)
        self.assertTrue(report["result"])
        self.assertEqual(self.query()[:4], [1, 1, 0, 33001])
        for key in ("stamina", "energy", "exp", "level", "power", "gold"):
            self.assertEqual(self.session.save["role_state"][key], before["role_state"][key])
        for mid in ("1300", "1200", "1002", "1107", "1012"):
            if mid == "1002":
                self.assertNotEqual(self.session.save["world_state"][mid], before["world_state"][mid])  # 魔符奖励。
            else:
                self.assertEqual(self.session.save["world_state"][mid], before["world_state"][mid])
        self.assertEqual(self.session.save.get("last_battle"), before.get("last_battle"))
        state = copy.deepcopy(self.session.save)
        self.assertEqual(self.session.handle(3701, self.seq - 1, recharge.ids([33001])), packets)
        self.assertEqual(self.session.save, state)
        self.assert_rejected(3701, recharge.ids([33001]))
        self.call(301, [6, 1, 200])
        self.call(3701, [33001])
        self.assertEqual(self.session.save["single_boss_state"]["cleared"]["1"], 1)
        self.assertEqual(self.query()[0], 2)

    def test_losses_are_real_free_retries_without_rewards_or_progress(self):
        self.team()
        self.strong(weak=True)
        before = copy.deepcopy(self.session.save)
        for _ in range(2):
            self.assertFalse(self.report(self.call(3701, [33001]))["result"])
        self.assertEqual(self.query()[:4], [0, 1, 0, 0])
        for key in ("world_state", "role_state", "guide", "last_battle"):
            self.assertEqual(self.session.save.get(key), before.get(key))

    def test_purchase_has_server_quote_vip_cap_live_projection_and_forward_day_only(self):
        self.query()
        for values in ([6, 1], [6, 1, 0], [6, 2, 400], [6, 0, 0]):
            self.assert_rejected(301, recharge.ids(values))
        self.call(301, [6, 1, 200])
        self.assertEqual(self.session.save["role_state"]["gold"], 9800)
        self.assertEqual(protocol.parse_ids_pb(self.call(300)[0][16:])[11], 1)
        self.assertEqual(self.query()[5], 1)
        self.assert_rejected(301, recharge.ids([6, 1, 200]))
        self.clock.return_value = NOW + 86400
        self.assertEqual(self.query(), [0, 2, 1, 0, 100, 0])
        self.clock.return_value = NOW
        self.query()
        self.assert_rejected(301, recharge.ids([6, 1, 200]))
        self.assert_rejected(3701, recharge.ids([33001]))

    def test_only_active_boss_sequential_difficulty_and_level_can_be_challenged(self):
        self.team()
        for cid in (33002, 33101, 33050, 33000, 9999):
            self.assert_rejected(3701, recharge.ids([cid]))
        self.session.save["role_state"]["level"] = 26
        self.assert_rejected(3700, b"")

    def test_onekey_requires_unlock_and_cleared_target_and_runs_actual_fights(self):
        self.team()
        self.strong()
        self.call(3701, [33001])
        self.call(301, [6, 1, 200])
        self.assert_rejected(3705, recharge.ids([33001, 1]))
        self.session.save["role_state"].update(level=80, vip=25)
        self.assert_rejected(3705, recharge.ids([33002, 1]))
        self.assert_rejected(3705, recharge.ids([33001, 10]))
        self.call(301, [6, 2, 400])
        self.call(3705, [33001, 3])
        self.assertEqual(self.query()[0], 4)
        self.assertEqual(self.session.save["last_single_boss_battle"]["attempts"], 3)
        self.assert_rejected(3705, recharge.ids([33001, 1]))

    def test_malformed_requests_and_unmatched_comb_do_not_mutate(self):
        for opcode in (3700, 3701, 3702, 3703, 3705):
            for body in (b"\x08", b"\x10\x01", b"\x0a\x00", recharge.ids([1 << 31]), recharge.ids([0] * 12)):
                self.assert_rejected(opcode, body)
        self.assert_rejected(999900, protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 3701)))

    def test_save_failure_does_not_publish_formations_rewards_or_purchased_attempts(self):
        self.team()
        self.strong()
        for opcode, values in ((3701, [33001]), (301, [6, 1, 200]), (3703, [140, 2, *self.team()[:8]])):
            before, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
            with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
                self.call(opcode, values)
            self.assertEqual((self.session.save, self.path.read_bytes()), (before, disk))
            self.session = self.reconnect()
            self.strong()

    def test_dedicated_idle_general_is_protected_from_refinement_rebirth_and_gm_delete(self):
        from zyj_server.admin import gm
        team = self.team()[:8]
        owned = formation.records(bytes.fromhex(self.session.save["world_state"]["1002"]), 1, 2)
        cids = {protocol.pb_get_varint(raw, 1) for raw in owned.values()}
        cid = next(int(k) for k, r in sorted(self.config["general"].items()) if r["battle"] and r["actor"] != "lead"
                   and r["init_cid"] == int(k) and r["quality"] == 3 and int(k) not in cids)
        iid = 2000999
        player.record_slot_update(self.session.save, protocol.encode_pb_field(1, 2, recruit.new_general(cid, iid, self.config)))
        protagonist = protocol.pb_get_varint(bytes.fromhex(self.session.save["protagonist_snapshot"]), 1)
        slot = next(i for i, v in enumerate(team[:7]) if v != protagonist)
        original = team[slot]
        team[slot] = iid
        self.call(3703, [140, 2, *team])
        self.assertIn(iid, qiankun.protected(self.session.save))
        self.assertIn(iid, protocol.parse_ids_pb(self.call(3704)[0][16:]))
        request = protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, iid) + protocol.encode_pb_field(2, 0, (1 << 64) - 1))
        for opcode in (1035, 1037, 1039):
            self.assert_rejected(opcode, request)
        before = copy.deepcopy(self.session.save)
        with self.assertRaisesRegex(ValueError, "闲置"):
            gm._manage(self.session.save, "remove-general", {"iid": iid}, self.config, self.steps, NOW)
        self.assertEqual(self.session.save, before)
        team[slot] = original
        self.call(3703, [140, 2, *team])
        self.assertNotIn(iid, qiankun.protected(self.session.save))

    def test_selected_pet_recomputes_only_battle_copy_and_is_protected_from_rebirth(self):
        self.session.handle(1040, 400, b"")
        self.call(1049, [91001])
        self.call(1043, [self.session.save["pet_state"]["pets"][0][0]])
        self.call(1048)
        active = pets.get_state(self.session.save, self.config)["active"]
        self.assertGreater(active, 0)
        team = self.team()[:8]
        before = copy.deepcopy(self.session.save)
        with_pet, _ = single_boss.project_team(before, team, self.config)
        team[7] = 0
        without_pet, _ = single_boss.project_team(before, team, self.config)
        self.assertIsNotNone(pets.combat(with_pet, self.config))
        self.assertIsNone(pets.combat(without_pet, self.config))
        delta = {k: int(v) - int(pets.attributes(without_pet, self.config)[k]) for k, v in pets.attributes(with_pet, self.config).items()}
        a = formation.records(bytes.fromhex(with_pet["world_state"]["1002"]), 1, 2)
        b = formation.records(bytes.fromhex(without_pet["world_state"]["1002"]), 1, 2)
        for iid in team[:7]:
            if iid:
                for field, value in delta.items():
                    self.assertEqual((protocol.pb_get_varint(a[iid], field) or 0) - (protocol.pb_get_varint(b[iid], field) or 0), value)
        self.assertEqual(self.session.save, before)
        state = pets.get_state(self.session.save, self.config)
        state["pets"][0][2] = 1
        self.call(1043, [0])
        self.assert_rejected(1065, recharge.ids([active]))

    def test_current_equipment_stones_relations_and_training_are_not_stacked_or_saved(self):
        original = self.team()[:8]
        before = copy.deepcopy(self.session.save)
        current, _ = single_boss.project_team(before, original, self.config)
        old = formation.records(bytes.fromhex(before["world_state"]["1002"]), 1, 2)
        new = formation.records(bytes.fromhex(current["world_state"]["1002"]), 1, 2)
        for iid in original[:7]:
            if iid:
                self.assertEqual(old[iid], new[iid])
        changed = list(original)
        changed[0], changed[1] = changed[1], changed[0]
        rearranged, _ = single_boss.project_team(before, changed, self.config)
        shuffled = formation.records(bytes.fromhex(rearranged["world_state"]["1002"]), 1, 2)
        for iid in original[:7]:
            if iid:
                self.assertEqual(old[iid], shuffled[iid])
        self.assertEqual(self.session.save, before)

    def test_first_rewards_are_lifetime_and_only_normal_drops_double_on_thursday(self):
        save = self.session.save
        row = self.config["personalboss_att"]["33001"]
        day = (NOW + 28800) // 86400
        normal = single_boss.prizes(save, row, False, self.config, day, random.Random(7))
        double = single_boss.prizes(save, row, False, self.config, day + 2, random.Random(7))
        first = single_boss.prizes(save, row, True, self.config, day + 2, random.Random(7))
        self.assertEqual(double, {cid: n * 2 for cid, n in normal.items()})
        for entry in row["firstDrop"].strip(";").split(";"):
            cid, count = map(int, entry.split(","))
            self.assertEqual(first[cid] - double.get(cid, 0), count)
        self.team()
        self.strong()
        self.call(3701, [33001])
        self.clock.return_value = NOW + 2 * 86400
        self.assertEqual(self.query()[3], 33001)
        self.assertEqual(self.query()[0], 0)
        self.assertEqual(self.report(self.call(3701, [33002]))["result"], True)
        self.clock.return_value = NOW + 3 * 86400
        self.assertEqual(self.query()[3], 0)
        self.team(2)
        self.call(3701, [33101])
        self.assertEqual(self.session.save["single_boss_state"]["cleared"], {"1": 2, "2": 1})

    def test_batch_stops_on_real_loss_and_failed_save_is_atomic(self):
        self.team()
        self.strong()
        self.call(3701, [33001])
        self.session.save["role_state"].update(level=80, vip=25)
        self.call(301, [6, 3, 600])
        before, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
            self.call(3705, [33001, 3])
        self.assertEqual((self.session.save, self.path.read_bytes()), (before, disk))
        self.session = self.reconnect()
        self.strong(weak=True)
        packets = self.call(3705, [33001, 3])
        counts = next(v for n, w, v in protocol.iter_pb_fields(packets[0][16:]) if (n, w) == (12, 2))
        self.assertEqual(protocol.parse_ids_pb(counts), [1, 0])
        self.assertEqual(self.query()[0], 1)

    def test_corrupt_history_fails_before_day_reset_and_reward_overflow_rolls_back(self):
        self.team()
        baseline = copy.deepcopy(self.session.save)
        for changes in ({"used": True}, {"bought": 100}, {"used": 2}, {"cleared": {"1": 51, "2": 0}},
                        {"teams": {"1": [0] * 8, "2": None}}, {"teams": {"1": [9999] * 8, "2": None}}):
            data = copy.deepcopy(baseline)
            data["single_boss_state"].update(changes)
            self.path.write_text(json.dumps(data))
            disk = self.path.read_bytes()
            self.clock.return_value = NOW + 86400
            with self.assertRaises(ValueError):
                self.reconnect()
            self.assertEqual(self.path.read_bytes(), disk)
        self.path.write_text(json.dumps(baseline))
        self.clock.return_value = NOW
        self.session = self.reconnect()
        self.strong()
        self.clock.return_value = NOW + 86400
        self.query()
        self.team(2)
        player.change_item_count(self.session.save, 91003, (1 << 31) - 1, self.config, NOW + 86400)
        self.assert_rejected(3701, recharge.ids([33101]))

    def combat_case(self, cycle, *, rounds=1, passive=0, aura=False, speed=1000, queen=False):
        team = self.team()[:8]
        attack, defense, config, _, _ = single_boss.rosters(self.session.save, team, self.config["personalboss_att"]["33004"], self.config)
        template = dict(next(iter(attack.values())), advance=0, atk=1000, hp=10000, speed=1,
                        critical=0, dodge=0, parry=0, arp=0, resilience=0, hit=0, criticaldmg=0, initial_ap=2, **{"def": 0})
        attack = {p: dict(template, iid=i + 1) for i, p in enumerate((2, 4, 8))}
        if queen:
            attack[8].update(cid=10595, skill=0)
        cid, skill = str(template["cid"]), str(template["skill"])
        config = {**config, "general": {**config["general"], cid: dict(config["general"][cid], combskillid=0)},
                  "skill": {**config["skill"], skill: dict(config["skill"][skill], ap=100)}}
        boss = dict(defense[2], atk=100, hp=1000000, speed=speed, boss_cycle=cycle, boss_aura=aura,
                    boss_passive=passive, cover_d=0, adddmgpct=0, **{"def": 100})
        inputs = copy.deepcopy((attack, {2: boss}, config))
        report = battle.simulate(attack, {2: boss}, config, 7, max_rounds=rounds)
        self.assertEqual((attack, {2: boss}, config), inputs)
        self.assertEqual(report, battle.simulate(attack, {2: boss}, config, 7, max_rounds=rounds))
        return report

    def test_boss_fixed_half_hp_single_execute_all_execute_and_ap_only_actions(self):
        report = self.combat_case([12642])
        action = next(a for a in report["b"]["a"] if a["s"].get("S") == 12642)
        self.assertEqual([(e["p"], e["m"]["m"]) for e in action["e"]], [(2, 5000), (4, 5000)])
        self.assertEqual(report["endmeta"]["attack"]["8"]["h"], 10000)
        report = self.combat_case([12640])
        self.assertEqual([v["h"] for v in report["endmeta"]["attack"].values()], [0, 10000, 10000])
        report = self.combat_case([12647])
        self.assertFalse(report["result"])
        self.assertTrue(all(v["h"] == 0 for v in report["endmeta"]["attack"].values()))
        report = self.combat_case([12644])
        action = next(a for a in report["b"]["a"] if a["s"].get("S") == 12644)
        self.assertEqual([e["ap"] for e in action["e"]], [1, 1, 1])
        self.assertTrue(all(v["h"] == 10000 for v in report["endmeta"]["attack"].values()))

    def test_boss_row_damage_self_sacrifice_aura_and_permanent_defense_are_exact(self):
        report = self.combat_case([12641])
        action = next(a for a in report["b"]["a"] if a["s"].get("S") == 12641)
        self.assertEqual([(e["p"], e["m"]["m"], e["ap"]) for e in action["e"]], [(2, 148, 1), (4, 148, 1)])
        self.assertTrue(any(e.get("m", {}).get("m") == 10000 and not e["r"] for a in report["b"]["a"] for e in a["e"] if isinstance(e.get("m"), dict)))
        report = self.combat_case([12646], rounds=2)
        damage = [a["e"][0]["m"]["m"] for a in report["b"]["a"] if a["s"].get("r") is True]
        self.assertEqual(damage, [886] * 3 + [867] * 3)
        report = self.combat_case([12644], aura=True)
        damage = [a["e"][0]["m"]["m"] for a in report["b"]["a"] if a["s"].get("r") is True]
        self.assertEqual(damage, [105] * 3)

    def test_two_action_stun_cycles_and_lubu_round_start_growth_are_real(self):
        report = self.combat_case([12645, 12644, 12644], rounds=3)
        stun = next(a for a in report["b"]["a"] if a["s"].get("S") == 12645)["e"][0]
        self.assertEqual(stun["u"], {"u": "dizzy", "w": True})
        self.assertEqual(stun["m"]["m"], 100)
        turns = [a for a in report["b"]["a"] if a["s"].get("r") is True and a["s"]["p"] == [stun["p"]]]
        self.assertEqual(len(turns), 1)  # 被命中当轮尚未行动，跳过当轮和下一轮。
        report = self.combat_case([12643], rounds=2, passive=12648)
        damage = [a["e"][0]["m"]["m"] for a in report["b"]["a"] if a["s"].get("S") == 12643]
        self.assertEqual(damage, [19, 38])  # 120×0.3/19逐段取整，再到140×0.3/19。
        self.assertEqual(len([a for a in report["b"]["a"] if a["s"].get("S") == 12648]), 2)

    def test_boss_damage_still_triggers_surviving_queen_recovery_not_fixed_wins(self):
        report = self.combat_case([12642], queen=True)
        self.assertEqual([v["h"] for v in report["endmeta"]["attack"].values()], [5520, 5520, 10000])
        self.assertFalse(report["result"])

    def test_boss_skill_seal_skips_action_without_advancing_configured_cycle(self):
        team = self.team()[:8]
        _, defense, config, _, _ = single_boss.rosters(self.session.save, team, self.config["personalboss_att"]["33004"], self.config)
        combo = config["combskill"]["13124"]
        attack = {}
        for index, cid in enumerate(combo[f"cid{i}"] for i in (1, 2, 3) if combo[f"cid{i}"]):
            attack[battle.POSITIONS[index]] = {"cid": cid, "iid": index + 1, "level": 1, "advance": 0, "skilllevel": 0,
                "skill": config["general"][str(cid)]["skillid"], "atk": 1000, "def": 0, "hp": 1000000, "speed": 1000 - 100 * index,
                "initial_ap": 4 if index == 0 else 0, **dict.fromkeys(("critical", "dodge", "parry", "resilience", "hit", "arp", "criticaldmg"), 0)}
        defense[2].update(hp=1000000, atk=1, speed=1, boss_cycle=[12644, 12645], cover_d=0, **{"def": 0})
        config = {**config, "combskillprobability": {**config["combskillprobability"], "13124": dict.fromkeys((f"bout{i}" for i in range(1, 11)), 1)}}
        report = battle.simulate(attack, defense, config, 7, max_rounds=2)
        casts = [a["s"]["S"] for a in report["b"]["a"] if a["s"].get("r") is False and "S" in a["s"]]
        self.assertEqual(casts, [12644])

    @classmethod
    def client_scripts(cls):
        if not hasattr(cls, "_client_scripts"):
            with redirect_stdout(io.StringIO()):
                encrypted = builder.get_patched_lua_scripts()
            cls._client_scripts = {}
            for name, raw in encrypted.items():
                data = builder.xxtea_decrypt(raw, builder.XXTEA_KEY)
                cls._client_scripts[name] = data[:struct.unpack("<I", data[-4:])[0]]
        return cls._client_scripts

    def test_actual_network_lua_formation_query_battle_batch_and_quoted_purchase(self):
        import test_activity_copy
        lua = test_activity_copy.ActivityCopyTests.network_lua(self)
        scripts = self.client_scripts()
        lua.execute(builder.read_script("params_pb", "pb"))
        code = builder.read_script("gamedata").decode().replace("\r\n", "\n")
        for first, last in (("SingleBoss", "Cornucopia"), ("CommonSlots", "SetSlotsEnemy")):
            lua.execute(code[code.index(f"function gamedata.{first}("):code.index(f"function gamedata.{last}(")].encode())
        lua.execute(b'''gamedata.cache.singleBoss={};gamedata.cache.vipstatus={personalboss_times=0}
            gamedata.cache.commonSlots={};gamedata.cache.generals={};gamedata.cache.protagonist={general={}}
            gamedata.cache.petsdata={pets={}};gamedata.cache.role.gold=10000
            gamedata.updateRoleGold=function(self,n) self.cache.role.gold=self.cache.role.gold+n end''')
        for name in ("GameSingleBoss", "GameSlotArrange", "GameRecharge"):
            lua.execute(scripts[f"assets/scripts/{name}.so"])
        self.assertIsNone(lua.globals().gameConfig)
        request = lua.table_from({b"param": b"noupdate"})
        self.assertEqual(lua.globals().UISingleBossQuaryCallback(request), (1, 3700, None))
        lua.globals().NetSingleBossQuaryCallback(lua.table_from({b"rbuf": self.call(3700)[0][16:]}))
        mode, mid, body = lua.globals().UISlotsArrangeQuaryCallback(lua.table_from({b"id": 140, b"param": 1}))
        self.assertEqual((mode, mid, body), (1, 3702, recharge.ids([140, 1])))
        response = lua.globals().NetSlotsArrangeQuaryCallback(lua.table_from({b"rbuf": self.call(3702, [140, 1])[0][16:]}))
        self.assertGreater(response[b"slots"][b"power"], 0)
        self.assertEqual(lua.globals().UISlotsArrangeQuaryCallback(lua.table_from({b"id": 140, b"param": 1}))[0], 1)
        team = self.team()[:8]
        mode, mid, body = lua.globals().UISlotsArrangeCallback(lua.table_from({b"param": lua.table_from({b"id": 140, b"param": 2}),
            b"generals": lua.table_from({str(i).encode(): iid for i, iid in enumerate(team[:7], 1)}), b"pet": team[7]}))
        self.assertEqual((mode, mid, body), (1, 3703, recharge.ids([140, 2, *team])))
        lua.globals().NetSlotsArrangeCallback(lua.table_from({b"rbuf": self.call(3703, [140, 2, *team])[0][16:]}))
        self.strong()
        lua.globals().UISingleBossBattleCallback(lua.table_from({b"id": 33001}))
        result = lua.globals().NetSingleBossBattleCallback(lua.table_from({b"rbuf": self.call(3701, [33001])[0][16:]}))
        self.assertEqual(result[b"result"], 1)
        self.assertTrue(json.loads(result[b"battlereport"])["result"])
        _, mid, body = lua.globals().UIUserBuyCallBack(lua.table_from({b"cid": 6, b"count": 1, b"gold": 200}))
        self.assertEqual((mid, protocol.parse_ids_pb(body)), (301, [6, 1, 200]))
        lua.globals().NetUserBuyCallBack(lua.table_from({b"rbuf": self.call(301, [6, 1, 200])[0][16:]}))
        self.assertEqual(lua.globals().gamedata[b"cache"][b"role"][b"gold"], 9800)
        self.session.save["role_state"]["level"] = 80
        result = lua.globals().NetKingManOnekeyChallengeCallback(lua.table_from({b"rbuf": self.call(3705, [33001, 1])[0][16:]}))
        self.assertEqual((result[b"attempts"], result[b"wins"]), (1, 1))

    def test_all_100_configurations_and_nine_specials_convert_actual_animation_assets(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("实际APK动画验证需要本机已有lupa.lua51")
        lua = LuaRuntime()
        config = dict(self.config)
        with zipfile.ZipFile(ROOT / "configs_sec5.zip") as archive:
            for name in ("generalanimation", "skillanimation"):
                config[name] = json.loads(archive.read("5/" + name + ".json"))
        lua.globals().gamedata = lua.table_from({"config": config}, recursive=True)
        lua.execute('''print=function() end;printT=print;battleScene={slotNum=7}
            table.getTableLength=function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
            CCFileUtils={sharedFileUtils=function(self) return self end,fullPathForFilename=function(self,p) return p end}
            ui={Split=function(s,sep) local t={} for v in string.gmatch(s,'[^'..sep..']+') do t[#t+1]=v end return t end}''')
        lua.execute(self.client_scripts()["assets/scripts/battleReportConvert.so"])
        lua.execute(builder.read_script("BattleReportAbbToKey"))
        team = self.team()[:8]
        seen = set()
        before = copy.deepcopy(self.session.save)
        with zipfile.ZipFile(builder.SRC_APK) as archive:
            names, assets = archive.namelist(), {}
            lua.globals().CCFileUtils.isFileExist = lambda _, path: any(n.endswith("/" + path) for n in names)
            def load_asset(path):
                if path not in assets:
                    matches = [n for n in names if n.endswith("/" + path)]
                    self.assertEqual(len(matches), 1, path)
                    assets[path] = json.loads(archive.read(matches[0]))
                return lua.table_from(assets[path], recursive=True)
            lua.globals().LoadJsonFileToTable = load_asset
            for row in sorted(config["personalboss_att"].values(), key=lambda r: r["id"]):
                attack, defense, combat, pet, _ = single_boss.rosters(before, team, row, config)
                for unit in attack.values():
                    unit.update(atk=1, hp=1000000000, speed=1, advance=0)
                report = battle.simulate(attack, defense, combat, 7, attack_pet=pet)
                seen.update(a["s"].get("S") for a in report["b"]["a"] if a["s"].get("r") is False)
                native = lua.table_from(json.loads(lua.globals().ReplaceAbbToKey(json.dumps(report))), recursive=True)
                atk, enemy = lua.globals().getBattleInitSlotInfo(native)
                animations, ext = lua.globals().convertBattleReportToAnimationSub(native, atk, enemy, None, "singleboss")
                self.assertGreater(len(animations), 1)
                for side, key in (("attack", "atk"), ("defense", "def")):
                    for pos, unit in report["endmeta"][side].items():
                        self.assertEqual((ext.endinfo[key][pos].hp, ext.endinfo[key][pos].ap), (unit["h"], unit["ap"]), (row["id"], side, pos))
                for seed in (1, 7):
                    prizes = single_boss.prizes(before, row, True, config, (NOW + 28800) // 86400, random.Random(seed))
                    self.assertTrue(prizes)
                    activities_reward = ";".join(f"{cid},{n}" for cid, n in prizes.items() if n)
                    activities.build_reward(before, activities_reward, config)
        self.assertTrue(set(range(12640, 12649)) <= seen, seen)
        self.assertEqual(self.session.save, before)

    def test_packaged_buttons_query_real_formation_select_difficulty_and_unlock_batch(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("实际APK界面验证需要本机已有lupa.lua51")
        lua = LuaRuntime()
        config = dict(self.config)
        with zipfile.ZipFile(ROOT / "configs_sec5.zip") as archive:
            config["generalanimation"] = json.loads(archive.read("5/generalanimation.json"))
        lua.globals().gamedata = lua.table_from({"config": config}, recursive=True)
        lua.globals().now = NOW
        lua.execute('''print=function() end;printT=print
            local function widget()
                return setmetatable({}, {__index=function(t,k)
                    if k=="addHandleOfControlEvent" then return function(self,f) self.callback=f end end
                    if k=="setVisible" then return function(self,v) self.visible=v end end
                    return function() end
                end})
            end
            CCBReaderLoad=function() return widget(),setmetatable({}, {__index=function(t,k) local n=widget() t[k]=n return n end}) end
            CCSkeletonAnimation={create=function() return widget() end}
            gamedata.config.getConfigByName=function(self,k) return self[k] end
            gamedata.time=function() return now end
            ui={setLabelString=function(n,s) n.text=s end,addGray=function() end,removeGray=function() end,setNewIconName=function() end}
            setSpriteFrameByName=function() end
            ccc3=function(r,g,b) return {r=r,g=g,b=b} end
            GameScene={topposY=1620,roleinfo={level=27},vipstatus={personalboss_times=0}}
            requests={};UIRequest=function(t) requests[#requests+1]=t end
            opened={};gameWindows={windows={kingfoot={show=false},kingmanOnekeyChallenge={show=false}},
                openWindow=function(self,k,t) opened[#opened+1]={name=k,data=t} end,
                closeWindow=function(self,k) closed=k end}
            gameTouch={clickprofbytime=function() end};guide={}
            gameTimer={times={},rigistTime=function() end}
            CCUserDefault={sharedUserDefault=function() return {getStringForKey=function() return "3" end} end}
            CCControlEventTouchUpInside=1
            singlebossBuyTimes=function() buys=(buys or 0)+1 end
            runGamePrompt=function(t) prompt=t.msg end
            parent=widget()
        ''')
        scripts = self.client_scripts()
        layer = lua.execute(scripts["assets/scripts/Layer_singleBoss.so"])
        data = lua.table_from({"battlenum": 0, "bosstype": 1, "isFirst": 1, "openlevel": 0, "curblood": 100})
        layer.init(layer, lua.globals().parent, 1620, data)
        self.assertTrue(layer.rootItems.oneFinishBtn.visible)
        self.assertTrue(layer.rootItems.oneFinishText.visible)
        layer.rootItems.battlebtn.callback()
        self.assertEqual((lua.globals().requests[2].type, lua.globals().requests[2].id), (3702, 140))
        data.isFirst, data.openlevel = 0, 33001
        layer.rootItems.battlebtn.callback()
        self.assertEqual(lua.globals().opened[1].data.type, "kingselect")
        layer.reloadlv(layer, lua.table_from({"rolelv": 27, "viplv": 0}))
        layer.rootItems.oneFinishBtn.callback()
        self.assertIn("80", lua.globals().prompt)
        layer.reloadlv(layer, lua.table_from({"rolelv": 80, "viplv": 0}))
        layer.rootItems.oneFinishBtn.callback()
        self.assertEqual(lua.globals().opened[2].name, "kingmanOnekeyChallenge")
        data.battlenum = 1
        layer.reloadData(layer, data)
        layer.rootItems.battlebtn.callback()
        self.assertEqual(lua.globals().buys, 1)
        lua.globals().GameScene.layers = lua.table_from({"singleboss": {"show": True, "module": layer}}, recursive=True)
        lua.execute(scripts["assets/scripts/UIsingleBoss.so"])
        data.bought = 1
        lua.globals().UISingleBossQuary(lua.table_from({"boss": data, "rolelv": 80, "viplv": 0}))
        self.assertEqual(layer.battletimes, 1)
        lua.execute('showRewardPopupWindow=function() end')
        lua.globals().UIKingmanOnekeyChallengeBack(lua.table_from({"attempts": 1, "wins": 0}))
        last = lua.globals().requests[len(lua.globals().requests)]
        self.assertEqual(last.type, 3700)
        with zipfile.ZipFile(builder.SRC_APK) as archive:
            ccb = archive.read("assets/UI/kingman/kingman_rulai.ccbi")
            self.assertTrue(all(name.encode() in ccb for name in ("oneFinishBtn", "oneFinishText", "battlebtn", "slotbtn")))
        window = lua.execute(scripts["assets/scripts/window_kingmanOnekeyChallenge.so"])
        window.attConfigData = lua.globals().gamedata.config.personalboss_att
        window.rootItems = layer.rootItems
        window.reloaddata(window, lua.table_from({"boss": {"bosstype": 2, "openlevel": 33102, "battlenum": 0}}, recursive=True))
        self.assertEqual(window.bosstpye, 33102)
        window.reloaddata(window, lua.table_from({"boss": {"bosstype": 1, "openlevel": 0}}, recursive=True))
        self.assertEqual(lua.globals().closed, "kingmanOnekeyChallenge")

    def test_calendar_date_not_weekday_and_account_snapshots_are_isolated(self):
        first = self.team()
        self.strong()
        self.call(3701, [33001])
        own = copy.deepcopy(self.session.save)
        other_path = self.path.with_name("other.json")
        other_path.write_text(json.dumps(self.baseline))
        from zyj_server.session import Session
        other = Session(self.tables, other_path, self.steps, self.config)
        self.assertEqual(protocol.parse_ids_pb(other.handle(3700, 200, b"")[0][16:]), [0, 1, 1, 0, 100, 0])
        self.assertEqual(self.session.save, own)
        self.assertEqual(json.loads(self.path.read_text())["single_boss_state"], own["single_boss_state"])
        zone = datetime.timezone(datetime.timedelta(hours=8))
        for date, expected in (((2026, 12, 1), 2), ((2026, 12, 2), 2), ((2026, 12, 3), 1), ((2026, 12, 31), 1)):
            self.clock.return_value = int(datetime.datetime(*date, 12, tzinfo=zone).timestamp())
            self.assertEqual(self.query()[1], expected)
        self.assertEqual(self.team()[:8], first[:8])


if __name__ == "__main__":
    unittest.main()
