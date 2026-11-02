"""本地基础公会；共享成员状态独立落盘，创建扣款以角色收据确认。"""

import copy
import json
import math
import re
import secrets

from . import activities, guild_chat, guild_games, storage
from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint


DAILY_OPCODES = (2250, 2251, 2260)
FEATURE_OPCODES = (2252, 2253, 2256, 2257, 2258, 2259)
MUTATIONS = (2251, 2253, 2257, 2258, 2259, 2260, *guild_games.MUTATIONS)
OPCODES = (*range(2230, 2244), *DAILY_OPCODES, *FEATURE_OPCODES, 2254, 2255, 2261, 2265, 2266, 2267, *guild_games.OPCODES)


def ids(values):
    return b"".join(encode_pb_field(1, 0, n) for n in values)


def params(values):
    return b"".join(encode_pb_field(1, 2, encode_pb_field(2, 2, v.encode("utf-8")) if isinstance(v, str)
                    else encode_pb_field(1, 0, v & ((1 << 64) - 1))) for v in values)


def message(mid, data):
    return encode_pb_field(1, 2, encode_pb_field(1, 0, mid & ((1 << 64) - 1)) + encode_pb_field(2, 2, data))


def request_ids(body, count):
    fields = list(iter_pb_fields(body))
    if len(fields) != count or any((n, w) != (1, 0) or not 0 <= v < (1 << 31) for n, w, v in fields):
        raise ValueError("公会操作参数无效")
    return [v for _, _, v in fields]


def valid_text(value, maximum, minimum=0):
    return (isinstance(value, str) and minimum <= len(value) <= maximum and value == value.strip()
            and (not value or value.isprintable()))


def request_text(body, maximum, minimum=0):
    fields = list(iter_pb_fields(body))
    if len(fields) != 1 or fields[0][:2] != (1, 2):
        raise ValueError("公会文字参数无效")
    fields = list(iter_pb_fields(fields[0][2]))
    if len(fields) != 1 or fields[0][:2] != (2, 2):
        raise ValueError("公会文字参数无效")
    try:
        text = fields[0][2].decode("utf-8")
    except UnicodeError:
        raise ValueError("公会文字编码无效") from None
    if not valid_text(text, maximum, minimum):
        raise ValueError(f"公会文字须为 {minimum}–{maximum} 个可显示字符，首尾不能有空格")
    return text


def load(path, saves):
    if not path.exists():
        if any(s.get("guild_creations") or daily_state(s)["receipt"] or s.get("guild_action_receipt") for s in saves.values()):
            raise ValueError("公会存档缺失，请恢复 guilds.json，不能重新创建空公会库")
        return {"version": 1, "next_id": 1, "checked_at": 0, "guilds": {}, "cooldowns": {}}
    try:
        state = json.loads(path.read_bytes())
        validate(state)
        return state
    except (ValueError, TypeError, KeyError, AttributeError, UnicodeError, OverflowError):
        raise ValueError("公会存档损坏，未修改成员或扣款") from None


def validate_role(save):
    """恢复成员身份前检查公开角色投影，损坏字段不能被误当成删号。"""
    try:
        identity = save["created_at"]
        role = save["role_state"]
        receipts = save.get("guild_creations", [])
        daily_state(save)
        receipt = save.get("guild_action_receipt", "")
        if not isinstance(receipt, str) or receipt and not re.fullmatch(r"[a-f0-9]{32}", receipt):
            raise ValueError
        if (type(identity) not in (float, int) or not math.isfinite(identity) or identity <= 0
                or not isinstance(save["role_name"], str) or not isinstance(role, dict)
                or not isinstance(receipts, list)
                or any(not isinstance(token, str) or not re.fullmatch(r"[a-f0-9]{32}", token) for token in receipts)):
            raise ValueError
        # 首次选将已置has_role，但Role快照要等紧接着的初始化才生成。
        if not save.get("role_snapshot") and role.get("level") == 1 and not receipts:
            return
        rid = pb_get_varint(bytes.fromhex(save["role_snapshot"]), 1)
        if (type(rid) is not int or not 0 < rid < (1 << 31)
                or any(type(role[k]) is not int or not 0 <= role[k] < (1 << 31)
                       for k in ("level", "vip", "power", "profile"))):
            raise ValueError
    except (ValueError, KeyError, TypeError, OverflowError):
        raise ValueError("账号公会身份或角色数据损坏，请恢复存档") from None


