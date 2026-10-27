--
-- Created by IntelliJ IDEA.
-- User: jutian
-- Date: 14/11/1
-- Time: 下午3:28
-- To change this template use File | Settings | File Templates.
--

require"myjson"

function MergeBattleReport(real, storyt)
    --local realt = LoadJsonStringToTable(real)
--    local realt = LoadJsonStringToTable(ReplaceAbbToKey(real))
--    local storyt = LoadJsonStringToTable(story)

    local realt = {}
    if type(real) == "string" then
        realt =  LoadJsonStringToTable(ReplaceAbbToKey(real))
    elseif type(real) == "table" then
        realt =  real
    else
        cclog("wrong battlereport type")
        return
    end

    local ret = {
        type="story",
        result=realt.result,
        meta = {
            attack = {
                generals = {

                },
                pet = realt.meta.attack.pet,
                name = realt.meta.attack.name
            },
            defense = {
                generals = {

                },
                pet = {},
                name = realt.meta.defense.name
            }
        },
        battle={
            init={
                attack={

                },
                defense={

                }
            },
            action={

            }
       }
    }
    local selfothers = {}
    for k,v in pairs(realt.meta.attack.generals) do
        ret.meta.attack.generals[k] = v
    end

    for k,v in pairs(storyt.meta.attack.generals) do
        ret.meta.attack.generals[k] = v
    end

    for k,v in pairs(realt.meta.defense.generals) do
        ret.meta.defense.generals[k] = v
    end

    for k,v in pairs(storyt.meta.defense.generals) do
        ret.meta.defense.generals[k] = v
    end

    for k,v in pairs(storyt.battle.init.attack) do
        ret.battle.init.attack[k] = v
    end

    for k,v in pairs(realt.battle.init.attack) do
        if not ret.battle.init.attack[k] then
            ret.battle.init.attack[k] = v
        else
            table.insert(selfothers, {pos = k, id = v.id})
        end
    end

    for k,v in pairs(storyt.battle.init.defense) do
        ret.battle.init.defense[k] = v
    end
    for k,v in pairs(realt.battle.init.defense) do
        if not ret.battle.init.defense[k] then
            ret.battle.init.defense[k] = v
        else
            local general = ret.meta.defense.generals[tostring(ret.battle.init.defense[k].id)]
            local general2 = ret.meta.defense.generals[tostring(v.id)]
            general.hp = general.hp + general2.hp
            general.hp2 = general.hp2 + general2.hp2
        end
    end

    for k,v in ipairs(storyt.battle.action) do
        table.insert(ret.battle.action, v)
        if v.type == "pos" then
            cclog("action pos")
            for k1,v1 in pairs(v.changes) do
                if v1.direct == true and v1.opt == "appear" then
                    cclog("action pos attack appear pos:%d", v1.pos)
                    if ret.battle.init.attack[tostring(v1.pos)] then
                        cclog("ok")
                        table.insert(selfothers, {pos = tostring(v1.pos), id = ret.battle.init.attack[tostring(v1.pos)].id})
                        ret.battle.init.attack[tostring(v1.pos)] = nil
                    end
                end
            end
        end
    end

    if table.getTableLength(selfothers) ~= 0 then
        local changes = {}
        for k,v in ipairs(selfothers) do
            table.insert(changes,{
                direct = true,
                opt = "appear",
                general = v.id,
                pos = tonumber(v.pos)})
        end
        table.insert(
            ret.battle.action,{
            type="pos",
            changes = changes})
        cclog("fix appear!")
    end

    for k,v in ipairs(realt.battle.action) do
        table.insert(ret.battle.action, v)
    end

    return ret
    --return MakeJsonStringFromTable(ret)
end

--好友副本
function  MergeBattleReportForFriendCopy(report1,report2)
    print("MergeBattleReportForFriendCopy=====")
    print(report1)
    print(report2)

    local rep1,rep2
    if type(report1) == "string" then
        rep1 =  LoadJsonStringToTable(ReplaceAbbToKey(report1))
    elseif type(report1) == "table" then
        rep1 =  report1
    end

    if not report2  then
        return rep1
    end


    if type(report2) == "string" then
        rep2 =  LoadJsonStringToTable(ReplaceAbbToKey(report2))
    elseif type(report2) == "table" then
        rep2 =  report2
    end

    local ret = {
--        type="story",
        result=rep2.result,
        meta = {
            attack = {
                generals = table.merge(rep1.meta.attack.generals,rep2.meta.attack.generals),
                pet = table.merge(rep1.meta.attack.pet,rep2.meta.attack.pet),
                name = {rep1.meta.attack.name,rep2.meta.attack.name}
            },
            defense = {
                generals = rep1.meta.defense.generals,
                pet = {},
                name = rep2.meta.defense.name
            }
        },
        battle={
            init=rep1.battle.init,
            action=rep1.battle.action
        }
    }

    local disappearaction = {
        type= "pos",
        changes = {},
    }
    for k,v in pairs(rep1.battle.init.attack) do
        table.insert(disappearaction.changes,{
            direct = true,
            opt = "disappear",
            pos = tonumber(k),
            general = v.id,
        } )
    end
    table.insert(ret.battle.action,disappearaction )

    local appearaction = {
        type= "pos",
        changes = {},
    }
    for k,v in pairs(rep2.battle.init.attack) do
        table.insert(appearaction.changes,{
            direct = true,
            opt = "appear",
            pos = tonumber(k),
            general = v.id,
        } )
    end

    table.insert(ret.battle.action,appearaction )

    table.insert(ret.battle.action,{type = "namechange",direct= true, index = 2} )
    table.insert(ret.battle.action,{type = "starAnimation",index = 2} )

    for k,v in pairs(rep2.battle.init.attack) do
        if k ~= "0" and rep2.meta.attack.generals and rep2.meta.attack.generals[tostring(v.id)] then
            table.insert(ret.battle.action,{type = "resetGeneral",direct= true ,pos = k,general = rep2.meta.attack.generals[tostring(v.id)]} )
        end
    end

    for k,v in pairs(rep2.battle.init.defense) do
        if k ~= "0" and rep2.meta.defense.generals and rep2.meta.defense.generals[tostring(v.id)] then
            table.insert(ret.battle.action,{type = "resetGeneral",direct= false ,pos = k,general = rep2.meta.defense.generals[tostring(v.id)]} )
        end
    end

    for k,v in ipairs(rep2.battle.action) do
        table.insert(ret.battle.action,v )
    end

    return ret
