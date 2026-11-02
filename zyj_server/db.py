"""SQLite 数据库存储层（Hybrid JSON 架构）。
支持玩家存档、账号凭据、系统邮件、公会状态、排行榜与 GM 操作流水的事务与索引存储；
与现有 JSON 文件保持平滑自动迁移与双写兼容。
"""

import hashlib
import json
import os
from pathlib import Path
import sqlite3
import threading
import time

_local = threading.local()


def get_db_path(save_path):
    """根据存档路径推导 SQLite 数据库路径（默认为同级目录下的 zyj.db）。"""
    path = Path(save_path)
    return path.parent / "zyj.db"


def connect(db_path):
    """建立具备 WAL 模式与并发超时的 SQLite 连接。"""
    db_path = Path(db_path)
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(db_path), timeout=10.0, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA synchronous=NORMAL")
    conn.execute("PRAGMA busy_timeout=5000")
    return conn


def get_connection(db_path):
    """获取当前线程绑定的数据库连接。"""
    key = str(Path(db_path).resolve())
    conns = getattr(_local, "connections", None)
    if conns is None:
        conns = _local.connections = {}
    if key not in conns:
        conns[key] = connect(db_path)
    return conns[key]


def init_db(db_path, base_dir=None):
    """初始化数据库表结构与索引，若库中为空则自动从磁盘现有 JSON 文件导入。"""
    conn = get_connection(db_path)
    with conn:
        conn.executescript("""
            CREATE TABLE IF NOT EXISTS credentials (
                account_id INTEGER PRIMARY KEY,
                algorithm TEXT NOT NULL,
                iterations INTEGER NOT NULL,
                salt TEXT NOT NULL,
                hash TEXT NOT NULL,
                created_at REAL NOT NULL DEFAULT 0
            );

            CREATE TABLE IF NOT EXISTS players (
                account_id INTEGER PRIMARY KEY,
                role_name TEXT,
                has_role INTEGER NOT NULL DEFAULT 0,
                level INTEGER NOT NULL DEFAULT 1,
                vip INTEGER NOT NULL DEFAULT 0,
                power INTEGER NOT NULL DEFAULT 0,
                coin INTEGER NOT NULL DEFAULT 0,
                gold INTEGER NOT NULL DEFAULT 0,
                stamina INTEGER NOT NULL DEFAULT 0,
                energy INTEGER NOT NULL DEFAULT 0,
                created_at REAL NOT NULL DEFAULT 0,
                last_login REAL NOT NULL DEFAULT 0,
                revision TEXT,
                role_data TEXT NOT NULL,
                updated_at INTEGER NOT NULL
            );

            CREATE INDEX IF NOT EXISTS idx_players_power ON players(power DESC);
            CREATE INDEX IF NOT EXISTS idx_players_level ON players(level DESC);
            CREATE INDEX IF NOT EXISTS idx_players_vip ON players(vip DESC);
            CREATE INDEX IF NOT EXISTS idx_players_last_login ON players(last_login DESC);

            CREATE TABLE IF NOT EXISTS mails (
                id INTEGER PRIMARY KEY,
                target INTEGER NOT NULL DEFAULT 0,
                title TEXT NOT NULL,
                content TEXT NOT NULL,
                attachments TEXT NOT NULL,
                card INTEGER NOT NULL DEFAULT 0,
                recharge_rmb INTEGER NOT NULL DEFAULT 0,
                sender TEXT NOT NULL DEFAULT 'GM',
                created_at INTEGER NOT NULL
            );

            CREATE INDEX IF NOT EXISTS idx_mails_target ON mails(target);
            CREATE INDEX IF NOT EXISTS idx_mails_created_at ON mails(created_at DESC);

            CREATE TABLE IF NOT EXISTS guilds (
                id INTEGER PRIMARY KEY DEFAULT 1,
                state_data TEXT NOT NULL,
                updated_at INTEGER NOT NULL
            );

            CREATE TABLE IF NOT EXISTS rankings (
                id INTEGER PRIMARY KEY DEFAULT 1,
                opened_at INTEGER NOT NULL DEFAULT 0,
                state_data TEXT NOT NULL,
                updated_at INTEGER NOT NULL
            );

            CREATE TABLE IF NOT EXISTS gm_operations (
                op_id TEXT PRIMARY KEY,
                account_id INTEGER,
                action TEXT NOT NULL,
                reason TEXT NOT NULL,
                operator TEXT DEFAULT 'GM',
                created_at REAL NOT NULL,
                details TEXT NOT NULL,
                status TEXT NOT NULL DEFAULT 'success'
            );

            CREATE INDEX IF NOT EXISTS idx_gm_operations_created_at ON gm_operations(created_at DESC);
            CREATE INDEX IF NOT EXISTS idx_gm_operations_account_id ON gm_operations(account_id);
        """)

    if base_dir is not None:
        migrate_from_files(db_path, base_dir)


