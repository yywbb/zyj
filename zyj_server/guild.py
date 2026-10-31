"""本地基础公会；共享成员状态独立落盘，创建扣款以角色收据确认。"""

import json
import math
import re
import secrets

from . import storage
from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint


OPCODES = (*range(2230, 2244), 2265, 2266, 2267)


def ids(values):
    return b"".join(encode_pb_field(1, 0, n) for n in values)


def params(values):
    return b"".join(encode_pb_field(1, 2, encode_pb_field(2, 2, v.encode("utf-8")) if isinstance(v, str)
                    else encode_pb_field(1, 0, v & ((1 << 64) - 1))) for v in values)


def message(mid, data):
    return encode_pb_field(1, 2, encode_pb_field(1, 0, mid) + encode_pb_field(2, 2, data))


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
        if any(s.get("guild_creations") for s in saves.values()):
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
        if not row["members"] or not isinstance(row["applications"], dict):
            raise ValueError("公会成员无效")
        posts = []
        for account, member in row["members"].items():
            identity(account, member)
            integer(member["joined_at"])
            integer(member["post"], 0, 2)
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
    for account, cooldown in state["cooldowns"].items():
        identity(account, cooldown)
        integer(cooldown["left_at"])


def write(path, state):
    validate(state)
    storage.atomic_write(path, json.dumps(state, ensure_ascii=False, allow_nan=False).encode("utf-8"))


def recover(state, saves):
    """只认已随扣款落盘的创建收据；未扣款的草稿不可见。"""
    for gid, row in list(state["guilds"].items()):
        pending = row.get("pending")
        if pending:
            saved = saves.get(int(pending["account"]), {})
            if pending["token"] not in saved.get("guild_creations", []):
                del state["guilds"][gid]
                continue
            del row["pending"]
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


def list_row(gid, row, viewer, saves):
    leader = next(a for a, m in row["members"].items() if m["post"] == 1)
    return params([int(gid), row["name"], 1, len(row["members"]), saves[int(leader)]["role_name"],
                   row["declaration"], power(row, saves), int(str(viewer) in row["applications"]), row["auto"], row["min_level"]])


def status(state, viewer, saves):
    gid, row = membership(state, viewer)
    if row is None:
        cooldown = state["cooldowns"].get(str(viewer))
        return message(0, params([2, cooldown["left_at"]]) if cooldown else params([0, 0]))
    return (message(1, params([int(gid), row["name"], 1, 0, row["content"], 0, 0, 0,
                               row["declaration"], len(row["members"]), power(row, saves)]))
            + message(2, ids([0, 0, row["members"][str(viewer)]["joined_at"], 0, 0, 0, 0, 0, 0, 0])))


def members(row, viewer, saves, online, now):
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
        secs = 0 if account in online else max(1, now - int(save.get("last_login", now)))
        result += message(account, params([rid, save["role_name"], role["level"], role["power"], 0, 0, secs,
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
        return status(state, viewer, saves), 0
    if not save.get("has_role") or save["role_state"]["level"] < config["build"]["28"]["level"]:
        raise ValueError("公会尚未解锁")
    gid, row = membership(state, viewer)
    kv = config["global_kv"]
    capacity = config["gang2_level"]["1"]["people"]

    def eligible(account, target=None):
        data = saves[account]
        if membership(state, account)[1] is not None:
            raise ValueError("角色已加入公会")
        cooldown = state["cooldowns"].get(str(account))
        if cooldown and now < cooldown["left_at"] + int(kv["gang_quit_limit"]["value"]):
            raise ValueError("退出公会后的冷却尚未结束")
        if target is not None:
            if len(target["members"]) >= capacity:
                raise ValueError("公会人数已满")
            if data["role_state"]["level"] < max(target["min_level"], config["build"]["28"]["level"]):
                raise ValueError("等级未达到公会招募要求")

    def join(account, target):
        eligible(account, target)
        target["members"][str(account)] = {"identity": saves[account]["created_at"], "post": 0, "joined_at": now}
        for g in state["guilds"].values():
            g["applications"].pop(str(account), None)

    def leave(account):
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
        return b"".join(message(int(i), list_row(i, g, viewer, saves)) for i, g in sorted(state["guilds"].items(), key=lambda p: int(p[0]))), 0
    if opcode == 2243:
        name = request_text(body, 12, 1)
        return next((list_row(i, g, viewer, saves) for i, g in state["guilds"].items() if g["name"].casefold() == name.casefold()), b""), 0
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
        targets = [g for g in targets if len(g["members"]) < capacity and save["role_state"]["level"] >= g["min_level"]]
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
    if opcode == 2236:
        request_ids(body, 0)
        return members(row, viewer, saves, online, now), 0
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
            else:
                option = values[0]
                if option not in (0, 1) or target["post"] != (0 if option == 0 else 2):
                    raise ValueError("副会长任免状态已变化")
                if option == 0 and sum(m["post"] == 2 for m in row["members"].values()) >= 3:
                    raise ValueError("副会长人数已达上限")
                target["post"] = 2 if option == 0 else 0
        return ids([1]), 0
    raise ValueError("此公会操作尚未开放")
