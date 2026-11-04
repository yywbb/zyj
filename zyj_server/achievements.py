"""普通成就：配置前置链、可信进度和原子领奖；未接入来源不伪造达成。"""

from collections import Counter

from . import cup, equip_evolve, formation, godstone, recruit
from .protocol import encode_pb_field, iter_pb_fields, parse_ids_pb, pb_get_varint

QUERIES = (2400,)
MUTATIONS = (2401,)
OPCODES = QUERIES + MUTATIONS
COUNTERS = ("equipbaptize", "robcount", "penglairewardcount", "petbreakcount", "gang_fishpond", "gang_incense", "worldbosscount", "soulhuntcount",
            "question_fullmarks", "question_weekcount", "question_monthcount", "question_week_one", "question_monthtop50",
            "question_month_three", "question_month_two", "question_month_one")
SUPPORTED_TYPES = {
    "level", "athletics", "cuprank", "blood", "copy", "equip_strengthen", "general", "gang_level", "gang_contribution", "soul",
    "copystar", "generalbreak", "treasurerefine", "treasurestrengthen", "magicstonelevellimit", "petnum", "vip",
    "stone_copy", "blackmarketgoldbuycount", "artifact", "personalboss1", "personalboss2", "battle_power", "fashioncoat",
    *COUNTERS, *(f"sigil{i}" for i in (1, 3, 5, 10, 15, 20, 25, 30, 35, 40)),
    *(f"equip_evolve{i}" for i in (1, 4, 8, 12, 20, 28)),
}


def get_state(save, config):
    state = save.get("achievement_state", {"completed": [], "claimed": [], "counts": {}, "guild_level": 0})
    if not isinstance(state, dict):
        raise ValueError("成就存档无效")
    for name in ("completed", "claimed"):
        values = state.get(name)
        if (not isinstance(values, list) or any(type(cid) is not int or str(cid) not in config["task"] for cid in values)
                or len(values) != len(set(values))):
            raise ValueError("成就完成或领取记录无效")
    claimed = set(state["claimed"])
    predecessors = claimed | {0}
    if (not claimed <= set(state["completed"])
            or any(config["task"][str(cid)]["needid"] not in predecessors for cid in claimed)
            or not isinstance(state.get("counts"), dict)
            or any(k not in COUNTERS or type(v) is not int or not 0 <= v < (1 << 31) for k, v in state["counts"].items())
            or type(state.get("guild_level")) is not int or not 0 <= state["guild_level"] <= max(map(int, config["gang2_level"]))):
        raise ValueError("成就前置、累计计数或公会等级无效")
    return state


def record(save, name, amount, config):
    state = get_state(save, config)
    if name not in COUNTERS or type(amount) is not int or not 0 <= amount < (1 << 31) - state["counts"].get(name, 0):
        raise ValueError("成就累计计数超出范围")
    if amount:
        state["counts"][name] = state["counts"].get(name, 0) + amount
        save["achievement_state"] = state


def snapshot(save, config):
    world = bytes.fromhex(save.get("world_state", {}).get("1002", ""))
    protagonist = pb_get_varint(bytes.fromhex(save.get("protagonist_snapshot", "")), 1)
    partners = [raw for iid, raw in formation.records(world, 1, 2).items() if iid != protagonist
                and config["general"][str(pb_get_varint(raw, 1))]["battle"]]
    equips = [parse_ids_pb(raw) for raw in formation.records(world, 2, 1).values()]
    ordinary = [item for item in equips if config["equip"][str(item[1])]["type"] in ("weapon", "armor", "head", "accessory")]
    treasures = [item + [0] * max(0, 4 - len(item)) for item in equips
                 if config["equip"][str(item[1])]["type"] in ("treasure", "horse")]
    copies = formation.records(bytes.fromhex(save.get("world_state", {}).get("1300", "")), 1, 1)
    slots = formation.records(world, 4, 1)
    level = save.get("role_state", {}).get("level", save.get("level", 1))
    number = min(7, config["role_exp"][str(level)]["slotnum"])
    state = get_state(save, config)
    scalar = {name: save.get("role_state", {}).get(key, 0) for name, key in (("level", "level"), ("vip", "vip"), ("battle_power", "power"))}
    scalar.update(state["counts"])
    scalar.update(save.get("magic_state", {}).get("counts", {}))
    scalar.update(athletics=save.get("arena_state", {}).get("rank", max(map(int, config["athletics_copy2"])) + 1),
                  cuprank=cup.get_state(save)["best"],
                  blood=save.get("mieshendian_state", {}).get("maxfloor", 0),
                  gang_level=state["guild_level"],
                  gang_contribution=save.get("guild_daily_state", {}).get("total_contribution", save.get("guild_daily_state", {}).get("contribution", 0)),
                  copystar=sum(pb_get_varint(point, 3) or 0 for raw in copies.values()
                               for point in formation.records(raw, 7, 1).values()),
                  magicstonelevellimit=min((min(godstone.levels(slots.get(sid, b""), config)) for sid in range(1, number + 1)), default=0),
                  petnum=len(save.get("pet_state", {}).get("pets", [])),
                  soul=sum((pb_get_varint(raw, 3) or 0) >= 10 and pb_get_varint(raw, 2) != 70000 for raw in formation.records(world, 3, 1).values()),
                  artifact=len(save.get("magic_state", {}).get("items", {})),
                  personalboss1=save.get("single_boss_state", {}).get("cleared", {}).get("1", 0),
                  personalboss2=save.get("single_boss_state", {}).get("cleared", {}).get("2", 0),
                  fashioncoat=len(save.get("fashion_state", {}).get("levels", {})),
                  equip_strengthen=max((item[2] for item in ordinary), default=0))
    return {"scalars": scalar, "partners": partners, "treasures": treasures, "copies": copies,
            "sigils": [parse_ids_pb(raw)[2] for raw in formation.records(world, 7, 1).values()],
            "evolves": [equip_evolve.score(item, config) for item in ordinary if str(item[1]) in config["equip_evolve"]], "config": config}


