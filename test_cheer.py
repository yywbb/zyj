import copy
from contextlib import redirect_stdout
from fractions import Fraction
import io
import json
import struct
import unittest
from unittest.mock import patch
import zipfile

import build_local_apk as builder
import test_mock_server
import test_penglai
from zyj_server import battle, cheer, development, formation, player, protocol, recharge, recruit, single_boss, training


class CheerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        test_penglai.PenglaiTests.setUpClass.__func__(cls)
        cls.baseline = copy.deepcopy(cls.baseline)
        cls.baseline["role_state"].update(level=50, coin=200000000, gold=100000)

    reconnect = test_penglai.PenglaiTests.reconnect
    call = test_penglai.PenglaiTests.call
    give = test_penglai.PenglaiTests.give
    props = test_penglai.PenglaiTests.props
    assert_rejected = test_penglai.PenglaiTests.assert_rejected

    def setUp(self):
        test_penglai.PenglaiTests.setUp(self)
        owned = {protocol.pb_get_varint(v, 1) for v in self.records(1, 2).values()}
        related = {int(cid) for raw in self.records(1, 2).values()
                   for i in range(1, 30) for cid in self.config["general"][str(protocol.pb_get_varint(raw, 1))].get(f"cond{i}ids", "").split(";") if cid}
        self.iids = []
        for cid, row in sorted(self.config["general"].items(), key=lambda p: int(p[0])):
            if (row["battle"] and row["quality"] in (3, 4, 5) and row["init_cid"] == int(cid)
                    and int(cid) not in owned | related):
                iid = 2000900 + len(self.iids)
                self.put(recruit.new_general(int(cid), iid, self.config))
                self.iids.append(iid)
                if len(self.iids) == 9:
                    break
        self.path.write_text(json.dumps(self.session.save))

    def records(self, field, key):
        return formation.records(bytes.fromhex(self.session.save["world_state"]["1002"]), field, key)

    def put(self, raw):
        player.record_slot_update(self.session.save, protocol.encode_pb_field(1, 2, raw))

    def assign(self, pos, iid=None, origin=None):
        self.sequence += 1
        body = protocol.encode_pb_field(1, 0, pos) + protocol.encode_pb_field(2 if origin is not None else 3, 0, origin if origin is not None else iid)
        packets = self.session.handle(1004, self.sequence, body)
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 1004)
        return packets, body

    def grow(self, iid, level):
        raw = self.records(1, 2)[iid]
        row = self.config["general"][str(protocol.pb_get_varint(raw, 1))]
        gained = sum(self.config["general_exp"][str(lv)][f'{row["quality"]}exp'] for lv in range(protocol.pb_get_varint(raw, 3), level))
        raw, _, _ = training.grow_general(raw, gained, b"", set(), {}, self.config, level)
        self.put(raw)

    def fill(self, level=1):
        for pos, iid in enumerate(self.iids[:8], 1):
            self.grow(iid, level)
            self.assign(pos, iid)

    def test_native_assignment_swap_clear_and_reconnect_keep_real_owned_members(self):
        before = copy.deepcopy(self.session.save)
        packets, body = self.assign(1, self.iids[0])
        self.assertEqual(protocol.pb_get_varint(self.records(5, 1)[1], 2), self.iids[0])
        self.assertEqual(self.session.handle(1004, self.sequence, body), packets)
        self.assign(2, self.iids[1])
        self.assign(1, origin=2)
        self.assertEqual([protocol.pb_get_varint(self.records(5, 1)[p], 2) for p in (1, 2)], self.iids[1::-1])
        self.assign(1, 0)
        self.session = self.reconnect()
        self.assertEqual(protocol.pb_get_varint(self.records(5, 1)[1], 2), 0)
        self.assertEqual(protocol.pb_get_varint(self.records(5, 1)[2], 2), self.iids[0])
        self.assertEqual(self.session.save["guide"], before["guide"])
        self.assertEqual(self.session.save["role_state"]["gold"], before["role_state"]["gold"])

    def test_full_team_bonus_is_real_reversible_and_never_accumulates_on_queries(self):
        before = self.records(1, 2)
        power = self.session.save["role_state"]["power"]
        self.fill(50)
        active = self.records(4, 2)
        for iid in active:
            if not iid:
                continue
            raw, changed = before[iid], self.records(1, 2)[iid]
            row = self.config["general"][str(protocol.pb_get_varint(raw, 1))]
            base = battle.general_base(row, "atk", protocol.pb_get_varint(raw, 3), protocol.pb_get_varint(raw, 4) or 0, self.config)
            self.assertEqual(protocol.pb_get_varint(changed, 6)-protocol.pb_get_varint(raw, 6), 750+int(base*Fraction(1, 100)))
            self.assertEqual(protocol.pb_get_varint(changed, 7)-protocol.pb_get_varint(raw, 7), 430)
            self.assertEqual(protocol.pb_get_varint(changed, 8)-protocol.pb_get_varint(raw, 8), 2500)
        current = self.records(1, 2)
        self.call(1002)
        self.call(1002)
        self.session = self.reconnect()
        self.assertEqual(self.records(1, 2), current)
        self.assign(8, 0)
        self.assertEqual({i: self.records(1, 2)[i] for i in active if i}, {i: before[i] for i in active if i})
        self.assertEqual(self.session.save["role_state"]["power"], power)

    def test_all_unlock_boundaries_and_malformed_requests_are_non_mutating(self):
        for level, count in ((26, 0), (27, 1), (29, 2), (32, 3), (36, 4), (39, 5), (42, 6), (46, 7), (50, 8)):
            self.session.save["role_state"]["level"] = level
            self.assertEqual(self.config["role_exp"][str(level)]["cheernum"], count)
            if count < 8:
                self.assert_rejected(1004, protocol.encode_pb_field(1, 0, count+1)+protocol.encode_pb_field(3, 0, self.iids[0]))
        for body in (b"", b"\x08", b"\x08\x00\x18\x00", b"\x08\x09\x18\x00", b"\x08\x01\x10\x00",
                     b"\x08\x01\x10\x01\x18\x00", b"\x08\x01\x18\x00\x18\x00", b"\x0a\x00\x18\x00",
                     recharge.ids([1, self.iids[0]])):
            self.assert_rejected(1004, body)
        self.assert_rejected(999900, protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 1004)))

    def test_main_protagonist_and_advanced_members_are_protected(self):
        baseline = copy.deepcopy(self.session.save)
        protagonist = protocol.pb_get_varint(bytes.fromhex(baseline["protagonist_snapshot"]), 1)
        for iid in (protagonist, 123456789):
            self.assert_rejected(1004, protocol.encode_pb_field(1, 0, 1)+protocol.encode_pb_field(3, 0, iid))
        self.session.save = baseline
        raw = self.records(1, 2)[self.iids[0]]
        for changed in (protocol.pb_set_varint(raw, 21, 1), protocol.pb_set_varint(raw, 4, 11),
                        raw+protocol.encode_pb_field(41, 2, recharge.ids([1]))):
            self.put(changed)
            self.assert_rejected(1004, protocol.encode_pb_field(1, 0, 1)+protocol.encode_pb_field(3, 0, self.iids[0]))

    def test_dedicated_members_can_join_replace_and_swap_supports_without_changing_saved_teams(self):
        self.call(3702, [140, 1])
        self.call(3702, [140, 2])
        for kind, iid in (("1", self.iids[0]), ("2", self.iids[1])):
            self.session.save["single_boss_state"]["teams"][kind][6] = iid
        teams = copy.deepcopy(self.session.save["single_boss_state"]["teams"])
        self.assign(1, self.iids[0])
        self.assign(1, self.iids[1])
        self.assign(2, self.iids[0])
        self.assign(1, origin=2)
        self.session = self.reconnect()
        self.assertEqual(self.session.save["single_boss_state"]["teams"], teams)
        self.assertEqual([protocol.pb_get_varint(self.records(5, 1)[p], 2) for p in (1, 2)], self.iids[:2])
        for kind in (1, 2):
            self.assertEqual(protocol.parse_ids_pb(self.call(3702, [140, kind])[0][16:])[:8], teams[str(kind)])

    def test_dedicated_projection_excludes_its_active_support_identity_and_full_team_bonus(self):
        self.fill(50)
        self.call(3702, [140, 1])
        self.call(3702, [140, 2])
        team = self.session.save["single_boss_state"]["teams"]["1"]
        team[6] = self.iids[0]
        self.session.save["single_boss_state"]["teams"]["2"] = list(team)
        before = copy.deepcopy(self.session.save)
        projected, _ = single_boss.project_team(self.session.save, team, self.config)
        self.assertEqual(self.session.save, before)
        self.assertEqual(len(cheer.combat(projected, self.config)), 7)
        self.assertNotIn(protocol.pb_get_varint(self.records(1, 2)[self.iids[0]], 1), cheer.combat(projected, self.config))
        self.assertEqual(cheer.tiers(projected, self.config), ())
        protagonist = protocol.pb_get_varint(bytes.fromhex(before["protagonist_snapshot"]), 1)
        original = self.records(1, 2)[protagonist]
        current = formation.records(bytes.fromhex(projected["world_state"]["1002"]), 1, 2)[protagonist]
        bonus = cheer.attributes(original, cheer.tiers(before, self.config), self.config)
        for field in (6, 7, 8):
            self.assertEqual(protocol.pb_get_varint(current, field), protocol.pb_get_varint(original, field) - bonus[field])
        same, _ = single_boss.project_team(self.session.save, team, self.config)
        self.assertEqual(projected["world_state"], same["world_state"])
        kind = single_boss.boss_type(self.session.save["single_boss_state"], self.config)
        packets = self.call(3701, [single_boss.levels(self.config, kind)[0]["id"]])
        report = json.loads(next(v for n, w, v in protocol.iter_pb_fields(packets[0][16:]) if n == 5))
        self.assertEqual(report["meta"]["attack"]["cheer"], cheer.combat(projected, self.config))
        self.assertEqual(self.session.save["world_state"]["1002"], before["world_state"]["1002"])

    def test_native_errors_and_save_failure_do_not_leave_half_an_assignment(self):
        memory, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        body = protocol.encode_pb_field(1, 0, 1)+protocol.encode_pb_field(3, 0, self.iids[0])
        with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
            self.session.handle(1004, 990, body)
        self.assertEqual((self.session.save, self.path.read_bytes()), (memory, disk))
        packets = self.session.handle(1004, 990, body)
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 1004)
        self.assertEqual(json.loads(self.path.read_text())["world_state"], self.session.save["world_state"])

    def test_minimum_level_upgrade_crosses_one_tier_and_refreshes_all_main_members(self):
        self.fill(10)
        self.assign(8, 0)
        self.grow(self.iids[8], 9)
        self.assign(8, self.iids[8])
        before, rows = self.records(1, 2), cheer.tiers(self.session.save, self.config)
        self.give(20199, 1)
        pills = self.props(20199)
        body = protocol.encode_pb_field(1, 0, self.iids[8])+b"".join(protocol.encode_pb_field(2, 0, n) for n in (0, 0, 0, 1))
        packets = self.session.handle(1038, 991, body)
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 1038)
        self.assertEqual(cheer.tiers(self.session.save, self.config)[0]["type_coefficient"], 10)
        self.assertIn(1027, [struct.unpack(">IIII", p[:16])[2] for p in packets])
        for iid in self.records(4, 2):
            if not iid: continue
            old, new = cheer.attributes(before[iid], rows, self.config), cheer.attributes(before[iid], cheer.tiers(self.session.save, self.config), self.config)
            for f in old:
                self.assertEqual(protocol.pb_get_varint(self.records(1, 2)[iid], f)-protocol.pb_get_varint(before[iid], f), new[f]-old[f])
        self.assertEqual(self.props(20199), pills-1)

    def test_breakthrough_requires_all_eight_at_the_threshold_not_total_levels(self):
        self.fill(50)
        self.give(20017, 100000)
        before = self.records(1, 2)
        for index, iid in enumerate(self.iids[:8]):
            cid = protocol.pb_get_varint(self.records(1, 2)[iid], 1)
            self.call(1017, [cid, 0])
            self.assertEqual(cheer.tiers(self.session.save, self.config)[1]["type_coefficient"], int(index == 7))
        for iid in self.records(4, 2):
            if not iid: continue
            raw = before[iid]
            base = battle.general_base(self.config["general"][str(protocol.pb_get_varint(raw, 1))], "atk", protocol.pb_get_varint(raw, 3), protocol.pb_get_varint(raw, 4) or 0, self.config)
            self.assertEqual(protocol.pb_get_varint(self.records(1, 2)[iid], 6)-protocol.pb_get_varint(raw, 6), 30+int(base*Fraction(1, 100)))

    def test_assigned_partner_keeps_real_pill_cultivation_costs_and_safe_rebirth_receipt(self):
        iid = self.iids[0]
        self.assign(1, iid)
        self.give(20196, 1)
        self.give(20009, 1)
        pills = (self.props(20196), self.props(20009))
        self.session.handle(1038, 991, protocol.encode_pb_field(1, 0, iid)+b"".join(protocol.encode_pb_field(2, 0, n) for n in (1, 0, 0, 0)))
        packet = self.session.handle(1013, 992, protocol.encode_pb_field(1, 0, iid)+protocol.encode_pb_field(2, 0, 1))[0]
        self.assertEqual(struct.unpack(">IIII", packet[:16])[2], 1013)
        token = self.session.save["general_foster_state"]["pending"][str(iid)]["token"]
        self.session.handle(1014, 993, b"".join(protocol.encode_pb_field(n, 0, v) for n, v in ((1, iid), (2, 1), (3, token))))
        rebirth = recharge.ids([iid])
        self.assert_rejected(1035, rebirth)
        self.assign(1, 0)
        packets = self.session.handle(1035, 994, rebirth)
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 1035)
        self.assertEqual((self.props(20196), self.props(20009)), pills)

    def test_real_relations_survive_growth_and_are_removed_without_erasing_training(self):
        actor, partner = 2000920, 2000921
        for cid, iid in ((10213, actor), (10214, partner)):
            self.put(recruit.new_general(cid, iid, self.config))
        self.session.handle(1003, 981, protocol.encode_pb_field(1, 0, 3)+protocol.encode_pb_field(3, 0, actor))
        raw = self.records(1, 2)[actor]
        self.assign(1, partner)
        self.assertEqual(protocol.pb_get_varint(self.records(1, 2)[actor], 6)-protocol.pb_get_varint(raw, 6),
                         int(battle.general_base(self.config["general"]["10213"], "atk", 1, 0, self.config)*Fraction(16, 100)))
        self.give(20196, 1)
        self.session.handle(1038, 982, protocol.encode_pb_field(1, 0, actor)+b"".join(protocol.encode_pb_field(2, 0, n) for n in (1, 0, 0, 0)))
        grown = self.records(1, 2)[actor]
        self.assign(1, 0)
        expected = int(battle.general_base(self.config["general"]["10213"], "atk", protocol.pb_get_varint(grown, 3), 0, self.config)*Fraction(16, 100))
        self.assertEqual(protocol.pb_get_varint(grown, 6)-protocol.pb_get_varint(self.records(1, 2)[actor], 6), expected)

    def test_dedicated_projection_preserves_supports_and_does_not_stack_global_attributes(self):
        self.fill(50)
        slots = self.records(4, 1)
        team = [protocol.pb_get_varint(slots.get(i, b""), 2) or 0 for i in range(1, 8)]+[0]
        before = copy.deepcopy(self.session.save)
        temporary, power = single_boss.project_team(self.session.save, team, self.config)
        self.assertEqual(self.session.save, before)
        self.assertEqual(formation.records(bytes.fromhex(temporary["world_state"]["1002"]), 1, 2), self.records(1, 2))
        self.assertEqual(power, self.session.save["role_state"]["power"])
        self.assertEqual(cheer.combat(temporary, self.config), cheer.combat(self.session.save, self.config))

    def test_campaign_report_has_actual_support_cids_without_extra_combat_units(self):
        self.fill()
        before = {i: self.records(1, 2)[i] for i in self.iids[:8]}
        packets = self.call(1306, [42102, 2])
        report = json.loads(next(v for n, w, v in protocol.iter_pb_fields(packets[0][16:]) if n == 5))
        self.assertEqual(report["meta"]["attack"]["cheer"], cheer.combat(self.session.save, self.config))
        self.assertEqual(len(report["b"]["init"]["attack"]), len([i for i in self.records(4, 2) if i]))
        self.assertEqual({i: self.records(1, 2)[i] for i in before}, before)

    def test_last_assignment_overflow_and_duplicate_origin_fail_atomically(self):
        for pos, iid in enumerate(self.iids[:7], 1):
            self.grow(iid, 50)
            self.assign(pos, iid)
        self.grow(self.iids[7], 50)
        iid = next(i for i in self.records(4, 2) if i)
        self.put(protocol.pb_set_varint(self.records(1, 2)[iid], 6, (1<<31)-1))
        self.assert_rejected(1004, protocol.encode_pb_field(1, 0, 8)+protocol.encode_pb_field(3, 0, self.iids[7]))
        self.put(recruit.new_general(protocol.pb_get_varint(self.records(1, 2)[self.iids[0]], 1), self.iids[8], self.config))
        self.assert_rejected(1004, protocol.encode_pb_field(1, 0, 8)+protocol.encode_pb_field(3, 0, self.iids[8]))

    def test_main_growth_and_protagonist_template_changes_keep_percent_bonus_exactly_once(self):
        self.fill(50)
        iid = protocol.pb_get_varint(bytes.fromhex(self.session.save["protagonist_snapshot"]), 1)
        raw, slot = self.records(1, 2)[iid], self.records(4, 2)[iid]
        rows, members, equips = cheer.tiers(self.session.save, self.config), cheer.members(self.session.save, self.config), self.records(2, 1)
        bare, _ = development.adjust(raw, {f: -v for f, v in cheer.attributes(raw, rows, self.config).items()})
        gained = int(self.config["props"]["20199"]["param1"])
        grown, _, _ = training.grow_general(bare, gained, slot, members, equips, self.config, 100)
        expected, _ = development.adjust(grown, cheer.attributes(grown, rows, self.config))
        self.give(20199, 1)
        packets = self.session.handle(1038, 996, protocol.encode_pb_field(1, 0, iid)+b"".join(protocol.encode_pb_field(2, 0, n) for n in (0, 0, 0, 1)))
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 1038)
        self.assertEqual(self.records(1, 2)[iid], expected)
        snapshot = bytes.fromhex(self.session.save["protagonist_snapshot"])
        row = self.config["protagonist_grow"][str(protocol.pb_get_varint(snapshot, 3)+1)]
        cid = row[f'general{self.session.save["selected_general_id"]}']
        trained = {f: protocol.pb_get_varint(snapshot, f-2) or 0 for f in (6, 7, 8)}
        plain, _, _ = development.grow_protagonist(grown, row, cid, trained, slot, members, equips, self.config)
        expected, _ = development.adjust(plain, cheer.attributes(plain, rows, self.config))
        changed, _, _ = development.grow_protagonist(self.records(1, 2)[iid], row, cid, trained, slot, members, equips, self.config, cheer_tiers=rows)
        self.assertEqual(changed, expected)

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

    def test_actual_network_pb_serializes_mutations_clears_empty_members_and_unlocks_on_errors(self):
        import test_activity_copy
        lua = test_activity_copy.ActivityCopyTests.network_lua(self)
        for name in ("slots_pb", "generals_pb", "combmessages_pb", "generalchangepos_pb", "apex_slots_pb", "error_pb", "params_pb"):
            lua.execute(builder.read_script(name, "pb"))
        lua.execute(b'''package.loaded.socket={}
            table.copy=function(t) local r={} for k,v in pairs(t) do r[k]=type(v)=="table" and table.copy(v) or v end return r end
            gamedata.cache.generals={};gamedata.cache.slots={};gamedata.cache.cheers={};gamedata.cache.protagonist={iid=1}
            gamedata.cache.role.level=50;gamedata.cache.generalfragments={};gamedata.sortData=function() end
            gamedata.relationData=function(self,r) return r end
            gamedata.Generals=function(self,rows) for _,r in ipairs(rows) do self.cache.generals[r.iid]={iid=r.iid,cid=r.cid,level1=r.level,level2=r.level2} end end
            for _,name in ipairs({"Slots","Protagonist","Equips","Souls","Gems","Newartifact","Jewel","slotGems"}) do gamedata[name]=function() end end
            mekehintext=function() end; CheckArtifactAllHint=function() end
            package.loaded.logError={errorMessage={},errorFunc={}};printf=function() end
            initPb=function(mod,fd) local m=mod.Ids();m:ParseFromString(fd.rbuf);return m end''')
        scripts = self.client_scripts()
        lua.execute(scripts["assets/pb/localcoverupdate_pb.so"])
        lua.globals().cheer_shop = builder.read_script("GameActivitySafeMaskShop")
        lua.execute(b'package.preload.GameActivitySafeMaskShop=assert(loadstring(cheer_shop,"GameActivitySafeMaskShop"))')
        code = scripts["assets/scripts/gamedata.so"].decode()
        start = code.index("function gamedata.cheerData(")
        lua.execute(code[start:code.index("function gamedata.slotgemData(", start)].encode())
        start = code.index("function gamedata.SlotInfoProcess(")
        lua.execute(code[start:code.index("\nend", start)+4].encode())
        lua.execute(scripts["assets/scripts/GameSlots.so"])
        lua.execute(scripts["assets/common_lua/GameErrorMessage.so"])
        for name in ("makeEquipsTemp", "makeSoulsByQualityAll", "makeSlotInfo", "makeOffEquip", "makeOffTreasure", "makeOnEquipsForSlot", "makeSlotGeminfo", "makeMofulist"):
            lua.globals()[name.encode()] = lua.eval(b"function() return {} end")
        lua.globals().makeEquipsByTypeAll = lua.eval(b"function() return {treasures={},horse={},treasure={}} end")
        code = scripts["assets/scripts/GameSlots.so"].decode()
        start = code.index("function NetSlotsAllInfoCallBack(fd)\n")
        lua.execute(b'local slots_pb=require("slots_pb")\n'+code[start:code.index("\nfunction ", start+1)].encode())
        fd = lambda raw: lua.table_from({b"rbuf": raw})
        lua.globals().NetSlotsAllInfoCallBack(fd(self.call(1002)[0][16:]))
        req = lua.table_from({b"pos1": 1, b"iid": self.iids[0]})
        mode, opcode, body = lua.globals().UIChangeCheerCallBack(req)
        self.assertEqual((mode, opcode), (1, 1004))
        self.assertEqual({n: v for n, w, v in protocol.iter_pb_fields(body)}, {1: 1, 3: self.iids[0]})
        self.assertEqual(lua.globals().UIChangeSlotCallBack(lua.table_from({b"pos1": 2, b"iid": self.iids[1]}))[0], 0)
        result = lua.globals().NetChangecheerCallBack(fd(self.session.handle(1004, 980, body)[0][16:]))
        self.assertEqual(result[b"changelslot"][b"iid"], self.iids[0])
        self.assertEqual(lua.globals().makeAllGeneralsTemp()[self.iids[0]][b"ison"], 1)
        req[b"iid"] = 0
        _, _, body = lua.globals().UIChangeCheerCallBack(req)
        lua.globals().NetChangecheerCallBack(fd(self.session.handle(1004, 981, body)[0][16:]))
        self.assertIsNone(lua.globals().gamedata[b"cache"][b"cheers"][1])
        self.assertIsNone(lua.globals().makeAllGeneralsTemp()[self.iids[0]][b"ison"])
        lua.globals().gamedata[b"cache"][b"cheers"][8] = lua.table_from({b"sid": 8, b"general": self.iids[0]})
        lua.globals().NetSlotsAllInfoCallBack(fd(self.call(1002)[0][16:]))
        self.assertIsNone(lua.globals().gamedata[b"cache"][b"cheers"][8])
        lua.globals().UIChangeCheerCallBack(req)
        lua.globals().NetErrorMessageCallback9(fd(recharge.ids([1005, 0])))
        self.assertIsNotNone(lua.globals().gamedata[b"ext"][b"localFormationBusy"])
        lua.globals().NetErrorMessageCallback9(fd(recharge.ids([1004, 0])))
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localFormationBusy"])
        self.assertEqual(lua.globals().UIChangeCheerCallBack(req)[0], 1)
        self.assertIsNone(lua.globals().gameConfig)

    def test_actual_existing_buttons_add_upgrade_remove_and_reject_late_window_callbacks(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("实际APK界面验证需要lupa.lua51")
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute('''print=function() end;printT=print;CCControlEventTouchUpInside=1
            requests={};UIRequest=function(t) requests[#requests+1]=t end
            runGamePrompt=function(t) prompt=t.msg end
            function node() return setmetatable({enabled=true}, {__index=function(t,k)
                if k=="addHandleOfControlEvent" then return function(self,f) self.callback=f end end
                if k=="setString" then return function(self,v) self.text=v end end
                if k=="setEnabled" then return function(self,v) self.enabled=v end end
                return function() end end}) end
            function items() return setmetatable({}, {__index=function(t,k) local n=node();rawset(t,k,n);return n end}) end
            ui=setmetatable({setLabelString=function(n,v) if v then n:setString(v) end end,judgeFeiSheng=function() return false end,
                addGray=function(kind,n) n.gray=true end,removeGray=function(kind,n) n.gray=false end},
                {__index=function() return function() end end})
            gameConfig={checkBuildOpen=function() return true end,strings={string_common=function() return "label" end}}
            GameScene={protagonist={iid=1},checkopenlevelbyId=function() return true end,
                shiftLayer=function(self,name,way,data) destination=data end}
            gameWindows={closeWindowDirect=function(self,name) closed=name end,
                openWindow=function(self,name,data,callback) selection=callback end}''')
        code = self.client_scripts()["assets/scripts/window_generalInfo_role.so"].decode()
        start = code.index("    ui.setLabelString(self.infoItems.doLab1,")
        end = code.index("    self:getMessage(generalConfig)", start)
        lua.execute("function configure(self) local cheerGeneration=self.localCheerGeneration; local cheerIID,cheerSID=self.data.general.iid,self.cheersid; local generalConfig={quality=3,awaken=0};\n"+code[start:end]+"\nend")
        window = lua.table_from({"root": lua.globals().node(), "infoItems": lua.globals()["items"](), "opt": 3, "sid": 8,
                                 "cheersid": 2, "localCheerGeneration": 1, "touchPriority": -103,
                                 "data": {"general": {"cid": 10213, "iid": self.iids[0], "level1": 2, "level2": 0}}}, recursive=True)
        lua.globals().configure(window)
        self.assertEqual((window.infoItems.doLab4.text, window.infoItems.doLab7.text), ("升 级", "撤 下"))
        self.assertFalse(window.infoItems.doButton5.enabled)
        self.assertFalse(window.infoItems.doButton6.enabled)
        self.assertTrue(window.infoItems.doButton5.gray)
        self.assertTrue(window.infoItems.doButton6.gray)
        self.assertTrue(window.infoItems.doButton4.enabled)
        self.assertTrue(window.infoItems.doButton7.enabled)
        window.infoItems.doButton4.callback()
        self.assertEqual((lua.globals().destination.cid, lua.globals().destination.page), (10213, "up"))
        window.infoItems.doButton1.callback()
        window.data.general.iid = self.iids[1]
        lua.globals().selection(lua.table_from([{ "iid": self.iids[2]}], recursive=True))
        window.infoItems.doButton7.callback()
        self.assertEqual(len(lua.globals().requests), 0)
        window.data.general.iid = self.iids[0]
        window.localCheerGeneration += 1
        lua.globals().selection(lua.table_from([{ "iid": self.iids[1]}], recursive=True))
        window.infoItems.doButton7.callback()
        self.assertEqual(len(lua.globals().requests), 0)
        lua.globals().configure(window)
        window.infoItems.doButton7.callback()
        request = lua.globals().requests[1]
        self.assertEqual((request.type, request.pos1, request.iid), (1004, 2, 0))
        self.assertEqual(lua.globals().closed, "generalInfoRole")
        lua.execute(self.client_scripts()["assets/scripts/UISlots.so"].decode())
        lua.execute('GameScene.addUpdate=function() end;GameScene.UpdatePresentLayer=function() end;requests={};UICheerChange({})')
        self.assertEqual([r.type for r in lua.globals().requests.values()], [10021])
        with zipfile.ZipFile(builder.SRC_APK) as archive:
            ccb = [n for n in archive.namelist() if n.endswith(".ccbi") and "general" in n.lower()]
            self.assertTrue(any(b"doButton7" in archive.read(n) and b"doButton4" in archive.read(n) for n in ccb))


class CheerCombatTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.role_config = player.load_role_config(test_penglai.ROOT / "configs_sec5.zip")

    combat_unit = test_mock_server.ReplayRoutingTests.combat_unit
    combo_teams = test_mock_server.ReplayRoutingTests.combo_teams
    assert_battle_report = test_mock_server.ReplayRoutingTests.assert_battle_report
    client_scripts = classmethod(CheerTests.client_scripts.__func__)

    def cases(self):
        for sid in battle.MULTI_COMBOS:
            row = self.role_config["combskill"][str(sid)]
            for initiator in range(3 if row["cid3"] else 2):
                attack, defense, config = self.combo_teams(sid, initiator)
                actor = battle.POSITIONS[initiator]
                for mixed in ((False, True) if row["cid3"] else (False,)):
                    keep = {actor}
                    if mixed:
                        keep.add(next(pos for pos in attack if pos != actor))
                    support = [u["cid"] for p, u in attack.items() if p not in keep]
                    main = {p: u for p, u in attack.items() if p in keep}
                    for direct in (True, False):
                        yield sid, main if direct else defense, defense if direct else main, config, support, direct

    def test_all_37_combos_each_initiator_both_sides_and_mixed_support_are_real_deterministic_actions(self):
        for sid, attack, defense, config, support, direct in self.cases():
            with self.subTest(skill=sid, support=support, direct=direct):
                inputs = copy.deepcopy((attack, defense, support))
                options = {"attack_cheer" if direct else "defense_cheer": support, "max_rounds": 1}
                report = battle.simulate(attack, defense, config, 7, **options)
                self.assertEqual(report, battle.simulate(attack, defense, config, 7, **options))
                self.assertEqual((attack, defense, support), inputs)
                actions = [a for a in report["b"]["a"] if a["s"].get("S") == sid]
                self.assertTrue(actions)
                self.assertTrue(all(a["s"]["t"] == "x" and set(a["s"]["p"]) <= (attack if direct else defense).keys() for a in actions))
                self.assertEqual(report["meta"]["attack" if direct else "defense"]["cheer"], support)
                self.assert_battle_report(report)

    def test_support_never_resurrects_field_partner_or_prevents_a_real_loss(self):
        attack, defense, config = self.combo_teams(12622, 1)
        attack[2]["hp"] = 1
        defense = {2: self.combat_unit(10201, atk=1000, speed=2000, initial_ap=0)}
        report = battle.simulate(attack, defense, config, 7, attack_cheer=[attack[2]["cid"]], max_rounds=1)
        self.assertFalse(any(a["s"].get("S") == 12622 for a in report["b"]["a"]))
        actor = {8: {**attack[8], "hp": 1}}
        report = battle.simulate(actor, defense, config, 7, attack_cheer=[attack[2]["cid"]])
        self.assertFalse(report["result"])
        self.assertEqual(report["endmeta"]["attack"]["8"]["h"], 0)

    def test_missing_support_insufficient_ap_and_failed_probability_keep_existing_fallbacks(self):
        attack, defense, config = self.combo_teams(12990)
        others = [u["cid"] for p, u in attack.items() if p != 2]
        for support, ap, chance in ((others[:1], 4, 1), (others, 0, 1), (others, 4, 0)):
            attack[2]["initial_ap"] = ap
            config = {**config, "combskillprobability": {**config["combskillprobability"], "12990": dict.fromkeys((f"bout{i}" for i in range(1, 11)), chance)}}
            report = battle.simulate({2: attack[2]}, defense, config, 7, attack_cheer=support, max_rounds=1)
            self.assertFalse(any(a["s"].get("S") == 12990 for a in report["b"]["a"]))

    def test_support_damage_and_ap_use_only_the_actual_initiator_and_invalid_lists_are_rejected(self):
        attack, defense, config = self.combo_teams(12622)
        partner = attack[8]["cid"]
        report = battle.simulate({2: attack[2]}, defense, config, 1, attack_cheer=[partner], max_rounds=1)
        first = report["b"]["a"][0]
        self.assertEqual(first["s"], {"r": True, "p": [2], "t": "x", "S": 12622})
        self.assertEqual(next(d["m"]["m"] for d in first["e"] if not d["r"]), 84)
        self.assertEqual([(d["p"], d["ap"]) for d in first["e"] if d["r"] and "ap" in d], [(2, 0)])
        for invalid in ([partner, partner], [99999999], [True], [partner]*9):
            with self.assertRaises(ValueError):
                battle.simulate({2: attack[2]}, defense, config, 1, attack_cheer=invalid)

    def test_every_configured_bonus_row_selects_one_threshold_without_summing_previous_tiers(self):
        save = {"role_state": {"level": 150}}
        for kind, rows in self.role_config["cheer"].items():
            for row in rows.values():
                raw = recruit.new_general(10201, 2000901, self.role_config)
                raw = protocol.pb_set_varint(raw, 3, max(1, row["type_coefficient"]) if kind == "1" else 1)
                raw = protocol.pb_set_varint(raw, 4, row["type_coefficient"] if kind == "2" else 0)
                chosen = cheer.tiers(save, self.role_config, generals=[raw]*8)
                self.assertEqual(chosen[int(kind)-1], row)
                self.assertTrue(all(v >= 0 for v in cheer.attributes(raw, chosen, self.role_config).values()))

    def test_configured_flat_and_percent_bonuses_use_base_growth_not_aggregate_or_cumulative_tiers(self):
        raw = recruit.new_general(10201, 2000901, self.role_config)
        config = copy.deepcopy(self.role_config)
        row = config["general"]["10201"]
        row.update(atk=1000)
        rows = (config["cheer"]["1"]["50"], config["cheer"]["2"]["3"])
        expected = cheer.attributes(raw, rows, config)
        self.assertEqual(expected[6], 960)
        changed, _ = development.adjust(raw, {6: 1000000})
        self.assertEqual(cheer.attributes(changed, rows, config), expected)

    def test_all_support_and_mixed_reports_convert_actual_apk_animations_with_matching_final_hp_and_ap(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("实际APK动画验证需要lupa.lua51")
        lua = LuaRuntime()
        config = dict(self.role_config)
        with zipfile.ZipFile(test_penglai.ROOT / "configs_sec5.zip") as archive:
            for name in ("generalanimation", "skillanimation", "personalboss_att"):
                config[name] = json.loads(archive.read("5/"+name+".json"))
        lua.globals().gamedata = lua.table_from({"config": config}, recursive=True)
        lua.execute('''print=function() end;printT=print;battleScene={slotNum=7}
            table.getTableLength=function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
            CCFileUtils={sharedFileUtils=function(self) return self end,fullPathForFilename=function(self,p) return p end}
            ui={Split=function(s,sep) local t={} for v in string.gmatch(s,'[^'..sep..']+') do t[#t+1]=v end return t end}''')
        with zipfile.ZipFile(builder.SRC_APK) as archive:
            names, assets = archive.namelist(), {}
            lua.globals().CCFileUtils.isFileExist = lambda _, path: any(n.endswith("/"+path) for n in names)
            def asset(path):
                if path not in assets:
                    matches = [n for n in names if n.endswith("/"+path)]
                    self.assertEqual(len(matches), 1, path)
                    assets[path] = json.loads(archive.read(matches[0]))
                return lua.table_from(assets[path], recursive=True)
            lua.globals().LoadJsonFileToTable = asset
            lua.execute(self.client_scripts()["assets/scripts/battleReportConvert.so"].decode())
            lua.execute(builder.read_script("BattleReportAbbToKey").decode())
            for sid, attack, defense, config, support, direct in self.cases():
                with self.subTest(skill=sid, support=support, direct=direct):
                    report = battle.simulate(attack, defense, config, 7, max_rounds=2,
                                             **{"attack_cheer" if direct else "defense_cheer": support})
                    native = lua.table_from(json.loads(lua.globals().ReplaceAbbToKey(json.dumps(report))), recursive=True)
                    allies, enemies = lua.globals().getBattleInitSlotInfo(native)
                    animations, ext = lua.globals().convertBattleReportToAnimationSub(native, allies, enemies)
                    self.assertGreater(len(animations), 1)
                    for side, key in (("attack", "atk"), ("defense", "def")):
                        for pos, unit in report["endmeta"][side].items():
                            self.assertEqual((ext.endinfo[key][pos].hp, ext.endinfo[key][pos].ap), (unit["h"], unit["ap"]))


if __name__ == "__main__":
    unittest.main()