# ---------------------------------------------------------------------------
# 玩家存档 (players)
# ---------------------------------------------------------------------------

def extract_player_fields(account_id, save_data, now=None):
    """从存档字典提取常用索引字段。"""
    if now is None:
        now = int(time.time())
    role_state = save_data.get("role_state") or {}
    role_name = save_data.get("role_name") or ""
    has_role = 1 if save_data.get("has_role") else 0
    level = int(role_state.get("level") or save_data.get("level") or 1)
    vip = int(role_state.get("vip") or 0)
    power = int(role_state.get("power") or role_state.get("power_all") or 0)
    coin = int(role_state.get("coin") or save_data.get("silver") or 0)
    gold = int(role_state.get("gold") or save_data.get("gold") or 0)
    stamina = int(role_state.get("stamina") or 0)
    energy = int(role_state.get("energy") or save_data.get("energy") or 0)
    created_at = float(save_data.get("created_at") or 0.0)
    last_login = float(save_data.get("last_login") or now)
    raw_json = json.dumps(save_data, ensure_ascii=False, allow_nan=False)
    revision = hashlib.sha256(raw_json.encode("utf-8")).hexdigest()
    return (account_id, role_name, has_role, level, vip, power, coin, gold, stamina,
            energy, created_at, last_login, revision, raw_json, now)


def save_player(db_path, account_id, save_data, now=None):
    """保存或更新玩家角色数据至 SQLite。"""
    row = extract_player_fields(account_id, save_data, now)
    conn = get_connection(db_path)
    with conn:
        conn.execute("""
            INSERT INTO players (
                account_id, role_name, has_role, level, vip, power, coin, gold, stamina,
                energy, created_at, last_login, revision, role_data, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(account_id) DO UPDATE SET
                role_name = excluded.role_name,
                has_role = excluded.has_role,
                level = excluded.level,
                vip = excluded.vip,
                power = excluded.power,
                coin = excluded.coin,
                gold = excluded.gold,
                stamina = excluded.stamina,
                energy = excluded.energy,
                created_at = excluded.created_at,
                last_login = excluded.last_login,
                revision = excluded.revision,
                role_data = excluded.role_data,
                updated_at = excluded.updated_at
        """, row)
    return row[12]  # 返回 revision


def load_player(db_path, account_id):
    """从 SQLite 加载玩家角色数据，不存在返回 None。"""
    conn = get_connection(db_path)
    cur = conn.cursor()
    cur.execute("SELECT role_data FROM players WHERE account_id = ?", (account_id,))
    row = cur.fetchone()
    if not row:
        return None
    try:
        return json.loads(row["role_data"])
    except (ValueError, TypeError):
        return None


def get_player_summary(db_path, account_id):
    """从 SQLite 查询轻量索引字段，不反序列化完整存档。"""
    conn = get_connection(db_path)
    cur = conn.cursor()
    cur.execute("""
        SELECT account_id, role_name, has_role, level, vip, power, coin, gold,
               stamina, energy, created_at, last_login, revision, updated_at
        FROM players WHERE account_id = ?
    """, (account_id,))
    row = cur.fetchone()
    return dict(row) if row else None