def progress(row, view):
    kind, target = row["type"], list(map(int, row["target"].split(",")))
    if kind not in SUPPORTED_TYPES:
        return 0, False
    required = target[-1]
    if kind == "copy":
        points = formation.records(view["copies"].get(target[0], b""), 7, 1)
        return (1, True) if (pb_get_varint(points.get(target[1], b""), 3) or 0) > 0 else (0, False)
    if kind in ("general", "generalbreak"):
        current = sum((view["config"]["general"][str(pb_get_varint(raw, 1))]["quality"] if kind == "general"
                       else pb_get_varint(raw, 4) or 0) >= target[0] for raw in view["partners"])
    elif kind in ("treasurerefine", "treasurestrengthen"):
        current = sum(item[3 if kind == "treasurerefine" else 2] >= target[0] for item in view["treasures"])
    elif kind.startswith("equip_evolve"):
        levels = sorted(view["evolves"], reverse=True)
        number = int(kind[len("equip_evolve"):])
        current = levels[number - 1] if len(levels) >= number else 0
    elif kind.startswith("sigil"):
        number = int(kind[5:])
        levels = sorted(view["sigils"], reverse=True)
        current = levels[number - 1] if len(levels) >= number else 0
    else:
        current = view["scalars"].get(kind, 0)
    return current, 0 < current <= required if kind in ("athletics", "cuprank") else current >= required


def observe(save, config, before=None):
    if not save.get("has_role"):
        return
    state = get_state(save, config)
    completed = set(state["completed"])
    sources = [save]
    if before and before.get("has_role") and "achievement_state" not in before:
        sources.append(before)
    for source in sources:
        view = snapshot(source, config)
        for row in config["task"].values():
            if row["id"] not in completed and progress(row, view)[1]:
                completed.add(row["id"])
    state["completed"] = sorted(completed)
    save["achievement_state"] = state


def statuses(save, config):
    state = get_state(save, config)
    completed, claimed = set(state["completed"]), set(state["claimed"])
    view = snapshot(save, config)
    result = {}
    for row in config["task"].values():
        if row["id"] in claimed or row["needid"] and row["needid"] not in claimed:
            continue
        current, done = progress(row, view)
        result[row["id"]] = (int(row["type"] in SUPPORTED_TYPES and (done or row["id"] in completed)), current)
    return result


def prepare(opcode, save, body, config):
    fields = list(iter_pb_fields(body))
    if (opcode == 2400 and body or opcode == 2401 and (len(fields) > 1 or any((n, w) != (1, 0)
            or str(cid) not in config["task"] for n, w, cid in fields)) or not save.get("has_role")):
        raise ValueError("成就参数无效或角色尚未创建")
    observe(save, config)
    rows = statuses(save, config)
    if opcode == 2400:
        return b"".join(encode_pb_field(1, 2, b"".join(encode_pb_field(n, 0, value) for n, value in
                        ((1, cid), (2, status), (3, current)))) for cid, (status, current) in sorted(rows.items()))
    selected = [fields[0][2]] if fields else [cid for cid, (status, _) in rows.items() if status == 1]
    if not selected or any(rows.get(cid, (0, 0))[0] != 1 for cid in selected):
        raise ValueError("成就尚未达成、前置未领取或奖励已领取")
    prizes = Counter()
    for cid in selected:
        row = config["task"][str(cid)]
        if row["xp"]:
            raise ValueError("此成就的经验奖励尚未接入")
        if row["coin"]:
            prizes[1000] += row["coin"]
        for index in (1, 2):
            if row[f"award{index}"]:
                prizes[row[f"award{index}"]] += row[f"award{index}num"]
    reward = recruit.build_reward(save, sorted(prizes.items()), config)
    get_state(save, config)["claimed"].extend(sorted(selected))
    return reward
