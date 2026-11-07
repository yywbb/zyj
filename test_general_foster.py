import copy
from contextlib import redirect_stdout
import io
import json
import random
import struct
import unittest
from unittest.mock import patch
import zipfile

import test_penglai
import build_local_apk as builder
from zyj_server import activities, battle, formation, general_foster, player, protocol, recharge, recruit, single_boss, training


class GeneralFosterTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        test_penglai.PenglaiTests.setUpClass.__func__(cls)
        cls.baseline = copy.deepcopy(cls.baseline)
        cls.baseline["role_state"].update(level=30, coin=20000000, gold=100000)

    reconnect = test_penglai.PenglaiTests.reconnect
    call = test_penglai.PenglaiTests.call
    give = test_penglai.PenglaiTests.give
    props = test_penglai.PenglaiTests.props
    groups = test_penglai.PenglaiTests.groups
    assert_rejected = test_penglai.PenglaiTests.assert_rejected

    def setUp(self):
        test_penglai.PenglaiTests.setUp(self)
        self.iid = 2000501
        raw = recruit.new_general(10201, self.iid, self.config)
        player.record_slot_update(self.session.save, protocol.encode_pb_field(1, 2, raw))
        self.give(20196, 100)
        body = protocol.encode_pb_field(1, 0, self.iid) + b"".join(protocol.encode_pb_field(2, 0, n) for n in (1, 0, 0, 0))
        self.assertEqual(struct.unpack(">IIII", self.session.handle(1038, 80, body)[0][:16])[2], 1038)
        self.give(20009, 1000)

    def generals(self):
        return formation.records(bytes.fromhex(self.session.save["world_state"]["1002"]), 1, 2)

    def scalar(self, opcode, *values, seed=0):
        self.sequence += 1
        body = b"".join(protocol.encode_pb_field(i, 0, v) for i, v in enumerate(values, 1))
        with patch("random.getrandbits", return_value=seed):
            packets = self.session.handle(opcode, self.sequence, body)
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], opcode)
        return packets

    def preview(self, method=1, seed=0, iid=None):
        packets = self.scalar(1013, iid or self.iid, method, seed=seed)
        parts = self.groups(packets[0][16:])
        current = formation.records(parts[1], 1, 2)[iid or self.iid]
        candidate = formation.records(parts[2], 1, 2)[iid or self.iid]
        token, count = protocol.parse_ids_pb(parts[3])
        return current, candidate, token, count, packets

    def confirm(self, token, keep=1, iid=None):
        return self.scalar(1014, iid or self.iid, keep, token)

    def set_raw(self, raw):
        player.record_slot_update(self.session.save, protocol.encode_pb_field(1, 2, raw))

    def auto(self, count=10, method=1, flags=(0, 0, 0), seed=0):
        packets = self.call(1126, [self.iid, method, count, *flags], seed)
        parts = self.groups(packets[0][16:])
        rows = protocol.parse_ids_pb(parts[2])
        rows = [v-(1<<64) if v >= (1<<63) else v for v in rows]
        return [rows[i:i+6] for i in range(0, len(rows), 6)], protocol.parse_ids_pb(parts[3]), packets

    def test_preview_pays_but_never_changes_general_until_versioned_confirmation(self):
        before, pills = copy.deepcopy(self.session.save), self.props(20009)
        raw, candidate, token, count, packets = self.preview(3)
        self.assertEqual(raw, self.generals()[self.iid])
        self.assertNotEqual(raw, candidate)
        self.assertEqual((count, pills-self.props(20009), before["role_state"]["gold"]-self.session.save["role_state"]["gold"]), (1, 1, 5))
        self.assertEqual(self.generals(), formation.records(bytes.fromhex(before["world_state"]["1002"]), 1, 2))
        self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in packets][-2:], [1200, 1001])
        self.assertNotIn("25", self.session.save["guide"]["sections"])
        self.confirm(token)
        self.assertEqual(self.generals()[self.iid], candidate)
        self.assertEqual(self.props(20009), pills-1)
        self.assertEqual(self.session.save["role_state"]["power"], before["role_state"]["power"])

    def test_reconnect_restores_preview_for_free_and_discard_does_not_refund_paid_costs(self):
        raw, candidate, token, _, _ = self.preview(4)
        pills, gold = self.props(20009), self.session.save["role_state"]["gold"]
        self.session = self.reconnect()
        restored = self.preview(0)
        self.assertEqual(restored[:4], (raw, candidate, token, 0))
        self.confirm(token, 0)
        self.assertEqual(self.generals()[self.iid], raw)
        self.assertEqual((self.props(20009), self.session.save["role_state"]["gold"]), (pills, gold))
        self.assertEqual(self.preview(0)[2], 0)

    def test_stale_cross_target_legacy_confirmations_and_extra_fields_never_apply(self):
        token = self.preview()[2]
        newer = self.preview()[2]
        self.assertGreater(newer, token)
        requests = ([self.iid, 1], [self.iid, 1, token], [self.iid+1, 1, newer], [self.iid, 2, newer], [self.iid, 1, 0])
        for values in requests:
            self.assert_rejected(1014, b"".join(protocol.encode_pb_field(i, 0, v) for i, v in enumerate(values, 1)))
        self.confirm(newer)
        self.assert_rejected(1014, protocol.encode_pb_field(1, 0, self.iid)+protocol.encode_pb_field(2, 0, 1)+protocol.encode_pb_field(3, 0, newer))

    def test_two_partners_keep_independent_reconnectable_previews_and_tokens(self):
        first = self.preview()
        second_iid = self.iid+1
        raw, _, _ = training.grow_general(recruit.new_general(10202, second_iid, self.config), 1000, b"", set(), {}, self.config, 60)
        self.set_raw(raw)
        second = self.preview(3, iid=second_iid)
        self.assertGreater(second[2], first[2])
        self.assert_rejected(1014, protocol.encode_pb_field(1, 0, self.iid)+protocol.encode_pb_field(2, 0, 1)+protocol.encode_pb_field(3, 0, second[2]))
        self.assertEqual(self.preview(0)[1:3], first[1:3])
        self.confirm(second[2], iid=second_iid)
        self.confirm(first[2])
        self.assertEqual((self.generals()[self.iid], self.generals()[second_iid]), (first[1], second[1]))

    def test_strict_payloads_locks_ownership_protagonist_cheers_and_advanced_data(self):
        for body in (b"", b"\x08", b"\x0a\x00", recharge.ids([self.iid, 1]), b"\x08\x01\x10\x01\x10\x02",
                     protocol.encode_pb_field(1, 0, self.iid)+protocol.encode_pb_field(2, 0, 5)):
            self.assert_rejected(1013, body)
        for values in ([self.iid, 0, 10, 0, 0, 0], [self.iid, 1, 0, 0, 0, 0], [self.iid, 1, 201, 0, 0, 0], [self.iid, 1, 10, 2, 0, 0]):
            self.assert_rejected(1126, recharge.ids(values))
        baseline = copy.deepcopy(self.session.save)
        for problem in ("level", "role", "owner", "protagonist", "one", "advanced", "illusion", "pills", "gold", "potential"):
            self.session.save = copy.deepcopy(baseline)
            iid, raw = self.iid, self.generals()[self.iid]
            if problem == "level": self.session.save["role_state"]["level"] = 29
            elif problem == "role": self.session.save["has_role"] = False
            elif problem == "owner": iid += 1
            elif problem == "protagonist": iid = protocol.pb_get_varint(bytes.fromhex(self.session.save["protagonist_snapshot"]), 1)
            elif problem == "one": self.set_raw(protocol.pb_set_varint(raw, 3, 1))
            elif problem == "advanced": self.set_raw(protocol.pb_set_varint(raw, 21, 1))
            elif problem == "illusion": self.set_raw(raw+protocol.encode_pb_field(41, 2, recharge.ids([1])))
            elif problem == "pills": player.change_item_count(self.session.save, 20009, -self.props(20009), self.config, test_penglai.NOW)
            elif problem == "gold": self.session.save["role_state"]["gold"] = 0
            elif problem == "potential": self.set_raw(protocol.pb_set_varint(raw, 17, 1<<31))
            with self.subTest(problem=problem):
                self.assert_rejected(1013, protocol.encode_pb_field(1, 0, iid)+protocol.encode_pb_field(2, 0, 3))
        self.session.save = baseline
        comb = protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 1013)+protocol.encode_pb_field(2, 2, b"\x08\x01\x10\x01"))
        self.assert_rejected(999900, comb)

    def test_zero_potential_can_only_transfer_verified_training_without_amplifying_it(self):
        self.set_raw(protocol.pb_set_varint(self.generals()[self.iid], 17, 1))
        raw, candidate, token, actual, _ = self.preview(3)
        self.assertEqual(actual, 1)
        self.confirm(token)
        units = self.session.save["general_foster_state"]["records"][str(self.iid)]["units"][:]
        self.assertEqual(sum(units), 2)
        floors = {f: protocol.pb_get_varint(candidate, f)-v*r for f, v, r in zip(general_foster.FIELDS, units, (1, 3, 1))}
        for seed in range(20):
            _, preview, token, _, _ = self.preview(3, seed)
            self.assertEqual(protocol.pb_get_varint(preview, 17), 0)
            self.confirm(token)
            units = self.session.save["general_foster_state"]["records"][str(self.iid)]["units"]
            self.assertEqual(sum(units), 2)
            for f, v, r in zip(general_foster.FIELDS, units, (1, 3, 1)):
                self.assertEqual(protocol.pb_get_varint(self.generals()[self.iid], f), floors[f]+v*r)
        del self.session.save["general_foster_state"]
        self.assert_rejected(1013, protocol.encode_pb_field(1, 0, self.iid)+protocol.encode_pb_field(2, 0, 1))

    def test_weighted_rolls_and_method_ratios_are_deterministic_and_conserve_local_units(self):
        for gold in (False, True):
            amounts = set()
            for seed in range(300):
                units, remaining, actual, _, _ = general_foster.roll([0, 0, 0], 1000, 1, gold, self.config, random.Random(seed))
                amounts.add(1000-remaining)
                self.assertEqual(sum(units), (1000-remaining)*(2 if gold else 1))
                self.assertEqual(actual, 1)
                self.assertEqual((units, remaining), general_foster.roll([0, 0, 0], 1000, 1, gold, self.config, random.Random(seed))[:2])
            self.assertEqual(amounts, {3, 4, 5} if gold else {1, 2, 3})

    def test_automatic_groups_apply_real_filters_count_partial_rows_and_charge_exactly(self):
        self.set_raw(protocol.pb_set_varint(self.generals()[self.iid], 17, 1))
        before, pills = copy.deepcopy(self.session.save), self.props(20009)
        rows, counts, packets = self.auto(10, 2, (1, 1, 1))
        self.assertEqual((counts, rows[0][0], rows[0][5]), ([1], 1, 1))
        self.assertEqual((pills-self.props(20009), before["role_state"]["gold"]-self.session.save["role_state"]["gold"]), (1, 5))
        self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in packets][-2:], [1200, 1001])
        self.assert_rejected(1126, recharge.ids([self.iid, 2, 10, 1, 1, 1]))
        before, pills = self.generals()[self.iid], self.props(20009)
        rows, counts, _ = self.auto(7, 1)
        self.assertEqual(sum(counts), 7)
        self.assertEqual(pills-self.props(20009), 7)
        self.assertEqual(sum(self.session.save["general_foster_state"]["records"][str(self.iid)]["units"]), 2)
        self.assertTrue(any(v < 0 for row in rows for v in (row[2], row[4])))

    def test_auto_rejects_pending_and_obeys_each_selected_non_decreasing_attribute(self):
        token = self.preview()[2]
        self.assert_rejected(1126, recharge.ids([self.iid, 1, 10, 0, 0, 0]))
        self.confirm(token)
        baseline = copy.deepcopy(self.session.save)
        for flags in ((1, 0, 0), (0, 1, 0), (0, 0, 1), (1, 1, 0), (1, 1, 1)):
            self.session.save = copy.deepcopy(baseline)
            before = self.generals()[self.iid]
            rows, counts, _ = self.auto(10, flags=flags)
            for field, flag in zip(general_foster.FIELDS, flags):
                if flag: self.assertGreaterEqual(protocol.pb_get_varint(self.generals()[self.iid], field), protocol.pb_get_varint(before, field))
            for row in rows:
                if row[0]:
                    for attr, delta in ((row[1], row[2]), (row[3], row[4])):
                        if flags[attr-1]: self.assertGreaterEqual(delta, 0)
            self.assertEqual(sum(counts), 10)

    def test_auto_full_200_limit_reconnect_and_retry_do_not_reapply_paid_results(self):
        before = self.props(20009)
        rows, counts, packets = self.auto(200)
        self.assertEqual((sum(counts), before-self.props(20009)), (200, 200))
        self.assertTrue(all(1 <= n <= 10 for n in counts))
        body = recharge.ids([self.iid, 1, 200, 0, 0, 0])
        self.assertEqual(self.session.handle(1126, self.sequence, body), packets)
        world, foster = self.session.save["world_state"], self.session.save["general_foster_state"]
        self.session = self.reconnect()
        self.assertEqual((self.session.save["world_state"], self.session.save["general_foster_state"]), (world, foster))
        memory, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
            self.auto(1)
        self.assertEqual((self.session.save, self.path.read_bytes()), (memory, disk))

    def test_active_power_and_dedicated_team_inherit_training_once(self):
        body = protocol.encode_pb_field(1, 0, 2)+protocol.encode_pb_field(3, 0, self.iid)
        self.assertEqual(struct.unpack(">IIII", self.session.handle(1003, 900, body)[0][:16])[2], 1003)
        before, old = copy.deepcopy(self.session.save), self.generals()[self.iid]
        _, candidate, token, _, _ = self.preview(4)
        packets = self.confirm(token)
        delta = protocol.pb_get_varint(candidate, 20)-protocol.pb_get_varint(old, 20)
        self.assertEqual(self.session.save["role_state"]["power"]-before["role_state"]["power"], delta)
        self.assertIn(205, [struct.unpack(">IIII", p[:16])[2] for p in packets])
        world = copy.deepcopy(self.session.save["world_state"])
        team = protocol.parse_ids_pb(self.call(3702, [140, 1])[0][16:])[:8]
        temporary, _ = single_boss.project_team(self.session.save, team, self.config)
        point = self.config["copy"]["42102"]["1"]
        self.assertEqual(battle.rosters(temporary, point, self.config)[0], battle.rosters(self.session.save, point, self.config)[0])
        self.assertEqual(world, self.session.save["world_state"])

    def test_pending_deltas_preserve_growth_equipment_like_changes_unknown_fields_and_new_potential(self):
        old, candidate, token, _, _ = self.preview()
        raw, _, up = training.grow_general(old, 1000, b"", set(), {}, self.config, 60)
        self.assertTrue(up)
        raw = protocol.pb_set_varint(raw, 6, protocol.pb_get_varint(raw, 6)+500)
        raw += protocol.encode_pb_field(50, 2, b"unknown")
        self.set_raw(raw)
        restored = self.preview(0)[1]
        self.confirm(token)
        self.assertEqual(self.generals()[self.iid], restored)
        for field in (6, 7, 8, 17):
            self.assertEqual(protocol.pb_get_varint(restored, field)-protocol.pb_get_varint(raw, field), protocol.pb_get_varint(candidate, field)-protocol.pb_get_varint(old, field))
        for field in (3, 4, 5): self.assertEqual(protocol.pb_get_varint(restored, field), protocol.pb_get_varint(raw, field))
        self.assertIn((50, 2, b"unknown"), list(protocol.iter_pb_fields(restored)))

    def test_liveness_counts_actual_paid_pills_not_confirmations_queries_or_claim_retries(self):
        token = self.preview(2)[2]
        self.assertEqual(activities.liveness_statuses(self.session.save, self.config, test_penglai.NOW)[1][22], 10)
        self.preview(0)
        self.confirm(token, 0)
        self.assertEqual(self.session.save["activity_state"]["liveness_counts"]["22"], 10)
        coin = self.session.save["role_state"]["coin"]
        self.call(2411, [122])
        self.assertEqual(self.session.save["role_state"]["coin"]-coin, 2000)
        self.assert_rejected(2411, recharge.ids([122]))
        self.assertNotIn("25", self.session.save["guide"]["sections"])
        for step in range(1, self.steps[25]+1):
            self.scalar(201, 25, step)
        self.assertEqual(self.session.save["guide"]["sections"]["25"]["status"], 2)

    def test_complete_rebirth_refunds_actual_pills_not_gold_fees_and_clears_preview_and_ledger(self):
        pills, exp_pills = self.props(20009), self.props(20196)+1
        self.confirm(self.preview(4)[2], 0)
        self.confirm(self.preview(3)[2])
        self.auto(20, 2)
        self.preview(3)
        raw, gold = self.generals()[self.iid], self.session.save["role_state"]["gold"]
        used = general_foster.used_potential(raw, self.config)
        fee = self.config["renascence"][str(protocol.pb_get_varint(raw, 3))]["generallvcost"]+(used*2+50)//100
        self.call(1035, [self.iid])
        self.assertEqual((self.props(20009), self.props(20196)), (pills, exp_pills))
        self.assertEqual(self.session.save["role_state"]["gold"], gold-fee)
        self.assertEqual(self.generals()[self.iid], recruit.new_general(10201, self.iid, self.config))
        for key in ("pending", "records"):
            self.assertNotIn(str(self.iid), self.session.save["general_foster_state"][key])
        self.assert_rejected(1035, recharge.ids([self.iid]))

    def test_unknown_old_history_is_never_reconstructed_for_refunds_or_transfer(self):
        self.session.save["qiankun_state"]["receipts"].clear()
        token = self.preview()[2]
        self.confirm(token)
        self.assert_rejected(1035, recharge.ids([self.iid]))
        from zyj_server.admin import gm
        self.preview()
        gm._manage(self.session.save, "remove-general", {"iid": self.iid}, self.config, self.steps, test_penglai.NOW)
        self.assertNotIn(self.iid, self.generals())
        for key in ("records", "pending"): self.assertNotIn(str(self.iid), self.session.save["general_foster_state"][key])
        self.assertNotIn(f"general:{self.iid}", self.session.save["qiankun_state"]["receipts"])

    def test_save_failure_retries_corrupt_state_and_overflow_are_atomic(self):
        self.sequence += 1
        body = protocol.encode_pb_field(1, 0, self.iid)+protocol.encode_pb_field(2, 0, 3)
        packets = self.session.handle(1013, self.sequence, body)
        memory, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        self.assertEqual(self.session.handle(1013, self.sequence, body), packets)
        for opcode, request in ((1013, body), (1014, protocol.encode_pb_field(1, 0, self.iid)+protocol.encode_pb_field(2, 0, 1)+protocol.encode_pb_field(3, 0, memory["general_foster_state"]["serial"]))):
            with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
                self.session.handle(opcode, self.sequence+1, request)
            self.assertEqual((self.session.save, self.path.read_bytes()), (memory, disk))
        for key, value in (("serial", True), ("serial", -1), ("pending", []), ("records", {"wrong": {}})):
            self.session.save = copy.deepcopy(memory)
            self.session.save["general_foster_state"][key] = value
            self.assert_rejected(1013, body)
        self.session.save = copy.deepcopy(memory)
        raw = self.generals()[self.iid]
        for field in (6, 7, 8): raw = protocol.pb_set_varint(raw, field, (1<<31)-1)
        self.set_raw(raw)
        self.assert_rejected(1013, body)

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

    def network_lua(self):
        import test_activity_copy
        lua = test_activity_copy.ActivityCopyTests.network_lua(self)
        for name in ("generals_pb", "fosterpreview_pb", "combmessages_pb", "error_pb", "params_pb"):
            lua.execute(builder.read_script(name, "pb"))
        lua.execute(self.client_scripts()["assets/pb/fosterconfirm_pb.so"])
        code = builder.read_script("gamedata").decode().replace("\r\n", "\n")
        start = code.index("function gamedata.generalData(")
        lua.execute(code[start:code.index("function gamedata.equipData(", start)].encode())
        start = code.index("function gamedata.Generals(")
        end = code.index("\nend", start)+len("\nend")
        lua.execute(code[start:end].encode())
        lua.execute(b'''gamedata.cache.generals={}; gamedata.cache.protagonist={iid=1}
            gamedata.cache.props={[20009]={num=1000}}; gamedata.cache.role.gold=100000
            gamedata.updateRoleGold=function(self,n) self.cache.role.gold=self.cache.role.gold+n end
            gamedata.updateprops=function(self,p) self.cache.props[p.cid].num=self.cache.props[p.cid].num+p.num end
            gamedata.isGeneralOn=function() return false end
            gamedata.checkIsMainChacter=function() return false end
            gamedata.findcombskilllevel=function() end
            package.loaded.logError={errorMessage={},errorFunc={}}; printf=function() end
            initPb=function(mod,fd) local m=mod.Ids();m:ParseFromString(fd.rbuf);return m end''')
        lua.execute(self.client_scripts()["assets/scripts/GameGeneralFoster.so"])
        lua.execute(self.client_scripts()["assets/common_lua/GameErrorMessage.so"])
        lua.globals().gamedata[b"cache"][b"props"][20009][b"num"] = self.props(20009)
        lua.globals().gamedata[b"cache"][b"role"][b"gold"] = self.session.save["role_state"]["gold"]
        self.assertIsNone(lua.globals().gameConfig)
        return lua

    def test_actual_network_pb_preview_restore_confirm_and_error_unlock_without_ui_globals(self):
        lua = self.network_lua()
        req = lua.table_from({b"id": self.iid, b"method": 3})
        mode, opcode, body = lua.globals().UIGeneralFosterPreviewCallBack(req)
        self.assertEqual((mode, opcode, dict((n, v) for n, w, v in protocol.iter_pb_fields(body))), (1, 1013, {1: self.iid, 2: 3}))
        self.assertEqual(lua.globals().UIGeneralFosterPreviewCallBack(req)[0], 0)
        packets = self.session.handle(opcode, 950, body)
        result = lua.globals().NetGeneralFosterPreviewCallBack(lua.table_from({b"rbuf": packets[0][16:]}))
        token = result[b"token"]
        current = lua.globals().gamedata[b"cache"][b"generals"][self.iid]
        self.assertEqual(current[b"potential"], protocol.pb_get_varint(self.generals()[self.iid], 17))
        self.assertLess(result[b"previewGeneralData"][b"potential"], current[b"potential"])
        self.assertEqual(lua.globals().gamedata[b"cache"][b"props"][20009][b"num"], self.props(20009))
        self.assertEqual(lua.globals().gamedata[b"cache"][b"role"][b"gold"], self.session.save["role_state"]["gold"])
        self.session = self.reconnect()
        lua = self.network_lua()
        req = lua.table_from({b"id": self.iid, b"method": 3})
        lua.globals().gamedata[b"cache"][b"props"][20009][b"num"] = self.props(20009)
        lua.globals().gamedata[b"cache"][b"role"][b"gold"] = self.session.save["role_state"]["gold"]
        _, opcode, body = lua.globals().UIGeneralFosterPreviewCallBack(lua.table_from({b"id": self.iid, b"method": 0}))
        result = lua.globals().NetGeneralFosterPreviewCallBack(lua.table_from({b"rbuf": self.session.handle(opcode, 951, body)[0][16:]}))
        self.assertEqual((result[b"token"], result[b"prop"]), (token, 0))
        _, opcode, body = lua.globals().UIGeneralFosterConfirmCallBack(lua.table_from({b"id": self.iid, b"opt": 1, b"token": token}))
        self.assertEqual(dict((n, v) for n, w, v in protocol.iter_pb_fields(body)), {1: self.iid, 2: 1, 3: token})
        result = lua.globals().NetGeneralFosterConfirmCallBack(lua.table_from({b"rbuf": self.session.handle(opcode, 952, body)[0][16:]}))
        for field, name in ((6, b"atk"), (7, b"defense"), (8, b"hp"), (17, b"potential")):
            self.assertEqual(result[b"general"][name], protocol.pb_get_varint(self.generals()[self.iid], field))
        lua.globals().UIGeneralFosterPreviewCallBack(req)
        lua.globals().NetErrorMessageCallback9(lua.table_from({b"rbuf": recharge.ids([1013, 0])}))
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localFosterBusy"])
        self.assertEqual(lua.globals().UIGeneralFosterPreviewCallBack(req)[0], 1)

    def test_actual_automatic_callback_charges_partial_row_once_and_keeps_signed_deltas(self):
        self.set_raw(protocol.pb_set_varint(self.generals()[self.iid], 17, 1))
        lua = self.network_lua()
        req = lua.table_from({b"iid": self.iid, b"method": 2, b"xlnum": 10, b"status1": 1, b"status2": 1, b"status3": 1})
        _, opcode, body = lua.globals().UIGeneralAutoTrainCallBack(req)
        self.assertEqual(protocol.parse_ids_pb(body), [self.iid, 2, 10, 1, 1, 1])
        self.assertEqual(lua.globals().UIGeneralFosterPreviewCallBack(lua.table_from({b"id": self.iid, b"method": 1}))[0], 0)
        packets = self.session.handle(opcode, 960, body)
        result = lua.globals().NetGeneralAutoTrainCallBack(lua.table_from({b"rbuf": packets[0][16:]}))
        self.assertEqual((result[b"actual"], result[b"stop"], result[b"status"][b"1"][b"count"]), (1, 1, 1))
        self.assertEqual(lua.globals().gamedata[b"cache"][b"props"][20009][b"num"], self.props(20009))
        self.assertEqual(lua.globals().gamedata[b"cache"][b"role"][b"gold"], self.session.save["role_state"]["gold"])
        req[b"method"], req[b"xlnum"], req[b"status1"], req[b"status2"], req[b"status3"] = 1, 7, 0, 0, 0
        _, opcode, body = lua.globals().UIGeneralAutoTrainCallBack(req)
        result = lua.globals().NetGeneralAutoTrainCallBack(lua.table_from({b"rbuf": self.session.handle(opcode, 961, body)[0][16:]}))
        self.assertEqual(result[b"actual"], 7)
        self.assertTrue(any(min(row[b"num1"], row[b"num2"]) < 0 for row in result[b"status"].values()))
        self.assertEqual(lua.globals().gamedata[b"cache"][b"props"][20009][b"num"], self.props(20009))

    def automatic_ui(self, speed=1, method=2):
        from lupa.lua51 import LuaRuntime
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.globals().gamedata = lua.table_from({"config": self.config}, recursive=True)
        with zipfile.ZipFile(test_penglai.ROOT / "configs_sec5.zip") as archive:
            lua.globals().gamedata.config.system_intro = lua.table_from(json.loads(archive.read("5/system_intro.json")), recursive=True)
        lua.globals().speed = speed
        lua.execute('''
            requests={}; prompts={}; actions={}; now=0
            os.time=function() return math.floor(now) end
            print=function() end; printT=print; CCControlEventTouchUpInside=1; kEditBoxInputModePhoneNumber=1
            table.getTableLength=function(t) local n=0; for _ in pairs(t) do n=n+1 end; return n end
            UIRequest=function(t) requests[#requests+1]=t end
            runGamePrompt=function(t) prompts[#prompts+1]=t.msg end
            function node()
                return setmetatable({enabled=true,generation=0}, {__index=function(t,k)
                    if k=='setString' then return function(self,v) self.text=v end end
                    if k=='getString' then return function(self) return self.text end end
                    if k=='setEnabled' then return function(self,v) self.enabled=v end end
                    if k=='addHandleOfControlEvent' then return function(self,f) self.callback=f end end
                    if k=='getContentSize' then return function() return {width=900,height=800} end end
                    if k=='getColor' then return function() return {} end end
                    if k=='stopAllActions' then return function(self) self.generation=self.generation+1 end end
                    if k=='runAction' then return function(self,a)
                        actions[#actions+1]={at=now+a.delay/speed,callback=a.callback,node=self,generation=self.generation}
                    end end
                    return function() end
                end})
            end
            function items() return setmetatable({}, {__index=function(t,k) local n=node();rawset(t,k,n);return n end}) end
            CCBReaderLoad=function() return node(),items() end
            CCNode={create=node}; CCDelayTime={create=function(_,n) return {delay=n} end}
            CCCallFunc={create=function(_,f) return {callback=f} end}
            CCSequence={createWithTwoActions=function(_,a,b) return {delay=a.delay,callback=b.callback} end}
            LuaEventHandler={create=function(_,f) return f end}
            ui={setLabelString=function(n,v) if v~=nil then n:setString(v) end end,
                getIDandNUMs=function() return {{cid=5,num=1}} end,
                creatInputEditBoxForNum=function(n,label,priority,callback)
                    inputArgs={length=3}; inputEnd=function(text) callback(tonumber(text)) end
                end,
                creatInputEditBoxByNode=function(n,mode,begin,finish,args)
                    inputBegin=begin; inputEnd=finish; inputArgs=args; return node()
                end,
                creatDelayButton=function(n,priority,f) n.repeatCallback=f end,
                createLuaTableView=node,createRichLabel=function() end,IDconfig=function() return {name='培养丹'} end}
            gameConfig={strings={string_common=function() return '培养' end,nameBuzu=function() return '培养丹不足' end}}
            gameTouch={clickprofbytime=function() end}
            GameScene={roleinfo={gold=100000},presentLayer='generalup',layers={generalup={show=false}},addUpdate=function() end}
            gameWindows={windows={generalInfo={show=false}}}
            function advance(seconds)
                local target=now+seconds
                for _=1,10000 do
                    local index,first
                    for i,a in ipairs(actions) do if a.at<=target and (not first or a.at<first.at) then index,first=i,a end end
                    if not first then now=target;return end
                    table.remove(actions,index); now=first.at
                    if first.generation==first.node.generation then first.callback() end
                end
                error('timer did not yield')
            end
        ''')
        scripts = self.client_scripts()
        window = lua.execute(scripts["assets/scripts/window_generalcultivateAuto.so"].decode())
        lua.globals().gameWindows.windows.generalcultivate = lua.table_from({"show": True, "module": window})
        lua.execute(scripts["assets/scripts/UIGenerals.so"].decode())
        raw = self.generals()[self.iid]
        data = {"iid": self.iid, "method": method, "extGeneralData": {"iid": self.iid, "potential": protocol.pb_get_varint(raw, 17),
                "atk": protocol.pb_get_varint(raw, 6), "hp": protocol.pb_get_varint(raw, 8), "defense": protocol.pb_get_varint(raw, 7)}}
        window.open(window, -100, lua.table_from(data, recursive=True), None)
        window.setpropNum(window, lua.table_from({"20009": self.props(20009)}))
        return lua, window, data

    def automatic_reply(self, ui, net, request, sequence):
        request = net.table_from({key.encode(): value for key, value in request.items()})
        remote, opcode, body = net.globals().UIGeneralAutoTrainCallBack(request)
        self.assertEqual((remote, opcode), (1, 1126))
        values = protocol.parse_ids_pb(body)
        self.assertLessEqual(values[2], 200)
        with patch("random.getrandbits", return_value=0):
            packets = self.session.handle(opcode, sequence, body)
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 1126)
        result = net.globals().NetGeneralAutoTrainCallBack(net.table_from({b"rbuf": packets[0][16:]}))
        def plain(value):
            if hasattr(value, "items"):
                return {plain(key): plain(item) for key, item in value.items()}
            return value.decode() if isinstance(value, bytes) else value
        result = ui.table_from(plain(result), recursive=True)
        ui.globals().GameScene.roleinfo.gold = self.session.save["role_state"]["gold"]
        ui.globals().UIGeneralFosterAutomatic(result)
        self.assertEqual(net.globals().gamedata[b"cache"][b"props"][20009][b"num"], self.props(20009))
        self.assertEqual(net.globals().gamedata[b"cache"][b"role"][b"gold"], self.session.save["role_state"]["gold"])
        return result, values[2]

    def test_actual_automatic_input_accepts_over_2000_without_changing_shared_input_helper(self):
        self.give(20009, 10000)
        lua, window, _ = self.automatic_ui()
        self.assertEqual(lua.globals().inputArgs.length, 10)
        lua.globals().inputEnd("2501", lua.globals().node())
        self.assertEqual(window.donum, 2501)
        for value in ("0", "-1", "1.5", "nan", "2147483648", str(self.props(20009)+1), "20001"):
            with self.subTest(value=value):
                lua.globals().inputEnd(value, lua.globals().node())
                self.assertEqual(window.donum, 2501)
        self.assertIn(b"length = 3", builder.read_script("ui", "common_lua"))

    def test_actual_automatic_unbounded_total_uses_bounded_batches_and_exact_persistent_costs(self):
        self.give(20009, 3000)
        ui, window, _ = self.automatic_ui()
        net = self.network_lua()
        pills, gold = self.props(20009), self.session.save["role_state"]["gold"]
        window.numchange(window, 2201)
        window.localFosterStart(window)
        cursor, batches, last = 1, [], None
        for batch in range(12):
            requests = ui.globals().requests
            queued = [requests[i] for i in range(cursor, len(requests)+1) if requests[i].type == 1126]
            cursor = len(requests)+1
            self.assertEqual(len(queued), 1)
            last, count = self.automatic_reply(ui, net, queued[0], 10000+batch)
            batches.append(count)
            self.assertLessEqual(ui.globals().table.getTableLength(window.status), 200)
            ui.globals().advance(0.2)
        self.assertEqual(batches, [200]*11+[1])
        self.assertEqual((pills-self.props(20009), gold-self.session.save["role_state"]["gold"]), (2201, 11005))
        self.assertEqual(self.session.save["activity_state"]["liveness_counts"]["22"], self.config["liveness"]["22"]["num"])
        self.assertEqual(window.donum, 0)
        self.assertIsNone(window.localFosterRun)
        before = len(ui.globals().requests)
        ui.globals().UIGeneralFosterAutomatic(last)
        ui.globals().advance(2)
        self.assertEqual(len(ui.globals().requests), before)
        world, foster = copy.deepcopy(self.session.save["world_state"]), copy.deepcopy(self.session.save["general_foster_state"])
        self.session = self.reconnect()
        self.assertEqual((self.session.save["world_state"], self.session.save["general_foster_state"]), (world, foster))
        self.call(1035, [self.iid])
        self.assertEqual(self.props(20009), pills)

    def test_actual_automatic_unknown_results_stop_at_real_deadline_and_errors_match_batch(self):
        for speed in (1, 3, 10):
            with self.subTest(speed=speed):
                ui, window, _ = self.automatic_ui(speed)
                net = self.network_lua()
                window.numchange(window, 500)
                window.localFosterStart(window)
                request = ui.globals().requests[len(ui.globals().requests)]
                remote, _, _ = net.globals().UIGeneralAutoTrainCallBack(net.table_from({key.encode(): value for key, value in request.items()}))
                self.assertEqual(remote, 1)
                ui.globals().advance(19)
                self.assertIsNotNone(window.localFosterRun)
                ui.globals().advance(3)
                self.assertIsNone(window.localFosterRun)
                before = len(ui.globals().requests)
                window.localFosterStart(window)
                self.assertEqual(len(ui.globals().requests), before)
                wrong = net.globals().NetErrorMessageCallback9(net.table_from({b"rbuf": recharge.ids([1013, 0])}))
                self.assertIsNotNone(net.globals().gamedata[b"ext"][b"localFosterBusy"])
                self.assertIsNone(wrong[b"localFosterBatch"])
                error = net.globals().NetErrorMessageCallback9(net.table_from({b"rbuf": recharge.ids([1126, 0])}))
                ui.globals().LocalFosterAutoError(ui.table_from({"request_opcode": 1126, "localFosterBatch": error[b"localFosterBatch"]}))
                self.assertIsNone(net.globals().gamedata[b"ext"][b"localFosterBusy"])
                window.localFosterStart(window)
                self.assertEqual(len(ui.globals().requests), before+1)

    def test_actual_automatic_stop_target_changes_and_reopened_windows_never_continue_old_batch(self):
        self.give(20009, 2000)
        for index, mode in enumerate(("stop", "between", "close", "target", "filter", "page")):
            with self.subTest(mode=mode):
                ui, window, data = self.automatic_ui()
                net = self.network_lua()
                window.numchange(window, 500)
                window.localFosterStart(window)
                request = ui.globals().requests[len(ui.globals().requests)]
                old_begin, old_end = ui.globals().inputBegin, ui.globals().inputEnd
                if mode == "stop": window.rootItems.doButton.callback()
                elif mode == "close":
                    window.close(window)
                    old_begin()
                    old_end("999", ui.globals().node())
                    window.open(window, -100, ui.table_from(data, recursive=True), None)
                elif mode == "target": window.iid = self.iid+1
                elif mode == "filter": window.status1 = 1
                elif mode == "page": ui.globals().GameScene.presentLayer = "city"
                before = len(ui.globals().requests)
                self.automatic_reply(ui, net, request, 11000+index)
                if mode == "between": window.rootItems.doButton.callback()
                ui.globals().advance(25)
                self.assertEqual(len(ui.globals().requests), before)
                self.assertIsNone(window.localFosterRun)
                if mode == "close": self.assertEqual(window.donum, 0)

    def test_actual_automatic_preflights_full_budget_and_stops_on_partial_batch(self):
        net = self.network_lua()
        pills, gold = self.props(20009), self.session.save["role_state"]["gold"]
        for resource, total in (("pills", pills+1), ("gold", gold//5+1)):
            net.globals().gamedata[b"cache"][b"props"][20009][b"num"] = max(pills,total) if resource == "gold" else pills
            request = net.table_from({b"iid": self.iid, b"method": 2, b"xlnum": 200, b"localFosterTotal": total, b"localFosterBatch": 42})
            remote, opcode, error = net.globals().UIGeneralAutoTrainCallBack(request)
            self.assertEqual((remote, opcode, error[b"localFosterBatch"]), (0, 503, 42))
            self.assertIsNone(net.globals().gamedata[b"ext"][b"localFosterBusy"])
            if resource == "gold": self.assertEqual(error[b"msgtype"], b"shortgold")
        net.globals().gamedata[b"cache"][b"props"][20009][b"num"] = pills
        self.assertEqual((self.props(20009), self.session.save["role_state"]["gold"]), (pills, gold))
        self.set_raw(protocol.pb_set_varint(self.generals()[self.iid], 17, 1))
        ui, window, _ = self.automatic_ui()
        window.numchange(window, 500)
        window.status1, window.status2, window.status3 = 1, 1, 1
        window.rootItems.doButton.callback()
        request = ui.globals().requests[len(ui.globals().requests)]
        result, _ = self.automatic_reply(ui, net, request, 12000)
        self.assertEqual((result.actual, result.stop, pills-self.props(20009), gold-self.session.save["role_state"]["gold"]), (1, 1, 1, 5))
        before = len(ui.globals().requests)
        ui.globals().advance(25)
        self.assertEqual(len(ui.globals().requests), before)
        self.assertIsNone(window.localFosterRun)

    def test_actual_automatic_save_failure_keeps_paid_prior_batch_and_never_retries_unknown_batch(self):
        self.give(20009, 2000)
        pills = self.props(20009)
        ui, window, _ = self.automatic_ui()
        net = self.network_lua()
        window.numchange(window, 500)
        window.localFosterStart(window)
        self.automatic_reply(ui, net, ui.globals().requests[len(ui.globals().requests)], 13000)
        ui.globals().advance(0.2)
        request = ui.globals().requests[len(ui.globals().requests)]
        remote, opcode, body = net.globals().UIGeneralAutoTrainCallBack(net.table_from({key.encode(): value for key, value in request.items()}))
        self.assertEqual((remote, opcode), (1, 1126))
        memory, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
            self.session.handle(opcode, 13001, body)
        self.assertEqual((self.session.save, self.path.read_bytes()), (memory, disk))
        self.assertEqual(self.props(20009), pills-200)
        before = len(ui.globals().requests)
        ui.globals().advance(22)
        self.assertIsNone(window.localFosterRun)
        window.localFosterStart(window)
        self.assertEqual(len(ui.globals().requests), before)
        self.assertIsNotNone(net.globals().gamedata[b"ext"][b"localFosterBusy"])

    def test_actual_automatic_ordinary_large_total_never_requires_or_charges_gold(self):
        self.give(20009, 3000)
        self.session.save["role_state"]["gold"] = 0
        pills = self.props(20009)
        ui, window, _ = self.automatic_ui(method=1)
        ui.globals().GameScene.roleinfo.gold = 0
        net = self.network_lua()
        window.numchange(window, 2201)
        window.setpropNum(window, ui.table_from({"20009": pills}))
        self.assertEqual(window.donum, 2201)
        window.localFosterStart(window)
        self.automatic_reply(ui, net, ui.globals().requests[len(ui.globals().requests)], 14000)
        window.rootItems.doButton.callback()
        before = len(ui.globals().requests)
        ui.globals().advance(2)
        self.assertEqual(len(ui.globals().requests), before)
        self.assertEqual((self.props(20009), self.session.save["role_state"]["gold"]), (pills-200, 0))

    def test_both_actual_training_pages_bind_own_token_ignore_late_targets_and_restore_on_entry(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("实际APK界面验证需要本机已有lupa.lua51")
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.globals().gamedata = lua.table_from({"config": self.config}, recursive=True)
        with zipfile.ZipFile(test_penglai.ROOT / "configs_sec5.zip") as archive:
            lua.globals().gamedata.config.generalanimation = lua.table_from(json.loads(archive.read("5/generalanimation.json")), recursive=True)
        lua.execute('''print=function() end; printT=print; CCControlEventTouchUpInside=1
            requests={}; UIRequest=function(t) requests[#requests+1]=t end
            function node() return setmetatable({}, {__index=function(t,k)
                if k=="addHandleOfControlEvent" then return function(self,f) self.callback=f end end
                if k=="setString" then return function(self,v) self.text=v end end
                return function() end
            end}) end
            function items() return setmetatable({}, {__index=function(t,k) local n=node();rawset(t,k,n);return n end}) end
            ui=setmetatable({setLabelString=function(n,v) if v then n:setString(v) end end},{__index=function() return function() end end})
            gameConfig={images={alpha="alpha"},strings={string_common=function() return "培养" end}}
            gameTouch={clickprofbytime=function() end}; setSpriteFrameByName=function() end
            ccc3=function() return {} end; gamedata.music={PlayOptSound=function() end}
            CCSkeletonAnimation={create=node}; GameScene={roleinfo={gold=100000},layers={},addUpdate=function() end}
            gameWindows={windows={generalInfo={show=false},generalcultivate={show=false}},openWindow=function() end}''')
        scripts = self.client_scripts()
        page = lua.execute(scripts["assets/scripts/Layer_generalup.so"].decode())
        window = lua.execute(scripts["assets/scripts/window_generalInfo.so"].decode())
        raw, candidate, token, _, _ = self.preview()
        def data(raw):
            return {"iid": self.iid, "cid": 10201, "level1": protocol.pb_get_varint(raw, 3), "level2": 0,
                    "atk": protocol.pb_get_varint(raw, 6), "defense": protocol.pb_get_varint(raw, 7), "hp": protocol.pb_get_varint(raw, 8),
                    "speed": protocol.pb_get_varint(raw, 9), "potential": protocol.pb_get_varint(raw, 17), "skilllevel": 0}
        for target in (page, window): target.data = lua.table_from({"general": data(raw)}, recursive=True)
        page.rootItems = lua.globals()["items"]()
        page.generalsdata = lua.table_from({"1": data(raw)}, recursive=True)
        page.generalindex, page.selectpage = 1, "train"
        page.setPage_train(page)
        self.assertEqual((lua.globals().requests[len(lua.globals().requests)].type, lua.globals().requests[len(lua.globals().requests)].method), (1013, 0))
        window.trainItems = lua.globals()["items"]()
        window.touchPriority, window.pagetype = -100, "train"
        window.setPage_train(window)
        self.assertEqual(lua.globals().requests[len(lua.globals().requests)].id, self.iid)
        lua.globals().GameScene.layers.generalup = lua.table_from({"show": True, "module": page})
        lua.globals().gameWindows.windows.generalInfo = lua.table_from({"show": True, "module": window})
        lua.execute(scripts["assets/scripts/UIGenerals.so"].decode())
        result = lua.table_from({"extGeneralData": data(raw), "previewGeneralData": data(candidate), "token": token, "prop": 1, "remaining": self.props(20009)}, recursive=True)
        lua.globals().UIGeneralFosterPreview(result)
        self.assertEqual(page.rootItems.train_num2.text, self.props(20009))
        self.assertEqual(window.trainItems.num2.text, self.props(20009))
        page.rootItems.trainButton2.callback()
        request = lua.globals().requests[len(lua.globals().requests)]
        self.assertEqual((request.type, request.id, request.token, request.opt), (1014, self.iid, token, 1))
        window.trainItems.doButton1.callback()
        request = lua.globals().requests[len(lua.globals().requests)]
        self.assertEqual((request.type, request.id, request.token, request.opt), (1014, self.iid, token, 0))
        page.localFosterToken, window.localFosterToken = 999, 999
        result.extGeneralData.iid, result.previewGeneralData.iid = 888, 888
        lua.globals().UIGeneralFosterPreview(result)
        self.assertEqual((page.localFosterToken, window.localFosterToken), (999, 999))
        page.ReloadData = lua.eval("function(self) self.reloaded=true end")
        window.reloaddata = lua.eval("function(self) self.reloaded=true end")
        lua.globals().UIGeneralFosterConfirm(lua.table_from({"general": {"iid": 888}}, recursive=True))
        self.assertIsNone(page.reloaded)
        self.assertIsNone(window.reloaded)
        lua.globals().gameWindows.windows.generalInfo.show = False
        lua.globals().GameScene.layers.generalup.show = False
        lua.globals().UIGeneralFosterPreview(result)
        self.assertEqual((page.localFosterToken, window.localFosterToken), (999, 999))


if __name__ == "__main__":
    unittest.main()
