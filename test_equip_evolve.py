"""装备进阶/升星：临时角色、原生配置、真实费用与66条成就依赖。"""

import copy
from fractions import Fraction
import json
from pathlib import Path
import struct
import unittest
import zipfile
from unittest.mock import patch

import build_local_apk as builder
import test_soul
from zyj_server import achievements, activities, battle, cheer, development, equip_baptize, equip_evolve, formation, guild, player, protocol, qiankun, recharge, recruit, single_boss, timebag, training


def setUpModule():
    test_soul.setUpModule()


class EquipEvolveTests(unittest.TestCase):
    request = test_soul.SoulTests.request
    success = test_soul.SoulTests.success
    reconnect = test_soul.SoulTests.reconnect
    add_account = test_soul.SoulTests.add_account
    records = test_soul.SoulTests.records
    groups = test_soul.SoulTests.groups
    assert_rejected = test_soul.SoulTests.assert_rejected
    props = test_soul.SoulTests.props
    refresh = test_soul.SoulTests.refresh
    gen = test_soul.SoulTests.gen
    client_scripts = classmethod(test_soul.SoulTests.client_scripts.__func__)
    client_call = test_soul.SoulTests.client_call

    def setUp(self):
        test_soul.SoulTests.setUp(self)
        self.save["role_state"].update(level=150,coin=2000000000)
        self.next_iid = 9900000
        for cid in (20274,20275,20276,20277,20282,20283,20222):
            self.give(cid,1000000)

    def give(self,cid,count):
        player.apply_reward(self.save,activities.build_reward(self.save,f"{cid},{count}",self.config),self.config,self.now)

    def add_equip(self,cid=21403,level=1,stage=0,stars=0,extra=b""):
        existing=formation.records(bytes.fromhex(self.save["world_state"]["1002"]),2,1)
        self.next_iid = max([self.next_iid,*existing])+1
        item=[self.next_iid,cid,level,stage,0,0,0,0,0,0,0,stars,0]
        player.record_slot_update(self.save,protocol.encode_pb_field(2,2,recharge.ids(item)+extra))
        return self.next_iid

    def equip(self,iid):
        return parse_item(formation.records(bytes.fromhex(self.save["world_state"]["1002"]),2,1)[iid])

    def wear(self,iid,sid=1):
        self.success(1,1005,raw=protocol.encode_pb_field(1,0,sid)+protocol.encode_pb_field(2,0,iid));self.refresh()

    def pay(self,opcode,iid):
        result=self.success(1,opcode,values=[iid]);self.refresh();return result

    def foods(self,cid,stage):
        row=self.config["equip_evolveconsume"][str(cid)]
        for material,count in equip_evolve.costs(row[f"equip{stage}"]).items():
            for _ in range(count):self.add_equip(material)

    def fill_team(self,stage=50,cid_quality=6):
        protagonist=protocol.pb_get_varint(bytes.fromhex(self.save["protagonist_snapshot"]),1)
        generals=formation.records(bytes.fromhex(self.save["world_state"]["1002"]),1,2)
        cids=[int(cid) for cid,r in self.config["general"].items() if r["battle"] and r["quality"]==3 and r.get("init_cid")==int(cid)][:6]
        iids=[protagonist]
        for index,cid in enumerate(cids,1):
            iid=2000900+index;iids.append(iid)
            player.record_slot_update(self.save,protocol.encode_pb_field(1,2,recruit.new_general(cid,iid,self.config)))
        self.assertEqual(len(set(iids)),7)
        slots={sid:guild_slot(sid,iid) for sid,iid in enumerate(iids,1)}
        for sid,slot in slots.items():
            for field,cid in zip(range(4,8),(21501,22501,23501,24501)):
                cid += 100 if cid_quality==7 else 0
                item=self.add_equip(cid,level=300,stage=stage,stars=20)
                slots[sid]=protocol.pb_set_varint(slots[sid],field,item)
        update=formation.apply_slots(self.save,slots,self.config)
        player.record_slot_update(self.save,update)
        for raw in formation.records(update,1,2).values():player.record_protagonist_general(self.save,raw)
        return slots

    def test_real_stage_costs_consumed_pristine_iids_response_order_and_reconnect(self):
        iid=self.add_equip(extra=protocol.encode_pb_field(99,2,b"preserve"))
        food=self.add_equip(21201)
        before=self.save["role_state"]["coin"]
        old={cid:self.props(cid) for cid in (20274,20275,20276)}
        result=self.pay(1122,iid)
        self.assertEqual(self.equip(iid)[3],1)
        self.assertEqual(self.save["role_state"]["coin"],before-41000)
        for cid,cost in ((20274,1),(20275,5),(20276,6)):self.assertEqual(self.props(cid),old[cid]-cost)
        self.assertEqual(protocol.parse_ids_pb(next(v for n,w,v in protocol.iter_pb_fields(result) if (n,w)==(9,2))),[food])
        self.assertNotIn(food,formation.records(bytes.fromhex(self.save["world_state"]["1002"]),2,1))
        raw=formation.records(bytes.fromhex(self.save["world_state"]["1002"]),2,1)[iid]
        self.assertIn((99,2,b"preserve"),list(protocol.iter_pb_fields(raw)))
        self.success(1,1101,raw=protocol.encode_pb_field(1,0,iid));self.refresh()
        raw=formation.records(bytes.fromhex(self.save["world_state"]["1002"]),2,1)[iid]
        self.assertIn((99,2,b"preserve"),list(protocol.iter_pb_fields(raw)))
        self.reconnect();self.refresh();self.assertEqual(self.equip(iid)[3],1)

    def test_stage_wear_strengthening_star_and_unmount_preserve_training_and_real_power(self):
        iid=self.add_equip()
        baseline=self.gen()
        original=protocol.pb_get_varint(formation.records(bytes.fromhex(self.save["world_state"]["1002"]),4,1)[1],4)
        self.wear(iid)
        plain=self.gen();self.foods(21403,1)
        self.pay(1122,iid)
        first=self.gen()
        self.assertEqual(protocol.pb_get_varint(first,6)-protocol.pb_get_varint(plain,6),int(self.config["equip_evolve"]["21403"]["init1"]))
        self.pay(1123,iid)
        starred=self.gen()
        self.assertEqual(protocol.pb_get_varint(starred,6)-protocol.pb_get_varint(first,6),52)
        self.success(1,1101,raw=protocol.encode_pb_field(1,0,iid));self.refresh()
        current=self.equip(iid)
        before=self.gen()
        self.pay(1123,iid)
        self.assertGreater(protocol.pb_get_varint(self.gen(),6),protocol.pb_get_varint(before,6))
        self.wear(original)
        self.assertEqual([protocol.pb_get_varint(self.gen(),f) for f in range(6,17)],
                         [protocol.pb_get_varint(baseline,f) for f in range(6,17)])
        self.assertGreater(current[2],1)

    def test_pristine_material_selection_never_consumes_worn_strengthened_washed_advanced_or_unknown_fields(self):
        iid=self.add_equip()
        for kwargs in ({"level":2},{"stage":1},{"stars":1},{"extra":protocol.encode_pb_field(90,0,1)}):self.add_equip(21201,**kwargs)
        worn=self.add_equip(21201);self.wear(worn)
        self.assert_rejected(1122,values=[iid])
        valid=self.add_equip(21201)
        self.pay(1122,iid)
        self.assertNotIn(valid,formation.records(bytes.fromhex(self.save["world_state"]["1002"]),2,1))
        self.assertIn(worn,formation.records(bytes.fromhex(self.save["world_state"]["1002"]),2,1))

    def test_orange_red_conversion_keeps_iid_wash_stars_and_requires_true_gates(self):
        iid=self.add_equip(level=149,stage=30,stars=5)
        self.foods(21501,1)
        self.assert_rejected(1122,values=[iid])
        current=self.equip(iid);current[2]=150;current[5:10]=[100,50,0,20,30];current[10]=5
        player.record_slot_update(self.save,protocol.encode_pb_field(2,2,recharge.ids(current)))
        self.save["role_state"]["level"]=74
        self.assert_rejected(1122,values=[iid])
        self.save["role_state"]["level"]=75
        self.pay(1122,iid)
        self.assertEqual(self.equip(iid),[iid,21501,150,1,0,100,50,0,20,30,5,5,0])
        self.assertIn(21403,equip_evolve.chain(21403,self.config))
        self.assertEqual(equip_evolve.score(self.equip(iid),self.config),31)

    def test_gold_conversion_and_every_global_gate_require_all_28_real_worn_pieces(self):
        slots=self.fill_team(stage=50)
        iid=protocol.pb_get_varint(slots[1],4)
        self.foods(21601,1)
        self.save["role_state"]["level"]=94;self.assert_rejected(1122,values=[iid])
        self.save["role_state"]["level"]=150
        slot=protocol.pb_set_varint(slots[7],7,0)
        player.record_slot_update(self.save,protocol.encode_pb_field(4,2,slot))
        self.assert_rejected(1122,values=[iid])
        player.record_slot_update(self.save,protocol.encode_pb_field(4,2,slots[7]))
        self.pay(1122,iid)
        self.assertEqual((self.equip(iid)[1],self.equip(iid)[3]),(21601,1))
        self.assertEqual(equip_evolve.score(self.equip(iid),self.config),81)
        for level in (11,21,31,41):
            item=self.equip(iid);item[3]=level-1;item[11]=35
            player.record_slot_update(self.save,protocol.encode_pb_field(2,2,recharge.ids(item)))
            self.foods(21601,level)
            if level>11:self.assert_rejected(1122,values=[iid])
            else:self.pay(1122,iid)

    def test_each_real_profile_level_and_star_row_has_exact_attributes_and_configured_caps(self):
        raw=self.gen()
        for cid,row in self.config["equip_evolve"].items():
            for level in range(row["level"]+1):
                item=[9900001,int(cid),1,level,0,0,0,0,0,0,0,0,0]
                body=protocol.encode_pb_field(4+equip_evolve.KINDS.index(self.config["equip"][cid]["type"]),0,item[0])
                values=equip_evolve.attributes(raw,body,{item[0]:recharge.ids(item)},self.config)
                expected=int(Fraction(str(row[f"init{level}"])))
                field=equip_evolve.FIELDS[row["attr"]]
                if not any(row[f"trigger_attr{i}"].startswith(row["attr"]+";") and level>=row[f"trigger{i}"] for i in range(1,14)):
                    self.assertEqual(values[field],expected)
        for cid,row in self.config["equip"].items():
            if row["type"] not in equip_evolve.KINDS:continue
            for stars in range(1,row["up_star"]+1):
                item=[9900001,int(cid),280,0,0,0,0,0,0,0,0,stars,0]
                equip_baptize.validate(item,self.config)
                base=int(Fraction(str(row["init1"]))+Fraction(str(row["grow_1"]))*279)
                slot=protocol.encode_pb_field(4+equip_evolve.KINDS.index(row["type"]),0,item[0])
                values=equip_evolve.attributes(raw,slot,{item[0]:recharge.ids(item)},self.config)
                zero=item[:];zero[11]=0
                plain=equip_evolve.attributes(raw,slot,{item[0]:recharge.ids(zero)},self.config)
                self.assertEqual(values[equip_evolve.FIELDS[row["attr1"]]]-plain[equip_evolve.FIELDS[row["attr1"]]],int(base*Fraction(str(self.config["equip_star"][str(stars)][f'add_{row["quality"]}']))))

    def test_strict_payloads_unlocks_caps_costs_preview_and_save_failure_are_atomic(self):
        iid=self.add_equip();self.foods(21403,1)
        for opcode in equip_evolve.OPCODES:
            for raw in (b"",b"\x08",b"\x08\x00",b"\x10\x01",guild.ids([iid,iid])):self.assert_rejected(opcode,raw=raw)
        self.save["role_state"]["level"]=49;self.assert_rejected(1122,values=[iid])
        self.save["role_state"]["level"]=54;self.assert_rejected(1123,values=[iid])
        self.save["role_state"]["level"]=150
        self.sessions[2].save["role_state"]["level"]=150
        self.assert_rejected(1122,account=2,values=[iid])
        self.success(1,1120,values=[iid,1,1]);self.refresh()
        self.assert_rejected(1122,values=[iid]);self.assert_rejected(1123,values=[iid])
        token=equip_baptize.get_state(self.save,self.config)["pending"][str(iid)]["token"]
        self.success(1,1121,values=[0,iid,token]);self.refresh()
        before,disk=copy.deepcopy(self.save),self.store.path(1).read_bytes()
        with patch.object(player,"save_role",return_value=False),self.assertRaises(OSError):self.request(1,1122,values=[iid])
        self.assertEqual((self.sessions[1].save,self.store.path(1).read_bytes()),(before,disk))

    def test_verified_rebirth_refunds_only_actual_costs_foods_stars_and_rejects_unknown_history(self):
        iid=self.add_equip();self.foods(21403,1)
        self.pay(1122,iid);self.pay(1123,iid)
        gold,coin=self.save["role_state"]["gold"],self.save["role_state"]["coin"]
        reply=self.pay(1117,iid)
        self.assertEqual(self.equip(iid),[iid,21403,1]+[0]*10)
        self.assertEqual(self.save["role_state"]["coin"],coin+41000+50000)
        self.assertEqual(self.save["role_state"]["gold"],gold-20-5)
        copies=[parse_item(raw) for n,w,raw in protocol.iter_pb_fields(reply) if (n,w)==(6,2) and parse_item(raw)[1]==21201]
        self.assertEqual(len(copies),1)
        self.assertEqual(copies[0][1:],[21201,1]+[0]*10)
        self.assertEqual(self.equip(copies[0][0]),copies[0])
        unknown=self.add_equip(stage=2)
        self.assert_rejected(1117,values=[unknown]);self.assert_rejected(1104,raw=protocol.encode_pb_field(1,2,protocol.encode_pb_field(1,0,unknown)+protocol.encode_pb_field(2,0,(1<<64)-1)))

    def test_all_66_achievement_predicates_read_actual_owned_stages_and_do_not_reset_after_consumption(self):
        iid=self.add_equip();self.foods(21403,1)
        self.pay(1122,iid)
        self.assertTrue(any(self.config["task"][str(t)]["type"]=="equip_evolve1" for t in self.save["achievement_state"]["completed"]))
        rows=[r for r in self.config["task"].values() if r["type"].startswith("equip_evolve")]
        self.assertEqual(len(rows),66)
        for row in rows:
            count=int(row["type"][len("equip_evolve"):]);level=int(row["target"])
            for actual in (level-1,level):
                self.assertEqual(achievements.progress(row,{"evolves":[actual]*count}),(actual,actual>=level))
        completed=set(self.save["achievement_state"]["completed"])
        self.pay(1117,iid)
        self.assertTrue(completed<=set(self.save["achievement_state"]["completed"]))

    def test_suit_uses_each_two_three_four_piece_minimum_tier_once_with_fractional_rates(self):
        raw=self.gen();items={};slot=b""
        for field,cid,level in zip(range(4,8),(21501,22404,23402,24403),(1,21,11,1)):
            iid=self.add_equip(cid,stage=level)
            items[iid]=recharge.ids(self.equip(iid));slot+=protocol.encode_pb_field(field,0,iid)
        all_values=equip_evolve.attributes(raw,slot,items,self.config)
        singles={f:Fraction(0) for f in range(6,17)}
        for field in range(4,8):
            for f,value in equip_evolve.attributes(raw,protocol.encode_pb_field(field,0,protocol.pb_get_varint(slot,field)),items,self.config).items():singles[f]+=value
        row=self.config["suit"]["29008"]
        expected={f:Fraction(0) for f in range(6,17)}
        for text in (row["2attr_3"],row["3attr_2"],row["4attr_1"]):
            for entry in text.split(";"):
                if not entry:continue
                name,value=entry.split(",");field=equip_evolve.FIELDS[name]
                expected[field]+=Fraction(value)*(100 if field>=10 else 1)
        self.assertEqual({f:all_values[f]-singles[f] for f in all_values},expected)
        self.assertEqual(expected[10],10)

    def test_old_local_snapshots_migrate_once_only_on_success_and_failed_save_preserves_disk(self):
        iid=self.add_equip(21501)
        self.wear(iid)
        expected=self.gen()
        world=bytes.fromhex(self.save["world_state"]["1002"])
        slot=formation.records(world,4,2)[protocol.pb_get_varint(expected,2)]
        equips=formation.records(world,2,1)
        members=cheer.members(self.save,self.config)
        old,_=formation.bonuses(expected,slot,members,equips,self.config,equip_growth=False)
        new,_=formation.bonuses(expected,slot,members,equips,self.config)
        legacy,delta=development.adjust(expected,{f:old[f]-new[f] for f in old})
        player.record_slot_update(self.save,protocol.encode_pb_field(1,2,legacy));player.record_protagonist_general(self.save,legacy)
        for key in ("power","power_all"):self.save["role_state"][key]+=delta
        self.save.pop("equip_evolve_version")
        player.save_role(self.save,self.store.path(1),self.sessions[1].step_counts)
        self.reconnect();self.refresh()
        self.assertNotIn("equip_evolve_version",self.save)
        before,disk=copy.deepcopy(self.save),self.store.path(1).read_bytes()
        with patch.object(player,"save_role",return_value=False),self.assertRaises(OSError):self.request(1,1002)
        self.assertEqual((self.sessions[1].save,self.store.path(1).read_bytes()),(before,disk))
        self.reconnect();self.refresh();self.success(1,1002);self.refresh()
        self.assertEqual(self.gen(),expected)
        self.assertEqual(self.save["equip_evolve_version"],1)
        self.success(1,1002);self.refresh();self.assertEqual(self.gen(),expected)

    def test_growth_and_dedicated_projection_recalculate_base_percentages_without_erasing_training(self):
        iid=self.add_equip(stage=21)
        self.wear(iid)
        before=self.gen();giid=protocol.pb_get_varint(before,2)
        world=bytes.fromhex(self.save["world_state"]["1002"]);slot=formation.records(world,4,2)[giid];equips=formation.records(world,2,1)
        values=equip_evolve.attributes(before,slot,equips,self.config)
        bare,_=development.adjust(before,{f:-int(value) for f,value in values.items()})
        config=copy.deepcopy(self.config)
        row=config["equip_evolve"]["21403"]
        for key in row:
            if key.startswith("trigger_attr"):row[key]=""
            elif key.startswith("init"):row[key]=0
        gain=int(self.config["props"]["20199"]["param1"])
        grown,_,_=training.grow_general(bare,gain,slot,cheer.members(self.save,self.config),equips,config,300)
        expected,_=development.adjust(grown,{f:int(value) for f,value in equip_evolve.attributes(grown,slot,equips,self.config).items()})
        self.give(20199,1)
        self.success(1,1038,raw=protocol.encode_pb_field(1,0,giid)+b"".join(protocol.encode_pb_field(2,0,v) for v in (0,0,0,1)));self.refresh()
        self.assertEqual(self.gen(),expected)
        self.success(1,3702,values=[140,1]);self.refresh()
        original=copy.deepcopy(self.save)
        temporary,_=single_boss.project_team(self.save,self.save["single_boss_state"]["teams"]["1"],self.config)
        self.assertEqual(formation.records(bytes.fromhex(temporary["world_state"]["1002"]),1,2)[giid],expected)
        self.assertEqual(self.save,original)

    def test_gold_keeps_red_relative_relations_and_publishes_authoritative_slot_status(self):
        self.fill_team()
        giid=protocol.pb_get_varint(bytes.fromhex(self.save["protagonist_snapshot"]),1)
        row=self.config["general"][str(protocol.pb_get_varint(self.gen(),1))]
        row.update(cond1type="equip",cond1ids="21504",cond1buf="atk:20")
        iid=self.add_equip(21504,level=300,stage=50,stars=10)
        self.wear(iid)
        self.foods(21604,1)
        packets=self.request(1,1122,values=[iid]);self.assertEqual(packets[0][0],1122);self.refresh()
        self.assertEqual(self.equip(iid)[1:4],[21604,300,1])
        self.assertIn(1027,[mid for mid,_ in packets])
        slot=formation.records(bytes.fromhex(self.save["world_state"]["1002"]),4,2)[giid]
        relation=next(v for n,w,v in protocol.iter_pb_fields(slot) if (n,w)==(3,2))
        self.assertEqual(protocol.pb_get_varint(relation,1),2)
        self.assertEqual([v for n,w,v in protocol.iter_pb_fields(relation) if (n,w)==(2,0)],[21504])
        self.assertIn(21504,equip_evolve.related(21604,self.config))

    def test_real_35_star_progress_keeps_int64_actual_coin_receipts_and_never_clamps_refund_overflow(self):
        self.fill_team()
        iid=self.add_equip(21505)
        self.wear(iid)
        giid=protocol.pb_get_varint(bytes.fromhex(self.save["protagonist_snapshot"]),1)
        while self.equip(iid)[2]<300:
            level=self.equip(iid)[2]
            self.save["role_state"]["coin"]=2000000000
            self.success(1,1109,values=[giid]);self.refresh()
            self.assertGreater(self.equip(iid)[2],level)
        self.assertEqual(self.equip(iid)[2],300)
        for _ in range(35):
            self.save["role_state"]["coin"]=2000000000
            self.pay(1123,iid)
        receipt=qiankun.get_state(self.save)["receipts"][f"equip:{iid}"]
        self.assertGreater(dict(receipt["costs"])[1000],(1<<31)-1)
        self.assertEqual(self.equip(iid)[11],35)
        self.assert_rejected(1123,values=[iid])
        replacement=self.add_equip(21501);self.wear(replacement)
        refund=dict(receipt["costs"])[1000]
        fee=equip_evolve.rebirth_fee(self.equip(iid),self.config)
        self.save["role_state"]["coin"]=(1<<63)-refund
        with self.assertRaisesRegex(ValueError,"容量"):
            qiankun.prepare(1117,copy.deepcopy(self.save),guild.ids([iid]),self.config)
        self.assert_rejected(1117,values=[iid])
        self.assertEqual(self.equip(iid)[11],35)
        self.save["role_state"]["coin"]-=1
        gold=self.save["role_state"]["gold"]
        reply=self.pay(1117,iid)
        self.assertEqual(protocol.pb_get_varint(reply,1),refund)
        self.assertEqual(self.save["role_state"]["coin"],(1<<63)-1)
        self.assertEqual(self.save["role_state"]["gold"],gold-fee)
        self.assertEqual(self.equip(iid),[iid,21505,1]+[0]*10)
        self.assertNotIn(f"equip:{iid}",qiankun.get_state(self.save)["receipts"])
        self.reconnect();self.refresh()
        self.assertEqual(self.save["role_state"]["coin"],(1<<63)-1)

    def test_progress_and_star_gifts_use_real_guides_simulated_payment_and_once_only_rewards(self):
        for gid,section,steps in ((130021,75,2),(130009,93,1)):
            self.assert_rejected(2882,values=[gid])
            for step in range(1,steps+1):self.success(1,201,raw=protocol.encode_pb_field(1,0,section)+protocol.encode_pb_field(2,0,step))
            self.refresh()
            self.assertEqual(protocol.parse_ids_pb(self.success(1,2882,values=[gid])),[gid,0,43200]);self.refresh()
            self.assert_rejected(2881,values=[gid])
            raw=b"".join(protocol.encode_pb_field(1,2,recharge.ids([v])) for v in (4,gid))
            order=self.records(self.success(1,115,raw=raw))[0];self.refresh()
            gold=self.save["role_state"]["gold"]
            self.success(1,116,values=[protocol.pb_get_varint(order,1)]);self.refresh()
            self.assertEqual(self.save["role_state"]["gold"],gold)
            self.reconnect();self.refresh()
            self.pay(2881,gid)
            self.assertTrue(timebag.get_state(self.save,gid)["claimed"])
            self.assert_rejected(2881,values=[gid])

    def network_lua(self):
        lua=test_soul.SoulTests.network_lua(self)
        lua.eval(b"require")(b"GameEquipStage")
        lua.globals().props_raw=bytes.fromhex(self.save["world_state"]["1200"])
        lua.execute(b'local t=require("idnums_pb").IdNums();t:ParseFromString(props_raw);gamedata:Props(t.idnums)')
        return lua

    def test_actual_network_pb_deducts_exact_cost_once_deletes_real_food_and_serializes_other_equipment_actions(self):
        iid=self.add_equip();food=self.add_equip(21201)
        lua=self.network_lua()
        fd=lambda raw:lua.table_from({b"rbuf":raw})
        req=lua.table_from({b"iid":iid,b"props":lua.table_from([]),b"growthView":lua.table_from({b"generation":7})})
        mode,opcode,raw=lua.globals().UIEquipStageUpCallBack(req)
        self.assertEqual((mode,opcode,protocol.parse_ids_pb(raw)),(1,1122,[iid]))
        self.assertEqual(lua.globals().UIEquipStarUpCallBack(req)[0],0)
        self.assertEqual(lua.globals().UISoulHuntCallBack(lua.table_from({b"param":1}))[0],0)
        self.assertEqual(lua.globals().UIEquipStrengthenCallBack(lua.table_from({b"iid":iid}))[0],0)
        self.assertEqual(lua.globals().UIChangeSlotCallBack(lua.table_from({b"pos1":1,b"pos2":2}))[0],0)
        coin=self.save["role_state"]["coin"]
        result=lua.globals().NetEquipStageUpCallBack(fd(self.success(1,1122,raw=raw)));self.refresh()
        self.assertEqual(result[b"growthIID"],iid)
        self.assertEqual(result[b"growthView"][b"generation"],7)
        self.assertEqual(lua.globals().gamedata[b"cache"][b"role"][b"coin"],coin-41000)
        self.assertEqual(self.save["role_state"]["coin"],coin-41000)
        self.assertIsNone(lua.globals().gamedata[b"cache"][b"equips"][food])
        self.assertEqual(lua.globals().gamedata[b"cache"][b"equips"][iid][b"level2"],1)
        self.assertEqual(lua.globals().gamedata[b"cache"][b"props"][20274][b"num"],999999)
        mode,opcode,raw=lua.globals().UIEquipStarUpCallBack(req)
        result=lua.globals().NetEquipStarUpCallBack(fd(self.success(1,1123,raw=raw)));self.refresh()
        self.assertEqual(lua.globals().gamedata[b"cache"][b"equips"][iid][b"level3"],1)
        self.assertEqual(lua.globals().gamedata[b"cache"][b"role"][b"coin"],self.save["role_state"]["coin"])
        lua.globals().UIEquipStageUpCallBack(req)
        lua.globals().NetErrorMessageCallback9(fd(guild.ids([1123,0])))
        self.assertIsNotNone(lua.globals().gamedata[b"ext"][b"localEquipGrowthBusy"])
        lua.globals().NetErrorMessageCallback9(fd(guild.ids([1122,0])))
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localEquipGrowthBusy"])
        self.assertEqual(lua.globals().UIEquipStageUpCallBack(req)[0],1)
        self.assertIsNone(lua.globals().gameConfig)

    def ui_lua(self):
        lua=test_soul.SoulTests.ui_lua(self)
        code=self.client_scripts()["assets/scripts/gamedata.so"].decode()
        start=code.index("function gamedata.getIDandNUMs(")
        lua.execute(code[start:code.index("\nfunction ",start+1)])
        lua.execute('''package.preload.UIEquipStarUp=function() end
            page={localEquipGrowthGeneration=1,rootNode=node(),selectpage="jinjie",data={iid=9900001,cid=21403,level2=0},
                reloaddata=function(self,data) self.received=(self.received or 0)+1;self.data=data end}
            legacy={localEquipGrowthGeneration=1,rootNode=node(),chooseData={{iid=9900001,cid=21403,level2=0}},
                reloadStatus=function(self,data) self.received=(self.received or 0)+1 end}
            GameScene.layers.equipsup={show=true,module=page}
            GameScene.layers.equipstage={show=false,module=legacy}''')
        lua.execute(self.client_scripts()["assets/scripts/UIEquipStage.so"].decode())
        return lua

    def test_actual_ui_binds_page_target_generation_and_never_replays_old_role_or_power_queries(self):
        lua=self.ui_lua()
        old=lua.globals().LocalEquipGrowthContext()
        payload=lua.table_from({"type":1122,"growthView":old,"growthIID":9900001,
                                "equipdata":{"iid":9900001,"cid":21501,"level2":1,"type":"weapon"}},recursive=True)
        lua.globals().page.data.iid=9900002
        lua.globals().UIEquipStageUp(payload)
        self.assertIsNone(lua.globals().page.received)
        lua.globals().page.data.iid=9900001;lua.globals().page.localEquipGrowthGeneration=2
        lua.globals().UIEquipStageUp(payload)
        self.assertIsNone(lua.globals().page.received)
        payload.growthView=lua.globals().LocalEquipGrowthContext()
        lua.globals().UIEquipStageUp(payload)
        self.assertEqual(lua.globals().page.received,1)
        self.assertEqual(lua.globals().page.data.cid,21501)
        self.assertFalse(any(r.type in (1001,10322) for r in lua.globals().requests.values()))
        lua.globals().GameScene.layers.equipsup.show=False
        lua.globals().UIEquipStarUp(payload)
        self.assertEqual(lua.globals().page.received,1)
        self.assertEqual(lua.globals().LocalEquipGrowthNext(lua.table_from({"cid":21403,"level2":30})),(21501,1))
        self.assertEqual(lua.globals().LocalEquipGrowthNext(lua.table_from({"cid":21501,"level2":50})),(21601,1))
        self.assertIsNone(lua.globals().LocalEquipGrowthNext(lua.table_from({"cid":21601,"level2":50})))

    def test_packaged_scripts_compile_and_both_native_progress_pages_keep_exact_target_gates(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("实际APK编译验证需要lupa.lua51")
        lua=LuaRuntime(unpack_returned_tuples=True)
        compile_lua=lua.eval("function(s,n) local f,e=loadstring(s,n);return f,e end")
        for name,raw in self.client_scripts().items():
            fn,error=compile_lua(raw,name);self.assertIsNotNone(fn,(name,error))
        for name in ("Layer_equip_up","Layer_equipstage"):
            code=self.client_scripts()[f"assets/scripts/{name}.so"].decode()
            self.assertIn("localEquipGrowthGeneration",code)
            self.assertIn("LocalEquipGrowthNext",code)
        self.assertIn("localEquipGrowthBusy",self.client_scripts()["assets/common_lua/GameErrorMessage.so"].decode())

    def test_28_real_items_progress_to_gold_ming_tier_and_all_66_rewards_are_actually_claimable(self):
        slots=self.fill_team()
        iids=[protocol.pb_get_varint(slot,n) for slot in slots.values() for n in range(4,8)]
        self.assertEqual(len(set(iids)),28)
        for level in range(1,22):
            for iid in iids:
                item=self.equip(iid)
                cid=self.config["equip_evolve"][str(item[1])]["evolve"] if level==1 else item[1]
                self.foods(cid,level)
                self.save["role_state"]["coin"]=2000000000
                for material,amount in equip_evolve.costs(self.config["equip_evolveconsume"][str(cid)][f"consume{level}"]).items():
                    if material!=1000 and self.props(material)<amount:self.give(material,1000000)
                self.pay(1122,iid)
        self.assertTrue(all(equip_evolve.score(self.equip(iid),self.config)==101 for iid in iids))
        rows=sorted((r for r in self.config["task"].values() if r["type"].startswith("equip_evolve")),key=lambda r:r["id"])
        self.assertEqual(len(rows),66)
        for row in rows:
            self.assertIn(row["id"],self.save["achievement_state"]["completed"])
            self.pay(2401,row["id"])
        self.reconnect();self.refresh()
        self.assertTrue({r["id"] for r in rows}<=set(self.save["achievement_state"]["claimed"]))
        self.assert_rejected(2401,values=[rows[0]["id"]])

    def test_item_left_in_an_empty_slot_can_progress_without_fake_power_increases(self):
        iid=self.add_equip();self.wear(iid,sid=2)
        self.success(1,1003,raw=protocol.encode_pb_field(1,0,2)+protocol.encode_pb_field(3,0,0));self.refresh()
        self.foods(21403,1)
        power=self.save["role_state"]["power"]
        packets=self.request(1,1122,values=[iid]);self.refresh()
        self.assertEqual(packets[0][0],1122)
        self.assertEqual(self.equip(iid)[3],1)
        self.assertEqual(self.save["role_state"]["power"],power)
        self.assertNotIn(205,[mid for mid,_ in packets])

    def test_same_sequence_cache_version_corruption_and_insufficient_materials_never_charge_twice(self):
        iid=self.add_equip();self.foods(21403,1)
        packets=self.request(1,1122,values=[iid]);self.refresh()
        before,disk=copy.deepcopy(self.save),self.store.path(1).read_bytes()
        retried=self.sessions[1].handle(1122,self.seq,guild.ids([iid]))
        self.assertEqual([(struct.unpack(">IIII",p[:16])[2],p[16:]) for p in retried],packets)
        self.assertEqual((self.sessions[1].save,self.store.path(1).read_bytes()),(before,disk))
        for invalid in (False,-1,2,"1"):
            self.save["equip_evolve_version"]=invalid
            self.assert_rejected(1122,values=[iid])
        self.save["equip_evolve_version"]=1
        self.save["role_state"]["coin"]=0
        self.assert_rejected(1122,values=[iid])
        self.save["role_state"]["coin"]=2000000000
        old=self.config["equip_evolveconsume"]["21403"]["consume2"]
        self.config["equip_evolveconsume"]["21403"]["consume2"]="1000,-1;"
        self.assert_rejected(1122,values=[iid])
        self.config["equip_evolveconsume"]["21403"]["consume2"]=old

    def test_actual_legacy_button_checks_next_quality_level_and_does_not_send_before_75(self):
        lua=self.ui_lua()
        module=lua.execute(self.client_scripts()["assets/scripts/Layer_equipstage.so"].decode())
        module.rootNode=lua.globals().node();module.rootItems=lua.globals()["items"]()
        module.localEquipGrowthGeneration=1
        module.chooseData=lua.table_from([{ "iid":9900001,"cid":21403,"level1":150,"level2":30,"level3":5,"quality":5}],recursive=True)
        module.spendPropsData=lua.table_from({str(cid):1000000 for cid in (1000,20274,20275,20276,21403)})
        lua.globals().legacy=module
        lua.globals().GameScene.layers.equipstage.module=module
        lua.globals().GameScene.layers.equipstage.show=True
        lua.globals().GameScene.layers.equipsup.show=False
        code=self.client_scripts()["assets/scripts/Layer_equipstage.so"].decode()
        start=code.index("    self.rootItems.stageUpBtn:addHandleOfControlEvent(function()")
        end=code.index("    self.rootItems.stageUpBtn:setTouchPriority(-101)",start)
        lua.execute("function bind_progress_button(self)\n"+code[start:end]+"\nend")
        lua.globals().bind_progress_button(module)
        lua.globals().GameScene.roleinfo.level=74
        module.rootItems.stageUpBtn.callback()
        self.assertEqual(len(lua.globals().requests),0)
        self.assertIn("75",lua.globals().prompt)
        lua.globals().GameScene.roleinfo.level=75
        module.rootItems.stageUpBtn.callback()
        req=lua.globals().requests[1]
        self.assertEqual((req.type,req.iid),(1122,9900001))
        self.assertEqual(req.growthView.equipstage.generation,1)

    def test_fractional_equipment_rate_reaches_pure_battle_without_becoming_an_integer_stat(self):
        self.config["equip_evolve"]["21403"]["trigger_attr1"]="critical;0.1"
        iid=self.add_equip(stage=1);self.wear(iid)
        attack,defense=battle.rosters(self.save,self.config["copy"]["42101"]["1"],self.config)
        self.assertEqual(attack[2]["pet_rates"]["critical"],Fraction(1,10))
        self.assertEqual(protocol.pb_get_varint(self.gen(),10),0)
        original=copy.deepcopy((attack,defense))
        report=battle.simulate(attack,defense,self.config,17)
        json.dumps(report)
        self.assertEqual((attack,defense),original)

    def test_all_64_max_stage_reports_convert_actual_animation_assets_with_matching_terminal_hp(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("实际APK动画验证需要lupa.lua51")
        lua=LuaRuntime();config=dict(self.config)
        with zipfile.ZipFile(Path(__file__).parent/"configs_sec5.zip") as archive:
            for name in ("generalanimation","skillanimation"):
                config[name]=json.loads(archive.read("5/"+name+".json"))
        lua.globals().gamedata=lua.table_from({"config":config},recursive=True)
        lua.execute('''print=function() end;printT=print;battleScene={slotNum=7}
            table.getTableLength=function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
            CCFileUtils={sharedFileUtils=function(self) return self end,fullPathForFilename=function(self,p) return p end}
            ui={Split=function(s,sep) local t={} for v in string.gmatch(s,'[^'..sep..']+') do t[#t+1]=v end return t end}''')
        with zipfile.ZipFile(builder.SRC_APK) as archive:
            names,assets=archive.namelist(),{}
            lua.globals().CCFileUtils.isFileExist=lambda _,path:any(n.endswith("/"+path) for n in names)
            def asset(path):
                if path not in assets:
                    matches=[n for n in names if n.endswith("/"+path)];self.assertEqual(len(matches),1,path)
                    assets[path]=json.loads(archive.read(matches[0]))
                return lua.table_from(assets[path],recursive=True)
            lua.globals().LoadJsonFileToTable=asset
            lua.execute(self.client_scripts()["assets/scripts/battleReportConvert.so"].decode())
            lua.execute(builder.read_script("BattleReportAbbToKey").decode())
            for cid,row in self.config["equip_evolve"].items():
                iid=self.add_equip(int(cid),level=300,stage=row["level"],stars=self.config["equip"][cid]["up_star"])
                self.wear(iid)
                attack,defense=battle.rosters(self.save,self.config["copy"]["42101"]["1"],self.config)
                report=battle.simulate(attack,defense,self.config,7)
                native=lua.table_from(json.loads(lua.globals().ReplaceAbbToKey(json.dumps(report))),recursive=True)
                allies,enemies=lua.globals().getBattleInitSlotInfo(native)
                animations,ext=lua.globals().convertBattleReportToAnimationSub(native,allies,enemies)
                self.assertGreater(len(animations),1)
                for side,key in (("attack","atk"),("defense","def")):
                    for pos,unit in report["endmeta"][side].items():
                        self.assertEqual((ext.endinfo[key][pos].hp,ext.endinfo[key][pos].ap),(unit["h"],unit["ap"]))

    def test_rebirth_fee_matches_actual_native_page_for_all_64_families_and_completed_quality_stages(self):
        lua=self.ui_lua()
        code=builder.read_script("Layer_qiankunlu").decode().replace("\r\n","\n")
        start=code.index('            local renascenceconfig = gamedata.config.renascence',code.index('elseif tempdata.type and (tempdata.type == "head"'))
        end=code.index('        elseif temconfig.staffType == "general" then',start)
        lua.execute("function native_fee(self,temconfig)\n"+code[start:end]+"\nreturn self.allspendgold end")
        for cid,profile in self.config["equip_evolve"].items():
            row=self.config["equip"][cid]
            for level in (0,1,profile["level"]):
                data=[9900001,int(cid),280,level,0,0,0,0,0,0,1,row["up_star"],0]
                window=lua.table_from({"chooseData":[{"level1":280,"level2":level,"level3":row["up_star"],"level4":0,"xcount":1}]},recursive=True)
                expected=lua.globals().native_fee(window,lua.table_from(row))
                self.assertEqual(equip_evolve.rebirth_fee(data,self.config),expected,(cid,level))

    def test_actual_orange_to_red_paid_chain_rebirth_returns_original_cid_and_all_recorded_costs(self):
        self.save["role_state"]["level"]=75
        original=protocol.pb_get_varint(formation.records(bytes.fromhex(self.save["world_state"]["1002"]),4,1)[1],4)
        iid=self.add_equip();self.wear(iid)
        giid=protocol.pb_get_varint(bytes.fromhex(self.save["protagonist_snapshot"]),1)
        self.success(1,1109,values=[giid]);self.refresh()
        self.assertEqual(self.equip(iid)[2],150)
        for _ in range(5):self.pay(1123,iid)
        for level in range(1,31):
            self.foods(21403,level);self.pay(1122,iid)
        self.foods(21501,1);self.pay(1122,iid)
        self.assertEqual(self.equip(iid)[1:4],[21501,150,1])
        receipt=copy.deepcopy(qiankun.get_state(self.save)["receipts"][f"equip:{iid}"])
        fee=equip_evolve.rebirth_fee(self.equip(iid),self.config)
        self.assertEqual(fee,self.config["renascence"]["150"]["strengthencost"]+self.config["renascence"]["1"]["equipevolvecost"]
                         +self.config["renascence"]["30"]["equipevolvecost"]+self.config["renascence"]["5"]["star_cost"])
        self.wear(original);self.save["role_state"]["coin"]=0
        gold=self.save["role_state"]["gold"]
        self.pay(1117,iid)
        self.assertEqual(self.equip(iid),[iid,21403,1]+[0]*10)
        self.assertEqual(self.save["role_state"]["coin"],dict(receipt["costs"])[1000])
        self.assertEqual(self.save["role_state"]["gold"],gold-fee)


def parse_item(raw):
    values=protocol.parse_ids_pb(raw)
    return values+[0]*(13-len(values))


def guild_slot(sid,iid):
    return protocol.encode_pb_field(1,0,sid)+protocol.encode_pb_field(2,0,iid)


if __name__=="__main__":
    unittest.main()
