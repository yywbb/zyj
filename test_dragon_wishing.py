"""神龙许愿：真实地图、骰子/日切、七天闭环、奖励和原生客户端。"""

import copy
import json
import random
import unittest
import zipfile
from unittest.mock import patch

import build_local_apk as builder
import test_nightclub
from zyj_server import activities, battle, dragon_wishing as dragon, player, protocol, recharge


def setUpModule():
    test_nightclub.setUpModule()


class DragonBattleTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.config = player.load_role_config("configs_sec5.zip")

    def unit(self, cid=10201, **values):
        return {"cid": cid, "iid": cid, "level": 1, "advance": int(cid in (10819, 10820, 10821, 10822)),
                "exp": 0, "atk": 100, "def": 0, "hp": 1000, "speed": 100, "initial_ap": 0,
                "skill": self.config["general"][str(cid)]["skillid"], "npc": True, **values}

    def test_absorb_preserves_max_hp_turns_damage_into_heal_and_unlocks_on_full_or_round_four(self):
        for amount, rounds, expected in ((100, 1, 101), (10000, 1, 1000), (100, 4, 301)):
            enemy = self.unit(atk=amount, hp=100000, speed=200)
            report = battle.simulate({2: enemy}, {2: self.unit(10820)}, self.config, 7, max_rounds=rounds)
            self.assertEqual((report["meta"]["defense"]["g"]["10820"]["h"], report["meta"]["defense"]["g"]["10820"]["j"]), (1, 1000))
            self.assertEqual(report["endmeta"]["defense"]["2"]["h"], expected)
        ray = battle.simulate({p: self.unit(iid=p, atk=1, hp=100000) for p in (2, 4, 8)},
                              {2: self.unit(10820, initial_ap=4, speed=200)}, self.config, 7, max_rounds=4)
        beams = [a for a in ray["b"]["a"] if a.get("s", {}).get("S") == 12986]
        self.assertEqual(len(beams), 1)
        self.assertEqual(sum(u["h"] == 0 for u in ray["endmeta"]["attack"].values()), 2)
        self.assertEqual(ray["endmeta"]["defense"]["2"]["ap"], 6)

    def test_fusion_is_strict_below_twenty_percent_and_selects_highest_other_max_hp(self):
        for damage, fused in ((800, False), (801, True)):
            friends = {2: self.unit(10819, speed=100), 8: self.unit(hp=2000, speed=1), 10: self.unit(hp=3000, speed=1)}
            report = battle.simulate(friends, {2: self.unit(atk=damage, hp=100000, speed=200)}, self.config, 7, max_rounds=1)
            self.assertEqual("2" not in report["endmeta"]["attack"], fused)
            casts = [a for a in report["b"]["a"] if a.get("s", {}).get("S") == 9000324]
            self.assertEqual(len(casts), int(fused))
            if fused:
                self.assertEqual(casts[0]["e"][0]["p"], 10)
                hit = next(a for a in report["b"]["a"] if a.get("s", {}).get("p") == [10])
                self.assertEqual(hit["e"][0]["m"]["m"], 200)
        report = battle.simulate({2: self.unit(10819)}, {2: self.unit(atk=801, hp=100000, speed=200)}, self.config, 7, max_rounds=1)
        self.assertIn("2", report["endmeta"]["attack"])

    def test_revives_twice_only_with_live_ally_halves_defense_and_never_revives_team_wipe(self):
        friends = {2: self.unit(10821, hp=1000, **{"def": 100}), 8: self.unit(hp=100000, speed=1)}
        report = battle.simulate(friends, {2: self.unit(atk=2000, hp=1000000, speed=200)}, self.config, 7, max_rounds=4)
        revives = [a for a in report["b"]["a"] if a.get("s", {}).get("S") == 9000328]
        self.assertEqual([a["e"][0]["m"]["m"] for a in revives], [-500, -500])
        self.assertEqual(report["endmeta"]["attack"]["2"]["h"], 0)
        for friends in ({2: self.unit(10821)}, {2: self.unit(10821), 8: self.unit(10821, iid=2)}):
            attacker = self.unit(10821, atk=100000, hp=1000000, initial_ap=10, speed=200)
            report = battle.simulate(friends, {2: attacker}, self.config, 7, max_rounds=1)
            self.assertFalse(any(a.get("s", {}).get("S") == 9000328 for a in report["b"]["a"]))

    def test_split_spawns_two_real_entities_next_round_and_explodes_once_with_seven_slot_cap(self):
        friends = {2: self.unit(10822, speed=200)}
        enemy = {2: self.unit(atk=1, hp=100000, speed=1)}
        before = copy.deepcopy((friends, enemy))
        report = battle.simulate(friends, enemy, self.config, 7, max_rounds=2)
        self.assertEqual((friends, enemy), before)
        spawns = [a for a in report["b"]["a"] if a["t"] == "pos"]
        self.assertEqual([len(a["changes"]) for a in spawns], [2, 2])
        explosions = [a for a in report["b"]["a"] if a.get("s", {}).get("S") == 12987]
        self.assertEqual(len(explosions), 2)
        self.assertEqual(report["endmeta"]["defense"]["2"]["h"], 99900)
        self.assertEqual(sum(u["c"] == 10823 and u["h"] == 0 for u in report["endmeta"]["attack"].values()), 2)
        full = {p: self.unit(10822, iid=p, speed=200) for p in battle.POSITIONS}
        report = battle.simulate(full, enemy, self.config, 7, max_rounds=1)
        self.assertFalse(any(a["t"] == "pos" for a in report["b"]["a"]))
        self.assertEqual(report, battle.simulate(full, enemy, self.config, 7, max_rounds=1))
        prepare = battle._prepare_teams
        def sealed(teams, config):
            prepare(teams, config)
            teams[True][2]["states"]["skilllock"] = 3
        with patch.object(battle, "_prepare_teams", side_effect=sealed):
            report = battle.simulate({2: self.unit(10823)}, enemy, self.config, 7, max_rounds=1)
        self.assertEqual(report["endmeta"]["attack"]["2"]["h"], 999)
        self.assertFalse(any(a.get("s", {}).get("r") is True for a in report["b"]["a"]))


