--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/9/1
-- Time: 11:00
-- To change this template use File | Settings | File Templates.
--


local propid = 20346
local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")
local combmessages_pb = require("combmessages_pb")
local params_pb = require("params_pb")
local battleresult_pb = require("battleresult_pb")
local players_pb = require("players_pb")
local result_pb = require("result_pb")

require"PickBattleResultReport"


local function makeHonorWarSlot( data )
    local slot = {
        {pos={-1,-1,-1,-1,-1,-1,-1},pet= -1,power=data[17],buff=data[20]},
        {pos={-1,-1,-1,-1,-1,-1,-1},pet= -1,power=data[18],buff=data[21]},
        {pos={-1,-1,-1,-1,-1,-1,-1},pet= -1,power=data[19],buff=data[22]},
    }
    slot[data[8]].pet = data[16]

    gamedata.cache.HonorWarSlot = slot

    slot[1].pos[data[1]] = data[9]
    slot[2].pos[data[2]] = data[10]
    slot[2].pos[data[3]] = data[11]
    slot[3].pos[data[4]] = data[12]
    slot[3].pos[data[5]] = data[13]
    slot[3].pos[data[6]] = data[14]
    slot[3].pos[data[7]] = data[15]
end

local function checkHonorWarSlot( slot )
    for i=1,3 do
        local onedata = slot[i]
        for idx, HonorSlotiid in ipairs(onedata.pos) do
            if HonorSlotiid >0 then
                local ischange = true
                for k,v in pairs(gamedata.cache.slots) do
                    if HonorSlotiid == v.general then
                        ischange = false
                    end
                end
                if ischange then slot[i].pos[idx]=0 end
            end
        end

        if onedata.pet >0 then
            local ispetchange = true
            for k,v in pairs(gamedata.cache.petsdata.pets) do
                if v.iid == onedata.pet then
                    ispetchange = false
                end 
            end
            if ispetchange then slot[i].pet = 0 end
        end
    end

    return slot
end

local function HonorWarChampionData( data )
    local tempdata = {}
    local arrnum = #data/7

    for i=1,arrnum do
        local idx = 7*(i-1)
        local temp = {}
        temp.rank = i

        temp.list           = data[idx+1] and data[idx+1].i or 0
        temp.rid            = data[idx+2] and data[idx+2].i or 0
        temp.name           = data[idx+2] and data[idx+2].s or ""
        temp.level          = data[idx+3] and data[idx+3].i or 0
        temp.profile        = data[idx+4] and data[idx+4].i or 0
        temp.w_l            = data[idx+5] and data[idx+5].i or 0
        temp.w_c            = data[idx+6] and data[idx+6].i or 0
        temp.serviceid      = data[idx+7] and data[idx+7].i or 0
        temp.servicename    = data[idx+7] and data[idx+7].s or ""
        tempdata[temp.list] = temp
    end

    return tempdata
end

local function makeHonorWarStatus( data )
    local PreStatus = {}
    for k,v in ipairs(data) do
        if v.id == 1 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            PreStatus.number = ids.ids[1]
            PreStatus.buff_one = ids.ids[2]
            PreStatus.buff_two = ids.ids[3]
            PreStatus.buff_three= ids.ids[4]
        elseif v.id == 2 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            PreStatus.list = ids.ids[1]
            PreStatus.competition = ids.ids[2]
            PreStatus.win = ids.ids[3]
            PreStatus.lose = ids.ids[4]
            PreStatus.rank = ids.ids[5]
            PreStatus.star = ids.ids[6]
            PreStatus.status = ids.ids[7]
            PreStatus.iscanArray = ids.ids[8]
        end
    end
    gamedata.cache.HonorWarStatus = PreStatus
end

