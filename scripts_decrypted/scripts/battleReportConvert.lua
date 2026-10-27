--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-7-24
-- Time: 上午9:58
-- To change this template use File | Settings | File Templates.
--



local GeneralConfig = gamedata.config.general
local animationConfig = gamedata.config.generalanimation
local skillConfig = gamedata.config.skill
local combskillConfig = gamedata.config.combskill
local skillanimationConfig = gamedata.config.skillanimation
local breakskillConfig =  gamedata.config.breakskill
local petConfig =  gamedata.config.pet3_attr

local posconfig = {
    [2] = 1,
    [8] = 2,
    [10] = 3,
    [4] = 4,
    [12] = 5,
    [6] = 6,
    [14] = 7
}
local posorderconfig = {
    [1] = 1,
    [2] = 1,
    [3] = 2,
    [4] = 2,
    [5] = 3,
    [6] = 3,
    [7] = 3,
    [8] = 1,
    [9] = 1,
    [10] = 2,
    [11] = 2,
    [12] = 3,
    [13] = 3,
    [14] = 4
}

local ext = {
    damagetotal = {
        atk = 0,
        def = 0,
    },
}

local injuredAudioTimes = {}

math.randomseed(os.time())
math.random()

local function generalInfoData(generalInfo,v)
    local data = {
        id = generalInfo.id,
        name = generalInfo.name,
        quality = GeneralConfig[tostring(generalInfo.cid)].quality,
        level = generalInfo.level1,
        level2 = generalInfo.level2,
        level3 = generalInfo.level3 or 0,
        ap = generalInfo.ap,
        cid = generalInfo.cid,
        hp = generalInfo.hp,
        hp2 = generalInfo.hp2,
        boss = v.boss,
        animation = animationConfig[tostring(GeneralConfig[tostring(generalInfo.cid)].animationid)],
        combskillid= GeneralConfig[tostring(generalInfo.cid)].combskillid,

        cover_d = generalInfo.cover_d or 0,
        cover_d2 = generalInfo.cover_d2 or 0,
        cover_p = generalInfo.cover_p or 0,
        cover_l = generalInfo.cover_l or 0,

        w_l = generalInfo.w_l or 0,
        w_c = generalInfo.w_c or 0,
        a_cid = generalInfo.a_cid or 0,
        a_level = generalInfo.a_level or 0,
        scope = generalInfo.scope or 0,
    }

    if type(generalInfo.defaultskill) == "table" and next(generalInfo.defaultskill) then
        data.skillid = generalInfo.defaultskill.id
    end

    return data
end

local function petInfoData(petInfo,v)
    local data = {
        id = petInfo.id,
        name = petConfig[tostring(petInfo.cid)][tostring(petInfo.level2)].name,
        icon = petConfig[tostring(petInfo.cid)][tostring(petInfo.level2)].icon,
        image = petConfig[tostring(petInfo.cid)][tostring(petInfo.level2)].image,
        quality = petConfig[tostring(petInfo.cid)][tostring(petInfo.level2)].quality,
        ap = petInfo.ap,
        cid = petInfo.cid,
        level = petInfo.level1,
        level2 = petInfo.level2,
        animation = animationConfig[tostring(petConfig[tostring(petInfo.cid)][tostring(petInfo.level2)].animationid)],
    }

    return data
end
local function generalSlotInfoData(general,pet,k,id,v)
    local geenralinfo = {}
    if k==0 or k=="0" then
        geenralinfo = petInfoData(pet[tostring(id)],v)
    else
        geenralinfo = generalInfoData(general[tostring(id)],v)
    end
    return geenralinfo
end

local function makeGeneralSlotInfo(general,pet,init)
    local generalSlotInfo ={}
    for k,v in pairs(init) do
        generalSlotInfo[k] = generalSlotInfoData(general,pet,k,v.id,v)
    end

    return generalSlotInfo
end

