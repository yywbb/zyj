"""神器打造→鉴定→穿戴：临时账号、真实配置和实际APK回调。"""

import copy
from fractions import Fraction
import json
import random
import unittest
import zipfile
from unittest.mock import patch

import build_local_apk as builder
import test_soul
import test_mock_server
from zyj_server import artifact, battle, cup, formation, friends, guild_war, player, protocol, ranking, recharge, single_boss, timebag


def setUpModule():
    test_soul.setUpModule()


class ArtifactTests(unittest.TestCase):
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
    client_call = test_soul.SoulTests.client_call
    assert_battle_report = test_mock_server.ReplayRoutingTests.assert_battle_report

    def setUp(self):
        test_soul.SoulTests.setUp(self)
        self.save["role_state"]["level"] = 60
        for cid in (20627, 20628, 20629, 20630, 20671, 20672):
            self.grant(cid, 200)

    def items(self):
        return artifact.read_world(self.save, self.config)[0]

    def forge(self, mode=0):
        raw = self.success(1, 5501, values=[mode])
        self.refresh()
        return artifact.iid(raw)

    def identify(self, key, prop=20672):
        raw = self.success(1, 5508, values=[key, prop])
        self.refresh()
        return raw

    def wear(self, key, sid=1):
        body = self.success(1, 5503, values=[sid, key, 1])
        self.refresh()
        return body

    def test_forge_normal_gold_and_batch_costs_and_inventory_survive_reconnect(self):
        before = copy.deepcopy(self.save)
        first, second = self.forge(), self.forge(1)
        self.assertEqual((artifact.values(self.items()[first])[1] // 100 % 10, artifact.values(self.items()[second])[1] // 100 % 10), (0, 1))
        rows = self.groups(self.success(1, 5515, values=[0, 10]))
        self.refresh()
        self.assertEqual(len(rows), 10)
        self.assertEqual(len(self.items()), 12)
        self.assertEqual(len({artifact.iid(raw) for raw in rows.values()}), 10)
        self.assertEqual([self.props(c) for c in (20627, 20628, 20629, 20630)], [80, 80, 80, 190])
        self.assertTrue(all(artifact.values(raw)[5] == 0 for raw in self.items().values()))
        self.assertEqual(self.save["role_state"], before["role_state"])
        committed = self.save["world_state"]["1002"]
        self.reconnect(); self.refresh()
        self.assertEqual(self.save["world_state"]["1002"], committed)
        self.assertEqual(set(self.items()), {first, second, *map(artifact.iid, rows.values())})

    def test_appraisal_and_wear_apply_real_attributes_once_and_unequip_restores_them(self):
        key = self.forge()
        before = copy.deepcopy(self.save)
        raw = self.identify(key, 20671)
        data = artifact.values(raw)
        self.assertEqual(data[5], 1)
        self.assertEqual(data[0], key)
        self.assertEqual(data[2], before["role_name"])
        self.assertEqual(self.props(20671), 199)
        self.assertEqual(self.save["role_state"]["power"], before["role_state"]["power"])
        original = self.gen()
        bonus = artifact.attributes(original, raw, self.config)
        self.wear(key)
        for field, amount in bonus.items():
            self.assertEqual(protocol.pb_get_varint(self.gen(), field), protocol.pb_get_varint(original, field) + amount)
        power = self.save["role_state"]["power"]
        self.wear(key)
        self.assertEqual(self.save["role_state"]["power"], power)
        self.reconnect(); self.refresh()
        attack, _ = battle.rosters(self.save, self.config["copy"]["42102"]["1"], self.config)
        unit = attack[2]
        self.assertEqual(unit["artifact"]["cid"], data[1])
        self.assertEqual(unit["artifact"]["skills"], [sid for sid in data[6:9] if sid])
        self.wear(0)
        for field in artifact.FIELDS.values():
            self.assertEqual(protocol.pb_get_varint(self.gen(), field), protocol.pb_get_varint(original, field))
        self.assertEqual(self.save["role_state"]["power"], before["role_state"]["power"])

    def test_all_twenty_four_forged_templates_use_real_config_not_experience_returns(self):
        for cid in (20627, 20628, 20629):
            self.grant(cid, 100)
        for row in self.config["trump"].values():
            if not row["appraiseMethod"]:
                continue
            with self.subTest(cid=row["id"]), patch.object(artifact, "choose", return_value=row):
                key = self.forge(row["goldTrump"])
                self.assertEqual(artifact.values(self.items()[key])[1], row["id"])
        self.assertEqual(len(self.items()), 24)

    def test_batch_appraisal_is_atomic_and_never_reidentifies_or_uses_wrong_gold_material(self):
        keys = [self.forge(), self.forge(1)]
        self.assert_rejected(5508, values=[keys[1], 20671])
        self.assert_rejected(5516, values=[keys[0], keys[0], 20672])
        rows = self.groups(self.success(1, 5516, values=[*keys, 20672]))
        self.refresh()
        self.assertEqual(set(map(artifact.iid, rows.values())), set(keys))
        self.assertEqual(self.props(20672), 198)
        self.assertTrue(all(artifact.values(raw)[5] == 1 for raw in rows.values()))
        self.assert_rejected(5508, values=[keys[0], 20672])
        third = self.forge()
        self.assert_rejected(5516, values=[third, keys[0], 20672])
        self.assertEqual(artifact.values(self.items()[third])[5], 0)

    def test_native_requests_limits_cost_shortfalls_unknown_operations_and_clock_rollback_are_atomic(self):
        for opcode in artifact.OPCODES:
            for raw in (b"\x08", b"\x10\x01", b"\x0a\x00", b"\x08\xff\xff\xff\xff\x7f"):
                self.assert_rejected(opcode, raw=raw)
        for opcode, values in ((5501, []), (5501, [2]), (5515, [0, 0]), (5515, [1, 11]),
                               (5508, [1, 20671]), (5503, [8, 0, 1]), (5503, [1, 0, 0])):
            self.assert_rejected(opcode, values=values)
        self.save["role_state"]["level"] = 57
        self.assert_rejected(5501, values=[0])
        self.save["role_state"]["level"] = 60
        player.change_item_count(self.save, 20629, -191, self.config, self.now)
        self.assert_rejected(5515, values=[0, 10])
        self.grant(20629, 100)
        self.forge()
        self.clock.return_value -= 1
        self.assert_rejected(5501, values=[0])
        for opcode in (5502, 5504, 5505, 5507, 5517, 5519, 5541):
            self.assert_rejected(opcode, values=[1])

    def test_failed_saves_and_same_connection_retries_never_charge_or_generate_twice(self):
        for opcode, values in ((5501, [0]), (5515, [1, 3])):
            session = self.sessions[1]
            memory, disk = copy.deepcopy(session.save), self.store.path(1).read_bytes()
            with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
                self.request(1, opcode, values=values)
            self.assertEqual((session.save, self.store.path(1).read_bytes()), (memory, disk))
            seq, body = self.seq+100, recharge.ids(values)
            first = session.handle(opcode, seq, body)
            committed, count = self.store.path(1).read_bytes(), len(artifact.read_world(session.save, self.config)[0])
            self.assertEqual(session.handle(opcode, seq, body), first)
            self.assertEqual(self.store.path(1).read_bytes(), committed)
            self.assertEqual(len(artifact.read_world(session.save, self.config)[0]), count)
            self.refresh()
        key = max(self.items())
        for opcode, values in ((5508, [key, 20672]),):
            memory, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
            with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
                self.request(1, opcode, values=values)
            self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (memory, disk))
        self.identify(key)
        memory, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 5503, values=[1, key, 1])
        self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (memory, disk))

    def test_partial_roster_pushes_preserve_other_artifacts_and_unknown_fields(self):
        first, second = self.forge(), self.forge(1)
        raw = self.items()[first] + protocol.encode_pb_field(99, 0, 7)
        player.record_slot_update(self.save, protocol.encode_pb_field(16, 2, raw))
        original = self.items()[second]
        updated = self.identify(first)
        self.assertEqual(self.items()[second], original)
        self.assertEqual(protocol.pb_get_varint(updated, 99), 7)
        self.assertEqual(len(self.items()), 2)
        self.assertEqual(artifact.iid(ranking.artifact(self.save, self.config)), first)

    def unit(self, kind=None, name=None, level=6, **changes):
        unit = {"cid": 10201, "iid": 10201, "level": 1, "advance": 0, "exp": 0,
                "atk": 100, "def": 0, "hp": 10000, "speed": 100, "initial_ap": 0,
                "skill": self.config["general"]["10201"]["skillid"], **changes}
        if kind:
            row = next(r for r in self.config["trump_skillRnd"][str(kind)].values() if r["name"] == name)
            unit["artifact"] = {"cid": {1:110001,2:110005,3:110009}[kind], "level": 0, "skills": [row[f"skill{level}"]]}
        return unit

    def test_every_real_artifact_skill_on_both_sides_is_deterministic_replayable_and_never_aliases_breakthroughs(self):
        count = 0
        for kind, rows in self.config["trump_skillRnd"].items():
            for row in rows.values():
                for level in range(1, 7):
                    for direct in (True, False):
                        with self.subTest(name=row["name"], level=level, direct=direct):
                            teams = {direct:{2:self.unit(int(kind), row["name"], level, speed=300, initial_ap=4)},
                                     not direct:{2:self.unit(iid=1),8:self.unit(iid=8)}}
                            original = copy.deepcopy(teams)
                            report = battle.simulate(teams[True], teams[False], self.config, 7, max_rounds=3)
                            self.assertEqual(report, battle.simulate(teams[True], teams[False], self.config, 7, max_rounds=3))
                            self.assertEqual(teams, original)
                            self.assert_battle_report(report)
                    count += 1
        self.assertEqual(count, 108)
        fake = self.unit()
        fake.update(advance=1)
        config = {**self.config, "general": {**self.config["general"], "10201": {**self.config["general"]["10201"], "break1":9000502}}}
        with self.assertRaisesRegex(ValueError, "9000502"):
            battle.simulate({2:fake}, {2:self.unit(iid=1)}, config, 7, max_rounds=1)

    def test_damage_families_use_configured_multipliers_and_strict_attack_comparisons(self):
        for name, enemy_atk, expected in (("神降", 100, 140), ("蔑视", 99, 145), ("蔑视", 100, 100),
                                          ("无畏", 101, 145), ("无畏", 100, 100)):
            for direct in (True, False):
                teams={direct:{2:self.unit(1,name,speed=300)},not direct:{2:self.unit(iid=1,atk=enemy_atk)}}
                report=battle.simulate(teams[True],teams[False],self.config,5,max_rounds=1)
                hit=next(a for a in report["b"]["a"] if a["s"].get("t")=="N")
                self.assertEqual(hit["e"][0]["m"]["m"],expected,(name,direct))

    def certain(self, name, kind):
        unit=self.unit(kind,name)
        config=copy.deepcopy(self.config)
        row=config["breakskill"][str(unit["artifact"]["skills"][0])]
        row["value2" if name=="屏障" else "value"]=1
        return unit,config,row["id"]

    def test_ap_skills_target_correct_units_and_trigger_only_once_per_round(self):
        for name,kind,skill in (("贪婪",3,False),("狂怒",3,True),("怒损",1,False),("怒蚀",1,True),
                                ("狂躁",2,False),("鼓舞",2,False)):
            actor,config,sid=self.certain(name,kind)
            actor.update(initial_ap=4 if skill else 0,speed=300)
            enemy=self.unit(iid=1,initial_ap=0,atk=50,speed=200)
            teams={True:{2:actor},False:{2:enemy,8:self.unit(iid=8,atk=200,speed=100)}}
            report=battle.simulate(teams[True],teams[False],config,8,max_rounds=1)
            events=[a for a in report["b"]["a"] if not a["s"] and any(d.get("E") and "ap" in d for d in a["e"])]
            self.assertEqual(len(events),1,name)
            d=events[0]["e"][0]
            self.assertEqual(d["r"], name not in ("怒损","怒蚀"),name)
            self.assertEqual(d["p"],8 if name=="怒蚀" else 2,name)
            self.assertIn("ap",d)
            self.assert_battle_report(report)

    def test_extra_attacks_are_plain_bounded_and_kill_effects_do_not_fire_from_counterattacks(self):
        for name in ("连击","残暴","嗜战"):
            actor,config,sid=self.certain(name,3)
            actor.update(atk=1000,speed=300)
            teams={True:{2:actor},False:{2:self.unit(iid=1,hp=1),8:self.unit(iid=8)}}
            report=battle.simulate(teams[True],teams[False],config,3,max_rounds=1)
            attacks=[a for a in report["b"]["a"] if a["s"].get("r") is True and a["s"].get("t") in ("N","k","x")]
            self.assertEqual(len(attacks),1 if name=="嗜战" else 2,name)
            self.assertTrue(all(a["s"]["t"]!="x" for a in attacks))
            self.assert_battle_report(report)
        actor,config,sid=self.certain("残暴",3)
        actor.update(atk=1000,parry=100,speed=1)
        report=battle.simulate({2:actor},{2:self.unit(iid=1,hp=1,speed=300),8:self.unit(iid=8)},config,1,max_rounds=1)
        self.assertEqual(sum(a["s"].get("r") is True and a["s"].get("t")=="N" for a in report["b"]["a"]),2)

    def test_barrier_counts_two_damage_events_expires_and_does_not_block_thunder_or_explosions(self):
        target,config,_=self.certain("屏障",2)
        target.update(speed=1)
        enemy={2:self.unit(iid=1,speed=300),8:self.unit(iid=8,speed=250),10:self.unit(iid=10,speed=200)}
        report=battle.simulate(enemy,{2:target},config,9,max_rounds=2)
        hits=[d["m"]["m"] for a in report["b"]["a"] if a["s"].get("r") is True and a["s"].get("t")=="N"
              for d in a["e"] if isinstance(d.get("m"),dict)]
        self.assertEqual(hits[:3],[0,0,100])
        report=battle.simulate({2:self.unit(iid=1,speed=300)},{2:target},config,9,max_rounds=2)
        hits=[d["m"]["m"] for a in report["b"]["a"] if a["s"].get("r") is True and a["s"].get("t") in ("N","k","x")
              for d in a["e"] if isinstance(d.get("m"),dict)]
        self.assertEqual(hits[0],0);self.assertGreater(hits[1],0)
        config["general"]["10201"]["break1"]=9000025
        report=battle.simulate({2:self.unit(iid=1,speed=300,advance=1,initial_ap=4)},{2:target},config,9,max_rounds=1)
        self.assertLess(report["endmeta"]["defense"]["2"]["h"],target["hp"])
        config["general"]["10201"]["break1"]=9000040
        report=battle.simulate({2:self.unit(iid=1,hp=1,advance=1,speed=1)},{2:target},config,9,max_rounds=1)
        self.assertLess(report["endmeta"]["defense"]["2"]["h"],target["hp"])
        self.assert_battle_report(report)

    def test_appraisal_scores_match_native_calculator_and_all_weighted_outputs_respect_mutex(self):
        from lupa.lua51 import LuaRuntime
        lua=LuaRuntime()
        lua.globals().gamedata=lua.table_from({"config":self.config},recursive=True)
        code=self.client_scripts()["assets/scripts/UIArtifact.so"].decode()
        start=code.index("function GetArtifctScore(");end=code.index("\nfunction ",start+1)
        lua.execute(code[start:end])
        keys=[]
        for kind,cid in ((1,110001),(2,110005),(3,110009)):
            with patch.object(artifact,"choose",return_value=self.config["trump"][str(cid)]): keys.append(self.forge())
        seen=set()
        for key in keys:
            for prop in (20671,20672):
                for seed in range(200):
                    raw=artifact.appraise(self.items()[key],prop,self.config,self.now,random.Random(seed))
                    d=artifact.values(raw);skills=[s for s in d[6:9] if s]
                    expected=sum(self.config["trump_rank"][str(v)]["score"] for v in d[3:5])
                    expected+=int(sum(self.config["breakskill"][str(s)]["integral"] for s in skills)*Fraction(str(self.config["trump_numskill"][str(len(skills)+1)]["weight"])))
                    self.assertEqual(d[28],expected)
                    native=lua.table_from({"cid":d[1],"isChecked":d[5],"attr1":d[3],"attr2":d[4],"skill1":d[6],"skill2":d[7],"skill3":d[8]})
                    self.assertEqual(lua.globals().GetArtifctScore(native),d[28])
                    self.assertEqual(len(artifact.skills(raw,self.config)),len(skills))
                    seen.update(skills)
        self.assertGreater(len(seen),60)

    def test_growth_swaps_replacement_dedicated_and_frozen_rosters_keep_artifact_differences(self):
        key=self.forge();self.identify(key);self.wear(key)
        self.grant(20199,20)
        iid=protocol.pb_get_varint(self.gen(),2)
        body=protocol.encode_pb_field(1,0,iid)+b"".join(protocol.encode_pb_field(2,0,n) for n in (0,0,0,10))
        self.success(1,1038,raw=body);self.refresh()
        grown=self.gen()
        frozen=cup.frozen(self.save,1,self.config)["snapshot"]
        war=guild_war.freeze(self.save)
        for snapshot in (frozen,war):
            roster,_=battle.rosters(snapshot,self.config["copy"]["42101"]["1"],self.config)
            self.assertEqual(roster[2]["artifact"]["cid"],artifact.values(self.items()[key])[1])
        before=copy.deepcopy(self.save)
        temporary,_=single_boss.project_team(self.save,[iid,0,0,0,0,0,0,0],self.config)
        self.assertEqual(self.save,before)
        self.assertEqual(artifact.assigned(temporary,self.config)[iid],self.items()[key])
        swap=protocol.encode_pb_field(1,0,1)+protocol.encode_pb_field(2,0,2)
        self.success(1,1003,raw=swap);self.refresh()
        self.assertEqual(self.gen(),grown)
        self.success(1,1003,raw=swap);self.refresh()
        self.wear(0)
        for snapshot in (frozen,war):
            roster,_=battle.rosters(snapshot,self.config["copy"]["42101"]["1"],self.config)
            self.assertIn("artifact",roster[2])
        raw=artifact.values(self.items()[key]);raw[3:5]=[10,10]
        player.record_slot_update(self.save,protocol.encode_pb_field(16,2,artifact.record(raw)))
        self.wear(key,2)
        slot=artifact.read_world(self.save,self.config)[1][2]
        other=protocol.pb_get_varint(slot,2)
        self.success(1,1003,raw=protocol.encode_pb_field(1,0,2)+protocol.encode_pb_field(3,0,0));self.refresh()
        self.assertEqual(protocol.pb_get_varint(artifact.read_world(self.save,self.config)[1][2],26),0)
        self.wear(key,1)
        self.assertNotIn(other,artifact.assigned(self.save,self.config))

    def test_public_projection_exposes_only_worn_artifacts_and_invalid_state_or_overflow_fails_closed(self):
        key=self.forge();self.identify(key);self.wear(key)
        hidden=self.forge(1)
        public=friends.public_slots(self.save)
        self.assertEqual([artifact.iid(v) for n,w,v in protocol.iter_pb_fields(public) if (n,w)==(16,2)],[key])
        self.assertNotEqual(key,hidden)
        self.save["artifact_state"]["serial"]=(1<<31)-1
        self.assert_rejected(5501,values=[0])
        self.save["artifact_state"]["serial"]=max(self.items())
        self.wear(0)
        original=self.gen()
        raw=original
        for field in (6,7,8): raw=protocol.pb_set_varint(raw,field,(1<<31)-1)
        player.record_slot_update(self.save,protocol.encode_pb_field(1,2,raw))
        self.assert_rejected(5503,values=[1,key,1])
        for state in (None,{}, {"serial":True,"checked_at":0},{"serial":1,"checked_at":-1}):
            with self.assertRaises(ValueError): artifact.get_state({**self.save,"artifact_state":state},self.config)

    def test_artifact_gift_requires_real_s80_and_simulated_tier4_payment_once_only(self):
        self.assert_rejected(2882,values=[130011])
        for step in range(1,self.sessions[1].step_counts[80]+1):
            self.success(1,201,raw=protocol.encode_pb_field(1,0,80)+protocol.encode_pb_field(2,0,step));self.refresh()
        self.success(1,2882,values=[130011]);self.refresh()
        self.assert_rejected(2881,values=[130011])
        body=b"".join(protocol.encode_pb_field(1,2,recharge.ids([v])) for v in (4,130011))
        order=self.records(self.success(1,115,raw=body))[0]
        self.success(1,116,values=[protocol.pb_get_varint(order,1)]);self.refresh()
        before=[self.props(c) for c in (20627,20628,20629,20630)]
        self.reconnect();self.refresh()
        self.success(1,2881,values=[130011]);self.refresh()
        self.assertEqual([self.props(c)-v for c,v in zip((20627,20628,20629,20630),before)],[10]*4)
        self.assertTrue(timebag.get_state(self.save,130011)["claimed"])
        self.assert_rejected(2881,values=[130011])

    def network_lua(self, *, native_protobuf=False):
        lua=test_soul.SoulTests.network_lua(self,native_protobuf=native_protobuf)
        code=self.client_scripts()["assets/scripts/gamedata.so"].decode()
        for name in ("artifactData","Newartifact"):
            start=code.index("function gamedata."+name+"(");end=code.find("\nfunction ",start+1)
            lua.execute(code[start:end].encode())
        lua.execute(b'gamedata.cache.artifacts={};require("GameArtifact")')
        lua.globals().seed_world=bytes.fromhex(self.save["world_state"]["1002"])
        lua.globals().seed_props=bytes.fromhex(self.save["world_state"]["1200"])
        lua.execute(b'local s=require("slots_pb").SlotS();s:ParseFromString(seed_world);gamedata:SlotInfoProcess(s);local p=require("idnums_pb").IdNums();p:ParseFromString(seed_props);gamedata:Props(p.idnums)')
        return lua

    def test_actual_network_pb_callbacks_forge_appraise_wear_and_batch_keep_native_nested_shape(self):
        lua=self.network_lua(native_protobuf=True)
        result=self.client_call(lua,1,"UIArtifactCastCallBack","NetArtifactCastCallBack",{"isUse":True,"props":[]})
        key=result[b"rewardArtifact"][1][b"iid"]
        self.assertEqual(lua.globals().gamedata[b"cache"][b"props"][20630][b"num"],190)
        result=self.client_call(lua,1,"UIArtifactCheckCallBack","NetArtifactCheckCallBack",{"iid":key,"useId":20672})
        self.assertEqual(result[b"rewardArtifact"][1][b"isChecked"],1)
        mode,mid,raw=lua.globals().UIArtifactChangeCallBack(lua.table_from({b"sid":1,b"iid":key}))
        self.assertEqual(protocol.parse_ids_pb(raw),[1,key,1])
        result=lua.globals().NetArtifactChangeCallBack(lua.table_from({b"rbuf":self.success(1,mid,raw=raw)}))
        self.assertEqual(result[b"data"][key][b"sid"],1)
        result=self.client_call(lua,1,"UIArtifactChangeCallBack","NetArtifactChangeCallBack",{"sid":1,"iid":0})
        self.assertIsNone(result[b"data"][key][b"sid"])
        result=self.client_call(lua,1,"UIUserArtifactOnceMakeCallBack","NetUserArtifactOnceMakeCallBack",{"curType":0,"count":3})
        keys=[result[b"artifactList"][i][1][b"iid"] for i in range(1,4)]
        req=lua.table_from({b"curList":lua.table_from({str(i).encode():lua.table_from({b"iid":k}) for i,k in enumerate(reversed(keys),1)}),b"itemID":20671})
        mode,mid,raw=lua.globals().UIUserArtifactOnceCheckupCallBack(req)
        self.assertEqual(protocol.parse_ids_pb(raw),[*sorted(keys),20671])
        result=lua.globals().NetUserArtifactOnceCheckupCallBack(lua.table_from({b"rbuf":self.success(1,mid,raw=raw)}))
        self.assertEqual(result[b"artifactList"][1][1][b"isChecked"],1)
        self.assertEqual(lua.globals().gamedata[b"cache"][b"props"][20671][b"num"],197)
        self.assertIsNone(lua.globals().gameConfig)

    def test_native_network_fifo_errors_seq_zero_and_late_duplicates_cannot_charge_twice(self):
        lua=self.network_lua(native_protobuf=True)
        fd=lambda raw,seq=1:lua.table_from({b"rbuf":raw,b"ser":seq})
        for generation in (1,2):
            lua.globals().UIArtifactCheckTimeCallBack(lua.table_from({b"artifactView":lua.table_from({b"generation":generation})}))
        raw=self.success(1,5509)
        self.assertTrue(lua.globals().NetArtifactCheckTimeCallBack(fd(raw,0))[b"localArtifactIgnored"])
        for generation in (1,2):
            self.assertEqual(lua.globals().NetArtifactCheckTimeCallBack(fd(raw))[b"artifactView"][b"generation"],generation)
        mode,mid,raw=lua.globals().UIArtifactCastCallBack(lua.table_from({b"isUse":False}))
        self.assertEqual(protocol.parse_ids_pb(raw),[0])
        self.assertEqual(lua.globals().UISoulHuntCallBack(lua.table_from({b"param":1}))[0],0)
        lua.globals().NetErrorMessageCallback9(fd(recharge.ids([5508,0])))
        self.assertIsNotNone(lua.globals().gamedata[b"ext"][b"localFormationBusy"])
        packet=self.success(1,mid,raw=raw)
        lua.globals().NetArtifactCastCallBack(fd(packet))
        balance=lua.globals().gamedata[b"cache"][b"props"][20627][b"num"]
        self.assertTrue(lua.globals().NetArtifactCastCallBack(fd(packet))[b"localArtifactIgnored"])
        self.assertEqual(lua.globals().gamedata[b"cache"][b"props"][20627][b"num"],balance)
        lua.globals().UIArtifactCastCallBack(lua.table_from({b"isUse":0}))
        lua.globals().NetErrorMessageCallback9(fd(recharge.ids([5501,0])))
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localFormationBusy"])
        self.assertEqual(lua.globals().UIArtifactCastCallBack(lua.table_from({b"isUse":0}))[0],1)

    def test_debuffs_use_configured_duration_and_healing_ignores_seal_without_changing_other_heals(self):
        for name in ("侵蚀","腐蚀","扼制"):
            actor,config,sid=self.certain(name,1 if name!="扼制" else 3)
            actor.update(initial_ap=4,speed=300)
            report=battle.simulate({2:actor},{2:self.unit(iid=1,atk=200)},config,2,max_rounds=3)
            changes=[d for a in report["b"]["a"] for d in a["e"] if d.get("B",d.get("u",{})).get("w")]
            self.assertTrue(changes,name)
            if name=="扼制": self.assertEqual(changes[0]["u"],{"u":"skilllock","w":True})
            else:
                attr="atk" if name=="侵蚀" else "def"
                self.assertEqual(changes[0]["B"],{"R":attr,"u":"weaken","w":True})
                self.assertTrue(any(d.get("B")=={"R":attr,"u":"weaken","w":False} for a in report["b"]["a"] for d in a["e"]))
            self.assert_battle_report(report)
        for name,expected in (("滋养",80),("救赎",4000)):
            actor=self.unit(2,name,initial_ap=4,speed=100)
            enemy=self.unit(iid=1,atk=3000,speed=300,initial_ap=4,hp=100000,advance=1)
            config=copy.deepcopy(self.config)
            config["general"]["10201"]["break1"]=9000021
            report=battle.simulate({2:actor},{2:enemy},config,1,max_rounds=3)
            self.assertTrue(any(d.get("u")=={"u":"close","w":True} for a in report["b"]["a"] for d in a["e"]))
            sid=actor["artifact"]["skills"][0]
            heals=[d["m"]["m"] for a in report["b"]["a"] if a["s"].get("S")==sid for d in a["e"] if isinstance(d.get("m"),dict)]
            self.assertEqual(heals[0],-expected)
            if name=="滋养": self.assertEqual(heals[1:3],[-20,-20])
            self.assert_battle_report(report)

    def test_all_artifact_reports_convert_actual_apk_animation_assets_and_preserve_terminal_hp_ap(self):
        from lupa.lua51 import LuaRuntime
        lua=LuaRuntime()
        config=dict(self.config)
        with zipfile.ZipFile("configs_sec5.zip") as archive:
            for name in ("generalanimation","skillanimation"):
                config[name]=json.loads(archive.read("5/"+name+".json"))
        lua.globals().gamedata=lua.table_from({"config":config},recursive=True)
        lua.execute('''print=function() end;printT=print;battleScene={slotNum=7}
            table.getTableLength=function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
            CCFileUtils={sharedFileUtils=function(self) return self end,fullPathForFilename=function(self,p) return p end}
            ui={Split=function(s,sep) local t={} for v in string.gmatch(s,'[^'..sep..']+') do t[#t+1]=v end return t end}''')
        with zipfile.ZipFile(builder.SRC_APK) as archive:
            names,assets=archive.namelist(),{}
            for row in self.config["trump"].values():
                if not row["appraiseMethod"]: continue
                for model in (row["animation"],*([row["animation"]+"_1"] if row["show"]==1 else [])):
                    for suffix in (".json",".atlas"):
                        self.assertEqual(sum(n.endswith("/"+model+"/"+model+suffix) for n in names),1)
            lua.globals().CCFileUtils.isFileExist=lambda _,p:any(n.endswith("/"+p) for n in names)
            def asset(path):
                if path not in assets:
                    matches=[n for n in names if n.endswith("/"+path)]
                    self.assertEqual(len(matches),1,path)
                    assets[path]=json.loads(archive.read(matches[0]))
                return lua.table_from(assets[path],recursive=True)
            lua.globals().LoadJsonFileToTable=asset
            lua.execute(self.client_scripts()["assets/scripts/battleReportConvert.so"].decode())
            lua.execute(builder.read_script("BattleReportAbbToKey").decode())
            for kind,rows in self.config["trump_skillRnd"].items():
                for row in rows.values():
                    for level in range(1,7):
                        for direct in (True,False):
                            teams={direct:{2:self.unit(int(kind),row["name"],level,initial_ap=4,speed=300)},
                                   not direct:{2:self.unit(iid=1),8:self.unit(iid=8)}}
                            report=battle.simulate(teams[True],teams[False],self.config,7,max_rounds=3)
                            native=lua.table_from(json.loads(lua.globals().ReplaceAbbToKey(json.dumps(report))),recursive=True)
                            allies,enemies=lua.globals().getBattleInitSlotInfo(native)
                            animations,ext=lua.globals().convertBattleReportToAnimationSub(native,allies,enemies)
                            self.assertGreater(len(animations),1)
                            for side,key in (("attack","atk"),("defense","def")):
                                for pos,unit in report["endmeta"][side].items():
                                    self.assertEqual((ext.endinfo[key][pos].hp,ext.endinfo[key][pos].ap),(unit["h"],unit["ap"]))

    def ui_lua(self):
        lua=test_soul.SoulTests.ui_lua(self)
        lua.execute(self.client_scripts()["assets/scripts/UIArtifact.so"].decode())
        lua.execute('''
            for _,name in ipairs({"artifactCreate","artifactCheck","artifactList","slotsInfo","qiankunlu"}) do
                GameScene.layers[name]={show=true,module={rootNode=node(),localArtifactGeneration=1,
                    setArtifactData=function(self,t) self.received=t end,reloadData=function(self,t) self.received=t end,
                    castSuccess=function(self,t) self.received=t end,checkSuccess=function(self,t) self.received=t end}}
            end
            for _,name in ipairs({"onceCreateArtifact","onceCheckup","artifactInfo","artifactSelect","onceCheckedPanel","checkTimeList"}) do
                gameWindows.windows[name]={show=false,module={localArtifactGeneration=1}}
            end
            gameTimer={times={},funcs={},rigistTime=function(self,n,s) self.times[n]=s end,
                rigistTimeFunc=function(self,n,f) self.funcs[n]=f end,UnrigistTime=function() end,UnrigistTimeFunc=function() end}
            ui.makeTimeDayText=function(n) return tostring(n) end
            gameConfig.strings.string_format=function(_,a,b) return b[1] end
            setSpriteFrameByName=function() end
            callbacks={};animations={}
            local baseNode=node
            function node() local n=baseNode();n.runAction=function(self,a) callbacks[#callbacks+1]=a[2] end;return n end
            CCBReaderLoad=function() return node(),items() end
            CCDelayTime={create=function(_,n) return n end};CCCallFunc={create=function(_,f) return f end}
            CCSequence={createWithTwoActions=function(_,a,b) return {a,b} end}
            getAnimationManager=function() local n=node();animations[#animations+1]=n;return n end
            ccp=function(x,y) return {x=x,y=y} end
            setTriggerGiftEnable=function() end
            gameTouch.UnrigistFunc=function() end
        ''')
        return lua

    def test_actual_ui_old_page_target_property_and_batch_replies_do_not_touch_new_generations(self):
        lua=self.ui_lua()
        lua.execute('''local view=LocalArtifactContext()
            GameScene.layers.artifactCreate.module.localArtifactGeneration=2
            UIArtifactCast({artifactView=view,data={},rewardArtifact={}})
            assert(not GameScene.layers.artifactCreate.module.received)
            UIArtifactCast({artifactView=LocalArtifactContext(),data={},rewardArtifact={}})
            assert(GameScene.layers.artifactCreate.module.received)
            local old=LocalArtifactContext();GameScene.layers.artifactCheck.module.artifactSelect={iid=999}
            UIArtifactCheck({artifactView=old,data={}});assert(not GameScene.layers.artifactCheck.module.received)
            GameScene.layers.artifactCheck.module.artifactSelect=nil
            GameScene.layers.artifactCheck.module.localArtifactGeneration=2
            UIUserArtifactOnceCheckup({artifactView=old,data={},artifactRevision=3})
        ''')
        # Test the native material dispatcher separately: a closed batch window must not update a different page.
        code=self.client_scripts()["assets/scripts/UIProps.so"].decode()
        start=code.index("function UIPropQueryById(t)");end=code.index("\nfunction ",start+1)
        lua.execute(code[start:end])
        lua.execute('''local win=gameWindows.windows.onceCheckup
            win.show=true;win.module.rootNode=node();win.module.checkPropNums=function() error("old materials applied") end
            UIRequest({type=12001,order=33013,cids={20671,20672}})
            local view=requests[#requests].artifactView
            win.show=false;win.module.rootNode=nil;win.module.localArtifactGeneration=2
            UIPropQueryById({order=33013,nums={},artifactView=view,artifactRevision=3})
            local old=LocalArtifactContext();GameScene.layers.artifactCreate.module.localArtifactGeneration=3
            UIUserArtifactOnceMake({artifactView=old,data={},artifactList={}})
            assert(not opened)
        ''')

    def test_actual_single_forge_appraisal_and_batch_delayed_animations_reject_closed_or_replaced_roots(self):
        lua=self.ui_lua()
        lua.globals().create_module=lua.execute(self.client_scripts()["assets/scripts/Layer_artifactCreate.so"].decode())
        lua.globals().check_module=lua.execute(self.client_scripts()["assets/scripts/Layer_artifactCheck.so"].decode())
        lua.globals().batch_module=lua.execute(self.client_scripts()["assets/scripts/window_onceCheckedPanel.so"].decode())
        lua.execute('''
            create_module.rootNode=node();create_module.rootItems=items();create_module.skeleton=node()
            create_module.selectpage="cast";create_module.localArtifactGeneration=1
            create_module.castTable={{cid=20627},{cid=20628},{cid=20629},{cid=20630}}
            create_module.getArtifactDatas=function() end;create_module.setArtifactShow=function() end
            local reward={rewardArtifact={["1"]={iid=1,cid=110001}}}
            create_module:castSuccess(reward);local old=callbacks[#callbacks]
            create_module:castSuccess(reward);old();assert(#animations==0)
            callbacks[#callbacks]();local complete=animations[#animations].callback
            create_module.localArtifactGeneration=2;complete();assert(not opened)
            check_module.rootNode=node();check_module.rootItems=items();check_module.lianHuaEffect=node()
            check_module.localArtifactGeneration=1;check_module.artifactSelect={iid=1}
            check_module.setArtifactData=function() end;check_module.setArtifactShow=function() end
            check_module.setAttrAfterShow=function() end;check_module.checkGongming=function() end
            check_module:checkSuccess(reward);old=check_module.lianHuaEffect.callback
            local count=#animations;check_module.artifactSelect={iid=2};old();assert(#animations==count)
            check_module.artifactSelect={iid=1};check_module:checkSuccess(reward);check_module.lianHuaEffect.callback()
            complete=animations[#animations].callback
            check_module.localArtifactGeneration=2;complete()
            batch_module.root=node();batch_module.tenCCB=node();batch_module.tenItems=items()
            batch_module.localArtifactGeneration=1;batch_module.loadindex=0
            batch_module.tendata={["1"]={["1"]={iid=1,cid=110001}}}
            batch_module:loadOneOfTen();old=callbacks[#callbacks]
            batch_module:close();batch_module.root=node();batch_module.localArtifactGeneration=3
            old();assert(not opened)
        ''')

    def test_real_second_time_display_never_accelerates_or_mutates_after_reentry(self):
        lua=self.ui_lua()
        for speed in (1,3,10):
            lua.globals().speed=speed
            lua.execute('''local now=100;os.time=function() return now end
                local page=GameScene.layers.artifactCheck.module
                page.localArtifactGeneration=1;page.timeSp={[1]="zi"};page.rootItems=items()
                LocalArtifactTime(page,{time=1,sec=5,receivedAt=100},"artifactCheck")
                local old=gameTimer.funcs.artifactCheck
                for i=1,20*speed do old() end
                assert(page.timeData.sec==5)
                now=104;old();assert(page.timeData.sec==1)
                local count=#requests;now=105;old();old();assert(#requests==count+1 and requests[#requests].type==5509)
                page.localArtifactGeneration=2;now=200;old();assert(#requests==count+1)
            ''')

    def test_actual_batch_buttons_submit_counts_and_targets_and_reject_previous_window_clicks(self):
        lua=self.ui_lua()
        for name,key in (("window_onceCreateArtifact","onceCreateArtifact"),("window_onceCheckup","onceCheckup")):
            window=lua.execute(self.client_scripts()[f"assets/scripts/{name}.so"].decode())
            lua.globals().gameWindows.windows[key]=lua.table_from({"show":True,"module":window})
        lua.execute('''
            local window=gameWindows.windows.onceCreateArtifact.module
            local data={exchangeNum=5,count=3,props={}}
            window:open(-103,data,nil);window.usenum=2
            local click=window.rootItems.yesButton.callback;click()
            assert(requests[#requests].type==5515 and requests[#requests].count==2 and requests[#requests].curType==0)
            window:open(-103,data,nil);local n=#requests;click();assert(#requests==n)
            window.rootItems.autobutton2.callback();window.usenum=1;window.rootItems.yesButton.callback()
            assert(requests[#requests].curType==1)
            window=gameWindows.windows.onceCheckup.module
            window.createList=function(self) self.listview=node() end
            window:open(-103,{artifacts={},itemNum1=10,itemNum2=10},nil)
            window.selectList={{iid=6000001}};window.isSelectState1=false
            click=window.rootItems.yesButton.callback;click()
            assert(requests[#requests].type==5516 and requests[#requests].curList[1].iid==6000001 and requests[#requests].itemID==20671)
            window:open(-103,{artifacts={},itemNum1=10,itemNum2=10},nil)
            n=#requests;click();assert(#requests==n)
        ''')

    def test_native_full_roster_query_replaces_artifact_cache_without_resurrecting_stale_items(self):
        key=self.forge();self.identify(key);self.wear(key)
        lua=self.network_lua(native_protobuf=True)
        lua.execute(b'''gamedata.cache.artifacts[999999]={iid=999999,cid=110001}
            CheckArtifactAllHint=function() end
            for _,name in ipairs({"makeEquipsTemp","makeAllGeneralsTemp","makeOffGenerals","makeSlotInfo","makeCheerInfo","makeAllGenerals",
                "makeOffEquip","makeOffTreasure","makeOnEquipsForSlot","makeSlotGeminfo","makeMofulist"}) do _G[name]=function() return {} end end
            makeEquipsByTypeAll=function() return {treasures={},horse={},treasure={}} end
            makeSoulsByQualityAll=function() return {all={},souls2={},souls3={},souls4={},souls5={}} end''')
        code=self.client_scripts()["assets/scripts/GameSlots.so"].decode()
        start=code.index("function NetSlotsAllInfoCallBack(fd)\n");end=code.index("\nfunction ",start+1)
        lua.execute(b'local slots_pb=require("slots_pb")\n'+code[start:end].encode())
        lua.globals().NetSlotsAllInfoCallBack(lua.table_from({b"rbuf":self.success(1,1002)}))
        self.assertIsNone(lua.globals().gamedata[b"cache"][b"artifacts"][999999])
        self.assertEqual(lua.globals().gamedata[b"cache"][b"artifacts"][key][b"sid"],1)