def validate(state):
    def integer(value, low=0, high=(1 << 31) - 1):
        if type(value) is not int or not low <= value <= high:
            raise ValueError("公会数值无效")

    def identity(key, row):
        if not isinstance(key, str) or not re.fullmatch(r"[1-9][0-9]{0,3}", key) or int(key) > 1000:
            raise ValueError("公会账号无效")
        value = row["identity"]
        if type(value) not in (float, int) or not math.isfinite(value) or value <= 0:
            raise ValueError("公会角色身份无效")

    if type(state["version"]) is not int or state["version"] != 1 or not isinstance(state["guilds"], dict) or not isinstance(state["cooldowns"], dict):
        raise ValueError("公会格式无效")
    integer(state["next_id"], 1)
    integer(state["checked_at"])
    guild_games.guild_war.validate(state)
    names, members = set(), set()
    for key, row in state["guilds"].items():
        if not isinstance(key, str) or not key.isdecimal() or str(int(key)) != key:
            raise ValueError("公会编号无效")
        integer(int(key), 1, state["next_id"] - 1)
        if (not valid_text(row["name"], 12, 1) or row["name"].casefold() in names
                or not valid_text(row["content"], 50) or not valid_text(row["declaration"], 50)):
            raise ValueError("公会名称或公告无效")
        names.add(row["name"].casefold())
        integer(row["created_at"])
        integer(row["auto"], 0, 1)
        integer(row["min_level"], 1, 120)
        integer(row.get("experience", 0), high=(1 << 63) - 1)
        fishpond_state(row)
        guild_chat.validate(row)
        guild_games.validate(row)
        events = row.get("events", [])
        integer(row.get("next_event", 1), 1)
        if not isinstance(events, list) or len(events) > 200:
            raise ValueError("公会动态无效")
        previous = 0
        for event in events:
            integer(event["id"], previous + 1, row.get("next_event", 1) - 1)
            previous = event["id"]
            integer(event["at"])
            integer(event["opt"], 1, 12)
            if any(not valid_text(event[k], 512) for k in ("name", "other", "content", "status", "param")):
                raise ValueError("公会动态内容无效")
        if not row["members"] or not isinstance(row["applications"], dict):
            raise ValueError("公会成员无效")
        posts = []
        for account, member in row["members"].items():
            identity(account, member)
            integer(member["joined_at"])
            integer(member["post"], 0, 2)
            integer(member.get("seen_at", 0))
            if account in members:
                raise ValueError("角色重复加入公会")
            members.add(account)
            posts.append(member["post"])
        if posts.count(1) != 1 or posts.count(2) > 3:
            raise ValueError("公会职务无效")
        for account, application in row["applications"].items():
            identity(account, application)
            integer(application["at"])
        if "pending" in row:
            pending = row["pending"]
            if (list(row["members"]) != [pending["account"]]
                    or not re.fullmatch(r"[a-f0-9]{32}", pending["token"])):
                raise ValueError("公会创建收据无效")
        if "pending_pray" in row:
            pending = row["pending_pray"]
            identity(pending["account"], pending)
            integer(pending["exp"], 1)
            if (pending["account"] not in row["members"]
                    or pending["identity"] != row["members"][pending["account"]]["identity"]
                    or not re.fullmatch(r"[a-f0-9]{32}", pending["token"])
                    or row.get("experience", 0) + pending["exp"] >= (1 << 63)):
                raise ValueError("公会上香收据无效")
            event = pending.get("event")
            if event is not None and (not isinstance(event, list) or len(event) != 5
                    or type(event[0]) is not int or not 0 <= event[0] < (1 << 31) or type(event[1]) is not int or event[1] != 3
                    or not valid_text(event[2], 64, 1) or event[3] not in ("1", "2", "3") or event[4] != str(pending["exp"])):
                raise ValueError("公会上香动态无效")
    for account, cooldown in state["cooldowns"].items():
        identity(account, cooldown)
        integer(cooldown["left_at"])
    pending = [(key, row["pending_action"]) for key, row in state["guilds"].items() if "pending_action" in row]
    if len(pending) > 1:
        raise ValueError("公会存在未完成的事务")
    for key, action in pending:
        identity(action["account"], action)
        after = action["after"]
        member = state["guilds"][key]["members"].get(action["account"])
        if (not member or member["identity"] != action["identity"]
                or not isinstance(action["token"], str) or not re.fullmatch(r"[a-f0-9]{32}", action["token"])
                or not isinstance(after, dict) or any(k in after for k in ("pending", "pending_pray", "pending_action"))
                or after.get("members") != state["guilds"][key]["members"]):
            raise ValueError("公会事务收据无效")
        candidate = copy.deepcopy(state)
        candidate["guilds"][key] = after
        if "war_after" in action:
            candidate["war"] = action["war_after"]
        validate(candidate)