local function isneedInjureAudio(time)
    local need = true
    for k,v in ipairs(injuredAudioTimes) do
        if math.abs(time - v) <= 0.1 then
            need = false
            break
        end
    end

    if need then injuredAudioTimes[#injuredAudioTimes+1] = time end
    return need
end

local function makeDamageEffect(data,generalInfo,damagejson,status)
    print(generalInfo.animation.name .. "_time.json")
    local path = CCFileUtils:sharedFileUtils():fullPathForFilename(generalInfo.animation.name .. "/" .. generalInfo.animation.name .. "_time.json")

    local timejson = LoadJsonFileToTable(path)

    local GeneralEffective = {
        damage = data.damage,
        damage2 = data.damage2,
        damage3 = data.damage3,
        status = status,
        forbear = data.forbear or 0,
    }

    if string.find(damagejson,",") then
        local i = string.find(damagejson,",")
        local j = string.len(damagejson)
        GeneralEffective.damagedelay=tonumber(string.sub(damagejson,1,i-1))
        GeneralEffective.shake =string.sub(damagejson,i+1,j)
    else
        GeneralEffective.damagedelay=tonumber(damagejson)
    end

    GeneralEffective.isneedaudio = isneedInjureAudio(GeneralEffective.damagedelay)

    local typeConfig = {
        losebloodnormal = "loseblood_normal",
        losebloodcritical = "loseblood_critical",
        loseblooddot = "dot",
        loseblooddot2 = "dot2",
        loseblooddodge = "dodge",
        losebloodparry = math.random(1,2) == 1 and "parry" or "parry",
        addbloodnormal = "addblood_normal",
        addbloodcritical = "addblood_critical",
        addbloodpassive = "manxue",
        losebloodcut = "loseblood_cut",
        losebloodsacrifice = "loseblood_sacrifice",
        losebloodfight = "loseblood_fight",
        losebloodproof = "loseblood_proof",
    }

    local forbear_typeConfig = {
        normal = 1,
        critical = 1,
        cut = 1,
        fight = 1,
    }

    local type = "normal"

    if string.find(data.status,"critical") then
        type = "critical"
    end

    if string.find(data.status,"parry") then
        type = "parry"
    end

    if string.find(data.status,"dot") then
        type = "dot"
    end

    if string.find(data.status,"dot2") then
        type = "dot2"
    end

    if string.find(data.status,"passive") then
        type = "passive"
    end

    if string.find(data.status,"cut") then
        type = "cut"
    end

    if string.find(data.status,"sacrifice") then
        type = "sacrifice"
    end

    if string.find(data.status,"fight") then
        type = "fight"
    end

    if string.find(data.status,"proof") then
        type = "proof"
    end

    if string.find(data.status,"dodge") then
        type = "dodge"
    end

    if data.damage >= 0 then
        local forbear = ""
        if data.forbear and data.forbear > 0 and forbear_typeConfig[type] then
            forbear = "_kezhi"
        elseif data.forbear and data.forbear < 0 and forbear_typeConfig[type] then
            forbear = "_beike"
        end    

        GeneralEffective.ccb = typeConfig["loseblood"..type]..forbear
        --GeneralEffective.action = "injured"
        --GeneralEffective.audio = generalInfo.animation.injureaudio
        GeneralEffective.delay = timejson.injured.delay
        GeneralEffective.actiondelay = timejson.injured.actiondelay
    else
        GeneralEffective.ccb = typeConfig["addblood"..type]
    end

--    if string.find(data.status,"dead") then
--        GeneralEffective.action = "death"
--        GeneralEffective.audio = generalInfo.animation.deadaudio
--    end

    return  GeneralEffective
end

local bufferconst = {
    atk_promote = true,
    def_promote = true,    
    atk_weaken = true,
    def_weaken = true,
    seal_break = true,

    critical_promote = true,
    def_promote = true,
    dodge_promote = true,
    atk_weaken = true,
    def_weaken = true,
    dodge_weaken = true,
    ray_promote = true,
    seal_break = true,
    damage_promote = true,
    chaos_promote = true,
    devil_promote = true,
    devil_weaken = true,

    xiyin_promote = true,
    speed_promote = true,
    speed_weaken = true,
    zengshang_promote = true,

    hunxiao_weaken = true,
}

local function makeBufferEffect(buffer)
    local name = buffer.attr.."_"..buffer.status
    local type = "normal"
    if string.find(name,"deadnum") then
        type = "zhujue"
    elseif bufferconst[name] then
        type = "const"
    end

    return{name = name,type = type,num = buffer.attr,switch = buffer.switch}
end

local function ramdomcritical(total,critical)

    local criT = {}
    if critical <= 0 then return criT end

    local posT = {}
    for i=1,total do
        posT[i] = i
    end

    for i = 1, critical do
        local pos = math.random(1,total+1-i)
        criT[posT[pos]] = true
        for j=pos, total-i do
            posT[j] = posT[j+1]
        end
    end

    return criT
end

local function makeDestGeneralEffective(destaction,generalInfo,skilljson,ccbindex,skillanimation,index,sourcegeneralinfo,persent,fixedDamage)
    local animation = {
        pos = tostring(destaction.pos),
        postype = destaction.direct and "atk" or "def",
        animation = {
            damage = {},
            status = {},
        }
    }

    local damagejson = skilljson and skilljson.damage[tostring(ccbindex)] or nil
    local ccbtype = skilljson and skilljson.ccbtype or nil

    if destaction.damage and next(destaction.damage) and damagejson then

        local damagecount = table.getTableLength(damagejson.damagedelay)
        if fixedDamage and next(fixedDamage)  then
            print("fixedDamage")
            --伤害为0时 固定伤害不执行
            if destaction.damage.damage and destaction.damage.damage > 0 then
                local total_fixedDamage = 0
                for k,v in pairs(fixedDamage) do
                    total_fixedDamage = total_fixedDamage + v
                end
                destaction.damage.damage = destaction.damage.damage - total_fixedDamage
                damagecount = damagecount - table.getTableLength(fixedDamage)
            else
                fixedDamage = nil
            end
        end


        if not destaction.damage.num then
            if damagecount == 1 then
                destaction.damage.num = string.find(destaction.damage.status,"critical") and 1 or 0
            else
                destaction.damage.num = 0
            end
        else
            destaction.damage.num = math.min(damagecount,destaction.damage.num)
        end

        local normaldamage =  math.floor(math.abs(destaction.damage.damage)/(damagecount+0.5*destaction.damage.num))
        local criticaldamage = math.floor(normaldamage*1.5)

        if destaction.damage.damage<0 then
            normaldamage = -1*normaldamage
            criticaldamage = -1*criticaldamage
        end

        local covernormal,covercritical = 0,0
        if destaction.damage.damage2 and destaction.damage.damage2>0 then
            covernormal =  math.floor(destaction.damage.damage2/(damagecount+0.5*destaction.damage.num))
            covercritical = math.floor(covernormal*1.5)
        end


        local sum = 0
        local sumcover = 0
        local criticalT = ramdomcritical(damagecount,destaction.damage.num)

        for i=1, damagecount do
            local d_status = ""
            local d_damage = 0
            local c_damage = 0
            local d_forbear = destaction.damage.forbear or 0


            if string.find(destaction.damage.status,"critical") and not criticalT[i] then
                if string.find(destaction.damage.status,"cut") or 
                    string.find(destaction.damage.status,"fight") or 
                    string.find(destaction.damage.status,"proof") then
                    d_status = destaction.damage.status
                else
                    d_status = "normal"
                end
            else
                d_status = destaction.damage.status
            end

            if i == damagecount then
                d_damage = destaction.damage.damage - sum
                c_damage = (destaction.damage.damage2 or 0) - sumcover
            else
                if  criticalT[i] then
--                    if persent and persent[tostring(i)] then
--                        d_damage = math.floor(destaction.damage.damage*persent[tostring(i)]*1.5/100)
--                    else
                        d_damage = criticaldamage
                        c_damage = covercritical
--                    end

                else
--                    if persent and persent[tostring(i)] then
--                        d_damage = math.floor(destaction.damage.damage*persent[tostring(i)]/100)
--                    else
                        d_damage = normaldamage
                        c_damage = covernormal
--                    end
                end
            end

            local damage3 = 0
            if destaction.damage.damage3 and destaction.damage.damage3>0 then
                damage3 = math.ceil(destaction.damage.damage3/damagecount)
            end 
            table.insert(animation.animation.damage, makeDamageEffect({status = d_status, damage = d_damage,damage2 = c_damage,damage3 = damage3,forbear = d_forbear},generalInfo,damagejson.damagedelay[tostring(i)],destaction.status))

            sum = sum + d_damage
            sumcover = sumcover + c_damage
        end


        if fixedDamage and next(fixedDamage) then
            for k,v in pairs(fixedDamage) do
                local _index = tonumber(k)
                table.insert(animation.animation.damage,_index,makeDamageEffect({status = "normal", damage = v,damage2 = 0,forbear = d_forbear},generalInfo,damagejson.damagedelay[tostring(_index)],destaction.status))
            end
            local total_fixedDamage = 0
            for k,v in pairs(fixedDamage) do
                total_fixedDamage = total_fixedDamage + v
            end

            ext.damagetotal[animation.postype] = ext.damagetotal[animation.postype] + destaction.damage.damage + total_fixedDamage
            generalInfo.hp = math.min(math.max(generalInfo.hp-destaction.damage.damage - total_fixedDamage,0),generalInfo.hp2)
            generalInfo.cover_d = math.min(math.max(generalInfo.cover_d-(destaction.damage.damage2 or 0),0),generalInfo.cover_d2)

        else
            ext.damagetotal[animation.postype] = ext.damagetotal[animation.postype] + destaction.damage.damage
            generalInfo.hp = math.min(math.max(generalInfo.hp-destaction.damage.damage,0),generalInfo.hp2)
            generalInfo.cover_d = math.min(math.max(generalInfo.cover_d-(destaction.damage.damage2 or 0),0),generalInfo.cover_d2)
        end

    end
------------------------  test  ------------------------------------

    if destaction.status and next(destaction.status) then
        animation.animation.status = destaction.status
    end

    if ccbtype and destaction.damage and next(destaction.damage) and damagejson then
        if string.find(ccbtype,"normal") then
            animation.animation.ccb = {delay = damagejson.ccbdelay, name = skillanimation.name.."02", dir = skillanimation.name}
        elseif string.find(ccbtype,"random") then
            local num = tonumber(string.sub(ccbtype,8,string.len(ccbtype)))
            local select = math.random(1,num)
            animation.animation.ccb = {delay = damagejson.ccbdelay, name = skillanimation.name.."02_"..select, dir = skillanimation.name }
        elseif string.find(ccbtype,"order") then
            animation.animation.ccb = {delay = damagejson.ccbdelay, name = skillanimation.name.."02_"..index, dir = skillanimation.name }
        elseif string.find(ccbtype,"posorder") then
            animation.animation.ccb = {delay = damagejson.ccbdelay, name = skillanimation.name.."02_"..posorderconfig[destaction.pos], dir = skillanimation.name }
        elseif string.find(ccbtype,"zhujue") then

            if sourcegeneralinfo.cid>=10101 and sourcegeneralinfo.cid<=10115 then
                local indx = math.mod((sourcegeneralinfo.cid-10100),5)
                print("zhujue   dest ", sourcegeneralinfo.cid,indx)
                local skillname = skillanimation.name ..((skillanimation.name=="mowangchongji"  or skillanimation.name=="mowangyiji") and "1" or "" )
                if indx == 0 then indx = 5 end
                animation.animation.ccb = {delay = damagejson.ccbdelay, name = skillname.."_"..indx, dir = skillname }
            elseif sourcegeneralinfo.cid>=10997 and sourcegeneralinfo.cid<=10999 then
                local skillname = skillanimation.name ..((skillanimation.name=="mowangchongji"  or skillanimation.name=="mowangyiji") and "1" or "" )
                animation.animation.ccb = {delay = damagejson.ccbdelay, name = skillname.."_6", dir = skillname }
            elseif sourcegeneralinfo.cid>=162001 and sourcegeneralinfo.cid<=162003 then
                local skillname = skillanimation.name ..((skillanimation.name=="mowangchongji"  or skillanimation.name=="mowangyiji") and "1" or "" )
                animation.animation.ccb = {delay = damagejson.ccbdelay, name = skillname.."_7", dir = skillname }
            else
                animation.animation.ccb = {delay = damagejson.ccbdelay, name = skillanimation.name.."02", dir = skillanimation.name }
            end
        end
    end

    return animation
end


function  makeSourceEffect(animation,action,sourceslotInfo,type,skillanimation,json)
    for k,v in ipairs(action.source.pos) do
        animation.sourceAnimation[k]={
            pos = tostring(v),
            postype = action.source.direct and "atk" or "def",
            animation = {action = json.scrouceaction or type}
        }
        if v==0 or v=="0" then
            animation.sourceccbmodule= {name = skillanimation.name }
            return
        end     --式神排除
        if type == "breakskill" and not json.scrouceaction then  animation.sourceAnimation[k].animation.action = "" end
        if type == "attack" then
            animation.sourceAnimation[k].animation.audio = sourceslotInfo[tostring(v)].animation.normalaudio
            animation.sourceAnimation[k].animation.actiondelay = json.attack.actiondelay
        else
            animation.sourceAnimation[k].animation.audio = sourceslotInfo[tostring(v)].animation.specialaudio


            if json.scrouce == "type" then
                local key_ex = "_1"
                if  tonumber(v) > battleScene.slotNum then
                    key_ex = "_2"
                end
                animation.sourceAnimation[k].animation.ccb = { name = skillanimation.name.."01"..key_ex, dir = skillanimation.name}
            elseif json.scrouce == "none" or json.scrouce == "special" then
                animation.sourceAnimation[k].animation.hideeffect = true

            elseif json.scrouce == "zhujue" then
                if action.source.passive then
                    animation.sourceAnimation[k].animation.ccb = {name = "baozou", dir = "zhujuebeidong" }
                else
                    animation.sourceAnimation[k].animation.hideeffect = true
                end
                animation.sourceccbmodule= {name = "zhujue"}
                animation.sourceAnimation[k].animation.action = "skill01_01"
                local path1 = CCFileUtils:sharedFileUtils():fullPathForFilename(sourceslotInfo[tostring(v)].animation.name .. "/" .. sourceslotInfo[tostring(v)].animation.name .. "_time.json")
                local sourcejson = LoadJsonFileToTable(path1)
                animation.sourceAnimation[k].animation.actiondelay1 =  sourcejson.skill01.actiondelay01
                animation.sourceAnimation[k].animation.actiondelay2 =  sourcejson.skill01.actiondelay02
                animation.sourceAnimation[k].animation.actiondelay = animation.screenAnimation.actiontime
            elseif json.scrouce == "zhujue2" then
                animation.sourceAnimation[k].animation.ccb = { name = skillanimation.name.."01", dir = skillanimation.name }
                animation.sourceAnimation[k].animation.action = "skill02"
                local path1 = CCFileUtils:sharedFileUtils():fullPathForFilename(sourceslotInfo[tostring(v)].animation.name .. "/" .. sourceslotInfo[tostring(v)].animation.name .. "_time.json")
                local sourcejson = LoadJsonFileToTable(path1)
                animation.sourceAnimation[k].animation.actiondelay = sourcejson.skill02.actiondelay


            else
                animation.sourceAnimation[k].animation.ccb = { name = skillanimation.name.."01", dir = skillanimation.name}
            end
            if not animation.sourceAnimation[k].animation.ccb then
                animation.sourceAnimation[k].animation.ccb = {}
            end
            animation.sourceAnimation[k].animation.ccb.skillname = skillanimation.name

            if not animation.sourceAnimation[k].animation.actiondelay then
                if type == "skill" or type == "breakskill" then
                    local path1 = CCFileUtils:sharedFileUtils():fullPathForFilename(sourceslotInfo[tostring(v)].animation.name .. "/" .. sourceslotInfo[tostring(v)].animation.name .. "_time.json")
                    local sourcejson = LoadJsonFileToTable(path1)
                    if sourcejson.skill and sourcejson.skill.actiondelay then
                        animation.sourceAnimation[k].animation.actiondelay = sourcejson.skill.actiondelay
                    else
                        animation.sourceAnimation[k].animation.actiondelay = json.times.delay1
                    end
                else
                    animation.sourceAnimation[k].animation.actiondelay = json.times.delay1
                end
            end

        end
    end

    if type ~= "attack" and json and string.find(json.scrouce,"special") then
        animation.sourceccbmodule= {name = skillanimation.name}
    end


    if json.scrouce == "specialwithblood" then

        local newdest = {}
        for k,v in ipairs(action.source.pos) do
            animation.sourceAnimation[k].animation.specialccb = animation.sourceAnimation[k].animation.ccb
            animation.sourceAnimation[k].animation.ccb = nil
            for kk,vv in ipairs(action.dest) do
                if vv.direct == action.source.direct and vv.pos == v and vv.damage and next(vv.damage) then
                    animation.sourceAnimation[k].animation.damage = vv.damage.damage
                    local generalInfo = sourceslotInfo[tostring(v)]
                    generalInfo.hp = math.min(math.max(generalInfo.hp-vv.damage.damage,0),generalInfo.hp2)
                else
                    table.insert(newdest,vv)
                end
            end
        end
        action.dest = newdest
    end

end

function  makeDestEffect(animation,action,atkSlotInfo,defSlotInfo,skillanimation,skilljson)
    if skilljson and (skilljson.type == "tb" or skilljson.type == "tborder") then
        local sort = function(a,b)
            local numbera = a.pos <= 7 and a.pos or a.pos-7
            local numberb = b.pos <= 7 and b.pos or b.pos-7
            return numbera<numberb
        end
        table.sort(action.dest,sort)
    end
    local  sourcegeneralinfo
    if action.source and next(action.source) then
        local sourceslotInfo =  action.source.direct and atkSlotInfo or defSlotInfo
        sourcegeneralinfo = sourceslotInfo[tostring(action.source.pos[1])]
    end

    local handledap = {}
    local handlebuffer = {}

    local index = "1"
    if skilljson and skilljson.type == "randomsame" then
        index = tostring(math.random(1,table.getTableLength(skilljson.damage)))
    end

    local idx = 0
    for k,v in ipairs(action.dest) do
        local slotinfo = v.direct and atkSlotInfo or defSlotInfo
        --print(v.direct,v.pos)
        if v.damage and next(v.damage) then
            idx = idx +1
            if skilljson  then

                if skilljson.type == "lr" then
                    index = tonumber(v.pos) <= 7 and "1" or "2"
                elseif skilljson.type == "tb" or skilljson.type == "tborder" then
                    index = tostring(idx)
                elseif skilljson.type == "order" or skilljson.type == "zhujue" then
                    index = tostring(idx)
                elseif skilljson.type == "pos" then
                    index = tostring(posconfig[v.pos])
                elseif skilljson.type == "posorder" then
                    index = tostring(posorderconfig[v.pos])
                elseif skilljson.type == "random" then
                    index = math.random(1,table.getTableLength(skilljson.damage))
                elseif skilljson.type == "same" or skilljson.type == "single" then
                    index = "1"
                elseif skilljson.type == "data" then
                    index = skilljson.typedata[tostring(v.pos)] or "1"
                end
                local persent = skilljson.damagePercent and  skilljson.damagePercent[tostring(index)]
                local fixedDamage = skilljson.fixedDamage and skilljson.fixedDamage[tostring(index)]

                table.insert(animation.destAnimation,makeDestGeneralEffective(v,slotinfo[tostring(v.pos)],skilljson,index,skillanimation,idx,sourcegeneralinfo,persent,fixedDamage))
            else
                table.insert(animation.destAnimation,makeDestGeneralEffective(v,slotinfo[tostring(v.pos)],{damage={["1"]={ccbdelay = 0,damagedelay = {["1"] = "0",}}}},"1"))
            end
        elseif v.status then
            table.insert(animation.destAnimation,makeDestGeneralEffective(v,slotinfo[tostring(v.pos)]))
        end

        if v.buffer then
            local generalindex = (v.direct and "atk" or "def")..v.pos
            handlebuffer[generalindex]  = handlebuffer[generalindex] or 1

            if not animation.buffers[handlebuffer[generalindex]] then
                animation.buffers[handlebuffer[generalindex]] = {}
            end
 
            table.insert(animation.buffers[handlebuffer[generalindex]],{
                pos = tostring(v.pos),
                postype = v.direct and "atk" or "def",
                buffer = makeBufferEffect(v.buffer)
            })
            handlebuffer[generalindex] = handlebuffer[generalindex] +1
        end

        if v.ap then
            if handledap[(v.direct and "atk" or "def")..v.pos] then
                for kk,vv in ipairs(animation.aps) do
                    if tostring(v.pos) == vv.pos 
                        and (v.direct and "atk" or "def") == vv.postype 
                        and v.ap ~= vv.ap then
                        vv.effect = false
                    end
                end
            end

            table.insert(animation.aps,{
                pos = tostring(v.pos),
                postype = v.direct and "atk" or "def",
                ap = v.ap,
                effect= v.effect
            })
            handledap[(v.direct and "atk" or "def")..v.pos] = true
--            if v.effect then
--                table.insert(animation.aps_effect,{
--                    pos = tostring(v.pos),
--                    postype = v.direct and "atk" or "def",
--                    ap = v.ap,
--                    effect= v.effect
--                })
--
--            else
--
--            end
            slotinfo[tostring(v.pos)].ap = v.ap
        end
    end

    if skilljson and string.find(skilljson.ccbtype,"special") then
        animation.destccbmodule= {name = skillanimation.name, type = skilljson.ccbtype,index = index}
    end

    if skilljson and skilljson.begineffect then
        local beginEffectArray = ui.Split(skilljson.begineffect, ",")
        local name = beginEffectArray[1]

        -- beginEffectArray.shift()

        -- 在全屏特效开始之后一段时间消失
        if #beginEffectArray > 1 then
            animation.destbeginemodule = { name = name, params = beginEffectArray }
        else
            animation.destbeginemodule = { name = name }
        end
    end

    if skilljson and skilljson.endffect then
        local endEffectArray = ui.Split(skilljson.endffect, ",")
        local name = endEffectArray[1]

        -- endEffectArray.shift()

        -- 比全屏特效结束早出现
        if #endEffectArray > 1 then
            local path = CCFileUtils:sharedFileUtils():fullPathForFilename(skillanimation.name ..((skillanimation.name=="mowangchongji"  or skillanimation.name=="mowangyiji") and "1" or "" ).. "/" .. skillanimation.name .. ".json")
            local _skilljson = LoadJsonFileToTable(path)
            endEffectArray[2] = tostring(tonumber(endEffectArray[2]) + _skilljson.times.delay2)
            animation.destendmodule = { name = name, params = endEffectArray }
        else 
            animation.destendmodule = { name = name }
        end
    end

end

function makeScreenEffect(json,skill,skillanimation,action,sourceslotInfo,type)

    local effect = {
        shake = {}
    }
    for k,v in pairs(json.shake) do
        local i = string.find(v,",")
        local j = string.len(v)

        local data = {
            delay=tonumber(string.sub(v,1,i-1)),
            name =string.sub(v,i+1,j)
        }

        if json.shakeparam and json.shakeparam[k] then
            if json.shakeparam[k] == "bydirect" then
                data.name = string.sub(v,i+1,j)..(action.source.direct and "_atk" or "_def") 
            end
        end

        table.insert(effect.shake,data)
    end

    effect.audio =  skillanimation.specialaudio

    local damagedestnum = 0
    for k,v in ipairs(action.dest) do
        if v.damage and next(v.damage) then
            damagedestnum = damagedestnum+1
        end
    end
    damagedestnum = math.min(damagedestnum,7)
    if json.dest.type == "order" or json.dest.type == "tborder" then
        effect.actiontime = json.times.delay2 + json.dest.damage[tostring(damagedestnum)].ccbdelay + json.dest.damage[tostring(damagedestnum)].ccbtime
    elseif json.dest.type == "zhujue" then
        effect.actiontime = json.times.delay2 + json.dest.damage[tostring(damagedestnum)].ccbdelay + json.dest.ccbtime
    else
        effect.actiontime = json.times.delay1
    end

    effect.destdelay = json.times.delay2
    print("skill.quality",skill.quality)
    if type ~= "breakskill"  and action.source.pos[1] ~= 0 then   --and skill.quality >2
        effect.common={ccbname = "common".."_"..type,skillname = skillanimation.name,general = {}, generalext = {},pos = {},direct = action.source.direct,skilltype = "normal" }

        for k,v in ipairs(action.source.pos) do
            effect.common.general[sourceslotInfo[tostring(v)].cid] = true
            table.insert(effect.common.pos,tostring(v))
        end

        if type == "combskill" then
            effect.common.skilltype = "comb"
            for i=1,3 do
                if skill["cid"..i] and skill["cid"..i] ~= 0 and not effect.common.general[skill["cid"..i]] then
                    table.insert(effect.common.generalext,animationConfig[tostring(GeneralConfig[tostring(skill["cid"..i])].animationid)].name)
                end
            end
        end


--        if type == "skill" then
--            for k,v in ipairs(action.source.pos) do
--                table.insert(effect.common.general,sourceslotInfo[tostring(v)].animation.name)
--                table.insert(effect.common.pos,tostring(v))
--            end
--        elseif type == "combskill" then
--            for i=1,3 do
--                if skill["cid"..i] and skill["cid"..i] ~= 0 then
--                    table.insert(effect.common.general,animationConfig[tostring(GeneralConfig[tostring(skill["cid"..i])].animationid)].name)
--                end
--            end
--        end
    end

    if json.screen then
        effect.effect={skillname = skillanimation.name,direct = action.source.direct }
    end

    if json.skill2 and json.skill2.spine then
        effect.skill2 = {}
        effect.skill2.spine = json.skill2.spine
        effect.skill2.fixpos = json.skill2.fixpos or false
        effect.skill2.fixscale = json.skill2.fixscale or 1
        effect.skill2.fixtime = json.skill2.fixtime or 0
    end

    return effect
end

function makeNormalAttack(animation,action,atkSlotInfo,defSlotInfo)
    local sourceslotInfo =  action.source.direct and atkSlotInfo or defSlotInfo
    local sourcegeneralinfo = sourceslotInfo[tostring(action.source.pos[1])]
    print(sourcegeneralinfo.animation.name .. "_time.json","makeNormalAttack source")
    local path1 = CCFileUtils:sharedFileUtils():fullPathForFilename(sourcegeneralinfo.animation.name .. "/" .. sourcegeneralinfo.animation.name .. "_time.json")

    local sourcejson = LoadJsonFileToTable(path1)

    local destslotInfo =  action.dest[1].direct and atkSlotInfo or defSlotInfo
    local destgeneralinfo = destslotInfo[tostring(action.dest[1].pos)]
    print(destgeneralinfo.animation.name .. "_time.json","makeNormalAttack dest")
    local path2 = CCFileUtils:sharedFileUtils():fullPathForFilename(destgeneralinfo.animation.name .. "/" .. destgeneralinfo.animation.name .. "_time.json")

    local destjson = LoadJsonFileToTable(path2)

    animation.screenAnimation.actiontime =  sourcejson.attack.delay + destjson.injured.actiondelay +0.3
    animation.screenAnimation.destdelay =  sourcejson.attack.delay

    makeSourceEffect(animation,action,sourceslotInfo,"attack",nil,sourcejson)
    makeDestEffect(animation,action,atkSlotInfo,defSlotInfo)

end

function getNewCombSkillAnimationId(slotInfo, skillConifg, cheer)
    if skillConifg.animationid_1 then
        if checkCombSkillByCid(slotInfo, skillConifg, cheer, 3) then
            return skillConifg.animationid_3
        elseif checkCombSkillByCid(slotInfo, skillConifg, cheer, 2) then
            return skillConifg.animationid_2
        elseif checkCombSkillByCid(slotInfo, skillConifg, cheer, 1) then
            return skillConifg.animationid_1
        else
            return skillConifg.animationid
        end
    else
        return skillConifg.animationid
    end
end

function checkCombSkillByCid(slotInfo, skillConifg, cheer, index)
    local _count = 0

    for i = 1, 3 do
        if skillConifg["cid"..i.."_"..index] ~= "" then
            _count = _count + 1
        end
    end

    if _count > 0 then
        for i = 1, 3 do
            local _temp1 = ui.Split(skillConifg["cid"..i.."_"..index], ";")
            local _temp2 = ui.Split(_temp1[1], ",")

            for k,v in pairs(slotInfo) do
                for ii,vv in ipairs(_temp2) do
                    print(vv, v.cid)
                    if tonumber(vv) == v.cid then
                        _count = _count - 1
                    end
                end
            end

            if cheer and next(cheer) then
                for ii,v in ipairs(cheer) do
                    for iii,vv in ipairs(_temp2) do
                        if tonumber(vv) == v then
                            _count = _count - 1
                        end
                    end
                end
            end
        end

        if _count <= 0 then
            return true
        else
            return false
        end
    else
        return false
    end
end

function makecombSkill(animation,action,atkSlotInfo,defSlotInfo,attackCheer,defenseCheer)
    local sourceslotInfo = action.source.direct and atkSlotInfo or defSlotInfo
    local _cheer = action.source.direct and attackCheer or defenseCheer

    print(action.source.skillid)
    local skill = combskillConfig[tostring(action.source.skillid)]
    local _animationid = getNewCombSkillAnimationId(sourceslotInfo, skill, _cheer)
    local skillanimation =  skillanimationConfig[tostring(_animationid)]
    -- local skillanimation =  skillanimationConfig[tostring(skill.animationid)]
    print(skillanimation.name .. ".json","makecombSkill")
    local path = CCFileUtils:sharedFileUtils():fullPathForFilename(skillanimation.name ..((skillanimation.name=="mowangchongji"  or skillanimation.name=="mowangyiji") and "1" or "" ).. "/" .. skillanimation.name .. ".json")
    local skilljson = LoadJsonFileToTable(path)

    animation.screenAnimation = makeScreenEffect(skilljson,skill,skillanimation,action,sourceslotInfo,"combskill")

    makeSourceEffect(animation,action,sourceslotInfo,"combskill",skillanimation,skilljson)
    makeDestEffect(animation,action,atkSlotInfo,defSlotInfo,skillanimation,skilljson.dest)
end

function makeSkill(animation,action,atkSlotInfo,defSlotInfo,skilltype)
    local sourceslotInfo =  action.source.direct and atkSlotInfo or defSlotInfo

    local skill =  skillConfig[tostring(action.source.skillid)] or combskillConfig[tostring(action.source.skillid)]
    local skillanimation =  skillanimationConfig[tostring(skill.animationid)]
    print(skillanimation.name .. ".json","makeSkill")
    local path = CCFileUtils:sharedFileUtils():fullPathForFilename(skillanimation.name..((skillanimation.name=="mowangchongji"  or skillanimation.name=="mowangyiji") and "1" or "" ) .. "/" .. skillanimation.name .. ".json")
    local skilljson = LoadJsonFileToTable(path)

    animation.screenAnimation = makeScreenEffect(skilljson,skill,skillanimation,action,sourceslotInfo,"skill")

    makeSourceEffect(animation,action,sourceslotInfo,"skill",skillanimation,skilljson)
    makeDestEffect(animation,action,atkSlotInfo,defSlotInfo,skillanimation,skilljson.dest)
end

function makebreakSkill(animation,action,atkSlotInfo,defSlotInfo)
    local sourceslotInfo =  action.source.direct and atkSlotInfo or defSlotInfo

    local skill = breakskillConfig[tostring(action.source.skillid)] or combskillConfig[tostring(action.source.skillid)]
    local skillanimation =  skillanimationConfig[tostring(skill.animationid)]
    print(skillanimation.name .. ".json","makebreakSkill")
    local path = CCFileUtils:sharedFileUtils():fullPathForFilename(skillanimation.name..((skillanimation.name=="mowangchongji"  or skillanimation.name=="mowangyiji") and "1" or "" ) .. "/" .. skillanimation.name .. ".json")
    local skilljson = LoadJsonFileToTable(path)

    animation.screenAnimation = makeScreenEffect(skilljson,skill,skillanimation,action,sourceslotInfo,"breakskill")

    makeSourceEffect(animation,action,sourceslotInfo,"breakskill",skillanimation,skilljson)
    makeDestEffect(animation,action,atkSlotInfo,defSlotInfo,skillanimation,skilljson.dest)
end

function makeSkillEffect(animation,action,atkSlotInfo,defSlotInfo)
    local skill = skillConfig[tostring(action.source.skillid)] or combskillConfig[tostring(action.source.skillid)] or breakskillConfig[tostring(action.source.skillid)]
    local skillanimation =  skillanimationConfig[tostring(skill.animationid)]
    print(skillanimation.name .. ".json","makeSkillEffect")
    local path = CCFileUtils:sharedFileUtils():fullPathForFilename(skillanimation.name..((skillanimation.name=="mowangchongji"  or skillanimation.name=="mowangyiji") and "1" or "" ) .. "/" .. skillanimation.name .. ".json")
    local skilljson = LoadJsonFileToTable(path)

    if skilljson.skilleffect and skilljson.skilleffect == "hpresume" then
        print("hpresume")
        animation.type2 = "destonly"
        animation.screenAnimation.actiontime =  0.7
        animation.screenAnimation.destdelay =  0
        makeDestEffect(animation,action,atkSlotInfo,defSlotInfo)
    else
        local sourceslotInfo =  action.source.direct and atkSlotInfo or defSlotInfo
        animation.screenAnimation = makeScreenEffect(skilljson,skill,skillanimation,action,sourceslotInfo,"breakskill")
        makeSourceEffect(animation,action,sourceslotInfo,"breakskill",skillanimation,skilljson)
        makeDestEffect(animation,action,atkSlotInfo,defSlotInfo,skillanimation,skilljson.dest)
    end
end

local function makeRoundAction(round)
    ext.endinfo.round = round
    return {type = "roundbegin",round = round}
end

local function makeBattleAction(action,atkSlotInfo,defSlotInfo,attackCheer,defenseCheer)
    local animation = {
        type = action.type,
        sourceAnimation = {},
        sourceccbmodule = {},
        destAnimation = {},
        destccbmodule = {},
        screenAnimation = {},
        buffers = {},
        aps = {},
        aps_effect = {},
    }

    if action.source and next(action.source) then
        animation.type2 = action.source.type
        if action.source.type == "normal" then
            makeNormalAttack(animation,action,atkSlotInfo,defSlotInfo)
        elseif action.source.type == "skill" then
            makeSkill(animation,action,atkSlotInfo,defSlotInfo)
        elseif action.source.type == "comb" then
            if #action.source.pos == 1 and action.source.pos[1] ~= 0 then
                local sourceslotInfo =  action.source.direct and atkSlotInfo or defSlotInfo
                local generalinfo = sourceslotInfo[tostring(action.source.pos[1])]
                local generalconfig = GeneralConfig[tostring(generalinfo.cid)]
                if generalconfig.combskillid == action.source.skillid then
                    makecombSkill(animation,action,atkSlotInfo,defSlotInfo,attackCheer,defenseCheer)
                elseif generalconfig.special_skill_reveal == action.source.skillid then
                    if not generalconfig.skillid or generalconfig.skillid == 0 then
                        animation.type2 = "skill"
                        makeSkill(animation,action,atkSlotInfo,defSlotInfo)
                    else
                        animation.type2 = "break"
                        makebreakSkill(animation,action,atkSlotInfo,defSlotInfo)
                    end 
                else
                    makecombSkill(animation,action,atkSlotInfo,defSlotInfo,attackCheer,defenseCheer)
                end
            else
                makecombSkill(animation,action,atkSlotInfo,defSlotInfo,attackCheer,defenseCheer)
            end
        elseif action.source.type == "break" then
            makebreakSkill(animation,action,atkSlotInfo,defSlotInfo)
        elseif action.source.type == "skilleffect" then
            makeSkillEffect(animation,action,atkSlotInfo,defSlotInfo)
        end
    elseif action.dest and next(action.dest) then
        animation.type2 = "destonly"
        if action.dest[1].damage and next(action.dest[1].damage) then
            animation.screenAnimation.actiontime =  1
        else
            animation.screenAnimation.actiontime =  0
        end
        animation.screenAnimation.destdelay =  0
        makeDestEffect(animation,action,atkSlotInfo,defSlotInfo)
    end

    return animation
end

local function makeTalkAction(action,meta)
    local animation =  {
        type = action.type,
        content = action.content,
        direct = action.direct and "left" or "right",
    }

    if action.direct then
        animation.general = action.general
    else
        animation.general = action.general
    end
    return animation
end

local function makePosAction(actions,meta,atkSlotInfo,defSlotInfo)
    local animation = {
        type = actions.type,
        changes = {},
    }

    for k,v in ipairs(actions.changes) do

        local action = {
            direct = v.direct and "atk" or "def",
            pos = v.pos,
            opt = v.opt,
        }
        if v.opt == "appear" then
            if v.direct then
                atkSlotInfo[tostring(v.pos)] = generalSlotInfoData(meta.attack.generals,meta.attack.pet,v.pos,v.general,v)
                action.general = generalSlotInfoData(meta.attack.generals,meta.attack.pet,v.pos,v.general,v)
            else
                defSlotInfo[tostring(v.pos)] = generalSlotInfoData(meta.defense.generals,meta.defense.pet,v.pos,v.general,v)
                action.general = generalSlotInfoData(meta.defense.generals,meta.defense.pet,v.pos,v.general,v)
            end
        else
            if v.direct then
                atkSlotInfo[tostring(v.pos)] = nil
            else
                defSlotInfo[tostring(v.pos)] = nil
            end
            action.general = nil
        end

        table.insert(animation.changes,action)
    end

    return animation
end

local function loadBattleConfig()
    GeneralConfig = gamedata.config.general

    for k,v in pairs(gamedata.config.boss2) do
        GeneralConfig[k] = v
    end
    for k,v in pairs(gamedata.config.personalboss_att) do
        GeneralConfig[k] = v
    end
    for k,v in pairs(gamedata.config.huodong_monster or {}) do
        GeneralConfig[k] = v
    end
    if gamedata.config.gang2_boss then
        for k,v in pairs(gamedata.config.gang2_boss) do
            GeneralConfig[k] = v
        end
    end
    if gamedata.config.apex_boss then
        for k,v in pairs(gamedata.config.apex_boss) do
            GeneralConfig[k] = v
        end
    end
    -- printT(GeneralConfig,"jkp-GeneralConfig")

    animationConfig = gamedata.config.generalanimation
    skillConfig = gamedata.config.skill
    skillanimationConfig = gamedata.config.skillanimation
    combskillConfig = gamedata.config.combskill
    breakskillConfig = gamedata.config.breakskill
    petConfig = gamedata.config.pet3_attr
end

function getBattleName(report)
    local atkname = {}
    local defname = {}
    if type(report.meta.attack.name) == "string" then
        atkname = {report.meta.attack.name}
    else
        atkname = report.meta.attack.name
    end

    if type(report.meta.defense.name) == "string" then
        defname = {report.meta.defense.name}
    else
        defname = report.meta.defense.name
    end

    local num = math.max(#atkname,#defname)
    local slots = {}
    for i=1,num do
        slots[i] = {slotnameatk = "",slotnamedef="" }
        if atkname[i] then
            for k,v in pairs(gamedata.config.lingzhentu_zhenfa) do
                local begin = string.find(atkname[i],"("..v.name..")")
                if begin then
                    print(atkname[i],begin)
                    slots[i].slotnameatk = v.name
                    if begin <= 1 then
                        atkname[i] = ""
                    else
                        atkname[i] = string.sub(atkname[i],1,begin-2)
                    end
                    break
                end
            end
        end
        if defname[i] then
            for k,v in pairs(gamedata.config.lingzhentu_zhenfa) do
                local begin = string.find(defname[i],"("..v.name..")")
                if begin then
                    print(defname[i],begin)
                    slots[i].slotnamedef = v.name
                    if begin <= 1 then
                        defname[i] = ""
                    else
                        defname[i] = string.sub(defname[i],1,begin-2)
                    end
                    break
                end
            end
        end
    end

    return atkname,defname,slots
end

function getBattleResult(report)
    return report.result
end

function getBattleInitSlotInfo(report)
    if not GeneralConfig or not next(GeneralConfig) then loadBattleConfig() end
    return makeGeneralSlotInfo(report.meta.attack.generals,report.meta.attack.pet,report.battle.init.attack),
           makeGeneralSlotInfo(report.meta.defense.generals,report.meta.defense.pet,report.battle.init.defense)
end

local function makemobaosha(v)
    return {
        type = v.type,
        postype = v.source.direct and "atk" or "def",
        pos = tostring(v.source.pos[1]),
        dir =  v.type,
        name = v.type.."_01",
    }
end

local function makehundisappear(v)
    return {
        type = v.type,
        name = "mobaosha_03",
    }
end


--只针对好友副本 第二回合重置血量
local function makeResetGeneral(v,atkSlotInfo,defSlotInfo)


    local slotinfo = v.direct and atkSlotInfo or defSlotInfo
    local generalInfo = slotinfo[tostring(v.pos)]
    local postype = v.direct and "atk" or "def"

    --重置之后的血量 减去 重置之前
    local damage = v.general.hp - generalInfo.hp
    generalInfo.hp2 = v.general.hp2
    ext.damagetotal[postype] = ext.damagetotal[postype] + damage
    generalInfo.hp = math.min(math.max(generalInfo.hp-damage,0),generalInfo.hp2)

    return v
end

function convertBattleReportToAnimationSub(report,atkSlotInfo,defSlotInfo,preAnimation,gstate)

    print("convertBattleReport==============================================================================")
    printT(report,"report.battle")

    ext = {
        damagetotal = {
            atk = 0,
            def = 0,
        },

        endinfo = {},
    }

    local animation = preAnimation or {}
    local round = 1
    if gstate ~= "story" and gstate ~= "skillview" then
        table.insert(animation,makeRoundAction(round))
    end

    local _attackCheer = report.meta.attack.cheer
    local _defenseCheer = report.meta.defense.cheer

    for k,v in ipairs(report.battle.action) do
        print("make action",k)
        injuredAudioTimes = {}
        if v.type == "talk" then
            table.insert(animation,makeTalkAction(v,report.meta))
        elseif v.type == "pos" then
            table.insert(animation,makePosAction(v,report.meta,atkSlotInfo,defSlotInfo))
        elseif v.type == "battle" then
            print("makebattle", k)
            if (v.source and next(v.source)) or (v.dest and next(v.dest))  then
                if v.source.skillid and v.source.skillid ==  12858 then
                else                   
                    if v.dest and next(v.dest) then
                        local newdest_sacrifice = {} 
                        local newdest = {} 
                        for k,v in ipairs(v.dest) do
                            if v.damage and next(v.damage) and v.damage.status and string.find(v.damage.status,"sacrifice") then
                                table.insert(newdest_sacrifice,v)
                            else
                                table.insert(newdest,v)
                            end
                        end                       
                        if next(newdest_sacrifice) then
                            local newaction = {
                                type = "battle",
                                dest = newdest_sacrifice,
                            }
                            table.insert(animation,makeBattleAction(newaction,atkSlotInfo,defSlotInfo,_attackCheer,_defenseCheer))
                        end
                        v.dest = newdest
                    end 
                    table.insert(animation,makeBattleAction(v,atkSlotInfo,defSlotInfo,_attackCheer,_defenseCheer))
                end
            else
                round = round +1
                if gstate ~= "story" and gstate ~= "skillview" then
                    table.insert(animation,makeRoundAction(round))
                end
            end
        elseif v.type == "namechange"  then
            table.insert(animation,v)
        elseif v.type == "starAnimation" then
            table.insert(animation,v)
            round = 1
            if gstate ~= "story" and gstate ~= "skillview" then
                table.insert(animation,makeRoundAction(round))
            end
        elseif v.type == "mobaoshaxuli" or v.type == "mobaosha" then
            table.insert(animation,makemobaosha(v))
        elseif v.type == "hundisappear" then
            table.insert(animation,makehundisappear(v))
        elseif v.type == "resetGeneral" then

            makeResetGeneral(v,atkSlotInfo,defSlotInfo)
            table.insert(animation,v)
        end
    end

    ext.endinfo.atk = atkSlotInfo
    ext.endinfo.def = defSlotInfo

    print("convertBattleReportToAnimation==============================================================================")
    printT(animation,"animation")

    return animation,ext
end


-- 已启用
function convertBattleReportToAnimation(report)

    GeneralConfig = gamedata.config.general
    animationConfig = gamedata.config.generalanimation
    skillConfig = gamedata.config.skill
    skillanimationConfig = gamedata.config.skillanimation
    combskillConfig = gamedata.config.combskill
    --printT(report.meta)
    printT(report.battle)


    local initatkSlotInfo = makeGeneralSlotInfo(report.meta.attack.generals,report.battle.init.attack)
    local initdefSlotInfo = makeGeneralSlotInfo(report.meta.defense.generals,report.battle.init.defense)

    local animation,ext = convertBattleReportToAnimationSub(report,table.copy(initatkSlotInfo),table.copy(initdefSlotInfo))

    print("convertBattleReportToAnimation==============================================================================")
    printT(animation,"animation")

    return report.meta.attack.name,report.meta.defense.name,report.result,initatkSlotInfo,initdefSlotInfo,animation,ext
end


��  