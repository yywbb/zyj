--
-- Author: songyibo
-- Date: 2020-06-15 16:46:17
--
local ids_pb = require("ids_pb")
local combmessages_pb = require("combmessages_pb")
local somethings_pb = require("somethings_pb")

function UIDewPoolQueryCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 8055, "DewPoolQuery")
   
    return 1, 8055, nil
end

function NetDewPoolQueryCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8055, "DewPoolQuery")
   
    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local t = {
        achievement = {},
        task = {},
        shop = {},
        props = {
            [192004] = gamedata:getPropNum(192004),
            [192005] = gamedata:getPropNum(192005)
        }
    }
    
    local sortfunc = function (a,b)
        if a.status == b.status then
            return a.order < b.order
        elseif a.status == 1 and b.status ~= 1 then
            return true
        elseif a.status ~= 1 and b.status == 1 then
            return false
        else
            return a.status < b.status
        end
    end

    for k,v in ipairs(datas.messages) do
        if v.id == 1 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            local config = gamedata.config.dew_pool_achievement

            local index = 0
            while ids.ids[index*3 + 1] do
                local type      = ids.ids[index*3 + 1]
                local id        = ids.ids[index*3 + 2]
                local status    = ids.ids[index*3 + 3]
                index = index + 1
                local config = table.copy(gamedata.config.dew_pool_achievement[tostring(type)][tostring(id)])
                config.status = status
                table.insert(t.achievement,config)
            end
            table.sort(t.achievement,sortfunc)

        elseif v.id == 2 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
        	local index = 0
            while ids.ids[index*4 + 1] do
                local type      = ids.ids[index*4 + 1]
                local id        = ids.ids[index*4 + 2]
                local status    = ids.ids[index*4 + 3]
                local now       = ids.ids[index*4 + 4]

                print(type,id,status,now)
                index = index + 1
                local config = table.copy(gamedata.config.dew_pool_task[tostring(type)][tostring(id)])
                config.status = status
                config.now = now
                table.insert(t.task,config)
            end
            table.sort(t.task,sortfunc)

        elseif v.id == 3 then
        	local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)

            for i,v in ipairs(ids.ids) do
            	table.insert(t.shop,{id = i,num = v})
            end
        end
    end
    return { type = 8055, data = t}
end


function UIDewPoolAwardCallback(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8056, "DewPoolAward")
    printT(uireq,"uireq")

    local ids = ids_pb.Ids()
    table.insert(ids.ids, uireq.method)
    table.insert(ids.ids, uireq._type)
    table.insert(ids.ids, uireq.id)

    gamedata.ext.DewPoolAwardInfo = uireq
    return 1, 8056, ids:SerializeToString()
end

function NetDewPoolAwardCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8056, "DewPoolAward")
    
  	local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)


    local unLockTask = 0
    if gamedata.ext.DewPoolAwardInfo.method == 1 then
        
        local _type = gamedata.ext.DewPoolAwardInfo._type
        local id = gamedata.ext.DewPoolAwardInfo.id

        for k1,v1 in pairs(gamedata.config.dew_pool_task) do
            for k2,v2 in pairs(v1) do
                local achievementInfo = gamedata.getIDandNUMs(v2.achievement_id)[1]

                if achievementInfo.cid == _type and achievementInfo.num == id then
                    unLockTask = 1
                    break
                end
            end
            if unLockTask == 1 then
                break
            end
        end

    end

    return {
        type = 8056,
        reward = gamedata:SomethingProcess(SomeThings),
        unLockTask = unLockTask
    }
end

function UIDewPoolExchangeCallback(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8057, "DewPoolExchange")
    printT(uireq,"uireq")

    gamedata.ext.dewPoolExchangeSpend = uireq.spenddata
    local ids = ids_pb.Ids()
    table.insert(ids.ids, uireq.id)
    return 1, 8057, ids:SerializeToString()
end

function NetDewPoolExchangeCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8057, "DewPoolExchange")
    
  	local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    gamedata:updateStaff({cid = gamedata.ext.dewPoolExchangeSpend.cid, num = -gamedata.ext.dewPoolExchangeSpend.num})

    return {
        type = 8057,
        reward = gamedata:SomethingProcess(SomeThings)
    }
end

-- #8140 DewPoolQuery

-- 传入 无
-- 传出 combmessages_pb
-- 	id[1] ids_pb

-- 		ids[status...] (status 0/1/2 未达到/可领取/已领取）

-- 	id[2] tasks_pb

-- 		tasks[(cid、status、now)...] (cid 任务cid) (status -1/0/1/2 未解锁/未达到/可领取/已领取）(now 当前进度）

-- 	id[3] ids_pb

-- 		ids[count...] (count 本周购买次数）


-- #8141 DewPoolAward

-- 传入 ids_pb
-- 	ids[type、id] (type 1/2 成就/任务)

-- 传出 somethings_pb
	
-- #8142 DewPoolExchange

-- 传入 ids_pb
-- 	ids[id]

-- 传出 somethings_pb

