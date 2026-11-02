"""公会文字聊天：身份由账号绑定，有限历史和逐连接游标。"""

import math

from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint


OPCODES = (3010, 3011)


def validate(row):
    chats = row.get("chats", [])
    index = row.get("next_chat", 1)
    if not isinstance(chats, list) or len(chats) > 100 or type(index) is not int or not 1 <= index < (1 << 31):
        raise ValueError("公会聊天历史无效")
    previous = 0
    for chat in chats:
        if (any(type(chat[k]) is not int or not 0 <= chat[k] < (1 << 31) for k in ("id", "at", "account"))
                or not previous < chat["id"] < index or not 1 <= chat["account"] <= 1000
                or type(chat["identity"]) not in (int, float) or not math.isfinite(chat["identity"]) or chat["identity"] <= 0
                or not isinstance(chat["text"], str) or not 1 <= len(chat["text"]) <= 200 or not chat["text"].isprintable()
                or not isinstance(chat["name"], str) or not 1 <= len(chat["name"]) <= 64 or not chat["name"].isprintable()
                or any(type(chat[k]) is not int or not 0 <= chat[k] < (1 << 31) for k in
                       ("level", "vip", "profile", "icon_box", "title"))):
            raise ValueError("公会聊天记录无效")
        previous = chat["id"]


def request_text(body, own_rid):
    fields = list(iter_pb_fields(body))
    if len(fields) != 1 or fields[0][:2] != (2, 2):
        raise ValueError("聊天需要一条公会消息")
    fields = list(iter_pb_fields(fields[0][2]))
    if sorted((n, w) for n, w, _ in fields) != [(1, 0), (2, 2)]:
        raise ValueError("公会消息参数无效")
    values = {n: v for n, _, v in fields}
    if values[1] != own_rid:
        raise ValueError("公会消息不能冒用其他角色")
    try:
        text = values[2].decode("utf-8")
    except UnicodeError:
        raise ValueError("聊天文字编码无效") from None
    if not 1 <= len(text) <= 200 or not text.isprintable() or not text.strip():
        raise ValueError("聊天内容须为 1–200 个可显示字符")
    if "&&&" in text or "<" in text or ">" in text:
        raise ValueError("请使用活动页面的邀请按钮")
    return text


def prepare(opcode, body, state, saves, viewer, config, now, cursor):
    from . import guild

    gid, row = guild.membership(state, viewer)
    if opcode == 3010:
        if body:
            if guild.request_ids(body, 1) != [0]:
                raise ValueError("公会聊天查询参数无效")
            cursor = None
        if row is None:
            return b"", None
    elif row is None:
        raise ValueError("请先加入公会再发言")
    if saves[viewer]["role_state"]["level"] < config["build"]["28"]["level"]:
        raise ValueError("公会聊天尚未解锁")
    if opcode == 3011:
        save = saves[viewer]
        role = save["role_state"]
        if (role["level"] < int(config["global_kv"]["chat_level"]["value"])
                or role["power"] < int(config["global_kv"]["guild_chat_power"]["value"])):
            raise ValueError("等级或战力未达到公会发言要求")
        raw = bytes.fromhex(save["role_snapshot"])
        text = request_text(body, pb_get_varint(raw, 1))
        previous = next((c for c in reversed(row.get("chats", []))
                         if c["account"] == viewer and c["identity"] == save["created_at"]), None)
        if previous and now - previous["at"] < 5:
            raise ValueError("公会发言间隔为 5 秒")
        index = row.get("next_chat", 1)
        row.setdefault("chats", []).append({"id": index, "at": now, "account": viewer, "identity": save["created_at"], "text": text,
            "name": save["role_name"], "level": role["level"], "vip": role["vip"], "profile": role["profile"],
            "icon_box": pb_get_varint(raw, 23) or 35001, "title": pb_get_varint(raw, 24) or 35501})
        row["chats"] = row["chats"][-100:]
        row["next_chat"] = index + 1
    start = cursor[1] if cursor and cursor[0] == gid else 0
    # 账号编号可复用，旧角色的消息不能关联到重建后的新角色。
    chats = [c for c in row.get("chats", []) if c["id"] > start
             and saves.get(c["account"], {}).get("created_at") == c["identity"]]
    result, players = b"", set()
    for chat in chats:
        own = chat["account"] == viewer and chat["identity"] == saves[viewer]["created_at"]
        rid = guild.role_id(viewer, viewer, saves) if own else 1000000 + chat["account"]
        if rid not in players:
            players.add(rid)
            result += encode_pb_field(1, 2, encode_pb_field(1, 0, rid) + encode_pb_field(2, 2, chat["name"].encode("utf-8"))
                + b"".join(encode_pb_field(n, 0, chat[k]) for n, k in ((3, "level"), (4, "vip"), (5, "profile")))
                + encode_pb_field(7, 0, 0) + encode_pb_field(8, 2, guild.params([0, 0, chat["icon_box"], chat["title"]])))
        result += encode_pb_field(2, 2, encode_pb_field(1, 0, rid) + encode_pb_field(2, 2, chat["text"].encode("utf-8"))
                                  + encode_pb_field(3, 0, chat["at"]))
    return result, (gid, row.get("next_chat", 1) - 1)
