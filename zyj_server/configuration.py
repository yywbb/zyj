"""服务端、后台和 APK 共用的配置源；维护项作为少量覆盖保存，重启后生效。"""

import copy
import hashlib
import json
from pathlib import Path
import re
import threading
import zipfile

from . import storage

EDITABLE = {
    "props": {"label": "恢复道具", "ids": ("20014", "20019", "20015", "20020"),
              "fields": {"param1": {"label": "恢复量", "type": "number-text", "max": 100000},
                         "desc": {"label": "道具说明", "type": "text"}}},
    "begin7day_task": {"label": "首日奖励", "ids": ("80001", "80030"),
                      "fields": {"rewards": {"label": "奖励（物品ID,数量;）", "type": "reward"},
                                 "name": {"label": "名称", "type": "text"}}},
    "liveness": {"label": "强化任务", "ids": ("16",),
                 "fields": {"num": {"label": "强化次数门槛", "type": "int", "max": 10000},
                            "reward": {"label": "奖励（物品ID,数量;）", "type": "reward"},
                            "desc": {"label": "任务说明", "type": "text"},
                            "description": {"label": "奖励说明", "type": "text"}}},
}


def overrides_path(config_path):
    return Path(config_path).with_name("config_overrides.json")


def revision(overrides):
    return hashlib.sha256(json.dumps(overrides, sort_keys=True, ensure_ascii=False).encode()).hexdigest()


def validate_overrides(overrides, archive):
    if not isinstance(overrides, dict) or not set(overrides) <= EDITABLE.keys():
        raise ValueError("覆盖配置包含尚未开放编辑的表")
    references = None
    for name, rows in overrides.items():
        spec = EDITABLE[name]
        if not isinstance(rows, dict) or not set(rows) <= set(spec["ids"]):
            raise ValueError(f"{name} 包含尚未开放编辑的条目")
        for row_id, fields in rows.items():
            if not isinstance(fields, dict) or not set(fields) <= spec["fields"].keys():
                raise ValueError(f"{name}/{row_id} 包含不可编辑字段")
            for field, value in fields.items():
                rule = spec["fields"][field]
                kind = rule["type"]
                if kind in ("int", "number-text"):
                    valid = type(value) is int if kind == "int" else isinstance(value, str) and bool(re.fullmatch(r"[1-9][0-9]{0,5}", value))
                    if not valid or not 1 <= int(value) <= rule["max"]:
                        raise ValueError(f"{rule['label']} 必须为 1~{rule['max']} 的整数")
                elif not isinstance(value, str) or not value.strip() or len(value) > (2048 if kind == "reward" else 500):
                    raise ValueError(f"{rule['label']} 格式或长度无效")
                elif kind == "reward":
                    if references is None:
                        references = {n: json.loads(archive.read(f"5/{n}.json"))
                                      for n in ("props", "equip", "general_fragment")}
                    entries = value.rstrip(";").split(";")
                    if len(entries) > 32:
                        raise ValueError("每项奖励最多 32 种物品")
                    seen, equipment = set(), 0
                    for entry in entries:
                        if not re.fullmatch(r"[1-9][0-9]{0,9},[1-9][0-9]{0,6}", entry):
                            raise ValueError("奖励格式应为 物品ID,数量;，数量必须为正整数")
                        cid, count = entry.split(",")
                        if cid in seen or int(count) > 1000000:
                            raise ValueError("奖励物品不能重复，每项数量最多 1000000")
                        seen.add(cid)
                        if cid in references["equip"]:
                            equipment += int(count)
                        elif cid not in ("1000", "1001") and not any(cid in references[n] for n in ("props", "general_fragment")):
                            raise ValueError(f"不支持的奖励物品 {cid}")
                    if equipment > 100:
                        raise ValueError("单次奖励装备总数最多 100 件")


def load_overrides(config_path, archive):
    path = overrides_path(config_path)
    data = json.loads(path.read_text(encoding="utf-8")) if path.exists() else {}
    validate_overrides(data, archive)
    return data


def apply_overrides(name, data, overrides):
    if name == "continue7_X1":
        for row in data.values():
            row["reward"] = ";".join(e for e in row["reward"].split(";") if e and e.split(",")[0] != "1026") + ";"
    if name == "activity_time":
        data["132"]["icon"] = "activity_continuous"
        for key in ("11", "104", "105", "106", "114", "115", "123", "124", "125", "126", "127", "128", "129"):
            data[key].update(open_type=1, begin="", end="", days_later=0, days_later2=0)
    if name == "build":
        for key in ("113", "370", "371", "372", "387", "388", "405", "406", "407", "408", "409", "410", "411"):
            data[key]["level"] = 1
    if name == "treasure2_fragment":
        for row in data.values():
            row["default"] = 1
    if name == "exchange_shop":
        # 本地常驻入口复用treasure_discount_x2/8原配方，不改招募概率。
        data["5"] = {"1": dict(data["1"]["1"], type=5, name="伙伴兑换", generals="11511,5;", target="11598,1;")}
    for row, changes in overrides.get(name, {}).items():
        if row not in data:
            raise ValueError(f"配置条目不存在: {name}/{row}")
        data[row].update(changes)
    return data


