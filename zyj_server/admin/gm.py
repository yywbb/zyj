"""本机 GM 发放与操作流水；与登录共用离线锁，先记录意图再修改存档。"""

import copy
import json
import re
import time
import uuid

from .. import player, recruit, storage
from ..session import Session
from . import views

RESOURCES = {"gold": "元宝", "coin": "银币", "stamina": "体力", "energy": "精力"}
ACTIONS = {"grant": "GM 调整与发放", "register": "创建登录账号", "backup": "创建备份",
           "restore": "恢复备份", "reset": "重置账号", "reset-guide": "重置引导", "config": "修改配置"}


def catalog(config):
    groups = {10000017, 10000018}
    for row in config["recruit_basic"].values():
        groups.update(row[key] for key in ("freecardgroupid", "freefirstcardgroupid", "normalfirstcardgroupid", "firsttentavern"))
    generals = {int(entry.split(",")[0]) for group in groups if group
                for entry in config["recruit_deck"][str(group)]["resourceid"].split(";") if entry}
    fragments = {row["general"] for row in config["general_fragment"].values()}
    rows = []
    for table, kind in (("props", "道具"), ("general_fragment", "武将碎片"), ("equip", "普通装备"), ("general", "武将")):
        for key, row in config[table].items():
            cid = int(key)
            if table == "general" and (cid not in generals or cid not in fragments or row["init_cid"] != cid):
                continue
            if table == "equip" and row["type"] not in ("weapon", "armor", "head", "accessory"):
                continue
            if table == "general_fragment" and str(row["general"]) not in config["general"]:
                continue
            name = config["general"][str(row["general"])]["name"] + "碎片" if table == "general_fragment" else row["name"]
            rows.append({"cid": cid, "name": name, "kind": kind, "description": row.get("desc", ""),
                         "max": 100 if table in ("equip", "general") else 1000000})
    return sorted(rows, key=lambda row: row["cid"])


def validate(data, items):
    if set(data) != {"operation_id", "revision", "reason", "resources", "items"}:
        raise ValueError("GM 操作需要操作编号、存档版本、原因、资源和物品")
    for key, length in (("operation_id", 32), ("revision", 64)):
        if not isinstance(data[key], str) or not re.fullmatch(f"[a-f0-9]{{{length}}}", data[key]):
            raise ValueError("操作编号或存档版本无效")
    if not isinstance(data["reason"], str) or not data["reason"].strip() or len(data["reason"]) > 200:
        raise ValueError("请填写 1–200 字的操作原因")
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
        if items[row["cid"]]["kind"] in ("普通装备", "武将"):
            instances += row["count"]
    if instances > 100:
        raise ValueError("一次最多发放 100 件装备或武将")
    if not resources and not rewards:
        raise ValueError("请至少填写一项资源变更或物品")


def changes(before, after):
    result = []
    for key, label in RESOURCES.items():
        if before[key] != after[key]:
            result.append({"name": label, "before": before[key], "after": after[key]})
    for field, identity in (("inventory", "cid"), ("generals", "iid"), ("equipment", "iid")):
        old = {(row.get("kind"), row[identity]): row for row in before[field]}
        for row in after[field]:
            previous = old.get((row.get("kind"), row[identity]))
            start, end = (previous["count"] if previous else 0, row["count"]) if field == "inventory" else (int(previous is not None), 1)
            if start != end:
                result.append({"name": row["name"], "cid": row["cid"], "iid": row.get("iid"), "before": start, "after": end})
    return result


class Workbench:
    def __init__(self, accounts):
        self.accounts = accounts
        self.directory = accounts.save_path.parent / "gm_operations"
        self.items = {row["cid"]: row for row in catalog(accounts.role_config)}

    def _write(self, row):
        storage.atomic_write(self.directory / (row["id"] + ".json"),
                             json.dumps(row, ensure_ascii=False, allow_nan=False).encode("utf-8"))

    def _read(self, path):
        row = json.loads(path.read_bytes())
        if row["status"] == "pending" and row["action"] == "grant":
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
        # shortcut: 本机流水按文件扫描；记录量明显增加时改用索引存储。
        with self.accounts.lock:
            rows = [self._read(path) for path in self.directory.glob("*.json")
                    if re.fullmatch(r"[a-f0-9]{32}\.json", path.name)]
        rows = [row for row in rows if (account is None or row["account"] == account)
                and (not action or row["action"] == action) and row["at"] >= since and (not until or row["at"] < until)]
        rows.sort(key=lambda row: (row["at"], row["id"]), reverse=True)
        # 请求正文只用于重试比对，页面使用明确的变更明细。
        return {"rows": [{k: v for k, v in row.items() if k != "request"} for row in rows[offset:offset + 50]],
                "total": len(rows), "offset": offset}

    def apply(self, account, data):
        validate(data, self.items)
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
            row = {"id": data["operation_id"], "at": time.time(), "account": account, "action": "grant",
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
                player.settle_stamina(save, store.role_config, now)
                state = player.get_role_state(save, store.role_config)
                for key, delta in data["resources"].items():
                    value = state[key] + delta
                    if not 0 <= value < (1 << 31):
                        raise ValueError(f"{RESOURCES[key]}不足或超出 int32 范围")
                    # GM 修正不属于游戏消费，不增加消费活动进度。
                    state[key] = value
                if any(self.items[item["cid"]]["kind"] == "武将" for item in data["items"]):
                    recruit.require_role(save)
                reward = recruit.build_reward(save, [(item["cid"], item["count"]) for item in data["items"]], store.role_config)
                player.apply_reward(save, reward, store.role_config, now)
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
                row["audit_warning"] = "发放已保存，操作记录待补写；可按操作编号查询结果。"
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
