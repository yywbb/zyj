local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")
local combmessages_pb = require("combmessages_pb")
local battleresult_pb = require("battleresult_pb")
require "PickBattleResultReport"
-- 道馆守卫 消息协议

-- 5301 打开页面 查询
function UIDaoGuanMainCallBack( uireq )
    cclog("UI type:%d cmd:%s recv request from UI", 5301, "UIDaoGuanMainCallBack")

    return 1, 5301, nil
end

function NetDaoGuanMainCallBack( fd )
    cclog("NET type:%d cmd:%s recv request from UI", 5301, "NetDaoGuanMainCallBack")
    local combMessage = combmessages_pb.CombMessages()
    combMessage:ParseFromString(fd.rbuf)

    local main = {list = {},rewardstatus = 0}
    local players = {}
    for k,v in ipairs(combMessage.messages) do
        if v.id == 1 then
            print("gggggggg1")
            -- 徽章数量及奖励状态
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)

            for i = 1, #ids.ids - 3 do
                main.list[i] = ids.ids[i] or 0
            end
                
            main.rewardstatus = ids.ids[#ids.ids - 2] or 0
            main.times = ids.ids[#ids.ids - 1] or 0
            main.laststatus = ids.ids[#ids.ids] or 0
        elseif v.id == 2 then
            local playersData = players_pb.Players()
            playersData:ParseFromString(v.data)
            players = gamedata:players(playersData.players)
        else
            cclog("GameDaoGuan NetDaoGuanGoToCallBack v.id = %d is wrong.", v.id)
        end
    end

    gamedata.cache.DaoGuandata = main

    return { type = 5301, maindata = main, players = players}
end

-- 5302 领取徽章奖励
function UIDaoGuanGetRewardCallBack( uireq )
    cclog("UI type:%d cmd:%s recv request from UI", 5302, "UIDaoGuanGetRewardCallBack")

    return 1, 5302, nil
end

function NetDaoGuanGetRewardCallBack( fd )
	cclog("NET type:%d cmd:%s recv request from UI", 5302, "NetDaoGuanGetRewardCallBack")
   	local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    gamedata.cache.DaoGuandata.rewardstatus = 2 

    return { type = 5302,  maindata = gamedata.cache.DaoGuandata,reward = gamedata:SomethingProcess(getData)}
end

-- 5303 进入道馆 道馆id
function UIDaoGuanGoToCallBack( uireq )
    cclog("UI type:%d cmd:%s recv request from UI", 5303, "UIDaoGuanGoToCallBack")
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.id)

    return 1, 5303, idsData:SerializeToString()
end

-- out combmessages players 加扩展翅膀 跟过关斩将有点类似
function NetDaoGuanGoToCallBack( fd )
    cclog("NET type:%d cmd:%s recv request from UI", 5303, "NetDaoGuanGoToCallBack")

    local players = {}
    local combMessage = combmessages_pb.CombMessages()
    combMessage:ParseFromString(fd.rbuf)
    local count = -1

    local cando = false
    for k,v in ipairs(gamedata.cache.DaoGuandata.list) do
        if v>0 then 
            cando = true
            break
        end
    end 

    for k,v in ipairs(combMessage.messages) do
    	if v.id == 1 then
            -- 剩余挑战次数
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            count = ids.ids[1]
            gamedata.cache.DaoGuandata.times = count
		elseif v.id == 2 then
            local playersData = players_pb.Players()
            playersData:ParseFromString(v.data)
            players = gamedata:players(playersData.players)
        else
            cclog("GameDaoGuan NetDaoGuanGoToCallBack v.id = %d is wrong.", v.id)
    	end
    end

    return { 
        type = 5303, 
        players = players, 
        count = count, 
        rid = gamedata.cache.role.id,
        cando = cando,
        laststatus = gamedata.cache.DaoGuandata.laststatus
    }
end

-- 5304 挑战  道馆id 和成员位置
function UIDaoGuanDareCallBack( uireq )
    cclog("UI type:%d cmd:%s recv request from UI", 5304, "UIDaoGuanDareCallBack")
    local idsData = ids_pb.Ids()

    table.insert(idsData.ids, uireq.id)
    table.insert(idsData.ids, uireq.position)
    gamedata.ext.daoguanId = uireq.id
    gamedata.ext.DarePosition = uireq.position
    
    for i = 1, 7 do
        table.insert(idsData.ids, uireq.generalsSelf[tostring(i)].iid)
    end

    table.insert(idsData.ids, uireq.pet)

    return 1, 5304, idsData:SerializeToString()
end

-- 切到战斗。如果玩家变化了给提示
function NetDaoGuanDareCallBack( fd )
    cclog("NET type:%d cmd:%s recv request from UI", 5304, "NetDaoGuanDareCallBack")

    local NetOverPassResultPb = battleresult_pb.BattleResult()
    NetOverPassResultPb:ParseFromString(fd.rbuf)

    local tip = ""
    if gamedata.cache.DaoGuandata.list[gamedata.ext.daoguanId]<=0 then
        tip = "metal"
    elseif gamedata.ext.DarePosition == 1 then
        tip = "leader"
    else
        tip = "member"
    end

    return {
        type = 5304,
        id = gamedata.ext.daoguanId,
        tip = tip,
        result = NetOverPassResultPb.result,
        reward = gamedata:SomethingProcess(NetOverPassResultPb.reward),
        battlereport = PickBattleResultReport(NetOverPassResultPb),
    }
end

-- 5305 战报查看 
function UIDaoGuanFightNoteCallBack( uireq )
    cclog("UI type:%d cmd:%s recv request from UI", 5305, "UIDaoGuanFightNoteCallBack")
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.id)
    return 1, 5305, idsData:SerializeToString()
end

function NetDaoGuanFightNoteCallBack( fd )
    cclog("NET type:%d cmd:%s recv request from UI", 5305, "NetDaoGuanFightNoteCallBack")

    local params = params_pb.ParamS()
    params:ParseFromString(fd.rbuf)
    
    local _sysList = {}
    local _playerList = {}

    for i = 1, #params.params do
        local _obj = params.params[i].s

        -- 前20条是系统，后20条是个人。
        if i <= 20 then
            table.insert(_sysList, _obj)
        elseif i > 20 then
            table.insert(_playerList, _obj)
        end
    end

    -- isGetReward 是否领取奖励，0表示不能领1标识可以领2标识已领取
    return { type = 5305, systemData = _sysList, playerData = _playerList}
end

-- 挑战布阵
function UIDaoGuanArrangeQuaryCallback(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 5306, "UIDaoGuanArrangeQuaryCallback")
    printT(uireq)

    if gamedata.cache.DaoGuandata.times<=0 then
        return 0,5306,{type = 5306,needtimes = true}
    end
    
    gamedata.ext.daoguanId = uireq.id or 0
    gamedata.ext.daoguanPosition = uireq.position or 0

    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.id)
    table.insert(idsData.ids, uireq.position or 0)

    return 1, 5306, idsData:SerializeToString()
