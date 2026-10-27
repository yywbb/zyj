--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/11/12
-- Time: 下午2:59
-- To change this template use File | Settings | File Templates.
--


local ids_pb = require("ids_pb")
local result_pb = require("result_pb")
local gangstatus_pb = require("gangstatus_pb")
local gangbroadcasts_pb = require("gangbroadcasts_pb")
local stringcontent_pb = require("stringcontent_pb")
local gangs_pb = require("gangs_pb")
local players_pb = require("players_pb")
local gangmembers_pb = require("gangmembers_pb")
local combmessages_pb = require("combmessages_pb")
local somethings_pb = require("somethings_pb")
local battleresult_pb = require("battleresult_pb")

function makeAllGeneralsWithPo(GeneralTemp)

    local allgenerals = {}
    for k,v in pairs(GeneralTemp or makeAllGeneralsTemp()) do
        v.fragmentnum = gamedata.cache.generalfragments[v.cid] and gamedata.cache.generalfragments[v.cid].num or 0
        local configdata = gamedata.config.general[tostring(v.cid)]
        local originCid = gamedata.getOriginCid(v.cid)
        v.hunponum = gamedata.getStaffNum(gamedata:findFragmentCid(originCid)).num
        table.insert(allgenerals,v)
    end
    gamedata.sortData(allgenerals, "ison", "quality", "level1", "level2","cid")

    return allgenerals
end

local function AnalysisMessage(destValue)
    local tmpReturnArray = {}
    local ids = ids_pb.Ids()
    ids:ParseFromString(destValue.data)
    for kk,vv in ipairs(ids.ids) do
        tmpReturnArray[tostring(kk)] = vv
        if tonumber(kk) == 5 then
            tmpReturnArray[tostring(kk)] = gamedata.cache.generals[vv].cid
        end
    end
    return tmpReturnArray
end

-----------------------------------------------------------------------------------------
function UIUserPatrolQuery(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4500, "UserPatrolQuery")
    return 1, 4500, nil
end

function NetUserPatrolQuery(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4500, "UserPatrolQuery")
    local reps = combmessages_pb.CombMessages()
    reps:ParseFromString(fd.rbuf)

    local tmpReturnArray = {}
    for k,v in ipairs(reps.messages) do
        tmpReturnArray[tostring(k)] = AnalysisMessage(v)
    end
    return { type = 4500 ,_message = tmpReturnArray}
end
-----------------------------------------------------------------------------------------
function UIUserPatrolStatus(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4501, "UserPatrolStatus")
    local clubData = ids_pb.Ids()
    table.insert(clubData.ids, uireq._id)
    return 1, 4501, clubData:SerializeToString()
end

function NetUserPatrolStatus(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4501, "UserPatrolStatus")

    local tmpReturnArray = {}
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    for kk,vv in ipairs(ids.ids) do
        tmpReturnArray[tostring(kk)] = vv
        if tonumber(kk) == 1 and vv == 2 then
            tmpReturnArray.generals = makeAllGeneralsWithPo()
        elseif tonumber(kk) == 5 then
            tmpReturnArray[tostring(kk)] = gamedata.cache.generals[vv].cid
        end
    end
    
    return { type = 4501 ,status = tmpReturnArray}
end
-----------------------------------------------------------------------------------------
function UIUserPatrolAttack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4502, "UserPatrolAttack")
    local clubData = ids_pb.Ids()
    table.insert(clubData.ids, uireq._id)
    if uireq._items then
        gamedata.ext.clubItems = uireq._items
    end
    return 1, 4502, clubData:SerializeToString()
end

function NetUserPatrolAttack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4502, "UserPatrolAttack")

    local tmpReturnArray = {}
    local reps = combmessages_pb.CombMessages()
    reps:ParseFromString(fd.rbuf)
    local t = { type = 4502}
    for k,v in ipairs(reps.messages) do
        if tonumber(k) == 1 then
            tmpReturnArray = {}
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            for kk,vv in ipairs(ids.ids) do
                tmpReturnArray[tostring(kk)] = vv
                if tonumber(kk) == 1 and vv == 2 then
                    tmpReturnArray.generals = makeAllGeneralsWithPo()
                end
            end
            t.datas = tmpReturnArray
        elseif tonumber(k) == 2 then
            local copyAttackResultPb = battleresult_pb.BattleResult()
            copyAttackResultPb:ParseFromString(v.data)

            t.reward = gamedata:SomethingProcess(copyAttackResultPb.reward)

            tmpReturnArray.result = copyAttackResultPb.result
            t.result = copyAttackResultPb.result
            t.battlereport = PickBattleResultReport(copyAttackResultPb)
        end
    end
    return t
