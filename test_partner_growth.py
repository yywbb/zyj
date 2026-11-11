"""伙伴高阶成长：临时账号、真实配置、费用和失败回滚。"""

import copy
from collections import Counter
from itertools import product
import json
import unittest
import zipfile
from unittest.mock import patch

import test_soul
import test_hades_battle
import build_local_apk as builder
from zyj_server import battle, cheer, development, formation, partner_growth, player, protocol, ranking, recruit


def setUpModule():
    test_soul.setUpModule()


# 自动进修的真实打包 Lua 时序模拟：12001 材料回显可丢弃、5513 回显可延迟，
# cocos 动作按时间排队，stopAllActions 只清对应节点。用于复现「回显丢失后
# autoXiulian 仍为真却再无续接定时器，必须点一次取消再点一次」的老问题。
AUTO_RESEARCH_LUA = r'''
generalup={};print=function() end;printT=function() end
clock=0;timers={};requests={};conflicting=0;level=0;heart=0;dropLeft=0;dropEvery=0;netdelay=0.05
lostEvery=0;lostCount=0;resyncs=0;n5513Sent=0
local function node(name)
  return setmetatable({name=name,
    runAction=function(self,a) if a and a.fn then table.insert(timers,{at=clock+(a.delay or 0.3),fn=a.fn,node=self}) end end,
    stopAllActions=function(self) local k={} for _,x in ipairs(timers) do if x.node~=self then table.insert(k,x) end end timers=k end,
    numberOfRunningActions=function(self) local n=0 for _,x in ipairs(timers) do if x.node==self then n=n+1 end end return n end},
    {__index=function() return function() end end})
end
netnode=node("net")
CCDelayTime={create=function(_,d) return {delay=d} end}
CCCallFunc={create=function(_,fn) return {fn=fn} end}
CCSequence={createWithTwoActions=function(_,a,b) return {delay=a.delay,fn=b.fn} end}
CCProgressFromTo={create=function() return {} end}
CCControlEventTouchUpInside=1
CCBReaderLoad=function() return {},{topnode=nil,bottomnode=nil} end
getAnimationManager=function() return {runAnimationsForSequenceNamed=function() end} end
table.copy=function(x) return x end
guide={controller={addComplete=function() end}}
GameScene={checkUpdate=function() return false end}
gameConfig={strings={string_common=function() return "" end,needlv=function() return "" end},images={}}
ui={setLabelString=function() end,setNewIcon=function() end,
    getIDandNUMs=function() return {{cid=1000,num=1}} end,
    IDconfig=function() return {name="mat"} end}
setControlButtonFrame=function() end
runGamePrompt=function() prompts=(prompts or 0)+1 end
gamedata={ext={},cache={},config={Immortal_level={["1"]={},["2"]={}}}}
for n=0,36 do for k=1,2 do gamedata.config.Immortal_level[tostring(k)][tostring(n)]={
  character=1000,generalLevel=1,consumeEveryTimes="1000,1",extraConsume="1000,1",
  stageAttr1="1,1",stageAttr2="1,1",stageAttr3="1,1"} end end
function UIRequest(req)
  table.insert(requests,req)
  if req.type==12001 then
    local skip=false
    if dropLeft>0 then dropLeft=dropLeft-1;skip=true
    elseif dropEvery>0 and #requests%dropEvery==0 then skip=true end
    if not skip then
      local n={} for _,c in ipairs(req.cids or {}) do n[tostring(c)]=999999 end
      page:setXiuLianPropShow(n)
    end
  elseif req.type==5513 then
    if gamedata.ext.localPartnerGrowthBusy then conflicting=conflicting+1 end
    local p={};gamedata.ext.localPartnerGrowthBusy=p;gamedata.ext.localFormationBusy=p
    n5513Sent=n5513Sent+1
    -- 偶发整包丢失：没有成功回包、没有错误回包，网络层的 busy 锁会残留。
    if lostEvery>0 and n5513Sent%lostEvery==0 then lostCount=lostCount+1;return end
    local up=req.isBreak==1
    table.insert(timers,{at=clock+netdelay,node=netnode,fn=function()
      gamedata.ext.localPartnerGrowthBusy=nil;gamedata.ext.localFormationBusy=nil
      if up then level=level+1;heart=0 else heart=heart+250 end
      if heart>1000 then heart=1000 end
      local xl={heart1=heart,heart2=0} for i=1,8 do xl["attr"..i]=0 end
      page:xiuLianSuccess({general={iid=7,cid=10830,level1=300,level6=level,level7=0},generalXiuLian=xl})
    end})
  elseif req.type==5511 then
    page.data.general.level6=level
  elseif req.type==5512 then
    -- 重查 5512 会把服务端真实进度/序号回灌，并解除续接器的重查门禁。
    resyncs=resyncs+1
    local xl={iid=req.iid,heart1=heart,heart2=0} for i=1,8 do xl["attr"..i]=0 end
    page:getXiuLianData({general=xl})
  end
end
local xl0={heart1=0,heart2=0} for i=1,8 do xl0["attr"..i]=0 end
page=setmetatable({data={general={iid=7,cid=10830,level1=300,level6=0,level7=0}},
  selectpage="xiulian",autoXiulian=false,levelUp=false,localPartnerGeneration=3,
  xiulianType=1,xiuLianProps={{cid=1000,num=1}},xiuLianHave={["1000"]=999999},
  xiuLianData={[7]=xl0},xiuLianAddData={[7]={}},
  rootItems=setmetatable({}, {__index=function(_,k) if not _G["n_"..k] then _G["n_"..k]=node(k) end return _G["n_"..k] end}),
  ReloadData=function(self) self:getXiulianProp() end,
  setXiuLianData=function() end,freshUI=function() end,
  setPage_xiulian=function() end,touchLayerSet=function() end},
  {__index=generalup})
'''


