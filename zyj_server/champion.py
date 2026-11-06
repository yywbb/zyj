"""冠军试炼：两关配置NPC、真实挑战/宝箱和试炼点商店；本地规则见battle_rules.md。"""

import json
import random

from . import activities, arena, battle, cheer, pets, recharge
from .penglai import comb
from .protocol import encode_pb_field, iter_pb_fields
from .ranking import parameters


QUERIES = (2700, 2710)
MUTATIONS = (2701, 2702, 2703, 2704, 2705, 2711, 2712)
OPCODES = QUERIES + MUTATIONS


def get_state(save, config):
    state = save.setdefault('champion_state', dict(day=0, checked_at=0, level=0, stage=1, used=0,
        resets=0, boxes=0, serial=1, cleared=[], points=0, period=0, refreshes=0, shelf_serial=0, slots=[]))
    integers = ('day', 'checked_at', 'level', 'stage', 'used', 'resets', 'boxes', 'serial',
                'points', 'period', 'refreshes', 'shelf_serial')
    if (not isinstance(state, dict) or any(type(state.get(k)) is not int or not 0 <= state[k] < (1 << 31) for k in integers)
            or state['stage'] not in (1, 2) or not 0 < state['serial'] or not 0 <= state['boxes'] <= 5
            or state['level'] != 0 and str(state['level']) not in config['champion_produce']
            or state['used'] > int(config['global_kv']['champion_times']['value'])
            or state['resets'] > max(r['champion_times'] for r in config['vip'].values())
            or not isinstance(state.get('cleared'), list) or not isinstance(state.get('slots'), list)):
        raise ValueError('冠军试炼存档无效')
    cleared = state['cleared']
    if (any(type(i) is not int or not 1 <= i <= 9 for i in cleared) or len(set(cleared)) != len(cleared)
            or len(cleared) + (3 if state['stage'] == 2 else 0) > state['used']
            or any(i > 3 and not any((p-1)//3 == (i-1)//3-1 and abs((p-1)%3-(i-1)%3) <= 1 for p in cleared) for i in cleared)
            or state['boxes'] and not any(i >= 7 for i in cleared)
            or bool(state['level']) != bool(state['day'])
            or not state['level'] and (state['used'] or cleared or state['boxes'] or state['resets'] or state['stage'] != 1)):
        raise ValueError('冠军试炼据点存档无效')
    if len(state['slots']) not in (0, 6) or bool(state['slots']) != bool(state['period']) or bool(state['slots']) != bool(state['shelf_serial']):
        raise ValueError('试炼商店货架存档无效')
    for slot in state['slots']:
        if (not isinstance(slot, list) or len(slot) != 2 or any(type(v) is not int for v in slot)
                or str(slot[0]) not in config['champion_goods'] or not 0 <= slot[1] <= config['champion_goods'][str(slot[0])]['limit']):
            raise ValueError('试炼商店商品存档无效')
    return state


def bump(state, key='serial'):
    if state[key] >= (1 << 31)-1:
        raise ValueError('冠军试炼操作序号已耗尽')
    state[key] += 1


def settle(save, config, now):
    state = get_state(save, config)
    day = (now+28800)//86400
    if day > state['day']:
        state.update(day=day, level=save['role_state']['level'], stage=1, used=0, resets=0, boxes=0, cleared=[], refreshes=0)
        bump(state)
    state['checked_at'] = max(state['checked_at'], now)
    return state


def box_status(state):
    return (3 if state['boxes'] == 5 else 2 if state['boxes'] else 1) if any(i >= 7 for i in state['cleared']) else 0


def open_points(state):
    return [i for i in range(1, 10) if i not in state['cleared'] and (i <= 3 or any(
        (p-1)//3 == (i-1)//3-1 and abs((p-1)%3-(i-1)%3) <= 1 for p in state['cleared']))]


def npc(state, point, config):
    # 自研：沿三条路线逐排增强，冻结本轮队伍等级；不借用真实玩家或旧竞技场战报。
    rank = 1000-(state['stage']-1)*450-((point-1)//3)*150-((point-1)%3)*50
    row = dict(config['athletics_copy2'][str(rank)], level=state['level']*int(config['global_kv']['general_level']['value']))
    return rank, row


def board(save, state, config):
    messages = [(0, recharge.ids([state['stage'], state['used'], state['resets'], box_status(state), state['boxes']]))]
    available = open_points(state)
    for i in range(1, 10):
        _, row = npc(state, i, config)
        _, defense = arena.rosters(save, row, config)
        power = sum(u['atk']+u['def']+u['hp']//10 for u in defense.values())
        profile = next(iter(defense.values()))['cid']
        messages.append((i, parameters([2 if i in state['cleared'] else int(i in available),
            0 if i in state['cleared'] else 100, profile, power, row['name'], 0, 0])))
    messages.append((100, recharge.ids([state['serial'], state['level'], state['day']])))
    return comb(messages)


def ids(body):
    fields = list(iter_pb_fields(body))
    if any((n, w) != (1, 0) or not 0 <= v < (1 << 31) for n, w, v in fields):
        raise ValueError('冠军试炼整数参数无效')
    return [v for _, _, v in fields]


def box_cost(opened, count, config):
    prices = [config['buycount_price'][str(i)]['championbox_cost'] for i in range(opened+1, count+1)]
    if any(type(price) is not int or price < 0 for price in prices) or sum(prices) >= (1 << 31):
        raise ValueError('试炼宝箱费用配置无效')
    return sum(prices)


def fight(save, state, point, config, seed):
    if state['used'] >= int(config['global_kv']['champion_times']['value']) or point not in open_points(state):
        raise ValueError('试炼次数不足或据点尚未开放/已经战胜')
    rank, row = npc(state, point, config)
    attack, defense = arena.rosters(save, row, config)
    report = battle.simulate(attack, defense, config, seed, attack_pet=pets.combat(save, config), attack_cheer=cheer.combat(save, config, illusion_mode="pvp"))
    report['meta']['attack']['n'] = save['role_name']
    report['meta']['defense']['n'] = row['name']
    state['used'] += 1
    specification = ''
    if report['result']:
        state['cleared'].append(point)
        specification = config['champion_produce'][str(state['level'])][str(state['stage'])][f'stronghold{point}']
    save['last_champion_battle'] = dict(seed=seed, rules=report['rules'], stage=state['stage'], point=point,
                                      npc=rank, won=report['result'], rounds=report['round'])
    return report, specification


def open_box(state, config):
    if box_status(state) not in (1, 2):
        raise ValueError('请先击败最后一排据点，或本关宝箱已全部开启')
    state['boxes'] += 1
    return config['champion_produce'][str(state['level'])][str(state['stage'])][f'storehouse{state["boxes"]}']


def next_stage(state):
    if state['stage'] != 1 or not state['boxes']:
        raise ValueError('免费宝箱未领取或已经是最后一关')
    state.update(stage=2, boxes=0, cleared=[])


def auto_cost(state, boxes, config):
    return box_cost(state['boxes'], max(boxes, state['boxes']), config) + (box_cost(0, boxes, config) if state['stage'] == 1 else 0)


def complete(save, state, path, boxes, config, seed):
    stats, specifications = [0]*6, []
    for _ in range(2):
        while not box_status(state) and state['used'] < int(config['global_kv']['champion_times']['value']):
            candidates = open_points(state)
            point = min(candidates, key=lambda i: (-((i-1)//3), abs((i-1)%3-(path-1)), i))
            report, specification = fight(save, state, point, config, seed+stats[0])
            stats[0] += 1
            stats[1 if report['result'] else 2] += 1
            specifications.append(specification)
            if not report['result']:
                return stats, ';'.join(specifications)
        if not box_status(state):
            break
        if state['boxes'] < boxes:
            stats[3] += 1
        while state['boxes'] < boxes:
            stats[5] += box_cost(state['boxes'], state['boxes']+1, config)
            specifications.append(open_box(state, config))
            stats[4] += 1
        if state['stage'] == 2:
            break
        next_stage(state)
    return stats, ';'.join(specifications)


def shelf_period(now, config):
    local = now+28800
    return max((local//86400-offset)*86400+r['hour']*3600-28800
               for r in config['champion_refresh'].values() for offset in (0, 1)
               if (local//86400-offset)*86400+r['hour']*3600 <= local)


def eligible(row, save):
    return row['down_level'] <= save['role_state']['level'] <= row['up_level'] and row['vip'] <= save['role_state']['vip']


def refresh_shop(save, state, config, seed):
    rng, slots = random.Random(seed), []
    for key in range(1, 7):
        table = config['champion_paramete'][str(key)]
        entries = []
        for entry in table['items2' if (state['refreshes'] and state['refreshes'] % 10 == 0) else 'items'].split(';'):
            if entry:
                cid, weight = map(int, entry.split(','))
                if cid <= 0 or weight < 0 or str(cid) not in config['champion_goods']:
                    raise ValueError('试炼商店货位配置无效')
                if eligible(config['champion_goods'][str(cid)], save):
                    entries.append((cid, weight))
        if not entries or sum(w for _, w in entries) <= 0:
            raise ValueError('试炼商店缺少可用商品')
        slots.append([rng.choices([i for i, _ in entries], [w for _, w in entries])[0], 0])
    state['slots'] = slots
    bump(state, 'shelf_serial')


def shop_query(state):
    return recharge.ids([state['points'], state['refreshes'], *(v for slot in state['slots'] for v in slot), state['shelf_serial'], state['period']])


def prepare(opcode, save, body, config, now, seed):
    if not save.get('has_role') or save['role_state']['level'] < config['build']['179']['level']:
        raise ValueError('冠军试炼需要50级')
    state = get_state(save, config)
    if opcode in MUTATIONS and (now < state['checked_at'] or now < save.get('stamina_clock', {}).get('checked_at', 0)):
        raise ValueError('服务器时钟回拨，冠军试炼未执行')
    state = settle(save, config, now)
    values = ids(body)
    if opcode in QUERIES:
        if values:
            raise ValueError('冠军试炼查询不接受参数')
        if opcode == 2700:
            return board(save, state, config), [], b''
        period = shelf_period(now, config)
        if period > state['period']:
            state['period'] = period
            refresh_shop(save, state, config, seed)
        return shop_query(state), [], b''
    sizes = {2701: 2, 2702: 1, 2703: 2, 2704: 2, 2705: 4, 2711: 5, 2712: 2}
    shop = opcode in (2711, 2712)
    if (len(values) != sizes[opcode] or values[0] != state['shelf_serial' if shop else 'serial']
            or shop and (not state['slots'] or state['period'] != shelf_period(now, config))):
        raise ValueError('试炼状态、货架或报价已变化，请重新打开页面')
    costs, reward = [], b''
    if opcode == 2701:
        report, specification = fight(save, state, values[1], config, seed)
        reward = activities.build_reward(save, specification, config)
        response = (encode_pb_field(1, 0, int(report['result']))+encode_pb_field(2, 0, report['star'])
            +encode_pb_field(4, 2, reward)+encode_pb_field(5, 2, json.dumps(report, ensure_ascii=False, separators=(',', ':')).encode('utf-8')))
    elif opcode == 2702:
        next_stage(state)
    elif opcode == 2703:
        if state['resets'] >= config['vip'][str(save['role_state']['vip'])]['champion_times'] or box_status(state) == 1:
            raise ValueError('今日试炼重置次数不足或免费宝箱尚未领取')
        price = config['buycount_price'][str(state['resets']+1)]['champion_cost']
        if type(price) is not int or not 0 <= price < (1 << 31) or values[1] != price:
            raise ValueError('试炼重置报价已变化')
        costs = [(1001, price)]
        state.update(stage=1, used=0, boxes=0, cleared=[], level=save['role_state']['level'], resets=state['resets']+1)
    elif opcode == 2704:
        price = box_cost(state['boxes'], state['boxes']+1, config)
        if values[1] != price:
            raise ValueError('试炼宝箱报价已变化')
        reward = activities.build_reward(save, open_box(state, config), config)
        costs = [(1001, price)]
        response = comb([(0, recharge.ids([box_status(state), state['boxes']])), (1, reward)])
    elif opcode == 2705:
        _, path, boxes, ceiling = values
        if (path not in (1, 2, 3) or not 1 <= boxes <= 5 or save['role_state']['level'] < int(config['global_kv']['champion_level']['value'])
                and save['role_state']['vip'] < int(config['global_kv']['champion_vip']['value'])):
            raise ValueError('一键试炼需要90级或VIP6，及有效路线/宝箱数量')
        if ceiling != auto_cost(state, boxes, config) or save['role_state']['gold'] < ceiling:
            raise ValueError('一键试炼报价已变化或元宝不足以覆盖上限')
        stats, specification = complete(save, state, path, boxes, config, seed)
        reward = activities.build_reward(save, specification, config)
        costs = [(1001, stats[5])]
        response = comb([(0, recharge.ids(stats)), (1, reward)])
    elif opcode == 2711:
        _, slot, cid, count, quoted = values
        if not 1 <= slot <= 6 or not 1 <= count <= 10 or cid != state['slots'][slot-1][0]:
            raise ValueError('试炼商店目标或数量已变化')
        row = config['champion_goods'][str(cid)]
        currency, price = map(int, row['consume'].strip(';').split(','))
        if currency != 1009 or not 0 < price*count < (1 << 31) or quoted != price or not eligible(row, save) or state['slots'][slot-1][1]+count > row['limit']:
            raise ValueError('试炼商店价格、等级或剩余数量已变化')
        reward = activities.build_reward(save, row['good'], config, count)
        state['slots'][slot-1][1] += count
        activities.record_liveness(save, 50, count, config, now)
        costs, response = [(1009, price*count)], reward
    else:
        currency, price = map(int, config['global_kv']['champion_refreshgold']['value'].strip(';').split(','))
        if currency != 1009 or not 0 < price < (1 << 31) or values[1] != price or state['refreshes'] >= (1 << 31)-1:
            raise ValueError('试炼商店刷新报价或次数无效')
        state['refreshes'] += 1
        refresh_shop(save, state, config, seed)
        costs = [(1009, price)]
    if shop:
        if opcode == 2711:
            bump(state, 'shelf_serial')
        if opcode == 2712:
            response = shop_query(state)
    else:
        bump(state)
        if opcode in (2702, 2703):
            response = board(save, state, config)
    return response, costs, reward
