"""本机 GM 发放与操作流水；与登录共用离线锁，先记录意图再修改存档。"""

import copy
import json
import re
import time
import uuid

from .. import cheer, formation, player, qiankun, recruit, storage, training
from ..protocol import encode_pb_field, iter_pb_fields, parse_ids_pb, pb_get_varint
from ..session import Session
from . import views

RESOURCES = {"gold": "元宝", "coin": "银币", "stamina": "体力", "energy": "精力"}
ACTIONS = {"grant": "GM 调整与发放", "register": "创建登录账号", "backup": "创建备份",
           "restore": "恢复备份", "reset": "重置账号", "reset-guide": "重置引导", "config": "修改配置",
           "inventory": "修正物品数量", "general-level": "武将升级", "formation": "调整阵容", "remove-general": "移除闲置武将",
           "mail": "GM 发送邮件", "mail-delete": "GM 撤回邮件", "kick": "强制下线",
           "transfer": "转移账号数据到测试号"}
TEST_ACCOUNT = 10
PLAYER_ACTIONS = {"grant": {"resources", "items"}, "inventory": {"cid", "count"},
                  "general-level": {"iid", "level"}, "formation": {"iid", "position"}, "remove-general": {"iid"}}
COMMON_ITEMS = (20081, 20014, 20019, 20015, 20020, 20100, 20619, 20618, *training.EXP_PROPS)