end
-----------------------------------------------------------------------------------------
function UIUserPatrolDo(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4503, "UserPatrolDo")
    local clubData = ids_pb.Ids()
    table.insert(clubData.ids, uireq._id)
    table.insert(clubData.ids, uireq._time)
    table.insert(clubData.ids, uireq._cid)
    if uireq._shaType ~= nil then
        gamedata.ext.shaType = uireq._shaType
        gamedata.ext.shaNum = uireq._shaNum
        if gamedata.ext.shaType == 0 then
            if gamedata.cache.role.energy < gamedata.ext.shaNum then
                return  0, 503, {type = 503, msgtype = "shortenergy", param = gamedata.cache.props}
            end
        elseif gamedata.ext.shaType == 1 then
            if gamedata.ext.shaNum > gamedata.cache.role.gold then
                return 0,503,{type = 503, msgtype = "shortgold" }
            end
        end
    end
    return 1, 4503, clubData:SerializeToString()
end

function NetUserPatrolDo(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4503, "UserPatrolDo")

    local tmpReturnArray = {}
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    for kk,vv in ipairs(ids.ids) do
        tmpReturnArray[tostring(kk)] = vv
        if kk == 5 then
            tmpReturnArray[tostring(kk)] = gamedata.cache.generals[vv].cid
        end
    end
    tmpReturnArray.generals = makeAllGeneralsWithPo()

    if gamedata.ext.shaType then
        if gamedata.ext.shaType == 0 then
            gamedata:updateRoleEnergy(0-gamedata.ext.shaNum,"天庭银座",1)
        elseif gamedata.ext.shaType == 1 then
            gamedata:updateRoleGold(0-gamedata.ext.shaNum,"天庭银座",1)
        end
        gamedata.ext.shaType = nil
        gamedata.ext.shaNum = nil
    end
    return { type = 4503 ,status = tmpReturnArray}
end
-----------------------------------------------------------------------------------------
function UIUserPatrolReward(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4504, "UserPatrolReward")
    local clubData = ids_pb.Ids()
    table.insert(clubData.ids, uireq._id)
    return 1, 4504, clubData:SerializeToString()
end

function NetUserPatrolReward(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4504, "UserPatrolReward")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    local reward, used, ext = gamedata:SomethingProcess(SomeThings)
    -- printT(reward,"==reward==")
    -- printT(used,"==used==")
    -- printT(ext,"==ext==")
    return { type = 4504 , _reward = reward,_type = ext._type}
end
-----------------------------------------------------------------------------------------
function UIUserPatrolEventDo(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4505, "UserPatrolEventDo")
    local clubData = ids_pb.Ids()
    table.insert(clubData.ids, uireq._index)
    table.insert(clubData.ids, uireq._choose)
    if uireq._gold and uireq._gold > 0 then
        if uireq._gold and uireq._gold > gamedata.cache.role.gold then
            return 0,503,{type = 503, msgtype = "shortgold"}
        end
        gamedata.ext.clubGold = uireq._gold
    end
    if uireq._coin and uireq._coin > 0 then
        if uireq._coin and uireq._coin > gamedata.cache.role.coin then
            return 0,503,{type = 503, msg = 1 }
        end
        gamedata.ext.clubCoin = uireq._coin
    end
    if uireq._item and uireq._nums then
        gamedata.ext.clubItem = uireq._item
        gamedata.ext.clubNums = uireq._nums
    end
    return 1, 4505, clubData:SerializeToString()
end

function NetUserPatrolEventDo(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4505, "UserPatrolEventDo")
    local EncounterOptResultPb = battleresult_pb.BattleResult()
    EncounterOptResultPb:ParseFromString(fd.rbuf)
    local t = { type = 4505 ,result = EncounterOptResultPb.result,}
    t.battlereport = PickBattleResultReport(EncounterOptResultPb)
    t.reward = gamedata:SomethingProcess(EncounterOptResultPb.reward)
    if gamedata.ext.clubCoin then
        gamedata:updateRoleCoin(0-gamedata.ext.clubCoin,"天庭银座",1)
    end
    if gamedata.ext.clubGold then
        gamedata:updateRoleGold(0-gamedata.ext.clubGold,"天庭银座",1)
    end
    if gamedata.ext.clubItem and gamedata.ext.clubNums then
        gamedata:updateStaff({cid = gamedata.ext.clubItem,num = 0-gamedata.ext.clubNums})
    end
    gamedata.ext.clubCoin = nil
    gamedata.ext.clubGold = nil
    gamedata.ext.clubItem = nil
    gamedata.ext.clubNums = nil
    return t