def list_top_players(db_path, sort_by="power", limit=50):
    """基于 SQL B-Tree 索引快速查询排行榜。"""
    valid_sorts = {"power": "power DESC", "level": "level DESC", "vip": "vip DESC", "last_login": "last_login DESC"}
    order = valid_sorts.get(sort_by, "power DESC")
    conn = get_connection(db_path)
    cur = conn.cursor()
    cur.execute(f"""
        SELECT account_id, role_name, level, vip, power, coin, gold, last_login
        FROM players
        WHERE has_role = 1
        ORDER BY {order}
        LIMIT ?
    """, (limit,))
    return [dict(r) for r in cur.fetchall()]


def delete_player(db_path, account_id):
    """从数据库删除指定账号的玩家角色数据。"""
    conn = get_connection(db_path)
    with conn:
        conn.execute("DELETE FROM players WHERE account_id = ?", (account_id,))


# ---------------------------------------------------------------------------
# 账号凭据 (credentials)
# ---------------------------------------------------------------------------

def save_credentials(db_path, account_id, record):
    """保存账号密码哈希至 SQLite。"""
    conn = get_connection(db_path)
    with conn:
        conn.execute("""
            INSERT INTO credentials (account_id, algorithm, iterations, salt, hash, created_at)
            VALUES (?, ?, ?, ?, ?, ?)
            ON CONFLICT(account_id) DO UPDATE SET
                algorithm = excluded.algorithm,
                iterations = excluded.iterations,
                salt = excluded.salt,
                hash = excluded.hash,
                created_at = excluded.created_at
        """, (account_id, record["algorithm"], record["iterations"],
              record["salt"], record["hash"], record.get("created_at", time.time())))


def load_credentials(db_path, account_id):
    """从 SQLite 读取账号密码哈希，不存在返回 None。"""
    conn = get_connection(db_path)
    cur = conn.cursor()
    cur.execute("SELECT algorithm, iterations, salt, hash, created_at FROM credentials WHERE account_id = ?", (account_id,))
    row = cur.fetchone()
    if not row:
        return None
    return dict(row)


def has_credentials(db_path, account_id):
    """检查账号是否已设置密码。"""
    conn = get_connection(db_path)
    cur = conn.cursor()
    cur.execute("SELECT 1 FROM credentials WHERE account_id = ?", (account_id,))
    return cur.fetchone() is not None


# ---------------------------------------------------------------------------
# 邮件 (mails)
# ---------------------------------------------------------------------------

def save_mail(db_path, entry):
    """保存单封邮件至 SQLite。"""
    conn = get_connection(db_path)
    attach_json = json.dumps(entry.get("attachments", {}), ensure_ascii=False)
    with conn:
        conn.execute("""
            INSERT INTO mails (id, target, title, content, attachments, card, recharge_rmb, sender, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
                target = excluded.target,
                title = excluded.title,
                content = excluded.content,
                attachments = excluded.attachments,
                card = excluded.card,
                recharge_rmb = excluded.recharge_rmb,
                sender = excluded.sender,
                created_at = excluded.created_at
        """, (entry["id"], entry.get("target", 0), entry["title"], entry.get("content", ""),
              attach_json, entry.get("card", 0), entry.get("recharge_rmb", 0),
              entry.get("sender", "GM"), entry.get("created_at", int(time.time()))))


def delete_mail(db_path, mail_id):
    """从 SQLite 删除指定邮件。"""
    conn = get_connection(db_path)
    with conn:
        cur = conn.execute("DELETE FROM mails WHERE id = ?", (mail_id,))
        return cur.rowcount > 0


def load_all_mails(db_path):
    """从 SQLite 加载全部邮件列表。"""
    conn = get_connection(db_path)
    cur = conn.cursor()
    cur.execute("SELECT id, target, title, content, attachments, card, recharge_rmb, sender, created_at FROM mails ORDER BY id ASC")
    rows = []
    for r in cur.fetchall():
        try:
            attach = json.loads(r["attachments"])
        except (ValueError, TypeError):
            attach = {}
        rows.append({
            "id": r["id"],
            "target": r["target"],
            "title": r["title"],
            "content": r["content"],
            "attachments": attach,
            "card": r["card"],
            "recharge_rmb": r["recharge_rmb"],
            "sender": r["sender"],
            "created_at": r["created_at"]
        })
    return rows


