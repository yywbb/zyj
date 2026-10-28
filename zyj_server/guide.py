"""客户端引导语义、存档迁移和消息编解码；不读写玩家存档。"""

import functools
import json
import zipfile

from .protocol import encode_varint, iter_pb_fields

print_flush = functools.partial(print, flush=True)


def load_guide_step_counts(config_path):
    counts = {}
    try:
        with zipfile.ZipFile(config_path) as z:
            step_cfg = json.loads(z.read("5/guide_step.json").decode("utf-8"))
            for sec, steps in step_cfg.items():
                counts[int(sec)] = len(steps)
        print_flush(f"[*] 引导配置就绪: 共 {len(counts)} 个 Section, Section 1 共 {counts.get(1, 0)} 步")
    except Exception as e:
        print_flush(f"[!] 读取引导配置失败 ({e})，完成判定将退化为仅依赖客户端上报")
    return counts


def normalize_sections(sections, step_counts):
    """按真实配置纠正状态: 步数已达上限 -> 2(已完成); 否则只要起步就是 1(进行中)。"""
    fixed = {}
    for sec, st in sections.items():
        try:
            sec_i = int(sec)
        except Exception:
            continue
        step = int(st.get("step", 0) or 0)
        status = int(st.get("status", 0) or 0)
        total = step_counts.get(sec_i, 0)
        if step <= 0 and not st.get("steps"):
            continue
        # 保留客户端上报过的完整步骤轨迹 (用于排障; 200 应答只回传最后一步)
        history = st.get("steps") or []
        if isinstance(history, list):
            history = sorted({int(x) for x in history if str(x).isdigit()})
            if step > 0 and step not in history:
                history.append(step)
                history.sort()
        else:
            history = [step] if step > 0 else []
        # 对齐官方抓包: 200 应答里的 step = 客户端"最后上报的那一步"
        # (官方样例 0a06080110021851 -> section=1, status=2, step=81)
        # redo==0 的步骤在 Comb 内上报，不能只看独立的 201 请求。
        if total and step >= total:
            status = 2
        elif status != 2:
            status = 1
        fixed[str(sec_i)] = {"status": status, "step": step, "steps": history}
    return fixed


def migrate_guide(save, step_counts):
    """兼容旧存档: 旧结构是 {section,status,step}, 且 status 只会是 0/2。"""
    g = save.get("guide")
    if not isinstance(g, dict):
        save["guide"] = {"sections": {}}
        return save
    if "sections" not in g:
        sec = int(g.get("section", 1) or 1)
        step = int(g.get("step", 0) or 0)
        sections = {}
        if step > 0:
            # 旧版本用 0 表示"进行中", 客户端不认, 这里纠正为 1
            sections[str(sec)] = {"status": int(g.get("status", 0) or 0), "step": step}
        save["guide"] = {"sections": sections}
    save["guide"]["sections"] = normalize_sections(save["guide"].get("sections", {}), step_counts)
    return save


def encode_guide_section(sec_i, status, step):
    """GuideSection { 1:section, 2:status, 3:step }"""
    sub = bytearray()
    sub.extend(encode_varint((1 << 3) | 0))
    sub.extend(encode_varint(sec_i))
    sub.extend(encode_varint((2 << 3) | 0))
    sub.extend(encode_varint(status))
    sub.extend(encode_varint((3 << 3) | 0))
    sub.extend(encode_varint(step))
    return bytes(sub)


def build_guide_query_pb(sections):
    """GuideQuery { repeated GuideSection sections = 1; }
    sections: { "<段号>": {"status":1|2, "step":n} }"""
    gq = bytearray()
    for sec in sorted(sections.keys(), key=lambda x: int(x)):
        st = sections[sec]
        sub = encode_guide_section(int(sec), int(st.get("status", 0)), int(st.get("step", 0)))
        gq.extend(encode_varint((1 << 3) | 2))
        gq.extend(encode_varint(len(sub)))
        gq.extend(sub)
    return bytes(gq)


def describe_guide(sections, step_counts):
    """生成人可读的引导进度描述。"""
    if not sections:
        return "全新号 (未开始引导)"
    parts = []
    for sec in sorted(sections.keys(), key=lambda x: int(x)):
        st = sections[sec]
        total = step_counts.get(int(sec), 0)
        tag = "已完成" if st.get("status") == 2 else "进行中"
        hist = st.get("steps") or []
        extra = f" 已记录{len(hist)}步" if hist else ""
        parts.append(f"S{sec} {tag} step {st.get('step')}/{total or '?'}{extra}")
    return ", ".join(parts)


def get_guide_sections(save, step_counts):
    g = save.get("guide")
    if not isinstance(g, dict):
        return {}
    return normalize_sections(g.get("sections", {}), step_counts)


def parse_guide_excute(body):
    values = {}
    for fn, wt, value in iter_pb_fields(body):
        if fn in (1, 2):
            if wt != 0:
                raise ValueError("引导 section/step 字段必须是整数")
            values[fn] = value
    if any(fn not in values or not 0 < values[fn] < (1 << 31) for fn in (1, 2)):
        raise ValueError("引导上报缺少有效的 section/step")
    return values[1], values[2]


def record_guide_progress(save, body, step_counts):
    section, step = parse_guide_excute(body)
    sections = get_guide_sections(save, step_counts)
    total = step_counts.get(section, 0)
    rec = sections.get(str(section), {})
    history = set(rec.get("steps") or [])
    history.add(step)
    done = bool(total and step >= total)
    sections[str(section)] = {"status": 2 if done else 1, "step": step, "steps": sorted(history)}
    save["guide"] = {"sections": sections}
    tag = "已完结" if done else "进行中"
    print_flush(f"  [201] Section {section} Step {step}/{total or '?'} [{tag}] 已记录 {len(history)} 步")
