"""端到端协议回放对照：按真实 1017 走完整突破→扣费→存档→重连→战斗。

不启动游戏、不碰手机与账号。用临时收窄 battle.PARTNER_EFFECTS 复现「修复前」
在扣费前被 check_combat 拒绝，再与修复后的真实事务和确定性战斗数值对照。
运行 `python -B gold_replay_contrast.py` 会把对照表写入 end_to_end_replay.md。
"""

import copy
import sys

import test_soul
import test_partner_growth
from zyj_server import battle, development, partner_growth, player, protocol

NEW_CODES = ({*range(9000524, 9000529)} | {*range(9000529, 9000535)}
             | {*range(9000541, 9000547)})


class Harness(test_soul.SoulTests):
    def runTest(self):
        pass

    put_hero = test_partner_growth.PartnerGrowthTests.put_hero
    paid = test_partner_growth.PartnerGrowthTests.paid


def fresh():
    harness = Harness()
    test_soul.SoulTests.setUp(harness)
    harness.iid = 2000900
    harness.save["role_state"].update(level=150, coin=10**12, gold=1000000)
    return harness


def ready(harness, base):
    raw = harness.put_hero(base, advance=13, awake=90)
    raw = protocol.pb_set_varint(raw, 23, 30)
    for field, value in partner_growth.fairy(raw, harness.config).items():
        raw = protocol.pb_set_varint(raw, field, value)
    raw = partner_growth.power(harness.save, harness.gen(harness.iid), raw)
    player.record_slot_update(harness.save, protocol.encode_pb_field(1, 2, raw))
    return raw


def body(*values):
    return b"".join(protocol.encode_pb_field(1, 0, v) for v in values)


def battle_unit(config, cid, **values):
    return {"cid": cid, "iid": cid, "level": 10, "advance": 0, "atk": 100, "def": 0,
            "hp": 10000, "speed": 100, "skill": config["general"][str(cid)]["skillid"],
            "initial_ap": 0, **values}


def gold_unit(config, cid, *pids, **values):
    return battle_unit(config, cid, iid=values.pop("iid", 700), advance=16,
                       partner_skills=list(pids), **values)


def isolated(config, cid):
    """清掉目标伙伴的低突破被动，保证对照只受本次选择的彩金技能影响。"""
    return {**config, "general": {**config["general"],
            str(cid): {**config["general"][str(cid)],
                       **{f"break{i}": 0 for i in range(1, 17)}}}}


def dealt(report):
    return sum(x["m"]["m"] for action in report["b"]["a"] for x in action["e"]
               if x["r"] is False and isinstance(x.get("m"), dict) and x["m"]["m"] > 0)


def heals(report):
    return [x["m"]["m"] for action in report["b"]["a"] for x in action["e"]
            if x["r"] is True and isinstance(x.get("m"), dict) and x["m"]["m"] < 0]


def contrast(config, name):
    """按伙伴返回 (口径说明, 无技能实测, 带技能实测)。"""
    if name == "关羽":
        config = isolated(config, 164001)
        values = []
        for pids in ((), (9001014,), (9001014, 9001015)):
            teams = {True: {2: gold_unit(config, 164001, *pids)},
                     False: {2: battle_unit(config, 10201, iid=1)}}
            battle._prepare_teams(teams, config)
            values.append(int(teams[True][2]["atk"]))
        return "开场攻击（天龙神姿/龙神乱舞光环）", values[0], values[1], values[2]
    if name == "燃脂大乔":
        config = isolated(config, 164002)
        # 去掉 +20000 攻击光环，只对照「前 2 回合 +25% 伤害」本身。
        table = dict(config["breakskill"])
        table["9001021"] = {**table["9001021"], "value2": 0}
        config = {**config, "breakskill": table}
        totals = []
        for pids in ((), (9001021,)):
            report = battle.simulate(
                {2: gold_unit(config, 164002, *pids, iid=700, speed=300, atk=100)},
                {2: battle_unit(config, 10201, iid=1, hp=10**9, atk=100, speed=1)},
                config, 7, max_rounds=2)
            totals.append(dealt(report))
        return "己方吴国前 2 回合累计伤害（潮街领舞）", totals[0], totals[1], None
    config = isolated(config, 164003)
    totals = []
    for pids in ((), (9001028,)):
        report = battle.simulate(
            {2: gold_unit(config, 164003, *pids, iid=700, speed=200, atk=10),
             8: battle_unit(config, 10201, iid=701, speed=1)},
            {2: battle_unit(config, 10201, iid=1, hp=100000, atk=100, speed=300,
                            initial_ap=4)},
            config, 7, max_rounds=1)
        totals.append(heals(report))
    return "王母怜生治疗量（生命最低者，受缺失生命 clamp）", 0, totals[1][0] if totals[1] else 0, None