def list_mails(db_path, account_id=None, offset=0, limit=50):
    """带索引的分页邮件查询。"""
    conn = get_connection(db_path)
    cur = conn.cursor()
    if account_id is not None:
        cur.execute("SELECT COUNT(*) FROM mails WHERE target IN (0, ?)", (account_id,))
        total = cur.fetchone()[0]
        cur.execute("""
            SELECT id, target, title, content, attachments, card, recharge_rmb, sender, created_at
            FROM mails WHERE target IN (0, ?)
            ORDER BY created_at DESC, id DESC
            LIMIT ? OFFSET ?
        """, (account_id, limit, offset))
    else:
        cur.execute("SELECT COUNT(*) FROM mails")
        total = cur.fetchone()[0]
        cur.execute("""
            SELECT id, target, title, content, attachments, card, recharge_rmb, sender, created_at
            FROM mails
            ORDER BY created_at DESC, id DESC
            LIMIT ? OFFSET ?
        """, (limit, offset))
    rows = []
    for r in cur.fetchall():
        try:
            attach = json.loads(r["attachments"])
        except (ValueError, TypeError):
            attach = {}
        rows.append({
            "id": r["id"],
            "target": r["target"],
            "title": r["title"],
            "content": r["content"],
            "attachments": attach,
            "card": r["card"],
            "recharge_rmb": r["recharge_rmb"],
            "sender": r["sender"],
            "created_at": r["created_at"]
        })
    return {"rows": rows, "total": total, "offset": offset}


# ---------------------------------------------------------------------------
# 公会状态 (guilds)
# ---------------------------------------------------------------------------

def save_guild(db_path, state_data):
    """保存公会状态数据至 SQLite。"""
    raw = json.dumps(state_data, ensure_ascii=False)
    now = int(time.time())
    conn = get_connection(db_path)
    with conn:
        conn.execute("""
            INSERT INTO guilds (id, state_data, updated_at) VALUES (1, ?, ?)
            ON CONFLICT(id) DO UPDATE SET state_data = excluded.state_data, updated_at = excluded.updated_at
        """, (raw, now))


def load_guild(db_path):
    """从 SQLite 加载公会状态数据，不存在返回 None。"""
    conn = get_connection(db_path)
    cur = conn.cursor()
    cur.execute("SELECT state_data FROM guilds WHERE id = 1")
    row = cur.fetchone()
    if not row:
        return None
    try:
        return json.loads(row["state_data"])
    except (ValueError, TypeError):
        return None


# ---------------------------------------------------------------------------
# GM 操作审计流水 (gm_operations)
# ---------------------------------------------------------------------------

def save_gm_operation(db_path, row):
    """保存一条 GM 操作流水至 SQLite。"""
    conn = get_connection(db_path)
    details_json = json.dumps(row.get("details", row.get("request", {})), ensure_ascii=False)
    with conn:
        conn.execute("""
            INSERT INTO gm_operations (op_id, account_id, action, reason, operator, created_at, details, status)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(op_id) DO UPDATE SET
                details = excluded.details,
                status = excluded.status
        """, (row["id"], row.get("account"), row["action"], row.get("reason", ""),
              row.get("operator", "GM"), float(row.get("at", time.time())),
              details_json, row.get("status", "success")))


