--
-- Created by IntelliJ IDEA.
-- User: jutian
-- Date: 15/9/24
-- Time: 下午3:39
-- To change this template use File | Settings | File Templates.
--

local battlereport_pb = require("battlereport_pb")

local function BRPTTMetaMetaPosition(t1,t2, x)
    t1.name = x.name
    for k,v in ipairs(x.generals) do
        local general = {
            id = v.id,
            cid = v.cid,
            level1 = v.level1,
            level2 = v.level2,
            level3 = v.level3 or 0,
            name = v.name,
            hp = v.hp,
            hp2 = v.hp2,
            ap = v.ap,
            defaultskill = {id=v.skill},

            cover_d = v.cover_d or 0,
            cover_d2 = v.cover_d2 or 0,
            cover_p = v.cover_p or 0,
            cover_l = v.cover_l or 0,

            w_l = v.w_l or 0,
            w_c = v.w_c or 0,
            a_cid = v.a_cid or 0,
            a_level = v.a_level or 0,
        }
        t1.generals[string.format("%d",general.id)] = general
        t2[string.format("%d",v.pos)] = {
            id = v.id,
            boss = v.boss
        }
    end
    if x.pet.id > 0 then
        t1.pet = {}
        t1.pet[string.format("%d",x.pet.id)] = {
            id = x.pet.id,
            cid = x.pet.cid,
            level1 = x.pet.level1,
            level2 = x.pet.level2,
            ap = x.pet.ap,
        }
        t2["0"] = {
            id = x.pet.id,
            pet = true
        }
    end
end

local function BRPTTBattleActionSource(source, pb)

    if #(pb.pos) ~= 0 then
        source.direct = pb.direct
        source.pos = {}
        for k,v in ipairs(pb.pos) do
            table.insert(source.pos, v)
        end
        if pb.type == 0 then
            source.type = "normal"
        elseif pb.type == 1 then
            source.type = "skill"
        elseif pb.type == 2 then
            source.type = "comb"
        elseif pb.type == 3 then
            source.type = "break"
        elseif pb.type == 4 then
            source.type = "skilleffect"
        end

        if pb.skill and pb.skill > 0 then
            source.skillid = pb.skill
        end
        if pb.passive  and pb.passive > 0 then
            source.passive = pb.passive
        end
    end
end

local function BRPTTBattleActionDests(dests, pb)
    local dest
    if pb.status and pb.status.valid == true then
        local damage = {
            direct = pb.damage.direct,
            pos = pb.damage.pos,
            status = {
                status = pb.status.status
            }
        }
        if pb.status.switch ~= nil then
            damage.status.switch = pb.status.switch
        end
        dest = damage
    end
    if pb.buffer and pb.buffer.valid == true then
        local damage
        if dest then
            damage = dest
            damage.buffer = {
                status = pb.buffer.status
            }
        else
            damage = {
                direct = pb.damage.direct,
                pos = pb.damage.pos,
                buffer = {
                    status = pb.buffer.status
                }
            }
        end
        if pb.buffer.attr then
            local n = tonumber(pb.buffer.attr);
            if n then
                damage.buffer.attr = n
            else
                damage.buffer.attr = pb.buffer.attr
            end
        end
        if pb.buffer.switch ~= nil then
            damage.buffer.switch = pb.buffer.switch
        end
        dest = damage
    end
    if pb.damage and pb.damage.valid == true then
        local damage
        if dest then
            damage = dest
            damage.direct = pb.damage.direct
            damage.pos = pb.damage.pos
            damage.damage = {}
        else
            damage = {
                direct = pb.damage.direct,
                pos = pb.damage.pos,
                damage = {}
            }
        end
        if pb.damage.damage then
            damage.damage.damage = pb.damage.damage
        end
        if pb.damage.damage2 then
            damage.damage.damage2 = pb.damage.damage2
        end
        if pb.damage.status then
            local status = pb.damage.status
            cclog("damage status %d", status)
            if status == 0 then
                damage.damage.status = "dodge"
            elseif status == 10 then
                damage.damage.status = "normal"
            elseif status == 11 then
                damage.damage.status = "parry"
            elseif status == 12 then
                damage.damage.status = "dot"
            elseif status == 19 then
                damage.damage.status = "dead"
            elseif status == 20 then
                damage.damage.status = "critical"
            elseif status == 21 then
                damage.damage.status = "critical;parray"
            elseif status == 29 then
                damage.damage.status = "critical;dead"
            elseif status == 30 then
                damage.damage.status = "passive"
            elseif status == 40 then
                damage.damage.status = "cut"
            elseif status == 41 then
                damage.damage.status = "cut;dead"
            elseif status == 50 then
                damage.damage.status = "sacrifice"
            elseif status == 60 then
                damage.damage.status = "fight"
            elseif status == 61 then
                damage.damage.status = "fight;dead"
            elseif status == 62 then
                damage.damage.status = "proof"
            end
        end
        if pb.damage.num and pb.damage.num > 0 then
            damage.damage.num = pb.damage.num
        end
        dest = damage
    end
    if pb.ap and pb.ap.valid == true then
        dest = {
            direct = pb.ap.direct,
            pos = pb.ap.pos,
            ap = pb.ap.ap,
            effect = pb.ap.effect,
        }
    end

    table.insert(dests, dest)
end


local function BRPTTBattleAction(actions, pb)
    local action = {
        type = "battle",
        source = {},
        dest = {}
    }
    BRPTTBattleActionSource(action.source, pb.source)
    for k,v in ipairs(pb.dests) do
        BRPTTBattleActionDests(action.dest, v)
    end
    table.insert(actions, action)
end


function BattleReportConvertPbToTab(data)
    local pb = battlereport_pb.BattleReport()
    pb:ParseFromString(data)
    local brt = {
        meta = {
            attack = {
                name = nil,
                generals = {},
                pet = {}
            },
            defense = {
                name = nil,
                generals = {},
                pet = {}
            },
        },
        battle = {
            init = {
                attack = {},
                defense = {},
            },
            action = {}
        },
        result=pb.result,
        type='battle'
    }

    BRPTTMetaMetaPosition(brt.meta.attack, brt.battle.init.attack, pb.a)
    BRPTTMetaMetaPosition(brt.meta.defense, brt.battle.init.defense, pb.b)

    for k,v in ipairs(pb.actions) do
        BRPTTBattleAction(brt.battle.action, v)
    end
    return brt
end





