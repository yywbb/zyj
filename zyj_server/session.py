"""处理一条连接的请求，返回有序的完整协议帧；不持有 socket。"""

import functools

from . import guide, player
from .protocol import pack_frame
from .replay import Replay

print_flush = functools.partial(print, flush=True)


class Session:
    def __init__(self, tables, save_path, step_counts, role_config):
        self.replay = Replay(tables)
        self.save_path = save_path
        self.step_counts = step_counts
        self.role_config = role_config
        self.save = player.load_save(save_path, step_counts)

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

        if opcode == 101:
            self.save["role_name"] = player.parse_set_name(body)
            if self.save.get("role_snapshot"):
                self.save["role_snapshot"] = player.apply_role_state(bytes.fromhex(self.save["role_snapshot"]), self.save).hex()
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

        responses = self.replay.match(opcode, seq, body)
        if responses is None:
            return [pack_frame(opcode, seq, b"")]
        packets = player.prepare_recorded_responses(seq, responses, self.save, body,
                                                    self.save_path, self.step_counts, self.role_config)
        # 缺少自身应答会使客户端的全屏 loading 遮罩一直吞掉点击。
        if opcode != 999900 and not any(r["opcode"] == opcode and r["seq"] != 0 for r in responses):
            packets.append(pack_frame(opcode, seq, b""))
            print_flush(f"  └── [S->C] 补发自应答 Opcode: {opcode:6d} (0x{opcode:04x}), Seq: {seq:3d}, Len:   0 B (录制缺失, 防遮罩残留)")
        return packets
