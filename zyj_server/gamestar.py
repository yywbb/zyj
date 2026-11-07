"""主角游戏厅：30关九点激活／突破；只修改事务工作副本。"""

from . import development, equip_evolve, formation, recharge
from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint, pb_set_field

QUERIES = (3720,)
MUTATIONS = (3721, 3722)
OPCODES = QUERIES + MUTATIONS


def get_state(save, config):
    state = save.get("gamestar_state", {"stage": 1, "step": 0, "checked_at": 0})
    if isinstance(state, dict) and "checked_at" not in state:
        # 旧档只有关卡和点数；只补读取视图，成功结算时再落盘。
        state = dict(state, checked_at=0)
    maximum = max(map(int, config["hoshimiya_break"]))
    if (not isinstance(state, dict) or any(type(state.get(k)) is not int for k in ("stage", "step", "checked_at"))
            or not 1 <= state["stage"] <= maximum + 1 or not 0 <= state["checked_at"] < (1 << 63)
            or not 0 <= state["step"] <= (config["hoshimiya_break"][str(state["stage"])]["break_cond1"] if state["stage"] <= maximum else 0)):
        raise ValueError("游戏厅进度存档无效")
    return state


def prepare(opcode, save, body, config, now):
    values = development.ids(body)
    state = get_state(save, config)
    if opcode == 3720:
        if values:
            raise ValueError("游戏厅查询不接受参数")
        if save.get("has_role") and save["role_state"]["level"] >= config["build"]["203"]["level"]:
            save["gamestar_state"] = dict(state, checked_at=max(now, state["checked_at"]))
        return recharge.ids([state["stage"], state["step"]]), [], b""
    if (not save.get("has_role") or save["role_state"]["level"] < config["build"]["203"]["level"]
            or save.get("guide", {}).get("sections", {}).get("1", {}).get("status") != 2):
        raise ValueError("游戏厅尚未解锁")
    if now < state["checked_at"]:
        raise ValueError("日期回拨，请稍后操作游戏厅")
    stage, step = state["stage"], state["step"]
    row = config["hoshimiya_break"].get(str(stage))
    if not row:
        raise ValueError("游戏厅已全部通关")
    snapshot = bytes.fromhex(save["protagonist_snapshot"])
    iid = pb_get_varint(snapshot, 1)
    raw = formation.records(bytes.fromhex(save["world_state"]["1002"]), 1, 2).get(iid)
    if not raw or config["general"][str(pb_get_varint(raw, 1))]["actor"] != "lead":
        raise ValueError("游戏厅主角状态缺失")
    if (pb_get_varint(raw, 4) or 0) > 23:
        raise ValueError("游戏厅暂不支持此主角的高级进阶")
    development.lead_fairy(raw, config)
    if opcode == 3721:
        if values != [stage, step] or step >= row["break_cond1"]:
            raise ValueError("游戏厅激活目标已变化，请重新打开页面")
        point = config["hoshimiya_jihuo"][str(stage)][str(step + 1)]
        if point["activation_cond"] != step:
            raise ValueError("游戏厅激活前置配置无效")
        spec, additions = point["activation_cost"], [point["activation_add"]]
        following = dict(state, step=step + 1, checked_at=now)
    else:
        if values != [stage] or step != row["break_cond1"]:
            raise ValueError("请先完成本关九点激活，且不能重复突破旧关卡")
        if (pb_get_varint(snapshot, 3) or 0) < row["break_cond2"]:
            raise ValueError("主角进阶不足，不能突破本关游戏厅")
        spec, additions = row["break_cost"], [row[f"break_add{i}"] for i in (1, 2, 3)]
        following = dict(state, stage=stage + 1, step=0, checked_at=now)
    changes = {6: 0, 7: 0, 8: 0}
    for addition in additions:
        name, amount = addition.split(":")
        if name not in ("atk", "def", "hp") or not 0 <= int(amount) < (1 << 31):
            raise ValueError("游戏厅属性配置无效")
        changes[{"atk": 6, "def": 7, "hp": 8}[name]] += int(amount)
    raw, increase = development.adjust(raw, changes)
    for key in ("power", "power_all"):
        save["role_state"][key] += increase
        if not 0 <= save["role_state"][key] < (1 << 31):
            raise ValueError("游戏厅增加后的角色战力超出范围")
    save["gamestar_state"] = following
    snapshot = pb_set_field(snapshot, 10, 2, raw)
    save["protagonist_snapshot"] = snapshot.hex()
    update = encode_pb_field(1, 2, raw) + encode_pb_field(6, 2, snapshot)
    return update, list(equip_evolve.costs(spec).items()), update
