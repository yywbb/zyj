"""把已落盘的游戏状态转成后台视图；查询不触发结算或写存档。"""

import copy
import time

from .. import activities, guide, player, protocol, recharge, recruit


def summary(snapshot, step_counts, role_config):
    result = {key: value for key, value in snapshot.items() if key != "save"}
    result.update(name="未建号", level=None, coin=None, gold=None, stamina=None, energy=None,
                  vip=None, power=None, created_at=None, guide="尚未开始", saved_at=None, has_role=False)
    if snapshot["error"]:
        return result
    try:
        save = copy.deepcopy(snapshot["save"])
        result.update(name=save.get("role_name") or ("未命名" if save.get("has_role") else "未建号"), has_role=bool(save.get("has_role")),
                      saved_at=save.get("last_login"), created_at=save.get("created_at"),
                      guide=guide.describe_guide(guide.get_guide_sections(save, step_counts), step_counts))
        if save.get("has_role") or save.get("role_state") or save.get("role_snapshot"):
            state = player.get_role_state(save, role_config)
            result.update({key: state.get(key) for key in ("level", "coin", "gold", "stamina", "energy", "maxstamina", "maxenergy", "vip", "power")})
    except (ValueError, TypeError, KeyError, AttributeError) as error:
        result["error"] = f"存档状态无法解析: {error}"
    return result


def detail(snapshot, step_counts, role_config):
    result = summary(snapshot, step_counts, role_config)
    result.update(generals=[], equipment=[], inventory=[], copies=[], states={}, business={}, general_level_cap=0, slot_limit=0)
    if result["error"]:
        return result
    save = copy.deepcopy(snapshot["save"])
    try:
        world = save.get("world_state", {})
        def rows(opcode, field=1):
            return [v for n, w, v in protocol.iter_pb_fields(bytes.fromhex(world.get(str(opcode), ""))) if n == field and w == 2]
        def number(raw, field):
            return protocol.pb_get_varint(raw, field) or 0
        def name(table, cid):
            row = role_config.get(table, {}).get(str(cid), {})
            if row.get("name"):
                return row["name"]
            if table == "props":
                for sub in ("token", "token_fragment", "pet3_fragment", "exclusive", "redl_awake_item"):
                    sub_row = role_config.get(sub, {}).get(str(cid), {})
                    if sub_row.get("name") or sub_row.get("desc"):
                        return sub_row.get("name") or sub_row.get("desc")
            return str(cid)
        positions = {number(row, 2): number(row, 1) for row in rows(1002, 4)}
        cheers = {number(row, 2): number(row, 1) for row in rows(1002, 5)}
        protagonist = number(bytes.fromhex(save.get("protagonist_snapshot", "")), 1)
        for row in rows(1002):
            cid, iid = number(row, 1), number(row, 2)
            result["generals"].append({"cid": cid, "iid": iid, "name": name("general", cid),
                                       "level": number(row, 3), "position": positions.get(iid), "cheer_position": cheers.get(iid),
                                       "protagonist": iid == protagonist, "quality": role_config["general"][str(cid)]["quality"],
                                       **{key: number(row, field) for key, field in (("exp", 5), ("atk", 6), ("defense", 7),
                                           ("hp", 8), ("speed", 9), ("potential", 17), ("power", 20))}})
        for row in rows(1002, 2):
            values = protocol.parse_ids_pb(row)
            if len(values) < 3:
                raise ValueError("装备记录缺少字段")
            result["equipment"].append({"iid": values[0], "cid": values[1], "name": name("equip", values[1]), "level": values[2]})
        fragments = {row["general"]: row["id"] for row in role_config["general_fragment"].values()}
        for opcode, table, kind in ((1200, "props", "道具"), (1012, "general", "武将碎片")):
            for row in rows(opcode):
                cid = number(row, 1)
                result["inventory"].append({"cid": cid, "item_id": fragments.get(cid) if opcode == 1012 else cid,
                                            "name": name(table, cid) + ("碎片" if opcode == 1012 else ""),
                                            "count": number(row, 2), "kind": kind})
        for row in rows(1300):
            points = [v for n, w, v in protocol.iter_pb_fields(row) if n == 7 and w == 2]
            cid = number(row, 1)
            result["copies"].append({"id": cid, "name": name("map", cid), "cleared": sum(number(p, 3) > 0 for p in points),
                                     "stars": sum(number(p, 3) for p in points), "boxes": [number(row, f) for f in (4, 5, 6)],
                                     "points": [{"id": number(p, 1), "stars": number(p, 3), "wins": number(p, 4)} for p in points]})
        result["states"] = {key: save.get(key, {}) for key in ("guide", "activity_state", "recruit_state", "recruit_pending", "recharge_state", "last_battle")}
        if save.get("has_role"):
            result["general_level_cap"] = min(result["level"] * int(role_config["global_kv"]["general_level"]["value"]),
                                               max(map(int, role_config["general_exp"])))
            result["slot_limit"] = min(7, role_config["role_exp"][str(result["level"])]["slotnum"])
            result["business"] = business(save, role_config)
    except (ValueError, TypeError, KeyError, AttributeError) as error:
        result["error"] = f"存档明细无法解析: {error}"
    return result


def business(save, config):
    """调用方传入副本；补齐旧档默认值只用于展示。"""
    now = int(time.time())
    day = (now + 8 * 3600) // 86400
    paid = recharge.get_state(save)
    active = activities.get_state(save)
    draws = recruit.get_state(save)
    first, _ = activities.get_reward_statuses(save, config, now)
    task_statuses, counts, _ = activities.liveness_statuses(save, config, now)
    labels = {0: "未达标", 1: "可领取", 2: "已领取"}
    monthly = max(0, paid["month_until"] - day)
    order = config["recharge"].get(str(paid["cid"]), {})
    def reward_name(cid):
        fragment = config["general_fragment"].get(str(cid))
        if fragment:
            return config["general"].get(str(fragment["general"]), {}).get("name", str(cid)) + "碎片"
        return config["general"].get(str(cid), config["props"].get(str(cid), {})).get("name", str(cid))
    return {
        "recharge": {"rmb": paid["rmb"], "vip": recharge.vip(paid, config), "order": paid["order"],
                     "tier": order.get("rmb"), "order_status": "已确认" if paid["paid"] else "待确认" if paid["cid"] else "无订单",
                     "first": "已领取" if paid["first_claimed"] else "可领取" if paid["bought"] else "未达标",
                     "month_days": monthly, "forever": paid["forever"], "card_rmb": paid["card_rmb"],
                     "month_claim": "已领取" if paid["card_days"]["1"] >= day else "可领取" if monthly else "未生效",
                     "forever_claim": "已领取" if paid["card_days"]["2"] >= day else "可领取" if paid["forever"] else "未生效",
                     "bought": paid["bought"], "card_gifts": paid["card_gifts"]},
        "activities": [{"id": cid, "name": config["begin7day_task"][str(cid)]["name"], "status": labels[status]}
                       for cid, status in first.items()] + [{"id": task, "name": config["liveness"][str(task)]["desc"],
                        "status": labels[status], "progress": counts[task], "target": config["liveness"][str(task)]["num"]}
                        for task, status in task_statuses.items()],
        "consumption": {"gold_spent": active["gold_spent"], "claimed": active["consume_claimed"], "purchases": active["discount_bought"]},
        "recruit": [{"pool": int(key), **row} for key, row in draws.items()],
        "pending": [{"cid": cid, "name": reward_name(cid), "count": count}
                    for cid, count in recruit.get_pending(save)["gets"]],
        "refreshes": recruit.get_pending(save)["refreshes"],
    }
