"""处理一条连接的请求，返回有序的完整协议帧；不持有 socket。"""

import copy
import functools
import struct
import time

from . import activities, activity_copy, arena, blackmarket, cornucopia, daily_events, development, equip_baptize, fashion, favorite, friend_copy, general_foster, guide, guild, hades_copy, magic, mieshendian, online_rewards, penglai, pets, player, qiankun, ranking, recharge, recruit, resource_purchase, rob, secret_shop, shop, sigil, single_boss, star_copy, timebag, training, treasure_refine, watchstar, welfare, world_boss
from . import cheer, cup, equip_evolve, friends, guild_chat, soul
from . import skytoken, achievements, antique, artifact, ascension_sendai, babel_tower, champion, collection, cover, deployment, dragon_wishing, examination, exchange, game_helper, gamestar, illusion, nightclub, partner_growth, pending_features, wing
from .protocol import encode_pb_field, get_comb_ids, get_comb_messages, iter_pb_fields, pack_frame, pb_set_field
from .replay import Replay, normalize_comb_request

print_flush = functools.partial(print, flush=True)


def unavailable_response(opcode, seq, body, message):
    print_flush(f"  [!] {message} (Opcode={opcode}, Seq={seq}, hex={body.hex()})")
    # 原生 9999 UI 错误清除 loading；1999 广播补充可读原因，避免走成功解析器。
    error = encode_pb_field(1, 0, opcode) + encode_pb_field(1, 0, 0)
    return [pack_frame(999999, seq, error), pack_frame(1999, 0, encode_pb_field(1, 2, message.encode("utf-8")))]