local function HonorWarRoleBattle( data,id )
    if data and id and id+0 > 0 then
        local point = {}
        point.id =        data[1] and data[1].s or ""
        point.phase =     data[2] and data[2].i or 0
        point.round =     data[3] and data[3].i or 0
        point.result =    data[4] and data[4].i or 0
        point.resultnum = data[5] and data[5].i or 0
        point.star =      data[6] and data[6].i or 0
        point.reward =    data[7] and data[7].i or 0
        
        point.rid_a =     data[8] and data[8].i or 0
        point.name_a =    data[8] and data[8].s or ""
        point.profile_a = data[9] and data[9].i or 0
        point.power_a =   data[10] and data[10].i or 0
        point.rid_b =     data[11] and data[11].i or 0
        point.name_b =    data[11] and data[11].s or ""
        point.profile_b = data[12] and data[12].i or 0
        point.power_b =   data[13] and data[13].i or 0
        point.time =      data[14] and data[14].i or 0

        point.title_a   =  data[15] and data[15].i or 0
        point.iconBox_a =  data[16] and data[16].i or 0
        point.title_b   =  data[17] and data[17].i or 0
        point.iconBox_b =  data[18] and data[18].i or 0



        gamedata.cache.Honorwarrolebattles[tostring(id)] = point
    end
end

--荣耀之战布阵查询
function UIHonorWarSlotQueryCallBack( uireq )
    cclog("NET type:%d cmd:%s recv request from UI", 6701, "HonorWarSlotQuery")

    if gamedata.cache.HonorWarSlot and not uireq.param then
        return 0, 6701, {
                            type = 6701, 
                            HonorWarSlot = checkHonorWarSlot(gamedata.cache.HonorWarSlot),
                            pets = gamedata.cache.petsdata.pets or {},
                        }
    else
        return 1, 6701, nil
    end
end

function NetHonorWarSlotQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6701, "HonorWarSlotQuery")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    makeHonorWarSlot(ids.ids)

    return { type = 6701, HonorWarSlot = checkHonorWarSlot(gamedata.cache.HonorWarSlot),pets = gamedata.cache.petsdata.pets or {},}
end

--荣耀之战布阵
function UIHonorWarSlotArrangeCallBack( uireq )
    cclog("NET type:%d cmd:%s recv request from UI", 6702, "HonorWarSlotArrange")
    local idsData = ids_pb.Ids()

    for i=1,8 do
        table.insert(idsData.ids, uireq.request[tostring(i)])    
    end

    return 1, 6702, idsData:SerializeToString()
end

function NetHonorWarSlotArrangeCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6702, "HonorWarSlotArrange")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    makeHonorWarSlot(ids.ids)

    return { type = 6702, HonorWarSlot = checkHonorWarSlot(gamedata.cache.HonorWarSlot),pets = gamedata.cache.petsdata.pets or {},}
end

--荣耀之战主页查询
function UIHonorWarStatusQueryCallBack( uireq )
    cclog("NET type:%d cmd:%s recv request from UI", 6503, "HonorWarStatusQuery")

    -- if gamedata.cache.HonorWarStatus then
    --     return 0, 6503, {type = 6503, HonorWarStatus = gamedata.cache.HonorWarStatus}
    -- else
        return 1, 6503, nil
    -- end
end

function NetHonorWarStatusQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6503, "HonorWarStatusQuery")
    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    makeHonorWarStatus(datas.messages)

    return { type = 6503, HonorWarStatus = gamedata.cache.HonorWarStatus}
end

--荣耀之战预选赛查询
function UIHonorWarRoleBattlesCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6504, "HonorWarRoleBattles")

    return 1, 6504, nil
end

function NetHonorWarRoleBattlesCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6504, "HonorWarRoleBattles")
    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    gamedata.cache.Honorwarrolebattles = {}

    for k,v in ipairs(datas.messages) do
        local params = params_pb.ParamS()
        params:ParseFromString(v.data)
        HonorWarRoleBattle(params.params,v.id)
    end

    return { type = 6504, honorwarrolebattles = gamedata.cache.Honorwarrolebattles or {}}
end

--荣耀之战战斗奖励领取
function UIHonorWarRoleBattlesRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6505, "HonorWarRoleBattlesReward")
    local params = params_pb.ParamS()

    local data = params.params:add()
    data.i = uireq.phase
    data.s = uireq.id

    return 1, 6505, params:SerializeToString()
end

function NetHonorWarRoleBattlesRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6505, "HonorWarRoleBattlesReward")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    local reward = gamedata:SomethingProcess(SomeThings)

    return {type = 6505, reward = reward}
end

--荣耀之战战斗详情
local infoid = 0
function UIHonorWarRoleBattlesInfoCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6506, "HonorWarRoleBattlesInfo")

    -- if gamedata.cache.HonorWarRoleBattlesInfo[uireq.id] then
    --     return 0, 6506, {type = 6506, info = gamedata.cache.HonorWarRoleBattlesInfo[uireq.id]}
    -- else
        local params = params_pb.ParamS()

        local data = params.params:add()
        data.i = uireq.phase
        data.s = uireq.id

        return 1, 6506, params:SerializeToString()
    -- end
end

function NetHonorWarRoleBattlesInfoCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6506, "HonorWarRoleBattlesInfo")
    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    if not gamedata.cache.HonorWarRoleBattlesInfo then
        gamedata.cache.HonorWarRoleBattlesInfo = {}
    end

    local battleinfo = {}

    for k,v in ipairs(datas.messages) do
        local params = params_pb.ParamS()
        params:ParseFromString(v.data)   
        local data = params.params    
        if v.id == 0 then 
            battleinfo.players = {
                rid_a      = data[1] and data[1].i or 0,
                rid_b      = data[2] and data[2].i or 0,
            }            
        elseif v.id == 1 then
            battleinfo[1] = {
                id         = data[1] and data[1].s or "",
                power_a    = data[2] and data[2].i or 0,
                general1_a = data[3] and data[3].i or 0,
                oldcid1_a  = data[4] and data[4].i or 0,
                power_b    = data[5] and data[5].i or 0,
                general1_b = data[6] and data[6].i or 0,
                oldcid1_b  = data[7] and data[7].i or 0,
                result     = data[8] and data[8].i or 0,
                time       = data[1] and data[1].i or 0,
                rid_a      = data[9] and data[9].i or 0,
                rid_b      = data[10] and data[10].i or 0,
            }
        elseif v.id == 2 then
            battleinfo[2] = {
                id         = data[1] and data[1].s or "",
                power_a    = data[2] and data[2].i or 0,
                general1_a = data[3] and data[3].i or 0,
                oldcid1_a  = data[4] and data[4].i or 0,
                general2_a = data[5] and data[5].i or 0,
                oldcid2_a  = data[6] and data[6].i or 0,
                power_b    = data[7] and data[7].i or 0,
                general1_b = data[8] and data[8].i or 0,
                oldcid1_b  = data[9] and data[9].i or 0,
                general2_b = data[10] and data[10].i or 0,
                oldcid2_b  = data[11] and data[11].i or 0,
                result     = data[12] and data[12].i or 0,
                time       = data[1] and data[1].i or 0,
                rid_a      = data[13] and data[13].i or 0,
                rid_b      = data[14] and data[14].i or 0,
            }            
        elseif v.id == 3 then
            battleinfo[3] = {
                id         = data[1] and data[1].s or "",
                power_a    = data[2] and data[2].i or 0,
                general1_a = data[3] and data[3].i or 0,
                oldcid1_a  = data[4] and data[4].i or 0,
                general2_a = data[5] and data[5].i or 0,
                oldcid2_a  = data[6] and data[6].i or 0,
                general3_a = data[7] and data[7].i or 0,
                oldcid3_a  = data[8] and data[8].i or 0,
                general4_a = data[9] and data[9].i or 0,
                oldcid4_a  = data[10] and data[10].i or 0,
                power_b    = data[11] and data[11].i or 0,
                general1_b = data[12] and data[12].i or 0,
                oldcid1_b  = data[13] and data[13].i or 0,
                general2_b = data[14] and data[14].i or 0,
                oldcid2_b  = data[15] and data[15].i or 0,
                general3_b = data[16] and data[16].i or 0,
                oldcid3_b  = data[17] and data[17].i or 0,
                general4_b = data[18] and data[18].i or 0,
                oldcid4_b  = data[19] and data[19].i or 0,
                result     = data[20] and data[20].i or 0,
                time       = data[1] and data[1].i or 0,
                rid_a      = data[21] and data[21].i or 0,
                rid_b      = data[22] and data[22].i or 0,
            }            
        end
    end

    gamedata.cache.HonorWarRoleBattlesInfo[infoid] = battleinfo
    return {type = 6506, info = gamedata.cache.HonorWarRoleBattlesInfo[infoid]}
