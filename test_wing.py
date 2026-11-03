"""主角翅膀：临时账号、真实配置、失败保星及原包回调。"""

import copy
import struct
import unittest
import zipfile
from unittest.mock import patch

import test_soul
import test_treasure_star
from zyj_server import battle, development, fashion, formation, player, protocol, ranking, recharge, training, wing


def setUpModule():
    test_soul.setUpModule()


class WingTests(unittest.TestCase):
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
    give = test_treasure_star.TreasureStarTests.give
    network_lua = test_soul.SoulTests.network_lua

    def setUp(self):
        test_soul.SoulTests.setUp(self)
        self.save["role_state"].update(level=150, coin=1000000000000)
        for cid in (20334, 20335, 20336, 20330, 20861, 20867):
            self.give(cid, 1000000)

    def test_activation_is_paid_once_adds_real_stats_and_preserves_reconnect(self):
        self.save["role_state"]["level"] = 34
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 3740))[:4], [0, 0, 0, 0])
        self.refresh()
        self.assert_rejected(3742, values=[0])
        self.save["role_state"]["level"] = 35
        raw, gold = self.gen(), self.save["role_state"]["gold"]
        self.success(1, 3742, values=[0]); self.refresh()
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 3740))[:4], [1, 0, 0, 0])
        self.assertEqual(self.save["role_state"]["gold"], gold - 1000)
        for field, amount in ((6, 6000), (7, 800), (8, 20000)):
            self.assertEqual(protocol.pb_get_varint(self.gen(), field) - protocol.pb_get_varint(raw, field), amount)
        self.assertEqual(protocol.pb_get_varint(bytes.fromhex(self.save["protagonist_snapshot"]), 8), 1)
        self.assert_rejected(3742, values=[0])
        self.reconnect(); self.refresh()
        self.assertEqual(self.save["wing_state"]["stage"], 1)

    def seed_wing(self, stage=1, stars=0, failures=0):
        raw = self.gen()
        old = wing.attributes(raw, self.save.get("wing_state"), self.config)
        state = {"stage": stage, "stars": stars, "exp": 0, "color": 0, "failures": failures, "colors": [], "checked_at": self.now}
        self.save["wing_state"] = state
        new = wing.attributes(raw, state, self.config)
        changed, delta = development.adjust(raw, {f: new[f] - old[f] for f in new})
        player.apply_sigil_update(self.save, protocol.encode_pb_field(1, 2, changed), delta, self.config)
        self.save["protagonist_snapshot"] = protocol.pb_set_varint(bytes.fromhex(self.save["protagonist_snapshot"]), 8, stage).hex()

    def test_real_weighted_feathers_stop_at_one_star_and_persist_actual_cost(self):
        self.success(1, 3742, values=[0]); self.refresh()
        before = self.props(20334)
        values = protocol.parse_ids_pb(self.success(1, 3741)); self.refresh()
        self.assertEqual(values[1], 1)
        self.assertTrue(1 <= len(values[5:]) <= 100)
        self.assertEqual(self.props(20334), before - len(values[5:]))
        self.assertEqual(values[2], sum(values[5:]) - self.config["wing_uplv"]["1"]["1"]["lv_exp"])
        self.reconnect(); self.refresh()
        self.assertEqual(self.save["wing_state"]["stars"], 1)
        self.seed_wing(13)
        material = self.config["wing_uplv"]["13"]["1"]["cost"]
        before = self.props(material)
        values = protocol.parse_ids_pb(self.success(1, 3741)); self.refresh()
        self.assertEqual((values[1], len(values[5:])), (0, 100))
        self.assertEqual(self.props(material), before - 100)

    def test_stage_failure_loses_one_star_insurance_protects_it_and_pity_is_real(self):
        for insurance, stars in ((0, 9), (1, 10)):
            self.seed_wing(5, 10)
            seed = 0  # 第一掷49，大于本阶20%的成功率。
            before = self.props(20336)
            with patch.object(player.random, "getrandbits", return_value=seed):
                reply = self.groups(self.success(1, 3742, values=[insurance]))
            self.refresh()
            self.assertEqual(protocol.parse_ids_pb(reply[0])[-1], 0)
            self.assertEqual((self.save["wing_state"]["stage"], self.save["wing_state"]["stars"]), (5, stars))
            self.assertEqual(wing.chance(self.save["wing_state"], self.config), 30)
            self.assertEqual(self.props(20336), before - (3 if insurance else 0))
        self.seed_wing(5, 10, 8)
        self.success(1, 3742, values=[0]); self.refresh()
        self.assertEqual((self.save["wing_state"]["stage"], self.save["wing_state"]["stars"]), (6, 0))

    def test_all_stage_star_attributes_are_finite_and_caps_and_gates_are_enforced(self):
        for stage in range(1, 14):
            for stars in range(11):
                self.seed_wing(stage, stars)
                values = wing.attributes(self.gen(), self.save["wing_state"], self.config)
                self.assertTrue(all(0 <= value < (1 << 31) for value in values.values()))
                wing.get_state(self.save, self.config)
        self.assert_rejected(3741)
        self.assert_rejected(3742, values=[0])
        self.seed_wing(1, 0)
        self.assert_rejected(3742, values=[0])
        self.seed_wing(5, 10)
        self.save["role_state"]["level"] = 69
        self.assert_rejected(3742, values=[0])

    def test_color_unlock_is_paid_once_per_color_then_switches_free(self):
        self.seed_wing(8)
        palette = protocol.parse_ids_pb(self.success(1, 3744)); self.refresh()
        self.assertEqual(palette[:3], [1, 1, 0])
        before, raw = self.props(20330), self.gen()
        self.success(1, 3743, values=[1]); self.refresh()
        self.assertEqual(self.props(20330), before - 30)
        for color in (0, 1, 1):
            self.success(1, 3743, values=[color]); self.refresh()
        self.assertEqual(self.props(20330), before - 30)
        self.assertEqual(self.gen(), raw)
        self.assertEqual(protocol.pb_get_varint(bytes.fromhex(self.save["protagonist_snapshot"]), 9), 1)
        self.assert_rejected(3743, values=[3])
        self.reconnect(); self.refresh()
        self.assertEqual(self.save["wing_state"]["colors"], [1])

    def test_bad_requests_funds_overflow_clock_rollback_and_save_failure_are_atomic(self):
        for opcode, raw in ((3740, b"\x08\x01"), (3741, b"\x08\x01"), (3742, b""), (3742, recharge.ids([2])),
                            (3743, recharge.ids([1])), (3744, b"\x08\x01")):
            self.assert_rejected(opcode, raw=raw)
        before = copy.deepcopy(self.save)
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 3742, values=[0])
        self.assertEqual(self.sessions[1].save, before)
        self.save["role_state"]["gold"] = 999
        self.assert_rejected(3742, values=[0])
        self.save["role_state"]["gold"] = 1000000
        self.success(1, 3742, values=[0]); self.refresh()
        self.clock.return_value -= 1
        self.assert_rejected(3741)
        self.clock.return_value = self.now
        self.save["role_state"]["power"] = (1 << 31) - 1
        self.assert_rejected(3741)

    def test_aptitude_survives_pills_templates_fashion_and_dedicated_team(self):
        self.seed_wing(2)
        self.give(20199, 1)
        before = self.gen()
        world = bytes.fromhex(self.save["world_state"]["1002"])
        iid = protocol.pb_get_varint(before, 2)
        slots, equips = formation.records(world, 4, 2), formation.records(world, 2, 1)
        grown, _, _ = training.grow_general(before, 20000, slots[iid], set(), equips, self.config, 300)
        self.success(1, 1038, raw=protocol.encode_pb_field(1, 0, iid) + b"\x10\x00" * 3 + b"\x10\x01"); self.refresh()
        current = self.gen()
        old, new = wing.attributes(before, self.save["wing_state"], self.config), wing.attributes(current, self.save["wing_state"], self.config)
        for field in (6, 7, 8):
            self.assertEqual(protocol.pb_get_varint(current, field), protocol.pb_get_varint(grown, field) + new[field] - old[field])
        self.success(1, 1074, values=[80001]); self.refresh()
        baseline = self.gen()
        self.success(1, 1073, values=[80001]); self.refresh()
        self.success(1, 1071); self.refresh()
        self.assertEqual(self.gen(), baseline)
        from zyj_server import single_boss
        snapshot = copy.deepcopy(self.save)
        temporary, _ = single_boss.project_team(self.save, [iid, 0, 0, 0, 0, 0, 0, 0], self.config)
        self.assertEqual(formation.records(bytes.fromhex(temporary["world_state"]["1002"]), 1, 2)[iid], self.gen())
        self.assertEqual(self.save, snapshot)

    def test_rank_progress_and_gift_follow_actual_owned_wing_and_real_guide(self):
        self.success(1, 3742, values=[0]); self.refresh()
        self.assertEqual(ranking.entry(1, self.save, self.config)["scores"]["5"], 100)
        self.assert_rejected(2882, values=[130006])
        for step in range(1, self.sessions[1].step_counts[86] + 1):
            self.success(1, 201, raw=protocol.encode_pb_field(1, 0, 86) + protocol.encode_pb_field(2, 0, step))
        self.refresh()
        self.success(1, 2882, values=[130006]); self.refresh()
        self.assertTrue(self.save["wing_gift_state"]["triggered_at"])
        self.assert_rejected(2881, values=[130006])
        raw = b"".join(protocol.encode_pb_field(1, 2, recharge.ids([v])) for v in (3, 130006))
        order = self.records(self.success(1, 115, raw=raw))[0]
        gold = self.sessions[1].save["role_state"]["gold"]
        self.success(1, 116, values=[protocol.pb_get_varint(order, 1)])
        self.reconnect(); self.refresh()
        self.assertEqual(self.save["role_state"]["gold"], gold)
        before = self.props(20334)
        self.success(1, 2881, values=[130006]); self.refresh()
        self.assertEqual(self.props(20334), before + 100)
        self.assert_rejected(2881, values=[130006])

    def test_actual_network_pb_prices_fifo_context_and_matching_errors(self):
        import build_local_apk as builder
        lua = self.network_lua()
        native = builder.read_script("gamedata").decode()
        start = native.index("function gamedata.WingData(")
        end = native.index("function gamedata.ServiceWarGroupInfoData(", start)
        lua.execute(native[start:end].encode())
        lua.eval(b"require")(b"GameWing")
        lua.globals().wing_props = bytes.fromhex(self.save["world_state"]["1200"])
        lua.execute(b'local p=require("idnums_pb").IdNums();p:ParseFromString(wing_props);gamedata:Props(p.idnums)')
        self.client_call(lua, 1, "UIWingQuaryCallback", "NetWingQuaryCallback", {})
        before = self.save["role_state"]["gold"]
        self.client_call(lua, 1, "UIWingStageUpCallback", "NetWingStageUpCallback", {"marknum": 0, "spend": []}); self.refresh()
        self.assertEqual(lua.globals().gamedata[b"cache"][b"role"][b"gold"], before - 1000)
        result = self.client_call(lua, 1, "UIWingSatrUpCallback", "NetWingSatrUpCallback", {"id": 1}); self.refresh()
        self.assertEqual(result[b"wing"][b"starnum"], 1)
        self.assertEqual(lua.globals().gamedata[b"cache"][b"props"][20334][b"num"], self.props(20334))
        lua.globals().UIWingSatrUpCallback(lua.table_from({}))
        self.assertEqual(lua.globals().UIWingStageUpCallback(lua.table_from({b"marknum": 0}))[0], 0)
        lua.globals().NetErrorMessageCallback9(lua.table_from({b"rbuf": recharge.ids([3742, 0])}))
        self.assertEqual(lua.globals().gamedata[b"ext"][b"localWingBusy"], 3741)
        lua.globals().NetErrorMessageCallback9(lua.table_from({b"rbuf": recharge.ids([3741, 0])}))
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localWingBusy"])
        self.seed_wing(8)
        self.client_call(lua, 1, "UIWingQuaryCallback", "NetWingQuaryCallback", {})
        self.client_call(lua, 1, "UIWingColorQueryCallback", "NetWingColorQueryCallback", {})
        before = self.props(20330)
        self.client_call(lua, 1, "UIWingDyeingCallback", "NetWingDyeingCallback", {"id": 1}); self.refresh()
        self.assertEqual(lua.globals().gamedata[b"cache"][b"props"][20330][b"num"], before - 30)
        self.assertEqual(self.props(20330), before - 30)
        self.client_call(lua, 1, "UIWingColorQueryCallback", "NetWingColorQueryCallback", {})
        self.client_call(lua, 1, "UIWingDyeingCallback", "NetWingDyeingCallback", {"id": 0}); self.refresh()
        self.client_call(lua, 1, "UIWingDyeingCallback", "NetWingDyeingCallback", {"id": 1}); self.refresh()
        self.assertEqual(lua.globals().gamedata[b"cache"][b"props"][20330][b"num"], before - 30)
        self.assertIsNone(lua.globals().gameConfig)

    def test_frozen_cup_and_guild_war_keep_actual_wing_visuals_without_live_changes(self):
        from zyj_server import cup, guild_war
        self.seed_wing(8)
        self.success(1, 3743, values=[1]); self.refresh()
        original = copy.deepcopy(self.save)
        cup_snapshot = cup.frozen(self.save, 1, self.config)["snapshot"]
        war_snapshot = guild_war.freeze(self.save)
        for snapshot in (cup_snapshot, war_snapshot):
            units, _ = battle.rosters(snapshot, self.config["copy"]["42101"]["1"], self.config)
            self.assertEqual((units[2]["w_l"], units[2]["w_c"]), (8, 1))
            _, defense = battle.rosters(snapshot, self.config["copy"]["42101"]["1"], self.config)
            report = battle.simulate(units, defense, self.config, 7)
            self.assertEqual(report["meta"]["attack"]["g"][str(units[2]["iid"])]["w_l"], 8)
        self.save["wing_state"]["stage"] = 9
        self.assertEqual(cup_snapshot["wing_state"]["stage"], 8)
        self.assertEqual(war_snapshot["wing_state"]["stage"], 8)
        self.save["wing_state"]["stage"] = 8
        self.assertEqual(self.save, original)

    def test_actual_ui_generations_and_all_wing_models_are_available(self):
        import build_local_apk as builder
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("翅膀界面验证需 lupa.lua51")
        scripts = self.client_scripts()
        lua = LuaRuntime()
        for name in ("GameWing", "UIWing", "Layer_wing_main", "window_wingColor"):
            lua.compile(scripts[f"assets/scripts/{name}.so"].decode())
        page = lua.execute(scripts["assets/scripts/Layer_wing_main.so"].decode())
        lua.globals().page = page
        lua.execute('''
            print=function() end;printT=print
            page.rootNode={};page.localWingGeneration=1;package.loaded.Layer_wing_main=page
            requests={};UIRequest=function(t) requests[#requests+1]=t end
            shown=0
            GameScene={layers={lead={show=true,module={pageDataCallback=function() shown=shown+1 end}}},addUpdate=function() end}
        ''')
        lua.execute(scripts["assets/scripts/UIWing.so"].decode())
        lua.execute('''
            UIRequest({type=3740})
            local view=requests[1].wingView
            UIWingQuary({wingView=view});assert(shown==1)
            page.localWingGeneration=2
            UIWingQuary({wingView=view});assert(shown==1)
            page.localWingGeneration=1;GameScene.layers.lead.show=false
            UIWingQuary({wingView=view});assert(shown==1)
        ''')
        with zipfile.ZipFile(builder.SRC_APK) as archive:
            names = archive.namelist()
            for level in range(1, 14):
                row = self.config["wing_stage"][str(level)]
                for color in (0, *(i for i in range(1, 6) if row[f"c{i}"])):
                    name = f"chibang0{level}" + (f"_0{color}" if color else "")
                    self.assertTrue(any(p.endswith(f"/{name}/{name}.json") for p in names), name)

    def test_actual_star_animation_uses_numeric_exp_and_cancels_closed_generation(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("翅膀经验动画验证需 lupa.lua51")
        lua = LuaRuntime()
        page = lua.execute(self.client_scripts()["assets/scripts/Layer_wing_main.so"].decode())
        lua.globals().page = page
        lua.globals().gamedata = lua.table_from({"config": self.config}, recursive=True)
        lua.execute('''
            print=function() end;printT=print
            table.getTableLength=function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
            ui={getIDandNUMs=function(s) local t={} for c,n in s:gmatch("(%d+),(%d+)") do
                t[#t+1]={cid=tonumber(c),num=tonumber(n)} end return t end,setLabelString=function() end}
            gameConfig={strings={string_common=function() return "label" end}}
            runGamePrompt=function() end;ccc3=function() return {} end
            CCDelayTime={create=function() return 0 end}
            CCCallFunc={create=function(_,f) return f end}
            CCSequence={createWithTwoActions=function(_,a,b) return b end}
            CCProgressFromTo={create=function() return {} end}
            page.rootNode={};page.localWingGeneration=1
            page.rootItems={starupBtn={runAction=function(_,f) pending=f end},expbarprogress={runAction=function() end}}
            page.wingdata={stagenum=1,starnum=0,expnumtable={20}}
            page.poptimes=1;page.starupNum=0;page.oldexp=0;page.labnum=2;page.firstnum=0
            page:showNumAction();pending();assert(page.oldexp==20 and page.poptimes==0)
            page.poptimes=1;page.oldexp=0;page:showNumAction()
            page.localWingGeneration=2;page.rootNode=nil;pending()
            assert(page.oldexp==0 and page.poptimes==1)
        ''')
