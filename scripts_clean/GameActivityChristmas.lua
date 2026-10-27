--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/26
-- Time: 下午7:10
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")
local combmessages_pb = require("combmessages_pb")

-- 商店查询
function UIActivityChristmasQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6601, "ActivityChristmas")

    return 1, 6601, nil
end

function NetActivityChristmasQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6601, "ActivityChristmas")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
   
    local data = {}
    data.propnum = ids.ids[1] or 0
    data.donum = ids.ids[2] or 0
    data.status1 = ids.ids[3] or 0
    data.status2 = ids.ids[4] or 0
    data.status3 = ids.ids[5] or 0
    data.status4 = ids.ids[6] or 0
    data.status5 = ids.ids[7] or 0

   
    return { type = 6601, data = data }
end


-- 奖励
function UIActivityChristmasDoCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6602, "ActivityChristmas")

    return 1, 6602, nil
end

function NetActivityChristmasDoCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6602, "ActivityChristmas")

    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)


    return { type = 6602, reward = gamedata:SomethingProcess(getData)}
end

-- 奖励兑换
function UIActivityChristmasRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6603, "ActivityChristmas")
    local doData = ids_pb.Ids()

    table.insert(doData.ids,uireq.id)

    return 1, 6603, doData:SerializeToString()
end

function NetActivityChristmasRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6603, "ActivityChristmas")

    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    return { type = 6603, reward = gamedata:SomethingProcess(getData)}
end

-- 奖励兑换2
function UIActivityChristmasReward2CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6604, "ActivityChristmas")

    return 1, 6604, nil
end

function NetActivityChristmasReward2CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6604, "ActivityChristmas")

    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    return { type = 6604, reward = gamedata:SomethingProcess(getData)}
end

--
--
function UIActivityHolidayQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6501, "UIActivityHolidayQueryCallBack")

    return 1, 6501, nil
end

function NetActivityHolidayQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6501, "NetActivityHolidayQueryCallBack")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf) 

    local donum = ids.ids[1] or 0
    local status = ids.ids[2] or 0
    local time = ids.ids[3] or 0
   
    return { type = 6501, donum = donum, status = status, time = time}
end


-- 奖励
function UIActivityHolidayDoCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6502, "UIActivityHolidayDoCallBack")

    local doData = ids_pb.Ids()

    table.insert(doData.ids,uireq.id)

    return 1, 6502, doData:SerializeToString()
end

function NetActivityHolidayDoCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6502, "NetActivityHolidayDoCallBack")

    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)


    return { type = 6502, reward = gamedata:SomethingProcess(getData)}
end


--
--timebuy
function UIActivityTimebuyQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6801, "UIActivityTimebuyQueryCallBack")

    return 1, 6801, nil
end

function NetActivityTimebuyQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6801, "NetActivityTimebuyQueryCallBack")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf) 

    local re_gold = ids.ids[1] or 0

    local status = {}
    for i = 1, math.floor((#ids.ids-1)/3) do
        local item = {id = ids.ids[3*(i-1)+2] or 0, num = ids.ids[3*(i-1)+3] or 0, allnum = ids.ids[3*(i-1)+4] or 0}
        status[tostring(item.id)] = item
    end
 
    return { type = 6801, re_gold = re_gold, status = status}
end

function UIActivityTimebuyListCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6802, "UIActivityTimebuyListCallBack")

    return 1, 6802, nil
end

function NetActivityTimebuyListCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6802, "NetActivityTimebuyListCallBack")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf) 

    local list = {}
    for i = 1, math.floor((#ids.ids)/3) do
        local item = {time = ids.ids[3*(i-1)+1] or 0, num = ids.ids[3*(i-1)+2] or 0, id = ids.ids[3*(i-1)+3] or 0}
        table.insert(list,item)
    end
 
    return { type = 6802, list = list}
end



function UIActivityTimebuyRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6803, "UIActivityTimebuyRewardCallBack")

    local isData = ids_pb.Ids()
    table.insert(isData.ids, uireq.id)

    if uireq.gold and (uireq.gold > gamedata.cache.role.gold) then
        return 0,503,{type = 503, msgtype = "shortgold" }
    end

    gamedata.ext.ActivityTimebuyOldGold = uireq.gold or 0

    return 1, 6803, isData:SerializeToString()
end

function NetActivityTimebuyRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6803, "NetActivityTimebuyRewardCallBack")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local gold = 0
    local reward = nil

    for k,v in ipairs(datas.messages) do
        if v.id == 1 then
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            reward = gamedata:SomethingProcess(SomeThings)
        elseif v.id == 2 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gold = ids.ids[1] or 0
        end
    end

    if gold > 0 then
        gamedata:updateRoleGold(0-gold,"限时团购",1)
    end

    return { type = 6803, reward = reward, gold = gold, old_gold = gamedata.ext.ActivityTimebuyOldGold or 0}
end


