"""按原碎片配方获得元始天尊；不新增招募权重，不改正式账号。"""

import copy
import json
import unittest
import zipfile
from unittest.mock import patch

import build_local_apk as builder
import test_exchange
from zyj_server import battle, configuration, formation, player, protocol, recharge, recruit


def setUpModule():
    test_exchange.setUpModule()


class GeneralCompoundTests(unittest.TestCase):
    request = test_exchange.ExchangeTests.request
    success = test_exchange.ExchangeTests.success
    reconnect = test_exchange.ExchangeTests.reconnect
    add_account = test_exchange.ExchangeTests.add_account
    assert_rejected = test_exchange.ExchangeTests.assert_rejected
    props = test_exchange.ExchangeTests.props
    records = test_exchange.ExchangeTests.records
    groups = test_exchange.ExchangeTests.groups
    refresh = test_exchange.ExchangeTests.refresh
    grant = test_exchange.ExchangeTests.grant
    client_scripts = classmethod(test_exchange.ExchangeTests.client_scripts.__func__)
    network_lua = test_exchange.ExchangeTests.network_lua
    client_call = test_exchange.ExchangeTests.client_call

    def setUp(self):
        test_exchange.ExchangeTests.setUp(self)

    def fragment(self, cid):
        raw = formation.records(bytes.fromhex(self.save["world_state"]["1012"]), 1, 1).get(cid, b"")
        return protocol.pb_get_varint(raw, 2) or 0

    def test_fifth_page_uses_the_unchanged_original_recipe_in_server_apk_and_admin_view(self):
        with zipfile.ZipFile("configs_sec5.zip") as archive:
            original = json.loads(archive.read("5/treasure_discount_x2.json"))["8"]
        row = self.config["exchange_shop"]["5"]["1"]
        for field in ("generals", "target", "count", "astrict"):
            self.assertEqual(row[field], original[field])
        exported = dict(configuration.iter_config_bytes("configs_sec5.zip"))
        self.assertEqual(json.loads(exported["exchange_shop.json"]), self.config["exchange_shop"])
        view = configuration.ConfigStore("configs_sec5.zip").table("exchange_shop", "伙伴兑换")
        self.assertEqual(view["rows"][0]["id"], "5")
        self.assertIsNone(view["rows"][0]["original"])

    def test_real_fragment_exchange_compound_reconnect_collection_and_duplicate_conversion(self):
        self.grant(11511, 200)
        before_gold = self.save["role_state"]["gold"]
        self.success(1, 4017, values=[5, 1, 40]); self.refresh()
        self.assertEqual((self.fragment(10511), self.fragment(10598)), (0, 40))
        self.reconnect(); self.refresh()
        raw = self.success(1, 1016, values=[10598]); self.refresh()
        general = self.records(raw)[0]
        self.assertEqual(protocol.pb_get_varint(general, 1), 10598)
        iid = protocol.pb_get_varint(general, 2)
        self.assertGreater(iid, 2000000)
        self.assertEqual(self.fragment(10598), 0)
        self.assertIn(10598, self.save["collection_state"]["generals"])
        self.assertEqual(self.save["role_state"]["gold"], before_gold)
        self.reconnect(); self.refresh()
        self.assertEqual(formation.records(bytes.fromhex(self.save["world_state"]["1002"]), 1, 2)[iid], general)
        reward = recruit.build_reward(self.save, [(10598, 1)], self.config)
        player.apply_reward(self.save, reward, self.config, self.now)
        self.assertEqual(self.fragment(10598), 40)
        self.assertFalse(any((n, w) == (8, 2) for n, w, _ in protocol.iter_pb_fields(reward)))
        self.assert_rejected(1016, values=[10598])

    def test_compound_insufficient_owned_advanced_and_bad_requests_never_consume_fragments(self):
        self.grant(11598, 39)
        self.assert_rejected(1016, values=[10598])
        for values in ([], [11598], [10598, 10598], [10829], [160016], [10101], [999999]):
            self.assert_rejected(1016, values=values)
        for raw in (b"\x0a\x00", b"\x10\x01", b"\x08"):
            self.assert_rejected(1016, raw=raw)
        self.save["guide"]["sections"]["1"]["status"] = 1
        self.assert_rejected(1016, values=[10598])

    def test_save_failure_and_same_connection_retry_keep_synthesis_atomic(self):
        self.grant(11598, 40)
        before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 1016, values=[10598])
        self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))
        session = self.sessions[1]
        raw = recharge.ids([10598])
        packets = session.handle(1016, 1234, raw)
        self.assertEqual(protocol.pb_get_varint(self.records(packets[0][16:])[0], 1), 10598)
        after, disk = copy.deepcopy(session.save), self.store.path(1).read_bytes()
        self.assertEqual(session.handle(1016, 1234, raw), packets)
        self.assertEqual((session.save, self.store.path(1).read_bytes()), (after, disk))

    def test_acquired_general_can_join_formation_and_simulate_without_mutating_existing_members(self):
        self.grant(11598, 40)
        general = self.records(self.success(1, 1016, values=[10598]))[0]
        iid = protocol.pb_get_varint(general, 2)
        self.success(1, 1003, raw=protocol.encode_pb_field(1, 0, 2) + protocol.encode_pb_field(3, 0, iid)); self.refresh()
        attack, defense = battle.rosters(self.save, self.config["copy"]["42101"]["1"], self.config)
        report = battle.simulate(attack, defense, self.config, 7)
        self.assertIn(10598, [v["c"] for v in report["meta"]["attack"]["g"].values()])

    def test_actual_pb_exchange_and_compound_deduct_fragments_once_and_absolute_queries_replace_them(self):
        self.grant(11511, 200)
        lua = self.network_lua(native_protobuf=True)
        native = builder.read_script("gamedata").decode()
        for first, last in (("function gamedata.generalfragmentData(", "function gamedata.recruitsData("),
                            ("function gamedata.ActivityTreasureX3(", "function gamedata.Mammon(")):
            lua.execute(native[native.index(first):native.index(last)].encode())
        lua.execute(b'gamedata.cache.generalfragments={}')
        for name in (b"GameGeneralFragmentList", b"GameGeneralCompound", b"GameActivityMultipleRebate"):
            lua.eval(b"require")(name)
        fd = lambda raw: lua.table_from({b"rbuf": raw})
        lua.globals().NetGeneralFragmentListCallback(fd(bytes.fromhex(self.save["world_state"]["1012"])))
        self.client_call(lua, 1, "UITitbitDiscountX3QuryCallBack", "NetTitbitDiscountX3QuryCallBack", {})
        mode, opcode, raw = lua.globals().UITitbitDiscountX3BuyCallBack(lua.table_from({b"pageid": b"5", b"id": 1, b"num": 40}))
        self.assertEqual((mode, opcode, protocol.parse_ids_pb(raw)), (1, 4017, [5, 1, 40]))
        packets = self.request(1, opcode, raw=raw)
        lua.globals().NetTitbitDiscountX3BuyCallBack(fd(packets[0][1]))
        lua.globals().NetGeneralFragmentListCallback(fd(next(raw for mid, raw in packets if mid == 1012)))
        self.assertEqual(lua.globals().gamedata[b"cache"][b"generalfragments"][10598][b"num"], 40)
        request = lua.table_from({b"ids": lua.table_from({b"1": 10598}), b"compoundView": 9})
        mode, opcode, raw = lua.globals().UIGeneralCompoundCallBack(request)
        self.assertEqual((mode, opcode, protocol.parse_ids_pb(raw)), (1, 1016, [10598]))
        self.assertEqual(lua.globals().UIGeneralCompoundCallBack(request)[0], 0)
        lua.globals().NetErrorMessageCallback9(fd(recharge.ids([4017, 0])))
        self.assertIsNotNone(lua.globals().gamedata[b"ext"][b"localCompoundBusy"])
        packets = self.request(1, opcode, raw=raw)
        result = lua.globals().NetGeneralCompoundCallBack(fd(packets[0][1]))
        lua.globals().NetGeneralFragmentListCallback(fd(next(raw for mid, raw in packets if mid == 1012)))
        self.assertEqual((result[b"gets"][1][b"cid"], result[b"compoundView"]), (10598, 9))
        self.assertIsNone(lua.globals().gamedata[b"cache"][b"generalfragments"][10598])
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localCompoundBusy"])
        self.assertTrue(lua.globals().NetGeneralCompoundCallBack(fd(b""))[b"localCompoundIgnored"])
        lua.globals().UIGeneralCompoundCallBack(request)
        lua.globals().NetErrorMessageCallback9(fd(recharge.ids([1016, 0])))
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localCompoundBusy"])
        self.assertIsNone(lua.globals().gameConfig)

    def test_actual_existing_fifth_tab_controls_and_synthesis_ui_ignore_stale_page_and_window(self):
        from lupa.lua51 import LuaRuntime
        scripts = self.client_scripts()
        lua = LuaRuntime()
        for name in ("GameGeneralCompound", "UIGenerals", "Layer_general", "window_infoAndAccess"):
            lua.compile(scripts[f"assets/scripts/{name}.so"].decode())
        lua.execute('''print=function() end;printT=print
            UIRequest=function(t) request=t end
            page={rootNode={},localCompoundGeneration=1,selectpage="fragments"}
            window={localCompoundGeneration=1}
            package.loaded.Layer_general=page;package.loaded.window_infoAndAccess=window
            GameScene={layers={generals={show=true}},addUpdate=function() end}
            opened=0;gameWindows={openWindow=function() opened=opened+1 end,windows={}}
        ''')
        lua.execute(scripts["assets/scripts/UIGenerals.so"].decode())
        lua.execute('''UIRequest({type=1016,ids={10598}})
            local view=request.compoundView
            UIGeneralCompound({compoundView=view});assert(opened==1)
            page.localCompoundGeneration=2
            UIGeneralCompound({compoundView=view});assert(opened==1)
            page.rootNode=nil;GameScene.layers.generals.show=false
            window.root={};window.paramData={cid=10598}
            UIGeneralCompound({compoundView=view});assert(opened==2)
            window.paramData.cid=10511
            UIGeneralCompound({compoundView=view});assert(opened==2)
            window.paramData.cid=10598;window.localCompoundGeneration=2
            UIGeneralCompound({compoundView=view});assert(opened==2)
        ''')
        with zipfile.ZipFile(builder.SRC_APK) as archive:
            path = next(n for n in archive.namelist() if n.endswith("/activityreward_new/duihuanshop.ccbi"))
            data = archive.read(path)
            for name in (b"planbutton5", b"btnnode5", b"plantitle5"):
                self.assertIn(name, data)


if __name__ == "__main__":
    unittest.main()