class PartnerGrowthTests(unittest.TestCase):
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

    def setUp(self):
        test_soul.SoulTests.setUp(self)
        self.save["role_state"].update(level=150, coin=10**12, gold=1000000)
        self.iid = 2000900
        self.put_hero()

    def put_hero(self, cid=10609, advance=10, awake=40, level=300):
        row = self.config["general"][str(cid)]
        raw = recruit.new_general(cid, self.iid, self.config)
        for field, value in ((3, level), (4, advance), (18, awake)):
            raw = protocol.pb_set_varint(raw, field, value)
        for name, field in (("atk", 6), ("def", 7), ("hp", 8), ("speed", 9)):
            raw = protocol.pb_set_varint(raw, field, int(battle.general_base(row, name, level, advance, self.config)))
        permanent = battle.self_stats(row, level, advance, self.config)
        awaken = partner_growth.awakened(raw, self.config)
        for field in range(6, 17):
            raw = protocol.pb_set_varint(raw, field, (protocol.pb_get_varint(raw, field) or 0)+permanent[field]+awaken.get(field, 0))
        raw = protocol.pb_set_varint(raw, 17, row["potential"]+int(row["potential-grow"]*(level-1)))
        raw = protocol.pb_set_varint(raw, 20, sum(protocol.pb_get_varint(raw, f) for f in (6, 7, 9))+protocol.pb_get_varint(raw, 8)//10)
        raw += protocol.encode_pb_field(50, 2, b"preserve-partner")
        player.record_slot_update(self.save, protocol.encode_pb_field(1, 2, raw))
        self.save["self_stats_version"] = 1
        return raw

    def test_yuding_plus_ten_preview_returns_real_red_template_without_changing_state(self):
        before = copy.deepcopy(self.save)
        result, costs, update = development.prepare(1023, self.save, protocol.encode_pb_field(1, 0, self.iid), self.config)
        raw = formation.records(result, 1, 2)[self.iid]
        self.assertEqual((protocol.pb_get_varint(raw, 1), protocol.pb_get_varint(raw, 4)), (10831, 11))
        self.assertIn((50, 2, b"preserve-partner"), list(protocol.iter_pb_fields(raw)))
        self.assertEqual((self.save, costs, update), (before, [], b""))

    def paid(self, opcode, values):
        raw = b"".join(protocol.encode_pb_field(1, 0, v) for v in values)
        working = copy.deepcopy(self.save)
        if opcode == 1017:
            _, costs, _ = development.prepare(opcode, working, raw, self.config)
        else:
            _, costs, _ = partner_growth.prepare(opcode, working, raw, self.config, self.now, 7)
        total = Counter()
        for cid, count in costs:
            total[cid] += count
        costs = total
        for cid, count in costs.items():
            if cid not in (1000, 1001):
                player.change_item_count(self.save, cid, count, self.config, self.now)
        coin = self.save["role_state"]["coin"]
        result = self.request(1, opcode, values=values)
        self.assertEqual(result[0][0], opcode, result)
        self.refresh()
        self.assertEqual(self.save["role_state"]["coin"], coin-costs[1000])
        return result

    def test_awakening_uses_original_aptitude_start_actual_cost_and_stale_target_guard(self):
        raw = self.put_hero(awake=0)
        result = self.paid(1025, [self.iid, 0])
        self.assertEqual(protocol.pb_get_varint(self.gen(self.iid), 18), 21)
        row = self.config["general_awakenattr"]["23"]["21"]
        for name, field in (("atk", 6), ("def", 7), ("hp", 8), ("hit", 14)):
            self.assertEqual(protocol.pb_get_varint(self.gen(self.iid), field), (protocol.pb_get_varint(raw, field) or 0)+row["awaken_"+name])
        self.assertIn(1200, [mid for mid, _ in result])
        self.assert_rejected(1025, values=[self.iid, 0])
        self.reconnect(); self.refresh()
        self.assertEqual(protocol.pb_get_varint(self.gen(self.iid), 18), 21)

    def test_red_levels_charge_red_quality_prices_and_real_essences_once(self):
        for stage in (11, 12, 13):
            old = self.put_hero(cid=10609 if stage == 11 else 10831, advance=stage-1, awake=90)
            result = self.paid(1017, [protocol.pb_get_varint(old, 1), 0, stage-1])
            hero = self.gen(self.iid)
            self.assertEqual((protocol.pb_get_varint(hero, 1), protocol.pb_get_varint(hero, 4)), (10831, stage))
            self.assertIn(3780, [mid for mid, _ in result])
            self.assert_rejected(1017, values=[10831, 0, stage-1])
            self.assertIn((50, 2, b"preserve-partner"), list(protocol.iter_pb_fields(hero)))

    def test_every_combat_supported_red_template_reaches_plus_thirteen_with_real_costs(self):
        completed = []
        for cid, row in sorted(self.config["general"].items()):
            if row["quality"] != 6 or not row["battle"] or row.get("partner_id") or row.get("actor") == "lead" or row["breach_upper_limit"] < 13:
                continue
            raw = self.put_hero(int(cid), advance=10, awake=90)
            try:
                partner_growth.check_combat(protocol.pb_set_varint(raw, 4, 13), self.config)
            except ValueError:
                with self.assertRaises(ValueError):
                    development.prepare(1017, copy.deepcopy(self.save), protocol.encode_pb_field(1, 0, int(cid))+b"\x08\x00\x08\x0a", self.config)
                continue
            for stage in (11, 12, 13):
                self.paid(1017, [int(cid), 0, stage-1])
            self.assertEqual(protocol.pb_get_varint(self.gen(self.iid), 4), 13)
            completed.append(int(cid))
        self.assertEqual(len(completed), 38)

    def test_all_six_later_levels_research_and_soaring_gates_reach_plus_sixteen(self):
        self.put_hero(awake=90)
        for target in range(11, 17):
            need = self.config["general_awake"][str(target)]["soaring_limit"]
            for level in range((protocol.pb_get_varint(self.gen(self.iid), 23) or 0)+1, need+1):
                step = self.config["partner_soaring"][str(level)]
                growth = self.save.setdefault("partner_growth_state", {"serial": 0, "checked_at": 0, "research": {}})
                growth["research"][str(self.iid)] = [step["immortal"], 0, 0, 0, 0]*2
                self.paid(7001, [self.iid, level-1])
            hero = self.gen(self.iid)
            self.paid(1017, [protocol.pb_get_varint(hero, 1), 1 if target >= 14 else 0, target-1])
        hero = self.gen(self.iid)
        self.assertEqual([protocol.pb_get_varint(hero, f) for f in (1, 4, 23, 35, 36, 37)], [164036, 16, 30, 1, 1, 1])
        self.assertGreater(protocol.pb_get_varint(hero, 26), 0)
        entry = ranking.entry(1, self.save, self.config)
        self.assertEqual(entry["scores"]["18"], protocol.pb_get_varint(hero, 20)+protocol.pb_get_varint(hero, 34))
        partner_growth.validate(hero, self.config)
        self.assert_rejected(1017, values=[164036, 1, 16])
        self.reconnect(); self.refresh()
        self.assertEqual(self.gen(self.iid), hero)
        self.success(1, 1004, raw=protocol.encode_pb_field(1, 0, 1)+protocol.encode_pb_field(3, 0, self.iid));self.refresh()
        self.assertEqual(cheer.combat(self.save, self.config), [164036])
        old = copy.deepcopy(self.save)
        self.success(1, 1004, raw=protocol.encode_pb_field(1, 0, 1)+protocol.encode_pb_field(3, 0, 0));self.refresh()
        self.success(1, 1003, raw=protocol.encode_pb_field(1, 0, 2)+protocol.encode_pb_field(3, 0, self.iid));self.refresh()
        self.assertEqual(self.save["role_state"]["g_power"]-old["role_state"]["g_power"], protocol.pb_get_varint(hero, 34))
        self.success(1, 1003, raw=protocol.encode_pb_field(1, 0, 2)+protocol.encode_pb_field(3, 0, 0));self.refresh()
        self.assertEqual(self.save["role_state"]["g_power"], old["role_state"]["g_power"])

    def test_actual_research_rolls_and_stage_boundary_charge_separately(self):
        self.put_hero(awake=90)
        self.success(1, 5512, values=[self.iid]);self.refresh()
        self.paid(5513, [self.iid, 1, 0, 0, 0, 0])
        progress = partner_growth.research(self.save, self.iid, self.config)
        self.assertGreater(progress[4], 0)
        self.assertEqual(progress[4], sum(progress[1:4]))
        self.assert_rejected(5513, values=[self.iid, 1, 0, 0, 0, 0])
        growth = self.save["partner_growth_state"]
        cap = self.config["Immortal_level"]["1"]["0"]["character"]
        growth["research"][str(self.iid)] = [0, cap, 0, 0, cap]+[0]*5
        before = self.gen(self.iid)
        self.paid(5513, [self.iid, 1, 1, 0, cap, growth["serial"]])
        # 升学是纯增益：本档点数保留，只追加已完成档的阶段属性。
        self.assertEqual(partner_growth.research(self.save, self.iid, self.config), [1, cap, 0, 0, cap]+[0]*5)
        changed = self.gen(self.iid)
        row = self.config["Immortal_level"]["1"]["0"]
        self.assertEqual(protocol.pb_get_varint(changed, 8)-protocol.pb_get_varint(before, 8),
                         int(row["stageAttr1"].split(",")[1]))
        self.assertEqual(protocol.pb_get_varint(changed, 6)-protocol.pb_get_varint(before, 6),
                         int(row["stageAttr2"].split(",")[1]))
        self.assertGreater(protocol.pb_get_varint(changed, 20), protocol.pb_get_varint(before, 20))

    def level_up(self, kind, level, split):
        """在存档副本上走一次真实 5513 升学；把伙伴置为主阵以校验角色战力同步。"""
        config = self.config
        row = config["Immortal_level"][str(kind)][str(level)]
        cap = row["character"]
        progress = [0]*10
        offset = (kind-1)*5
        progress[offset:offset+5] = [level, *split, cap]
        working = copy.deepcopy(self.save)
        working["partner_growth_state"] = {"research": {str(self.iid): progress}, "serial": 0, "checked_at": 0}
        body = b"".join(protocol.encode_pb_field(1, 0, v) for v in (self.iid, kind, 1, level, cap, 0))
        original = formation.records

        def active(world, kind_, sub):
            return {self.iid: b""} if (kind_, sub) == (4, 2) else original(world, kind_, sub)

        with patch.object(formation, "records", side_effect=active):
            _, costs, update = partner_growth.prepare(5513, working, body, config, self.now, 7)
        changed = next(data for _, wire, data in protocol.iter_pb_fields(update) if wire == 2)
        return working, progress, changed, costs, row

    def test_research_level_up_keeps_points_and_never_lowers_stats_or_power(self):
        weights = {1: (59012, 81708, 90000), 2: (49934, 90786, 90000)}
        for kind, shares in weights.items():
            total = sum(shares)
            for level in (0, 5, 20, 33):
                cap = self.config["Immortal_level"][str(kind)][str(level)]["character"]
                balanced = [cap*x//total for x in shares]
                balanced[2] = cap-balanced[0]-balanced[1]
                for split in (balanced, [0, cap, 0], [cap, 0, 0], [0, 0, cap]):
                    with self.subTest(kind=kind, level=level, split=split):
                        working, progress, changed, costs, row = self.level_up(kind, level, split)
                        offset = (kind-1)*5
                        after = partner_growth.research(working, self.iid, self.config)
                        self.assertEqual(after[offset:offset+5], [level+1, *split, sum(split)])
                        stage = {}
                        for i in (1, 2, 3):
                            name, amount = row[f"stageAttr{i}"].split(",")
                            stage[name] = stage.get(name, 0)+int(amount)
                        before_stats = partner_growth.research_stats(progress, self.config)
                        after_stats = partner_growth.research_stats(after, self.config)
                        for name, value in before_stats.items():
                            self.assertEqual(after_stats[name]-value, stage.get(name, 0), name)
                        raw = self.gen(self.iid)
                        delta = protocol.pb_get_varint(changed, 20)-protocol.pb_get_varint(raw, 20)
                        expected = (stage.get("hp", 0)//10+stage.get("atk", 0)+stage.get("def", 0)
                                    +stage.get("adddmg", 0)+stage.get("subdmg", 0))
                        # HP 按整十分计战力，增量允许因旧值余量多 1 分，但不能为负。
                        self.assertIn(delta, (expected, expected+1))
                        self.assertGreater(delta, 0)
                        self.assertEqual(working["role_state"]["power"]-self.save["role_state"]["power"], delta)
                        self.assertEqual(working["role_state"]["power_all"]-self.save["role_state"]["power_all"], delta)
                        self.assertEqual(costs, partner_growth.pairs(row["extraConsume"]))

    def test_research_level_up_chain_keeps_serial_gates_and_rejects_bad_next_cap(self):
        config = self.config
        cap = config["Immortal_level"]["1"]["0"]["character"]
        next_cap = config["Immortal_level"]["1"]["1"]["character"]
        self.assertGreater(next_cap, cap)
        working = copy.deepcopy(self.save)
        working["partner_growth_state"] = {"research": {str(self.iid): [0, cap, 0, 0, cap]+[0]*5},
                                            "serial": 0, "checked_at": 0}

        def call(values, seed=7):
            body = b"".join(protocol.encode_pb_field(1, 0, v) for v in values)
            return partner_growth.prepare(5513, working, body, config, self.now, seed)

        state = working["partner_growth_state"]
        call([self.iid, 1, 1, 0, cap, 0])
        self.assertEqual((state["research"][str(self.iid)][:5], state["serial"]), ([1, cap, 0, 0, cap], 1))
        # 新档上限更高，旧心性保留但不满，不能连点升学；普通进修继续累计。
        with self.assertRaisesRegex(ValueError, "进修条件不足"):
            call([self.iid, 1, 1, 1, cap, 1])
        call([self.iid, 1, 0, 1, cap, 1], seed=11)
        grown = state["research"][str(self.iid)]
        self.assertGreater(grown[4], cap)
        self.assertEqual(grown[4], sum(grown[1:4]))
        self.assertEqual(state["serial"], 2)
        grown[1] += next_cap-grown[4]
        grown[4] = next_cap
        call([self.iid, 1, 1, 1, next_cap, 2])
        final = state["research"][str(self.iid)]
        self.assertEqual(final[:5], [2, final[1], final[2], final[3], next_cap])
        self.assertEqual(final[4], sum(final[1:4]))
        self.assertEqual(state["serial"], 3)
        partner_growth.state(working, config)
        # 满级不再收费升学；新档上限异常时扣费前拒绝。
        top = len(config["Immortal_level"]["1"])-1
        top_cap = config["Immortal_level"]["1"][str(top)]["character"]
        working["partner_growth_state"] = {"research": {str(self.iid): [top, top_cap, 0, 0, top_cap]+[0]*5},
                                            "serial": 0, "checked_at": 0}
        with self.assertRaisesRegex(ValueError, "已满级"):
            call([self.iid, 1, 1, top, top_cap, 0])
        working["partner_growth_state"] = {"research": {str(self.iid): [0, cap, 0, 0, cap]+[0]*5},
                                            "serial": 0, "checked_at": 0}
        shrunk = {**config["Immortal_level"]["1"]["1"], "character": cap-1}
        with patch.dict(config["Immortal_level"]["1"], {"1": shrunk}):
            with self.assertRaisesRegex(ValueError, "超出新档上限"):
                call([self.iid, 1, 1, 0, cap, 0])

    def test_missing_gates_insufficient_materials_and_save_failure_are_atomic(self):
        self.put_hero(awake=0)
        self.assert_rejected(1017, values=[10609, 0, 10])
        self.assert_rejected(1025, values=[self.iid, 0])
        self.assert_rejected(7001, values=[self.iid, 0])
        step = self.config["general_awaken"]["21"]
        for cid, count in partner_growth.pairs(step["consume1"]):
            if cid != 1000:
                self.grant(cid, count)
        before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 1025, values=[self.iid, 0])
        self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))

    def test_malformed_growth_requests_and_corrupt_research_never_change_saves(self):
        for opcode, requests in ((1025, ([], [self.iid], [self.iid, 40, 0], [0, 40])),
                                 (7001, ([], [self.iid], [self.iid, 0, 0])),
                                 (5512, ([], [self.iid, 0])),
                                 (5513, ([], [self.iid, 1, 0], [self.iid, 3, 0, 0, 0, 0], [self.iid, 1, 2, 0, 0, 0]))):
            for values in requests:
                self.assert_rejected(opcode, values=values)
        self.assert_rejected(5511, values=[self.iid])
        before = copy.deepcopy(self.save)
        for state in ({"research": {}, "serial": True, "checked_at": 0},
                      {"research": {str(self.iid): [0, 1, 0, 0, 0]+[0]*5}, "serial": 0, "checked_at": 0},
                      {"research": {str(self.iid): [True]+[0]*9}, "serial": 0, "checked_at": 0}):
            working = {**self.save, "partner_growth_state": state}
            with self.assertRaises(ValueError):
                partner_growth.state(working, self.config)
        self.assertEqual(self.save, before)

    def test_actual_packaged_network_pb_cost_fifo_shared_lock_and_matching_errors(self):
        raw = protocol.encode_pb_field(1, 0, 10609)+protocol.encode_pb_field(1, 0, 0)+protocol.encode_pb_field(1, 0, 10)
        _, costs, _ = development.prepare(1017, copy.deepcopy(self.save), raw, self.config)
        for cid, count in costs:
            if cid != 1000:
                player.change_item_count(self.save, cid, count, self.config, self.now)
        lua = self.network_lua(native_protobuf=True)
        code = self.client_scripts()["assets/scripts/gamedata.so"].decode()
        for name in ("updategeneralfragmentbynum", "UpdateRedFragment", "isGeneralOn"):
            start = code.index("function gamedata."+name+"(")
            end = code.find("\nfunction ", start+1)
            lua.execute(code[start:end].encode())
        lua.execute(b'gc=assert(require("GameGeneralBreak"));gamedata.cache.generalfragments={[10609]={cid=10609,num=120}};gamedata.cache.redfragment={[18831]={cid=18831,num=40}};gamedata.cache.generalslove={alldata={}}')
        lua.globals().props_raw = bytes.fromhex(self.save["world_state"]["1200"])
        lua.execute(b'local t=require("idnums_pb").IdNums();t:ParseFromString(props_raw);gamedata:Props(t.idnums)')
        view = lua.table_from({b"iid": self.iid, b"cid": 10609, b"advance": 10, b"awake": 40, b"soar": 0, b"generation": 1})
        query = lua.table_from({b"general": self.iid, b"partnerView": view})
        lua.globals().UIGeneralBreakPreviewCallBack(query)
        lua.globals().UIGeneralBreakPreviewCallBack(query)
        preview = self.success(1, 1023, values=[self.iid])
        result = lua.globals().NetGeneralBreakPreviewCallBack(lua.table_from({b"rbuf": preview, b"ser": 0}))
        self.assertTrue(result[b"partnerIgnored"])
        for _ in range(2):
            result = lua.globals().NetGeneralBreakPreviewCallBack(lua.table_from({b"rbuf": preview, b"ser": 7}))
            self.assertEqual(result[b"nextGeneral"][b"cid"], 10831)
        request = lua.table_from({b"ids": lua.table_from({b"1": 10609}), b"scope": 0, b"partnerView": view})
        mode, opcode, body = lua.globals().UIGeneralBreakCallBack(request)
        self.assertEqual((mode, opcode, protocol.parse_ids_pb(body)), (1, 1017, [10609, 0, 10]))
        self.assertEqual(lua.globals().UIGeneralBreakCallBack(request)[0], 0)
        error = lambda mid: lua.table_from({b"rbuf": protocol.encode_pb_field(1, 0, mid)+b"\x08\x00"})
        lua.globals().NetErrorMessageCallback9(error(1025))
        self.assertIsNotNone(lua.globals().gamedata[b"ext"][b"localPartnerGrowthBusy"])
        before = self.save["role_state"]["coin"]
        packet = self.success(1, opcode, raw=body)
        result = lua.globals().NetGeneralBreakCallBack(lua.table_from({b"rbuf": packet, b"ser": 9}))
        self.assertEqual(result[b"general"][b"cid"], 10831)
        self.assertEqual(lua.globals().gamedata[b"cache"][b"role"][b"coin"], before-10000000)
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localPartnerGrowthBusy"])
        self.assertTrue(lua.globals().NetGeneralBreakCallBack(lua.table_from({b"rbuf": packet, b"ser": 0}))[b"partnerIgnored"])
        self.assertIsNone(lua.globals().gameConfig)

    def test_yuding_all_gold_choices_simulate_both_sides_without_mutating_inputs(self):
        for choices in product((1, 3), repeat=3):
            raw = self.put_hero(cid=164036, advance=13, awake=90)
            raw = protocol.pb_set_varint(raw, 4, 16)
            for i, choice in enumerate(choices, 35):
                raw = protocol.pb_set_varint(raw, i, choice)
            packed = sum(choice*10**(2-i) for i, choice in enumerate(choices))
            raw = protocol.pb_set_varint(raw, 40, self.config["jinjiangkezhiguanxi"][str(packed)]["camp"])
            for field, value in partner_growth.fairy(raw, self.config).items():
                raw = protocol.pb_set_varint(raw, field, value)
            raw = partner_growth.power(self.save, self.gen(self.iid), raw)
            partner_growth.validate(raw, self.config)
            unit = {name: protocol.pb_get_varint(raw, f) or 0 for name, f in battle.GENERAL_FIELDS.items()}
            unit.update(skill=180063, skilllevel=0, partner_skills=partner_growth.skills(raw, self.config))
            for direct in (True, False):
                teams = {True: {}, False: {}}
                for side in teams:
                    for i, pos in enumerate(battle.POSITIONS):
                        teams[side][pos] = dict(unit, iid=(1000 if side else 2000)+i, hp=10000000, speed=10+i)
                        if side != direct or i:
                            teams[side][pos].update(cid=10213, skill=self.config["general"]["10213"]["skillid"], advance=0, partner_skills=[])
                original = copy.deepcopy(teams)
                report = battle.simulate(teams[True], teams[False], self.config, 7, max_rounds=3)
                self.assertEqual(teams, original)
                self.assertIn("endmeta", report)
                test_hades_battle.HadesBattleTests.assert_replays(self, report)

    def test_yuanshi_and_tongtian_all_paid_gold_choices_keep_gates_costs_and_reconnect(self):
        for cid, gold in ((10829, 164004), (10839, 164038)):
            for choices in product((1, 3), repeat=3):
                with self.subTest(cid=cid, choices=choices):
                    raw = self.put_hero(cid, advance=13, awake=90)
                    self.assert_rejected(1017, values=[cid, choices[0], 13])
                    raw = protocol.pb_set_varint(raw, 23, 30)
                    for field, value in partner_growth.fairy(raw, self.config).items():
                        raw = protocol.pb_set_varint(raw, field, value)
                    raw = partner_growth.power(self.save, self.gen(self.iid), raw)
                    player.record_slot_update(self.save, protocol.encode_pb_field(1, 2, raw))
                    for stage, choice in enumerate(choices, 14):
                        old = protocol.pb_get_varint(self.gen(self.iid), 1)
                        self.paid(1017, [old, choice, stage-1])
                        self.assert_rejected(1017, values=[old, choice, stage-1])
                    hero = self.gen(self.iid)
                    self.assertEqual([protocol.pb_get_varint(hero, f) for f in (1, 4, 35, 36, 37)], [gold, 16, *choices])
                    self.assertIn((50, 2, b"preserve-partner"), list(protocol.iter_pb_fields(hero)))
                    partner_growth.check_combat(hero, self.config)
                    self.reconnect();self.refresh()
                    self.assertEqual(self.gen(self.iid), hero)

    def test_guangchengzi_all_paid_gold_choices_keep_gates_costs_and_reconnect(self):
        # 广成子 10830→164027：六彩金技能此前未接入战斗引擎，+13 升 +14 会在扣费前报
        # 「尚不支持该突破被动 9001142」。三阶各两种选择都应能付费、保存并通过战前校验。
        for choices in product((1, 3), repeat=3):
            with self.subTest(choices=choices):
                raw = self.put_hero(10830, advance=13, awake=90)
                self.assert_rejected(1017, values=[10830, choices[0], 13])
                raw = protocol.pb_set_varint(raw, 23, 30)
                for field, value in partner_growth.fairy(raw, self.config).items():
                    raw = protocol.pb_set_varint(raw, field, value)
                raw = partner_growth.power(self.save, self.gen(self.iid), raw)
                player.record_slot_update(self.save, protocol.encode_pb_field(1, 2, raw))
                for stage, choice in enumerate(choices, 14):
                    old = protocol.pb_get_varint(self.gen(self.iid), 1)
                    self.paid(1017, [old, choice, stage-1])
                    self.assert_rejected(1017, values=[old, choice, stage-1])
                hero = self.gen(self.iid)
                self.assertEqual([protocol.pb_get_varint(hero, f) for f in (1, 4, 35, 36, 37)], [164027, 16, *choices])
                self.assertIn((50, 2, b"preserve-partner"), list(protocol.iter_pb_fields(hero)))
                partner_growth.check_combat(hero, self.config)
                self.reconnect(); self.refresh()
                self.assertEqual(self.gen(self.iid), hero)

    def test_new_gold_missing_materials_and_final_save_failure_do_not_convert_or_charge(self):
        for cid, choice in product((10829, 10839), (1, 3)):
            self.save["role_state"].update(level=150, coin=10**12, gold=1000000)
            raw = protocol.pb_set_varint(self.put_hero(cid, advance=13, awake=90), 23, 30)
            for field, value in partner_growth.fairy(raw, self.config).items():
                raw = protocol.pb_set_varint(raw, field, value)
            raw = partner_growth.power(self.save, self.gen(self.iid), raw)
            player.record_slot_update(self.save, protocol.encode_pb_field(1, 2, raw))
            player.change_item_count(self.save, 20811, -self.props(20811), self.config, self.now)
            self.assert_rejected(1017, values=[cid, choice, 13])
            working = copy.deepcopy(self.save)
            body = b"".join(protocol.encode_pb_field(1, 0, v) for v in (cid, choice, 13))
            _, costs, _ = development.prepare(1017, working, body, self.config)
            for item, count in costs:
                if item not in (1000, 1001):
                    self.grant(item, count)
            before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
            with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
                self.request(1, 1017, values=[cid, choice, 13])
            self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))
            self.reconnect();self.refresh()

    def test_new_gold_paid_active_rosters_fight_real_campaign_and_failed_save_is_atomic(self):
        original_simulate = battle.simulate
        for cid, gold in ((10829, 164004), (10839, 164038)):
            raw = protocol.pb_set_varint(self.put_hero(cid, advance=13, awake=90), 23, 30)
            for field, value in partner_growth.fairy(raw, self.config).items():
                raw = protocol.pb_set_varint(raw, field, value)
            raw = partner_growth.power(self.save, self.gen(self.iid), raw)
            player.record_slot_update(self.save, protocol.encode_pb_field(1, 2, raw))
            for stage in (14, 15, 16):
                self.paid(1017, [protocol.pb_get_varint(self.gen(self.iid), 1), 1, stage-1])
            self.success(1, 1003, raw=protocol.encode_pb_field(1, 0, 2)+protocol.encode_pb_field(3, 0, self.iid));self.refresh()
            self.save["role_state"]["stamina"] = 100
            reports = []
            def simulate(*args, **kwargs):
                report = original_simulate(*args, **kwargs)
                reports.append(report)
                return report
            with patch.object(battle, "simulate", side_effect=simulate):
                self.success(1, 1306, values=[42102, 1]);self.refresh()
            self.assertTrue(reports[0]["result"])
            test_hades_battle.HadesBattleTests.assert_replays(self, reports[0])
            self.assertEqual(reports[0]["meta"]["attack"]["g"][str(self.iid)]["c"], gold)
            self.assertEqual(self.save["role_state"]["stamina"], 100-self.config["copy"]["42102"]["1"]["physical"])
            before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
            with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
                self.request(1, 1306, values=[42102, 1])
            self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))
            self.reconnect();self.refresh()
            self.assertEqual(protocol.pb_get_varint(self.gen(self.iid), 1), gold)

    def test_actual_packaged_awakening_and_research_callbacks_use_server_bound_snapshots(self):
        self.put_hero(awake=0)
        for cid in (20278, 20017, 20661, 20662):
            self.grant(cid, 10000)
        lua = self.network_lua(native_protobuf=True)
        code = self.client_scripts()["assets/scripts/gamedata.so"].decode()
        start = code.index("function gamedata.isGeneralOn(")
        lua.execute(code[start:code.index("\nfunction ", start+1)].encode())
        lua.eval(b"require")(b"GameGeneralBreak")
        lua.globals().props_raw = bytes.fromhex(self.save["world_state"]["1200"])
        lua.execute(b'local t=require("idnums_pb").IdNums();t:ParseFromString(props_raw);gamedata:Props(t.idnums)')
        def view():
            hero = lua.globals().gamedata[b"cache"][b"generals"][self.iid]
            return lua.table_from({b"iid": self.iid, b"cid": hero[b"cid"], b"advance": hero[b"level2"], b"awake": hero[b"skilllevel"], b"soar": hero[b"level8"]})
        request = lua.table_from({b"iid": self.iid, b"partnerView": view()})
        mode, mid, raw = lua.globals().UIGeneralAwakenCallBack(request)
        self.assertEqual((mode, mid, protocol.parse_ids_pb(raw)), (1, 1025, [self.iid, 0]))
        coin = self.save["role_state"]["coin"]
        result = lua.globals().NetGeneralAwakenCallBack(lua.table_from({b"rbuf": self.success(1, mid, raw=raw), b"ser": 1}))
        self.refresh()
        self.assertEqual(result[b"general"][b"skilllevel"], 21)
        self.assertEqual(lua.globals().gamedata[b"cache"][b"role"][b"coin"], self.save["role_state"]["coin"])
        self.assertLess(self.save["role_state"]["coin"], coin)
        query = lua.table_from({b"iid": self.iid, b"partnerView": view()})
        _, mid, raw = lua.globals().UIGeneralXiuLianInfoCallBack(query)
        lua.globals().NetGeneralXiuLianInfoCallBack(lua.table_from({b"rbuf": self.success(1, mid, raw=raw), b"ser": 2}))
        request = lua.table_from({b"iid": self.iid, b"xiuLian": 1, b"isBreak": 0, b"partnerView": view()})
        mode, mid, raw = lua.globals().UIGeneralXiuLianCallBack(request)
        self.assertEqual((mode, mid), (1, 5513))
        result = lua.globals().NetGeneralXiuLianCallBack(lua.table_from({b"rbuf": self.success(1, mid, raw=raw), b"ser": 3}))
        self.refresh()
        self.assertEqual(result[b"generalXiuLian"][b"heart1"], partner_growth.research(self.save, self.iid, self.config)[4])
        self.assertEqual(lua.globals().gamedata[b"cache"][b"role"][b"coin"], self.save["role_state"]["coin"])
        # 升学走同一套打包回调：本档点数保留，客户端把点数与累计阶段属性一起显示，战力上涨。
        cap = self.config["Immortal_level"]["1"]["0"]["character"]
        state = self.save["partner_growth_state"]
        state["research"][str(self.iid)] = [0, cap, 0, 0, cap]+[0]*5
        _, mid, raw = lua.globals().UIGeneralXiuLianInfoCallBack(query)
        lua.globals().NetGeneralXiuLianInfoCallBack(lua.table_from({b"rbuf": self.success(1, mid, raw=raw), b"ser": 4}))
        request = lua.table_from({b"iid": self.iid, b"xiuLian": 1, b"isBreak": 1, b"partnerView": view()})
        mode, mid, raw = lua.globals().UIGeneralXiuLianCallBack(request)
        self.assertEqual((mode, mid, protocol.parse_ids_pb(raw)[:3]), (1, 5513, [self.iid, 1, 1]))
        before = protocol.pb_get_varint(self.gen(self.iid), 20)
        result = lua.globals().NetGeneralXiuLianCallBack(lua.table_from({b"rbuf": self.success(1, mid, raw=raw), b"ser": 5}))
        self.refresh()
        after = partner_growth.research(self.save, self.iid, self.config)
        self.assertEqual(after[:5], [1, cap, 0, 0, cap])
        self.assertEqual(result[b"generalXiuLian"][b"heart1"], cap)
        stats = partner_growth.research_stats(after, self.config)
        for key, name in ((b"attr1", "hp"), (b"attr2", "atk"), (b"attr3", "adddmg")):
            self.assertEqual(result[b"generalXiuLian"][key], stats[name])
        self.assertGreater(protocol.pb_get_varint(self.gen(self.iid), 20), before)
        self.assertEqual(lua.globals().gamedata[b"cache"][b"role"][b"coin"], self.save["role_state"]["coin"])
        # 升学后自动进修不再停下：下一笔按新档继续普通抽取，服务端照常接受并增长心性。
        request = lua.table_from({b"iid": self.iid, b"xiuLian": 1, b"isBreak": 0, b"partnerView": view()})
        mode, mid, raw = lua.globals().UIGeneralXiuLianCallBack(request)
        self.assertEqual((mode, mid, protocol.parse_ids_pb(raw)[:5]), (1, 5513, [self.iid, 1, 0, 1, cap]))
        before = protocol.pb_get_varint(self.gen(self.iid), 20)
        result = lua.globals().NetGeneralXiuLianCallBack(lua.table_from({b"rbuf": self.success(1, mid, raw=raw), b"ser": 6}))
        self.refresh()
        after = partner_growth.research(self.save, self.iid, self.config)
        self.assertEqual(after[0], 1)
        self.assertGreater(after[4], cap)
        self.assertEqual(result[b"generalXiuLian"][b"heart1"], after[4])
        self.assertGreater(protocol.pb_get_varint(self.gen(self.iid), 20), before)
        self.assertEqual(lua.globals().gamedata[b"cache"][b"role"][b"coin"], self.save["role_state"]["coin"])

    def test_actual_ui_context_rejects_closed_reopened_or_switched_partner(self):
        from lupa.lua51 import LuaRuntime
        lua = LuaRuntime(encoding=None)
        lua.execute(b'''UIRequest=function(req) sent=req end
            GameScene={layers={},addUpdate=function() end};gameWindows={windows={}}
            local page={data={general={iid=7,cid=10609,level2=10,skilllevel=40,level8=0}},
                selectpage="tupo",localPartnerGeneration=2,setTupoNext=function(self,t) applied=(applied or 0)+1 end}
            GameScene.layers.generalup={show=true,module=page}''')
        source = self.client_scripts()["assets/scripts/UIGenerals.so"]
        source = source[source.index(b"local operations={[1017]"):]
        lua.execute(source)
        lua.execute(b'UIRequest({type=1023,general=7});response={partnerView=sent.partnerView};UIGeneralBreakPreview(response)')
        self.assertEqual(lua.globals().applied, 1)
        for change in (b'GameScene.layers.generalup.show=false', b'GameScene.layers.generalup.show=true;GameScene.layers.generalup.module.localPartnerGeneration=3',
                       b'GameScene.layers.generalup.module.localPartnerGeneration=2;GameScene.layers.generalup.module.data.general.iid=8',
                       b'GameScene.layers.generalup.module.data.general.iid=7;GameScene.layers.generalup.module.data.general.level2=11'):
            lua.execute(change+b';UIGeneralBreakPreview(response)')
            self.assertEqual(lua.globals().applied, 1)

    def test_native_research_refresh_keeps_success_and_requeries_after_reentry(self):
        from lupa.lua51 import LuaRuntime
        code = self.client_scripts()["assets/scripts/Layer_generalup.so"].decode()
        for phase in (0, 1):
            with self.subTest(material_refresh=phase):
                lua = LuaRuntime()
                lua.globals().config = lua.table_from(self.config, recursive=True)
                lua.execute('''generalup={};gamedata={config=config};print=function() end
                    GameScene={checkUpdate=function() return false end,checkopenlevelbyId=function() return true end}
                    gameConfig={images={},strings={string_common=function() return "" end},checkBuildOpen=function() return true end}
                    guide={controller={addComplete=function() end}}
                    ui={setLabelString=function() end,getIDandNUMs=function() return {{cid=20661,num=10}} end}
                    setSpriteFrameByName=function() end
                    sent={};UIRequest=function(req) sent[#sent+1]=req end
                    local node=setmetatable({}, {__index=function() return function() end end})
                    local hero={iid=7,cid=10609,level1=300,level2=10,skilllevel=0,level6=0,level7=0}
                    snapshot={iid=7,heart1=10,heart2=0}
                    page=setmetatable({data={general=hero},generalsdata={['1']=hero},generalindex=1,
                        generalcid=10609,selectpage="xiulian",xiulianType=1,autoXiulian=true,
                        localPartnerGeneration=2,localPartnerTarget=7,xiuLianData={[7]=snapshot},
                        rootItems=setmetatable({}, {__index=function() return node end}),generalListTableView=node,
                        pagenodes={xiulian="xiuliannode"},setPageTitleOffset=function() end,touchLayerSet=function() end,
                        setXiuLianData=function(self) displayed=self.xiuLianData[7] end}, {__index=generalup})''')
                for name in ("ReloadData", "freshUI", "shiftPage", "setPage_xiulian", "getXiulianProp"):
                    start = code.index(f"function generalup.{name}(")
                    lua.execute(code[start:code.index("\nend", start)+len("\nend")])
                lua.globals().page.isRefreshXiulianProps = phase
                lua.execute('page:ReloadData();assert(page.xiuLianData[7]==snapshot);assert(displayed==snapshot)')
                self.assertTrue(lua.globals().page.autoXiulian)
                self.assertIsNone(lua.globals().page.isRefreshXiulianProps)
                self.assertEqual([req.type for req in lua.globals().sent.values()], [12001])
                lua.execute('''sent={};page.isRefreshXiulianProps=1;page.xiuLianHave={}
                    page:shiftPage("xiulian")
                    assert(page.xiuLianData[7]==nil and page.xiuLianHave==nil)
                    assert(page.isRefreshXiulianProps==nil and not page.autoXiulian)''')
                self.assertEqual([req.type for req in lua.globals().sent.values()], [5511, 5512])
                lua.execute('''sent={};page.xiuLianData={[7]=snapshot,[8]={iid=8}}
                    page.generalsdata['1'].iid=8;page.isRefreshXiulianProps=1;page.xiuLianHave={}
                    page:freshUI()
                    assert(page.xiuLianData[7]==snapshot and page.xiuLianData[8]==nil)
                    assert(page.isRefreshXiulianProps==nil and page.xiuLianHave==nil)''')
                self.assertEqual([req.type for req in lua.globals().sent.values()], [5511, 5512])

    def test_native_research_material_timers_ignore_closed_or_switched_pages(self):
        code = self.client_scripts()["assets/scripts/Layer_generalup.so"].decode()
        start = code.index("function generalup.setXiuLianPropShow(")
        block = code[start:code.index("\nend", start)+len("\nend")]
        # 材料回显不再自建定时器，统一交给带世代/iid/auto 守卫的 autoResearchKick。
        self.assertIn("self:autoResearchKick()", block)
        self.assertNotIn("CCCallFunc:create", block)
        for change in ("page.localPartnerGeneration=4;page.data=nil",
                       "page.data.general.iid=8",
                       "page.autoXiulian=false",
                       'page.selectpage="tupo"'):
            with self.subTest(change=change):
                lua = self._research_lua(code)
                lua.execute("page.autoXiulian=true;page:setXiuLianPropShow({['1000']=999999})")
                lua.execute(change)
                lua.execute('''
                    for i=1,5 do
                      if #timers==0 then break end
                      table.sort(timers,function(a,b) return a.at<b.at end)
                      local t=table.remove(timers,1); clock=t.at; t.fn()
                    end
                    n5513=0;for _,r in ipairs(requests) do if r.type==5513 then n5513=n5513+1 end end
                ''')
                self.assertEqual(int(lua.globals().n5513), 0, change)

    def _research_lua(self, code, **settings):
        from lupa.lua51 import LuaRuntime
        lua = LuaRuntime()
        lua.execute(AUTO_RESEARCH_LUA)
        for name in ("executeXiulian", "setXiuLianStateShow", "getXiulianProp",
                     "setXiuLianPropShow", "xiuLianSuccess", "autoResearchKick",
                     "getXiuLianData"):
            start = code.index("function generalup.%s(" % name)
            lua.execute(code[start:code.index("\nend", start)+len("\nend")])
        for key, value in settings.items():
            lua.globals()[key] = value
        return lua

    @staticmethod
    def _pump_research(lua, steps=300):
        lua.execute('''
            page:executeXiulian()
            for i=1,%d do
              if #timers==0 then break end
              table.sort(timers,function(a,b) return a.at<b.at end)
              local t=table.remove(timers,1); clock=t.at; t.fn()
            end
            n5513=0;n12001=0
            for _,r in ipairs(requests) do
              if r.type==5513 then n5513=n5513+1 elseif r.type==12001 then n12001=n12001+1 end
            end
        ''' % steps)

    def test_native_auto_research_continues_through_level_up(self):
        from lupa.lua51 import LuaRuntime
        code = self.client_scripts()["assets/scripts/Layer_generalup.so"].decode()
        self.assertNotIn("(not self.levelUp)", code)
        self.assertIn("function generalup.autoResearchKick(self)", code)
        self.assertIn("localPartnerGrowthBusy", code)
        self.assertIn("    self:setXiuLianStateShow()\n    self:autoResearchKick()", code)
        # 在途锁超时自愈：只清本模块 pending，重查 5511/5512 后由回显解除门禁。
        self.assertIn("localAutoResearchWaits", code)
        self.assertIn("localAutoResearchResync", code)
        self.assertIn("UIRequest({type=5512,iid=iid})", code)
        start = code.index("function generalup.getXiuLianData(")
        self.assertIn("self:autoResearchKick()", code[start:code.index("\nend", start)])
        # 新函数必须插在顶层 return 之前，否则整个脚本编译失败。
        self.assertLess(code.index("function generalup.autoResearchKick"), code.index("\nreturn generalup"))
        LuaRuntime().compile(code)
        # 旧实现只要 12001 材料回显丢一次就永久停住（autoXiulian 仍为真、无定时器）；
        # 5513 慢回显还会在上一笔未回时并发再发一笔。以下场景都必须连续升学且不冲突。
        for label, settings, minimum in (
            ("正常连续升学", {}, 90),
            ("偶发丢失一次材料回显", {"dropLeft": 1}, 90),
            ("周期性丢失材料回显", {"dropEvery": 3}, 90),
            ("5513 慢回显", {"netdelay": 0.35}, 60),
            ("慢回显叠加周期丢失", {"netdelay": 0.35, "dropEvery": 3}, 60),
        ):
            with self.subTest(label):
                lua = self._research_lua(code, **settings)
                self._pump_research(lua)
                g = lua.globals()
                self.assertGreaterEqual(int(g.n5513), minimum, label)
                self.assertEqual(int(g.conflicting), 0, label)
                self.assertTrue(bool(g.page.autoXiulian), label)
                self.assertGreater(int(g.level), 5, label)
                self.assertGreater(int(lua.eval('#timers')), 0, label)

    def test_native_auto_research_recovers_when_5513_reply_is_lost(self):
        # 5513 整包丢失（既没有成功回包也没有错误回包）时，网络层的 busy 锁残留；
        # 旧续接器把两者都当作「5513 在途」无限排队，auto 仍为真却再也不发请求。
        code = self.client_scripts()["assets/scripts/Layer_generalup.so"].decode()
        for label, settings, minimum in (
            ("偶发丢失一次 5513 回包", {"lostEvery": 25}, 60),
            ("频繁丢失 5513 回包", {"lostEvery": 7}, 40),
            ("慢回显叠加丢包", {"netdelay": 0.35, "lostEvery": 25}, 40),
        ):
            with self.subTest(label):
                lua = self._research_lua(code, **settings)
                self._pump_research(lua)
                g = lua.globals()
                self.assertGreater(int(g.lostCount), 0, label)
                self.assertGreater(int(g.resyncs), 0, label)
                self.assertGreaterEqual(int(g.n5513), minimum, label)
                self.assertEqual(int(g.conflicting), 0, label)
                self.assertTrue(bool(g.page.autoXiulian), label)
                self.assertGreater(int(g.level), 5, label)
                self.assertGreater(int(lua.eval('#timers')), 0, label)

    def test_lost_5513_is_never_followed_by_a_stale_retry(self):
        # 结果未知的 5513 不能补发：丢包后的下一笔进修之前必须先有 5512 重查，
        # 让服务端真实进度/序号回灌，避免重复扣费或旧序号被拒后停住。
        code = self.client_scripts()["assets/scripts/Layer_generalup.so"].decode()
        lua = self._research_lua(code, lostEvery=7)
        self._pump_research(lua, steps=160)
        lua.execute('''
            seen=0;bad=0;waiting=false;resynced=0
            for _,r in ipairs(requests) do
              if r.type==5513 then
                seen=seen+1
                if seen%7==0 then waiting=true
                elseif waiting then
                  if resynced==0 then bad=bad+1 end
                  waiting=false;resynced=0
                end
              elseif r.type==5512 then resynced=resynced+1
              end
            end
        ''')
        g = lua.globals()
        self.assertGreater(int(g.seen), 21)
        self.assertEqual(int(g.bad), 0)
        self.assertEqual(int(g.conflicting), 0)
        self.assertTrue(bool(g.page.autoXiulian))

    def test_auto_research_busy_timeout_resyncs_only_own_pending(self):
        code = self.client_scripts()["assets/scripts/Layer_generalup.so"].decode()
        lua = self._research_lua(code)
        lua.execute('''
            local p={opcode=5513,iid=7}
            gamedata.ext.localPartnerGrowthBusy=p;gamedata.ext.localFormationBusy=p
            page.autoXiulian=true;page:autoResearchKick()
            for i=1,25 do
              if #timers==0 then break end
              table.sort(timers,function(a,b) return a.at<b.at end)
              local t=table.remove(timers,1);clock=t.at;t.fn()
            end
            cleared=gamedata.ext.localPartnerGrowthBusy==nil and gamedata.ext.localFormationBusy==nil
            n5511=0;n5512=0
            for _,r in ipairs(requests) do
              if r.type==5511 then n5511=n5511+1 elseif r.type==5512 then n5512=n5512+1 end
            end
        ''')
        g = lua.globals()
        self.assertTrue(bool(g.cleared))          # 只清本模块自己设置的同一把锁
        self.assertGreater(int(g.n5511), 0)       # 重查等级
        self.assertGreater(int(g.n5512), 0)       # 重查真实进度与序号后才继续
        self.assertEqual(int(g.conflicting), 0)
        self.assertTrue(bool(g.page.autoXiulian))

    def test_auto_research_never_clears_another_modules_lock(self):
        code = self.client_scripts()["assets/scripts/Layer_generalup.so"].decode()
        lua = self._research_lua(code)
        lua.execute('''
            local other={opcode=1017}
            gamedata.ext.localFormationBusy=other
            page.autoXiulian=true;page:autoResearchKick()
            for i=1,25 do
              if #timers==0 then break end
              table.sort(timers,function(a,b) return a.at<b.at end)
              local t=table.remove(timers,1);clock=t.at;t.fn()
            end
            kept=gamedata.ext.localFormationBusy==other
            stopped=not page.autoXiulian
            n5513=0;for _,r in ipairs(requests) do if r.type==5513 then n5513=n5513+1 end end
        ''')
        g = lua.globals()
        self.assertTrue(bool(g.kept))     # 别人的在途锁不能动
        self.assertTrue(bool(g.stopped))  # 但也不能永远显示「取消」空转
        self.assertEqual(int(g.n5513), 0)

    def test_auto_research_kick_stops_when_cancelled_or_generation_changes(self):
        code = self.client_scripts()["assets/scripts/Layer_generalup.so"].decode()
        for label, mutation in (
            ("手动取消", "page.autoXiulian=false"),
            ("切换世代", "page.localPartnerGeneration=page.localPartnerGeneration+1"),
            ("切换页面", 'page.selectpage="tupo"'),
        ):
            with self.subTest(label):
                lua = self._research_lua(code)
                lua.execute("page.autoXiulian=true;page:autoResearchKick()")
                lua.execute(mutation)
                lua.execute('''
                    for i=1,5 do
                      if #timers==0 then break end
                      table.sort(timers,function(a,b) return a.at<b.at end)
                      local t=table.remove(timers,1); clock=t.at; t.fn()
                    end
                    n5513=0;for _,r in ipairs(requests) do if r.type==5513 then n5513=n5513+1 end end
                ''')
                self.assertEqual(int(lua.globals().n5513), 0, label)

    def test_native_soaring_animation_completion_never_touches_closed_generation(self):
        from lupa.lua51 import LuaRuntime
        lua = LuaRuntime(encoding=None)
        code = self.client_scripts()["assets/scripts/Layer_generalup.so"]
        start = code.index(b"function generalup.feiShengCallback(")
        end = code.index(b"\nend", start)+len(b"\nend")
        lua.execute(b'''generalup={};print=function() end
            getAnimationManager=function() return {setAnimationCompletedCallback=function(self,fn) delayed=fn end,
                runAnimationsForSequenceNamed=function() end} end
            page={data={general={iid=7}},localPartnerGeneration=3,feishengEffectItems={[1]={{items={}},{items={}}}},
                ReloadData=function() applied=(applied or 0)+1 end}
            gamedata={config={partner_soaring={['2']={}}}}''')
        lua.execute(code[start:end])
        lua.execute(b'generalup.feiShengCallback(page,{level8=1});page.localPartnerGeneration=4;page.data=nil;delayed()')
        self.assertIsNone(lua.globals().applied)

    def test_unknown_battle_dependencies_time_rollback_and_overflow_never_charge(self):
        self.put_hero(awake=90)
        self.config["general"]["10831"]["break11"] = 9001196
        self.config["breakskill"]["9001196"]["type_param"] = 1234567
        self.assert_rejected(1017, values=[10609, 0, 10])
        self.save["partner_growth_state"] = {"research": {}, "serial": 0, "checked_at": self.now+1}
        self.assert_rejected(1025, values=[self.iid, 90])
        self.save["partner_growth_state"]["checked_at"] = self.now
        self.save["partner_growth_state"]["serial"] = (1 << 31)-1
        self.assert_rejected(5513, values=[self.iid, 1, 0, 0, 0, (1 << 31)-1])

    def test_active_conversion_and_soaring_keep_real_stats_power_equipment_and_battle_projection(self):
        self.success(1, 1003, raw=protocol.encode_pb_field(1, 0, 2)+protocol.encode_pb_field(3, 0, self.iid));self.refresh()
        before, old = copy.deepcopy(self.save), self.gen(self.iid)
        self.paid(1017, [10609, 0, 10])
        changed = self.gen(self.iid)
        self.assertEqual(self.save["role_state"]["power"]-before["role_state"]["power"], protocol.pb_get_varint(changed, 20)-protocol.pb_get_varint(old, 20))
        self.assertEqual(formation.records(bytes.fromhex(self.save["world_state"]["1002"]), 4, 2)[self.iid], formation.records(bytes.fromhex(before["world_state"]["1002"]), 4, 2)[self.iid])
        self.save["partner_growth_state"]["research"][str(self.iid)] = [1, 0, 0, 0, 0]*2
        before = copy.deepcopy(self.save)
        self.paid(7001, [self.iid, 0])
        changed = self.gen(self.iid)
        self.assertEqual(self.save["role_state"]["g_power"]-before["role_state"]["g_power"], protocol.pb_get_varint(changed, 34))
        attack, _ = battle.rosters(self.save, self.config["copy"]["42101"]["1"], self.config)
        unit = next(u for u in attack.values() if u["iid"] == self.iid)
        self.assertEqual(unit["atk"], protocol.pb_get_varint(changed, 6)+protocol.pb_get_varint(changed, 26)//10)
        self.assertEqual((unit["skilllevel"], unit["awakening"]), (0, 40))

    def test_failed_advanced_breakthrough_never_leaks_costs_template_or_new_state(self):
        raw = b"".join(protocol.encode_pb_field(1, 0, v) for v in (10609, 0, 10))
        _, costs, _ = development.prepare(1017, copy.deepcopy(self.save), raw, self.config)
        for cid, count in costs:
            if cid != 1000:
                player.change_item_count(self.save, cid, count, self.config, self.now)
        before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 1017, raw=raw)
        self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))

    def test_complete_cost_receipt_refunds_actual_growth_and_keeps_unknown_fields(self):
        baseline = recruit.new_general(10609, self.iid, self.config)+protocol.encode_pb_field(50, 2, b"preserve-partner")
        self.save["qiankun_state"]["receipts"][f"general:{self.iid}"] = {"before": baseline.hex(), "after": self.gen(self.iid).hex(), "costs": [[20017, 100]]}
        self.paid(1025, [self.iid, 40])
        self.paid(1017, [10609, 0, 10])
        receipt = self.save["qiankun_state"]["receipts"][f"general:{self.iid}"]
        before_coin = self.save["role_state"]["coin"]
        refunded_coin = dict(receipt["costs"])[1000]
        result = self.success(1, 1035, values=[self.iid]);self.refresh()
        self.assertEqual(self.gen(self.iid), baseline)
        self.assertEqual(self.save["role_state"]["coin"], before_coin+refunded_coin)
        self.assertNotIn(f"general:{self.iid}", self.save["qiankun_state"]["receipts"])
        self.assertIn(self.iid, formation.records(result, 8, 2))

    def test_research_rebirth_invalidates_old_serial_and_publishes_zero_levels(self):
        baseline = recruit.new_general(10609, self.iid, self.config)
        self.save["qiankun_state"]["receipts"][f"general:{self.iid}"] = {"before": baseline.hex(), "after": self.gen(self.iid).hex(), "costs": [[20017, 100]]}
        self.paid(5513, [self.iid, 1, 0, 0, 0, 0])
        before = self.save["partner_growth_state"]["serial"]
        packets = self.request(1, 1035, values=[self.iid]);self.refresh()
        self.assertEqual(packets[0][0], 1035, packets)
        self.assertEqual(self.save["partner_growth_state"]["serial"], before+1)
        self.assertNotIn(str(self.iid), self.save["partner_growth_state"]["research"])
        levels = protocol.parse_ids_pb(next(raw for mid, raw in packets if mid == 5511))
        index = levels.index(self.iid)
        self.assertEqual(levels[index:index+3], [self.iid, 0, 0])

    def test_client_roster_updates_keep_research_until_actual_rebirth(self):
        lua = self.network_lua(native_protobuf=True)
        lua.eval(b"require")(b"GameGeneralBreak")
        raw = self.gen(self.iid)
        query = lua.table_from({b"iid": self.iid})
        lua.globals().UIGeneralXiuLianInfoCallBack(query)
        detail = b"".join(protocol.encode_pb_field(1, 0, v) for v in [1, 0, 0, 0, 0]*2+[4])
        lua.globals().NetGeneralXiuLianInfoCallBack(lua.table_from({b"rbuf": detail, b"ser": 1}))
        def apply(general):
            lua.globals().raw_general = protocol.encode_pb_field(1, 2, general)
            lua.execute(b'local p=require("generals_pb").Generals();p:ParseFromString(raw_general);gamedata:Generals(p.generals)')
        apply(raw)
        self.assertEqual(lua.globals().gamedata[b"cache"][b"generals"][self.iid][b"level6"], 1)
        apply(recruit.new_general(10609, self.iid, self.config))
        hero = lua.globals().gamedata[b"cache"][b"generals"][self.iid]
        self.assertEqual((hero[b"level6"], hero[b"level7"]), (0, 0))