def run():
    test_soul.setUpModule()
    cases = (("关羽", 10825, 164001, (1, 3, 1)),
             ("燃脂大乔", 10834, 164002, (2, 3, 2)),
             ("王母娘娘", 10817, 164003, (1, 2, 1)))
    results = []
    for name, base, gold_cid, picks in cases:
        harness = fresh()
        ready(harness, base)
        request = body(base, picks[0], 13)
        original = battle.PARTNER_EFFECTS
        battle.PARTNER_EFFECTS = original - NEW_CODES
        try:
            try:
                development.prepare(1017, copy.deepcopy(harness.save), request, harness.config)
                before = "未拒绝（异常）"
            except ValueError as error:
                before = str(error)
        finally:
            battle.PARTNER_EFFECTS = original
        steps = []
        for stage, choice in enumerate(picks, 14):
            old = protocol.pb_get_varint(harness.gen(harness.iid), 1)
            _, costs, _ = development.prepare(
                1017, copy.deepcopy(harness.save), body(old, choice, stage - 1), harness.config)
            steps.append((stage, choice, old, sum(count for _, count in costs)))
            harness.paid(1017, [old, choice, stage - 1])
        hero = harness.gen(harness.iid)
        assert [protocol.pb_get_varint(hero, f) for f in (1, 4, 35, 36, 37)] == [gold_cid, 16, *picks]
        partner_growth.check_combat(hero, harness.config)
        harness.reconnect()
        harness.refresh()
        assert harness.gen(harness.iid) == hero
        label, plain, boosted, stacked = contrast(harness.config, name)
        results.append({"partner": name, "chain": f"{base}→{gold_cid}", "opcode": "1017",
                        "before": before, "steps": steps, "persisted": True,
                        "label": label, "plain": plain, "boosted": boosted,
                        "stacked": stacked})
    return results


def markdown(results):
    lines = ["# 彩金突破端到端协议回放对照", "",
             "本地按真实 `1017` 三阶付费走完整事务（扣费 → 存档 → 重连 → `check_combat`），"
             "再用确定性 `battle` 做数值对照；未启动游戏、未连接手机、未操作任何账号。", "",
             "「修复前」由临时收窄 `battle.PARTNER_EFFECTS` 复现（随后立即还原），"
             "故障发生在扣费之前，与用户报障一致。", "",
             "| 伙伴 | 链 | opcode | 修复前（扣费前） | 修复后付费链 | 存档/重连 | 战斗对照 |",
             "| --- | --- | --- | --- | --- | --- | --- |"]
    for r in results:
        steps = " → ".join(f"+{stage} 选{choice} (cid {cid}, 花费 {cost})"
                           for stage, choice, cid, cost in r["steps"])
        metric = f"{r['label']}：{r['plain']} → {r['boosted']}"
        if r["stacked"] is not None:
            metric += f"，双选仍为 {r['stacked']}（不叠加）"
        lines.append(f"| {r['partner']} | {r['chain']} | {r['opcode']} | {r['before']} | "
                     f"{steps} | {'一致' if r['persisted'] else '不一致'} | {metric} |")
    lines += ["", "复现方式：`python -B gold_replay_contrast.py` 重新生成本表；"
              "`test_gold_replay_contrast.py` 对上述数值做断言。", ""]
    return "\n".join(lines)


if __name__ == "__main__":
    data = run()
    with open("end_to_end_replay.md", "w", encoding="utf-8", newline="\n") as stream:
        stream.write(markdown(data) + "\n")
    print("replay rows:", len(data), file=sys.stderr, flush=True)
