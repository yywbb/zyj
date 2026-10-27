--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-26
-- Time: 上午10:17
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")
local combmessages_pb = require("combmessages_pb")

function UIActivityZhounianReponse(fd)

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local alldata = gamedata.cache.zhounian2
    alldata.taskreward = nil
    alldata.totalreward = nil

    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            alldata.main = {}
            alldata.main.status = ids.ids[1] or 0
            alldata.main.praystatus = ids.ids[2] or 0
            alldata.main.cid = ids.ids[3] or 0
            alldata.main.luck = ids.ids[4] or 0
            alldata.main.tasktimes = ids.ids[5] or 0
            alldata.main.freshtimes = ids.ids[6] or 0
            alldata.main.randomNum = ids.ids[7] or 0 --随机次数
            alldata.main.randomCid = ids.ids[8] or 0 --随机伙伴
        elseif v.id == 1 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            alldata.tasks = {}
            print("UIActivityZhounianReponse",#ids.ids)
            for i=1,#ids.ids,5 do
                print(i)
                if ids.ids[i] > 0 then
                    table.insert(alldata.tasks,{
                            iid = ids.ids[i],
                            cid = ids.ids[i+1],
                            process = ids.ids[i+2],
                            kind = ids.ids[i+3],
                            status = ids.ids[i+4],
                        })
                end
            end

        elseif v.id == 2 then
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            alldata.taskreward = gamedata:SomethingProcess(SomeThings)
        elseif v.id == 3 then
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            alldata.totalreward = gamedata:SomethingProcess(SomeThings)
        end
    end

    return alldata
end

function UIActivityZhounianRandomCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5309, "ZhounianRandom")
    local count = tonumber(uireq.count)
    local isOne = tonumber(uireq.isOne)
    local length = tonumber(table.getTableLength(gamedata.config.buycount_price))
    
    if count >= length then
        count = length
    end
    print("count = ",count)
    gamedata.ext.randomPrice = 0
    if isOne > 0 then
        gamedata.ext.randomPrice = gamedata.config.buycount_price[tostring(count)].Anniversary_cost
    end
    
    return 1, 5309, nil
end

function NetActivityZhounianRandomCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5309, "ZhounianRandom")
    
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local data = {}
    data.cid = ids.ids[1] or 0
    print("randomPrice = ",gamedata.ext.randomPrice)
    gamedata:updateRoleGold(0-gamedata.ext.randomPrice, "许愿随机消费", 1)

    return {type = 5309, data = data}
end

function UIActivityZhounianQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5310, "ZhounianQuery")

    return 1,5310,nil
end

function NetActivityZhounianQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5310, "ZhounianQuery")
    
    return {
        type=5310,
        data=UIActivityZhounianReponse(fd),
    }
end


function UIActivityZhounianPrayCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5311, "ZhounianPray")

    local ids = ids_pb.Ids()
    table.insert(ids.ids,uireq.cid)

    return 1,5311,ids:SerializeToString()
end

function NetActivityZhounianPrayCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5311, "ZhounianPray")
    
    return {
        type=5311,
        data=UIActivityZhounianReponse(fd),
        ispray = true,
    }
end


function UIActivityZhounianTaskCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5312, "ZhounianTask")

    local ids = ids_pb.Ids()
    table.insert(ids.ids,uireq.id)

    return 1,5312,ids:SerializeToString()
end

function NetActivityZhounianTaskCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5312, "ZhounianTask")
    
    return {
        type=5312,
        data=UIActivityZhounianReponse(fd),
    }
end


function UIActivityZhounianTaskCancelCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5318, "ZhounianTaskCancel")

    local ids = ids_pb.Ids()
    table.insert(ids.ids,uireq.id)

    return 1,5318,ids:SerializeToString()
end

function NetActivityZhounianTaskCancelCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5318, "ZhounianTaskCancel")
    
    return {
        type=5318,
        data=UIActivityZhounianReponse(fd),
    }
end


function UIActivityZhounianTaskGetCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5313, "ZhounianTaskGet")

    local ids = ids_pb.Ids()
    -- table.insert(ids.ids,uireq.id)
    if uireq.rewardData and next(uireq.rewardData) then
        for k,v in pairs(uireq.rewardData) do
            print("v = ",v)
            table.insert(ids.ids, v)
        end
    else
        table.insert(ids.ids, uireq.id)
    end

    return 1,5313,ids:SerializeToString()
end

function NetActivityZhounianTaskGetCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5313, "ZhounianTaskGet")
    
    return {
        type=5313,
        data=UIActivityZhounianReponse(fd),
    }
end


function UIActivityZhounianTaskFreshCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5314, "ZhounianTaskFresh")

    return 1,5314,nil
end

function NetActivityZhounianTaskFreshCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5314, "ZhounianTaskFresh")
    local config = gamedata.config.buycount_price
    local key = "Anniversary_consume"
    local count = gamedata.cache.zhounian2.main.freshtimes+1
    local cost = config[tostring(count)] and config[tostring(count)][key] or config[tostring(table.getTableLength(config))][key]

    gamedata:updateStaff({cid = 1001,num = 0-cost})

    return {
        type=5314,
        data=UIActivityZhounianReponse(fd),
    }
end

-----------------------------------------------------------

function UIActivityChaozhiQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5315, "ChaozhiQuery")

    return 1,5315,nil
end

function NetActivityChaozhiQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5315, "ChaozhiQuery")
    
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local data = {total=0,status = {},times = {}}

    for k,v in ipairs(ids.ids) do

        if k<=3 then
            data.status[k] = v
        else
            data.total = data.total + v
            data.times[k-3] = v
        end
        
    end
    gamedata.cache.activitychaozhi = data

    return {
        type=5315,
        data=gamedata.cache.activitychaozhi,
        pronum = gamedata.cache.props[20580] and gamedata.cache.props[20580].num or 0
    }
end

function UIActivityChaozhiBuyCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5316, "ChaozhiBuy")

    local ids = ids_pb.Ids()
    table.insert(ids.ids,uireq.id)

    gamedata.ext.ChaozhiBuyid = uireq.id

    return 1,5316,ids:SerializeToString()
end

function NetActivityChaozhiBuyCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5316, "ChaozhiBuy")
    
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    local id = gamedata.ext.ChaozhiBuyid
    local data = gamedata.cache.activitychaozhi
    data.times[id] = data.times[id]+1
    data.total = data.total + 1
    

    local rewardconfig = gamedata.config.value_feedback

    for i=1,3 do
        if data.status[i] == 0 and data.total>=rewardconfig[tostring(i)].number then
            data.status[i] = 1
        end
    end

    local pkgconfig = gamedata.config.value_feedback_package[tostring(id)]
    local _,costgold = gamedata.getIDandNUM(pkgconfig.cost)
    local rate = tonumber(gamedata.config.global_kv.Anniversary_vouchers.value)
    local costprop = math.ceil(costgold/rate)

    local hasprop = gamedata.cache.props[20580] and gamedata.cache.props[20580].num or 0
    
    local needprop = math.min(hasprop,costprop)
    gamedata:updateStaff({cid = 20580,num = 0-needprop})

    local needgold = (costprop-needprop)*rate
    gamedata:updateStaff({cid = 1001,num = 0-needgold})

    return {
        type=5316,
        reward=gamedata:SomethingProcess(SomeThings),
        data=data,
        pronum = gamedata.cache.props[20580] and gamedata.cache.props[20580].num or 0
    }
end

function UIActivityChaozhiGetCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5317, "ChaozhiGet")

    local ids = ids_pb.Ids()
    table.insert(ids.ids,uireq.id)

    gamedata.ext.ChaozhiBGetid = uireq.id

    return 1,5317,ids:SerializeToString()
end

function NetActivityChaozhiGetCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5317, "ChaozhiGet")
    
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    local reward = gamedata:SomethingProcess(SomeThings)

    gamedata.cache.activitychaozhi.status[gamedata.ext.ChaozhiBGetid] = 2

    return {
        type=5317,
        reward=reward,
        data = gamedata.cache.activitychaozhi,
        pronum = gamedata.cache.props[20580] and gamedata.cache.props[20580].num or 0
    }
end