def list_gm_operations(db_path, account=None, action="", since=0, until=0, offset=0, limit=50):
    """通过 SQL 索引进行高效的历史操作分页查询。"""
    conn = get_connection(db_path)
    cur = conn.cursor()
    clauses, params = [], []
    if account is not None:
        clauses.append("account_id = ?")
        params.append(account)
    if action:
        clauses.append("action = ?")
        params.append(action)
    if since > 0:
        clauses.append("created_at >= ?")
        params.append(since)
    if until > 0:
        clauses.append("created_at < ?")
        params.append(until)

    where = (" WHERE " + " AND ".join(clauses)) if clauses else ""
    cur.execute(f"SELECT COUNT(*) FROM gm_operations{where}", params)
    total = cur.fetchone()[0]

    cur.execute(f"""
        SELECT op_id, account_id, action, reason, operator, created_at, details, status
        FROM gm_operations{where}
        ORDER BY created_at DESC, op_id DESC
        LIMIT ? OFFSET ?
    """, (*params, limit, offset))

    rows = []
    for r in cur.fetchall():
        try:
            details = json.loads(r["details"])
        except (ValueError, TypeError):
            details = {}
        rows.append({
            "id": r["op_id"],
            "account": r["account_id"],
            "action": r["action"],
            "reason": r["reason"],
            "operator": r["operator"],
            "at": r["created_at"],
            "status": r["status"],
            **details
        })
    return {"rows": rows, "total": total, "offset": offset}


# ---------------------------------------------------------------------------
# 自动迁移工具 (Migrate from JSON files)
# ---------------------------------------------------------------------------

def migrate_from_files(db_path, base_dir):
    """从现有 JSON 文件自动导入初始数据至 SQLite。"""
    base = Path(base_dir)
    conn = get_connection(db_path)

    # 1. 迁移角色存档
    cur = conn.cursor()
    cur.execute("SELECT COUNT(*) FROM players")
    if cur.fetchone()[0] == 0:
        # 账号 1: base / role_save.json
        p1 = base / "role_save.json"
        if p1.exists():
            try:
                save_data = json.loads(p1.read_bytes())
                if isinstance(save_data, dict):
                    save_player(db_path, 1, save_data)
            except Exception:
                pass
        # 账号 2..1000: base / accounts / <id> / role_save.json
        accounts_dir = base / "accounts"
        if accounts_dir.is_dir():
            for sp in accounts_dir.glob("*/role_save.json"):
                try:
                    aid = int(sp.parent.name)
                    save_data = json.loads(sp.read_bytes())
                    if isinstance(save_data, dict):
                        save_player(db_path, aid, save_data)
                except Exception:
                    continue

    # 2. 迁移凭据
    cur.execute("SELECT COUNT(*) FROM credentials")
    if cur.fetchone()[0] == 0:
        accounts_dir = base / "accounts"
        if accounts_dir.is_dir():
            for cp in accounts_dir.glob("*/credentials.json"):
                try:
                    aid = int(cp.parent.name)
                    rec = json.loads(cp.read_bytes())
                    if isinstance(rec, dict) and "hash" in rec:
                        save_credentials(db_path, aid, rec)
                except Exception:
                    continue

    # 3. 迁移邮件
    cur.execute("SELECT COUNT(*) FROM mails")
    if cur.fetchone()[0] == 0:
        mp = base / "mails.json"
        if mp.exists():
            try:
                mdata = json.loads(mp.read_bytes())
                for m in mdata.get("mails", []):
                    save_mail(db_path, m)
            except Exception:
                pass

    # 4. 迁移公会
    cur.execute("SELECT COUNT(*) FROM guilds")
    if cur.fetchone()[0] == 0:
        gp = base / "guilds.json"
        if gp.exists():
            try:
                gdata = json.loads(gp.read_bytes())
                if isinstance(gdata, dict):
                    save_guild(db_path, gdata)
            except Exception:
                pass

    # 5. 迁移 GM 操作日志
    cur.execute("SELECT COUNT(*) FROM gm_operations")
    if cur.fetchone()[0] == 0:
        gm_dir = base / "gm_operations"
        if gm_dir.is_dir():
            for op in gm_dir.glob("*.json"):
                try:
                    odata = json.loads(op.read_bytes())
                    if isinstance(odata, dict) and "id" in odata:
                        save_gm_operation(db_path, odata)
                except Exception:
                    continue
