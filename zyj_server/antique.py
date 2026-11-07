"""33级古董拍卖与鉴定（build 377）：开拍、轮次叫价、落槌、鉴定师结算、记录与一键拍卖。

本地规则（原服抓包无 5410–5415 帧，以下规则按客户端 Lua 语义与真实配置推导，
实现后在此处固定，不事后改写）：
- 开拍（5410 带 cid）：校验等级门槛与实际库存并消耗 1 件古董，按
  antique_appraisal[appraisalID] 生成竞拍队列：第 1 轮时间为开拍时刻，之后每轮
  顺延 round_time 秒；结尾轮固定为鉴定师（npcId=0）。结束轮 R 以
  probability[r] 为累积分布一次性掷出（第 2 轮起首个 u<probability[R] 的轮），
  全部未命中则取配置最后一轮；真品概率取 judge[R]。NPC 出价 = normPrice ×
  uniform(low, high) 且不低于上一轮，鉴定师出价 = normPrice ×
  uniform(gemmologistLow, gemmologistHigh)，出价人不伪造：仅使用配置
  antique_npc 的 1–9 号竞拍人（extraDropPro 全为 0，特殊 NPC 补偿事件不开放）。
- 落槌（5411）：仅在鉴定师到场前（now < 结尾轮时间）且已有叫价时有效，按当前
  轮次把古董以该轮价格卖给该轮竞拍人，货币为 antique_item.coinID；所得写记录。
- 鉴定（5414）：仅在鉴定师到场后有效；真品按结尾轮价格结算，赝品无收益，
  古董不退回。结果与队列在开拍时一次性生成并随存档原子保存。
- 一键拍卖（5415）：请求价格吸附到 antique_fast 最近分段；每件古董独立掷
  true_rate（真品），真品再掷 transaction_rate（成交），成交价 =
  分段 price × uniform(coefficient)；全部收益合并为一次货币结算，写一键记录。
- 记录（5412）：普通记录以 -1 分隔（时间/古董/鉴定结果/每轮轮次、出价人、价格），
  一键记录以 -2 分隔（时间/古董/鉴定结果/数量、真品、赝品、成交、收益），
  最多保留 50 条，新记录在前。
"""

import random

from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint

QUERIES = (5412, 5413)
MUTATIONS = (5410, 5411, 5414, 5415)
OPCODES = QUERIES + MUTATIONS
BUILD = "377"
MAX_RECORDS = 50
COIN_FIELDS = {1000: 1, 1001: 2}


def ids(values):
    return b"".join(encode_pb_field(1, 0, v & ((1 << 64) - 1)) for v in values)


def comb(pairs):
    return b"".join(encode_pb_field(1, 2, encode_pb_field(1, 0, mid) + encode_pb_field(2, 2, data))
                    for mid, data in pairs)


def somethings(coin_id, amount):
    return encode_pb_field(COIN_FIELDS[coin_id], 0, amount) if amount > 0 else b""


def owned(save, cid):
    world = bytes.fromhex(save["world_state"]["1200"])
    return next((pb_get_varint(record, 2) or 0 for name, wire, record in iter_pb_fields(world)
                 if (name, wire) == (1, 2) and pb_get_varint(record, 1) == cid), 0)


