"""伙伴升星 1029：临时账号、真实配置、费用和失败回滚；不跑全量回归。"""

import copy
from collections import Counter
import json
import struct
import unittest
from unittest.mock import patch

import test_soul
import test_partner_growth
import build_local_apk as builder
from zyj_server import battle, development, formation, partner_growth, player, protocol, qiankun, recruit


def setUpModule():
    test_soul.setUpModule()


class PartnerStarTests(unittest.TestCase):
    request = test_soul.SoulTests.request
    add_account = test_soul.SoulTests.add_account
    success = test_soul.SoulTests.success
    reconnect = test_soul.SoulTests.reconnect
    refresh = test_soul.SoulTests.refresh
    grant = test_soul.SoulTests.grant
    props = test_soul.SoulTests.props
    gen = test_soul.SoulTests.gen
    assert_rejected = test_soul.SoulTests.assert_rejected
    client_scripts = classmethod(test_soul.SoulTests.client_scripts.__func__)
    network_lua = test_soul.SoulTests.network_lua
    client_call = test_soul.SoulTests.client_call
    put_hero = test_partner_growth.PartnerGrowthTests.put_hero
    paid = test_partner_growth.PartnerGrowthTests.paid

    def setUp(self):
        test_soul.SoulTests.setUp(self)
        self.iid = 2000900
        self.save["role_state"].update(level=150, coin=10**12, gold=1000000, g_gold=1000000)

    def star_hero(self, star=0, soar=10, awake=0, cid=164036):
        """直接构造合法的 14 阶彩金伙伴（含技能选择/阵营），再设置飞升、星级与仙属性。"""
        raw = self.put_hero(cid=cid, advance=13, awake=awake, level=300)
        raw = protocol.pb_set_varint(raw, 4, 14)
        row = self.config["general"][str(cid)]
        options = [i for i in (1, 2, 3) if row.get(f"gold1_will_skills_{i}")]
        choice = options[0]
        raw = protocol.pb_set_varint(raw, 35, choice)
        raw = protocol.pb_set_varint(raw, 40, self.config["jinjiangkezhiguanxi"][str(choice*100)]["camp"])
        raw = protocol.pb_set_varint(raw, 22, star)
        raw = protocol.pb_set_varint(raw, 23, soar)
        for field, value in partner_growth.fairy(raw, self.config).items():
            raw = protocol.pb_set_varint(raw, field, value)
        score = ((protocol.pb_get_varint(raw, 24) or 0)//10
                 + (protocol.pb_get_varint(raw, 25) or 0)
                 + (protocol.pb_get_varint(raw, 26) or 0))
        raw = protocol.pb_set_varint(raw, 34, score)
        player.record_slot_update(self.save, protocol.encode_pb_field(1, 2, raw))
        self.save["self_stats_version"] = 1
        return raw

    def values(self, raw):
        return [self.iid, protocol.pb_get_varint(raw, 1), protocol.pb_get_varint(raw, 22) or 0,
                protocol.pb_get_varint(raw, 23) or 0, protocol.pb_get_varint(raw, 4) or 0]

    def test_activation_charges_g_gold_and_sets_final_star_stats(self):
        raw = self.star_hero()
        before = copy.deepcopy(self.save)
        request = b"".join(protocol.encode_pb_field(1, 0, v) for v in self.values(raw))
        _, costs, _ = partner_growth.prepare(1029, copy.deepcopy(self.save), request, self.config, self.now, 7)
        self.assertEqual(costs, [(1025, 1000)])
        result = self.request(1, 1029, values=self.values(raw))
        self.refresh()
        hero = self.gen(self.iid)
        row = self.config["general_star"]["1"]
        self.assertEqual(protocol.pb_get_varint(hero, 22), 1)
        for name, field in (("g_hp", 24), ("g_def", 25), ("g_atk", 26)):
            self.assertEqual((protocol.pb_get_varint(hero, field) or 0)-(protocol.pb_get_varint(raw, field) or 0), row[name])
            self.assertEqual(protocol.pb_get_varint(hero, field), partner_growth.fairy(hero, self.config)[field])
        self.assertEqual(protocol.pb_get_varint(hero, 34),
                         (protocol.pb_get_varint(hero, 24) or 0)//10
                         + (protocol.pb_get_varint(hero, 25) or 0) + (protocol.pb_get_varint(hero, 26) or 0))
        self.assertEqual(self.save["role_state"]["g_gold"], before["role_state"]["g_gold"]-1000)
        self.assertEqual([mid for mid, _ in result][0], 1029)
        self.assertIn(1001, [mid for mid, _ in result])
        self.assertIn(5511, [mid for mid, _ in result])
        self.assert_rejected(1029, values=self.values(raw))
        self.reconnect(); self.refresh()
        self.assertEqual(protocol.pb_get_varint(self.gen(self.iid), 22), 1)
        self.assertEqual(self.save["role_state"]["g_gold"], before["role_state"]["g_gold"]-1000)

    def test_each_star_row_uses_final_stats_and_real_costs(self):
        raw = self.star_hero(soar=20)
        for star in range(6):
            with self.subTest(star=star):
                before = copy.deepcopy(self.save)
                current = self.gen(self.iid)
                row = self.config["general_star"][str(star+1)]
                _, costs, _ = partner_growth.prepare(1029, copy.deepcopy(self.save),
                                                     b"".join(protocol.encode_pb_field(1, 0, v) for v in self.values(current)),
                                                     self.config, self.now, 7)
                self.assertEqual(Counter(costs), Counter(tuple(map(int, e.split(","))) for e in row["consume"].split(";") if e))
                self.paid(1029, self.values(current))
                self.refresh()
                hero = self.gen(self.iid)
                self.assertEqual(protocol.pb_get_varint(hero, 22), star+1)
                for name, field in (("g_hp", 24), ("g_def", 25), ("g_atk", 26)):
                    self.assertEqual((protocol.pb_get_varint(hero, field) or 0)-(protocol.pb_get_varint(current, field) or 0),
                                     row[name]-(self.config["general_star"][str(star)][name] if star else 0))
                self.assertEqual(self.save["role_state"]["coin"], before["role_state"]["coin"]-dict(costs).get(1000, 0))
                self.assert_rejected(1029, values=self.values(current))

    def test_display_target_and_malformed_ids_are_rejected_without_spending(self):
        raw = self.star_hero()
        good = self.values(raw)
        for values in (good[:1], good[:4], good+[0], [self.iid, good[1]+1, 0, 10, 14],
                       [self.iid, good[1], 1, 10, 14], [self.iid, good[1], 0, 9, 14],
                       [self.iid, good[1], 0, 10, 13], [self.iid+1, good[1], 0, 10, 14],
                       [self.iid, 0, 0, 10, 14]):
            with self.subTest(values=values):
                self.assert_rejected(1029, values=values)
        self.assertEqual(protocol.pb_get_varint(self.gen(self.iid), 22), 0)

    def test_gates_reject_role_level_quality_breakthrough_soaring_and_max_star(self):
        raw = self.star_hero()
        working = copy.deepcopy(self.save)
        working["role_state"]["level"] = 99
        self.sessions[1].save = working
        self.assert_rejected(1029, values=self.values(raw))
        self.sessions[1].save = self.save

        self.assert_rejected(1029, values=[self.iid, 0, 0, 10, 14])  # 不存在的形态由显示目标拒绝
        plain = self.put_hero(cid=10609, advance=10, awake=0)
        self.assert_rejected(1029, values=self.values(plain))
        self.star_hero(soar=9)
        low = self.gen(self.iid)
        self.assert_rejected(1029, values=self.values(low))  # 第1星需要飞升10级
        self.star_hero(star=180, soar=60)
        full = self.gen(self.iid)
        self.assert_rejected(1029, values=self.values(full))
        self.config["general"]["164036"] = {**self.config["general"]["164036"], "rising_star": 0}
        blocked = self.star_hero()
        self.assert_rejected(1029, values=self.values(blocked))

    def test_insufficient_material_and_clock_rollback_are_atomic(self):
        raw = self.star_hero()
        self.save["role_state"]["g_gold"] = 0
        self.assert_rejected(1029, values=self.values(raw))
        self.save["role_state"]["g_gold"] = 1000000
        state = partner_growth.state(self.save, self.config)
        state["checked_at"] = self.now+86400
        self.save["partner_growth_state"] = state
        self.assert_rejected(1029, values=self.values(raw))
        self.assertEqual(protocol.pb_get_varint(self.gen(self.iid), 22), 0)
        self.assertEqual(self.save["role_state"]["g_gold"], 1000000)

    def test_starred_partner_keeps_validation_combat_preview_and_rebirth_protection(self):
        raw = self.star_hero()
        self.paid(1029, self.values(raw))
        self.refresh()
        hero = self.gen(self.iid)
        self.assertIsNotNone(partner_growth.validate(hero, self.config))
        partner_growth.check_combat(hero, self.config)
        preview, costs, update = development.prepare(1023, self.save, protocol.encode_pb_field(1, 0, self.iid), self.config)
        self.assertEqual((costs, update), ([], b""))
        self.assertEqual(protocol.pb_get_varint(formation.records(preview, 1, 2)[self.iid], 22), 1)
        self.assertFalse(qiankun.pristine_general(hero, self.config, self.save))
        # 觉醒仍可继续，且升星属性不被飞升/彩金重算覆盖。
        awake = [self.iid, 0]
        self.paid(1025, awake)
        self.refresh()
        grown = self.gen(self.iid)
        self.assertEqual(protocol.pb_get_varint(grown, 22), 1)
        self.assertEqual(protocol.pb_get_varint(grown, 24), partner_growth.fairy(grown, self.config)[24])
        # 战斗投影把升星后的仙属性按 fairy_turn_every 折算进普通面板。
        unit = {name: protocol.pb_get_varint(grown, f) or 0 for name, f in battle.GENERAL_FIELDS.items()}
        unit.update(skill=self.config["general"][str(protocol.pb_get_varint(grown, 1))]["skillid"],
                    skilllevel=0, partner_skills=partner_growth.skills(grown, self.config))
        teams = {True: {2: unit}, False: {2: dict(unit)}}
        battle._prepare_teams(teams, self.config)
        self.assertIn("passive_rows", teams[True][2])

    def test_up_star_rebirth_8301_remains_explicitly_closed(self):
        raw = self.star_hero()
        self.paid(1029, self.values(raw))
        self.assert_rejected(8301, values=[self.iid])
        self.refresh()
        self.assertEqual(protocol.pb_get_varint(self.gen(self.iid), 22), 1)

    def test_packaged_client_scripts_bind_display_generation_and_errors(self):
        scripts = self.client_scripts()

        def code(name):
            return scripts["assets/scripts/"+name+".so"].decode("utf-8")

        game, ui, layer, errors = (code(n) for n in ("GameGeneralUp", "UIGenerals", "Layer_generalup", "UIErrorMessage"))
        self.assertEqual(game.count("function UIGeneralUpStarCallBack"), 2)
        self.assertEqual(game.count("function NetGeneralUpStarCallBack"), 2)
        self.assertIn("localPartnerStarBusy", game)
        self.assertIn("ids({hero.iid,hero.cid,star,hero.level8 or 0,hero.level2 or 0})", game)
        self.assertIn("partnerStarIgnored", ui)
        self.assertIn("star=hero.level5 or 0", ui)
        self.assertIn("33019", ui)
        self.assertIn("partnerStarErrorView", errors)
        block = layer[layer.index("function generalup.upStarCallback"):]
        self.assertIn("generation~=self.localPartnerGeneration", block[:1200])
        self.assertNotIn("UIRequest({type = 1001})", ui[ui.index("function UIGeneralUpStar(t)"):ui.index("function UIGeneralUpStar(t)")+600])

        raw = self.star_hero()
        cid = protocol.pb_get_varint(raw, 1)
        lua = self.network_lua(native_protobuf=True)
        # 网络补丁只依赖真实 PB 与配置；这里桩掉原生缓存/钱包写入以便单独验证 1029 回调。
        lua.execute(b'assert(require("GameGeneralBreak"));assert(require("GameGeneralUp"));'
                    +b'gamedata.cache.generalslove={alldata={}};gamedata.cache.generals={};'
                    +b'gamedata.ext.starCostLog={};'
                    +b'gamedata.updateStaff=function(self,data) table.insert(gamedata.ext.starCostLog,{cid=data.cid,num=data.num}) end;'
                    +b'gamedata.isGeneralOn=function() return nil end;'
                    +b'gamedata.Generals=function(self,rows) for _,r in ipairs(rows) do local hero=self.cache.generals[r.iid];'
                    +b'if hero then hero.cid=r.cid;hero.level2=r.level2 or 0;hero.level5=r.level5 or 0;'
                    +b'hero.level8=r.fei_sheng_level or hero.level8 end end end;'
                    +b'gamedata.config.general={};gamedata.config.general_star={};'
                    +b'gamedata.cache.generals['+str(self.iid).encode()+b']={iid='+str(self.iid).encode()
                    +b',cid='+str(cid).encode()+b',level2=14,skilllevel=0,level8=10,level5=0};'
                    +b'gamedata.config.general[tostring('+str(cid).encode()+b')]={rising_star=1};'
                    +b'gamedata.config.general_star["1"]={consume="1025,1000;",limitlv=10};'
                    +b'gamedata.config.general_star["2"]={consume="20067,18;1000,263300;",limitlv=10};')
        view = lua.table_from({b"kind": b"layer", b"generation": 1, b"tab": b"upstar", b"iid": self.iid,
                               b"cid": cid, b"advance": 14, b"awake": 0, b"soar": 10, b"star": 0})
        mode, opcode, body = lua.globals().UIGeneralUpStarCallBack(lua.table_from({b"iid": self.iid, b"partnerView": view}))
        self.assertEqual((mode, opcode), (1, 1029))
        self.assertEqual(protocol.parse_ids_pb(body), self.values(raw))
        self.assertEqual(lua.globals().UIGeneralUpStarCallBack(lua.table_from({b"iid": self.iid, b"partnerView": view}))[0], 0)
        packet = self.success(1, 1029, raw=body)
        self.assertTrue(lua.globals().NetGeneralUpStarCallBack(lua.table_from({b"rbuf": packet, b"ser": 0}))[b"partnerStarIgnored"])
        result = lua.globals().NetGeneralUpStarCallBack(lua.table_from({b"rbuf": packet, b"ser": 7}))
        self.assertEqual(result[b"general"][b"level5"], 1)
        costs = lua.globals().gamedata[b"ext"][b"starCostLog"]
        self.assertEqual((len(costs), costs[1][b"cid"], costs[1][b"num"]), (1, 1025, -1000))
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localPartnerStarBusy"])
        self.refresh()
        self.assertEqual(protocol.pb_get_varint(self.gen(self.iid), 22), 1)


if __name__ == "__main__":
    unittest.main()
