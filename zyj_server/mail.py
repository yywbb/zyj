"""系统邮件与 GM 邮件；管理全服/个人邮件存储、奖励发放与领取状态。"""

import copy
import json
from pathlib import Path
import time

from . import activities, examination, player, protocol, ranking, recharge, recruit, storage, world_boss


def load_mails(path):
    path = Path(path)
    if not path.exists():
        return {"next_id": 800000001, "mails": []}
    try:
        data = json.loads(path.read_bytes())
        if not isinstance(data, dict):
            return {"next_id": 800000001, "mails": []}
        data.setdefault("next_id", 800000001)
        data.setdefault("mails", [])
        return data
    except (ValueError, OSError):
        return {"next_id": 800000001, "mails": []}


def save_mails(path, data):
    path = Path(path)
    storage.atomic_write(path, json.dumps(data, ensure_ascii=False, allow_nan=False).encode("utf-8"))


def send_mail(path, target, title, content, attachments=None, recharge_info=None, card=0, sender="GM", now=None):
    if not isinstance(title, str) or not title.strip() or len(title) > 50:
        raise ValueError("邮件标题须为 1~50 个字符")
    if not isinstance(content, str) or len(content) > 500:
        raise ValueError("邮件内容不能超过 500 个字符")
    if target not in (0, "all") and (type(target) is not int or not 1 <= target <= 1000):
        raise ValueError("邮件目标必须为 'all' 或 1~1000 的账号编号")
    if card not in (0, 1, 2):
        raise ValueError("充值月卡类型无效")

    norm_target = 0 if target in (0, "all") else int(target)
    attach = {}
    if attachments:
        if not isinstance(attachments, dict):
            raise ValueError("附件必须为键值对")
        for k, v in attachments.items():
            cid, count = int(k), int(v)
            limit = 1 << (63 if cid == 1000 else 31)
            if not 0 < count < limit:
                raise ValueError("附件物品数量无效")
            total = attach.get(str(cid), 0) + count
            if total >= limit:
                raise ValueError("附件物品数量无效")
            attach[str(cid)] = total

    # 特殊礼包（如 20081 天机令大礼包）在邮件发出的瞬间自动拆包为所有天机令与激活材料，
    # 避免未重打 APK 的客户端将 20081 显示为原版的“删除道具（金币图标）”。
    if "20081" in attach:
        pack_count = attach.pop("20081")
        for cid in range(201901, 201925):
            attach[str(cid)] = min((1 << 31) - 1, attach.get(str(cid), 0) + pack_count)
        for cid in range(192596, 192600):
            attach[str(cid)] = min((1 << 31) - 1, attach.get(str(cid), 0) + 1160 * pack_count)
    rmb = 0
    if recharge_info:
        if not isinstance(recharge_info, dict):
            raise ValueError("充值信息必须为对象")
        rmb = int(recharge_info.get("rmb", 0))
        gold = int(recharge_info.get("gold", 0))
        if rmb < 0 or gold < 0 or rmb >= (1 << 31) or gold >= (1 << 31):
            raise ValueError("充值金额无效")
        if rmb > 0:
            attach["1008"] = attach.get("1008", 0) + rmb
        if gold > 0:
            attach["1001"] = attach.get("1001", 0) + gold
        if recharge_info.get("card"):
            card = int(recharge_info["card"])

    if card == 1:
        # 月卡：立即获得250元宝，25元充值额度
        attach["1001"] = attach.get("1001", 0) + 250
        attach["1008"] = attach.get("1008", 0) + 25
    elif card == 2:
        # 终身卡：立即获得980元宝，98元充值额度
        attach["1001"] = attach.get("1001", 0) + 980
        attach["1008"] = attach.get("1008", 0) + 98

    if now is None:
        now = int(time.time())

    state = load_mails(path)
    mail_id = state["next_id"]
    state["next_id"] += 1

    entry = {
        "id": mail_id,
        "target": norm_target,
        "title": title.strip(),
        "content": content.strip(),
        "attachments": attach,
        "card": card,
        "recharge_rmb": rmb if rmb > 0 else (25 if card == 1 else (98 if card == 2 else 0)),
        "created_at": now,
        "sender": sender
    }
    state["mails"].append(entry)
    save_mails(path, state)
    try:
        from . import db
        db_path = db.get_db_path(path)
        if db_path.exists():
            db.save_mail(db_path, entry)
    except Exception:
        pass
    return entry