def load_tables(config_path, names):
    with zipfile.ZipFile(config_path) as archive:
        overrides = load_overrides(config_path, archive)
        return {name: apply_overrides(name, json.loads(archive.read(f"5/{name}.json")), overrides) for name in names}


def iter_config_bytes(config_path):
    with zipfile.ZipFile(config_path) as archive:
        overrides = load_overrides(config_path, archive)
        for entry in archive.namelist():
            if not entry.startswith("5/") or not entry.endswith(".json"):
                continue
            name = Path(entry).stem
            if name.startswith("._"):
                continue
            raw = archive.read(entry)
            if name in overrides or name in ("continue7_X1", "activity_time", "build", "treasure2_fragment", "exchange_shop"):
                raw = json.dumps(apply_overrides(name, json.loads(raw), overrides), ensure_ascii=False).encode("utf-8")
            yield name + ".json", raw


class ConfigStore:
    def __init__(self, config_path):
        self.path = Path(config_path)
        self.lock = threading.Lock()
        with zipfile.ZipFile(self.path) as archive:
            self.names = sorted(Path(p).stem for p in archive.namelist()
                                if p.startswith("5/") and p.endswith(".json") and not Path(p).name.startswith("._"))
            self.active_revision = revision(load_overrides(self.path, archive))

    def status(self):
        with zipfile.ZipFile(self.path) as archive:
            saved = revision(load_overrides(self.path, archive))
        return {"revision": saved, "active_revision": self.active_revision,
                "restart_required": saved != self.active_revision, "tables": self.names, "editable": EDITABLE}

    def table(self, name, query="", offset=0):
        if name not in self.names or len(query) > 100 or offset < 0:
            raise ValueError("配置表或查询参数无效")
        with self.lock, zipfile.ZipFile(self.path) as archive:
            overrides = load_overrides(self.path, archive)
            original = json.loads(archive.read(f"5/{name}.json"))
            data = apply_overrides(name, copy.deepcopy(original), overrides)
        entries = data.items() if isinstance(data, dict) else enumerate(data)
        rows = [{"id": str(key), "value": value, "original": original.get(key) if isinstance(original, dict) else original[key], "changed": str(key) in overrides.get(name, {})}
                for key, value in entries
                if not query or query.casefold() in (str(key) + json.dumps(value, ensure_ascii=False)).casefold()]
        if query:
            rows.sort(key=lambda row: row["id"] != query)
        return {"name": name, "rows": rows[offset:offset + 50], "total": len(rows),
                "offset": offset, "revision": revision(overrides), "editor": EDITABLE.get(name)}

    def update(self, name, row_id, changes, expected_revision):
        if name not in EDITABLE or row_id not in EDITABLE[name]["ids"]:
            raise ValueError("该条目仅供浏览")
        if changes is not None and (not isinstance(changes, dict) or not changes):
            raise ValueError("请提供要修改的字段")
        with self.lock, zipfile.ZipFile(self.path) as archive:
            before = load_overrides(self.path, archive)
            if revision(before) != expected_revision:
                raise ValueError("配置已被修改，请刷新后重试。")
            updated = copy.deepcopy(before)
            if changes is None:
                updated.get(name, {}).pop(row_id, None)
                if not updated.get(name):
                    updated.pop(name, None)
            else:
                updated.setdefault(name, {}).setdefault(row_id, {}).update(changes)
            validate_overrides(updated, archive)
            base = json.loads(archive.read(f"5/{name}.json"))
            previous = apply_overrides(name, copy.deepcopy(base), before)[row_id]
            apply_overrides(name, base, updated)
            backup_id = None
            if before != updated:
                backup_id = storage.backup(self.path.parent / "backups" / "configs", json.dumps(before, ensure_ascii=False).encode())
                storage.atomic_write(overrides_path(self.path), json.dumps(updated, ensure_ascii=False, indent=2).encode())
            return {"revision": revision(updated), "restart_required": revision(updated) != self.active_revision,
                    "backup_id": backup_id, "changes": [{"name": field, "before": previous.get(field), "after": base[row_id].get(field)}
                        for field in EDITABLE[name]["fields"] if previous.get(field) != base[row_id].get(field)]}