def validate_config(config):
    tables = []
    for name in ("antique_item", "antique_appraisal", "antique_fast", "antique_npc"):
        table = config[name]
        if not isinstance(table, dict) or not table:
            raise ValueError(f"{name} 配置无效")
        tables.append(table)
    items, appraisals, fast, npcs = tables
    for row in items.values():
        if (not isinstance(row, dict) or type(row.get("cid")) is not int or not 0 < row["cid"] < (1 << 31)
                or type(row.get("level")) is not int or not 0 < row["level"] < (1 << 31)
                or row.get("coinID") not in COIN_FIELDS
                or type(row.get("normPrice")) is not int or not 0 < row["normPrice"] < (1 << 31)
                or type(row.get("appraisalID")) is not int
                or type(row.get("fast_min")) is not int or type(row.get("fast_max")) is not int
                or not 0 < row["fast_min"] <= row["fast_max"] < (1 << 31)):
            raise ValueError("古董条目配置无效")
        if str(row["appraisalID"]) not in appraisals or str(row["cid"]) not in fast:
            raise ValueError("古董缺少鉴定轮次或一键分段配置")
    for table in appraisals.values():
        if not isinstance(table, dict) or not table:
            raise ValueError("古董鉴定轮次配置无效")
        try:
            keys = sorted(table, key=lambda k: int(k))
        except (TypeError, ValueError):
            raise ValueError("古董鉴定轮次配置无效") from None
        previous_probability = -1
        for index, key in enumerate(keys, 1):
            row = table[key]
            if (int(key) != index or type(row.get("round_time")) is not int or row["round_time"] <= 0
                    or not all(0 < row.get(name, 0) <= row.get(name.replace("Low", "High"))
                               for name in ("low", "gemmologistLow"))
                    or type(row.get("probability")) is not int or not 0 <= row["probability"] <= 100
                    or row["probability"] < previous_probability
                    or type(row.get("judge")) is not int or not 0 <= row["judge"] <= 100):
                raise ValueError("古董鉴定轮次行配置无效")
            previous_probability = row["probability"]
    for sections in fast.values():
        if not isinstance(sections, dict) or not sections:
            raise ValueError("古董一键分段配置无效")
        for row in sections.values():
            if (not isinstance(row, dict) or type(row.get("price")) is not int or not 0 < row["price"] < (1 << 31)
                    or not 0 <= row.get("true_rate", -1) <= 1 or not 0 <= row.get("transaction_rate", -1) <= 1
                    or not isinstance(row.get("coefficient"), str)):
                raise ValueError("古董一键分段行配置无效")
            try:
                low, high = (float(v) for v in row["coefficient"].rstrip(";").split(","))
            except ValueError:
                raise ValueError("古董一键分段系数无效") from None
            if not 0 < low <= high:
                raise ValueError("古董一键分段系数无效")
    if any(row.get("extraDropPro") for row in npcs.values() if isinstance(row, dict)):
        raise ValueError("古董特殊NPC补偿配置尚未接通")
    bidders = sorted(int(row["npc"]) for row in npcs.values()
                     if isinstance(row, dict) and type(row.get("npc")) is int and row.get("bidders", 0) > 0)
    if not bidders:
        raise ValueError("古董竞拍人配置无效")
    return items, appraisals, fast, bidders


def get_state(save, config):
    items, _, _, _ = validate_config(config)
    state = save.get("antique_state", {"checked_at": 0, "auction": None, "records": []})
    if (not isinstance(state, dict) or type(state.get("checked_at")) is not int
            or not 0 <= state["checked_at"] < (1 << 63) or not isinstance(state.get("records"), list)
            or len(state["records"]) > MAX_RECORDS):
        raise ValueError("古董拍卖存档状态无效")
    auction = state.get("auction")
    if auction is not None:
        rounds = auction.get("rounds") if isinstance(auction, dict) else None
        if (rounds is None or not 1 <= len(rounds) <= 20 or auction.get("result") not in (0, 1)
                or type(auction.get("cid")) is not int or str(auction["cid"]) not in items
                or type(auction.get("start")) is not int or not 0 <= auction["start"] < (1 << 63)
                or any(not isinstance(rnd, dict) or rnd.get("npc") not in range(10)
                       or type(rnd.get("price")) is not int or not 0 < rnd["price"] < (1 << 31)
                       or type(rnd.get("time")) is not int or rnd["time"] < 0 for rnd in rounds)
                or rounds[-1]["npc"] != 0
                or any(rounds[i]["time"] >= rounds[i + 1]["time"] for i in range(len(rounds) - 1))):
            raise ValueError("古董拍卖进行状态无效")
    for record in state["records"]:
        if not isinstance(record, dict) or type(record.get("time")) is not int or record["time"] < 0:
            raise ValueError("古董拍卖记录无效")
        if "rounds" in record:
            if (type(record.get("cid")) is not int or str(record["cid"]) not in items
                    or record.get("judge") not in (0, 1) or not isinstance(record["rounds"], list)
                    or any(not isinstance(entry, list) or len(entry) != 3
                           or any(type(v) is not int or v < 0 for v in entry) for entry in record["rounds"])):
                raise ValueError("古董拍卖记录无效")
        else:
            if (type(record.get("cid")) is not int or str(record["cid"]) not in items
                    or record.get("judge") not in (0, 1) or any(type(record.get(k)) is not int
                    or record[k] < 0 for k in ("num", "right", "wrong", "sold", "gold"))
                    or record["right"] + record["wrong"] != record["num"]):
                raise ValueError("古董一键记录无效")
    return state


