"""账号绑定与离线维护；登录占用和后台写操作共用一把锁。"""

import copy
import hashlib
import json
from pathlib import Path
import re
import secrets
import threading
import time

from . import guild, online_rewards, player, protocol, ranking, storage, welfare
from .session import Session

PASSWORD_ITERATIONS = 600000


def validate_password(password):
    if not isinstance(password, str) or not re.fullmatch(r"[!-~]{8,64}", password):
        raise ValueError("密码须为 8~64 位英文字母、数字或符号（不含空格）")
    return password


def parse_account_id(text):
    if not isinstance(text, str) or not re.fullmatch(r"[1-9][0-9]{0,3}", text) or int(text) > 1000:
        raise ValueError("账号编号必须为 1~1000 的整数")
    return int(text)


def parse_login_credentials(body):
    try:
        if len(body) > 1024:
            raise ValueError
        fields = list(protocol.iter_pb_fields(body))
        if len(fields) not in (2, 3) or any((n, w) != (1, 2) for n, w, _ in fields):
            raise ValueError
        params = [list(protocol.iter_pb_fields(raw)) for _, _, raw in fields]
        if any(len(p) != 1 or p[0][:2] != (2, 2) for p in params[:2]):
            raise ValueError
        if len(params) == 3 and (len(params[2]) != 1 or params[2][0][:2] != (1, 0)):
            raise ValueError
        identity = params[0][0][2].decode("ascii")
        if not identity.startswith("local_account_"):
            raise ValueError
        account = parse_account_id(identity[len("local_account_"):])
        return account, validate_password(params[1][0][2].decode("ascii"))
    except (ValueError, UnicodeError):
        raise ValueError("登录参数无效，请使用账号密码版客户端") from None


