"""彩金伙伴接通进度：从 configs_sec5.zip 与 battle 的效果号白名单实时复算。

口径与 battle._prepare_teams 完全一致：type=0 是普通属性行（不需要效果号白名单），
其余行按 ``type_param or id`` 取效果号，不在 dynamic 白名单内即视为「未接通」，
付费转换会在扣费前被 check_combat 拒绝。只统计 quality=7 且非主角的伙伴条目。
"""

import json
import zipfile

from zyj_server import battle


def skill_ids(row):
    ids = set()
    for stage in (1, 2, 3):
        for choice in (1, 2, 3):
            value = row.get(f"gold{stage}_will_skills_{choice}", 0)
            if isinstance(value, int) and value:
                ids.add(value)
            elif isinstance(value, str) and value.strip():
                ids.update(int(x) for x in value.replace(";", ",").split(",")
                           if x.strip().isdigit())
    return sorted(ids)


def rows(config_path="configs_sec5.zip"):
    with zipfile.ZipFile(config_path) as archive:
        general = json.loads(archive.read("5/general.json"))
        breakskill = json.loads(archive.read("5/breakskill.json"))
    allowed = (battle.DYNAMIC_BASE | battle.HADES_EFFECTS
               | battle.PARTNER_EFFECTS | battle.LEAD_GOLD_EFFECTS)
    result = []
    for cid, row in general.items():
        if str(row.get("quality")) != "7" or row.get("actor") == "lead":
            continue
        sids = skill_ids(row)
        codes, missing = [], set()
        for sid in sids:
            passive = breakskill.get(str(sid))
            if not passive:
                missing.add(sid)
                continue
            code = passive["type_param"] or passive["id"]
            if 9100001 <= passive["id"] <= 9100007:
                code = passive["id"]
            codes.append(code)
            if passive["type"] != 0 and code not in allowed:
                missing.add(code)
        result.append({"cid": int(cid), "name": row.get("name"), "sids": sids,
                       "codes": sorted(set(codes)), "missing": sorted(missing),
                       "done": not missing})
    return sorted(result, key=lambda r: r["cid"])


def summary(config_path="configs_sec5.zip"):
    data = rows(config_path)
    todo = [r for r in data if not r["done"]]
    return {"total": len(data), "done": len(data) - len(todo), "todo": len(todo),
            "families": len({tuple(r["missing"]) for r in todo}),
            "codes": len({c for r in todo for c in r["missing"]})}


def markdown(config_path="configs_sec5.zip"):
    """生成可直接提交的进度表 Markdown（与 rows() 同一份实时数据）。"""
    data = rows(config_path)
    s = summary(config_path)
    lines = [
        "# 彩金伙伴接通进度表",
        "",
        f"由 `gold_partner_progress.py` 从 `configs_sec5.zip` 与 `battle` 白名单实时复算，"
        f"不要用手工计数。口径：`quality=7` 且非主角；`type=0` 属性行不计；"
        f"其余行按 `type_param or id` 取效果号，不在 `dynamic` 白名单即未接通。",
        "",
        f"- 条目总数 **{s['total']}**，已接通 **{s['done']}**，剩余 **{s['todo']}**",
        f"- 剩余条目归并为 **{s['families']}** 个技能族，共 **{s['codes']}** 个待实现效果号",
        "- 接通 ≠ 只是加白名单：按项目约定每个效果号都必须在 `battle.py` 实现战斗效果并有定向回归",
        "",
        "| CID | 伙伴 | 技能行 | 效果号族 | 缺失效果号 | 状态 |",
        "| ---: | --- | --- | --- | --- | --- |",
    ]
    for r in data:
        sids = f"{r['sids'][0]}–{r['sids'][-1]}" if r["sids"] else "—"
        # 有些技能族含 type=0 属性行（code 回退到行 ID），不能简单用首尾区间表示。
        codes = ", ".join(str(c) for c in r["codes"]) if r["codes"] else "—"
        miss = ", ".join(str(c) for c in r["missing"]) if r["missing"] else "—"
        lines.append(f"| {r['cid']} | {r['name']} | {sids} | {codes} | {miss} | "
                     f"{'已接通' if r['done'] else '未接通'} |")
    lines += ["", "## 批次记录", "",
              "- 2026-11-07：玉鼎／元始／通天／广成子等 13 个条目接通。",
              "- 2026-11-08：太乙真人、魔吕布、如来（含 174013/174003 复用链）。",
              "- 2026-11-09：关羽、燃脂大乔、王母娘娘，共 8 个条目接通"
              "（164001/164002/164003 主链 + 174001/174005/174018 第二链"
              " + 174032/174011 复用同一技能族自动覆盖）。",
              ""]
    return "\n".join(lines)