def delete_mail(path, mail_id):
    state = load_mails(path)
    initial_len = len(state["mails"])
    state["mails"] = [m for m in state["mails"] if m["id"] != mail_id]
    if len(state["mails"]) != initial_len:
        save_mails(path, state)
        try:
            from . import db
            db_path = db.get_db_path(path)
            db.delete_mail(db_path, mail_id)
        except Exception:
            pass
        return True
    return False


def list_mails(path, account=None, offset=0, limit=50):
    state = load_mails(path)
    rows = state["mails"]
    if account is not None:
        rows = [m for m in rows if m["target"] in (0, account)]
    rows.sort(key=lambda m: (m.get("created_at", 0), m["id"]), reverse=True)
    return {
        "rows": rows[offset:offset + limit],
        "total": len(rows),
        "offset": offset
    }


def get_player_mails(mail_path, save, viewer, ranking_state, config, world_mails=None, examination_mails=None):
    mails = {}

    # 1. 排名奖励邮件 (700000001 ~ 700000010)
    if ranking_state:
        rank_claims = save.setdefault("rank_mail_state", {"period": ranking_state["opened_at"], "claimed": [], "deleted": []})
        r_mails = ranking.reward_mails(ranking_state, viewer, save.get("created_at", 0), config)
        for mid, row in r_mails.items():
            if mid not in rank_claims["deleted"]:
                mails[mid] = {
                    "id": mid,
                    "type": 0,
                    "title": row["title"],
                    "content": row["content"],
                    "attachments": {str(cid): n for cid, n in row["gets"]},
                    "second": row["second"],
                    "status": 2 if mid in rank_claims["claimed"] else 0,
                    "is_rank": True,
                    "gets": row["gets"],
                    "card": 0
                }

    # 2. GM 系统邮件 (800000001+)
    if mail_path:
        gm_claims = save.setdefault("mail_state", {"claimed": [], "deleted": []})
        state = load_mails(mail_path)
        for row in state["mails"]:
            mid = row["id"]
            if mid in gm_claims["deleted"]:
                continue
            if row["target"] != 0 and row["target"] != viewer:
                continue
            gets = [(int(cid), count) for cid, count in row.get("attachments", {}).items()]
            mails[mid] = {
                "id": mid,
                "type": 0,
                "title": row["title"],
                "content": row.get("content", ""),
                "attachments": {str(cid): count for cid, count in row.get("attachments", {}).items()},
                "second": row.get("created_at", 0),
                "status": 2 if mid in gm_claims["claimed"] else 0,
                "is_rank": False,
                "gets": gets,
                "card": row.get("card", 0),
                "recharge_rmb": row.get("recharge_rmb", 0)
            }

    claims = world_boss.get_state(save)
    for mid, row in (world_mails or {}).items():
        if mid not in claims["deleted"]:
            mails[mid] = {**row, "id": mid, "type": 0, "attachments": {str(cid): n for cid, n in row["gets"]},
                          "status": 2 if mid in claims["claimed"] else 0, "is_rank": False, "is_world_boss": True, "card": 0}
    exam_claims = examination.get_state(save, config)
    for mid, row in (examination_mails or {}).items():
        if mid not in exam_claims["deleted"]:
            mails[mid] = {**row, "id": mid, "type": 0, "attachments": {str(cid): n for cid, n in row["gets"]},
                          "status": 2 if mid in exam_claims["claimed"] else 0, "is_rank": False, "is_examination": True, "card": 0}
    return mails


def has_unclaimed(mail_path, save, viewer, ranking_state, config):
    mails = get_player_mails(mail_path, save, viewer, ranking_state, config)
    return any(m["status"] == 0 and bool(m["attachments"]) for m in mails.values())