class PartnerBattleTests(unittest.TestCase):
    unit = test_hades_battle.HadesBattleTests.unit
    hits = test_hades_battle.HadesBattleTests.hits
    assert_replays = test_hades_battle.HadesBattleTests.assert_replays

    @classmethod
    def setUpClass(cls):
        cls.config = player.load_role_config("configs_sec5.zip")

    def isolated(self):
        row = {**self.config["general"]["164036"], **{f"break{i}": 0 for i in range(1, 17)}}
        return {**self.config, "general": {**self.config["general"], "164036": row}}

    def gold(self, pid, **values):
        return self.unit(164036, iid=700, advance=16, partner_skills=[pid], **values)

    def test_chan_kill_adds_next_attack_damage_and_team_ap_without_repeating_old_bonus(self):
        report = battle.simulate({2: self.gold(9001196, speed=300), 8: self.unit(10610, iid=701, speed=500, atk=1000)},
                                 {2: self.unit(iid=1, hp=50, speed=1, atk=1), 8: self.unit(iid=2, speed=1, atk=1)}, self.isolated(), 7, max_rounds=2)
        self.assertEqual(self.hits(report)[:2], [200, 100])
        self.assert_replays(report)

    def test_four_enemy_damage_threshold_and_five_enemy_personal_skill_targets(self):
        report = battle.simulate({2: self.gold(9001197, speed=300)}, {2: self.unit(iid=1, atk=1)}, self.isolated(), 7, max_rounds=1)
        self.assertEqual(self.hits(report)[0], 160)
        report = battle.simulate({2: self.gold(9001197, speed=300, initial_ap=4)},
                                 {p: self.unit(iid=i+1, atk=1) for i, p in enumerate(battle.POSITIONS[:5])}, self.isolated(), 7, max_rounds=1)
        cast = next(a for a in report["b"]["a"] if a["s"].get("S") == 180063)
        self.assertEqual(len([d for d in cast["e"] if not d["r"] and isinstance(d.get("m"), dict)]), 5)
        self.assert_replays(report)

    def test_two_round_aid_keeps_combo_ownership_and_ap_gates(self):
        config = self.isolated()
        config["combskillprobability"] = copy.deepcopy(config["combskillprobability"])
        config["combskillprobability"]["12988"]["bout1"] = 0
        report = battle.simulate({2: self.gold(9001198, speed=1), 8: self.unit(10610, iid=701, speed=100, initial_ap=4), 10: self.unit(10608, iid=702, speed=1)},
                                 {8: self.unit(iid=1, speed=100, hp=1000000, atk=1)}, config, 7, max_rounds=1)
        action = next(a for a in report["b"]["a"] if a["s"] and a["s"]["t"] in ("N", "k", "x"))
        self.assertEqual((action["s"].get("S"), action["s"]["p"]), (12988, [8, 10, 2]))
        self.assert_replays(report)

    def test_even_round_ap_can_enable_personal_cast_without_legacy_awakening_scaling(self):
        report = battle.simulate({2: self.gold(9001199, speed=300)},
                                 {8: self.unit(iid=1, hp=1000000, atk=1)}, self.isolated(), 7, max_rounds=2)
        actions = [a["s"]["t"] for a in report["b"]["a"] if a["s"].get("r") and a["s"]["t"] in ("N", "k", "x")]
        self.assertEqual(actions, ["N", "k"])
        self.assert_replays(report)

    def test_unpurgeable_qi_blocks_basic_ap_and_spreads_to_another_enemy(self):
        report = battle.simulate({2: self.gold(9001200, speed=300)},
                                 {2: self.unit(iid=1, hp=1000000, atk=1), 8: self.unit(iid=2, hp=1000000, atk=1)}, self.isolated(), 7, max_rounds=2)
        self.assertEqual([report["endmeta"]["defense"][str(p)]["ap"] for p in (2, 8)], [0, 2])
        self.assert_replays(report)

    def revival_report(self, rounds=1):
        team = {p: self.unit(iid=700+i, hp=10000, atk=1, speed=1) for i, p in enumerate(battle.POSITIONS[:5])}
        team[2] = self.gold(9001201, hp=100, atk=1, speed=1, cover_d=100, cover_p=100, cover_l=1)
        return battle.simulate(team, {2: self.unit(iid=1, hp=1000000, atk=1000, speed=500)}, self.isolated(), 7, max_rounds=rounds)

    def test_gold_revival_requires_four_living_allies_restores_cover_and_is_once(self):
        report = self.revival_report()
        self.assertEqual((report["endmeta"]["attack"]["2"]["h"], report["endmeta"]["attack"]["2"]["cover_d"]), (100, 65))
        self.assert_replays(report)
        self.assertEqual(self.revival_report(2)["endmeta"]["attack"]["2"]["h"], 0)

    def test_actual_gold_and_revival_reports_convert_original_apk_animation_assets(self):
        self.assert_native_reports((self.revival_report(), battle.simulate({2: self.gold(9001200, speed=300)},
                {2: self.unit(iid=1, hp=1000000, atk=1), 8: self.unit(iid=2, hp=1000000, atk=1)}, self.isolated(), 7, max_rounds=2)))

    def assert_native_reports(self, reports):
        from lupa.lua51 import LuaRuntime
        lua = LuaRuntime()
        config = dict(self.config)
        with zipfile.ZipFile("configs_sec5.zip") as archive:
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
            def load(path):
                if path not in assets:
                    assets[path] = json.loads(archive.read(next(n for n in names if n.endswith("/"+path))))
                return lua.table_from(assets[path], recursive=True)
            lua.globals().LoadJsonFileToTable = load
            lua.execute(PartnerGrowthTests.client_scripts()["assets/scripts/battleReportConvert.so"])
            lua.execute(builder.read_script("BattleReportAbbToKey"))
            for report in reports:
                native = lua.table_from(json.loads(lua.globals().ReplaceAbbToKey(json.dumps(report))), recursive=True)
                attack, defense = lua.globals().getBattleInitSlotInfo(native)
                animations, ext = lua.globals().convertBattleReportToAnimationSub(native, attack, defense, None, "penglai")
                self.assertGreater(len(animations), 1)
                for side, key in (("attack", "atk"), ("defense", "def")):
                    for pos, unit in report["endmeta"][side].items():
                        self.assertEqual((ext.endinfo[key][pos].hp, ext.endinfo[key][pos].ap), (unit["h"], unit["ap"]))


