"""群仙屠龙闭环：临时多账号、真实HP/战报、邮件和故障恢复。"""

import copy
import json
import struct
import threading
import unittest
import zipfile
from unittest.mock import patch

import build_local_apk as builder
import test_friends
from zyj_server import achievements, formation, guild, mail, player, protocol, world_boss
from zyj_server.admin import gm


def setUpModule():
    test_friends.setUpModule()


class WorldBossTests(unittest.TestCase):
    request = test_friends.FriendsTests.request
    success = test_friends.FriendsTests.success
    records = test_friends.FriendsTests.records
    reconnect = test_friends.FriendsTests.reconnect
    client_scripts = classmethod(test_friends.FriendsTests.client_scripts.__func__)
    client_call = test_friends.FriendsTests.client_call
    add_account = test_friends.FriendsTests.add_account

    def setUp(self):
        test_friends.FriendsTests.setUp(self)
        self.day = (self.now + 28800) // 86400
        self.at()

    def at(self, days=0, hour=12, minute=0, second=0):
        self.clock.return_value = (self.day + days) * 86400 - 28800 + hour * 3600 + minute * 60 + second

    def shared(self):
        return json.loads((self.root / "world_boss.json").read_bytes())

    def period(self, kind="1"):
        return self.shared()["bosses"][kind]["period"]

    def query(self, account=1, kind=1):
        return self.success(account, 3400 if kind == 1 else 3410)

    def attack(self, account=1, kind=1, method=0, auto=0):
        raw = self.success(account, 3401 if kind == 1 else 3411, values=[method, auto])
        battle_body = self.records(raw, 6)[0]
        return raw, json.loads(self.records(battle_body, 5)[0])

    def assert_rejected(self, account, opcode, **kwargs):
        before = copy.deepcopy(self.sessions[account].save)
        disk = {a: self.store.path(a).read_bytes() for a in self.sessions}
        path = self.root / "world_boss.json"
        shared = path.read_bytes() if path.exists() else None
        self.assertEqual([mid for mid, _ in self.request(account, opcode, **kwargs)], [999999, 1999])
        self.assertEqual((self.sessions[account].save, {a: self.store.path(a).read_bytes() for a in self.sessions}), (before, disk))
        self.assertEqual(path.read_bytes() if path.exists() else None, shared)

    def mails(self, account=1):
        return {protocol.pb_get_varint(r, 1): r for r in self.records(self.success(account, 3100), 2)
                if 600000001 <= protocol.pb_get_varint(r, 1) < 700000000}

    def set_hp(self, hp, kind="1"):
        state = self.shared()
        state["bosses"][kind]["period"]["hp"] = hp
        world_boss.write(self.root / "world_boss.json", state)

    def test_windows_are_utc8_half_open_independent_and_never_backfill_missed_days(self):
        self.at(hour=11, minute=59, second=59)
        self.assertEqual(protocol.pb_get_varint(self.query(), 1), 0)
        self.assert_rejected(1, 3401, values=[0, 0])
        self.at()
        raw = self.query()
        self.assertEqual(protocol.pb_get_varint(raw, 1), 1)
        self.assertEqual(protocol.pb_get_varint(raw, 9), self.config["boss2"]["30001"]["hp"])
        self.assertEqual(protocol.pb_get_varint(self.query(kind=2), 1), 0)
        self.at(minute=30)
        self.assertEqual(protocol.pb_get_varint(self.query(), 1), 0)
        self.assert_rejected(1, 3401, values=[0, 0])
        self.at(hour=21)
        self.assertEqual(protocol.pb_get_varint(self.query(kind=2), 1), 1)
        self.assertEqual(self.mails(), {})
        self.at(10, 21)
        self.query(kind=2)
        self.assertEqual(self.period("2")["day"], self.day + 10)
        self.assertEqual(self.shared()["next_mail"], 600000001)

    def test_actual_loss_damages_shared_hp_counts_once_and_preserves_campaign_and_experience(self):
        before = copy.deepcopy(self.sessions[1].save)
        raw, report = self.attack()
        self.assertFalse(report["result"])
        damage = protocol.pb_get_varint(raw, 2)
        self.assertGreater(damage, 0)
        self.assertEqual(self.period()["hp"], self.config["boss2"]["30001"]["hp"] - damage)
        self.assertEqual(sum(r["h"] for r in report["endmeta"]["defense"].values()), self.period()["hp"])
        saved = self.sessions[1].save
        self.assertEqual(saved["achievement_state"]["counts"]["worldbosscount"], 1)
        self.assertIn(51501, saved["achievement_state"]["completed"])
        for key in ("exp", "level", "energy", "stamina"):
            self.assertEqual(saved["role_state"][key], before["role_state"][key])
        for key in ("1002", "1300"):
            self.assertEqual(saved["world_state"][key], before["world_state"][key])
        self.assertEqual(saved.get("last_battle"), before.get("last_battle"))
        self.assertEqual(saved["guide"], before["guide"])
        self.assertEqual(protocol.pb_get_varint(self.query(2), 9), self.period()["hp"])
        self.assertEqual(protocol.pb_get_varint(self.query(2), 7), 0)

    def test_strict_payload_level_auto_gate_and_comb_rejection_are_nonmutating(self):
        for opcode in world_boss.OPCODES:
            for raw in (b"\x08", b"\x10\x01", b"\x0a\x00", guild.ids([0, 0, 0])):
                self.assert_rejected(1, opcode, raw=raw)
        for values in ([], [0], [1, 0], [3, 0], [0, 2], [(1 << 64) - 1, 0], [0, (1 << 64) - 1]):
            self.assert_rejected(1, 3401, values=values)
        self.assert_rejected(1, 3401, values=[0, 1])
        self.sessions[1].save["role_state"]["level"] = 20
        self.assert_rejected(1, 3400)
        self.sessions[1].save["role_state"]["level"] = 31
        raw = protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 3401) + protocol.encode_pb_field(2, 2, guild.ids([0, 0])))
        self.assert_rejected(1, 999900, raw=raw)
        self.sessions[1].save["role_state"]["level"] = 45
        self.attack(auto=1)

    def test_cooldown_paid_revive_and_phoenix_use_actual_costs_and_do_not_reuse_mutations(self):
        gold = self.sessions[1].save["role_state"]["gold"]
        raw, _ = self.attack()
        self.assertEqual(protocol.pb_get_varint(raw, 4), 60)
        self.assert_rejected(1, 3401, values=[0, 0])
        self.attack(method=2)
        self.assertEqual(self.sessions[1].save["role_state"]["gold"], gold - 5)
        self.reconnect()
        self.assert_rejected(1, 3401, values=[0, 0])
        self.at(minute=1)
        self.assert_rejected(1, 3401, values=[2, 0])
        with patch.object(world_boss.secrets, "randbits", return_value=77):
            hp = self.period()["hp"]
            expected = world_boss.simulate(copy.deepcopy(self.sessions[1].save), 30001, hp, 10, self.config, 77)
            _, report = self.attack(method=10)
        self.assertEqual(report, json.loads(json.dumps(expected)))
        self.assertEqual(self.sessions[1].save["role_state"]["gold"], gold - 25)
        self.sessions[1].save["role_state"]["gold"] = 0
        self.assert_rejected(1, 3401, values=[10, 0])
        self.assert_rejected(1, 3401, values=[2, 0])

    def test_int64_totals_damage_ranks_and_native_self_rids_never_use_int32(self):
        self.query()
        state = self.shared()
        period = state["bosses"]["1"]["period"]
        period.update(cid=30120, hp=self.config["boss2"]["30120"]["hp"])
        world_boss.write(self.root / "world_boss.json", state)
        raw, _ = self.attack()
        self.assertEqual(protocol.pb_get_varint(raw, 10), self.config["boss2"]["30120"]["hp"])
        self.assertGreater(protocol.pb_get_varint(raw, 10), (1 << 31))
        state = self.shared()
        state["bosses"]["1"]["period"]["damage"]["1"]["amount"] = 1 << 40
        world_boss.write(self.root / "world_boss.json", state)
        own = self.records(self.success(1, 3402))[0]
        visitor = self.records(self.success(2, 3402))[0]
        self.assertEqual(protocol.pb_get_varint(own, 7), 1 << 40)
        self.assertEqual(protocol.pb_get_varint(own, 1), protocol.pb_get_varint(bytes.fromhex(self.sessions[1].save["role_snapshot"]), 1))
        self.assertEqual(protocol.pb_get_varint(visitor, 1), 1000001)

    def test_actual_last_hit_finishes_once_mails_rank_and_kill_rewards_and_advances_next_day(self):
        self.query()
        self.set_hp(1)
        raw, report = self.attack()
        self.assertTrue(report["result"])
        self.assertEqual((protocol.pb_get_varint(raw, 1), protocol.pb_get_varint(raw, 3)), (0, 1))
        self.assert_rejected(2, 3401, values=[0, 0])
        mails = self.mails()
        self.assertEqual(len(mails), 1)
        mid, mail = next(iter(mails.items()))
        items = json.loads(self.records(mail, 7)[0])
        self.assertEqual(items, {"1000": 650000, "20166": 25, "91004": 10})
        self.assertNotIn("192072", items)
        self.assertEqual(self.shared()["bosses"]["1"]["next_cid"], 30002)
        self.assert_rejected(1, 3102, values=[mid])
        self.success(1, 3101, values=[mid])
        self.reconnect()
        self.assert_rejected(1, 3101, values=[mid])
        self.success(1, 3102, values=[mid])
        self.assertEqual(self.mails(), {})
        self.at(1)
        self.query()
        self.assertEqual(self.period()["cid"], 30002)

    def test_timeout_mails_only_real_positive_damage_rank_and_never_backfills_participation(self):
        self.attack(2)
        self.attack(1)
        self.at(minute=30)
        peers = {a: self.store.path(a).read_bytes() for a in (2, 3)}
        self.assertEqual(len(self.mails()), 1)
        self.assertEqual({a: self.store.path(a).read_bytes() for a in (2, 3)}, peers)
        self.assertEqual(len(self.mails(2)), 1)
        self.assertEqual(self.mails(3), {})
        self.assertEqual(len(self.shared()["bosses"]["1"]["history"]["damage"]), 2)
        self.assertEqual(self.shared()["bosses"]["1"]["next_cid"], 30001)
        self.assertEqual(self.sessions[3].save.get("achievement_state", {}).get("counts", {}).get("worldbosscount", 0), 0)

    def test_same_connection_duplicate_and_concurrent_last_hit_are_exactly_once_within_live_state(self):
        self.query()
        self.set_hp(1)
        self.seq += 1
        raw = guild.ids([0, 0])
        session = self.sessions[1]
        packets = session.handle(3401, self.seq, raw)
        before = self.store.path(1).read_bytes(), (self.root / "world_boss.json").read_bytes()
        self.assertEqual(session.handle(3401, self.seq, raw), packets)
        self.assertEqual((self.store.path(1).read_bytes(), (self.root / "world_boss.json").read_bytes()), before)
        self.assertEqual(self.period()["damage"]["1"]["count"], 1)
        self.at(1)
        self.query()
        self.set_hp(1)
        results = []
        def hit(account):
            results.append(self.sessions[account].handle(3401, 9900, raw))
        threads = [threading.Thread(target=hit, args=(a,)) for a in (1, 2)]
        for thread in threads: thread.start()
        for thread in threads: thread.join()
        self.assertEqual(sorted(struct.unpack(">IIII", result[0][:16])[2] for result in results), [3401, 999999])
        self.assertEqual(len(self.period()["damage"]), 1)

    def test_save_and_publish_failures_recover_only_paid_same_identity_hp_and_counts(self):
        self.query()
        hp = self.period()["hp"]
        before, disk = copy.deepcopy(self.sessions[1].save), self.store.path(1).read_bytes()
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 3401, values=[10, 0])
        self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))
        self.assertIsNotNone(self.shared()["pending"])
        self.reconnect()
        self.query()
        self.assertEqual(self.period()["hp"], hp)
        original, calls = world_boss.write, 0
        def fail_publish(path, state):
            nonlocal calls
            calls += 1
            if calls == 2: raise OSError("publish")
            return original(path, state)
        with patch.object(world_boss, "write", side_effect=fail_publish), self.assertRaises(OSError):
            self.request(1, 3401, values=[10, 0])
        paid = json.loads(self.store.path(1).read_bytes())
        self.reconnect()
        self.query()
        self.assertLess(self.period()["hp"], hp)
        self.assertEqual(self.sessions[1].save["role_state"]["gold"], paid["role_state"]["gold"])
        self.assertEqual(self.period()["damage"]["1"]["count"], 1)

    def test_rollback_invalid_shared_missing_journal_and_broken_peer_fail_closed(self):
        self.attack()
        self.at(hour=11)
        self.assert_rejected(1, 3401, values=[10, 0])
        self.query()
        self.at()
        path = self.root / "world_boss.json"
        good = path.read_bytes()
        path.unlink()
        self.assert_rejected(1, 3400)
        path.write_bytes(b"{}")
        self.assert_rejected(1, 3400)
        path.write_bytes(good)
        self.store.path(2).write_bytes(b"{}")
        self.assert_rejected(1, 3400)

    def test_all_eight_participation_thresholds_read_only_actual_saved_counter(self):
        self.attack()
        for count in (1, 5, 10, 20, 50, 80, 100, 180):
            save = copy.deepcopy(self.sessions[1].save)
            save["achievement_state"]["counts"]["worldbosscount"] = count
            view = achievements.snapshot(save, self.config)
            for row in (r for r in self.config["task"].values() if r["type"] == "worldbosscount"):
                self.assertEqual(achievements.progress(row, view), (count, count >= int(row["target"])))
        self.success(1, 2401, values=[51501])
        self.reconnect()
        self.assert_rejected(1, 2401, values=[51501])

    def test_both_bosses_have_separate_counts_notifications_and_configured_drops(self):
        first, _ = self.attack()
        before = self.period()
        self.at(hour=21)
        second, _ = self.attack(kind=2)
        self.assertEqual(protocol.pb_get_varint(first, 7), 1)
        self.assertEqual(protocol.pb_get_varint(second, 7), 1)
        self.assertEqual(self.period("2")["cid"], 31001)
        self.assertEqual(self.period()["damage"], before["damage"])
        self.assertEqual(self.sessions[1].save["achievement_state"]["counts"]["worldbosscount"], 2)
        for opcode, kind in ((3403, "1"), (3413, "2")):
            raw = self.success(2, opcode)
            rows = self.records(raw)
            self.assertEqual(len(rows), 1)
            self.assertEqual(protocol.pb_get_varint(rows[0], 5), self.period(kind)["damage"]["1"]["amount"])
            self.assertEqual(protocol.pb_get_varint(raw, 2), self.period(kind)["hp"])
        self.assertNotEqual(self.period()["events"][0]["id"], self.period("2")["events"][0]["id"])
        self.assertGreater(len(self.mails()), 0)

    def test_recreated_role_does_not_inherit_mail_cooldown_rank_or_old_identity_receipt(self):
        self.query()
        self.set_hp(1)
        self.attack()
        self.assertEqual(len(self.mails()), 1)
        save = copy.deepcopy(test_friends.test_guild.SAVE)
        save.update(created_at=self.now + 1, role_name="重建角色")
        save["role_state"].update(level=31)
        player.save_role(save, self.store.path(1), test_friends.test_guild.COUNTS)
        self.reconnect()
        self.assertEqual(self.mails(), {})
        self.query()
        self.assertEqual(self.shared()["players"]["1"]["mails"], {})
        self.assertEqual(self.sessions[1].save.get("achievement_state", {}).get("counts", {}).get("worldbosscount", 0), 0)
        self.at(1)
        self.attack()
        self.assertEqual(self.period()["damage"]["1"]["count"], 1)

    def test_test_account_copy_keeps_mail_open_and_never_inherits_or_regrants_world_boss_mail(self):
        self.query()
        self.set_hp(1)
        self.attack()
        source_mid = next(iter(self.mails()))
        self.add_account(10)
        for account in (1, 10):
            self.store.close_session(account)
        source, shared = self.store.path(1).read_bytes(), (self.root / "world_boss.json").read_bytes()
        workbench = gm.Workbench(self.store)
        workbench.transfer(1)
        self.assertEqual(self.store.path(1).read_bytes(), source)
        self.assertEqual((self.root / "world_boss.json").read_bytes(), shared)
        self.reconnect(1)
        self.reconnect(10)
        self.assertEqual(set(self.mails()), {source_mid})
        self.assertEqual(self.mails(10), {})
        self.query(10)
        self.at(1)
        self.query(10)
        self.set_hp(1)
        self.attack(10)
        target_mid = next(iter(self.mails(10)))
        self.success(10, 3101, values=[target_mid])
        gm_mid = mail.send_mail(self.root / "mails.json", 10, "测试号邮件", "不重复领取", {"1001": 3}, now=int(self.clock.return_value))["id"]
        self.success(10, 3101, values=[gm_mid])
        for account in (1, 10):
            self.store.close_session(account)
        workbench.transfer(1)
        self.reconnect(1)
        self.reconnect(10)
        self.assertEqual(protocol.pb_get_varint(self.mails(10)[target_mid], 4), 2)
        self.assert_rejected(10, 3101, values=[target_mid])
        self.assert_rejected(10, 3101, values=[gm_mid])
        self.assertEqual(protocol.pb_get_varint(self.mails()[source_mid], 4), 0)

    def test_copy_drops_source_friend_cup_and_exam_bindings_without_breaking_real_queries(self):
        self.success(1, 2302, values=[1000002])
        self.success(1, 2100)
        self.success(1, 7003, values=[1])
        self.query()
        names = ("friend_state", "cup_state", "examination_state", "world_boss_state")
        source = self.sessions[1].save
        self.assertTrue(all(name in source for name in names))
        self.add_account(10)
        for account in (1, 10):
            self.store.close_session(account)
        gm.Workbench(self.store).transfer(1)
        self.reconnect(1)
        self.reconnect(10)
        self.assertTrue(all(name not in self.sessions[10].save for name in names))
        for opcode in (2300, 2100, 7002, 3400, 3100):
            for account in (1, 10):
                with self.subTest(opcode=opcode, account=account):
                    self.success(account, opcode)
        self.assertEqual(self.sessions[1].save["examination_state"]["records"], source["examination_state"]["records"])
        self.assertNotIn("examination_state", self.sessions[10].save)

    def test_mail_claim_save_failure_all_claim_delete_and_peer_isolation(self):
        self.attack(1)
        self.attack(2)
        self.at(minute=30)
        mid = next(iter(self.mails()))
        disk = self.store.path(1).read_bytes()
        shared = (self.root / "world_boss.json").read_bytes()
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 3101, values=[mid])
        self.assertEqual(self.store.path(1).read_bytes(), disk)
        self.assertEqual((self.root / "world_boss.json").read_bytes(), shared)
        self.assertEqual(protocol.pb_get_varint(self.mails()[mid], 4), 0)
        peer = self.store.path(2).read_bytes()
        self.success(1, 3101, values=[(1 << 64) - 1])
        self.assertEqual(self.store.path(2).read_bytes(), peer)
        self.assertEqual(protocol.pb_get_varint(self.mails()[mid], 4), 2)
        self.success(1, 3102, values=[(1 << 64) - 1])
        self.assertEqual(self.mails(), {})
        self.assertEqual(len(self.mails(2)), 1)

    def test_zero_damage_loss_counts_participation_but_has_no_drop_or_rank_mail(self):
        self.config["boss2"]["30001"]["ap"] = 4
        for raw in formation.records(bytes.fromhex(self.sessions[1].save["world_state"]["1002"]), 1, 2).values():
            raw = protocol.pb_set_varint(protocol.pb_set_varint(raw, 8, 1), 9, 1)
            player.record_slot_update(self.sessions[1].save, protocol.encode_pb_field(1, 2, raw))
        raw, report = self.attack()
        self.assertFalse(report["result"])
        self.assertEqual(protocol.pb_get_varint(raw, 2), 0)
        self.assertTrue(all(w == 2 and v == b"" for _, w, v in protocol.iter_pb_fields(self.records(self.records(raw, 6)[0], 4)[0])))
        self.assertEqual(self.sessions[1].save["achievement_state"]["counts"]["worldbosscount"], 1)
        self.at(minute=30)
        self.assertEqual(self.mails(), {})

    def test_unsupported_roster_and_skill_never_charge_or_publish_a_partial_attack(self):
        raw = next(iter(formation.records(bytes.fromhex(self.sessions[1].save["world_state"]["1002"]), 1, 2).values()))
        player.record_slot_update(self.sessions[1].save, protocol.encode_pb_field(1, 2, protocol.pb_set_varint(raw, 21, 1)))
        self.assert_rejected(1, 3401, values=[10, 0])
        player.record_slot_update(self.sessions[1].save, protocol.encode_pb_field(1, 2, raw))
        self.config["boss2"]["30001"]["skillid"] = 999999
        self.assert_rejected(1, 3401, values=[10, 0])

    def test_shared_draft_failure_and_killing_publish_failure_never_double_mint_mails(self):
        self.query()
        self.set_hp(1)
        disk = self.store.path(1).read_bytes()
        shared = (self.root / "world_boss.json").read_bytes()
        with patch.object(world_boss, "write", side_effect=OSError("draft")), self.assertRaises(OSError):
            self.request(1, 3401, values=[10, 0])
        self.assertEqual((self.store.path(1).read_bytes(), (self.root / "world_boss.json").read_bytes()), (disk, shared))
        original, calls = world_boss.write, 0
        def fail_publish(path, state):
            nonlocal calls
            calls += 1
            if calls == 2: raise OSError("publish")
            return original(path, state)
        with patch.object(world_boss, "write", side_effect=fail_publish), self.assertRaises(OSError):
            self.request(1, 3401, values=[10, 0])
        self.reconnect()
        self.query(2)
        mid = next(iter(self.mails()))
        self.assertEqual(len(self.mails()), 1)
        self.success(1, 3101, values=[mid])
        self.reconnect()
        self.assert_rejected(1, 3101, values=[mid])

    def test_tied_real_damage_ranks_by_account_and_only_first_500_get_configured_buckets(self):
        state = world_boss.load(self.root / "world_boss.json", {}, int(self.clock.return_value))
        saves = {}
        for account in range(1, 503):
            save = copy.deepcopy(self.sessions[1].save)
            save["created_at"] = self.now - account
            saves[account] = save
            state["players"][str(account)] = {"identity": save["created_at"], "mails": {}}
        world_boss.settle(state, saves, self.config, int(self.clock.return_value))
        period = state["bosses"]["1"]["period"]
        from zyj_server import friends
        period["damage"] = {str(a): {"identity": s["created_at"], "profile": friends.player_body(a, -1, saves).hex(),
            "amount": 1, "count": 1, "ready_at": int(self.clock.return_value) + 60} for a, s in saves.items()}
        world_boss.finish(state, "1", saves, self.config, world_boss.times(self.day, "1")[1])
        world_boss.validate(state)
        self.assertEqual([a for a, _ in world_boss.ranks(period)], list(range(1, 503)))
        self.assertEqual(sum(bool(r["mails"]) for r in state["players"].values()), 500)
        self.assertEqual(state["players"]["501"]["mails"], {})
        first = next(iter(state["players"]["1"]["mails"].values()))
        self.assertEqual(world_boss.pairs(first["reward"])[1000], 250000)

    def network_lua(self, account=1):
        lua = test_friends.FriendsTests.network_lua(self, account)
        for name in ("worldboss1_pb", "worldboss1rank_pb", "worldboss1realnotify_pb"):
            lua.execute(builder.read_script(name, "pb"))
        code = builder.read_script("gamedata").decode().replace("\r\n", "\n")
        for start, end in (("function gamedata.playerwithgeneralsdata(", "function gamedata.gangbroadcastsData("),
                           ("function gamedata.WorldBossData(", "function gamedata.GuildWarInspire("),
                           ("function gamedata.propData(", "function gamedata.generalfragmentData("),
                           ("function gamedata.updatePetsFragment(", "function gamedata.setPetData("),
                           ("function gamedata.updateRoleCoin(", "function gamedata.updateRoleExp(")):
            lua.execute(code[code.index(start):code.index(end)].encode())
        lua.execute(b'''gamedata.cache.worldboss={};gamedata.cache.worldboss2={}
            gamedata.cache.worldbossrank={};gamedata.cache.worldbossrank2={}
            gamedata.cache.props={};gamedata.cache.petsfragment={}
            gamedata.time=function() return clock end''')
        lua.globals().clock = int(self.clock.return_value)
        lua.execute(self.client_scripts()["assets/scripts/GameWorldBoss.so"])
        return lua

    def test_actual_native_pb_callbacks_keep_int64_and_bool_requests_numeric_and_separate_caches(self):
        lua = self.network_lua()
        query = self.client_call(lua, 1, "UIWorldBoss1QueryCallBack", "NetWorldBoss1QueryCallBack", {"view": 4, "page": b"onepage"})
        self.assertEqual((query[b"view"], query[b"worldboss"][b"status"]), (4, 1))
        self.assertGreater(query[b"worldboss"][b"bosslevel"], 1 << 31)
        gold = lua.globals().gamedata[b"cache"][b"role"][b"gold"]
        req = lua.table_from({b"view": 4, b"page": b"onepage", b"method": 10, b"isauto": False})
        mode, opcode, raw = lua.globals().UIWorldBoss1AttackCallBack(req)
        self.assertEqual((mode, protocol.parse_ids_pb(raw)), (1, [10, 0]))
        result = lua.globals().NetWorldBoss1AttackCallBack(lua.table_from({b"rbuf": self.success(1, opcode, raw=raw)}))
        self.assertEqual(result[b"view"], 4)
        self.assertTrue(result[b"battlereport"])
        self.assertEqual(lua.globals().gamedata[b"cache"][b"role"][b"gold"], gold - 20)
        self.assertEqual(lua.globals().gamedata[b"cache"][b"worldboss"][b"attackcount"], 0)
        self.client_call(lua, 1, "UIWorldBoss1QueryCallBack", "NetWorldBoss1QueryCallBack", {"view": 4, "page": b"onepage"})
        self.assertEqual(lua.globals().gamedata[b"cache"][b"worldboss"][b"attackcount"], 1)
        other = self.client_call(lua, 1, "UIWorldBoss2QueryCallBack", "NetWorldBoss2QueryCallBack", {"view": 5, "page": b"twopage"})
        self.assertEqual((other[b"page"], other[b"worldboss"][b"status"], other[b"worldboss"][b"attackcount"]), (b"twopage", 0, 0))
        self.assertIsNone(lua.globals().gameConfig)

    def test_actual_network_fifo_busy_errors_live_history_and_notify_cursor(self):
        lua = self.network_lua()
        pending = []
        for view in (4, 6):
            req = lua.table_from({b"view": view, b"page": b"onepage"})
            mode, opcode, raw = lua.globals().UIWorldBoss1QueryCallBack(req)
            self.assertEqual(mode, 1)
            pending.append(self.success(1, opcode, raw=raw or b""))
        self.assertEqual(lua.globals().UIWorldBoss1QueryCallBack(req)[0], 0)
        for view, raw in zip((4, 6), pending):
            self.assertEqual(lua.globals().NetWorldBoss1QueryCallBack(lua.table_from({b"rbuf": raw}))[b"view"], view)
        mode, opcode, raw = lua.globals().UIWorldBoss1AttackCallBack(lua.table_from({b"method": 0, b"isauto": True}))
        self.assertEqual(protocol.parse_ids_pb(raw), [0, 1])
        self.assertEqual(lua.globals().UIWorldBoss2AttackCallBack(lua.table_from({b"method": 0}))[0], 0)
        lua.globals().NetErrorMessageCallback9(lua.table_from({b"rbuf": guild.ids([opcode, 0])}))
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localWorldBossBusy"])
        self.attack()
        for count in (1, 0):
            result = self.client_call(lua, 1, "UIWorldBoss1RealNotifyCallBack", "NetWorldBoss1RealNotifyCallBack", {"view": 6, "page": b"onepage"})
            self.assertEqual(len(result[b"infos"]), count)
        self.at(minute=30)
        result = self.client_call(lua, 1, "UIWorldBoss1PreRankCallBack", "NetWorldBoss1PreRankCallBack", {"view": 6, "page": b"onepage"})
        self.assertGreater(result[b"time"], 0)
        self.assertEqual(len(result[b"ranks"]), 1)

    def ui_lua(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("实际屠龙界面验证需要lupa.lua51")
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute('''print=function() end;printT=print;CCControlEventTouchUpInside=1
            clock=1000;requests={};UIRequest=function(t) requests[#requests+1]=t end
            table.getTableLength=function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
            function node() return setmetatable({}, {__index=function(t,k)
                if k=="getContentSize" then return function() return {width=500,height=600} end end
                if k=="setString" then return function(self,s) self.text=s end end
                if k=="setVisible" then return function(self,v) self.visible=v end end
                if k=="setEnabled" then return function(self,v) self.enabled=v end end
                if k=="addHandleOfControlEvent" then return function(self,f) self.handler=f end end
                return function() end
            end}) end
            function items() return setmetatable({}, {__index=function(t,k) local n=node();rawset(t,k,n);return n end}) end
            CCBReaderLoad=function() return node(),items() end
            CCSkeletonAnimation={create=function() return node() end}
            ccp=function(x,y) return {x=x,y=y} end
            ui={setLabelString=function(n,s) n.text=s end,setSpriteTextureRect2=function() end,
                makeTimeText=tostring,getVipLevelByStr=function() return 5 end}
            gameTouch={clickprofbytime=function() end}
            gameTimer={times={},funcs={},rigistTime=function(self,k,n) self.times[k]=n end,
                rigistTimeFunc=function(self,k,f) self.funcs[k]=f end,
                UnrigistTimeFunc=function(self,k) self.times[k]=nil;self.funcs[k]=nil end}
            gameConfig={strings={string_common=function() return "屠龙" end},checkBuildOpen=function() return false end}
            gamedata={time=function() return clock end,config={boss2={["30001"]={animationid=30005,name="甲"},
                ["31001"]={animationid=30006,name="乙"}},generalanimation={["30005"]={name="龙"},["30006"]={name="鸟"}},
                global_kv={worldboss_gold={value=20},worldboss_autolv={value=45}}}}
            GameScene={topposY=1600,vip={vip=5},roleinfo={id=9,level=31},layers={worldboss={show=true},
                main={module={setWorldBossStatus=function() end}}}}
            gameWindows={windows={}}
            runGamePrompt=function(t) prompt=t.msg end
            showRewardPopupWindow=function(reward,x,cb) rewards=(rewards or 0)+1;rewardDone=cb end
            updateDataLife=function() staleReward=(staleReward or 0)+1 end
            RunbattleCallBack=function(kind,t,cb) played=(played or 0)+1;battleDone=cb end''')
        lua.globals().boss = lua.execute(self.client_scripts()["assets/scripts/Layer_worldboss2.so"].decode())
        lua.execute('''GameScene.layers.worldboss.module=boss;boss:init(node(),1600)
            boss.showOneNotify=function() end;requests={}''')
        lua.execute(self.client_scripts()["assets/scripts/UIWorldBoss.so"].decode())
        return lua

    def test_actual_layer_reentry_page_isolation_error_unlock_and_stale_playback_callbacks(self):
        lua = self.ui_lua()
        lua.execute('''local view=boss.localWorldBossView
            local status={status=1,cd=60,bosshp=100,bosslevel=200,ranks={},attackcount=1,damagesum=100}
            UIWorldBoss1Query({view=view,page="onepage",worldboss=status})
            assert(boss.localWorldBossReady==1060 and boss.choosepage=="start")
            boss.hasjoin=true;boss:reloadstatus(status)
            UIWorldBoss2Query({view=view,page="twopage",worldboss={status=0}})
            assert(boss.data.onepage.statusdata.status==1)
            UIWorldBoss1Attack({type=3401,view=view,page="onepage",worldboss=status,battlereport="report",reward={}})
            assert(played==1 and boss.localWorldBossPlaying)
            boss:shiftPage("twopage");local nextView=boss.localWorldBossView
            battleDone();assert(not boss.localWorldBossPlaying)
            UIWorldBoss1Attack({type=3401,view=view,page="onepage",worldboss=status,battlereport="report",reward={{cid=1000}}})
            assert(played==1 and staleReward==1 and boss.localWorldBossView==nextView)
            boss.localWorldBossBusy=3411;boss:setauto(true)
            LocalWorldBossError({request_opcode=3411})
            assert(not boss.isauto and boss.localWorldBossBusy==nil)
            boss:clear();UIWorldBoss2Query({view=nextView,page="twopage",worldboss=status})
            assert(gameTimer.funcs.localworldboss==nil)''')

    def test_actual_auto_waits_real_seconds_and_one_reply_never_accelerates_buys_or_runs_offscreen(self):
        lua = self.ui_lua()
        lua.execute('''boss.hasjoin=true;boss.isauto=true
            boss:reloadstatus({status=1,cd=60,bosshp=100,bosslevel=200,ranks={},attackcount=1,damagesum=1})
            requests={}
            local tick=gameTimer.funcs.localworldboss
            for i=1,600 do tick() end
            for _,req in ipairs(requests) do assert(req.type~=3401) end
            clock=1059;tick();assert(boss.localWorldBossBusy==nil)
            clock=1060;tick();assert(boss.localWorldBossBusy==3401)
            local count=#requests;for i=1,600 do tick() end;assert(#requests==count)
            for _,req in ipairs(requests) do if req.type==3401 then assert(req.method==0 and req.isauto) end end
            LocalWorldBossError({request_opcode=3401});clock=1120;tick()
            assert(not boss.isauto and boss.localWorldBossBusy==nil)
            GameScene.layers.worldboss.show=false;clock=1200;local count=#requests;tick()
            assert(#requests==count and gameTimer.funcs.localworldboss==nil)''')

    def test_actual_paid_choice_reuses_native_confirm_and_closing_or_changed_page_never_spends(self):
        lua = self.ui_lua()
        lua.globals().confirm = lua.execute(self.client_scripts()["assets/scripts/window_confirm.so"].decode())
        lua.execute('''gameWindows.openWindow=function(self,name,data,cb)
                confirm:open(-100,data,cb);self.windows.confirm={show=true,module=confirm}
            end
            gameWindows.closeWindowDirect=function(self,name) self.windows.confirm.show=false;confirm:close() end
            gameWindows.closeWindow=gameWindows.closeWindowDirect
            boss.hasjoin=true
            boss:reloadstatus({status=1,cd=60,bosshp=100,bosslevel=200,ranks={},attackcount=1,damagesum=1})
            requests={};boss:localWorldBossRequest({type=3401,method=10,isauto=true})
            assert(#requests==0 and confirm.rootItems.conceltext.text=="5元宝复活")
            confirm.rootItems.closeButton.handler();assert(#requests==0)
            boss:localWorldBossRequest({type=3401,method=10,isauto=true})
            confirm.rootItems.concel.handler()
            assert(#requests==1 and requests[1].method==2 and requests[1].isauto==false)
            LocalWorldBossError({request_opcode=3401})
            boss:localWorldBossRequest({type=3401,method=10})
            confirm.rootItems.confirm.handler()
            assert(#requests==2 and requests[2].method==10 and requests[2].isauto==false)
            LocalWorldBossError({request_opcode=3401})
            boss:localWorldBossRequest({type=3401,method=10})
            boss:shiftPage("twopage");local count=#requests
            confirm.rootItems.confirm.handler();assert(#requests==count)''')

    def test_all_240_actual_profiles_simulate_and_convert_real_animation_assets_to_same_terminal_hp(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("实际APK动画验证需要lupa.lua51")
        lua = LuaRuntime()
        config = dict(self.config)
        with zipfile.ZipFile(test_friends.test_guild.ROOT / "configs_sec5.zip") as archive:
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
            for cid, row in self.config["boss2"].items():
                with self.subTest(cid=cid):
                    before = copy.deepcopy(self.sessions[1].save)
                    report = world_boss.simulate(self.sessions[1].save, int(cid), row["hp"], 0, self.config, 7)
                    self.assertEqual(self.sessions[1].save, before)
                    native = lua.table_from(json.loads(lua.globals().ReplaceAbbToKey(json.dumps(report))), recursive=True)
                    allies, enemies = lua.globals().getBattleInitSlotInfo(native)
                    animations, ext = lua.globals().convertBattleReportToAnimationSub(native, allies, enemies)
                    self.assertGreater(len(animations), 1)
                    for side, key in (("attack", "atk"), ("defense", "def")):
                        for pos, unit in report["endmeta"][side].items():
                            self.assertEqual((ext.endinfo[key][pos].hp, ext.endinfo[key][pos].ap), (unit["h"], unit["ap"]))


if __name__ == "__main__":
    unittest.main()
