--
-- Author: yxf
-- Date: 2019-03-21 11:15:41
--

local ids_pb = require("ids_pb")
local combmessages_pb = require("combmessages_pb")
local battleresult_pb = require("battleresult_pb")
local somethings_pb = require("somethings_pb")


---------------------------特惠礼包1--------------------------

function UIDisscountGiftQueryCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8020, "DisscountGiftQuery")
  
    return 1, 8020, nil

end

function NetDisscountGiftQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8020, "DisscountGiftQuery")
    
    local t = {
        type = 8020,
    }
    t.giftdata = {}
    
    local  ids = ids_pb.Ids();
    ids:ParseFromString(fd.rbuf)
    print("length:"..#ids.ids)
    for i = 1,#ids.ids/3 do 
        table.insert(t.giftdata,{id = ids.ids[3*i-2],status = ids.ids[3*i-1],times = ids.ids[3*i]})
    end
    printT(t,"NetDisscountGiftQueryCallBack")
    return t
end


function UIDisscountGiftRewardCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8021, "DisscountGiftReward")
  
    local idsData = ids_pb.Ids()

    table.insert(idsData.ids, uireq.id or 1)
    print("UISpeedGiftRewardCallBack id:"..uireq.id)
    return 1, 8021, idsData:SerializeToString()
end


function NetDisscountGiftRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8021, "DisscountGiftReward")
    
    local t = {
        type = 8021,
    }

    local  getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    t.reward = gamedata:SomethingProcess(getData)

    printT(t,"NetDisscountGiftRewardCallBack")

    return t
end



---------------------------特惠礼包2--------------------------

function UIDisscountGiftQueryCallBack2(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8022, "DisscountGiftQuery2")
  
    return 1, 8022, nil

end

function NetDisscountGiftQueryCallBack2(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8022, "DisscountGiftQuery2")
    
    local t = {
        type = 8022,
        day = 1,
    }
    t.giftdata = {}
    
    local  ids = ids_pb.Ids();
    ids:ParseFromString(fd.rbuf)
    print("length:"..#ids.ids)
    t.day = ids.ids[1]
    local gdata = {}
    for i=2,#ids.ids do
        table.insert(gdata,ids.ids[i])
    end
    printT(gdata,"jkp-gdata")
    for i = 1,#gdata/3 do 
        table.insert(t.giftdata,{id = gdata[3*i-2],status = gdata[3*i-1],times = gdata[3*i]})
    end
    printT(t,"NetDisscountGiftQueryCallBack")
    return t
end


function UIDisscountGiftRewardCallBack2(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8023, "DisscountGiftReward2")
  
    local idsData = ids_pb.Ids()

    table.insert(idsData.ids, uireq.id or 1)
    print("UISpeedGiftRewardCallBack id:"..uireq.id)
    return 1, 8023, idsData:SerializeToString()
end


function NetDisscountGiftRewardCallBack2(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8023, "DisscountGiftReward2")
    
    local t = {
        type = 8023,
    }

    local  getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    t.reward = gamedata:SomethingProcess(getData)

    printT(t,"NetDisscountGiftRewardCallBack")

    return t
end

---------------------------特惠礼包3--------------------------

function UIDisscountGiftQueryCallBack3(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8024, "DisscountGiftQuery3")
  
    return 1, 8024, nil

end

function NetDisscountGiftQueryCallBack3(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8024, "DisscountGiftQuery3")
    
    local t = {
        type = 8024,
    }
    t.giftdata = {}
    
    local  ids = ids_pb.Ids();
    ids:ParseFromString(fd.rbuf)
    print("length:"..#ids.ids)
    for i = 1,#ids.ids/3 do 
        table.insert(t.giftdata,{id = ids.ids[3*i-2],status = ids.ids[3*i-1],times = ids.ids[3*i]})
    end
    printT(t,"NetDisscountGiftQueryCallBack")
    return t
end


function UIDisscountGiftRewardCallBack3(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8025, "DisscountGiftReward3")
  
    local idsData = ids_pb.Ids()

    table.insert(idsData.ids, uireq.id or 1)
    print("UISpeedGiftRewardCallBack id:"..uireq.id)
    return 1, 8025, idsData:SerializeToString()
end


function NetDisscountGiftRewardCallBack3(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8025, "DisscountGiftReward3")
    
    local t = {
        type = 8025,
    }

    local  getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    t.reward = gamedata:SomethingProcess(getData)

    printT(t,"NetDisscountGiftRewardCallBack")

    return t
end



---------------------------加速礼包1--------------------------

function UISpeedGiftQueryCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8026, "SpeedGiftQuery")
    gamedata.ext.speedGift_ReqType = uireq.param
    return 1, 8026, nil

end

function NetSpeedGiftQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8026, "SpeedGiftQuery")
    
    local t = {
        type = 8026,
        requireType = gamedata.ext.speedGift_ReqType
    }
    t.giftdata = {}
    
    local  ids = ids_pb.Ids();
    ids:ParseFromString(fd.rbuf)
    print("length:"..#ids.ids)
    for i = 1,#ids.ids/3 do 
        table.insert(t.giftdata,{id = ids.ids[3*i-2],status = ids.ids[3*i-1],times = ids.ids[3*i]})
    end
    printT(t,"NetSpeedGiftQueryCallBack")
    return t
end


function UISpeedGiftRewardCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8027, "SpeedGiftReward")
  
    local idsData = ids_pb.Ids()

    table.insert(idsData.ids, uireq.id or 1)
    print("UISpeedGiftRewardCallBack id:"..uireq.id)
    return 1, 8027, idsData:SerializeToString()
