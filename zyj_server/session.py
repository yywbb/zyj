"""处理一条连接的请求，返回有序的完整协议帧；不持有 socket。"""

import copy
import functools
import time

from . import activities, guide, player, recharge, recruit
from .protocol import encode_pb_field, get_comb_ids, pack_frame
from .replay import Replay

print_flush = functools.partial(print, flush=True)


def unavailable_response(opcode, seq, body, message):
    print_flush(f"  [!] {message} (Opcode={opcode}, Seq={seq}, hex={body.hex()})")
    # 原生 9999 UI 错误清除 loading；1999 广播补充可读原因，避免走成功解析器。
    error = encode_pb_field(1, 0, opcode) + encode_pb_field(1, 0, 0)
    return [pack_frame(999999, seq, error), pack_frame(1999, 0, encode_pb_field(1, 2, message.encode("utf-8")))]


class Session:
    def __init__(self, tables, save_path, step_counts, role_config):
        self.replay = Replay(tables)
        self.save_path = save_path
        self.step_counts = step_counts
        self.role_config = role_config
        self.random_replies = {}
        self.save = player.load_save(save_path, step_counts)
        player.initialize_world_state(self.save, self.replay.master_comb_packets)
        activities.get_state(self.save)
        recruit.get_state(self.save)
        recruit.get_pending(self.save)
        recharge.get_state(self.save)
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
        """成功响应只在落盘后返回；解析、业务或保存失败时抛错，由收发入口关闭连接。"""
        print_flush(f"[C->S] Opcode: {opcode:6d} (0x{opcode:04x}), Seq: {seq:3d}, Payload: {len(body):3d} B")
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

        if opcode in (1306, 1403, 7111, 7112, 7113, 115, 1003, 1009):
            key = (seq, body)
            cached = self.random_replies.get(opcode)
            if cached and cached[0] == key:
                if self.save != cached[2]:
                    return unavailable_response(opcode, seq, body, "该操作已结算，当前角色状态已变化，请重新进入。")
                return list(cached[1])
            working = copy.deepcopy(self.save)
            try:
                if opcode == 1306:
                    packets = player.prepare_battle_responses(seq, working, body, self.save_path,
                                                             self.step_counts, self.role_config)
                else:
                    packets = player.prepare_recorded_responses(
                        seq, [{"opcode": opcode, "seq": seq, "hex": ""}], working, body,
                        self.save_path, self.step_counts, self.role_config)
            except ValueError as error:
                return unavailable_response(opcode, seq, body, str(error))
            self.save = working
            self.random_replies[opcode] = (key, packets, copy.deepcopy(self.save))
            return packets

        if opcode in activities.UNSUPPORTED_OPCODES:
            return unavailable_response(opcode, seq, body, "此活动操作尚缺原版结算数据，未扣除资源。")

        if opcode in (1304, 1402, 7110, *recharge.OPCODES, *activities.TRANSACTION_OPCODES):
            working = copy.deepcopy(self.save)
            try:
                packets = player.prepare_recorded_responses(
                    seq, [{"opcode": opcode, "seq": seq, "hex": ""}], working, body,
                    self.save_path, self.step_counts, self.role_config)
            except ValueError as error:
                return unavailable_response(opcode, seq, body, str(error))
            self.save = working
            return packets

        if opcode in player.WORLD_QUERY_IDS:
            responses = [{"opcode": opcode, "seq": seq, "hex": self.save["world_state"][str(opcode)]}]
        elif opcode in activities.OPCODES or opcode == 999905:
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
            return [pack_frame(opcode, seq, b"")]
        packets = player.prepare_recorded_responses(seq, responses, self.save, body,
                                                    self.save_path, self.step_counts, self.role_config)
        # 缺少自身应答会使客户端的全屏 loading 遮罩一直吞掉点击。
        if opcode != 999900 and not any(r["opcode"] == opcode and r["seq"] != 0 for r in responses):
            packets.append(pack_frame(opcode, seq, b""))
            print_flush(f"  └── [S->C] 补发自应答 Opcode: {opcode:6d} (0x{opcode:04x}), Seq: {seq:3d}, Len:   0 B (录制缺失, 防遮罩残留)")
        return packets