end

--荣耀之战战斗播放
function UIHonorWarBattlePlayCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6507, "HonorWarBattlePlay")
    local params = params_pb.ParamS()

    local data = params.params:add()
    data.i = uireq.idx
    data.s = uireq.id

    return 1, 6507, params:SerializeToString()
end


function NetHonorWarBattlePlayCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6507, "HonorWarBattlePlay")
    local copyAttackResultPb = battleresult_pb.BattleResult()
    copyAttackResultPb:ParseFromString(fd.rbuf)

    return {
        type = 6507,
        result = copyAttackResultPb.result,
        reward = gamedata:SomethingProcess(copyAttackResultPb.reward),
        battlereport = PickBattleResultReport(copyAttackResultPb),
        star = copyAttackResultPb.star
    }
end

--荣耀之战淘汰赛玩家信息
local function HonorWarPlayers( data,id )
    if data and id and id+0 > 0 then
        local point = {}
        point.rid = data[1] and data[1].i or 0
        point.name = data[1] and data[1].s or ""
        point.level = data[2] and data[2].i or 0
        point.profile = data[3] and data[3].i or 0
        point.server_id = data[4] and data[4].i or 0
        point.server_name = data[4] and data[4].s or ""

        gamedata.cache.honorwarplayers[tostring(point.rid)] = point
    end
end

function UIHonorWarTopUserInfoCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6512, "HonorWarTopUserInfo")

    return 1, 6512, nil
end

function NetHonorWarTopUserInfoCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6512, "HonorWarTopUserInfo")
    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    gamedata.cache.honorwarplayers = {}

    for k,v in ipairs(datas.messages) do
        local params = params_pb.ParamS()
        params:ParseFromString(v.data)
        HonorWarPlayers(params.params,v.id)
    end

    return { type = 6512, honorwarplayers = gamedata.cache.honorwarplayers or {}}
end

--荣耀之战淘汰赛
function UIHonorWarTopCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6508, "HonorWarTopCallBack")

    return 1, 6508, nil
end

function NetHonorWarTopCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6508, "HonorWarTopCallBack")
    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local topinfo = {}
    for k,v in ipairs(datas.messages) do
        if v.id == 0 then    
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            local data = ids.ids
            topinfo.selfdata = {}
            topinfo.selfdata.list = data[1] or 0
            topinfo.selfdata.rank = data[2] or 0
            topinfo.selfdata.time = data[3] or 0
        else
            local params = params_pb.ParamS()
            params:ParseFromString(v.data)
            local data = params.params
            topinfo[tostring(v.id)] = {}
            local totalbetcount = 0
            
            for i = 1, (#data)/7 do
                local onebattle = {}
                local idx = 7*(i-1)
                onebattle.id     = data[idx+1].s or "0"
                onebattle.phase  = data[idx+1].i or 0
                onebattle.p_id1  = data[idx+2].i or 0
                onebattle.p_id2  = data[idx+3].i or 0
                onebattle.result = data[idx+4].i or 0
                onebattle.resultnum = data[idx+5].i or 0
                onebattle.bet    = data[idx+6].i or 0
                onebattle.betnum = data[idx+7].i or 0
                onebattle.betcount = tonumber(data[idx+7].s or "0") or 0
                totalbetcount = totalbetcount + onebattle.betcount
                topinfo[tostring(v.id)][tostring(i)] = onebattle
            end

            topinfo[tostring(v.id)].totalbetcount = totalbetcount
        end
    end
    gamedata.cache.honorwartop = topinfo

    return { type = 6508, honorwartop = gamedata.cache.honorwartop or {}}
end

--荣耀之战淘汰赛押注
function UIHonorWarWeedBetCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6509, "HonorWar")
    local params = params_pb.ParamS()

    local data1 = params.params:add()
    data1.s = uireq.id
    local data2 = params.params:add()
    data2.i = uireq.mark
    local data3 = params.params:add()
    data3.i = uireq.money

    gamedata.ext.HonorwarWeedBet = uireq

    return 1, 6509, params:SerializeToString()