def catalog(config):
    id_dict = config.get("ID_dictionary", {})
    def get_dict_name(cid, fallback=""):
        s = str(cid)
        if s in id_dict and "0" in id_dict[s] and id_dict[s]["0"].get("name"):
            return id_dict[s]["0"]["name"]
        return fallback

    rows = []
    seen = set()

    # 0. 仙元：作为资源存放在角色数据里，不在 props 表中，这里补进物品库，邮件/发放与普通道具一样添加。
    seen.add(1025)
    rows.append({"cid": 1025, "name": "仙元", "kind": "道具", "description": "仙界货币，用于仙界相关功能", "max": 1000000})

    # 1. 道具 (props)
    if "props" in config:
        for key, row in config["props"].items():
            cid = int(key)
            seen.add(cid)
            rows.append({"cid": cid, "name": row.get("name", ""), "kind": "道具", "description": row.get("desc", ""),
                         "max": 1000000})

    # 2. 战宠碎片 (pet3_fragment) - 包含 91008 鲲碎片 等
    if "pet3_fragment" in config:
        for key, row in config["pet3_fragment"].items():
            debris = int(row.get("debris", key))
            petid = str(row.get("petid", ""))
            pet_name = config.get("pet3_attr", {}).get(petid, {}).get("0", {}).get("name") or get_dict_name(petid, "战宠")
            name = get_dict_name(debris, f"{pet_name}碎片")
            seen.add(debris)
            rows.append({"cid": debris, "name": name, "kind": "战宠碎片",
                         "description": row.get("desc", "") or f"合成战宠【{pet_name}】所需碎片", "max": 1000000})

    # 3. 战宠 (pet3_attr) - 包含 90008 鲲 等
    if "pet3_attr" in config:
        for key, row in config["pet3_attr"].items():
            cid = int(key)
            name = row.get("0", {}).get("name") or get_dict_name(cid, "战宠")
            ptype = row.get("0", {}).get("type", "")
            q = row.get("0", {}).get("quality", "")
            seen.add(cid)
            rows.append({"cid": cid, "name": name, "kind": "战宠",
                         "description": f"战宠 / {ptype} / 品质{q}", "max": 100})

    # 4. 专属装备 (exclusive) - 包含 201532 紫霄神鲲 等
    if "exclusive" in config:
        for key, row in config["exclusive"].items():
            cid = int(key)
            seen.add(cid)
            rows.append({"cid": cid, "name": row.get("name", ""), "kind": "专属装备",
                         "description": row.get("describe", "") or row.get("desc", ""), "max": 100})

    # 5. 武将碎片 (general_fragment)
    if "general_fragment" in config:
        for key, row in config["general_fragment"].items():
            cid = int(key)
            gid = str(row.get("general", ""))
            if gid in config.get("general", {}):
                gname = config["general"][gid].get("name") or get_dict_name(gid, "武将")
                seen.add(cid)
                rows.append({"cid": cid, "name": f"{gname}碎片", "kind": "武将碎片",
                             "description": f"合成武将【{gname}】所需碎片", "max": 1000000})

    # 6. 武将 (general)
    if "general" in config:
        for key, row in config["general"].items():
            cid = int(key)
            if row.get("battle") == 1 and row.get("name") and row.get("quality", 0) >= 2 and row.get("init_cid") == cid:
                if cid not in seen:
                    seen.add(cid)
                    desc = f"武将 / 品质{row.get('quality')} / 资质{row.get('aptitude', '')}"
                    rows.append({"cid": cid, "name": row.get("name", ""), "kind": "武将",
                                 "description": desc, "max": 100})

    # 7. 宝物碎片 / 坐骑碎片 (treasure2_fragment)
    if "treasure2_fragment" in config:
        for key, row in config["treasure2_fragment"].items():
            cid = int(key)
            if cid not in seen:
                seen.add(cid)
                rows.append({"cid": cid, "name": row.get("name", ""), "kind": "宝物碎片",
                             "description": "宝物/坐骑合成碎片", "max": 1000000})

    # 8. 装备碎片 (equip_fragment)
    if "equip_fragment" in config:
        for key, row in config["equip_fragment"].items():
            cid = int(key)
            if cid not in seen:
                seen.add(cid)
                name = row.get("name", "")
                rows.append({"cid": cid, "name": name if name.endswith("碎片") else f"{name}碎片", "kind": "装备碎片",
                             "description": "装备合成碎片", "max": 1000000})

    # 9. 普通装备 / 坐骑 / 宝物 (equip)
    if "equip" in config:
        equip_types = {
            "weapon": "武器", "armor": "衣服", "head": "头盔", "accessory": "配饰",
            "horse": "坐骑", "treasure": "宝物"
        }
        for key, row in config["equip"].items():
            cid = int(key)
            etype = row.get("type")
            if etype in equip_types and row.get("adorn", 1) == 1:
                if cid not in seen:
                    seen.add(cid)
                    desc = row.get("desc", "")
                    q = row.get("quality")
                    type_label = equip_types[etype]
                    if q:
                        desc = f"{type_label} / 品质{q} · {desc}" if desc else f"{type_label} / 品质{q}"
                    rows.append({"cid": cid, "name": row.get("name", ""), "kind": "普通装备",
                                 "description": desc, "max": 100})

    # 10. 觉醒道具 (redl_awake_item)
    if "redl_awake_item" in config:
        for key, row in config["redl_awake_item"].items():
            cid = int(key)
            if cid not in seen:
                seen.add(cid)
                name = row.get("name", "")
                rows.append({"cid": cid, "name": name if name.endswith("丹") else f"{name}突破觉醒丹", "kind": "道具",
                             "description": row.get("desc", ""), "max": 1000000})

    # 11. 令牌 (token) & 令牌碎片 (token_fragment)
    if "token" in config:
        for key, row in config["token"].items():
            cid = int(key)
            if cid not in seen:
                seen.add(cid)
                rows.append({"cid": cid, "name": row.get("desc", "") or f"令牌{cid}", "kind": "道具",
                             "description": row.get("desc", ""), "max": 1000000})
    if "token_fragment" in config:
        for key, row in config["token_fragment"].items():
            cid = int(key)
            if cid not in seen:
                seen.add(cid)
                rows.append({"cid": cid, "name": row.get("name", "") or f"令牌碎片{cid}", "kind": "道具",
                             "description": row.get("desc", ""), "max": 1000000})

    # 12. 法宝宝石 (trump_gem)
    if "trump_gem" in config:
        for key, row in config["trump_gem"].items():
            cid = int(key)
            if cid not in seen:
                seen.add(cid)
                rows.append({"cid": cid, "name": row.get("desc", "") or f"宝石{cid}", "kind": "道具",
                             "description": row.get("desc", ""), "max": 1000000})

    # 13. 战魂 (soul) & 魔符 (sigil)
    if "soul" in config:
        for key, row in config["soul"].items():
            cid = int(key)
            if cid not in seen:
                name = get_dict_name(cid, f"战魂{cid}")
                seen.add(cid)
                rows.append({"cid": cid, "name": name, "kind": "战魂",
                             "description": "命格战魂", "max": 100})
    if "sigil" in config:
        for key, row in config["sigil"].items():
            cid = int(key)
            if cid not in seen:
                name = get_dict_name(cid, f"魔符{cid}")
                seen.add(cid)
                rows.append({"cid": cid, "name": name, "kind": "魔符",
                             "description": row.get("desc", ""), "max": 100})

    return sorted(rows, key=lambda row: row["cid"])


