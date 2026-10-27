--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/1/23
-- Time: 上午10:48
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")


local function maketimebagdata()
 
    local newdata = {}
    for k,v in pairs(gamedata.cache.timebag) do
        if v.status == 1 or (v.status==0 and gamedata:time()<v.recivetime+v.time) then
            v.time = v.time-(gamedata:time()-v.recivetime)
            v.recivetime = gamedata:time()
            table.insert(newdata,v)
        end
    end

    table.sort(newdata,function(a,b)
        return a.cid < b.cid
    end)

    return newdata
end

local function updatabagdata()
    for k,v in pairs(gamedata.cache.timebag or {}) do
        local config = gamedata.config.trigger_gift2[tostring(v.cid)]
        if v.status==0 and gamedata:time()>=(v.recivetime+v.time) then
            if config.update == 1 then
                v.status = -1
            else
                v.status = -2
            end
        end
    end
end

local function recivetimebagdata( data )

    if not gamedata.cache.timebag then
        gamedata.cache.timebag = {}
    end

    local showcid = nil
    for k,v in ipairs(data.ids) do
        if math.mod(k,3) == 1 then
            if v>0 then
                gamedata.cache.timebag[v] = {
                    cid = v,
                    status = data.ids[k+1],-- -2:超时 -1:未触发 0:触发 1:可领 2:已领
                    time = data.ids[k+2],
                    recivetime = gamedata:time()
                }
                showcid = v
            end
        end
    end

    return showcid
end 


function UITimeBagCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2880, "TimeBag")

    gamedata.ext.TimeBagrequireparam = uireq.param

    if gamedata.cache.timebag and next(gamedata.cache.timebag) then
        return 0, 2880, {type = 2880, timebag = maketimebagdata(),param = gamedata.ext.TimeBagrequireparam}
    end
    return 1, 2880, nil
end

function NetTimeBagCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2880, "TimeBag")
    local timebagData = ids_pb.Ids()
    timebagData:ParseFromString(fd.rbuf)

    recivetimebagdata(timebagData)

    return { type = 2880, timebag = maketimebagdata(),param = gamedata.ext.TimeBagrequireparam}
end

-------------------------------------------------------------------------------------------------

function UITimeBagGetCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2881, "TimeBagGet")
    local bagData = ids_pb.Ids()

    table.insert(bagData.ids, uireq.id)

    gamedata.ext.timebaggetiid = uireq.id

    return 1, 2881, bagData:SerializeToString()
end

function NetTimeBagGetCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2881, "TimeBagGet")
    
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    gamedata.cache.timebag[gamedata.ext.timebaggetiid].status = 2

    return { 
        type = 2881, 
        reward = gamedata:SomethingProcess(SomeThings),
        timebag = maketimebagdata(),
    }
end

function UITimeBagTrigCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2882, "TimeBagTrig")
    local bagData = ids_pb.Ids()

    updatabagdata()

    if uireq.opt == 1 then
        for k,v in pairs(gamedata.config.trigger_gift2) do
            if v.type==uireq.opt 
                and tonumber(v.param1)==uireq.sysID 
                and gamedata.cache.role.level>=v.level
                and gamedata.cache.timebag[v.id].status==-1 then
                table.insert(bagData.ids, v.id) 
            end
        end        
    elseif uireq.opt == 2 then
        local nowtime = gamedata:time()
        local servertime = gamedata.cache.role.servertime
        local temp = os.date("*t", servertime)
        timediff = nowtime - (servertime - temp.hour*3600 - temp.min*60 - temp.sec)
        local serverday = math.ceil(timediff/86400)

        for k,v in pairs(gamedata.config.trigger_gift2) do
            if v.type==uireq.opt 
                and serverday >=tonumber(v.param1) 
                and serverday <=tonumber(v.param2) 
                and gamedata.cache.role.level>=v.level 
                and gamedata.cache.timebag[v.id].status==-1 then
                table.insert(bagData.ids, v.id) 
            end
        end          
    elseif uireq.opt == 3 then
        local nowtime = gamedata:time()
        local servertime = gamedata.cache.role.servertime
        local temp = os.date("*t", servertime)
        timediff = nowtime - (servertime - temp.hour*3600 - temp.min*60 - temp.sec)
        local serverday = math.ceil(timediff/86400)

        for k,v in pairs(gamedata.config.trigger_gift2) do
            if v.type==uireq.opt 
                and serverday >=tonumber(v.param1) 
                and serverday <=tonumber(v.param2) 
                and gamedata.cache.role.stamina<tonumber(v.param3)
                and gamedata.cache.role.level>=v.level 
                and gamedata.cache.timebag[v.id].status==-1 then
                table.insert(bagData.ids, v.id) 
            end
        end     
    end

    gamedata.ext.BagTrigparam = uireq.param

    if #bagData.ids > 0 then
        return 1, 2882, bagData:SerializeToString()
    else
        return 0, 2882, { type = 2882,param = gamedata.ext.BagTrigparam}
    end
end

function NetTimeBagTrigCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2882, "TimeBagTrig")
    
    local timebagData = ids_pb.Ids()
    timebagData:ParseFromString(fd.rbuf)

    local showcid = recivetimebagdata(timebagData)

    return { type = 2882, timebag = maketimebagdata(),showcid=showcid,param = gamedata.ext.BagTrigparam}
end

function UITimeBagTimeOverCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 28801, "TimeBagGet")

    gamedata.cache.timebag[uireq.id].status = -2

    return 0, 28801, {type = 28801, timebag = maketimebagdata()}
end