def write(path, state):
    validate(state)
    storage.atomic_write(path, json.dumps(state, ensure_ascii=False, allow_nan=False).encode("utf-8"))
    try:
        from . import db
        db_path = db.get_db_path(path)
        db.save_guild(db_path, state)
    except Exception:
        pass


def recover(state, saves):
    """只认已随扣款落盘的创建收据；未扣款的草稿不可见。"""
    for gid, row in list(state["guilds"].items()):
        action = row.pop("pending_action", None)
        if action:
            saved = saves.get(int(action["account"]), {})
            if saved.get("created_at") == action["identity"] and saved.get("guild_action_receipt") == action["token"]:
                row = state["guilds"][gid] = action["after"]
                if "war_after" in action:
                    state["war"] = action["war_after"]
        pending = row.get("pending")
        if pending:
            saved = saves.get(int(pending["account"]), {})
            if pending["token"] not in saved.get("guild_creations", []):
                del state["guilds"][gid]
                continue
            del row["pending"]
        pending = row.pop("pending_pray", None)
        if pending:
            saved = saves.get(int(pending["account"]), {})
            if saved.get("created_at") == pending["identity"] and daily_state(saved)["receipt"] == pending["token"]:
                row["experience"] = row.get("experience", 0) + pending["exp"]
                if "event" in pending:
                    log(row, *pending["event"])
        for group in (row["members"], row["applications"]):
            for account, entry in list(group.items()):
                if saves.get(int(account), {}).get("created_at") != entry["identity"]:
                    del group[account]
                elif not saves[int(account)].get("role_snapshot"):
                    raise ValueError("公会成员角色快照缺失，请恢复存档")
        if not row["members"]:
            del state["guilds"][gid]
        elif not any(m["post"] == 1 for m in row["members"].values()):
            # 管理员重建会长角色时，由最早入会的现存成员接任，旧身份不继承权限。
            successor = min(row["members"], key=lambda a: (row["members"][a]["joined_at"], int(a)))
            row["members"][successor]["post"] = 1
    joined = {account for row in state["guilds"].values() for account in row["members"]}
    for row in state["guilds"].values():
        for account in joined:
            row["applications"].pop(account, None)
    for account, entry in list(state["cooldowns"].items()):
        if saves.get(int(account), {}).get("created_at") != entry["identity"]:
            del state["cooldowns"][account]


def membership(state, account):
    return next(((gid, g) for gid, g in state["guilds"].items() if str(account) in g["members"]), (None, None))


def role_id(account, viewer, saves):
    return pb_get_varint(bytes.fromhex(saves[account]["role_snapshot"]), 1) if account == viewer else 1000000 + account


def target_account(rid, viewer, saves):
    account = viewer if rid == role_id(viewer, viewer, saves) else rid - 1000000
    if account not in saves or account == viewer:
        raise ValueError("请选择当前列表中的其他本地角色")
    return account


def power(row, saves):
    return sum(saves[int(a)]["role_state"]["power"] for a in row["members"])


def progress(row, config):
    level, exp = 1, row.get("experience", 0)
    while str(level + 1) in config["gang2_level"] and exp >= config["gang2_level"][str(level)]["gang_exp"]:
        exp -= config["gang2_level"][str(level)]["gang_exp"]
        level += 1
    return level, min(exp, config["gang2_level"][str(level)]["gang_exp"])


def log(row, now, opt, name, other="", content="", status="", param=""):
    index = row.get("next_event", 1)
    row.setdefault("events", []).append({"id": index, "at": now, "opt": opt, "name": str(name),
                                        "other": str(other), "content": str(content), "status": str(status), "param": str(param)})
    row["events"] = row["events"][-200:]
    row["next_event"] = index + 1


def stage_action(state, before, account, save):
    """共享变化先作草稿；只有随个人扣款/奖励保存的收据才能发布。"""
    gid, row = membership(state, account)
    if row == before["guilds"][gid] and state.get("war") == before.get("war"):
        return
    token = secrets.token_hex(16)
    save["guild_action_receipt"] = token
    pending = copy.deepcopy(before["guilds"][gid])
    pending["pending_action"] = {"account": str(account), "identity": save["created_at"], "token": token, "after": row}
    if state.get("war") != before.get("war"):
        pending["pending_action"]["war_after"] = state.pop("war")
        if "war" in before:
            state["war"] = copy.deepcopy(before["war"])
    state["guilds"][gid] = pending


