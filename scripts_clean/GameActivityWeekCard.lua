--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-26
-- Time: 上午10:17
-- To change this template use File | Settings | File Templates.
--
function UIActivityWeekCardQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5801, "WeekCardQuery")

    -- if gamedata.cache.peentoGift and next(gamedata.cache.peentoGift) then
    --     return 0,5401,{type = 5401,data=gamedata.cache.peentoGift}
    -- end

    return 1,5801,nil
end

function NetActivityWeekCardQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5801, "WeekCardQuery")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local weekCard = {}
    weekCard.left = ids.ids[1] or 0
    weekCard.getState = ids.ids[2] or 0

    gamedata.cache.weekCard = weekCard
    return {
        type=5801,
        data=weekCard,
    }
end

function UIActivityWeekCardRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5803, "WeekCardReward")
    if not gamedata.cache.weekCard or not next(gamedata.cache.weekCard) then
        return
    end

    return 1,5803,nil
end


function NetActivityWeekCardRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5803, "WeekCardReward")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    local reward = gamedata:SomethingProcess(SomeThings)
    
    gamedata.cache.weekCard.getState = 2
    return {
        type=5803,
        reward = reward,
        data= gamedata.cache.weekCard,
    }
end

function UIActivityWeekCardActiveCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5802, "WeekCardActive")

    local cost = {cid=uireq.useId,num = -uireq.useNum,name = "激活周卡"}
    gamedata.ext.weekCardCost = cost
    return 1,5802,nil
end

function NetActivityWeekCardActiveCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5802, "WeekCardActive")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    local reward = gamedata:SomethingProcess(SomeThings)
    
    if gamedata.cache.weekCard.getState == 0 and  gamedata.cache.weekCard.left <= 0 then
        gamedata.cache.weekCard.getState = 1
    end
    gamedata.cache.weekCard.left = gamedata.cache.weekCard.left + 7

    gamedata:updateStaff(gamedata.ext.weekCardCost)
    return {
        type=5802,
        reward = reward,
        data= gamedata.cache.weekCard,
    }
end