end
-----------------------------------------------------------------------------------------

function UIUserPatrolOneAdd(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4509, "UserPatrolOneAdd")


    local clubData = ids_pb.Ids()
    table.insert(clubData.ids, uireq._time)
    for i=1,10 do
        if uireq.data[tostring(i)] then
            table.insert(clubData.ids, uireq.data[tostring(i)])
        else
            table.insert(clubData.ids, 0)
        end
    end

    printT(uireq,"uireq  --    ")
    gamedata.ext.baoNum = uireq._baoNum or 0
    gamedata.ext.shaNum = uireq._shaNum or 0
    gamedata.ext.nightArrayData = uireq.data or {}
--m_i3InsertType
    if gamedata.ext.shaNum == 0 then
        if gamedata.cache.role.energy < gamedata.ext.baoNum then
            return  0, 503, {type = 503, msgtype = "shortenergy", param = gamedata.cache.props}
        end
    else
        if gamedata.ext.baoNum > gamedata.cache.role.gold then
            return 0,503,{type = 503, msgtype = "shortgold" }
        end
    end
    -- if gamedata.ext.baoNum > 0 then
    --     if gamedata.ext.baoNum > gamedata.cache.role.gold then
    --         return 0,503,{type = 503, msgtype = "shortgold" }
    --     end
    -- end
        
    return 1, 4509, clubData:SerializeToString()
end

function NetUserPatrolOneAdd(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4509, "UserPatrolOneAdd")

    local reps = combmessages_pb.CombMessages()
    reps:ParseFromString(fd.rbuf)
    local tmpReturnArray ={}
    for k,v in ipairs(reps.messages) do
         tmpReturnArray[tostring(k)] = AnalysisMessage(v)
    end

    -- if gamedata.ext.shaNum and gamedata.ext.shaNum > 0 then
    --     gamedata:updateRoleEnergy(0-gamedata.ext.shaNum,"天庭银座",1)
    -- end
    -- if gamedata.ext.baoNum and gamedata.ext.baoNum > 0 then
    --     gamedata:updateRoleGold(0-gamedata.ext.baoNum,"天庭银座",1)
    -- end

     if gamedata.ext.shaNum == 0 then
        gamedata:updateRoleEnergy(0-gamedata.ext.baoNum,"天庭银座",1)
    else
        gamedata:updateRoleGold(0-gamedata.ext.baoNum,"天庭银座",1)
    end

    gamedata.ext.baoNum = 0
    gamedata.ext.shaNum = 0
    for k,v in pairs(gamedata.ext.nightArrayData) do
        gamedata.ext.nightArrayData[tostring(k)] = gamedata.cache.generals[v].cid
    end

    return { type = 4509 ,data = tmpReturnArray,nightArrayData = gamedata.ext.nightArrayData}

end

function UIUserPatrolOneAddReward(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4510, "UserPatrolOneAddReward")
    
    local clubData = ids_pb.Ids()
    for i=1,table.getTableLength(uireq.data) do
        table.insert(clubData.ids, uireq.data[tostring(i)])
    end
    
    return 1, 4510, clubData:SerializeToString()
end

function NetUserPatrolOneAddReward(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4510, "UserPatrolOneAddReward")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    local reward, used, ext = gamedata:SomethingProcess(SomeThings)
    
    return { type = 4510 , reward = reward,_type = ext._type}
    
end

function UIUserPatrolOneAddQuery(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4511, "UserPatrolOneAddQuery")
        
    return 1, 4511, nil
end


function NetUserPatrolOneAddQuery(fd)

    cclog("NET type:%d cmd:%s recv response from gameserver", 4511, "UserPatrolOneAddQuery")
    local reps = combmessages_pb.CombMessages()
    reps:ParseFromString(fd.rbuf)
    local tmpReturnArray ={}
    for k,v in ipairs(reps.messages) do
        tmpReturnArray[tostring(k-1)] = AnalysisMessage(v)
    end

    local generalsData = makeAllGeneralsWithPo()

    return { type = 4511 ,data = tmpReturnArray,generalsdata =generalsData}
end
