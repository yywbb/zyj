"""羽毛兑换：真实配方、原子扣料与实际发布Lua，不操作正式存档。"""

import copy
import unittest
from unittest.mock import patch

import build_local_apk as builder
import test_soul
from zyj_server import player, protocol, recharge


def setUpModule():
    test_soul.setUpModule()


class ExchangeTests(unittest.TestCase):
    request = test_soul.SoulTests.request
    success = test_soul.SoulTests.success
    reconnect = test_soul.SoulTests.reconnect
    add_account = test_soul.SoulTests.add_account
    assert_rejected = test_soul.SoulTests.assert_rejected
    props = test_soul.SoulTests.props
    groups = test_soul.SoulTests.groups
    records = test_soul.SoulTests.records
    refresh = test_soul.SoulTests.refresh
    grant = test_soul.SoulTests.grant
    client_scripts = classmethod(test_soul.SoulTests.client_scripts.__func__)
    client_call = test_soul.SoulTests.client_call
    network_lua = test_soul.SoulTests.network_lua

    def setUp(self):
        test_soul.SoulTests.setUp(self)
        self.save["role_state"]["level"] = 125

    def counts(self):
        result = {mid: protocol.parse_ids_pb(raw) for mid, raw in self.groups(self.success(1, 4016)).items()}
        self.refresh()
        return result

    def test_all_six_open_recipes_charge_configured_materials_and_grant_only_rewards(self):
        for row in self.config["exchange_shop"]["1"].values():
            if not row["open"]:
                continue
            costs = [tuple(map(int, v.split(","))) for v in row["generals"].split(";") if v]
            rewards = [tuple(map(int, v.split(","))) for v in row["target"].split(";") if v]
            for cid, count in costs:
                self.grant(cid, count * 3)
            previous = {cid: self.props(cid) for cid, _ in costs + rewards}
            world = copy.deepcopy(self.save["world_state"])
            packets = self.request(1, 4017, values=[1, row["id"], 3])
            self.assertEqual([mid for mid, _ in packets][:3], [4017, 1200, 1001], (row["id"], packets))
            self.refresh()
            for cid, count in costs:
                self.assertEqual(self.props(cid), previous[cid] - count * 3)
            for cid, count in rewards:
                self.assertEqual(self.props(cid), previous[cid] + count * 3)
            for key in ("1002", "1012", "1107", "1300"):
                self.assertEqual(self.save["world_state"][key], world[key])
            self.assertFalse(any(n in (1, 2, 13, 14, 16) for n, _, _ in protocol.iter_pb_fields(packets[0][1])))
            self.assertEqual(self.counts()[1][row["id"] - 1], 3)

    def test_query_retains_five_native_groups_and_counts_do_not_reset_on_reconnect_or_midnight(self):
        self.grant(20338, 40)
        self.success(1, 4017, values=[1, 1, 2]); self.refresh()
        self.reconnect(); self.refresh()
        self.clock.return_value += 86400
        counts = self.counts()
        self.assertEqual(set(counts), set(range(1, 6)))
        self.assertEqual(counts[1], [2, 0, 0, 0, 0, 0, 0])
        self.assertEqual(self.props(20338), 20)
        self.assertEqual(self.props(20342), 10)

    def test_closed_pages_levels_quantities_and_malformed_payloads_cannot_exchange(self):
        for values in ([1, 7, 1], [2, 1, 1], [3, 1, 1], [4, 1, 1], [5, 1, 1],
                       [0, 1, 1], [1, 99, 1], [1, 1], [1, 1, 0], [1, 1, 1000], [1, 1, 1, 0]):
            self.assert_rejected(4017, values=values)
        for raw in (b"\x08", b"\x10\x01", b"\x0a\x00", recharge.ids([1, 1, 1]) + b"\x10\x01"):
            self.assert_rejected(4017, raw=raw)
        self.assert_rejected(4016, values=[1])
        self.assert_rejected(999900, raw=protocol.encode_pb_field(1, 2,
            protocol.encode_pb_field(1, 0, 4017) + protocol.encode_pb_field(2, 2, recharge.ids([1, 1, 1]))))
        self.save["role_state"]["level"] = 124
        self.assert_rejected(4017, values=[1, 5, 1])
        self.save["role_state"]["level"] = 125
        with patch.dict(self.config["exchange_shop"]["1"]["5"], {"up_level": 124}):
            self.assert_rejected(4017, values=[1, 5, 1])
        self.save["guide"]["sections"]["1"]["status"] = 1
        self.assert_rejected(4017, values=[1, 1, 1])

    def test_second_material_insufficient_reward_overflow_limit_and_save_failure_rollback_whole_batch(self):
        self.grant(20339, 4)
        self.assert_rejected(4017, values=[1, 2, 2])
        self.grant(20338, 10)
        self.grant(20343, (1 << 31) - 1)
        self.assert_rejected(4017, values=[1, 2, 2])
        raw = bytes.fromhex(self.save["world_state"]["1200"])
        self.save["world_state"]["1200"] = b"".join(protocol.encode_pb_field(n, w, v) for n, w, v in protocol.iter_pb_fields(raw)
            if (n, w) != (1, 2) or protocol.pb_get_varint(v, 1) != 20343).hex()
        before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 4017, values=[1, 2, 2])
        self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))
        self.success(1, 4017, values=[1, 2, 2]); self.refresh()
        self.save["exchange_state"]["counts"]["1:2"] = 999
        self.assert_rejected(4017, values=[1, 2, 1])

    def test_same_connection_retry_does_not_repeat_cost_or_reward_and_rollback_clock_rejects(self):
        self.grant(20338, 40)
        session = self.sessions[1]
        body = recharge.ids([1, 1, 2])
        packets = session.handle(4017, 909, body)
        self.assertEqual(protocol.pb_get_varint(packets[0][16:], 1), None)
        after, disk = copy.deepcopy(session.save), self.store.path(1).read_bytes()
        self.assertEqual(session.handle(4017, 909, body), packets)
        self.assertEqual((session.save, self.store.path(1).read_bytes()), (after, disk))
        self.clock.return_value -= 1
        self.assert_rejected(4017, values=[1, 1, 1])

    def test_corrupt_saved_counts_and_invalid_config_fail_closed(self):
        for state in ([], {"counts": []}, {"counts": {"1:1": -1}, "checked_at": self.now},
                      {"counts": {"5:99": 1}, "checked_at": self.now},
                      {"counts": {"1:1": True}, "checked_at": self.now}):
            self.save["exchange_state"] = state
            self.assert_rejected(4016)
        self.save.pop("exchange_state")
        self.grant(20338, 100)
        for field, value in (("generals", "20338,0;"), ("generals", "20338,-1;"),
                             ("target", "20342,-1;"), ("target", "10598,1;"), ("astrict", 1)):
            with patch.dict(self.config["exchange_shop"]["1"]["1"], {field: value}):
                self.assert_rejected(4017, values=[1, 1, 1])

    def test_actual_native_pb_callback_keeps_materials_counts_busy_lock_and_fifo_context(self):
        self.grant(20339, 10); self.grant(20338, 20)
        lua = self.network_lua(native_protobuf=True)
        code = builder.read_script("gamedata").decode()
        start = code.index("function gamedata.ActivityTreasureX3(")
        end = code.index("\nfunction ", start + 1)
        lua.execute(code[start:end].encode())
        lua.eval(b"require")(b"GameActivityMultipleRebate")
        lua.globals().seed_props = bytes.fromhex(self.save["world_state"]["1200"])
        lua.execute(b'local p=require("idnums_pb").IdNums();p:ParseFromString(seed_props);gamedata:Props(p.idnums)')
        result = self.client_call(lua, 1, "UITitbitDiscountX3QuryCallBack", "NetTitbitDiscountX3QuryCallBack", {"exchangeView": 1})
        self.assertEqual(result[b"exchangeView"], 1)
        request = lua.table_from({b"pageid": b"1", b"id": 2, b"index": 99, b"num": 2, b"exchangeView": 1})
        mode, opcode, raw = lua.globals().UITitbitDiscountX3BuyCallBack(request)
        self.assertEqual((mode, opcode, protocol.parse_ids_pb(raw)), (1, 4017, [1, 2, 2]))
        self.assertEqual(lua.globals().UITitbitDiscountX3BuyCallBack(request)[0], 0)
        self.assertEqual(lua.globals().UITitbitDiscountX3QuryCallBack(lua.table_from({}))[0], 0)
        fd = lambda raw: lua.table_from({b"rbuf": raw})
        lua.globals().NetErrorMessageCallback9(fd(recharge.ids([4016, 0])))
        self.assertIsNotNone(lua.globals().gamedata[b"ext"][b"localExchangeBusy"])
        result = lua.globals().NetTitbitDiscountX3BuyCallBack(fd(self.success(1, 4017, raw=raw)))
        self.refresh()
        self.assertEqual((result[b"index"], result[b"pageid"], result[b"exchangeView"]), (2, 1, 1))
        for cid in (20338, 20339, 20343):
            self.assertEqual(lua.globals().gamedata[b"cache"][b"props"][cid][b"num"], self.props(cid))
        self.assertEqual(result[b"activityTreasure"][1][2][b"num"], 2)
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localExchangeBusy"])
        self.assertTrue(lua.globals().NetTitbitDiscountX3BuyCallBack(fd(b""))[b"localExchangeIgnored"])
        for view in (2, 3):
            lua.globals().UITitbitDiscountX3QuryCallBack(lua.table_from({b"exchangeView": view}))
        self.assertEqual(lua.globals().UITitbitDiscountX3BuyCallBack(request)[0], 0)
        for view in (2, 3):
            result = lua.globals().NetTitbitDiscountX3QuryCallBack(fd(self.success(1, 4016)))
            self.assertEqual(result[b"exchangeView"], view)
            self.assertEqual(result[b"activityTreasure"][1][2][b"num"], 2)
        lua.globals().UITitbitDiscountX3BuyCallBack(request)
        lua.globals().NetErrorMessageCallback9(fd(recharge.ids([4017, 0])))
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localExchangeBusy"])
        self.assertIsNone(lua.globals().gameConfig)

    def test_actual_ui_rejects_closed_page_reply_and_old_purchase_dialog_without_auto_consumption(self):
        from lupa.lua51 import LuaRuntime
        lua = LuaRuntime()
        scripts = self.client_scripts()
        for name in ("GameActivityMultipleRebate", "UIActivityMultipleRebate", "Layer_activity_treasuresDiscount_x3"):
            lua.compile(scripts[f"assets/scripts/{name}.so"].decode())
        page = lua.execute(scripts["assets/scripts/Layer_activity_treasuresDiscount_x3.so"].decode())
        lua.globals().page = page
        lua.globals().gamedata = lua.table_from({"config": self.config}, recursive=True)
        lua.execute('''print=function() end;printT=print
            GameScene={roleinfo={level=124}};table.getTableLength=function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
            local counts={};for i=1,7 do counts[tostring(i)]={num=0,isshow=1} end
            page:screenLevelData({["1"]=counts})
            assert(counts["1"].isshow==1 and counts["5"].isshow==0 and counts["7"].isshow==0)
            GameScene.roleinfo.level=125;page:screenLevelData({["1"]=counts})
            assert(counts["5"].isshow==1 and counts["7"].isshow==0)
        ''')
        lua.execute('''print=function() end;printT=print
            page.show=true;page.localExchangeGeneration=1
            page.reloaddata=function(self,t) self.reloads=(self.reloads or 0)+1 end
            package.loaded.Layer_activity_treasuresDiscount_x3=page
            requests={};UIRequest=function(t) requests[#requests+1]=t end
            popups=0;showRewardPopupWindow=function() popups=popups+1 end
            GameScene={addUpdate=function() end}
        ''')
        lua.execute(scripts["assets/scripts/UIActivityMultipleRebate.so"].decode())
        lua.execute('''UIRequest({type=4016});assert(requests[1].exchangeView==1)
            UITitbitDiscountX3Qury({exchangeView=1});assert(page.reloads==1)
            UITitbitDiscountX3Buy({exchangeView=1});assert(page.reloads==2 and popups==1)
            assert(#requests==1)
            page.localExchangeGeneration=2
            UITitbitDiscountX3Buy({exchangeView=1});assert(page.reloads==2 and popups==1)
            page.show=false
            UITitbitDiscountX3Qury({exchangeView=2});assert(page.reloads==2)
        ''')
        code = scripts["assets/scripts/Layer_activity_treasuresDiscount_x3.so"].decode()
        start = code.index("    local generation, pageid =")
        end = code.index("    end, CCControlEventTouchUpInside)", start) + len("    end, CCControlEventTouchUpInside)")
        lua.execute('''self=page;page.show=true;page.selectpage="1";page.isscrolltouched=true
            data={id=2,count=999};index=2;props={{num=2}};self.localExchangeGeneration=2
            remaining_num=999;canExchangeMax=2;treasuresStatus={num=0}
            gameTouch={clickprofbytime=function() end};ui={exchangeMore=function(cb) dialog=cb end}
            item={exchangeBtn={addHandleOfControlEvent=function(self,cb) self.callback=cb end}}
        ''')
        lua.execute(code[start:end])
        lua.execute('''item.exchangeBtn.callback();local callback=dialog;assert(callback)
            page.localExchangeGeneration=3;callback(1);assert(#requests==1)
            page.localExchangeGeneration=2;page.selectpage="2";callback(1);assert(#requests==1)
            page.selectpage="1";callback(1);assert(#requests==2 and requests[2].id==2)
        ''')


if __name__ == "__main__":
    unittest.main()