end

function NetHonorWarWeedBetCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6509, "HonorWar")

    local Result = result_pb.Result()
    Result:ParseFromString(fd.rbuf)

    if gamedata.ext.HonorwarWeedBet and gamedata.ext.HonorwarWeedBet.money then
        gamedata:updateRoleCoin(0-gamedata.ext.HonorwarWeedBet.money)
    end

    return {
        type = 6509,
        result = Result.result,
        id = gamedata.ext.HonorwarWeedBet and gamedata.ext.HonorwarWeedBet.id or 1
    }
end

-- 荣耀之战历届冠军查询
function UIHonorWarChampionQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6510, "HonorWarChampionQuery")
    
    if gamedata.cache.HonorWarChampion then
        return 0, 6510, {type = 6510, infodata = gamedata.cache.HonorWarChampion}
    else
        return 1, 6510, nil
    end
end

function NetHonorWarChampionQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6510, "HonorWarChampionQuery")

    local params = params_pb.ParamS()
    params:ParseFromString(fd.rbuf)

    local data = params.params
    local tempdata = {alldata = {},mydata={
        rank = 0,
        name = gamedata.cache.role.name,
        championNum = 0,
    }}
    local arrnum = #data/3

    for i=1,arrnum do
        local temp = {}
        local idx = 3*(i-1)
        temp.rank = i
        temp.rid            = data[idx+2] and data[idx+2].i or 0
        temp.name           = data[idx+2] and data[idx+2].s or ""
        temp.serviceid      = data[idx+1] and data[idx+1].i or 0
        temp.servicename    = data[idx+1] and data[idx+1].s or ""
        temp.championNum    = data[idx+3] and data[idx+3].i or 0

        if temp.rid == gamedata.cache.role.rid then
            tempdata.mydata = temp
        end
        table.insert(tempdata.alldata,temp)
    end

    return { type = 6510, infodata = tempdata}
end

-- 荣耀之战赛区查询
function UIHonorWarGroupInfoQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6511, "HonorWarGroupInfoQuery")

    if gamedata.cache.HonorWarGroupInfo then
        return 0, 6511, {type = 6511, infodata = gamedata.cache.HonorWarGroupInfo}
    else
        return 1, 6511, nil
    end
end

function NetHonorWarGroupInfoQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6511, "HonorWarGroupInfoQuery")
    local params = params_pb.ParamS()
    params:ParseFromString(fd.rbuf)

    local data = params.params
    local tempdata = {mydata={}}
    local teamnum = #data/2

    for i=1,teamnum do
        local idx = 2*(i-1)
        local oneserver = {
            groupid = data[idx+1] and data[idx+1].i or 0,
            serverid = data[idx+2] and data[idx+2].i or 0,
            servername = data[idx+2] and data[idx+2].s or "",
        }

        if not tempdata["group"..oneserver.groupid] then
            tempdata["group"..oneserver.groupid] = {}
        end
        table.insert(tempdata["group"..oneserver.groupid],oneserver)

        if gamedata.selectserver == oneserver.serverid then
            tempdata.mydata = oneserver
        end
    end

    gamedata.cache.HonorWarGroupInfo = tempdata

    return { type = 6511, infodata = tempdata}
end


--荣耀之战上届冠军查询
function UIHonorWarLastChampionQueryCallBack( uireq )
    cclog("NET type:%d cmd:%s recv request from UI", 6513, "HonorWarLastChampionQuery")

    -- if gamedata.cache.HonorWarLastChampion then
    --     return 0, 6513, {type = 6513, HonorWarLastChampion = gamedata.cache.HonorWarLastChampion}
    -- else
        return 1, 6513, nil
    -- end
end

function NetHonorWarLastChampionQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6513, "HonorWarLastChampionQuery")
    local params = params_pb.ParamS()
    params:ParseFromString(fd.rbuf)

    gamedata.cache.HonorWarLastChampion = HonorWarChampionData(params.params) 

    return { type = 6513, HonorWarLastChampion = gamedata.cache.HonorWarLastChampion}
end

--荣耀之战星级排行查询
function UIHonorWarStarRankQueryCallBack( uireq )
    cclog("NET type:%d cmd:%s recv request from UI", 6514, "HonorWarStarRankQuery")
    
    return 1, 6514, nil
end

local function HonorWarStarRank( data,i )
    local data = {
        rank = (i-1)/3 + 1,
        serverid   = data[i].i or 0,
        servername = data[i].s or "",
        rid        = data[i+1].i or 0,
        name       = data[i+1].s or "",
        star       = data[i+2].i or 0,
    }

    if not string.find(data.name,"S"..data.serverid.."-") then
        data.name = "S"..data.serverid.."-"..data.name
    end

    return data
end

function NetHonorWarStarRankQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6514, "HonorWarStarRankQuery")
    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local rankdata = {}
    local mydata = {rank=0,name=gamedata.cache.role.name,star = 0}

    for k,v in ipairs(datas.messages) do
        local params = params_pb.ParamS()
        params:ParseFromString(v.data)
        local data = params.params
        if v.id == 1 then
            if mydata.rank == 0 then
                mydata=HonorWarStarRank(data,1)
                mydata.rank = 0
            end
        else
            for i=1,#data,3 do
                local onedata = HonorWarStarRank(data,i)
                table.insert( rankdata, onedata)
                if onedata.rid == gamedata.cache.role.id 
                    or onedata.rid == gamedata.cache.role.id + gamedata.selectserver*1000000 then
                    mydata = onedata
                end
            end
        end
    end

    mydata.competition = gamedata.cache.HonorWarStatus.competition

    return { type = 6514, rankdata = rankdata,mydata=mydata}
end

--荣耀之战报名
function UIHonorWarSignupCallBack( uireq )
    cclog("NET type:%d cmd:%s recv request from UI", 6515, "HonorWarSignup")

    return 1, 6515, nil
end

function NetHonorWarSignupCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6515, "HonorWarSignup")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    return { type = 6515, result = ids.ids[1]}
end

function UIWeekLivenessCallBack( uireq )
    cclog("NET type:%d cmd:%s recv request from UI", 6516, "WeekLiveness")
    if gamedata.cache.WeekLiveness then
        return 0, 6516, {type = 6516, weekliveness = gamedata.cache.weekliveness}
    else
        return 1, 6516, nil
    end
end

function NetWeekLivenessCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6516, "WeekLiveness")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    gamedata.cache.weekliveness = ids.ids[1] or 0

    return { type = 6516, weekliveness = gamedata.cache.weekliveness}
end

--
--    [6518] = UIAchievementQueryCallBack,
--    [6519] = UIAchievementRewardCallBack,

local tasks_pb = require"tasks_pb"
function UIAchievementQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6518, "AchievementQueryCallBack")

    return 1,6518,nil

end

function NetAchievementQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6518, "AchievementQueryCallBack")
    local taskResponse = tasks_pb.Tasks()
    taskResponse:ParseFromString(fd.rbuf)

    local task = {}
    for k,v in ipairs(taskResponse.tasks) do
        task[tostring(v.cid)] = { cid = v.cid, status = v.status, now = v.now}
    end

    return {type = 6518,task = task}
end

function UIAchievementRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6519, "AchievementRewardCallBack")

    if uireq.id then
        local TaskCompleteData = ids_pb.Ids()
        table.insert(TaskCompleteData.ids,uireq.id)
        return 1, 6519, TaskCompleteData:SerializeToString()
    else
        return 1, 6519, nil
    end
end

function NetAchievementRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6519, "AchievementRewardCallBack")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    return {
        type = 6519,
        reward = gamedata:SomethingProcess(SomeThings)
    }
end


-----------------------------------------------------------------