end


function NetSpeedGiftRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8027, "SpeedGiftReward")
    
    local t = {
        type = 8027,
    }

    local  getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    t.reward = gamedata:SomethingProcess(getData)

    printT(t,"NetSpeedGiftRewardCallBack")

    return t
end


---------------------------加速礼包2--------------------------

function UISpeedGiftQueryCallBack2(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8028, "SpeedGiftQuery2")
    gamedata.ext.speedGift_ReqType = uireq.param
    return 1, 8028, nil

end

function NetSpeedGiftQueryCallBack2(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8028, "SpeedGiftQuery2")
    
    local t = {
        type = 8028,
        requireType = gamedata.ext.speedGift_ReqType
    }
    t.giftdata = {}
    
    local  ids = ids_pb.Ids();
    ids:ParseFromString(fd.rbuf)
    print("length:"..#ids.ids)
    for i = 1,#ids.ids/3 do 
        table.insert(t.giftdata,{id = ids.ids[3*i-2],status = ids.ids[3*i-1],times = ids.ids[3*i]})
    end
    printT(t,"NetSpeedGiftQueryCallBack2")
    return t
end


function UISpeedGiftRewardCallBack2(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8029, "SpeedGiftReward2")
  
    local idsData = ids_pb.Ids()

    table.insert(idsData.ids, uireq.id or 1)
    print("UISpeedGiftRewardCallBack3 id:"..uireq.id)
    return 1, 8029, idsData:SerializeToString()
end


function NetSpeedGiftRewardCallBack2(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8029, "SpeedGiftReward2")
    
    local t = {
        type = 8029,
    }

    local  getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    t.reward = gamedata:SomethingProcess(getData)

    printT(t,"NetSpeedGiftRewardCallBack2")

    return t
end


---------------------------加速礼包3--------------------------

function UISpeedGiftQueryCallBack3(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8032, "SpeedGiftQuery3")
    gamedata.ext.speedGift_ReqType = uireq.param
    return 1, 8032, nil

end

function NetSpeedGiftQueryCallBack3(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8032, "SpeedGiftQuery3")
    
    local t = {
        type = 8032,
        requireType = gamedata.ext.speedGift_ReqType
    }
    t.giftdata = {}
    
    local  ids = ids_pb.Ids();
    ids:ParseFromString(fd.rbuf)
    print("length:"..#ids.ids)
    for i = 1,#ids.ids/3 do 
        table.insert(t.giftdata,{id = ids.ids[3*i-2],status = ids.ids[3*i-1],times = ids.ids[3*i]})
    end
    printT(t,"NetSpeedGiftQueryCallBack3")
    return t
end


function UISpeedGiftRewardCallBack3(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8033, "SpeedGiftReward3")
  
    local idsData = ids_pb.Ids()

    table.insert(idsData.ids, uireq.id or 1)
    print("UISpeedGiftRewardCallBack3 id:"..uireq.id)
    return 1, 8033, idsData:SerializeToString()
end


function NetSpeedGiftRewardCallBack3(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8033, "SpeedGiftReward3")
    
    local t = {
        type = 8033,
    }

    local  getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    t.reward = gamedata:SomethingProcess(getData)

    printT(t,"NetSpeedGiftRewardCallBack3")

    return t
end

---------------------------合服礼包--------------------------

function UIHefuGiftQuryCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8045, "HefuGiftQury")
  
    return 1, 8045, nil

end

function NetHefuGiftQuryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8045, "HefuGiftQury")
    
    local t = {
        type = 8045,
        day = 1,
    }
    t.giftdata = {}
    
    local  ids = ids_pb.Ids();
    ids:ParseFromString(fd.rbuf)
    print("length:"..#ids.ids)
    t.day = ids.ids[1]
    local gdata = {}
    for i=2,#ids.ids do
        table.insert(gdata,ids.ids[i])
    end
    printT(gdata,"jkp-gdata")
    for i = 1,#gdata/3 do 
        table.insert(t.giftdata,{id = gdata[3*i-2],status = gdata[3*i-1],times = gdata[3*i]})
    end
    printT(t,"NetHefuGiftQuryCallBack")
    return t
end


function UIHefuGiftBuyCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8046, "HefuGiftBuy")
  
    local idsData = ids_pb.Ids()

    table.insert(idsData.ids, uireq.id or 1)
    print("HefuGiftBuy id:"..uireq.id)
    return 1, 8046, idsData:SerializeToString()
end


function NetHefuGiftBuyCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8046, "HefuGiftBuy")
    
    local t = {
        type = 8046,
    }

    local  getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    t.reward = gamedata:SomethingProcess(getData)

    printT(t,"HefuGiftBuy")

    return t
end

  n+  