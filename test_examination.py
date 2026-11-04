"""三界联考：原题库、真实计时、临时多账号排名／邮件与失败恢复。"""

import copy
from datetime import datetime, timedelta, timezone
import json
import unittest
from unittest.mock import patch

import build_local_apk as builder
import test_soul
from zyj_server import achievements, examination, player, protocol, recharge


def setUpModule():
    test_soul.setUpModule()


class ExaminationTests(unittest.TestCase):
    request = test_soul.SoulTests.request
    success = test_soul.SoulTests.success
    reconnect = test_soul.SoulTests.reconnect
    add_account = test_soul.SoulTests.add_account
    assert_rejected = test_soul.SoulTests.assert_rejected
    refresh = test_soul.SoulTests.refresh
    props = test_soul.SoulTests.props
    records = test_soul.SoulTests.records
    groups = test_soul.SoulTests.groups
    client_scripts = classmethod(test_soul.SoulTests.client_scripts.__func__)
    network_lua = test_soul.SoulTests.network_lua
    client_call = test_soul.SoulTests.client_call

    def setUp(self):
        test_soul.SoulTests.setUp(self)
        self.save["role_state"]["level"] = 125

    def start(self, kind=1, account=1):
        values = protocol.parse_ids_pb(self.success(account, 7003, values=[kind]))
        self.refresh()
        return values

    def answer(self, cid, kind=1, account=1, right=True, elapsed=.5, timestamp=0):
        self.clock.return_value += elapsed
        subject = self.config["sanjie_subject_config"][str(cid)]
        values = [kind, cid, subject["answer1" if right else "answer2"], timestamp]
        result = protocol.parse_ids_pb(self.success(account, 7004, values=values))
        self.refresh()
        return result, values

    def saturday(self):
        self.clock.return_value = datetime(2026, 11, 7, 18, tzinfo=timezone(timedelta(hours=8))).timestamp()

    def journal(self):
        return json.loads((self.root / "examinations.json").read_bytes())

    def test_real_ten_question_practice_rewards_progress_and_full_marks_survive_reconnect(self):
        before = copy.deepcopy(self.save)
        for index in range(10):
            started = self.start()
            cid = started[0]
            self.assertIn("1", self.config["sanjie_subject_config"][str(cid)]["type"].split(";"))
            self.assertGreater(started[1], int(self.clock.return_value * 1000))
            reply, _ = self.answer(cid)
            self.assertEqual((reply[0], reply[5], reply[6]), (1, index + 1, index + 1))
        self.assertEqual(self.save["role_state"]["coin"] - before["role_state"]["coin"], 2500000)
        self.assertEqual(self.save["role_state"]["exp"] - before["role_state"]["exp"], 60000)
        self.assertEqual(self.save["achievement_state"]["counts"]["question_fullmarks"], 1)
        for key in ("gold", "stamina", "energy"):
            self.assertEqual(self.save["role_state"][key], before["role_state"][key])
        self.assertEqual(self.save["world_state"]["1300"], before["world_state"]["1300"])
        self.reconnect(); self.refresh()
        values = protocol.parse_ids_pb(self.success(1, 7002))
        self.assertEqual((values[1], values[2], values[3], values[6]), (3, 10, 10, 1000))
        self.assert_rejected(7003, values=[1])

    def test_server_clock_and_real_answer_not_client_time_determine_correctness_and_reward(self):
        first = self.start()[0]
        reply, _ = self.answer(first, timestamp=(1 << 31) - 1)
        self.assertEqual(reply[0], 1)
        second = self.start()[0]
        reply, _ = self.answer(second, right=False, elapsed=1)
        self.assertEqual(reply[0], 0)
        third = self.start()[0]
        reply, _ = self.answer(third, elapsed=31, timestamp=1)
        self.assertEqual(reply[0], 0)
        self.assertEqual(reply[6], 1)
        self.assertEqual(reply[1:3], [6000 + 4800 * 2, 250000 + 25000 * 2])

    def test_real_role_level_up_keeps_main_general_xp_and_next_day_practice_starts_fresh(self):
        self.save["role_state"].update(level=31, exp=self.config["role_exp"]["31"]["nextexp"] - 1)
        before = copy.deepcopy(self.save)
        cid = self.start()[0]
        self.answer(cid)
        self.assertEqual(self.save["role_state"]["level"], 32)
        self.assertEqual(self.save["role_state"]["exp"], 5999)
        self.assertEqual(self.save["world_state"]["1002"], before["world_state"]["1002"])
        self.assertEqual(self.save["world_state"]["1300"], before["world_state"]["1300"])
        self.clock.return_value += 86400
        values = protocol.parse_ids_pb(self.success(1, 7002))
        self.assertEqual(values[1:7], [1, 0, 0, 0, 0, 0])
        self.assertEqual(self.start()[6:], [1, 0])

    def test_reconnect_and_repeated_start_do_not_extend_deadline_or_repeat_answer_rewards(self):
        first = self.start()
        self.clock.return_value += 2
        self.assertEqual(self.start()[:2], first[:2])
        self.reconnect(); self.refresh()
        self.assertEqual(self.start()[:2], first[:2])
        reply, request = self.answer(first[0])
        before = copy.deepcopy(self.save["role_state"])
        self.reconnect(); self.refresh()
        repeated = protocol.parse_ids_pb(self.success(1, 7004, values=request)); self.refresh()
        self.assertEqual(repeated, reply)
        self.assertEqual(self.save["role_state"], before)
        request[2] = self.config["sanjie_subject_config"][str(first[0])]["answer2"]
        self.assert_rejected(7004, values=request)

    def test_level_schedule_bad_payload_and_rollback_rejections_are_non_mutating(self):
        for opcode, values in ((7002, [1]), (7003, []), (7003, [4]), (7004, [1, 1, 1]), (7005, [1]), (7005, [2, 0])):
            self.assert_rejected(opcode, values=values)
        for opcode in examination.OPCODES:
            self.assert_rejected(opcode, raw=b"\x10\x01")
        self.save["role_state"]["level"] = 9
        self.assert_rejected(7003, values=[1])
        self.save["role_state"]["level"] = 125
        self.assert_rejected(7003, values=[2])
        cid = self.start()[0]
        self.clock.return_value -= 1
        self.assert_rejected(7004, values=[1, cid, self.config["sanjie_subject_config"][str(cid)]["answer1"], 0])

    def test_same_connection_retry_and_save_failure_do_not_duplicate_xp_coin_or_score(self):
        cid = self.start()[0]
        body = recharge.ids([1, cid, self.config["sanjie_subject_config"][str(cid)]["answer1"], 0])
        before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.sessions[1].handle(7004, 999, body)
        self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))
        self.reconnect(); self.refresh()
        packets = self.sessions[1].handle(7004, 999, body)
        self.assertEqual(protocol.parse_ids_pb(packets[0][16:])[0], 1)
        before, disk = copy.deepcopy(self.sessions[1].save), self.store.path(1).read_bytes()
        self.assertEqual(self.sessions[1].handle(7004, 999, body), packets)
        self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))

    def test_coin_and_capped_xp_overflow_roll_back_answer_and_public_draft_write_failure_is_safe(self):
        before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
        with patch.object(examination, "write", side_effect=OSError("disk full")), self.assertRaises(OSError):
            self.start()
        self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))
        self.assertFalse((self.root / "examinations.json").exists())
        cid = self.start()[0]
        values = [1, cid, self.config["sanjie_subject_config"][str(cid)]["answer1"], 0]
        self.save["role_state"]["coin"] = (1 << 63) - 1
        self.assert_rejected(7004, values=values)
        self.save["role_state"].update(coin=1000000, level=150, exp=(1 << 31) - 1)
        self.assert_rejected(7004, values=values)

    def test_paid_role_receipt_recovers_interrupted_publication_without_regrading_or_rewarding(self):
        cid = self.start()[0]
        write = examination.write
        calls = []

        def fail_publish(*args):
            calls.append(True)
            if len(calls) == 2:
                raise OSError("publish failed")
            return write(*args)

        with patch.object(examination, "write", side_effect=fail_publish), self.assertRaises(OSError):
            self.answer(cid)
        saved = json.loads(self.store.path(1).read_bytes())
        self.assertEqual(len(saved["examination_state"]["records"]["1"]["answers"]), 1)
        self.reconnect(); self.refresh()
        self.success(1, 7002); self.refresh()
        self.assertIsNone(self.journal()["pending"])
        self.assertEqual(self.save["role_state"]["coin"], saved["role_state"]["coin"])

    def test_weekly_ranks_freeze_real_participants_and_native_mail_claims_once_without_writing_peers(self):
        self.saturday()
        for account in (1, 2):
            cid = self.start(2, account)[0]
            self.answer(cid, kind=2, account=account, elapsed=1)
        peer = self.store.path(2).read_bytes()
        rows = self.records(self.success(1, 7005, values=[2]))
        self.assertEqual(len(rows), 3)
        self.clock.return_value = datetime(2026, 11, 7, 22, tzinfo=timezone(timedelta(hours=8))).timestamp()
        self.success(1, 7005, values=[2])
        mails = self.records(self.success(1, 3100), 2)
        exam = [v for v in mails if 500000001 <= protocol.pb_get_varint(v, 1) < 600000000]
        self.assertEqual(len(exam), 1)
        mid = protocol.pb_get_varint(exam[0], 1)
        self.assert_rejected(3102, values=[mid])
        self.refresh(); gold = self.save["role_state"]["gold"]
        self.success(1, 3101, values=[mid]); self.refresh()
        self.assertEqual(self.save["role_state"]["gold"] - gold, 500)
        self.assert_rejected(3101, values=[mid])
        self.success(1, 2400); self.refresh()
        self.assertEqual(self.save["achievement_state"]["counts"]["question_week_one"], 1)
        self.assertEqual(self.store.path(2).read_bytes(), peer)
        self.reconnect(); self.success(1, 3102, values=[mid])

    def test_monthly_zero_points_not_ranked_and_weekly_zero_points_are_real_participation(self):
        self.saturday()
        self.start(2)
        self.clock.return_value += 4 * 3600
        self.success(1, 7005, values=[2])
        self.assertEqual(len(self.journal()["mails"]), 1)
        start, _ = examination.window(3, int(self.clock.return_value), self.journal()["opened_day"], self.config)
        if start < self.clock.return_value:
            start += 28 * 86400
        self.clock.return_value = start + 1
        self.start(3)
        self.clock.return_value = start + 4 * 3600
        self.assertEqual(len(self.records(self.success(1, 7005, values=[3]))), 1)
        self.assertEqual(len(self.journal()["mails"]), 1)

    def test_recreated_identity_does_not_claim_old_exam_mail_and_failed_mail_claim_keeps_flags(self):
        self.saturday()
        self.start(2)
        self.clock.return_value += 4 * 3600
        self.success(1, 7005, values=[2]); self.refresh()
        mid = min(map(int, self.journal()["mails"]))
        self.save["role_state"]["coin"] = (1 << 63) - 1
        self.assert_rejected(3101, values=[mid])
        self.save["role_state"]["coin"] = 200000000
        before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 3101, values=[mid])
        self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))
        self.store.close_session(1)
        fresh = copy.deepcopy(self.save)
        fresh["created_at"] += 1
        fresh.pop("examination_state")
        player.save_role(fresh, self.store.path(1), {})
        self.sessions[1] = self.store.open_session(1, "test-password", ("same-address", 1))
        self.refresh()
        self.assert_rejected(3101, values=[mid])

    def test_lost_corrupt_shared_journal_and_corrupt_personal_answers_fail_closed(self):
        self.start()
        path = self.root / "examinations.json"
        original = path.read_bytes()
        path.write_bytes(b"{broken")
        self.assert_rejected(7002)
        path.unlink()
        self.assert_rejected(7002)
        path.write_bytes(original)
        self.save["examination_state"]["records"]["1"]["ids"] = [1] * 10
        self.assert_rejected(7002)

    def test_three_real_monthly_places_publish_all_rank_achievement_sources_once(self):
        self.saturday()
        self.start(2)
        opened = self.journal()["opened_day"]
        start, _ = examination.window(3, int(self.clock.return_value), opened, self.config)
        if start < self.clock.return_value:
            start += 28 * 86400
        self.clock.return_value = start + 1
        for account in (1, 2, 3):
            cid = self.start(3, account)[0]
            self.answer(cid, kind=3, account=account, elapsed=1)
        self.clock.return_value = start + 4 * 3600
        self.success(1, 7005, values=[3])
        for account, place in ((1, "one"), (2, "two"), (3, "three")):
            for _ in range(2):
                self.success(account, 2400)
            counts = self.sessions[account].save["achievement_state"]["counts"]
            self.assertEqual(counts["question_monthcount"], 1)
            self.assertEqual(counts["question_monthtop50"], 1)
            self.assertEqual(counts["question_month_" + place], 1)
        types = {row["type"] for row in self.config["task"].values() if row["type"].startswith("question_")}
        self.assertEqual(types - set(achievements.COUNTERS), set())

    def test_all_original_questions_reference_text_and_correct_option_and_utc8_schedule_boundaries(self):
        self.assertEqual(len(self.config["sanjie_subject_config"]), 292)
        for row in self.config["sanjie_subject_config"].values():
            for key in ("subject", "answer1", "answer2", "answer3", "answer4"):
                self.assertIn(str(row[key]), self.config["sanjie_subject_text"])
        self.saturday()
        now = int(self.clock.return_value)
        start, end = examination.window(2, now, examination.opened_day(self.save), self.config)
        self.assertEqual((start, end), (now, now + 4 * 3600))
        first, _ = examination.window(3, now, examination.opened_day(self.save), self.config)
        following, _ = examination.window(3, first + 28 * 86400, examination.opened_day(self.save), self.config)
        self.assertEqual(following - first, 28 * 86400)

    def test_actual_native_pb_status_start_answer_and_rank_keep_fifo_context_and_error_locks(self):
        lua = self.network_lua(native_protobuf=True)
        lua.eval(b"require")(b"GameExamination")
        self.client_call(lua, 1, "UIExaminationStatusCallBack", "NetExaminationStatusCallBack", {"examinationView": 1})
        fd = lambda raw: lua.table_from({b"rbuf": raw})
        result = self.client_call(lua, 1, "UIExaminationStartCallBack", "NetExaminationStartCallBack", {"timuType": 1, "examinationView": 1})
        cid = result[b"timuid"]
        self.assertGreaterEqual(result[b"endtimes"], self.clock.return_value + 29)
        request = lua.table_from({b"timuType": 1, b"timuid": cid,
            b"answerid": str(self.config["sanjie_subject_config"][str(cid)]["answer1"]).encode(), b"timestap": 0, b"examinationView": 1})
        mode, opcode, raw = lua.globals().UIExaminationEndCallBack(request)
        self.assertEqual((mode, opcode), (1, 7004))
        self.assertEqual(lua.globals().UIExaminationStartCallBack(lua.table_from({b"timuType": 2}))[0], 0)
        lua.globals().NetErrorMessageCallback9(fd(recharge.ids([7003, 0])))
        self.assertEqual(lua.globals().gamedata[b"ext"][b"localExaminationBusy"], 7004)
        result = lua.globals().NetExaminationEndCallBack(fd(self.success(1, opcode, raw=raw)))
        self.assertEqual((result[b"result"], result[b"examKind"], result[b"examQuestion"], result[b"examinationView"]), (1, 1, cid, 1))
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localExaminationBusy"])
        for view in (2, 3):
            lua.globals().UIExaminationStatusCallBack(lua.table_from({b"examinationView": view}))
        for view in (2, 3):
            result = lua.globals().NetExaminationStatusCallBack(fd(self.success(1, 7002)))
            self.assertEqual(result[b"examinationView"], view)
        self.saturday()
        self.start(2)
        result = self.client_call(lua, 1, "UIExaminationPaihangbangCallBack", "NetExaminationPaihangbangCallBack", {"ranktype": 2, "examinationView": 8})
        self.assertEqual(len(result[b"data"]), 2)
        self.assertEqual(result[b"data"][1][b"params"][4][b"i"], 1)
        self.assertEqual(result[b"data"][2][b"params"][1][b"i"], 0)
        self.assertIsNone(lua.globals().gameConfig)

    def test_actual_ui_generations_timer_uses_real_deadline_and_does_not_retry_unknown_answers(self):
        from lupa.lua51 import LuaRuntime
        scripts = self.client_scripts()
        lua = LuaRuntime()
        for name in ("GameExamination", "UIExamination", "Layer_examination", "window_examinnationRank"):
            lua.compile(scripts[f"assets/scripts/{name}.so"].decode())
        page = lua.execute(scripts["assets/scripts/Layer_examination.so"].decode())
        lua.globals().page = page
        lua.execute('''print=function() end;printT=print
            requests={};UIRequest=function(t) requests[#requests+1]=t end
            page.rootNode={};page.localExaminationGeneration=1;page.currenntKaoshitype=1;page.timuid=10
            page.reload=function(self) self.reloads=(self.reloads or 0)+1 end
            page.startKaoshi=function(self) self.starts=(self.starts or 0)+1 end
            page.endKaoshi=function(self) self.answers=(self.answers or 0)+1 end
            package.loaded.Layer_examination=page
            window={rootNode={},localExaminationGeneration=1,phtype=2,reload=function(self) self.reloads=(self.reloads or 0)+1 end}
            package.loaded.window_examinnationRank=window
            GameScene={layers={examination={show=true,module=page},main={show=true,module={sanjieliankaoUpdateTime=function() end}}}}
            gameWindows={windows={examinationrank={show=true,module=window}}}
        ''')
        lua.execute(scripts["assets/scripts/UIExamination.so"].decode())
        lua.execute('''UIRequest({type=7003,timuType=1});local view=requests[1].examinationView
            UIExaminationStart({examKind=1,examinationView=view});assert(page.starts==1)
            UIExaminationEnd({examKind=1,examQuestion=11,examinationView=view});assert(not page.answers)
            UIExaminationEnd({examKind=1,examQuestion=10,examinationView=view});assert(page.answers==1)
            UExaminationPaihangbang({examKind=2,examinationView=view});assert(window.reloads==1)
            window.localExaminationGeneration=2
            UExaminationPaihangbang({examKind=2,examinationView=view});assert(window.reloads==1)
            page.localExaminationGeneration=2
            UIExaminationStart({examKind=1,examinationView=view});assert(page.starts==1)
        ''')
        lua.execute('''now=100;gamedata={time=function() return now end}
            timers={};gameTimer={rigistTime=function() end,UnrigistTimeFunc=function(self,key) timers[key]=nil end,
                rigistTimeFunc=function(self,key,f) timers[key]=f end}
            ui={makeTimeText=function(n) return n end};ccc3=function(...) return {...} end
            page.rootItems={daojishiTime={setColor=function() end,setString=function(self,n) self.text=n end}}
            page.items={yongshi={setString=function(self,n) self.text=n end}}
            page.result={1001,1002,1003,1004};page.rightAnswerIndex=1;page.userClickAnswerIndex=0
            page.selectAnswer=function(self,index) self.selected=index end
        ''')
        page.countdowntime(page, 130)
        page.totaltime(page, 7)
        lua.execute('''for i=1,100 do timers.examination_countdown_flesh();timers.examination_total_flesh() end
            assert(page.countdowntimes==30 and page.times==7 and not page.selected)
            now=131;timers.examination_countdown_flesh();assert(page.selected==2 and page.countdowntimes==0)
            timers.examination_total_flesh();assert(page.times==38)
            page.localExaminationGeneration=3;now=132;timers.examination_total_flesh();assert(page.times==38)
            page.examination_requestId=7004;page.examination_requestTimuType=1
            page:checkRequestTimeOut();assert(#requests==1)
        ''')


if __name__ == "__main__":
    unittest.main()