class DragonWishingTests(unittest.TestCase):
    request = test_nightclub.NightclubTests.request
    success = test_nightclub.NightclubTests.success
    reconnect = test_nightclub.NightclubTests.reconnect
    add_account = test_nightclub.NightclubTests.add_account
    assert_rejected = test_nightclub.NightclubTests.assert_rejected
    refresh = test_nightclub.NightclubTests.refresh
    grant = test_nightclub.NightclubTests.grant
    props = test_nightclub.NightclubTests.props
    groups = test_nightclub.NightclubTests.groups
    records = test_nightclub.NightclubTests.records
    strong = test_nightclub.NightclubTests.strong
    client_scripts = classmethod(test_nightclub.NightclubTests.client_scripts.__func__)
    network_lua = test_nightclub.NightclubTests.network_lua
    client_call = test_nightclub.NightclubTests.client_call

    def setUp(self):
        test_nightclub.NightclubTests.setUp(self)
        rng = random.Random(7)
        sampler = patch.object(player.random, "getrandbits", side_effect=rng.getrandbits)
        sampler.start(); self.addCleanup(sampler.stop)

    def query(self):
        values = protocol.parse_ids_pb(self.success(1, 4901)); self.refresh()
        return values

    def state(self):
        return self.save["dragon_wishing_state"]

    def act(self, opcode, values=(), auto=0):
        state = self.state()
        if opcode == 4902:
            quote = 0 if state["dice"] else dragon.price(self.config, state["bought"] + 1, "shenlong_dice_cost")
            values = [state["serial"], quote, auto]
        else:
            values = [*values, state["serial"]]
        raw = self.success(1, opcode, values=values); self.refresh()
        return raw

    def pending(self, eid, *, boss=0, point=None):
        self.query()
        state = self.state()
        kind = 4 if eid > 10000 else eid
        point = point or next(i for i in range(1, 140) if dragon.layout(state, self.config).get(f"point{i}") == kind)
        road, index = next((r, ps.index(point)) for r, ps in dragon.roads(self.config).items() if point in ps)
        state["path"] = [[road, index]]
        state["points"][point - 1] = kind - 5 if 6 <= kind <= 9 else 1
        state["pending"] = {"event": eid, "boss": boss, "level": self.save["role_state"]["level"]}
        return state

    def test_real_entry_155_native_fields_plus_serial_and_initial_dice_only_once(self):
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 4907)), [2]); self.refresh()
        first = self.query()
        self.assertEqual(len(first), 156)
        self.assertEqual((first[1:9], first[154:]), ([0, 0, 0, 30, 1, 0, 0, 1], [1, 1]))
        self.act(4902)
        dice = self.state()["dice"]
        self.reconnect(); self.refresh()
        self.assertEqual(self.query()[4], dice)
        self.assertIn(dice, (29, 30))
        self.assertEqual(self.query()[154], 0)

    def test_hourly_recovery_overflow_cap_fractional_clock_and_rollback_do_not_mint_dice(self):
        self.query()
        state = self.state()
        dragon.change_dice(state, -7, self.config, self.now)
        self.assertEqual((state["dice"], state["next_at"]), (23, self.now + 3600))
        self.clock.return_value += 3599
        self.assertEqual(self.query()[4:7], [23, 1, 1])
        self.clock.return_value += 1
        self.assertEqual(self.query()[4:7], [24, 1, 0])
        self.clock.return_value += 7200
        self.assertEqual(self.query()[4], 24)
        state = self.state(); dragon.change_dice(state, -2, self.config, int(self.clock.return_value))
        self.clock.return_value += 4000
        self.assertEqual(self.query()[4:7], [23, 1, 3200])
        self.reconnect(); self.refresh()
        self.clock.return_value -= 10
        self.assert_rejected(4902, values=[self.state()["serial"], 0, 0])

    def test_paid_manual_roll_quote_auto_no_purchase_and_actual_daily_roll_count(self):
        self.query()
        self.state()["dice"] = 0
        self.state()["next_at"] = self.now + 3600
        self.assert_rejected(4902, values=[self.state()["serial"], 0, 0])
        self.assert_rejected(4902, values=[self.state()["serial"], 10, 1])
        gold = self.save["role_state"]["gold"]
        self.act(4902)
        self.assertEqual(self.save["role_state"]["gold"], gold - 10)
        self.assertEqual(self.state()["bought"], 1)
        self.assertIn(self.state()["dice"], (0, 1))
        self.assertEqual(activities.liveness_statuses(self.save, self.config, self.now)[1][43], 1)
        self.query()
        self.assertEqual(activities.liveness_statuses(self.save, self.config, self.now)[1][43], 1)

    def test_all_nine_questions_both_choices_use_internal_dice_and_original_rewards_once(self):
        for eid, row in self.config["shenlong_praram"].items():
            for choice in (1, 2):
                self.pending(int(eid))
                before = copy.deepcopy(self.save)
                costs = dragon.pairs(row[f"cost{choice}"])
                rewards = dragon.pairs(row[f"bonus{choice}"])
                expected_dice = self.state()["dice"] - costs.pop(1022, 0) + rewards.pop(1022, 0)
                for cid, count in costs.items(): player.change_item_count(before, cid, -count, self.config, self.now)
                player.apply_reward(before, dragon.recruit.build_reward(before, list(rewards.items()), self.config), self.config, self.now)
                old = self.state()["serial"]
                self.act(4904, [choice])
                self.assertEqual(self.state()["dice"], expected_dice)
                self.assertEqual((self.save["role_state"], self.save["world_state"]), (before["role_state"], before["world_state"]))
                self.assert_rejected(4904, values=[choice, old])

    def test_guard_loss_retry_bribe_and_flee_cannot_grant_fake_wins_or_duplicate_daily_ball(self):
        self.pending(9, boss=4, point=139)
        before = copy.deepcopy(self.save)
        raw = self.groups(self.act(4904, [1]))[2]
        self.assertEqual(protocol.pb_get_varint(raw, 1), 0)
        self.assertEqual(self.state()["balls"], 0)
        self.assertEqual(self.save["world_state"], before["world_state"])
        self.assert_rejected(4905, values=[self.state()["serial"]])
        self.strong()
        raw = self.groups(self.act(4904, [1]))[2]
        self.assertEqual(protocol.pb_get_varint(raw, 1), 1)
        self.assertEqual((self.state()["balls"], self.state()["ball_today"]), (1, True))
        self.pending(9, boss=4, point=139)
        gold = self.save["role_state"]["gold"]
        self.act(4904, [2])
        self.assertIn(self.save["role_state"]["gold"], (gold - 50, gold + 50))
        self.assertEqual(self.state()["balls"], 1)
        self.pending(6, boss=1)
        self.act(4904, [3])
        self.assertIsNone(self.state()["pending"])

    def test_shop_visit_limits_quotes_costs_and_leaving_are_persisted_and_stale_requests_rejected(self):
        self.pending(3)
        gold = self.save["role_state"]["gold"]
        self.assert_rejected(4906, values=[1, 1, 0, self.state()["serial"]])
        self.act(4906, [1, 1, 400])
        self.assertEqual(self.save["role_state"]["gold"], gold - 400)
        self.reconnect(); self.refresh()
        self.assert_rejected(4906, values=[1, 1, 400, self.state()["serial"]])
        self.act(4905)
        self.assert_rejected(4906, values=[2, 1, 300, self.state()["serial"]])

    def test_seven_real_daily_completions_unlock_one_weighted_wish_keep_day_and_reconnect(self):
        self.query(); self.strong()
        for day in range(7):
            self.query()
            for _ in range(100):
                if self.state()["ball_today"]:
                    break
                pending = self.state()["pending"]
                if pending:
                    if pending["event"] == 9:
                        self.act(4904, [1])
                    else:
                        self.act(4905)
                else:
                    self.act(4902)
            self.assertEqual(self.state()["balls"], day + 1)
            self.reconnect(); self.refresh()
            if day < 6:
                self.clock.return_value += 86400
        self.assert_rejected(4902, values=[self.state()["serial"], 0, 0])
        serial = self.state()["serial"]
        before = copy.deepcopy(self.save)
        self.act(4903, [1])
        self.assertIn(self.save["role_state"]["gold"] - before["role_state"]["gold"], (1088, 1288, 1588))
        self.assertEqual((self.state()["balls"], self.state()["wishes"], self.state()["ball_today"]), (0, 1, True))
        self.assert_rejected(4903, values=[1, serial])
        self.assertEqual(self.save["world_state"]["1300"], before["world_state"]["1300"])
        self.assertEqual(activities.liveness_statuses(self.save, self.config, int(self.clock.return_value))[1][43], 10)
        self.success(1, 2411, values=[143]); self.refresh()
        self.assert_rejected(2411, values=[143])

    def test_invalid_payloads_save_failures_and_overflow_preserve_dice_choices_and_rewards(self):
        for opcode in dragon.OPCODES:
            self.assert_rejected(opcode, raw=b"\x10\x01")
        self.query()
        before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.act(4902)
        self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))
        self.pending(100009)
        self.save["role_state"]["gold"] = (1 << 31) - 1
        self.assert_rejected(4904, values=[1, self.state()["serial"]])
        self.save["role_state"]["gold"] = 1000000
        self.pending(3)
        before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.act(4906, [1, 1, 400])
        self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))
        self.state()["points"] = []
        self.assert_rejected(4901)

    def test_all_three_wish_decks_costs_and_failures_commit_with_claim_flags(self):
        self.query()
        for choice in (1, 2, 3):
            self.state()["balls"] = 7
            before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
            with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
                self.act(4903, [choice])
            self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))
            reward = self.act(4903, [choice])
            expected = copy.deepcopy(before)
            native = b"".join(protocol.encode_pb_field(n, w, raw) for n, w, raw in protocol.iter_pb_fields(reward) if n != 100)
            player.apply_reward(expected, native, self.config, self.now)
            self.assertEqual((self.save["world_state"], self.save["role_state"]), (expected["world_state"], expected["role_state"]))
            self.assertEqual((self.state()["balls"], self.state()["wishes"]), (0, choice))
            self.reconnect(); self.refresh()
            self.assert_rejected(4903, values=[choice, self.state()["serial"]])

    def test_all_wish_level_buckets_auto_unlocks_and_dice_tile_reward_use_actual_configuration(self):
        self.query()
        for level in (30, 70, 71, 90, 91, 110, 111, 150):
            self.save["role_state"]["level"] = level
            for choice in (1, 2, 3):
                self.state()["balls"] = 7
                before = copy.deepcopy(self.save)
                self.act(4903, [choice])
                bucket = min(int(k) for k in self.config["shenlong_reward"] if int(k) >= level)
                possible = []
                for entry in self.config["shenlong_reward"][str(bucket)][f"reward{choice}"].strip(";").split(";"):
                    cid, count, weight = map(int, entry.split(","))
                    if weight:
                        expected = copy.deepcopy(before)
                        player.apply_reward(expected, dragon.recruit.build_reward(expected, [(cid, count)], self.config), self.config, self.now)
                        possible.append((expected["role_state"], expected["world_state"]))
                self.assertIn((self.save["role_state"], self.save["world_state"]), possible)
        for level, vip, allowed in ((30, 3, False), (30, 4, True), (60, 0, True)):
            self.save["role_state"].update(level=level, vip=vip)
            dragon.fresh_map(self.state(), self.config, 1)
            if allowed:
                self.act(4902, auto=1)
            else:
                self.assert_rejected(4902, values=[self.state()["serial"], 0, 1])
        state = copy.deepcopy(self.state())
        dragon.fresh_map(state, self.config, 1)
        road, index = next((r, i) for r, ps in dragon.roads(self.config).items() for i, p in enumerate(ps)
                           if i > 0 and dragon.layout(state, self.config).get(f"point{p}") == 10)
        state["path"] = [[road, index-1]]
        state["dice"], state["next_at"] = 29, 0
        seed = next(seed for seed in range(30) if random.Random(seed).randint(1, 6) == 1)
        _, route, _, _, eid = dragon.roll(state, self.save, self.config, self.now, random.Random(seed))
        self.assertEqual((state["dice"], eid, state["points"][route[-1]-1]), (30, 10, 0))

    def test_roll_retry_cache_insufficient_cost_and_failed_battle_save_preserve_all_progress(self):
        self.query()
        serial = self.state()["serial"]
        raw = recharge.ids([serial, 0, 0])
        replies = self.sessions[1].handle(4902, 7878, raw)
        self.assertEqual(self.sessions[1].handle(4902, 7878, raw), replies)
        self.refresh(); self.reconnect(); self.refresh()
        self.assert_rejected(4902, raw=raw)
        self.assert_rejected(999900, raw=dragon.comb([(4902, raw)]))
        self.state().update(dice=0, next_at=self.now+3600, pending=None)
        self.save["role_state"]["gold"] = 0
        quote = dragon.price(self.config, self.state()["bought"] + 1, "shenlong_dice_cost")
        self.assert_rejected(4902, values=[self.state()["serial"], quote, 0])
        self.pending(9, boss=4, point=139)
        self.assert_rejected(4904, values=[2, self.state()["serial"]])
        self.strong()
        before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.act(4904, [1])
        self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))
        self.state()["path"] = [[1, 0], [2, 3]]
        self.assert_rejected(4901)

    def test_actual_packaged_ui_entry_old_pages_windows_and_real_second_recovery(self):
        from lupa.lua51 import LuaRuntime
        lua = LuaRuntime()
        scripts = self.client_scripts()
        for name in ("GameDragonWishing", "UIDragonWishing", "Layer_shenlongxuyuan", "window_shenlongxuyuan_event", "window_shenlongxuyuan_shop", "window_shenlongxuyuan_reward"):
            lua.compile(scripts[f"assets/scripts/{name}.so"].decode())
        page = lua.execute(scripts["assets/scripts/Layer_shenlongxuyuan.so"].decode())
        lua.globals().page = page
        lua.globals().gamedata = lua.table_from({"config": self.config}, recursive=True)
        lua.execute('''print=function() end;printT=print;now=100
            function node() return setmetatable({}, {__index=function(t,k)
                if k=="addHandleOfControlEvent" then return function(self,f) self.callback=f end end
                return function() end
            end}) end
            function items() return setmetatable({}, {__index=function(t,k) local n=node();rawset(t,k,n);return n end}) end
            gameTouch={clickprofbytime=function() end};ui={setLabelString=function() end,makeTimeText=tostring}
            gameTimer={times={},rigistTime=function(self,k,n) self.times[k]=n end,
                rigistTimeFunc=function(self,k,cb) timer=cb end,UnrigistTimeFunc=function(self,k) self.times[k]=nil end}
            gamedata.time=function() return now end
            requests={};UIRequest=function(t) requests[#requests+1]=t end;updateDataLife=function() end
            page.rootNode=node();page.rootItems=items();page.localDragonGeneration=1;page.m_bIsAutoGame=-1
            page.setDice=function(self) self.moves=(self.moves or 0)+1 end
            GameScene={presentLayer="daily",layers={shenlongxuyuan={show=false,module=page}},
                checkopenlevelbyId=function() return true end,shiftLayer=function(self,key,dir,param)
                    self.presentLayer=key;self.param=param end}
            gameScene=GameScene
            gameWindows={closeAllWindowDirect=function() end,windows={},openWindow=function(self,name,data,callback) windowData=data;windowCallback=callback end}
        ''')
        scene = scripts["assets/scripts/GameScene.so"].decode()
        start = scene.index("function gameScene.shiftLayerById(")
        lua.execute(scene[start:scene.index("\nfunction ", start + 1)])
        lua.execute(scripts["assets/scripts/UIDragonWishing.so"].decode())
        lua.execute('''GameScene:shiftLayerById(308);assert(requests[1].type==4907)
            local view=requests[1].dragonView
            GameScene:shiftLayer("other");GameScene:shiftLayer("daily")
            UIDragonWishingQueryMap({type=4907,map=2,dragonView=view});assert(GameScene.presentLayer=="daily")
            UIRequest({type=4907});view=requests[#requests].dragonView
            UIDragonWishingQueryMap({type=4907,map=2,dragonView=view});assert(GameScene.presentLayer=="shenlongxuyuan" and GameScene.param==2)
            GameScene.layers.shenlongxuyuan.show=true
            UIRequest({type=4902});view=requests[#requests].dragonView
            UIDragonWishingGet({type=4902,dragonView=view});assert(page.moves==1)
            local movingCount=#requests;UIRequest({type=4902});assert(#requests==movingCount)
            page.localDragonGeneration=2
            UIDragonWishingGet({type=4902,dragonView=view});assert(page.moves==1)
            local state={serial=10,dicenum=23,dicebuy=0,time=60}
            UIRequest({type=4901,opt=2});view=requests[#requests].dragonView
            UIDragonWishingQuery({type=4901,opt=2,dragonwishing=state,dragonstate=state,dragonView=view})
            local count=#requests
            for i=1,100 do timer() end;assert(gameTimer.times.shenlongxuyuandice==60 and #requests==count)
            now=159;timer();assert(gameTimer.times.shenlongxuyuandice==1)
            now=160;timer();timer();assert(#requests==count+1 and requests[#requests].type==4901)
            page.reloaddata=function() end
            UIDragonWishingQuery({type=4901,opt=0,dragonwishing=state,dragonstate=state,dragonView=view})
            assert(not page.localDragonMoving)
            gameWindows:openWindow("shenlongxuyuan_shop",{},function() UIRequest({type=4905}) end)
            local oldcb=windowCallback
            gameWindows:openWindow("shenlongxuyuan_shop",{},nil)
            count=#requests;oldcb();assert(#requests==count)
            gameWindows:openWindow("shenlongxuyuan_reward",{},function() UIRequest({type=4903,id=1}) end)
            oldcb=windowCallback;page.localDragonGeneration=3;oldcb();assert(#requests==count)
        ''')

    def test_native_network_protocol_serial_prices_fifo_error_unlock_and_absolute_dice_state(self):
        lua = self.network_lua(native_protobuf=True)
        lua.eval(b"require")(b"GameDragonWishing")
        self.client_call(lua, 1, "UIDragonWishingQueryMapCallBack", "NetDragonWishingQueryMapCallBack", {})
        result = self.client_call(lua, 1, "UIDragonWishingQueryCallBack", "NetDragonWishingQueryCallBack", {"opt": 2})
        self.refresh()
        self.assertEqual((result[b"opt"], result[b"dragonwishing"][b"serial"]), (2, 1))
        self.client_call(lua, 1, "UIDragonWishingGetCallBack", "NetDragonWishingGetCallBack", {"dragonSerial": 1, "xgold": 0})
        self.refresh()
        self.assertEqual(lua.globals().gamedata[b"ext"][b"localDragonState"][b"serial"], self.state()["serial"])
        fd = lambda raw: lua.table_from({b"rbuf": raw})
        self.pending(100003)
        self.client_call(lua, 1, "UIDragonWishingQueryCallBack", "NetDragonWishingQueryCallBack", {})
        serial = self.state()["serial"]
        mode, opcode, raw = lua.globals().UIDragonWishingEventCallBack(lua.table_from({b"opt": 1, b"dragonSerial": serial}))
        self.assertEqual((mode, opcode, protocol.parse_ids_pb(raw)), (1, 4904, [1, serial]))
        self.assertEqual(lua.globals().UIDragonWishingEventCallBack(lua.table_from({b"opt": 1, b"dragonSerial": serial}))[0], 0)
        lua.globals().NetErrorMessageCallback9(fd(recharge.ids([4906, 0])))
        self.assertEqual(lua.globals().gamedata[b"ext"][b"localDragonBusy"], 4904)
        result = lua.globals().NetDragonWishingEventCallBack(fd(self.success(1, opcode, raw=raw))); self.refresh()
        self.assertEqual(result[b"adddice"], 2)
        self.assertEqual(result[b"dragonstate"][b"dicenum"], self.state()["dice"])
        self.pending(100004)
        self.client_call(lua, 1, "UIDragonWishingQueryCallBack", "NetDragonWishingQueryCallBack", {})
        result = self.client_call(lua, 1, "UIDragonWishingEventCallBack", "NetDragonWishingEventCallBack", {"opt": 2, "dragonSerial": self.state()["serial"]})
        self.refresh()
        self.assertEqual(result[b"adddice"], -1)
        self.pending(3)
        self.client_call(lua, 1, "UIDragonWishingQueryCallBack", "NetDragonWishingQueryCallBack", {})
        self.assertEqual(lua.globals().UIDragonWishingShopCallBack(lua.table_from({b"id": 1, b"xgold": 1, b"dragonSerial": self.state()["serial"]}))[0], 0)
        gold = self.save["role_state"]["gold"]
        self.client_call(lua, 1, "UIDragonWishingShopCallBack", "NetDragonWishingShopCallBack", {"id": 1, "xgold": 400, "dragonSerial": self.state()["serial"]})
        self.refresh()
        self.assertEqual(self.save["role_state"]["gold"], gold - 400)
        self.assertEqual(lua.globals().gamedata[b"cache"][b"role"][b"gold"], gold - 400)
        self.client_call(lua, 1, "UIDragonWishingEventCloseCallBack", "NetDragonWishingEventCloseCallBack", {"dragonSerial": self.state()["serial"]})
        self.refresh()
        for opt in (0, 2): lua.globals().UIDragonWishingQueryCallBack(lua.table_from({b"opt": opt}))
        for opt in (0, 2):
            self.assertEqual(lua.globals().NetDragonWishingQueryCallBack(fd(self.success(1, 4901)))[b"opt"], opt)
        lua.globals().UIDragonWishingGetCallBack(lua.table_from({b"xgold": 0, b"dragonSerial": self.state()["serial"]}))
        lua.globals().NetErrorMessageCallback9(fd(recharge.ids([4902, 0])))
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localDragonBusy"])
        self.assertIsNone(lua.globals().gameConfig)

    def test_all_600_profiles_and_special_mechanisms_convert_actual_animation_assets(self):
        from lupa.lua51 import LuaRuntime
        lua = LuaRuntime()
        config = dict(self.config)
        with zipfile.ZipFile("configs_sec5.zip") as archive:
            for name in ("generalanimation", "skillanimation", "personalboss_att"):
                config[name] = json.loads(archive.read("5/" + name + ".json"))
        lua.globals().gamedata = lua.table_from({"config": config}, recursive=True)
        lua.execute('''print=function() end;printT=print;battleScene={slotNum=7}
            table.getTableLength=function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
            CCFileUtils={sharedFileUtils=function(self) return self end,fullPathForFilename=function(self,p) return p end}
            ui={Split=function(s,sep) local t={} for v in string.gmatch(s,'[^'..sep..']+') do t[#t+1]=v end return t end}''')
        with zipfile.ZipFile(builder.SRC_APK) as archive:
            names, assets = archive.namelist(), {}
            lua.globals().CCFileUtils.isFileExist = lambda _, path: any(n.endswith("/" + path) for n in names)
            def load_asset(path):
                if path not in assets:
                    assets[path] = json.loads(archive.read(next(n for n in names if n.endswith("/" + path))))
                return lua.table_from(assets[path], recursive=True)
            lua.globals().LoadJsonFileToTable = load_asset
            lua.execute(self.client_scripts()["assets/scripts/battleReportConvert.so"])
            lua.execute(builder.read_script("BattleReportAbbToKey"))
            def verify(report):
                native = lua.table_from(json.loads(lua.globals().ReplaceAbbToKey(json.dumps(report))), recursive=True)
                attack, defense = lua.globals().getBattleInitSlotInfo(native)
                animations, ext = lua.globals().convertBattleReportToAnimationSub(native, attack, defense, None, "penglai")
                self.assertGreater(len(animations), 1)
                for side, key in (("attack", "atk"), ("defense", "def")):
                    self.assertEqual(set(ext.endinfo[key].keys()), set(report["endmeta"][side]))
                    for pos, unit in report["endmeta"][side].items():
                        self.assertEqual(ext.endinfo[key][pos].hp, unit["h"])
                        self.assertEqual(ext.endinfo[key][pos].ap, unit["ap"])
            before = copy.deepcopy(self.save)
            for boss in range(1, 5):
                for level in range(1, 151):
                    with self.subTest(boss=boss, level=level):
                        verify(dragon.simulate(self.save, boss, level, config, 7))
            unit = lambda cid=10201, **kw: DragonBattleTests.unit(self, cid, **kw)
            for special in (10819, 10820, 10821, 10822, 10823):
                team = {2: unit(special), 8: unit(hp=100000, speed=1)}
                enemy = {2: unit(atk=801 if special==10819 else 2000 if special==10821 else 1, hp=1000000, speed=200)}
                verify(battle.simulate(team, enemy, config, 7, max_rounds=6))
            self.assertEqual(self.save, before)

    def test_all_original_map_edges_are_used_and_routes_never_jump_across_unconnected_nodes(self):
        self.query()
        all_paths = dragon.roads(self.config)
        for road, row in self.config["shenlong_map2"].items():
            for key in ("road", "road_1", "road_2"):
                if row[key] and row[key] != 1:
                    self.assertEqual(all_paths[int(road)][-1], all_paths[row[key]][0])
        visited = set()
        for seed in range(40):
            state = copy.deepcopy(self.state())
            rng = random.Random(seed)
            for _ in range(250):
                pos = dragon.step(state, self.config, rng)
                visited.add(pos)
                if pos == 139: break
        self.assertEqual(visited, set(range(2, 140)))


if __name__ == "__main__":
    unittest.main()