def validate(data, items):
    if not isinstance(data, dict):
        raise ValueError("GM 操作必须为对象")
    action = data.get("action", "grant")
    if not isinstance(action, str) or action not in PLAYER_ACTIONS:
        raise ValueError("不支持的 GM 操作")
    expected = {"operation_id", "revision", "reason"} | PLAYER_ACTIONS[action]
    if "action" in data:
        expected.add("action")
    if set(data) != expected:
        raise ValueError("GM 操作字段不完整或包含多余参数")
    for key, length in (("operation_id", 32), ("revision", 64)):
        if not isinstance(data[key], str) or not re.fullmatch(f"[a-f0-9]{{{length}}}", data[key]):
            raise ValueError("操作编号或存档版本无效")
    if not isinstance(data["reason"], str) or not data["reason"].strip() or len(data["reason"]) > 200:
        raise ValueError("请填写 1–200 字的操作原因")
    if action != "grant":
        if any(type(data[key]) is not int or not (0 if key in ("count", "position") else 1) <= data[key] < (1 << 31)
               for key in PLAYER_ACTIONS[action]):
            raise ValueError("物品、武将或数量参数无效")
        if action == "inventory" and data["cid"] == 1025:
            raise ValueError("仙元是角色资源，请通过发放物品或邮件调整")
        if action == "inventory" and items.get(data["cid"], {}).get("kind") not in ("道具", "武将碎片", "战宠碎片", "宝物碎片", "装备碎片"):
            raise ValueError("只能修正目录中的道具或碎片数量")
        if action == "formation" and data["position"] > 7:
            raise ValueError("阵位必须为 0（下阵）或 1–7")
        return action
    resources = data["resources"]
    if (not isinstance(resources, dict) or not set(resources) <= RESOURCES.keys()
            or any(type(v) is not int or not 0 < abs(v) < (1 << 31) for v in resources.values())):
        raise ValueError("资源变更必须是非零整数，且在 int32 范围内")
    rewards = data["items"]
    if not isinstance(rewards, list) or len(rewards) > 32:
        raise ValueError("一次最多发放 32 种物品")
    seen, instances = set(), 0
    for row in rewards:
        if (not isinstance(row, dict) or set(row) != {"cid", "count"} or type(row["cid"]) is not int
                or row["cid"] not in items or type(row["count"]) is not int
                or not 1 <= row["count"] <= items[row["cid"]]["max"] or row["cid"] in seen):
            raise ValueError("物品不存在、数量超限或包含重复条目")
        seen.add(row["cid"])
        if items[row["cid"]]["kind"] in ("普通装备", "武将", "战宠", "专属装备", "战魂", "魔符"):
            instances += row["count"]
    if instances > 100:
        raise ValueError("一次最多发放 100 件装备、武将或特殊实体")
    if not resources and not rewards:
        raise ValueError("请至少填写一项资源变更或物品")
    return action