end

--封神赛boss战解析
function MergeBattleReportForGodCompetition(report1,report2,report3)
    print("MergeBattleReportForGodCompetition==")

    local rep1,rep2,rep3
    if type(report1) == "string" then
        rep1 =  LoadJsonStringToTable(ReplaceAbbToKey(report1))
    elseif type(report1) == "table" then
        rep1 =  report1
    end

    if type(report2) == "string" then
        rep2 =  LoadJsonStringToTable(ReplaceAbbToKey(report2))
    elseif type(report2) == "table" then
        rep2 =  report2
    end

    if type(report3) == "string" then
        rep3 =  LoadJsonStringToTable(ReplaceAbbToKey(report3))
    elseif type(report3) == "table" then
        rep3 =  report3
    end

    local metaGeneralsData = table.merge(rep1.meta.attack.generals,rep2.meta.attack.generals)
    local metaPetData = table.merge(rep1.meta.attack.pet,rep2.meta.attack.pet),

    printT(metaGeneralsData,"jkp-data1")
    printT(metaPetData,"jkp-data2")

    local ret = {
        result = rep3.result,
        meta = {
            attack = {
                generals = table.merge(metaGeneralsData,rep3.meta.attack.generals),
                pet = table.merge(metaPetData,rep3.meta.attack.pet),
                name = {"阵容1","阵容2","阵容3"}
            },
            defense = {
                generals = rep1.meta.defense.generals,
                pet = rep1.meta.defense.pet,
                name = rep1.meta.defense.name
            }
        },
        battle = {
            init = rep1.battle.init,
            action = rep1.battle.action
        }
    }
    --消失
    local disappearaction = {
        type= "pos",
        changes = {},
    }
    for k,v in pairs(rep1.battle.init.attack) do
        table.insert(disappearaction.changes,{
            direct = true,
            opt = "disappear",
            pos = tonumber(k),
            general = v.id,
        } )
    end
    table.insert(ret.battle.action,disappearaction )

    --出现
    local appearaction = {
        type= "pos",
        changes = {},
    }
    for k,v in pairs(rep2.battle.init.attack) do
        table.insert(appearaction.changes,{
            direct = true,
            opt = "appear",
            pos = tonumber(k),
            general = v.id,
        } )
    end
    table.insert(ret.battle.action,appearaction )

    table.insert(ret.battle.action,{type = "namechange",direct= true, index = 2} )
    table.insert(ret.battle.action,{type = "starAnimation",index = 2} )

    for k,v in pairs(rep2.battle.init.attack) do
        if rep2.meta.attack.generals and rep2.meta.attack.generals[tostring(v.id)] then
            table.insert(ret.battle.action,{type = "resetGeneral",direct= true ,pos = k,general = rep2.meta.attack.generals[tostring(v.id)]} )
        end
    end

    for k,v in pairs(rep2.battle.init.defense) do
        if rep2.meta.defense.generals and rep2.meta.defense.generals[tostring(v.id)] then
            table.insert(ret.battle.action,{type = "resetGeneral",direct= false ,pos = k,general = rep2.meta.defense.generals[tostring(v.id)]} )
        end
    end

    for k,v in ipairs(rep2.battle.action) do
        table.insert(ret.battle.action,v )
    end

    --阵容3
    --消失
    local disappearaction = {
        type= "pos",
        changes = {},
    }
    for k,v in pairs(rep2.battle.init.attack) do
        table.insert(disappearaction.changes,{
            direct = true,
            opt = "disappear",
            pos = tonumber(k),
            general = v.id,
        } )
    end
    table.insert(ret.battle.action,disappearaction )

    --出现
    local appearaction = {
        type= "pos",
        changes = {},
    }
    for k,v in pairs(rep3.battle.init.attack) do
        table.insert(appearaction.changes,{
            direct = true,
            opt = "appear",
            pos = tonumber(k),
            general = v.id,
        } )
    end
    table.insert(ret.battle.action,appearaction )

    table.insert(ret.battle.action,{type = "namechange",direct= true, index = 3} )
    table.insert(ret.battle.action,{type = "starAnimation",index = 3} )

    for k,v in pairs(rep3.battle.init.attack) do
        if rep3.meta.attack.generals and rep3.meta.attack.generals[tostring(v.id)] then
            table.insert(ret.battle.action,{type = "resetGeneral",direct= true ,pos = k,general = rep3.meta.attack.generals[tostring(v.id)]} )
        end
    end

    for k,v in pairs(rep3.battle.init.defense) do
        if rep3.meta.defense.generals and rep3.meta.defense.generals[tostring(v.id)] then
            table.insert(ret.battle.action,{type = "resetGeneral",direct= false ,pos = k,general = rep3.meta.defense.generals[tostring(v.id)]} )
        end
    end

    for k,v in ipairs(rep3.battle.action) do
        table.insert(ret.battle.action,v )
    end

    return ret
end  *-  