class GuangchengziBattleTests(unittest.TestCase):
    """广成子彩金六技能：平息/进击/磁场/过热/无限光波/能量防护。"""
    unit = test_hades_battle.HadesBattleTests.unit
    hits = test_hades_battle.HadesBattleTests.hits
    assert_replays = test_hades_battle.HadesBattleTests.assert_replays

    @classmethod
    def setUpClass(cls):
        cls.config = player.load_role_config("configs_sec5.zip")

    def isolated(self, *patches):
        row = {**self.config["general"]["164027"], **{f"break{i}": 0 for i in range(1, 17)}}
        skills = dict(self.config["breakskill"])
        for sid, values in patches:
            skills[str(sid)] = {**skills[str(sid)], **values}
        return {**self.config, "general": {**self.config["general"], "164027": row}, "breakskill": skills}

    def gold(self, pid=None, **values):
        return self.unit(164027, iid=700, advance=16, partner_skills=[pid] if pid else [], **values)

    def aps(self, report, direct=True):
        return [d["ap"] for a in report["b"]["a"]
                if a["s"].get("r") == direct and a["s"].get("t") in ("N", "k", "x")
                for d in a["e"] if d["r"] != direct and "ap" in d]

    def test_all_six_gold_skills_pass_combat_preparation_and_replay(self):
        for pid in range(9001142, 9001148):
            with self.subTest(pid=pid):
                report = battle.simulate({2: self.gold(pid, speed=300, initial_ap=4)},
                                         {2: self.unit(iid=1, hp=1000000, atk=1)},
                                         self.isolated(), 7, max_rounds=2)
                self.assertTrue(report["b"]["a"])
                self.assert_replays(report)

    def test_extra_basic_target_is_probabilistic_and_bounded_by_value2(self):
        defense = {2: self.unit(iid=1, hp=1000000, atk=1), 8: self.unit(iid=2, hp=1000000, atk=1)}
        for chance, count in ((1, 2), (0, 1)):
            with self.subTest(chance=chance):
                report = battle.simulate({2: self.gold(9001143, speed=300)}, defense,
                                         self.isolated((9001143, {"value": chance})), 7, max_rounds=1)
                self.assertEqual(len(self.hits(report)), count)
                self.assert_replays(report)

    def test_ap_skill_extra_drain_uses_value2_and_is_probabilistic(self):
        defense = {2: self.unit(iid=1, hp=1000000, atk=1, initial_ap=4)}
        for chance, expected in ((1, True), (0, False)):
            with self.subTest(chance=chance):
                report = battle.simulate({2: self.gold(9001142, speed=300, initial_ap=4)}, defense,
                                         self.isolated((9001142, {"value": chance})), 7, max_rounds=1)
                self.assertEqual(1 in self.aps(report), expected)
                self.assert_replays(report)

    def test_ap_drain_triggers_magnetic_field_and_overheat_once(self):
        defense = {2: self.unit(iid=1, hp=1000000, atk=100, speed=1, initial_ap=4)}
        def fight(pid=None):
            # 技能必须实际造成伤害才会走命中后的降怒逻辑；atk=1 会被 0 伤害整块跳过。
            return battle.simulate({2: self.gold(pid, speed=300, initial_ap=4, atk=100, hp=10000)},
                                   defense, self.isolated(), 7, max_rounds=1)
        plain, magnet, heat = fight(), fight(9001144), fight(9001145)
        # 磁场：目标被降怒后攻击降低，广成子承伤更少。
        self.assertGreater(magnet["endmeta"]["attack"]["2"]["h"], plain["endmeta"]["attack"]["2"]["h"])
        # 过热：广成子生命上限 10000 × 实际降怒 1 × 0.1 = 1000 额外伤害。
        self.assertEqual(plain["endmeta"]["defense"]["2"]["h"] - heat["endmeta"]["defense"]["2"]["h"], 1000)
        for report in (plain, magnet, heat):
            self.assert_replays(report)

    def test_aura_skills_add_hp_only_to_gold_allies(self):
        for pid in (9001146, 9001147):
            with self.subTest(pid=pid):
                config = self.isolated((pid, {"value": 0}))
                attack = {2: self.gold(pid, speed=300),
                          8: self.unit(164027, iid=701, hp=10000, speed=1),
                          10: self.unit(10201, iid=702, hp=10000, speed=1)}
                report = battle.simulate(attack, {2: self.unit(iid=1, hp=1000000, atk=1)}, config, 7, max_rounds=1)
                meta = report["meta"]["attack"]["g"]
                self.assertEqual((meta["700"]["h"], meta["701"]["h"], meta["702"]["h"]),
                                 (10000 + 240000, 10000 + 240000, 10000))
                self.assert_replays(report)

    def test_curse_mark_raises_damage_taken_and_weakens_target(self):
        config = self.isolated((9001146, {"value": 1}))
        attack = {2: self.gold(9001146, speed=300, initial_ap=4, atk=100, hp=1000000)}
        defense = {2: self.unit(iid=1, hp=1000000, atk=100, speed=1)}
        # 同一随机序列：只把三项印记比例置零作为对照，roll 仍然发生。
        with patch.multiple(battle, CURSE_DAMAGE=0, CURSE_ATTACK=0, CURSE_DEFENSE=0):
            plain = battle.simulate(copy.deepcopy(attack), copy.deepcopy(defense), config, 7, max_rounds=2)
        cursed = battle.simulate(copy.deepcopy(attack), copy.deepcopy(defense), config, 7, max_rounds=2)
        self.assertGreater(self.hits(cursed)[-1], self.hits(plain)[-1])
        self.assertGreater(cursed["endmeta"]["attack"]["2"]["h"], plain["endmeta"]["attack"]["2"]["h"])
        self.assert_replays(cursed)
        self.assert_replays(plain)

    def test_guard_mark_blocks_exactly_one_attack(self):
        defense = {2: self.unit(iid=1, hp=1000000, atk=100, speed=1)}
        config = self.isolated((9001147, {"value": 1}))
        def fight(actor, rounds):
            return battle.simulate({2: actor}, defense, config, 7, max_rounds=rounds)
        guarded = fight(self.gold(9001147, speed=300, initial_ap=4, atk=1), 1)
        plain = fight(self.gold(None, speed=300, initial_ap=4, atk=1), 1)
        lost = lambda report: report["meta"]["attack"]["g"]["700"]["h"] - report["endmeta"]["attack"]["2"]["h"]
        self.assertEqual(lost(guarded), 0)
        self.assertGreater(lost(plain), 0)
        self.assertTrue(any(d.get("m", {}).get("u") == "proof" for a in guarded["b"]["a"]
                            for d in a["e"] if isinstance(d.get("m"), dict)))
        # 一层印记只挡一次：第二回合不再释放技能，普通攻击应当生效。
        self.assertGreater(lost(fight(self.gold(9001147, speed=300, initial_ap=4, atk=1), 2)), 0)
        self.assert_replays(guarded)
        self.assert_replays(plain)