class Session:
    def __init__(self, tables, save_path, step_counts, role_config, growth_buyers=None, rank_query=None, rank_observer=None, guild_request=None, friend_request=None, cup_request=None, world_boss_request=None):
        self.replay = Replay(tables)
        self.save_path = save_path
        self.step_counts = step_counts
        self.role_config = role_config
        self.growth_buyers = growth_buyers
        self.rank_query = rank_query
        self.rank_observer = rank_observer
        self.guild_request = guild_request
        self.friend_request = friend_request
        self.cup_request = cup_request
        self.world_boss_request = world_boss_request
        self.guild_profit = None
        self.guild_level = None
        self.cup_rank = None
        self.examination_request = None
        self.examination_ranks = None
        self.random_replies = {}
        self.connected_at = int(time.time())
        self.refresh_day = (self.connected_at + 28800) // 86400
        self.save = player.load_save(save_path, step_counts)
        player.initialize_world_state(self.save, self.replay.master_comb_packets)
        activities.get_state(self.save)
        recruit.get_state(self.save)
        recruit.get_pending(self.save)
        recharge.get_state(self.save)
        shop.get_state(self.save)
        fashion.get_state(self.save, role_config)
        online_rewards.get_state(self.save, role_config)
        welfare.get_state(self.save)
        daily_events.get_state(self.save)
        star_copy.get_state(self.save, role_config)
        hades_copy.get_state(self.save, role_config)
        friend_copy.get_state(self.save, role_config)
        activity_copy.get_state(self.save, role_config)
        arena.get_state(self.save, role_config)
        champion.get_state(self.save, role_config)
        mieshendian.get_state(self.save, role_config)
        blackmarket.get_state(self.save, role_config)
        watchstar.get_state(self.save, role_config)
        resource_purchase.get_state(self.save)
        qiankun.get_state(self.save)
        secret_shop.get_state(self.save, role_config)
        guild.daily_state(self.save)
        friends.daily(self.save)
        cup.get_state(self.save)
        world_boss.get_state(self.save)
        examination.get_state(self.save, role_config)
        soul.get_state(self.save)
        equip_evolve.get_version(self.save)
        game_helper.receipt(self.save)
        artifact.get_state(self.save, role_config)
        antique.get_state(self.save, role_config)
        wing.get_state(self.save, role_config)
        cover.get_state(self.save, role_config)
        gamestar.get_state(self.save, role_config)
        deployment.get_state(self.save, role_config)
        partner_growth.state(self.save, role_config)
        illusion.get_state(self.save, role_config)
        illusion.validate_ownership(self.save, role_config)
        collection.get_state(self.save, role_config)
        achievements.get_state(self.save, role_config)
        pets.get_state(self.save, role_config)
        favorite.get_state(self.save, role_config)
        cornucopia.get_state(self.save, role_config)
        penglai.get_state(self.save, role_config)
        nightclub.get_state(self.save, role_config)
        dragon_wishing.get_state(self.save, role_config)
        single_boss.get_state(self.save, role_config)
        equip_baptize.get_state(self.save, role_config)
        magic.get_state(self.save, role_config)
        sigil_state = sigil.get_state(self.save, role_config)
        self.sigil_auto_pending = sigil_state["auto_level"] if sigil_state["auto_state"] else None
        for gift_id in timebag.GIFTS:
            timebag.get_state(self.save, gift_id)
        if self.save.get("has_role"):
            player.get_role_state(self.save, role_config)
        cheer.assigned(self.save, role_config)
        player.validate_stamina_clock(self.save)

        sections = guide.get_guide_sections(self.save, step_counts)
        in_progress = [s for s in sections.values() if s.get("status") == 1]
        if sections and not in_progress:
            print_flush(f"[★] 状态: 玩家【{self.save.get('role_name', '主角')}】引导段均已完结，直接进入主城！")
        elif in_progress:
            print_flush(f"[★] 状态: 玩家【{self.save.get('role_name', '未命名')}】断点续玩 -> {guide.describe_guide(sections, step_counts)}")
        else:
            print_flush("[★] 状态: 全新玩家连入，正常跑完整新手流程 (剧情动画 -> 起名 -> 选将 -> 第一战)！")

    def handle(self, opcode, seq, body):
        before = copy.deepcopy(self.save) if self.rank_observer else None
        packets = self._handle(opcode, seq, body)
        if not self.rank_observer or not packets or struct.unpack(">IIII", packets[0][:16])[2] == 999999:
            return packets
        state = self.rank_observer(before) if self.save != before else None
        for i, packet in enumerate(packets):
            _, _, mid, sequence = struct.unpack(">IIII", packet[:16])
            if mid not in (2000, 999900):
                continue
            raw = packet[16:]
            if mid == 999900 and 2000 not in get_comb_ids(raw):
                continue
            state = state or self.rank_observer()
            now = int(time.time())
            if mid == 2000:
                raw = ranking.rewrite_activities(raw, state, self.role_config, now)
            else:
                out = bytearray()
                for n, w, value in iter_pb_fields(raw):
                    if (n, w) == (1, 2):
                        messages = get_comb_messages(encode_pb_field(1, 2, value))
                        if messages[0][0] == 2000:
                            value = pb_set_field(value, 2, 2, ranking.rewrite_activities(messages[0][1], state, self.role_config, now))
                    out.extend(encode_pb_field(n, w, value))
                raw = bytes(out)
            packets[i] = pack_frame(mid, sequence, raw)
        return packets

    def _handle(self, opcode, seq, body):
        """成功响应只在落盘后返回；解析、业务或保存失败时抛错，由收发入口关闭连接。"""
        print_flush(f"[C->S] Opcode: {opcode:6d} (0x{opcode:04x}), Seq: {seq:3d}, Payload: {len(body):3d} B")
        if opcode == 999904:
            if body:
                return unavailable_response(opcode, seq, body, "心跳不接受参数")
            working = copy.deepcopy(self.save)
            packets = player.prepare_recorded_responses(
                seq, [{"opcode": opcode, "seq": seq, "hex": ""}], working, body,
                self.save_path, self.step_counts, self.role_config, self.connected_at)
            self.save = working
            day = working["welfare_state"]["day"]
            if day > self.refresh_day:
                packets.append(pack_frame(110, 0, b""))
                self.refresh_day = day
            return packets
        if opcode == 200:
            sections = guide.get_guide_sections(self.save, self.step_counts)
            pb = guide.build_guide_query_pb(sections)
            print_flush(f"  └── [S->C] 应答 Opcode 200: {guide.describe_guide(sections, self.step_counts)} | hex={pb.hex()}")
            return [pack_frame(200, seq, pb)]

        if opcode == 100:
            return [pack_frame(100, seq, player.build_random_name(body, self.role_config))]

        if opcode == 101:
            self.save["role_name"] = player.parse_set_name(body)
            if self.save.get("role_snapshot"):
                self.save["role_snapshot"] = player.apply_role_state(bytes.fromhex(self.save["role_snapshot"]), self.save, int(time.time())).hex()
            print_flush(f"[★] 玩家确定角色名: 【{self.save['role_name']}】")
            if not player.save_role(self.save, self.save_path, self.step_counts):
                raise OSError("名字保存失败")
            return [pack_frame(101, seq, b"\x08\x01")]

        if opcode == 201:
            guide.record_guide_progress(self.save, body, self.step_counts)
            if not player.save_role(self.save, self.save_path, self.step_counts):
                raise OSError("引导进度保存失败")
            return [pack_frame(201, seq, b"\x08\x01")]

        if opcode == 999898:
            if player.record_legacy_role_state(self.save, body, self.role_config):
                if not player.save_role(self.save, self.save_path, self.step_counts):
                    raise OSError("角色状态保存失败")
            return [pack_frame(999898, seq, b"\x08\x01")]

        if opcode == 4601:
            return unavailable_response(opcode, seq, body, "本地服周年兑换尚未实现，未扣除材料或元宝。")

        if opcode == 20000:
            return unavailable_response(opcode, seq, body, "本地模拟充值使用档位订单，无需支付凭证。")

        if opcode == 1401:
            return unavailable_response(opcode, seq, body, "本地服暂未开放此招募方式，请使用普通招募。")

        if opcode in (5520, 8204):
            return unavailable_response(opcode, seq, body, "此高级养成没有完整消耗记录，安全保护：未扣款、未重生。")

        if opcode == 8301:
            return unavailable_response(opcode, seq, body, "伙伴升星重生尚未接通，未扣费、未重置星级。")

        if opcode in (6211, 6212):
            try:
                return game_helper.handle(self, opcode, seq, body)
            except ValueError as error:
                return unavailable_response(opcode, seq, body, str(error))

        if opcode in pets.UNSUPPORTED:
            return unavailable_response(opcode, seq, body, "此接口属于旧版魔宠，当前版本请使用进阶、图鉴和技能页面，未扣除资源。")

        if opcode in world_boss.OPCODES and (self.world_boss_request or opcode in world_boss.MUTATIONS):
            try:
                if self.world_boss_request is None:
                    raise ValueError("屠龙挑战需要绑定本地账号库，未扣除元宝")
                return self.world_boss_request(self, opcode, seq, body)
            except ValueError as error:
                return unavailable_response(opcode, seq, body, str(error))

        if opcode == 2105:
            return unavailable_response(opcode, seq, body, "本地杯赛竞猜尚未开放，未扣除银币、元宝或道具。")

        if opcode in cup.OPCODES:
            try:
                if self.cup_request is None:
                    raise ValueError("杯赛需要绑定本地账号库")
                return self.cup_request(self, opcode, seq, body)
            except ValueError as error:
                return unavailable_response(opcode, seq, body, str(error))

        if opcode == 1107 and body:
            return unavailable_response(opcode, seq, body, "装备碎片列表查询不接受参数")

        if opcode in friends.OPCODES:
            try:
                if self.friend_request is None:
                    raise ValueError("好友需要绑定本地账号库")
                return self.friend_request(self, opcode, seq, body)
            except ValueError as error:
                return unavailable_response(opcode, seq, b"" if opcode == 2306 else body, str(error))

        if opcode in examination.OPCODES:
            try:
                if self.examination_request is None:
                    if opcode == 7002 and not body:
                        return [pack_frame(opcode, seq, examination.query(self.save, self.role_config, int(time.time())))]
                    raise ValueError("三界联考需要绑定本地账号库")
                return self.examination_request(self, opcode, seq, body)
            except ValueError as error:
                return unavailable_response(opcode, seq, body, str(error))

        if opcode in (*guild.OPCODES, *guild_chat.OPCODES):
            try:
                if self.guild_request is None:
                    raise ValueError("公会需要绑定本地账号库")
                return self.guild_request(self, opcode, seq, body)
            except ValueError as error:
                return unavailable_response(opcode, seq, body, str(error))

        if opcode in (3500, 3503, 5601, 5602, 5603, 3625):
            try:
                if self.rank_query is None:
                    raise ValueError("排行榜需要绑定本地账号库")
                return [pack_frame(opcode, seq, self.rank_query(body, opcode))]
            except ValueError as error:
                return unavailable_response(opcode, seq, body, str(error))

        if opcode in (3100, 3101, 3102):
            key = (seq, body)
            cached = self.random_replies.get(opcode)
            if cached and cached[0] == key and self.save == cached[2]:
                return list(cached[1])
            working = copy.deepcopy(self.save)
            now = int(time.time())
            try:
                if self.rank_query is None or not working.get("has_role"):
                    raise ValueError("本地排名邮件需要已创建的账号")
                reply, reward = self.rank_query(body, opcode, working)
                online_rewards.settle(working, self.role_config, self.connected_at, now)
                welfare.settle(working, now)
                player.settle_stamina(working, self.role_config, now)
                if reward:
                    player.apply_reward(working, reward, self.role_config, now)
            except ValueError as error:
                return unavailable_response(opcode, seq, body, str(error))
            packets = [pack_frame(opcode, seq, reply)]
            if working.get("fashion_state") != self.save.get("fashion_state"):
                data, _, _ = fashion.prepare(1070, working, b"", self.role_config, now)
                packets.append(pack_frame(1070, 0, data))
                packets.append(pack_frame(1027, 0, bytes.fromhex(working["world_state"]["1002"])))
                old, new = self.save["role_state"], working["role_state"]
                power = recharge.ids([new["power"] - old["power"], new["power"], 0, new["g_power"],
                                      new["power_all"] - old["power_all"], new["power_all"]])
                packets.append(pack_frame(205, 0, power))
            packets = player.save_response_group(packets, working, self.save, self.save_path, self.step_counts, self.role_config, now)
            self.save = working
            if opcode != 3100:
                self.random_replies[opcode] = (key, packets, copy.deepcopy(working))
            return packets

        if opcode in (999901, 999989):
            try:
                fields = list(iter_pb_fields(body))
                if len(fields) != 1 or fields[0][:2] != (1, 0) or not 0 < fields[0][2] < (1 << 31):
                    raise ValueError("行为上报或响应重取参数无效")
                if opcode == 999989:
                    # 仅重建只读提示查询，绝不重做消费、战斗或奖励交易。
                    if fields[0][2] != 1032:
                        raise ValueError("暂只支持重新获取提示状态，请重新打开对应页面")
                    return self.handle(1032, seq, b"")
                return [pack_frame(opcode, seq, body)]
            except ValueError as error:
                return unavailable_response(opcode, seq, body, str(error))

        if opcode in (7094, 7095):
            working = copy.deepcopy(self.save)
            now = int(time.time())
            try:
                if self.growth_buyers is None:
                    raise ValueError("全服福利需要绑定本地账号库")
                welfare.settle(working, now)
                online_rewards.settle(working, self.role_config, self.connected_at, now)
                player.settle_stamina(working, self.role_config, now)
                reply = welfare.prepare_global(opcode, working, body, self.role_config, self.growth_buyers())
                if opcode == 7095:
                    player.apply_reward(working, reply, self.role_config, now)
            except ValueError as error:
                return unavailable_response(opcode, seq, body, str(error))
            packets = player.save_response_group([pack_frame(opcode, seq, reply)], working, self.save,
                                                self.save_path, self.step_counts, self.role_config, now)
            self.save = working
            return packets

        sign_comb = False
        break_comb = False
        rob_comb = False
        watch_comb = False
        pet_comb = False
        if opcode == 999900:
            if any(mid in dragon_wishing.MUTATIONS for mid in get_comb_ids(body)):
                return unavailable_response(opcode, seq, body, "神龙许愿操作请从对应页面单独发起")
            if any(mid in examination.MUTATIONS for mid in get_comb_ids(body)):
                return unavailable_response(opcode, seq, body, "联考答题请从考试页面单独发起")
            if 1004 in get_comb_ids(body):
                return unavailable_response(opcode, seq, body, "助阵操作请单独发起")
            if any(mid in (*friends.MUTATIONS, 1020, 1022, 2305) for mid in get_comb_ids(body)):
                return unavailable_response(opcode, seq, body, "好友操作请从对应页面单独发起")
            # 仅开放下列原生引导的完整二消息模板；保留顺序及额外字段校验。
            templates = [encode_pb_field(1, 2, encode_pb_field(1, 0, 3642) + empty)
                         + encode_pb_field(1, 2, encode_pb_field(1, 0, 201) + encode_pb_field(2, 2, b"\x08\x33\x10\x01"))
                         for empty in (b"", encode_pb_field(2, 2, b""))]
            sign_comb = normalize_comb_request(body) in templates
            templates = [encode_pb_field(1, 2, encode_pb_field(1, 0, 2063) + empty)
                         + encode_pb_field(1, 2, encode_pb_field(1, 0, 201) + encode_pb_field(2, 2, b"\x08\x39\x10\x02"))
                         for empty in (b"", encode_pb_field(2, 2, b""))]
            watch_comb = normalize_comb_request(body) in templates
            messages = get_comb_messages(body)
            if [mid for mid, _ in messages] == [1049, 201]:
                expected = (encode_pb_field(1, 2, encode_pb_field(1, 0, 1049) + encode_pb_field(2, 2, messages[0][1]))
                            + encode_pb_field(1, 2, encode_pb_field(1, 0, 201) + encode_pb_field(2, 2, b"\x08\x3b\x10\x03")))
                pet_comb = normalize_comb_request(body) == expected
            if [mid for mid, _ in messages] == [1017, 201]:
                values = development.ids(messages[0][1])
                if len(values) in (1, 2) and (len(values) == 1 or values[1] == 0):
                    expected = (encode_pb_field(1, 2, encode_pb_field(1, 0, 1017) + encode_pb_field(2, 2, messages[0][1]))
                                + encode_pb_field(1, 2, encode_pb_field(1, 0, 201) + encode_pb_field(2, 2, b"\x08\x05\x10\x04")))
                    break_comb = normalize_comb_request(body) == expected
            if [mid for mid, _ in messages] == [1111, 201]:
                expected = (encode_pb_field(1, 2, encode_pb_field(1, 0, 1111) + encode_pb_field(2, 2, messages[0][1]))
                            + encode_pb_field(1, 2, encode_pb_field(1, 0, 201) + encode_pb_field(2, 2, b"\x08\x34\x10\x03")))
                rob_comb = normalize_comb_request(body) == expected

        local_box = False
        if opcode == 1201:
            values = player.parse_prop_use(body)
            local_box = shop.openable_box(self.role_config["props"].get(str(values[0]), {}))

        local_development = (opcode in development.MUTATIONS and (opcode != 1057
                             or self.save.get("guide", {}).get("sections", {}).get("1", {}).get("status") == 2))
        # 7010 是跨系统的购买次数协议；只有 sysId=450 属于通天塔，其余仍走录制帧/兜底。
        tower_buy = opcode == babel_tower.BUY_TIMES and next(
            (value for n, w, value in iter_pb_fields(body) if (n, w) == (1, 0)), None) == 450
        if sign_comb or break_comb or rob_comb or watch_comb or pet_comb or local_box or local_development or tower_buy or opcode in (301, 1016, 1305, 1306, 1307, *star_copy.MUTATIONS, *mieshendian.MUTATIONS, 1403, 7111, 7112, 7113, 115, 1003, 1004, 1005, 1007, 1009, 1130, 2038, *babel_tower.MUTATIONS, *ascension_sendai.MUTATIONS, *welfare.CLAIMS,
                                  *pets.MUTATIONS, *timebag.MUTATIONS, *friend_copy.MUTATIONS, *activity_copy.BATTLES, *activity_copy.SWEEPS, *hades_copy.MUTATIONS, *arena.MUTATIONS,
                                  *watchstar.MUTATIONS, *artifact.MUTATIONS, *antique.MUTATIONS, *champion.MUTATIONS, *nightclub.MUTATIONS, *dragon_wishing.MUTATIONS, *gamestar.MUTATIONS, *deployment.MUTATIONS, *partner_growth.MUTATIONS,
                                  *qiankun.MUTATIONS, *secret_shop.MUTATIONS,
                                  *rob.MUTATIONS, *blackmarket.MUTATIONS, *wing.MUTATIONS, *cover.MUTATIONS, *exchange.MUTATIONS,
                                  *daily_events.CLAIMS, *collection.MUTATIONS, *achievements.MUTATIONS, *soul.MUTATIONS, *equip_evolve.OPCODES,
                                   *training.OPCODES, *shop.PURCHASES, *fashion.TRANSACTIONS, *favorite.MUTATIONS, *cornucopia.MUTATIONS, *penglai.MUTATIONS, *single_boss.MUTATIONS, *equip_baptize.OPCODES, *sigil.MUTATIONS, *treasure_refine.OPCODES, *general_foster.OPCODES, *magic.MUTATIONS, *illusion.MUTATIONS, *skytoken.OPCODES):
            key = (seq, body)
            cached = self.random_replies.get(opcode)
            if cached and cached[0] == key:
                if self.save != cached[2]:
                    return unavailable_response(opcode, seq, body, "该操作已结算，当前角色状态已变化，请重新进入。")
                return list(cached[1])
            working = copy.deepcopy(self.save)
            try:
                if opcode in (1306, 1307):
                    packets = player.prepare_battle_responses(seq, working, body, self.save_path,
                                                             self.step_counts, self.role_config, self.connected_at, opcode=opcode, guild_profit=self.guild_profit)
                else:
                    reply = (encode_pb_field(1, 2, encode_pb_field(1, 0, 3642) + encode_pb_field(2, 2, b""))
                             + encode_pb_field(1, 2, encode_pb_field(1, 0, 201) + encode_pb_field(2, 2, b"\x08\x01"))) if sign_comb else b""
                    if break_comb:
                        reply = (encode_pb_field(1, 2, encode_pb_field(1, 0, 1017) + encode_pb_field(2, 2, b""))
                                  + encode_pb_field(1, 2, encode_pb_field(1, 0, 201) + encode_pb_field(2, 2, b"\x08\x01")))
                    if rob_comb:
                        section = working.get("guide", {}).get("sections", {}).get("52", {})
                        if section.get("status") != 1 or section.get("step") != 2:
                            raise ValueError("挑战引导步骤已变化，请重新进入")
                        reply = (encode_pb_field(1, 2, encode_pb_field(1, 0, 1111) + encode_pb_field(2, 2, b""))
                                 + encode_pb_field(1, 2, encode_pb_field(1, 0, 201) + encode_pb_field(2, 2, b"\x08\x01")))
                    if watch_comb:
                        section = working.get("guide", {}).get("sections", {}).get("57", {})
                        if section.get("status") == 2 or section.get("step", 0) >= 2:
                            raise ValueError("观星台引导步骤已变化，请重新进入")
                        reply = (encode_pb_field(1, 2, encode_pb_field(1, 0, 2063) + encode_pb_field(2, 2, b""))
                                  + encode_pb_field(1, 2, encode_pb_field(1, 0, 201) + encode_pb_field(2, 2, b"\x08\x01")))
                    if pet_comb:
                        section = working.get("guide", {}).get("sections", {}).get("59", {})
                        if section.get("status") != 1 or section.get("step") != 2:
                            raise ValueError("魔宠合成引导步骤已变化，请重新进入")
                        reply = (encode_pb_field(1, 2, encode_pb_field(1, 0, 1049) + encode_pb_field(2, 2, b""))
                                 + encode_pb_field(1, 2, encode_pb_field(1, 0, 201) + encode_pb_field(2, 2, b"\x08\x01")))
                    packets = player.prepare_recorded_responses(
                        seq, [{"opcode": opcode, "seq": seq, "hex": reply.hex()}], working, body,
                        self.save_path, self.step_counts, self.role_config, self.connected_at, guild_profit=self.guild_profit, guild_level=self.guild_level, cup_rank=self.cup_rank, examination_ranks=self.examination_ranks)
            except ValueError as error:
                return unavailable_response(opcode, seq, body, str(error))
            self.save = working
            self.random_replies[opcode] = (key, packets, copy.deepcopy(self.save))
            return packets

        if opcode in activities.UNSUPPORTED_OPCODES:
            return unavailable_response(opcode, seq, body, "此活动操作尚缺原版结算数据，未扣除资源。")

        if opcode in (204, 300, *exchange.QUERIES, 1304, *star_copy.QUERIES, *hades_copy.QUERIES, *antique.QUERIES, *collection.QUERIES, *achievements.QUERIES, *soul.QUERIES, *player.WORLD_QUERY_IDS, *mieshendian.QUERIES, 1402, 2037, 2410, 2411, 6517, 3611, 7110, *rob.QUERIES, *daily_events.QUERIES, *development.QUERIES, *welfare.QUERIES, *recharge.OPCODES, *activities.TRANSACTION_OPCODES,
                      *shop.QUERIES, *artifact.QUERIES, *champion.QUERIES, *nightclub.QUERIES, *dragon_wishing.QUERIES, *gamestar.QUERIES, *deployment.QUERIES, *fashion.QUERIES, *blackmarket.QUERIES, *watchstar.QUERIES, *qiankun.QUERIES, *secret_shop.QUERIES,
                      *pets.QUERIES, *timebag.QUERIES, *world_boss.QUERIES, *friend_copy.QUERIES, *activity_copy.QUERIES, *arena.QUERIES, *favorite.QUERIES, *cornucopia.QUERIES, *penglai.QUERIES, *single_boss.QUERIES, *sigil.QUERIES, *magic.QUERIES, *wing.QUERIES, *cover.QUERIES, *illusion.QUERIES, *partner_growth.QUERIES, *babel_tower.QUERIES, *ascension_sendai.QUERIES, *pending_features.QUERIES):
            working = copy.deepcopy(self.save)
            try:
                baseline = next((data for frame in self.replay.master_comb_packets if frame["opcode"] == 999900
                                 for mid, data in get_comb_messages(bytes.fromhex(frame["hex"])) if mid == opcode), b"") if opcode in (300, 2880) else b""
                packets = player.prepare_recorded_responses(
                    seq, [{"opcode": opcode, "seq": seq, "hex": baseline.hex()}], working, body,
                    self.save_path, self.step_counts, self.role_config, self.connected_at,
                    auto_sigils=self.sigil_auto_pending if opcode == 1002 else None, guild_profit=self.guild_profit, guild_level=self.guild_level, cup_rank=self.cup_rank, examination_ranks=self.examination_ranks)
            except ValueError as error:
                return unavailable_response(opcode, seq, body, str(error))
            self.save = working
            if opcode == 1002:
                self.sigil_auto_pending = None
            return packets

        if opcode in activities.OPCODES or opcode == 999905:
            responses = [{"opcode": opcode, "seq": seq, "hex": ""}]
        elif opcode == 1032:
            ids = activities.parse_hint_ids(body)
            if ids and all(mid in activities.HINT_IDS for mid in ids):
                responses = [{"opcode": opcode, "seq": seq, "hex": ""}]
            else:
                responses = self.replay.match(opcode, seq, body)
        elif opcode == 1201:
            ids = player.parse_prop_use(body)
            prop = self.role_config["props"].get(str(ids[0]), {})
            if prop.get("type") == "value":
                responses = [{"opcode": opcode, "seq": seq, "hex": ""}]
            else:
                responses = self.replay.match(opcode, seq, body)
        else:
            responses = self.replay.match(opcode, seq, body)
        if responses is None:
            ids = get_comb_ids(body) if opcode == 999900 else (opcode,)
            if 1306 in ids:
                return unavailable_response(opcode, seq, body, "此关卡复合挑战尚未支持，请从普通关卡入口挑战。")
            if 4601 in ids:
                return unavailable_response(opcode, seq, body, "本地服周年兑换尚未实现，未扣除材料或元宝。")
            if 1304 in ids:
                return unavailable_response(opcode, seq, body, "此副本宝箱复合请求尚未支持，请单独领取。")
            if any(mid in (1401, 1403, 7111, 7112, 7113) for mid in ids):
                return unavailable_response(opcode, seq, body, "此招募复合请求尚未支持，请使用普通招募。")
            if any(mid in (115, 116, 20000) for mid in ids):
                return unavailable_response(opcode, seq, body, "本地模拟充值请从充值档位单独下单。")
            if any(mid in activities.UNSUPPORTED_OPCODES + activities.TRANSACTION_OPCODES for mid in ids):
                return unavailable_response(opcode, seq, body, "此活动复合操作尚未实现，未扣除资源。")
            return unavailable_response(opcode, seq, body, "此操作尚未实现或参数不受支持，未更改存档。")
        if not any(r["opcode"] == opcode and r["seq"] != 0 for r in responses):
            return unavailable_response(opcode, seq, body, "此操作缺少完整应答，未更改存档。")
        if self.guild_request and opcode == 999900 and 2230 in get_comb_ids(body):
            try:
                membership = self.guild_request(self, 2230, seq, b"")[0][16:]
            except ValueError as error:
                return unavailable_response(opcode, seq, body, str(error))
            responses = [dict(r) for r in responses]
            for response in responses:
                if response["opcode"] == 999900:
                    response["hex"] = b"".join(
                        encode_pb_field(n, w, pb_set_field(value, 2, 2, membership)
                                        if (n, w) == (1, 2) and get_comb_ids(encode_pb_field(n, w, value)) == (2230,) else value)
                        for n, w, value in iter_pb_fields(bytes.fromhex(response["hex"]))
                    ).hex()
        if (opcode == 999900 and any(mid in (1007, 1109) for mid in get_comb_ids(body))
                and self.save.get("guide", {}).get("sections", {}).get("1", {}).get("status") == 2):
            return unavailable_response(opcode, seq, body, "教程装备录制已过期，请使用当前阵容单独装备或强化。")
        if self.friend_request and opcode == 999900:
            queries = {mid: raw for mid, raw in get_comb_messages(body) if mid in (2300, 2313)}
            if queries:
                try:
                    replies = {mid: self.friend_request(self, mid, seq, raw)[0][16:] for mid, raw in queries.items()}
                except ValueError as error:
                    return unavailable_response(opcode, seq, body, str(error))
                responses = [dict(r) for r in responses]
                for response in responses:
                    if response["opcode"] == 999900:
                        out = bytearray()
                        for n, w, value in iter_pb_fields(bytes.fromhex(response["hex"])):
                            if (n, w) == (1, 2):
                                mid = get_comb_messages(encode_pb_field(n, w, value))[0][0]
                                if mid in replies:
                                    value = pb_set_field(value, 2, 2, replies[mid])
                            out.extend(encode_pb_field(n, w, value))
                        response["hex"] = out.hex()
        working = copy.deepcopy(self.save)
        initialize_sigils = opcode == 999900 and any(mid == 1002 for mid, raw in get_comb_messages(body))
        packets = player.prepare_recorded_responses(seq, responses, working, body,
                                                     self.save_path, self.step_counts, self.role_config, self.connected_at,
                                                     auto_sigils=self.sigil_auto_pending if initialize_sigils else None, guild_profit=self.guild_profit)
        self.save = working
        if initialize_sigils:
            self.sigil_auto_pending = None
        return packets