def _manage(save, action, data, config, step_counts, now):
    if action == "inventory":
        fragment = config["general_fragment"].get(str(data["cid"]))
        query, cid = ("1012", fragment["general"]) if fragment else ("1200", data["cid"])
        count = next((pb_get_varint(v, 2) or 0 for n, w, v in iter_pb_fields(bytes.fromhex(save["world_state"][query]))
                      if n == 1 and w == 2 and pb_get_varint(v, 1) == cid), 0)
        if count == data["count"]:
            raise ValueError("物品数量未变化")
        player.change_item_count(save, data["cid"], data["count"] - count, config, now)
        return
    if save.get("guide", {}).get("sections", {}).get("1", {}).get("status") != 2:
        raise ValueError("请先完成新手引导后管理武将")
    world = bytes.fromhex(save["world_state"]["1002"])
    generals, slots, equips = formation.records(world, 1, 2), formation.records(world, 4, 2), formation.records(world, 2, 1)
    iid = data["iid"]
    if iid not in generals:
        raise ValueError("武将不存在")
    raw = generals[iid]
    row = config["general"][str(pb_get_varint(raw, 1))]
    if (not row["battle"]
            or any(any(parse_ids_pb(v)) for n, w, v in iter_pb_fields(raw) if n == 41 and w == 2)
            or iid in formation.records(world, 5, 2)):
        raise ValueError("暂不支持高级或助阵武将管理")
    if any(pb_get_varint(raw, n) for n in range(21, 41)):
        from .. import partner_growth
        partner_growth.validate(raw, config)
    if action == "formation":
        position = data["position"]
        current = pb_get_varint(slots.get(iid, b""), 1) or 0
        if position == current:
            raise ValueError("武将阵位未变化")
        body = encode_pb_field(1, 0, position or current) + encode_pb_field(3, 0, iid if position else 0)
        player.prepare_recorded_response(1003, b"", save, body, step_counts, config, now)
    elif action == "remove-general":
        from .. import general_foster

        protagonist = pb_get_varint(bytes.fromhex(save.get("protagonist_snapshot", "")), 1)
        if iid == protagonist or row["actor"] == "lead" or iid in qiankun.protected(save):
            raise ValueError("只能移除非主角的闲置武将，请先下阵")
        from .. import partner_growth
        partner_growth.remove(save, iid)
        save["world_state"]["1002"] = b"".join(encode_pb_field(n, w, v) for n, w, v in iter_pb_fields(world)
            if not (n == 1 and w == 2 and pb_get_varint(v, 2) == iid)).hex()
        general_foster.remove(save, iid)
    else:
        level = pb_get_varint(raw, 3) or 0
        maximum = min(save["role_state"]["level"] * int(config["global_kv"]["general_level"]["value"]),
                      max(map(int, config["general_exp"])))
        if not 1 <= level < data["level"] <= maximum:
            raise ValueError(f"目标等级须高于当前等级，且不超过 {maximum}")
        needed = sum(config["general_exp"][str(lv)][f'{row["quality"]}exp'] for lv in range(level, data["level"]))
        gained = max(0, needed - (pb_get_varint(raw, 5) or 0))
        members = cheer.members(save, config)
        raw, increase, _ = training.grow_general(raw, gained, slots.get(iid, b""), members, equips, config, data["level"], cheer_tiers=cheer.tiers(save, config), wing_state=save.get("wing_state"))
        player.apply_reward(save, encode_pb_field(8, 2, raw), config, now)
        if save.get("protagonist_snapshot"):
            player.record_slot_update(save, encode_pb_field(6, 2, bytes.fromhex(save["protagonist_snapshot"])))
        if iid in slots:
            for key in ("power", "power_all"):
                save["role_state"][key] += increase
                if not 0 <= save["role_state"][key] < (1 << 31):
                    raise ValueError("角色战力超出范围")


def changes(before, after):
    result = []
    for key, label in {**RESOURCES, "power": "阵容战力"}.items():
        if before[key] != after[key]:
            result.append({"name": label, "before": before[key], "after": after[key]})
    for field, identity in (("inventory", "cid"), ("generals", "iid"), ("equipment", "iid")):
        old = {(row.get("kind"), row[identity]): row for row in before[field]}
        new = {(row.get("kind"), row[identity]): row for row in after[field]}
        for key in dict.fromkeys([*old, *new]):
            previous, current = old.get(key), new.get(key)
            row = current or previous
            start, end = ((previous["count"] if previous else 0, current["count"] if current else 0)
                          if field == "inventory" else (int(previous is not None), int(current is not None)))
            if start != end:
                result.append({"name": row["name"], "cid": row["cid"], "iid": row.get("iid"), "before": start, "after": end})
            if field == "generals" and previous and current:
                for attr, label in (("level", "等级"), ("exp", "经验"), ("position", "阵位"), ("atk", "攻击"),
                                    ("defense", "防御"), ("hp", "生命"), ("speed", "速度"), ("potential", "潜力"), ("power", "战力")):
                    if previous[attr] != current[attr]:
                        result.append({"name": f'{row["name"]} · {label}', "iid": row["iid"],
                                       "before": previous[attr], "after": current[attr]})
    return result