def request_values(body, count):
    fields = list(iter_pb_fields(body))
    if any(n != 1 or w != 0 or not 0 <= v < (1 << 31) for n, w, v in fields):
        raise ValueError("古董拍卖请求必须为完整整数列表")
    values = [v for _, _, v in fields]
    if count is not None and len(values) != count:
        raise ValueError("古董拍卖请求参数数量无效")
    return values


def require_unlocked(save, config):
    if (not save.get("has_role") or save["role_state"]["level"] < int(config["build"][BUILD]["level"])
            or save.get("guide", {}).get("sections", {}).get("1", {}).get("status") != 2):
        raise ValueError("古董拍卖尚未解锁")


def item_row(config, cid):
    items, _, _, _ = validate_config(config)
    item = items.get(str(cid))
    if item is None:
        raise ValueError("古董不存在")
    return item


def require_item(save, config, cid, count=1):
    item = item_row(config, cid)
    if save["role_state"]["level"] < item["level"]:
        raise ValueError("等级未达到该古董的拍卖门槛")
    if owned(save, cid) < count:
        raise ValueError("古董数量不足")
    return item


def current_round(auction, now):
    """落槌可成交的轮次：鉴定师到场前已叫价的最后一轮，未叫价为 0。"""
    if now >= auction["rounds"][-1]["time"]:
        raise ValueError("拍卖已结束，请等待鉴定师结算")
    return sum(1 for rnd in auction["rounds"][:-1] if now >= rnd["time"])


def bid_prices(item, rng, rounds, count):
    prices, previous = [], 0
    for index in range(1, count + 1):
        row = rounds[str(index)]
        price = int(item["normPrice"] * rng.uniform(row["low"], row["high"]))
        prices.append(max(price, previous, 1))
        previous = prices[-1]
    return prices


def start_auction(config, now, rng, item, cid):
    _, appraisals, _, bidders = validate_config(config)
    rounds = appraisals[str(item["appraisalID"])]
    keys = sorted(rounds, key=lambda k: int(k))
    ticket = rng.randrange(100)
    end = next((int(key) for key in keys[1:] if ticket < rounds[key]["probability"]), len(keys))
    result = 1 if rng.randrange(100) < rounds[str(end)]["judge"] else 0
    queue, elapsed = [], 0
    prices = bid_prices(item, rng, rounds, end - 1)
    for index in range(1, end + 1):
        row = rounds[str(index)]
        elapsed += row["round_time"]
        if index < end:
            npc, price = bidders[rng.randrange(len(bidders))], prices[index - 1]
        else:
            npc = 0
            price = max(int(item["normPrice"] * rng.uniform(row["gemmologistLow"], row["gemmologistHigh"])), 1)
        queue.append({"npc": npc, "price": price, "time": now + elapsed})
    return {"cid": cid, "start": now, "result": result, "rounds": queue}


def queue_reply(auction, status):
    flat = [status, auction["cid"]]
    for index, rnd in enumerate(auction["rounds"], 1):
        flat += [index, rnd["npc"], rnd["price"], auction["result"] if index == len(auction["rounds"]) else 0,
                 rnd["time"]]
    return ids(flat)


def record_rounds(auction, count):
    return [[i + 1, auction["rounds"][i]["npc"], auction["rounds"][i]["price"]] for i in range(count)]