def daily_state(save, now=None):
    state = save.get("guild_daily_state", {"day": 0, "pray": 0, "claimed": False, "contribution": 0, "receipt": ""})
    if (not isinstance(state, dict)
            or any(type(state.get(k)) is not int or not 0 <= state[k] < (1 << 31) for k in ("day", "contribution"))
            or type(state.get("pray")) is not int or not 0 <= state["pray"] <= 3
            or type(state.get("claimed")) is not bool or not isinstance(state.get("receipt"), str)
            or state["receipt"] and not re.fullmatch(r"[a-f0-9]{32}", state["receipt"])):
        raise ValueError("公会日常存档无效")
    state = dict(state)
    state.setdefault("total_contribution", state["contribution"])
    state.setdefault("soap_used", 0)
    state.setdefault("soap_contribution", 0)
    state.setdefault("fish_claimed", [])
    state.setdefault("shop", {})
    if (any(type(state[k]) is not int or not 0 <= state[k] < (1 << 31)
            for k in ("total_contribution", "soap_used", "soap_contribution"))
            or state["total_contribution"] < state["contribution"]
            or not isinstance(state["fish_claimed"], list)
            or any(type(n) is not int or n not in range(1, 5) for n in state["fish_claimed"])
            or len(set(state["fish_claimed"])) != len(state["fish_claimed"])
            or not isinstance(state["shop"], dict)
            or any(not isinstance(k, str) or not k.isdecimal() or str(int(k)) != k or int(k) < 1
                   or type(v) is not int or not 0 <= v < (1 << 31) for k, v in state["shop"].items())):
        raise ValueError("公会贡献或玩法存档无效")
    state["fish_claimed"] = list(state["fish_claimed"])
    state["shop"] = dict(state["shop"])
    if now is not None and (now + 28800) // 86400 > state["day"]:
        state.update(day=(now + 28800) // 86400, pray=0, claimed=False, soap_used=0, soap_contribution=0, fish_claimed=[], shop={})
    return state


def change_contribution(daily, delta):
    total = daily["total_contribution"] + max(0, delta)
    if not 0 <= daily["contribution"] + delta < (1 << 31) or total >= (1 << 31):
        raise ValueError("公会贡献不足或超出范围")
    daily["contribution"] += delta
    daily["total_contribution"] = total


def prepare_daily(opcode, body, state, save, viewer, config, now):
    _, row = membership(state, viewer)
    if row is None or not save.get("has_role") or save["role_state"]["level"] < config["build"]["28"]["level"]:
        raise ValueError("请先加入已解锁的公会")
    daily = daily_state(save, now)
    save["guild_daily_state"] = daily
    if opcode == 2251:
        method, = request_ids(body, 1)
        incense = config["gang2_incense"].get(str(method))
        if not incense or daily["pray"]:
            raise ValueError("上香档位无效或今日已贡献，请明日再来")
        if method == 3 and not config["vip"][str(save["role_state"]["vip"])]["for_200"]:
            raise ValueError("此档上香需要贵族3及以上")
        cid, cost = map(int, incense["param"].rstrip(";").split(","))
        contribution, exp = incense["contribution"], incense["gang_exp"]
        if (cid not in (1000, 1001) or type(cost) is not int or not 0 < cost < (1 << 31)
                or type(contribution) is not int or not 0 < contribution < (1 << 31)
                or type(exp) is not int or not 0 < exp < (1 << 31)
                or daily["contribution"] + contribution >= (1 << 31)):
            raise ValueError("上香配置或贡献数量无效")
        change_contribution(daily, contribution)
        daily.update(pray=method, receipt=secrets.token_hex(16))
        row["pending_pray"] = {"account": str(viewer), "identity": save["created_at"], "token": daily["receipt"], "exp": exp,
                               "event": [now, 3, save["role_name"], str(method), str(exp)]}
        return ids([contribution, exp, 0]), [(cid, cost)], b""
    request_ids(body, 0)
    if opcode == 2250:
        return ids([daily["pray"]]), [], b""
    if daily["claimed"]:
        raise ValueError("今日公会奖励已领取，请明日再来")
    level, _ = progress(row, config)
    reward = activities.build_reward(save, config["gang2_level"][str(level)]["param"], config)
    daily["claimed"] = True
    return reward, [], reward


def fishpond_state(row, now=None):
    state = row.get("fishpond", {"day": 0, "experience": 0, "progress": 0})
    if (not isinstance(state, dict) or any(type(state.get(k)) is not int or not 0 <= state[k] < (1 << 31)
                                         for k in ("day", "experience", "progress"))):
        raise ValueError("公会仙池存档无效")
    state = dict(state)
    if now is not None and (now + 28800) // 86400 > state["day"]:
        state.update(day=(now + 28800) // 86400, progress=0)
    return state


def pond_status(row, daily, config, now):
    level, _ = progress(row, config)
    setting = config["gang2_fishpond"][str(config["gang2_level"][str(level)]["fishpondid"])]
    pond = fishpond_state(row, now)
    exp, fish_level = pond["experience"], 1
    while fish_level < setting["level"]:
        required = config["gang2_fishpondexp"][str(fish_level)]["exp" + str(setting["quality"])]
        if exp < required:
            break
        exp -= required
        fish_level += 1
    exp = min(exp, config["gang2_fishpondexp"][str(fish_level)]["exp" + str(setting["quality"])])
    boxes = [2 if n in daily["fish_claimed"] else int(pond["progress"] >= setting[f"milestone_award{n}"]) for n in range(1, 5)]
    return [setting["quality"], exp, fish_level, pond["progress"], *boxes, daily["soap_used"]]


def prepare_feature(opcode, body, state, save, viewer, config, now):
    _, row = membership(state, viewer)
    if row is None or not save.get("has_role") or save["role_state"]["level"] < config["build"]["28"]["level"]:
        raise ValueError("请先加入已解锁的公会")
    daily = daily_state(save, now)
    save["guild_daily_state"] = daily
    if opcode == 2259:
        name = request_text(body, 12, 1)
        if row["members"][str(viewer)]["post"] != 1:
            raise ValueError("只有会长可以修改公会名")
        if any(g["name"].casefold() == name.casefold() for g in state["guilds"].values()):
            raise ValueError("公会名未改变或与其他公会重复")
        row["name"] = name
        return ids([0]), [(1001, 300)], b""
    if opcode == 2252:
        request_ids(body, 0)
        return ids([daily["shop"].get(str(i), 0) for i in range(1, max(map(int, config["gang2_shop"])) + 1)]), [], b""
    if opcode == 2253:
        index, count = request_ids(body, 2)
        item = config["gang2_shop"].get(str(index))
        if (not item or not 1 <= count <= 100 or item["alone_cycle"] != 0
                or progress(row, config)[0] < item["gang_level"]
                or daily["shop"].get(str(index), 0) + count > item["number"]):
            raise ValueError("公会商品、等级、数量或今日限购无效")
        cid, cost = map(int, item["consume"].rstrip(";").split(","))
        if cid != 1006 or cost <= 0:
            raise ValueError("公会商店价格配置无效")
        reward = activities.build_reward(save, item["award"], config, count)
        change_contribution(daily, -cost * count)
        daily["shop"][str(index)] = daily["shop"].get(str(index), 0) + count
        return reward, [], reward
    if opcode == 2256:
        request_ids(body, 0)
        row["fishpond"] = fishpond_state(row, now)
        return ids(pond_status(row, daily, config, now)), [], b""
    if opcode == 2258:
        box, = request_ids(body, 1)
        if box not in range(1, 5) or pond_status(row, daily, config, now)[box + 3] != 1:
            raise ValueError("仙池宝箱未达进度或今日已领取")
        level, _ = progress(row, config)
        setting = config["gang2_fishpond"][str(config["gang2_level"][str(level)]["fishpondid"])]
        reward = activities.build_reward(save, setting[f"award{box}"], config)
        daily["fish_claimed"].append(box)
        return reward, [], reward
    fields = list(iter_pb_fields(body))
    values = request_ids(body, len(fields))
    pairs = list(zip(values[::2], values[1::2]))
    if (not 2 <= len(values) <= 8 or len(values) % 2 or len({cid for cid, _ in pairs}) != len(pairs)
            or any(str(cid) not in config["gang2_bait"] or count <= 0 for cid, count in pairs)
            or daily["soap_used"] + sum(count for _, count in pairs) > int(config["global_kv"]["gang2_fishpoind_limit"]["value"])):
        raise ValueError("肥皂类型、数量或每日使用上限无效")
    old = pond_status(row, daily, config, now)
    old_level, _ = progress(row, config)
    pond = fishpond_state(row, now)
    prizes, gang_exp, fish_exp, contribution = {}, 0, 0, 0
    for cid, count in pairs:
        bait = config["gang2_bait"][str(cid)]
        for entry in bait["award"].rstrip(";").split(";"):
            reward_cid, number = map(int, entry.split(","))
            prizes[reward_cid] = prizes.get(reward_cid, 0) + number * count
        gang_exp += bait["gang_exp"] * count
        fish_exp += bait["fish_exp"] * count
        contribution += bait["contribution"] * count
        pond["progress"] += bait["gang_milestone"] * count
        log(row, now, 9, save["role_name"], str(cid), status=str(bait["gang_exp"] * count))
    pond["experience"] += fish_exp
    row["experience"] = row.get("experience", 0) + gang_exp
    row["fishpond"] = pond
    change_contribution(daily, contribution)
    daily["soap_used"] += sum(count for _, count in pairs)
    daily["soap_contribution"] += contribution
    reward = activities.build_reward(save, ";".join(f"{cid},{number}" for cid, number in sorted(prizes.items())), config)
    current = pond_status(row, daily, config, now)
    new_level, exp = progress(row, config)
    quality_up = current[0] != old[0]
    reply = (message(0, ids([2 if quality_up else int(old_level != new_level), int(not quality_up and current[2] != old[2]), gang_exp, contribution, fish_exp]))
             + (message(1, ids([exp, new_level])) if new_level != old_level else b"")
             + message(2, ids(current)) + message(3, reward))
    return reply, pairs, reward


def list_row(gid, row, viewer, saves, config):
    leader = next(a for a, m in row["members"].items() if m["post"] == 1)
    return params([int(gid), row["name"], progress(row, config)[0], len(row["members"]), saves[int(leader)]["role_name"],
                   row["declaration"], power(row, saves), int(str(viewer) in row["applications"]), row["auto"], row["min_level"]])


def status(state, viewer, saves, config, now):
    gid, row = membership(state, viewer)
    if row is None:
        cooldown = state["cooldowns"].get(str(viewer))
        return message(0, params([2, cooldown["left_at"]]) if cooldown else params([0, 0]))
    level, exp = progress(row, config)
    daily = daily_state(saves[viewer], now)
    return (message(1, params([int(gid), row["name"], level, exp, row["content"], 0, 0, 0,
                                row["declaration"], len(row["members"]), power(row, saves)]))
            + message(2, ids([daily["contribution"], daily["total_contribution"], row["members"][str(viewer)]["joined_at"],
                              int(daily["claimed"]), 0, 0, 0, 0, 0, 0])))


def members(row, viewer, saves, online, now, config):
    posts = [0, 0, 0, 0]
    vice = 1
    result = b""
    for key, member in sorted(row["members"].items(), key=lambda p: int(p[0])):
        account = int(key)
        save, rid = saves[account], role_id(account, viewer, saves)
        role = save["role_state"]
        if member["post"] == 1:
            posts[0] = rid
        elif member["post"] == 2:
            posts[vice], vice = rid, vice + 1
        raw = bytes.fromhex(save["role_snapshot"])
        last_seen = max(int(save.get("last_login", now)), member.get("seen_at", 0))
        secs = 0 if account in online else max(1, now - last_seen)
        daily = daily_state(save, now)
        today = config["gang2_incense"][str(daily["pray"])]["contribution"] if daily["pray"] else 0
        today += daily["soap_contribution"]
        result += message(account, params([rid, save["role_name"], role["level"], role["power"], daily["total_contribution"], today, secs,
                                          role["profile"], role["vip"], 0, 0,
                                          pb_get_varint(raw, 23) or 35001, pb_get_varint(raw, 24) or 35501]))
    return message(0, ids(posts)) + result


def applications(row, viewer, saves):
    result = b""
    for key in sorted(row["applications"], key=int):
        account = int(key)
        save = saves[account]
        role, raw = save["role_state"], bytes.fromhex(save["role_snapshot"])
        body = (encode_pb_field(1, 0, role_id(account, viewer, saves))
                + encode_pb_field(2, 2, save["role_name"].encode("utf-8"))
                + b"".join(encode_pb_field(n, 0, v) for n, v in
                           ((3, role["level"]), (4, role["vip"]), (5, role["profile"]), (7, role["power"])))
                + encode_pb_field(8, 2, params([0, 0, pb_get_varint(raw, 23) or 35001, pb_get_varint(raw, 24) or 35501])))
        result += encode_pb_field(1, 2, body)
    return result


def prepare(opcode, body, state, saves, viewer, config, now, online):
    """修改尚未发布的共享副本；返回原生响应和创建所需的元宝。"""
    key, save = str(viewer), saves.get(viewer, {})
    if opcode == 2230:
        request_ids(body, 0)
        return status(state, viewer, saves, config, now), 0
    if not save.get("has_role") or save["role_state"]["level"] < config["build"]["28"]["level"]:
        raise ValueError("公会尚未解锁")
    gid, row = membership(state, viewer)
    kv = config["global_kv"]
    def capacity(target):
        return config["gang2_level"][str(progress(target, config)[0])]["people"]

    def eligible(account, target=None):
        data = saves[account]
        if membership(state, account)[1] is not None:
            raise ValueError("角色已加入公会")
        cooldown = state["cooldowns"].get(str(account))
        if cooldown and now < cooldown["left_at"] + int(kv["gang_quit_limit"]["value"]):
            raise ValueError("退出公会后的冷却尚未结束")
        if target is not None:
            if len(target["members"]) >= capacity(target):
                raise ValueError("公会人数已满")
            if data["role_state"]["level"] < max(target["min_level"], config["build"]["28"]["level"]):
                raise ValueError("等级未达到公会招募要求")

    def join(account, target):
        eligible(account, target)
        target["members"][str(account)] = {"identity": saves[account]["created_at"], "post": 0, "joined_at": now}
        log(target, now, 1, saves[account]["role_name"], save["role_name"])
        for g in state["guilds"].values():
            g["applications"].pop(str(account), None)

    def leave(account):
        if guild_games.member_busy(row, account, now):
            raise ValueError("请先结束公会活动并领取待结算奖励，再退出或移除成员")
        log(row, now, 2 if account == viewer else 10, saves[account]["role_name"])
        del row["members"][str(account)]
        state["cooldowns"][str(account)] = {"identity": saves[account]["created_at"], "left_at": now}

    if opcode == 2231:
        name = request_text(body, 12, 1)
        eligible(viewer)
        if save["role_state"]["level"] < int(kv["gang_establish_level"]["value"]):
            raise ValueError("等级未达到创建公会要求")
        if any(g["name"].casefold() == name.casefold() for g in state["guilds"].values()):
            raise ValueError("公会名重复，创建失败")
        gid = str(state["next_id"])
        state["next_id"] += 1
        state["guilds"][gid] = {"name": name, "content": "", "declaration": "", "created_at": now,
                                "auto": 0, "min_level": config["build"]["28"]["level"], "applications": {},
                                "members": {key: {"identity": save["created_at"], "post": 1, "joined_at": now}},
                                "pending": {"account": key, "token": secrets.token_hex(16)}}
        return ids([0]), int(kv["gang_establish_coin"]["value"])
    if opcode == 2232:
        request_ids(body, 0)
        return b"".join(message(int(i), list_row(i, g, viewer, saves, config)) for i, g in sorted(state["guilds"].items(), key=lambda p: int(p[0]))), 0
    if opcode == 2243:
        name = request_text(body, 12, 1)
        return next((list_row(i, g, viewer, saves, config) for i, g in state["guilds"].items() if g["name"].casefold() == name.casefold()), b""), 0
    if opcode in (2233, 2267):
        target_id, = request_ids(body, 1)
        eligible(viewer)
        if target_id and str(target_id) not in state["guilds"]:
            raise ValueError("公会不存在，请刷新列表")
        targets = [state["guilds"][str(target_id)]] if target_id else list(state["guilds"].values())
        if opcode == 2267:
            if not any(key in g["applications"] for g in targets):
                raise ValueError("没有待取消的公会申请")
            for g in targets:
                g["applications"].pop(key, None)
            return ids([0]), 0
        if target_id:
            eligible(viewer, targets[0])
        targets = [g for g in targets if len(g["members"]) < capacity(g) and save["role_state"]["level"] >= g["min_level"]]
        for g in targets:
            if g["auto"]:
                join(viewer, g)
                return ids([1]), 0
        targets = [g for g in targets if key not in g["applications"]]
        if not targets:
            raise ValueError("没有可申请的公会，或申请已提交")
        for g in targets:
            g["applications"][key] = {"identity": save["created_at"], "at": now}
        return ids([0]), 0
    if row is None:
        raise ValueError("您还没有加入公会")
    post = row["members"][key]["post"]
    if opcode == 2254:
        offset, count = request_ids(body, 2)
        if offset > (1 << 20) or not 1 <= count <= 100:
            raise ValueError("公会动态分页范围无效")
        events = list(reversed(row.get("events", [])))[offset:offset + count]
        return (message(-1, ids([offset])) + b"".join(message(offset + i + 1, params([
            event["opt"], event["at"], event["name"], event["other"], event["content"], event["status"], event["param"]]))
            for i, event in enumerate(events))), 0
    if opcode == 2255:
        request_ids(body, 0)
        leader = next(a for a, m in row["members"].items() if m["post"] == 1)
        last = max(int(saves[int(leader)].get("last_login", now)), row["members"][leader].get("seen_at", 0))
        limit = int(kv["gang_impeach_limit"]["value"])
        if leader == key or int(leader) in online or now - last < limit:
            raise ValueError(f"仅可弹劾连续离线满 {limit // 3600} 小时的会长")
        row["members"][leader]["post"] = 0
        row["members"][key]["post"] = 1
        log(row, now, 7, save["role_name"])
        return ids([0]), 0
    if opcode == 2261:
        request_ids(body, 0)
        entries = sorted(row["members"], key=lambda a: (-daily_state(saves[int(a)], now)["soap_contribution"], int(a)))
        result = b""
        for account in entries:
            data = saves[int(account)]
            role, raw = data["role_state"], bytes.fromhex(data["role_snapshot"])
            result += encode_pb_field(1, 2,
                encode_pb_field(1, 0, role_id(int(account), viewer, saves))
                + encode_pb_field(2, 2, data["role_name"].encode("utf-8"))
                + b"".join(encode_pb_field(n, 0, v) for n, v in ((3, role["level"]), (4, role["vip"]), (5, role["profile"]),
                    (7, daily_state(data, now)["soap_contribution"])))
                + encode_pb_field(8, 2, params([0, 0, pb_get_varint(raw, 23) or 35001, pb_get_varint(raw, 24) or 35501])))
        return result, 0
    if opcode == 2236:
        request_ids(body, 0)
        return members(row, viewer, saves, online, now, config), 0
    if opcode == 2242:
        request_ids(body, 0)
        if post == 1:
            raise ValueError("会长请先传位，只有最后一名成员可解散公会")
        leave(viewer)
        return ids([1]), 0
    if opcode == 2265 and not body:
        return ids([row["auto"], row["min_level"]]), 0
    if post not in (1, 2):
        raise ValueError("只有会长或副会长可以管理公会")
    if opcode == 2234:
        request_ids(body, 0)
        return applications(row, viewer, saves), 0
    if opcode == 2235:
        rid, option = request_ids(body, 2)
        account = target_account(rid, viewer, saves)
        if option not in (0, 1) or str(account) not in row["applications"]:
            raise ValueError("公会申请已失效或审批参数无效")
        if option == 0:
            join(account, row)
        else:
            del row["applications"][str(account)]
        return ids([0 if option == 0 else 2005]), 0
    if opcode in (2237, 2238):
        row["content" if opcode == 2237 else "declaration"] = request_text(body, 50)
        return ids([1]), 0
    if opcode == 2265:
        auto, minimum = request_ids(body, 2)
        if auto not in (0, 1) or not 1 <= minimum <= 120:
            raise ValueError("自动招募设置无效")
        row.update(auto=auto, min_level=minimum)
        return ids([auto, minimum]), 0
    if opcode == 2266:
        request_ids(body, 0)
        if post != 1 or len(row["members"]) != 1:
            raise ValueError("只有最后一名会长可以解散公会，请先传位")
        leave(viewer)
        del state["guilds"][gid]
        return ids([0]), 0
    if opcode in (2239, 2240, 2241):
        values = request_ids(body, 2 if opcode == 2239 else 1)
        account = target_account(values[-1], viewer, saves)
        target = row["members"].get(str(account))
        if not target or target["post"] == 1:
            raise ValueError("目标不是可管理的本公会成员")
        if opcode == 2240:
            if post == 2 and target["post"] != 0:
                raise ValueError("副会长只能移除普通成员")
            leave(account)
        else:
            if post != 1:
                raise ValueError("只有会长可以任命副会长或传位")
            if opcode == 2241:
                if target["post"] != 2:
                    raise ValueError("请先将接任者任命为副会长")
                target["post"], row["members"][key]["post"] = 1, 0
                log(row, now, 6, saves[account]["role_name"])
            else:
                option = values[0]
                if option not in (0, 1) or target["post"] != (0 if option == 0 else 2):
                    raise ValueError("副会长任免状态已变化")
                if option == 0 and sum(m["post"] == 2 for m in row["members"].values()) >= 3:
                    raise ValueError("副会长人数已达上限")
                target["post"] = 2 if option == 0 else 0
                log(row, now, 4 if option == 0 else 5, saves[account]["role_name"])
        return ids([1]), 0
    raise ValueError("此公会操作尚未开放")