class Workbench:
    def __init__(self, accounts):
        self.accounts = accounts
        self.directory = accounts.save_path.parent / "gm_operations"
        self.items = {row["cid"]: row for row in catalog(accounts.role_config)}

    def _write(self, row):
        storage.atomic_write(self.directory / (row["id"] + ".json"),
                             json.dumps(row, ensure_ascii=False, allow_nan=False).encode("utf-8"))
        try:
            from .. import db
            db_path = db.get_db_path(self.accounts.save_path)
            if db_path.exists():
                db.save_gm_operation(db_path, row)
        except Exception:
            pass

    def _read(self, path):
        row = json.loads(path.read_bytes())
        if row["status"] == "pending" and row["action"] in PLAYER_ACTIONS:
            saved = self.accounts.snapshot(row["account"])["save"]
            if saved.get("gm_receipt") == row["id"]:
                row["status"] = "success"
        return row

    def _finish_pending(self, account):
        # 新操作覆盖回执前，先把上次成功写入但日志未完成的结果落盘。
        for path in self.directory.glob("*.json"):
            if not re.fullmatch(r"[a-f0-9]{32}\.json", path.name):
                continue
            row = json.loads(path.read_bytes())
            if row["account"] == account and row["status"] == "pending":
                resolved = self._read(path)
                if resolved["status"] == "success":
                    self._write(resolved)

    def history(self, account=None, action="", since=0, until=0, offset=0):
        if (action and action not in ACTIONS) or offset < 0 or since < 0 or until < 0 or (until and since > until):
            raise ValueError("操作记录筛选参数无效")
        with self.accounts.lock:
            rows = [self._read(path) for path in self.directory.glob("*.json")
                    if re.fullmatch(r"[a-f0-9]{32}\.json", path.name)]
        if not rows:
            try:
                from .. import db
                db_path = db.get_db_path(self.accounts.save_path)
                if db_path.exists():
                    return db.list_gm_operations(db_path, account, action, since, until, offset, 50)
            except Exception:
                pass
        rows = [row for row in rows if (account is None or row["account"] == account)
                and (not action or row["action"] == action) and row["at"] >= since and (not until or row["at"] < until)]
        rows.sort(key=lambda row: (row["at"], row["id"]), reverse=True)
        # 请求正文只用于重试比对，页面使用明确的变更明细。
        return {"rows": [{k: v for k, v in row.items() if k != "request"} for row in rows[offset:offset + 50]],
                "total": len(rows), "offset": offset}

    def apply(self, account, data):
        action = validate(data, self.items)
        store = self.accounts
        with store.lock:
            store.path(account)
            path = self.directory / (data["operation_id"] + ".json")
            if path.exists():
                row = self._read(path)
                if row["account"] != account or row.get("request") != data:
                    raise ValueError("操作编号已用于另一项请求，请重新填写操作")
                return {k: v for k, v in row.items() if k != "request"}
            self._finish_pending(account)
            snapshot = store.snapshot(account)
            row = {"id": data["operation_id"], "at": time.time(), "account": account, "action": action,
                   "reason": data["reason"], "status": "pending", "request": copy.deepcopy(data),
                   "before_revision": snapshot["revision"], "after_revision": None, "backup_id": None, "changes": []}
            self._write(row)
            try:
                if snapshot["online"]:
                    raise ValueError("账号仍在线，请先退出游戏再执行 GM 操作")
                if snapshot["revision"] != data["revision"]:
                    raise ValueError("存档已变化，请刷新玩家档案后重新操作")
                if snapshot["error"] or not snapshot["save"].get("has_role"):
                    raise ValueError(snapshot["error"] or "角色尚未创建")
                save = Session(store.tables, store.path(account), store.step_counts, store.role_config).save
                before = copy.deepcopy(save)
                now = int(time.time())
                player.settle_self_stats(save, store.role_config)
                player.settle_stamina(save, store.role_config, now)
                state = player.get_role_state(save, store.role_config)
                for key, delta in data.get("resources", {}).items():
                    value = state[key] + delta
                    # 银币在协议里是 int64，其余资源是 int32。
                    if not 0 <= value < (1 << 63 if key == "coin" else 1 << 31):
                        raise ValueError(f"{RESOURCES[key]}不足或超出范围")
                    # GM 修正不属于游戏消费，不增加消费活动进度。
                    state[key] = value
                if action == "grant":
                    if any(self.items[item["cid"]]["kind"] == "武将" for item in data["items"]):
                        recruit.require_role(save)
                    expanded_items = []
                    for item in data["items"]:
                        if item["cid"] == 20081:
                            for cid in range(201901, 201925):
                                expanded_items.append((cid, item["count"]))
                            for cid in range(192596, 192600):
                                expanded_items.append((cid, 1160 * item["count"]))
                        else:
                            expanded_items.append((item["cid"], item["count"]))
                    reward = recruit.build_reward(save, expanded_items, store.role_config)
                    player.apply_reward(save, reward, store.role_config, now)
                else:
                    _manage(save, action, data, store.role_config, store.step_counts, now)
                player.settle_stamina(save, store.role_config, now)
                after = views.detail({**snapshot, "save": save}, store.step_counts, store.role_config)
                previous = views.detail(snapshot, store.step_counts, store.role_config)
                if previous["error"] or after["error"]:
                    raise ValueError(previous["error"] or after["error"])
                row["changes"] = changes(previous, after)
                row["backup_id"] = storage.backup(store.save_path.parent / "backups" / "accounts" / str(account), store.path(account).read_bytes())
                self._write(row)
                save["gm_receipt"] = row["id"]
                player.save_response_group([], save, before, store.path(account), store.step_counts, store.role_config, now)
            except (ValueError, TypeError, KeyError, OSError) as error:
                row.update(status="failed", error=str(error))
                self._write(row)
                raise
            row["status"] = "success"
            try:
                row["after_revision"] = store.snapshot(account)["revision"]
                self._write(row)
            except OSError:
                # 存档回执已随奖励落盘，重试/查询可确认成功，不能谎报发放失败。
                row["audit_warning"] = "变更已保存，操作记录待补写；可按操作编号查询结果。"
            return {k: v for k, v in row.items() if k != "request"}

    def logged(self, action, account, details, operation):
        """记录现有维护操作，只接收经过挑选的业务字段，不接收密码。"""
        with self.accounts.lock:
            if account is not None:
                self._finish_pending(account)
            row = {"id": uuid.uuid4().hex, "at": time.time(), "account": account, "action": action,
                   "reason": ACTIONS[action], "status": "pending", "details": details}
            if account is not None:
                row["before_revision"] = self.accounts.snapshot(account)["revision"]
            self._write(row)
            try:
                result = operation()
            except (ValueError, TypeError, KeyError, OSError) as error:
                row.update(status="failed", error=str(error))
                self._write(row)
                raise
            row.update(status="success", result=result)
            try:
                if account is not None:
                    row["after_revision"] = self.accounts.snapshot(account)["revision"]
                self._write(row)
            except OSError:
                result = {**result, "audit_warning": "操作已完成，但流水未完成落盘，请核对当前状态。"}
            return result

    def kick(self, account, reason="GM 强制下线"):
        if not isinstance(reason, str) or not reason.strip() or len(reason) > 200:
            raise ValueError("请填写 1–200 字的操作原因")
        self.accounts.path(account)
        return self.logged("kick", account, {"reason": reason},
                           lambda: self.accounts.kick(account))

    def list_mails(self, account=None, offset=0, limit=50):
        from .. import mail
        return mail.list_mails(self.accounts.save_path.with_name("mails.json"), account, offset, limit)

    def send_mail(self, data):
        from .. import mail
        if not isinstance(data, dict):
            raise ValueError("邮件数据必须为对象")
        title = data.get("title", "")
        content = data.get("content", "")
        target = data.get("target", 0)
        if target in ("all", "0", 0):
            target = 0
        else:
            target = int(target)
            self.accounts.path(target)

        resources = data.get("resources", {})
        items = data.get("items", [])
        recharge_info = data.get("recharge", {})
        card = int(recharge_info.get("card", 0)) if isinstance(recharge_info, dict) else 0
        reason = (data.get("reason") or "GM 发送邮件").strip()

        attachments = {}
        for key, cid in (("gold", 1001), ("coin", 1000), ("stamina", 1002), ("energy", 1003)):
            if key in resources and int(resources[key]) > 0:
                attachments[str(cid)] = int(resources[key])

        for item in items:
            cid = int(item["cid"])
            count = int(item["count"])
            if count > 0:
                attachments[str(cid)] = attachments.get(str(cid), 0) + count

        mail_path = self.accounts.save_path.with_name("mails.json")
        details = {
            "target": target or "all",
            "title": title,
            "attachments": attachments,
            "recharge": recharge_info,
            "reason": reason
        }
        return self.logged("mail", target if target else None, details,
                           lambda: mail.send_mail(mail_path, target, title, content, attachments, recharge_info, card=card, sender="GM"))

    def delete_mail(self, mail_id, reason="GM 撤回邮件"):
        from .. import mail
        mail_path = self.accounts.save_path.with_name("mails.json")
        details = {"mail_id": mail_id, "reason": reason}
        return self.logged("mail-delete", None, details,
                           lambda: {"deleted": mail.delete_mail(mail_path, mail_id), "mail_id": mail_id})

    def transfer(self, account, reason="GM 转移账号数据"):
        """把源账号存档复制到测试账号(10)；先备份两端确保可回滚，源账号不变。"""
        if not isinstance(reason, str) or not reason.strip() or len(reason) > 200:
            raise ValueError("请填写 1–200 字的操作原因")
        store = self.accounts
        target = TEST_ACCOUNT
        with store.lock:
            store.path(account)
            store.path(target)
            if account == target:
                raise ValueError("不能把测试账号复制到自身")
            source_snapshot = store.snapshot(account)
            target_snapshot = store.snapshot(target)
            if source_snapshot["online"] or target_snapshot["online"]:
                raise ValueError("源账号或测试账号仍在线，请先退出游戏再转移")
            if source_snapshot["error"] or not source_snapshot["save"].get("has_role"):
                raise ValueError(source_snapshot["error"] or "源账号尚未创建角色")
            source_raw = store.path(account).read_bytes()
            copied = copy.deepcopy(source_snapshot["save"])
            for name in ("friend_state", "cup_state", "world_boss_state", "examination_state", "rank_mail_state", "mail_state"):
                copied.pop(name, None)
                # 共享收据不能跨账号；重复复制仍须保留测试号自己的领取记录。
                if target_snapshot["save"].get("created_at") == copied["created_at"] and name in target_snapshot["save"]:
                    copied[name] = copy.deepcopy(target_snapshot["save"][name])
            details = {"target": target, "reason": reason}

            def copy_save():
                details["source_backup_id"] = storage.backup(store.save_path.parent / "backups" / "accounts" / str(account), source_raw)
                details["target_backup_id"] = (storage.backup(store.save_path.parent / "backups" / "accounts" / str(target),
                    store.path(target).read_bytes()) if store.path(target).exists() else None)
                if not player.save_role(copied, store.path(target), store.step_counts):
                    raise OSError("保存失败，原测试号存档已保留")
                return {"account": account, "target": target, "source_backup_id": details["source_backup_id"],
                        "target_backup_id": details["target_backup_id"], "transferred_size": len(source_raw)}

            return self.logged("transfer", account, details, copy_save)