end

function NetDaoGuanArrangeQuaryCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5306, "NetDaoGuanArrangeQuaryCallback")
    local idsData = ids_pb.Ids()
    idsData:ParseFromString(fd.rbuf)

    local slots = { generalsSelf = {}, generalsOpponent = {}, oldcid = {} }
    
    local gnum = 0
    local onum = 0
    for k,v in ipairs(idsData.ids) do
        if k > 0 and k <= 7 then
            slots.generalsSelf[k] = {iid = v, cid = 0}

            if v == gamedata.cache.protagonist.iid then
                slots.generalsSelf[k].cid = gamedata.cache.protagonist.general.cid
            else
                if gamedata.cache.generals[v] then
                    if gamedata:illusionsLimite("l_pvp") then
                        slots.generalsSelf[k].cid = gamedata.cache.generals[v].illusionGeneralCid or gamedata.cache.generals[v].cid
                    else
                        slots.generalsSelf[k].cid = gamedata.cache.generals[v].cid
                    end
                else
                    print("generals %d is null.", v)
                end
            end
        elseif k == 8 then
            slots.pet = v
        elseif k == 9 then
            slots.power = v
        elseif k > 9 and k <= 23 then
            local num = k%2
            if num == 0 then
                gnum = gnum + 1
                slots.generalsOpponent[gnum] = v
            else
                onum = onum + 1
                slots.oldcid[onum] = v
            end
        elseif k == 24 then
            slots.opponentID = v
        else
            print("gamedata CommonSlotsDaoGuan key is wrong.")
        end
    end

    return {type = 5306, slots = slots, id = gamedata.ext.daoguanId, position = gamedata.ext.daoguanPosition}
end