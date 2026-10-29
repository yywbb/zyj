"""把已落盘的游戏状态转成后台视图；查询不触发结算或写存档。"""

import copy

from .. import guide, player, protocol


def summary(snapshot, step_counts, role_config):
    result = {key: value for key, value in snapshot.items() if key != "save"}
    result.update(name="未建号", level=None, coin=None, gold=None, stamina=None, energy=None,
                  guide="尚未开始", saved_at=None, has_role=False)
    if snapshot["error"]:
        return result
    try:
        save = copy.deepcopy(snapshot["save"])
        result.update(name=save.get("role_name") or ("未命名" if save.get("has_role") else "未建号"), has_role=bool(save.get("has_role")),
                      saved_at=save.get("last_login"), guide=guide.describe_guide(guide.get_guide_sections(save, step_counts), step_counts))
        if save.get("has_role") or save.get("role_state") or save.get("role_snapshot"):
            state = player.get_role_state(save, role_config)
            result.update({key: state.get(key) for key in ("level", "coin", "gold", "stamina", "energy", "maxstamina", "maxenergy")})
    except (ValueError, TypeError, KeyError, AttributeError) as error:
        result["error"] = f"存档状态无法解析: {error}"
    return result


def detail(snapshot, step_counts, role_config):
    result = summary(snapshot, step_counts, role_config)
    result.update(generals=[], equipment=[], inventory=[], copies=[], states={})
    if result["error"]:
        return result
    save = snapshot["save"]
    try:
        world = save.get("world_state", {})
        def rows(opcode, field=1):
            return [v for n, w, v in protocol.iter_pb_fields(bytes.fromhex(world.get(str(opcode), ""))) if n == field and w == 2]
        def number(raw, field):
            return protocol.pb_get_varint(raw, field) or 0
        def name(table, cid):
            return role_config.get(table, {}).get(str(cid), {}).get("name") or str(cid)
        positions = {number(row, 2): number(row, 1) for row in rows(1002, 4)}
        for row in rows(1002):
            cid, iid = number(row, 1), number(row, 2)
            result["generals"].append({"cid": cid, "iid": iid, "name": name("general", cid),
                                       "level": number(row, 3), "position": positions.get(iid)})
        for row in rows(1002, 2):
            values = protocol.parse_ids_pb(row)
            if len(values) < 3:
                raise ValueError("装备记录缺少字段")
            result["equipment"].append({"iid": values[0], "cid": values[1], "name": name("equip", values[1]), "level": values[2]})
        for opcode, table, kind in ((1200, "props", "道具"), (1012, "general", "武将碎片")):
            for row in rows(opcode):
                cid = number(row, 1)
                result["inventory"].append({"cid": cid, "name": name(table, cid), "count": number(row, 2), "kind": kind})
        for row in rows(1300):
            points = [v for n, w, v in protocol.iter_pb_fields(row) if n == 7 and w == 2]
            cid = number(row, 1)
            result["copies"].append({"id": cid, "name": name("map", cid), "cleared": sum(number(p, 3) > 0 for p in points),
                                     "stars": sum(number(p, 3) for p in points), "boxes": [number(row, f) for f in (4, 5, 6)]})
        result["states"] = {key: save.get(key, {}) for key in ("guide", "activity_state", "recruit_state", "recruit_pending", "recharge_state", "last_battle")}
    except (ValueError, TypeError, KeyError, AttributeError) as error:
        result["error"] = f"存档明细无法解析: {error}"
    return result
