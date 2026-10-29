"""账号绑定与离线维护；登录占用和后台写操作共用一把锁。"""

import copy
import hashlib
import json
from pathlib import Path
import re
import threading
import time

from . import player, protocol, storage
from .session import Session


def parse_account_id(text):
    if not isinstance(text, str) or not re.fullmatch(r"[1-9][0-9]{0,3}", text) or int(text) > 1000:
        raise ValueError("账号编号必须为 1~1000 的整数")
    return int(text)


def parse_login_account(body):
    params = []
    for field, wire, value in protocol.iter_pb_fields(body):
        if field == 1:
            if wire != 2:
                raise ValueError("登录参数必须是嵌套消息")
            params.append(list(protocol.iter_pb_fields(value)))
    if not params:
        raise ValueError("登录缺少账号标识")
    identities = [(wire, value) for field, wire, value in params[0] if field == 2]
    if len(identities) != 1 or identities[0][0] != 2:
        raise ValueError("登录缺少唯一账号标识")
    identity = identities[0][1].decode("ascii")
    prefix = "local_account_"
    if not identity.startswith(prefix):
        raise ValueError("不是本地账号标识，请安装局域网版客户端")
    return parse_account_id(identity[len(prefix):])


class AccountStore:
    def __init__(self, save_path, tables, step_counts, role_config):
        self.save_path = Path(save_path)
        self.tables = tables
        self.step_counts = step_counts
        self.role_config = role_config
        self.active = {}
        self.lock = threading.RLock()

    def path(self, account):
        if type(account) is not int or not 1 <= account <= 1000:
            raise ValueError("账号编号必须为 1~1000 的整数")
        return self.save_path if account == 1 else self.save_path.parent / "accounts" / str(account) / "role_save.json"

    def open_session(self, account, address):
        path = self.path(account)
        with self.lock:
            if account in self.active:
                raise ValueError(f"账号 {account} 已在线，请先退出原设备")
            self.active[account] = {"address": str(address[0]), "connected_at": time.time()}
        try:
            return Session(self.tables, path, self.step_counts, self.role_config)
        except Exception as error:
            self.close_session(account)
            raise ValueError(f"载入玩家状态失败: {error}") from error

    def close_session(self, account):
        with self.lock:
            self.active.pop(account, None)

    def account_ids(self):
        with self.lock:
            ids = {1, *self.active}
            for path in (self.save_path.parent / "accounts").glob("*/role_save.json"):
                try:
                    ids.add(parse_account_id(path.parent.name))
                except ValueError:
                    continue
            for directory in (self.save_path.parent / "backups" / "accounts").glob("*"):
                try:
                    ids.add(parse_account_id(directory.name))
                except ValueError:
                    continue
            return sorted(ids)

    def snapshot(self, account):
        with self.lock:
            path = self.path(account)
            raw = path.read_bytes() if path.exists() else b""
            result = {"id": account, "online": account in self.active,
                      "connection": dict(self.active.get(account, {})), "has_save": path.exists(),
                      "revision": hashlib.sha256(raw).hexdigest(), "error": None, "save": {}}
            if path.exists():
                try:
                    result["save"] = json.loads(raw)
                    if not isinstance(result["save"], dict):
                        raise ValueError("存档必须为对象")
                except (ValueError, UnicodeError):
                    result.update(save={}, error="存档 JSON 损坏，请备份后恢复有效版本。")
            return result

    def backups(self, account):
        self.path(account)
        directory = self.save_path.parent / "backups" / "accounts" / str(account)
        return sorted([{"id": p.stem, "created_at": p.stat().st_mtime}
                       for p in directory.glob("*.json") if re.fullmatch(r"[a-f0-9]{32}", p.stem)],
                      key=lambda row: row["created_at"], reverse=True)

    def maintain(self, account, action, revision, backup_id=None):
        if action not in ("backup", "restore", "reset", "reset-guide"):
            raise ValueError("未知账号操作")
        with self.lock:
            path = self.path(account)
            if account in self.active:
                raise ValueError("账号仍在线，请先退出游戏再维护。")
            if self.snapshot(account)["revision"] != revision:
                raise ValueError("存档已变化，请刷新账号后重试。")
            directory = self.save_path.parent / "backups" / "accounts" / str(account)
            restored = None
            if action == "restore":
                if not isinstance(backup_id, str) or not re.fullmatch(r"[a-f0-9]{32}", backup_id):
                    raise ValueError("备份编号无效")
                source = directory / (backup_id + ".json")
                if not source.is_file():
                    raise ValueError("备份不存在")
                restored = Session(self.tables, source, self.step_counts, self.role_config).save
                player.get_role_state(copy.deepcopy(restored), self.role_config)
            elif not path.exists():
                raise ValueError("该账号尚无存档")
            if action == "reset-guide":
                restored = player.load_save(path, self.step_counts)
                restored["guide"] = {"sections": {}}
            # 备份落盘失败时不能开始破坏性操作。
            previous = storage.backup(directory, path.read_bytes()) if path.exists() else None
            if action == "reset":
                path.unlink()
            elif restored is not None and not player.save_role(restored, path, self.step_counts):
                raise OSError("保存失败，原存档已保留")
            return {"backup_id": previous, "account": account, "action": action}