def prepare(opcode, save, body, mail_path, ranking_state, viewer, config, now=None, *, world_mails=None, examination_mails=None):
    if now is None:
        now = int(time.time())

    rank_claims = save.setdefault("rank_mail_state", {"period": ranking_state["opened_at"] if ranking_state else 0, "claimed": [], "deleted": []})
    gm_claims = save.setdefault("mail_state", {"claimed": [], "deleted": []})

    mails = get_player_mails(mail_path, save, viewer, ranking_state, config, world_mails, examination_mails)
    world_claims = world_boss.get_state(save)
    exam_claims = examination.get_state(save, config)

    if opcode == 3100:
        if body:
            raise ValueError("邮件查询不接受参数")
        result = b""
        for mid, row in sorted(mails.items()):
            raw = b"".join(protocol.encode_pb_field(n, 0, v) for n, v in
                           ((1, mid), (2, 0), (3, 0), (4, row["status"]), (8, row["second"])))
            attachment_json = json.dumps(row["attachments"])
            for field, text in ((5, row["title"]), (6, row["content"]), (7, attachment_json)):
                raw += protocol.encode_pb_field(field, 2, text.encode("utf-8"))
            result += protocol.encode_pb_field(2, 2, raw)
        return result, b""

    fields = list(protocol.iter_pb_fields(body))
    if not fields or any((n, w) != (1, 0) for n, w, _ in fields):
        raise ValueError("邮件操作需要有效的邮件编号")
    ids = [v for _, _, v in fields]

    # 一键处理（全部领取 / 全部删除）
    if ids == [(1 << 64) - 1]:
        if opcode == 3102:
            # 全部删除：删除已领取或无附件的邮件
            ids = [mid for mid, m in mails.items() if m["status"] == 2 or not m["attachments"]]
        else:
            # 全部领取：领取所有未领取且有附件的邮件
            ids = [mid for mid, m in mails.items() if m["status"] == 0 and m["attachments"]]

    if not ids or len(ids) != len(set(ids)) or any(mid not in mails for mid in ids):
        raise ValueError("没有可处理的邮件")

    if opcode == 3102:
        for mid in ids:
            m = mails[mid]
            if m["status"] != 2 and m["attachments"]:
                raise ValueError("请先领取附件，不能删除未领取奖励")
            if m.get("is_examination"):
                save["examination_state"] = exam_claims
                exam_claims["deleted"].append(mid)
            elif m.get("is_world_boss"):
                save["world_boss_state"] = world_claims
                world_claims["deleted"].append(mid)
            elif m["is_rank"]:
                rank_claims["deleted"].append(mid)
            else:
                gm_claims["deleted"].append(mid)
        return b"\x08\x01", b""

    # opcode 3101: 领取
    for mid in ids:
        if mails[mid]["status"] == 2:
            raise ValueError("邮件奖励已领取")

    all_gets = []
    day = (now + 8 * 3600) // 86400

    for mid in ids:
        m = mails[mid]
        if m.get("is_examination"):
            save["examination_state"] = exam_claims
            exam_claims["claimed"].append(mid)
        elif m.get("is_world_boss"):
            save["world_boss_state"] = world_claims
            world_claims["claimed"].append(mid)
        elif m["is_rank"]:
            rank_claims["claimed"].append(mid)
        else:
            gm_claims["claimed"].append(mid)
            # 月卡/终身卡权益处理
            card = m.get("card", 0)
            if card in (1, 2):
                rstate = recharge.get_state(save)
                if card == 1:
                    rstate["month_until"] = max(day, rstate["month_until"]) + 30
                    rstate["card_rmb"] += 25
                elif card == 2:
                    rstate["forever"] = True
                    rstate["card_rmb"] += 98

        for item in m["gets"]:
            if item[0] == 20081:
                pack_count = item[1]
                for cid in range(201901, 201925):
                    all_gets.append((cid, pack_count))
                for cid in range(192596, 192600):
                    all_gets.append((cid, 1160 * pack_count))
            else:
                all_gets.append(item)

    reward = recruit.build_reward(save, all_gets, config) if all_gets else b""
    return reward, reward