class AccountStore:
    def __init__(self, save_path, tables, step_counts, role_config):
        self.save_path = Path(save_path)
        self.tables = tables
        self.step_counts = step_counts
        self.role_config = role_config
        self.active = {}
        self.lock = threading.RLock()
        # shortcut: 限流仅在本进程内保留；支持多进程部署时再共享计数。
        self.failed_logins = {}

    def path(self, account):
        if type(account) is not int or not 1 <= account <= 1000:
            raise ValueError("账号编号必须为 1~1000 的整数")
        return self.save_path if account == 1 else self.save_path.parent / "accounts" / str(account) / "role_save.json"

    def credential_path(self, account):
        self.path(account)
        return self.save_path.parent / "accounts" / str(account) / "credentials.json"

    def register(self, account, password, revision):
        password = validate_password(password)
        with self.lock:
            path = self.credential_path(account)
            if account in self.active:
                raise ValueError("账号仍在线，请先退出游戏再绑定密码。")
            if path.exists():
                raise ValueError("账号已设置密码，不能重复创建或覆盖。")
            if self.snapshot(account)["revision"] != revision:
                raise ValueError("存档已变化，请刷新账号后重试。")
            salt = secrets.token_bytes(16)
            digest = hashlib.pbkdf2_hmac("sha256", password.encode("ascii"), salt, PASSWORD_ITERATIONS)
            record = {"algorithm": "pbkdf2_sha256", "iterations": PASSWORD_ITERATIONS,
                      "salt": salt.hex(), "hash": digest.hex()}
            storage.atomic_write(path, json.dumps(record).encode("utf-8"))
            return {"account": account, "registered": True}

    def authenticate(self, account, password):
        password = validate_password(password)
        with self.lock:
            path = self.credential_path(account)
            now = time.monotonic()
            attempts = self.failed_logins.get(account, [])
            if len(attempts) >= 5 and now < attempts[-1] + 60:
                raise ValueError("登录尝试过于频繁，请一分钟后重试。")
            attempts = [at for at in attempts if now - at < 60]
            salt, expected = bytes(16), bytes(32)
            registered = path.exists()
            if registered:
                try:
                    record = json.loads(path.read_bytes())
                    if (not isinstance(record, dict) or record.get("algorithm") != "pbkdf2_sha256"
                            or type(record.get("iterations")) is not int or record["iterations"] != PASSWORD_ITERATIONS
                            or not isinstance(record.get("salt"), str) or not re.fullmatch(r"[a-f0-9]{32}", record["salt"])
                            or not isinstance(record.get("hash"), str) or not re.fullmatch(r"[a-f0-9]{64}", record["hash"])):
                        raise ValueError
                    salt, expected = bytes.fromhex(record["salt"]), bytes.fromhex(record["hash"])
                except (ValueError, UnicodeError):
                    raise ValueError("账号登录配置损坏，请联系管理员。") from None
            actual = hashlib.pbkdf2_hmac("sha256", password.encode("ascii"), salt, PASSWORD_ITERATIONS)
            if not secrets.compare_digest(actual, expected) or not registered:
                self.failed_logins[account] = attempts + [now]
                raise ValueError("账号未启用或密码错误")
            self.failed_logins.pop(account, None)

    def open_session(self, account, password, address):
        path = self.path(account)
        with self.lock:
            self.authenticate(account, password)
            if account in self.active:
                raise ValueError(f"账号 {account} 已在线，请先退出原设备")
            self.active[account] = {"address": str(address[0]), "connected_at": time.time()}
        try:
            return Session(self.tables, path, self.step_counts, self.role_config, self.growth_buyers,
                           lambda body, opcode=3500, save=None: self.rank_query(account, body, opcode, save),
                           lambda previous=None: self.observe_rankings({account: previous} if previous else None),
                           lambda session, opcode, seq, body: self.guild_request(account, session, opcode, seq, body))
        except Exception as error:
            self.close_session(account)
            raise ValueError(f"载入玩家状态失败: {error}") from error

    def close_session(self, account):
        with self.lock:
            self.active.pop(account, None)

    def guild_request(self, account, session, opcode, seq, body):
        with self.lock:
            saves = {}
            for member in self.account_ids():
                snapshot = self.snapshot(member)
                data = snapshot["save"]
                if snapshot["error"] or snapshot["has_save"] and type(data.get("has_role")) is not bool:
                    raise ValueError("账号存档损坏，无法读取公会")
                if data.get("has_role"):
                    guild.validate_role(data)
                    saves[member] = data
            path = self.save_path.with_name("guilds.json")
            state = guild.load(path, saves)
            before = copy.deepcopy(state)
            guild.recover(state, saves)
            if session.save.get("has_role"):
                guild.validate_role(session.save)
                saves[account] = session.save
            now = max(int(time.time()), state["checked_at"])
            reply, cost = guild.prepare(opcode, body, state, saves, account, self.role_config, now, self.active)
            packets = [protocol.pack_frame(opcode, seq, reply)]
            if opcode == 2231:
                working = copy.deepcopy(session.save)
                online_rewards.settle(working, self.role_config, session.connected_at, now)
                welfare.settle(working, now)
                player.settle_stamina(working, self.role_config, now)
                player.change_item_count(working, 1001, -cost, self.role_config, now)
                _, created = guild.membership(state, account)
                working.setdefault("guild_creations", []).append(created["pending"]["token"])
                packets.append(protocol.pack_frame(1001, 0, player.apply_role_state(bytes.fromhex(working["role_snapshot"]), working, now)))
                state["checked_at"] = now
                # 草稿先落盘，扣款与收据同存档提交；中断后按收据发布或丢弃草稿。
                guild.write(path, state)
                packets = player.save_response_group(packets, working, session.save, session.save_path,
                                                     self.step_counts, self.role_config, now)
                session.save = working
                saves[account] = working
                guild.recover(state, saves)
            if state != before:
                state["checked_at"] = now
                guild.write(path, state)
            return packets

    def growth_buyers(self):
        """只统计已原子落盘的本地购买账号；损坏存档不能虚增全服人数。"""
        count = 0
        for account in self.account_ids():
            snapshot = self.snapshot(account)
            if snapshot["error"]:
                raise ValueError("账号存档损坏，无法统计成长计划人数")
            save = snapshot["save"]
            if save.get("has_role") and welfare.get_state(save)["growth_bought"]:
                count += 1
        return count

    def rank_saves(self):
        saves = {}
        for account in self.account_ids():
            snapshot = self.snapshot(account)
            if snapshot["error"]:
                raise ValueError("账号存档损坏，无法生成排行榜")
            if snapshot["save"].get("has_role") and snapshot["save"].get("role_snapshot"):
                saves[account] = snapshot["save"]
        return saves

    def observe_rankings(self, previous=None):
        with self.lock:
            return ranking.observe(self.save_path.with_name("rankings.json"), self.rank_saves(),
                                   self.role_config, int(time.time()), previous)

    def rank_query(self, viewer, body, opcode=3500, save=None):
        saves = self.rank_saves()
        if opcode == 3625:
            return ranking.temple_query(body, saves, viewer, self.role_config)
        if opcode in (3100, 3101, 3102):
            return ranking.prepare_mail(opcode, save, body, self.observe_rankings(), viewer, self.role_config)
        if opcode in (5602, 5603):
            if body:
                raise ValueError("成长基线查询不接受参数")
            state = self.observe_rankings()
            return welfare.ids([state["players"].get(str(viewer), {}).get("baseline", 0)])
        if opcode == 5601:
            return ranking.summary(body, self.observe_rankings(), viewer)
        state = self.observe_rankings() if opcode == 3503 or len(list(protocol.iter_pb_fields(body))) == 4 else None
        return ranking.query(body, saves, viewer, self.role_config, state, opcode)

    def account_ids(self):
        with self.lock:
            ids = {1, *self.active}
            for path in (self.save_path.parent / "accounts").glob("*/credentials.json"):
                try:
                    ids.add(parse_account_id(path.parent.name))
                except ValueError:
                    continue
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
                      "registered": self.credential_path(account).exists(),
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
