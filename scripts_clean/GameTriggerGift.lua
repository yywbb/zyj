--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/11/18
-- Time: 11:13
-- To change this template use File | Settings | File Templates.
--

--

local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")

function UITriggerGiftQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4800, "TriggerGiftQuery")

    gamedata.ext.TriggerGiftPushIID = uireq.pushiid or 0

    return 1, 4800, nil

end

function NetTriggerGiftQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4800, "TriggerGiftQuery")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    gamedata:TriggerGift(ids.ids)

    return { type = 4800, triggergift = gamedata.cache.triggergift or {}, pushiid = gamedata.ext.TriggerGiftPushIID or 0}

end

--
function UITriggerGiftRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4801, "TriggerGiftReward")
    local doData = ids_pb.Ids()

    table.insert(doData.ids, uireq.iid)
    gamedata.ext.TriggerGiftId =  uireq.iid
    gamedata.ext.TriggerGiftPrice =  uireq.price or {}

    for k,v in pairs(gamedata.ext.TriggerGiftPrice) do
        if v.cid == 1001 then
            if v.num > gamedata.cache.role.gold then
                return 0,503,{type = 503, msgtype = "shortgold" }
            end
        elseif v.cid == 1000 then
            if v.num > gamedata.cache.role.coin then
                return 0,503,{type = 503, msgtype = "shortcoin" }
            end
        else
            if gamedata.getStaffNum(v.cid).num < v.num then
                return 0,503,{type = 503,msgtype = "shortprop",id= v.cid,num= v.num}
            end
        end
    end

    return 1, 4801, doData:SerializeToString()
end

function NetTriggerGiftRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4801, "TriggerGiftReward")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    if gamedata.ext.TriggerGiftPrice and next(gamedata.ext.TriggerGiftPrice) then
        for k,v in pairs(gamedata.ext.TriggerGiftPrice) do
            gamedata:updateStaff({cid = v.cid,num = 0-v.num})
        end
    end

    return { type = 4801, reward = gamedata:SomethingProcess(SomeThings), iid = gamedata.ext.TriggerGiftId or 0}
end


function NetTriggerGiftPushCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4802, "TriggerGiftPush")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local triggergiftpush = gamedata:SetTriggerGift(ids.ids)

    return { type = 4802, triggergift = gamedata.cache.triggergift or {}, triggergiftpush = triggergiftpush}

end