class YuanshiTongtianBattleTests(unittest.TestCase):
    unit = test_hades_battle.HadesBattleTests.unit
    hits = test_hades_battle.HadesBattleTests.hits
    assert_replays = test_hades_battle.HadesBattleTests.assert_replays
    assert_native_reports = PartnerBattleTests.assert_native_reports
    setUpClass = classmethod(PartnerBattleTests.setUpClass.__func__)

    def isolated(self, *extra):
        config = {**self.config, "general": {**self.config["general"]}}
        for cid in (164004, 164038):
            config["general"][str(cid)] = {**self.config["general"][str(cid)], **{f"break{i}": 0 for i in range(1, 17)}}
        if extra:
            config["general"]["164004"]["break1"] = extra[0]
        return config

    def gold(self, cid, *pids, **values):
        return self.unit(cid, **{"iid": 700, "advance": 16, "partner_skills": list(pids), **values})

    def test_photon_mark_doubles_only_owners_target_and_moves_only_on_own_kill(self):
        for ally_kill, expected in ((False, [50, 200]), (True, [100, 100])):
            attack = {2: self.gold(164004, 9001034, speed=300)}
            if ally_kill:
                attack[8] = self.unit(iid=701, speed=400)
            report = battle.simulate(attack, {2: self.unit(iid=1, hp=50, atk=1, speed=1),
                                             8: self.unit(iid=2, atk=1, speed=1)}, self.isolated(), 7, max_rounds=2)
            self.assertEqual(self.hits(report), expected)
            self.assert_replays(report)
        report = battle.simulate({8: self.gold(164004, 9001034, speed=300)}, {2: self.unit(iid=1, atk=1)}, self.isolated(), 7, max_rounds=1)
        self.assertEqual(self.hits(report, pos=8), [100])

    def test_enemy_deaths_restore_ap_and_add_damage_but_immediate_revival_does_not(self):
        config = self.isolated()
        report = battle.simulate({2: self.gold(164004, 9001035, speed=300)},
                                 {2: self.unit(iid=1, hp=50, atk=1, speed=1), 8: self.unit(iid=2, atk=1, speed=1)}, config, 7, max_rounds=2)
        self.assertEqual(self.hits(report), [50, 105])
        self.assertEqual(report["endmeta"]["attack"]["2"]["ap"], 5)
        self.assert_replays(report)
        config["general"]["10305"] = {**config["general"]["10305"], "break1": 9000376}
        report = battle.simulate({2: self.gold(164004, 9001035, speed=300)},
                                 {2: self.unit(10305, iid=1, advance=1, hp=50, atk=1, speed=1)}, config, 7, max_rounds=1)
        self.assertEqual(report["endmeta"]["attack"]["2"]["ap"], 2)
        self.assert_replays(report)

    def test_revived_enemy_self_explosion_does_not_reuse_an_old_killer_for_mark_transfer(self):
        config = self.isolated()
        config["general"]["10823"] = {**config["general"]["10823"], "break1": config["general"]["10821"]["break1"]}
        report = battle.simulate({2: self.gold(164004, 9001034, speed=300)},
                                 {2: self.unit(10823, iid=1, npc=True, advance=1, hp=50, atk=1, speed=500),
                                  8: self.unit(iid=2, atk=1, speed=1)}, config, 7, max_rounds=2)
        self.assertEqual(self.hits(report), [25, 100])
        self.assert_replays(report)

    def test_battery_adds_initial_ap_and_damage_for_first_round_only(self):
        report = battle.simulate({2: self.gold(164004, 9001036, speed=300)}, {2: self.unit(iid=1, hp=1000000, atk=1)}, self.isolated(), 7, max_rounds=2)
        self.assertEqual(report["meta"]["attack"]["g"]["700"]["ap"], 2)
        self.assertEqual(self.hits(report)[0], 115)
        cast = next(a for a in report["b"]["a"] if a["s"].get("S") == 180029)
        self.assertEqual(next(d["m"]["m"] for d in cast["e"] if not d["r"] and isinstance(d.get("m"), dict)), 81)
        self.assert_replays(report)

    def test_chan_aura_is_team_scoped_and_same_family_does_not_stack(self):
        attack = {2: self.gold(164004, 9001037, speed=300), 8: self.gold(164004, 9001037, iid=701, speed=200),
                  10: self.unit(iid=702, speed=100)}
        report = battle.simulate(attack, {2: self.unit(iid=1, atk=100, speed=400)}, self.isolated(), 7, max_rounds=1)
        self.assertEqual(self.hits(report), [110])
        self.assertEqual(self.hits(report, pos=8), [110])
        self.assertEqual(self.hits(report, pos=10), [100])
        self.assertEqual(self.hits(report, False), [85])
        self.assert_replays(report)

    def test_last_stand_extension_blocks_damage_and_healing_through_next_round_only(self):
        config = self.isolated(9000379)
        report = battle.simulate({2: self.gold(164004, 9001038, atk=1, hp=100, speed=1),
                                 8: self.unit(10610, iid=701, initial_ap=4, speed=200)},
                                {2: self.unit(iid=1, atk=1000, hp=10**9, speed=500)}, config, 7, max_rounds=3)
        self.assertEqual(self.hits(report, False)[:2], [99, 0])
        heals = [d["m"]["m"] for a in report["b"]["a"] if a["s"].get("S") == self.config["general"]["10610"]["skillid"]
                 for d in a["e"] if d["r"] and d["p"] == 2 and isinstance(d.get("m"), dict)]
        self.assertEqual(heals, [0])
        self.assertEqual(report["endmeta"]["attack"]["2"]["h"], 0)
        self.assert_replays(report)

    def test_round_matrix_blocks_control_and_nonpet_ap_loss_but_not_pet(self):
        config = self.isolated()
        config["breakskill"] = {**config["breakskill"], "9001039": {**config["breakskill"]["9001039"], "value": 1}}
        config["general"]["10201"] = {**config["general"]["10201"], "break1": 9100002, "break2": 9000370}
        with patch.object(battle.random.Random, "random", return_value=0):
            report = battle.simulate({2: self.unit(advance=2, speed=300)},
                                     {2: self.gold(164004, 9001039, iid=1, hp=10**9, initial_ap=4)}, config, 7, max_rounds=1)
        enemy = next(a for a in report["b"]["a"] if a["s"].get("r") is True and a["s"]["t"] == "N")
        self.assertFalse(any(d.get("u", {}).get("u") == "dizzy" for d in enemy["e"]))
        self.assertTrue(all(d["ap"] == 4 for d in enemy["e"] if d["r"] is False and "ap" in d))
        self.assert_replays(report)
        phase = min(int(k) for k, r in config["pet3_attr"]["90008"].items() if r["skillid"] == 12997)
        config["combskill"] = {**config["combskill"], "12997": {**config["combskill"]["12997"], "trigger": 1}}
        report = battle.simulate({2: self.unit()}, {2: self.gold(164004, 9001039, iid=1, initial_ap=4)}, config, 7,
                                 attack_pet={"cid": 90008, "iid": 999, "phase": phase, "level": 1}, max_rounds=1)
        self.assertTrue(any(d.get("ap") == 2 and not d["r"] for a in report["b"]["a"] if a["s"].get("p") == [0] for d in a["e"]))
        self.assert_replays(report)

    def test_sword_marks_increase_owner_damage_reduce_return_hits_and_expire(self):
        with patch.object(battle.random.Random, "random", return_value=.99):
            report = battle.simulate({2: self.gold(164038, 9001208, speed=300, initial_ap=4)},
                                     {2: self.unit(iid=1, hp=100000, atk=100), 8: self.unit(iid=2, hp=100000, atk=100)}, self.isolated(), 7, max_rounds=3)
        self.assertEqual(self.hits(report), [220, 220, 130, 100])
        self.assertEqual(self.hits(report, False), [70, 70, 200])
        self.assert_replays(report)

    def test_personal_extra_targets_and_stun_probability_do_not_expand_combo(self):
        enemies = {p: self.unit(iid=i+1, hp=100000, atk=1) for i, p in enumerate(battle.POSITIONS[:5])}
        with patch.object(battle.random.Random, "random", return_value=.7), patch.object(battle.random.Random, "randint", return_value=2):
            report = battle.simulate({2: self.gold(164038, 9001209, speed=300, initial_ap=4)}, enemies, self.isolated(), 7, max_rounds=1)
        cast = next(a for a in report["b"]["a"] if a["s"].get("S") == 180072)
        hits = [d for d in cast["e"] if not d["r"] and isinstance(d.get("m"), dict)]
        self.assertEqual(len(hits), 4)
        self.assertTrue(all(d.get("u") == {"u": "dizzy", "w": True} for d in hits))
        self.assert_replays(report)

    def test_personal_ap_drain_picks_highest_one_or_two_and_respects_immunity(self):
        with patch.object(battle.random.Random, "randint", return_value=2):
            report = battle.simulate({2: self.gold(164038, 9001210, speed=300, initial_ap=4)},
                                     {p: self.unit(iid=i+1, initial_ap=ap, hp=100000, atk=1) for i, (p, ap) in enumerate(((2, 1), (8, 10), (10, 7)))}, self.isolated(), 7, max_rounds=1)
        drain = next(a for a in report["b"]["a"] if not a["s"] and sum("ap" in d and not d["r"] for d in a["e"]) == 2)
        self.assertEqual([(d["p"], d["ap"]) for d in drain["e"]], [(8, 8), (10, 5)])
        self.assert_replays(report)
        config = self.isolated()
        config["general"]["10305"] = {**config["general"]["10305"], "break1": 9000537}
        report = battle.simulate({2: self.gold(164038, 9001210, speed=300, initial_ap=4)},
                                 {2: self.unit(10305, iid=1, advance=1, initial_ap=4, hp=100000)}, config, 7, max_rounds=1)
        drain = next(a for a in report["b"]["a"] if not a["s"] and any(not d["r"] and "ap" in d for d in a["e"]))
        self.assertEqual(drain["e"][0]["ap"], 4)
        self.assert_replays(report)

    def test_kill_from_extra_damage_casts_personal_once_without_second_ap_cost(self):
        config = self.isolated()
        config["general"]["164038"]["break1"] = 9000645
        report = battle.simulate({2: self.gold(164038, 9001211, speed=300)},
                                 {2: self.unit(iid=1, hp=100000, atk=1), 8: self.unit(iid=2, hp=1, atk=1),
                                  10: self.unit(iid=3, hp=1, atk=1)}, config, 7, max_rounds=1)
        casts = [a for a in report["b"]["a"] if a["s"].get("S") == 180072]
        self.assertEqual(len(casts), 1)
        self.assertEqual(report["endmeta"]["attack"]["2"]["ap"], 2)
        self.assert_replays(report)

    def test_personal_recovery_heals_lowest_to_full_and_rolls_two_ap(self):
        with patch.object(battle.random.Random, "random", return_value=0):
            report = battle.simulate({2: self.gold(164038, 9001212, speed=300, initial_ap=4), 8: self.unit(iid=701, hp=1000, speed=1)},
                                     {8: self.unit(iid=1, speed=400, atk=500, hp=10**9)}, self.isolated(), 7, max_rounds=1)
        self.assertTrue(any(d["r"] and d["p"] == 2 and d.get("m", {}).get("m", 0) == -500 for a in report["b"]["a"] for d in a["e"] if isinstance(d.get("m"), dict)))
        self.assertEqual(report["endmeta"]["attack"]["2"]["h"], 10000)
        self.assertEqual(report["endmeta"]["attack"]["2"]["ap"], 2)
        self.assert_replays(report)

    def test_even_round_immunity_blocks_two_hits_then_expires(self):
        with patch.object(battle.random.Random, "random", return_value=.99):
            report = battle.simulate({2: self.gold(164038, 9001213, speed=500)},
                                     {p: self.unit(iid=i+1, hp=10**9, atk=100) for i, p in enumerate(battle.POSITIONS[:3])}, self.isolated(), 7, max_rounds=3)
        hits = []
        round_no = 1
        for a in report["b"]["a"]:
            if not a["s"] and not a["e"]:
                round_no += 1
            if a["s"].get("r") is False:
                hits += [(round_no, d["m"]["m"], d["m"]["u"]) for d in a["e"] if d["r"] and isinstance(d.get("m"), dict)]
        self.assertEqual([h[1] for h in hits if h[0] == 2], [0, 0, 100])
        self.assertTrue(all(h[1] > 0 for h in hits if h[0] == 3))
        self.assert_replays(report)

    def test_gold_attack_auras_stack_across_heroes_not_choices_and_exclude_red(self):
        config = self.isolated()
        config["general"]["164036"] = {**config["general"]["164036"], **{f"break{i}": 0 for i in range(1, 17)}}
        attack = {2: self.gold(164004, 9001038), 8: self.gold(164004, 9001039, iid=701),
                  10: self.gold(164038, 9001212, iid=702), 4: self.gold(164036, 9001201, iid=703),
                  12: self.unit(10829, iid=704)}
        teams = {True: attack, False: {2: self.unit(iid=1)}}
        battle._prepare_teams(teams, config)
        self.assertEqual([u["atk"] for u in attack.values()], [160100]*4+[100])

    def test_counted_immunity_survives_artifact_display_expiry_then_clears_next_round(self):
        config = self.isolated()
        row = next(r for r in config["trump_skillRnd"]["2"].values() if r["name"] == "屏障")
        sid = row["skill6"]
        config["breakskill"] = {**config["breakskill"], str(sid): {**config["breakskill"][str(sid)], "value2": 1}}
        actor = self.gold(164038, 9001213, speed=500, artifact={"cid": 110005, "level": 0, "skills": [sid]})
        with patch.object(battle.random.Random, "random", return_value=.99):
            report = battle.simulate({2: actor}, {2: self.unit(iid=1, hp=10**9, atk=100)}, config, 7, max_rounds=3)
        switches, round_no = {}, 1
        for action in report["b"]["a"]:
            if not action["s"] and not action["e"]:
                round_no += 1
            for change in action["e"]:
                if change["r"] and change.get("u", {}).get("u") == "invincible":
                    switches.setdefault(round_no, []).append(change["u"]["w"])
        self.assertEqual(switches[2], [True])
        self.assertEqual(switches[3], [False])
        self.assert_replays(report)

    def test_even_round_immunity_requires_not_more_allies_and_ignores_execution(self):
        report = battle.simulate({2: self.gold(164038, 9001213, speed=300), 8: self.unit(iid=701)},
                                 {2: self.unit(iid=1, hp=10**9, atk=100)}, self.isolated(), 7, max_rounds=2)
        self.assertTrue(all(n > 0 for n in self.hits(report, False)))
        self.assert_replays(report)
        boss = self.unit(iid=1, npc=True, hp=10**9, atk=1, speed=1, skill=0, boss_cycle=[12640])
        boss["cid"] = int(next(iter(self.config["personalboss_att"])))
        # 第一轮普攻，第二轮Boss才有一次行动；免疫已在第二轮开始获得。
        config = self.isolated()
        config["general"][str(boss["cid"])] = dict(self.config["personalboss_att"][str(boss["cid"])], skillid=0, combskillid=0, init_cid=0)
        actor = self.gold(164038, 9001213, speed=300)
        config["general"]["164038"]["break1"] = 9100002
        with patch.object(battle.random.Random, "random", side_effect=[0]+[.99]*20):
            report = battle.simulate({2: actor}, {2: boss}, config, 7, max_rounds=2)
        self.assertEqual(report["endmeta"]["attack"]["2"]["h"], 0)
        self.assert_replays(report)

    def test_kill_followup_stops_at_terminal_state_and_never_fires_for_an_ally(self):
        for ally in (False, True):
            attack = {2: self.gold(164038, 9001211, speed=300)}
            if ally:
                attack[8] = self.unit(iid=701, speed=500)
            report = battle.simulate(attack, {2: self.unit(iid=1, hp=1, speed=1)}, self.isolated(), 7, max_rounds=30)
            self.assertFalse(any(a["s"].get("S") == 180072 for a in report["b"]["a"]))
            self.assertTrue(report["result"])
            self.assert_replays(report)

    def test_different_seeds_pve_pvp_and_gold_pair_all_choices_keep_terminal_replay(self):
        for choices in product((1, 3), repeat=6):
            attack = {}
            for pos, cid, offset in ((2, 164004, 0), (8, 164038, 3)):
                row = self.config["general"][str(cid)]
                pids = [row[f"gold{i}_will_skills_{ch}"] for i, ch in enumerate(choices[offset:offset+3], 1)]
                attack[pos] = self.gold(cid, *pids, iid=700+pos, hp=10**7, speed=300-pos, initial_ap=4)
            for direct, npc, seed in ((True, False, 31), (False, True, 77)):
                teams = {direct: attack, not direct: {p: self.unit(iid=100+i, hp=10**7, atk=500000, npc=npc) for i, p in enumerate(battle.POSITIONS)}}
                original = copy.deepcopy(teams)
                report = battle.simulate(teams[True], teams[False], self.config, seed)
                self.assertEqual(teams, original)
                self.assert_replays(report)

    def reports(self):
        for cid in (164004, 164038):
            row = self.config["general"][str(cid)]
            for choices in product((1, 3), repeat=3):
                pids = [row[f"gold{i}_will_skills_{ch}"] for i, ch in enumerate(choices, 1)]
                for direct in (True, False):
                    teams = {direct: {2: self.gold(cid, *pids, hp=10**8, initial_ap=4, speed=300)},
                             not direct: {p: self.unit(iid=100+i, hp=10**8, atk=1000) for i, p in enumerate(battle.POSITIONS)}}
                    original = copy.deepcopy(teams)
                    report = battle.simulate(teams[True], teams[False], self.config, 7, max_rounds=6)
                    self.assertEqual(report, battle.simulate(teams[True], teams[False], self.config, 7, max_rounds=6))
                    self.assertEqual(teams, original)
                    self.assert_replays(report)
                    yield report

    def test_all_real_choices_both_sides_are_deterministic_and_replay_native_assets(self):
        self.assert_native_reports(self.reports())

    def test_gold_pair_combo_uses_both_real_positions_without_personal_only_effects(self):
        config = self.isolated()
        config["combskillprobability"] = copy.deepcopy(config["combskillprobability"])
        config["combskillprobability"]["13073"]["bout1"] = 1
        report = battle.simulate({2: self.gold(164004, 9001034, speed=300, initial_ap=4),
                                 8: self.gold(164038, 9001209, 9001212, iid=701, speed=1, hp=1000000)},
                                {2: self.unit(iid=1, hp=10**9, atk=1)}, config, 7, max_rounds=1)
        cast = next(a for a in report["b"]["a"] if a["s"].get("S") == 13073)
        self.assertEqual(cast["s"]["p"], [2, 8])
        self.assert_replays(report)
        self.assert_native_reports([report])


if __name__ == "__main__":
    unittest.main()