def prepare(opcode, save, body, config, now, seed):
    require_unlocked(save, config)
    state = dict(get_state(save, config))
    rng = random.Random(seed)
    if opcode in MUTATIONS and now < state["checked_at"]:
        raise ValueError("服务器时钟回拨，古董拍卖已停止")
    if opcode == 5410:
        values = request_values(body, None)
        if not values:
            auction = state["auction"]
            return (queue_reply(auction, 1) if auction else ids([0])), [], b""
        if len(values) != 1:
            raise ValueError("古董拍卖请求参数数量无效")
        if state["auction"] is not None:
            raise ValueError("已有拍卖正在进行，请先落槌或鉴定")
        item = require_item(save, config, values[0])
        state["checked_at"] = now
        state["auction"] = start_auction(config, now, rng, item, values[0])
        save["antique_state"] = state
        return queue_reply(state["auction"], 2), [(values[0], 1)], b""
    if opcode == 5415:
        cid, count, price = request_values(body, 3)
        if state["auction"] is not None:
            raise ValueError("已有拍卖正在进行，请先落槌或鉴定")
        item = require_item(save, config, cid, count)
        if not item["fast_min"] <= price <= item["fast_max"]:
            raise ValueError("一键拍卖成交价超出配置区间")
        _, _, fast, _ = validate_config(config)
        sections = fast[str(cid)]
        row = sections[min(sections, key=lambda k: abs(int(k) - price))]
        low, high = (float(v) for v in row["coefficient"].rstrip(";").split(","))
        total, sold, genuine = 0, 0, 0
        for _ in range(count):
            if rng.randrange(10000) < int(round(row["true_rate"] * 10000)):
                genuine += 1
                if rng.randrange(10000) < int(round(row["transaction_rate"] * 10000)):
                    sold += 1
                    total += max(int(row["price"] * rng.uniform(low, high)), 1)
        state["checked_at"] = now
        state["records"] = [{"time": now, "cid": cid, "judge": 1 if genuine else 0, "num": count,
                             "right": genuine, "wrong": count - genuine, "sold": sold, "gold": total},
                            *state["records"]][:MAX_RECORDS]
        state["auction"] = None
        save["antique_state"] = state
        reward = somethings(item["coinID"], total)
        return comb(((0, ids([0, 0])), (1, reward))), [(cid, count)], reward
    if opcode == 5411:
        request_values(body, 0)
        auction = state["auction"]
        if auction is None:
            raise ValueError("当前没有进行中的拍卖")
        index = current_round(auction, now)
        if index == 0:
            raise ValueError("拍卖尚未开始叫价，无法落槌")
        rnd = auction["rounds"][index - 1]
        item = item_row(config, auction["cid"])
        price = rnd["price"]
        state["checked_at"] = now
        state["records"] = [{"time": auction["start"], "cid": auction["cid"], "judge": auction["result"],
                             "rounds": record_rounds(auction, index)}, *state["records"]][:MAX_RECORDS]
        state["auction"] = None
        save["antique_state"] = state
        reward = somethings(item["coinID"], price)
        return comb(((0, ids([rnd["npc"], 0])), (1, reward))), [], reward
    if opcode == 5414:
        request_values(body, 0)
        auction = state["auction"]
        if auction is None:
            raise ValueError("当前没有进行中的拍卖")
        if now < auction["rounds"][-1]["time"]:
            raise ValueError("鉴定师尚未到场，请等待拍卖结束")
        item = item_row(config, auction["cid"])
        price = auction["rounds"][-1]["price"] if auction["result"] else 0
        state["checked_at"] = now
        state["records"] = [{"time": auction["start"], "cid": auction["cid"], "judge": auction["result"],
                             "rounds": record_rounds(auction, len(auction["rounds"]))},
                            *state["records"]][:MAX_RECORDS]
        state["auction"] = None
        save["antique_state"] = state
        reward = somethings(item["coinID"], price)
        return ids([auction["result"]]), [], reward
    if opcode == 5412:
        request_values(body, 0)
        flat = []
        for record in state["records"]:
            if "rounds" in record:
                flat += [-1, record["time"], record["cid"], record["judge"]]
                for entry in record["rounds"]:
                    flat += entry
            else:
                flat += [-2, record["time"], record["cid"], record["judge"], record["num"],
                         record["right"], record["wrong"], record["sold"], record["gold"]]
        return ids(flat), [], b""
    request_values(body, 0)
    auction = state["auction"]
    ended = auction is None or now >= auction["rounds"][-1]["time"]
    return ids([1 if ended else 0]), [], b""
