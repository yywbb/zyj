"""主城图鉴、推荐阵容与普通成就；只使用临时角色。"""

import copy
from contextlib import redirect_stdout
import io
import json
import struct
import unittest
from unittest.mock import patch

import test_penglai
import test_guild
import build_local_apk as builder
from zyj_server import achievements, collection, formation, player, protocol, recharge, recruit, rob


class CollectionAchievementTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        test_penglai.PenglaiTests.setUpClass.__func__(cls)

    setUp = test_penglai.PenglaiTests.setUp
    reconnect = test_penglai.PenglaiTests.reconnect
    call = test_penglai.PenglaiTests.call
    give = test_penglai.PenglaiTests.give
    props = test_penglai.PenglaiTests.props
    assert_rejected = test_penglai.PenglaiTests.assert_rejected

    def tasks(self):
        return {protocol.pb_get_varint(raw, 1): (protocol.pb_get_varint(raw, 2), protocol.pb_get_varint(raw, 3))
                for n, w, raw in protocol.iter_pb_fields(self.call(2400)[0][16:]) if (n, w) == (1, 2)}

    def album(self, opcode):
        return {protocol.pb_get_varint(raw, 1): protocol.pb_get_varint(raw, 2)
                for n, w, raw in protocol.iter_pb_fields(self.call(opcode)[0][16:]) if (n, w) == (1, 2)}

    def add_general(self, cid):
        reward = recruit.build_reward(self.session.save, [(cid, 1)], self.config)
        player.apply_reward(self.session.save, reward, self.config, test_penglai.NOW)

    def checkpoint(self):
        return self.call(999904)

    def test_complete_catalogues_have_explicit_flags_and_only_owned_items_are_lit(self):
        for opcode, name in ((1015, "general"), (1103, "equip")):
            flags = self.album(opcode)
            expected = {int(cid) for cid, row in self.config[name].items() if row.get("illustrated") == 1}
            self.assertEqual(set(flags), expected)
            self.assertTrue(set(flags.values()) <= {0, 1})
            self.assertLess(sum(flags.values()), len(flags))
        self.assertEqual((len(self.album(1015)), len(self.album(1103))), (215, 179))

    def test_collection_survives_consumption_reconnect_and_queries_do_not_grant_objects(self):
        self.add_general(10505)
        player.apply_reward(self.session.save, recruit.build_reward(self.session.save, [(21403, 1)], self.config), self.config)
        self.checkpoint()
        world = self.session.save["world_state"]
        for field, cid in ((1, 10505), (2, 21403)):
            world["1002"] = b"".join(protocol.encode_pb_field(n, w, raw)
                for n, w, raw in protocol.iter_pb_fields(bytes.fromhex(world["1002"]))
                if (n, w) != (field, 2) or (protocol.pb_get_varint(raw, 1) if field == 1
                    else protocol.parse_ids_pb(raw)[1]) != cid).hex()
        self.checkpoint()
        self.session = self.reconnect()
        assets = copy.deepcopy(self.session.save["world_state"])
        self.assertEqual(self.album(1015)[10505], 1)
        self.assertEqual(self.album(1103)[21403], 1)
        self.assertEqual(self.session.save["world_state"], assets)

    def test_recommendation_requires_all_collected_members_and_claim_is_permanent(self):
        self.assertEqual(protocol.parse_ids_pb(self.call(3910)[0][16:]), [0] * 8)
        self.assert_rejected(3911, recharge.ids([1]))
        for cid in (10505, 10409, 10549, 10415):
            self.add_general(cid)
        self.checkpoint()
        self.assertEqual(protocol.parse_ids_pb(self.call(3910)[0][16:])[0], 1)
        before = self.props(20100), self.props(20017)
        self.call(3911, [1])
        self.assertEqual((self.props(20100), self.props(20017)), (before[0] + 10, before[1] + 10))
        self.session = self.reconnect()
        self.assertEqual(protocol.parse_ids_pb(self.call(3910)[0][16:])[0], 2)
        self.assert_rejected(3911, recharge.ids([1]))

    def test_all_eight_recommendations_use_real_members_and_exact_configured_rewards(self):
        state = collection.get_state(self.session.save, self.config)
        state["generals"] = sorted({int(value) for row in self.config["team_recommend"].values()
                                    for value in row["icon"].split(";") if value})
        self.session.save["collection_state"] = state
        self.assertEqual(protocol.parse_ids_pb(self.call(3910)[0][16:]), [1] * 8)
        for cid in range(1, 9):
            self.call(3911, [cid])
        self.assertEqual(protocol.parse_ids_pb(self.call(3910)[0][16:]), [2] * 8)

    def test_achievement_query_has_one_current_node_per_chain_and_real_progress(self):
        tasks = self.tasks()
        roots = {row["id"] for row in self.config["task"].values() if not row["needid"]}
        self.assertEqual(set(tasks), roots)
        self.assertEqual(tasks[50001], (1, self.session.save["role_state"]["level"]))
        self.assertEqual(tasks[51501], (0, 0))
        self.assertEqual(tasks[50101][0], 0)
        assets = copy.deepcopy(self.session.save["world_state"])
        self.tasks()
        self.assertEqual(self.session.save["world_state"], assets)

    def test_single_claim_unlocks_next_node_and_cannot_skip_or_claim_twice_after_reconnect(self):
        self.assert_rejected(2401, recharge.ids([50002]))
        before = self.props(20197)
        self.call(2401, [50001])
        self.assertEqual(self.props(20197), before + 1)
        tasks = self.tasks()
        self.assertNotIn(50001, tasks)
        self.assertEqual(tasks[50002][0], 1)
        self.session = self.reconnect()
        self.assert_rejected(2401, recharge.ids([50001]))

    def test_claim_all_only_claims_the_initial_frontier_and_rewards_match_each_claim(self):
        tasks = self.tasks()
        available = {cid for cid, (status, _) in tasks.items() if status == 1}
        self.call(2401)
        self.assertEqual(set(self.session.save["achievement_state"]["claimed"]), available)
        self.assertNotIn(50002, available)
        self.assertIn(50002, self.tasks())

    def test_achieved_milestones_survive_downgrades_and_use_best_rank_not_reverse_comparison(self):
        self.session.save["arena_state"]["rank"] = 5000
        self.checkpoint()
        self.session.save["arena_state"]["rank"] = 5364
        self.assertEqual(self.tasks()[50101][0], 1)
        self.call(2401, [50101])
        self.assertEqual(self.tasks()[50102][0], 0)

    def test_ordinary_progress_sources_do_not_modify_snapshots_or_count_protagonist(self):
        before = copy.deepcopy(self.session.save)
        view = achievements.snapshot(self.session.save, self.config)
        self.assertEqual(self.session.save, before)
        row = self.config["task"]["50501"]
        expected = sum(self.config["general"][str(protocol.pb_get_varint(raw, 1))]["quality"] >= 5
            for iid, raw in formation.records(bytes.fromhex(before["world_state"]["1002"]), 1, 2).items()
            if iid != protocol.pb_get_varint(bytes.fromhex(before["protagonist_snapshot"]), 1))
        self.assertEqual(achievements.progress(row, view)[0], expected)

    def test_every_supported_config_condition_checks_its_threshold_in_both_directions(self):
        supported = [row for row in self.config["task"].values() if row["type"] in achievements.SUPPORTED_TYPES]
        self.assertEqual(len(supported), 875)
        for row in supported:
            with self.subTest(cid=row["id"], kind=row["type"]):
                kind = row["type"]
                target = list(map(int, row["target"].split(",")))
                view = {"scalars": {}, "partners": [], "treasures": [], "sigils": [], "evolves": [], "copies": {}, "config": self.config}
                if kind == "copy":
                    self.assertIn(str(target[1]), self.config["copy"][str(target[0])])
                    raw = protocol.encode_pb_field(1, 0, target[1]) + protocol.encode_pb_field(3, 0, 1)
                    view["copies"][target[0]] = protocol.encode_pb_field(7, 2, raw)
                elif kind in ("general", "generalbreak"):
                    cid = next(r["generalid"] for r in self.config["general"].values()
                               if r["quality"] >= target[0] and r["battle"]) if kind == "general" else 10505
                    view["partners"] = [protocol.encode_pb_field(1, 0, cid) + protocol.encode_pb_field(4, 0, target[0])]
                    view["partners"] *= target[1]
                elif kind in ("treasurerefine", "treasurestrengthen"):
                    view["treasures"] = [[i + 1, 26102, target[0], target[0]] for i in range(target[1])]
                elif kind.startswith("equip_evolve"):
                    view["evolves"] = [target[0]] * int(kind[len("equip_evolve"):])
                elif kind.startswith("sigil"):
                    view["sigils"] = [target[0]] * int(kind[5:])
                else:
                    view["scalars"][kind] = target[-1]
                self.assertTrue(achievements.progress(row, view)[1])
                if kind == "copy":
                    view["copies"] = {}
                elif kind in ("general", "generalbreak"):
                    view["partners"].pop()
                elif kind in ("treasurerefine", "treasurestrengthen"):
                    view["treasures"].pop()
                elif kind.startswith("equip_evolve"):
                    view["evolves"][0] -= 1
                elif kind.startswith("sigil"):
                    view["sigils"][0] -= 1
                else:
                    view["scalars"][kind] += 1 if kind in ("athletics", "cuprank") else -1
                self.assertFalse(achievements.progress(row, view)[1])

    def test_paid_wash_counts_actual_rolls_not_stones_preview_restores_or_confirmations(self):
        self.session.save["role_state"]["level"] = 80
        iid = 9900001
        player.record_slot_update(self.session.save, protocol.encode_pb_field(2, 2, recharge.ids([iid, 21201, 1])))
        self.give(20222, 1000)
        preview = protocol.parse_ids_pb(self.call(1120, [iid, 1, 10])[0][16:])
        self.assertEqual(self.session.save["achievement_state"]["counts"]["equipbaptize"], 10)
        self.call(1120, [iid, 0, 0])
        self.call(1121, [0, iid, preview[13]])
        self.call(1124, [iid, 1, 20, 0, 0, 0, 0, 0])
        self.assertEqual(self.session.save["achievement_state"]["counts"]["equipbaptize"], 30)

    def test_actual_penglai_dice_and_pet_advancement_increment_only_successful_settlements(self):
        self.session.save["role_state"].update(level=50, coin=10000000)
        self.give(20262, 1)
        self.call(2121, [1])
        self.assertEqual(self.session.save["achievement_state"]["counts"]["penglairewardcount"], 1)
        previous = self.session.save["penglai_state"]["dice"]
        self.call(2128, [0])
        actual = self.session.save["penglai_state"]["dice"] - previous
        self.assertEqual(self.session.save["achievement_state"]["counts"]["penglairewardcount"], 1 + actual)
        self.give(91001, 1000)
        self.call(1049, [91001])
        pet = self.session.save["pet_state"]["pets"][0]
        for entry in self.config["pet3_attr"][str(pet[1])]["0"]["consume"].split(";"):
            if entry:
                cid, count = map(int, entry.split(","))
                if cid != 1000:
                    self.give(cid, count)
        self.call(1046, [pet[0]])
        self.assertEqual(self.session.save["achievement_state"]["counts"]["petbreakcount"], 1)

    def test_actual_rob_batch_counts_paid_attempts_including_losses_not_requested_ten(self):
        self.session.save["role_state"]["energy"] = 2
        fragments = formation.records(bytes.fromhex(self.session.save["world_state"]["1107"]), 1, 1)
        cid = next(int(cid) for cid in self.config["treasure2_fragment"]
                   if not protocol.pb_get_varint(fragments.get(int(cid), b""), 2))
        for raw in formation.records(bytes.fromhex(self.session.save["world_state"]["1002"]), 1, 2).values():
            for field in (6, 7, 8):
                raw = protocol.pb_set_varint(raw, field, 1)
            player.record_slot_update(self.session.save, protocol.encode_pb_field(1, 2, raw))
        self.call(1114, [rob.NPC_BASE + cid * 3])
        self.assertEqual(self.session.save["achievement_state"]["counts"]["robcount"], self.session.save["last_rob"]["attempts"])
        self.assertEqual((self.session.save["last_rob"]["attempts"], self.session.save["last_rob"]["wins"]), (2, 0))

    def test_cumulative_counts_are_lifetime_uncapped_and_unknown_history_is_not_invented(self):
        self.assertEqual(achievements.get_state(self.session.save, self.config)["counts"], {})
        achievements.record(self.session.save, "robcount", 31, self.config)
        self.checkpoint()
        self.assertEqual(self.tasks()[51701], (1, 31))
        with patch("time.time", return_value=test_penglai.NOW + 86400):
            self.checkpoint()
        self.assertEqual(self.tasks()[51701], (1, 31))

    def test_malformed_queries_claims_unimplemented_types_and_unmatched_combs_are_atomic(self):
        for opcode in (*collection.OPCODES, *achievements.OPCODES):
            for body in (b"\x08", b"\x0a\x00", b"\x10\x01", recharge.ids([0]), recharge.ids([1, 2])):
                self.assert_rejected(opcode, body)
        self.assert_rejected(2401, recharge.ids([51501]))
        for mid in (2401, 3911):
            comb = protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, mid)
                                             + protocol.encode_pb_field(2, 2, recharge.ids([1])))
            self.assert_rejected(999900, comb)

    def test_claim_save_failure_overflow_and_same_sequence_retry_do_not_duplicate_rewards(self):
        self.sequence += 1
        request = recharge.ids([50001])
        memory, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
            self.session.handle(2401, self.sequence, request)
        self.assertEqual((self.session.save, self.path.read_bytes()), (memory, disk))
        packets = self.session.handle(2401, self.sequence, request)
        memory, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        self.assertEqual(self.session.handle(2401, self.sequence, request), packets)
        self.assertEqual((self.session.save, self.path.read_bytes()), (memory, disk))
        self.give(20197, (1 << 31) - 1 - self.props(20197))
        self.assert_rejected(2401, recharge.ids([50002]))

    def test_recommendation_save_failure_retry_and_reward_overflow_keep_claim_and_inventory_atomic(self):
        for cid in (10505, 10409, 10549, 10415):
            self.add_general(cid)
        self.checkpoint()
        before, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        request = recharge.ids([1])
        with patch.object(player.os, "replace", side_effect=OSError("full")), self.assertRaises(OSError):
            self.session.handle(3911, 9000, request)
        self.assertEqual((self.session.save, self.path.read_bytes()), (before, disk))
        self.give(20100, (1 << 31) - 1 - self.props(20100))
        self.assert_rejected(3911, request)
        self.give(20100, -10)
        packets = self.session.handle(3911, 9000, request)
        before, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        self.assertEqual(self.session.handle(3911, 9000, request), packets)
        self.assertEqual((self.session.save, self.path.read_bytes()), (before, disk))

    def test_first_legacy_transaction_checkpoints_provable_before_state_without_reconstructing_old_counts(self):
        self.session.save.pop("achievement_state", None)
        self.session.save.pop("collection_state", None)
        self.session.save["role_state"]["power"] = 50000
        before = copy.deepcopy(self.session.save)
        working = copy.deepcopy(before)
        working["role_state"]["power"] = 0
        player.save_response_group([], working, before, self.path, self.steps, self.config, test_penglai.NOW)
        self.assertIn(53101, working["achievement_state"]["completed"])
        self.assertEqual(working["achievement_state"]["counts"], {})
        self.assertNotIn("achievement_state", before)

    def test_corrupt_collection_or_achievement_state_is_rejected_without_replacing_disk(self):
        for key, value in (("collection_state", {"generals": [True], "equips": [], "claimed": []}),
                           ("achievement_state", {"completed": [], "claimed": [50001], "counts": {}, "guild_level": 0})):
            baseline = self.path.read_bytes()
            self.path.write_text(json.dumps({**self.session.save, key: value}))
            bad = self.path.read_bytes()
            with self.assertRaises(ValueError):
                self.reconnect()
            self.assertEqual(self.path.read_bytes(), bad)
            self.path.write_bytes(baseline)

    def test_achievement_hint_44_matches_claimable_frontier_and_updates_after_claims(self):
        self.assertEqual(protocol.parse_ids_pb(self.call(1032, [44])[0][16:]), [1])
        self.call(2401)
        while any(status == 1 for status, _ in self.tasks().values()):
            self.call(2401)
        self.assertEqual(protocol.parse_ids_pb(self.call(1032, [44])[0][16:]), [0])

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
        for name in ("idnums_pb", "tasks_pb", "error_pb", "params_pb"):
            lua.execute(builder.read_script(name, "pb"))
        code = builder.read_script("gamedata").decode().replace("\r\n", "\n")
        for start, end in (("function gamedata.GeneralCollect(", "function gamedata.SingleBoss("),
                           ("function gamedata.taskData(", "function gamedata.Penglai3(")):
            lua.execute(code[code.index(start):code.index(end)].encode())
        lua.execute(b'''gamedata.cache.generalcollect={};gamedata.cache.equipcollect={};gamedata.cache.task={}
            package.loaded.logError={errorMessage={},errorFunc={}};printf=function() end
            initPb=function(mod,fd) local m=mod.Ids();m:ParseFromString(fd.rbuf);return m end''')
        lua.execute(b"package.preload.GameTask=function()\n" + builder.read_script("GameTask") + b"\nend")
        lua.execute(self.client_scripts()["assets/scripts/GameCollect.so"])
        lua.execute(self.client_scripts()["assets/common_lua/GameErrorMessage.so"])
        self.assertIsNone(lua.globals().gameConfig)
        return lua

    def client_call(self, lua, send, receive, request):
        mode, opcode, body = getattr(lua.globals(), send)(lua.table_from({k.encode(): v for k, v in request.items()}))
        self.assertEqual(mode, 1)
        self.sequence += 1
        packet = self.session.handle(opcode, self.sequence, body or b"")[0]
        self.assertEqual(struct.unpack(">IIII", packet[:16])[2], opcode)
        return getattr(lua.globals(), receive)(lua.table_from({b"rbuf": packet[16:]}))

    def test_actual_network_lua_decodes_catalogues_tasks_claims_and_replaces_full_caches(self):
        lua = self.network_lua()
        lua.globals().gamedata[b"cache"][b"generalcollect"][999999] = 1
        result = self.client_call(lua, "UIGeneralCollectCallBack", "NetGeneralCollectCallBack", {"view": 3})
        self.assertEqual((result[b"view"], len(list(result[b"generalcollect"].items()))), (3, 215))
        self.assertIsNone(result[b"generalcollect"][999999])
        result = self.client_call(lua, "UIEquipCollectCallBack", "NetEquipCollectCallBack", {"view": 3})
        self.assertEqual(len(list(result[b"equipcollect"].items())), 179)
        self.client_call(lua, "UITaskQueryCallBack", "NetTaskQueryCallBack", {"view": 7})
        result = self.client_call(lua, "UITaskCompleteCallBack", "NetTaskCompleteCallBack", {"id": 50001, "view": 7})
        self.assertEqual(result[b"view"], 7)
        result = self.client_call(lua, "UITaskQueryCallBack", "NetTaskQueryCallBack", {"view": 7})
        self.assertIsNone(result[b"task"][50001])
        self.assertIsNotNone(result[b"task"][50002])
        for cid in (10505, 10409, 10549, 10415):
            self.add_general(cid)
        self.checkpoint()
        self.client_call(lua, "UITeamRecomQueryCallBack", "NetTeamRecomQueryCallBack", {"view": 3})
        result = self.client_call(lua, "UITeamRecomRewardCallBack", "NetTeamRecomRewardCallBack", {"id": 1, "view": 3})
        self.assertEqual(result[b"teamRecomQuery"][1], 2)

    def test_actual_lua_claim_lock_fifo_context_and_native_errors_never_retry_blindly(self):
        lua = self.network_lua()
        request = lua.table_from({b"view": 1, b"id": 50001})
        self.assertEqual(lua.globals().UITaskCompleteCallBack(request)[0], 1)
        self.assertEqual(lua.globals().UITaskCompleteCallBack(request)[0], 0)
        self.assertEqual(lua.globals().UITeamRecomRewardCallBack(lua.table_from({b"id": 1}))[0], 0)
        lua.globals().NetErrorMessageCallback9(lua.table_from({b"rbuf": recharge.ids([2401, 0])}))
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localProgressBusy"])
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localProgressPending"][2401])
        for view in (1, 2):
            self.assertEqual(lua.globals().UITaskQueryCallBack(lua.table_from({b"view": view}))[0], 1)
        self.assertEqual(lua.globals().UITaskQueryCallBack(lua.table_from({b"view": 2}))[0], 0)
        for view in (1, 2):
            reply = lua.globals().NetTaskQueryCallBack(lua.table_from({b"rbuf": self.call(2400)[0][16:]}))
            self.assertEqual(reply[b"view"], view)

    def ui_lua(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("实际图鉴/成就界面验证需要lupa.lua51")
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.globals().gamedata = lua.table_from({"config": self.config}, recursive=True)
        lua.execute('''print=function() end;printT=print;CCControlEventTouchUpInside=1
            table.getTableLength=function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
            requests={};UIRequest=function(t) requests[#requests+1]=t end
            function node() return setmetatable({size={width=1080,height=1920}}, {__index=function(t,k)
                if k=="addHandleOfControlEvent" then return function(self,f) self.callback=f end end
                if k=="getContentSize" then return function(self) return self.size end end
                if k=="getScale" then return function() return 1 end end
                if k=="getPositionX" or k=="getPositionY" then return function() return 0 end end
                return function() end
            end}) end
            function items() return setmetatable({}, {__index=function(t,k) local n=node();rawset(t,k,n);return n end}) end
            CCBReaderLoad=function() return node(),items() end
            CCSizeMake=function(w,h) return {width=w,height=h} end
            gamedata.config.getConfigByName=function(self,name) return self[name] end
            ui=setmetatable({getGeneralID=function() return {} end,getIDandDesc=function() return {} end,
                getIDandNUMs=function() return {} end,IDconfig=function() return {icon="x",name="x"} end},
                {__index=function() return function() end end})
            setSpriteFrameByName=function() end
            gameConfig={originSize={width=1080,height=1920},maiscenebottomheight=100,
                strings={string_common=function() return "图鉴" end,getAward=function() return "奖励" end}}
            gameTouch={rigistFunc=function() end,UnrigistFunc=function() end}
            GameScene={topposY=1920,layers={}}
            gameWindows={windows={roleinfo={show=false}}}
            showRewardPopupWindow=function(reward,_,callback) popups=(popups or 0)+1;if callback then callback() end end''')
        scripts = self.client_scripts()
        album = lua.execute(scripts["assets/scripts/Layer_collect.so"].decode())
        tasks = lua.execute(scripts["assets/scripts/Layer_achievement.so"].decode())
        lua.globals().GameScene.layers.collect = lua.table_from({"show": True, "module": album})
        lua.globals().GameScene.layers.achievement = lua.table_from({"show": True, "module": tasks})
        lua.execute(scripts["assets/scripts/UICollect.so"].decode())
        lua.execute(scripts["assets/scripts/UITask.so"].decode())
        album.init(album, lua.globals().node(), 1920, None)
        tasks.init(tasks, lua.globals().node(), 1920)
        return lua, album, tasks

    def test_actual_pages_bind_claim_buttons_and_discard_closed_or_old_generation_replies(self):
        lua, album, tasks = self.ui_lua()
        self.assertEqual((lua.globals().requests[1].type, lua.globals().requests[1].view), (1015, album.localCollectionView))
        self.assertEqual((lua.globals().requests[2].type, lua.globals().requests[2].view), (2400, tasks.localAchievementView))
        tasks.activennum = 1
        tasks.rootItems.allbutton.callback()
        self.assertEqual((lua.globals().requests[3].type, lua.globals().requests[3].view), (2401, tasks.localAchievementView))
        tasks.isscrolltouched = True
        item = lua.globals()["items"]()
        tasks.setCell(tasks, item, lua.table_from({"cid": 50001, "status": 1, "now": 22}))
        item.button.callback()
        self.assertEqual(lua.globals().requests[4].id, 50001)
        tasks.reloaddata = lua.eval("function(self,t) self.reloaded=true end")
        album.reloadgeneralData = lua.eval("function(self,t) self.reloaded=true end")
        old_album, old_tasks = album.localCollectionView, tasks.localAchievementView
        album.clear(album)
        tasks.clear(tasks)
        lua.globals().UIGeneralCollect(lua.table_from({"view": old_album}))
        lua.globals().UITaskQuery(lua.table_from({"view": old_tasks}))
        lua.globals().UITaskComplete(lua.table_from({"view": old_tasks}))
        self.assertIsNone(album.reloaded)
        self.assertIsNone(tasks.reloaded)
        self.assertIsNone(lua.globals().popups)
        album.init(album, lua.globals().node(), 1920, None)
        tasks.init(tasks, lua.globals().node(), 1920)
        lua.globals().UITaskQuery(lua.table_from({"view": old_tasks}))
        self.assertIsNone(tasks.reloaded)
        lua.globals().UITaskQuery(lua.table_from({"view": tasks.localAchievementView}))
        self.assertTrue(tasks.reloaded)
        lua.globals().UITaskComplete(lua.table_from({"view": tasks.localAchievementView, "reward": {}}))
        request = lua.globals().requests[len(lua.globals().requests)]
        self.assertEqual((request.type, request.view), (2400, tasks.localAchievementView))


class GuildAchievementTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        test_guild.setUpModule()

    def setUp(self):
        test_guild.GuildFeatureTests.setUp(self)

    request = test_guild.GuildFeatureTests.request
    success = test_guild.GuildFeatureTests.success
    shared = test_guild.GuildFeatureTests.shared
    update_guild = test_guild.GuildFeatureTests.update_guild
    level = test_guild.GuildFeatureTests.level
    give = test_guild.GuildFeatureTests.give
    reconnect = test_guild.GuildFeatureTests.reconnect

    def task_rows(self, account=1):
        return {protocol.pb_get_varint(raw, 1): (protocol.pb_get_varint(raw, 2), protocol.pb_get_varint(raw, 3))
                for n, w, raw in protocol.iter_pb_fields(self.success(account, 2400)) if (n, w) == (1, 2)}

    def test_current_guild_level_is_account_bound_readonly_and_claims_survive_membership_changes(self):
        self.level(2)
        disk = self.store.path(2).read_bytes()
        shared = (self.root / "guilds.json").read_bytes()
        self.assertEqual(self.task_rows()[50601], (1, 2))
        self.assertEqual((self.store.path(2).read_bytes(), (self.root / "guilds.json").read_bytes()), (disk, shared))
        self.success(1, 2401, values=[50601])
        self.reconnect()
        self.assertNotIn(50601, self.task_rows())
        self.assertEqual(self.task_rows()[50602][0], 0)

    def test_incense_and_soap_counts_commit_with_costs_survive_day_reset_and_rollback_on_failed_save(self):
        self.success(1, 2251, values=[1])
        self.give(20162, 10)
        self.success(1, 2257, values=[20162, 3])
        state = self.sessions[1].save["achievement_state"]["counts"]
        self.assertEqual((state["gang_incense"], state["gang_fishpond"]), (1, 3))
        before = copy.deepcopy(self.sessions[1].save)
        with patch.object(player.os, "replace", side_effect=OSError("full")), self.assertRaises(OSError):
            self.request(1, 2257, values=[20162, 1])
        self.assertEqual(self.sessions[1].save, before)
        self.reconnect()
        with patch("time.time", return_value=self.now + 86400):
            self.success(1, 2250)
        self.assertEqual(self.sessions[1].save["achievement_state"]["counts"], state)


if __name__ == "__main__":
    unittest.main()
