--
-- Author: songyibo
-- Date: 2020-09-08 16:18:42
--
local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")

local function makeIllusionDatas( ... )
    local datas = {}
    for k,v in pairs(table.copy(gamedata.cache.illusion)) do

        local illusion = table.copy(v)
        illusion.order = gamedata.config.illusion[tostring(v.cid)].order
        illusion.tupoLv = 0

        if illusion.generalIid and illusion.generalIid > 0 then
            illusion.general = gamedata.cache.generals[illusion.generalIid]
            illusion.illusionGeneral = 1
        else
            illusion.illusionGeneral = 0
        end

        if illusion.general then
           illusion.tupoLv = illusion.general.level2
        end

        table.insert(datas,illusion)
    end
    
    gamedata.sortData(datas,"illusionGeneral","endtime","tupoLv","order",nil,nil,false,false,false,false)

    return datas
end

function UIIllusionQueryCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8110, "IllusionQuery")

    local ids = ids_pb.Ids()
    table.insert(ids.ids, uireq.update or 0)
    
    if next(gamedata.cache.illusion) and (not uireq.update) then
    	return 0,8110,{ type = 8110,data = makeIllusionDatas()}
    end
    return 1, 8110, ids:SerializeToString()
end

function NetIllusionQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8110, "IllusionQuery")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    gamedata.cache.illusion = {}
    gamedata:illusions(ids.ids)
    
    return { type = 8110,data = makeIllusionDatas()}
end


function UIIllusionExeCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8111, "IllusionExe")
    printT(uireq,"uireq")

    local ids = ids_pb.Ids()
    table.insert(ids.ids, uireq.illusionIid)
    table.insert(ids.ids, uireq.generalIid)

    gamedata.ext.IllusionExeInfo = uireq
    return 1, 8111, ids:SerializeToString()
end

function NetIllusionExeCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8111, "IllusionExe")
    local info = generals_pb.Generals()
    info:ParseFromString(fd.rbuf)
    gamedata:Generals(info.generals)

    local general = gamedata.cache.generals[gamedata.ext.IllusionExeInfo.generalIid]
    local illusionData = gamedata.cache.illusion[gamedata.ext.IllusionExeInfo.illusionIid]
    illusionData.generalIid = general.iid
    return { type = 8111,data = makeIllusionDatas()}
end

function UIIllusionCancelCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8112, "IllusionCancel")
    printT(uireq,"uireq")

    local ids = ids_pb.Ids()
    table.insert(ids.ids, uireq.illusionIid)
    gamedata.ext.IllusionCancelInfo = uireq
    return 1, 8112, ids:SerializeToString()
end

function NetIllusionCancelCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8112, "IllusionCancel")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local general = gamedata.cache.generals[gamedata.ext.IllusionCancelInfo.generalIid]
    general.illusion = {}
    general.illusionGeneralCid = nil
    general.g_fashion = 0

    local illusionData = gamedata.cache.illusion[gamedata.ext.IllusionCancelInfo.illusionIid]
    illusionData.generalIid = 0
    gamedata:Generals({general})
    return { type = 8112,data = makeIllusionDatas()}
end

function UIIllusionActivityQueryCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8113, "IllusionActivityQuery")

    return 1, 8113, nil
end

function NetIllusionActivityQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8113, "IllusionActivityQuery")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local giftdata = {}
    
    for i = 1,#ids.ids/3 do 
        table.insert(giftdata,{id = ids.ids[3*i-2],status = ids.ids[3*i-1],times = ids.ids[3*i]})
    end

    return { type = 8113,giftdata = giftdata}
end

function UIIllusionActivityRewardCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8114, "IllusionActivityReward")
    printT(uireq,"uireq")

    local ids = ids_pb.Ids()
    table.insert(ids.ids, uireq.id or 1)
    return 1, 8114, ids:SerializeToString()
end

function NetIllusionActivityRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8114, "IllusionActivityReward")
    local  getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)
    return { type = 8114,reward = gamedata:SomethingProcess(getData)}
end

function UIIllusionActivityQueryX1CallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8115, "IllusionActivityQuery")

    return 1, 8115, nil
end

function NetIllusionActivityQueryX1CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8115, "IllusionActivityQuery")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local giftdata = {}
    
    for i = 1,#ids.ids/3 do 
        table.insert(giftdata,{id = ids.ids[3*i-2],status = ids.ids[3*i-1],times = ids.ids[3*i]})
    end

    return { type = 8115,giftdata = giftdata}
end

function UIIllusionActivityRewardX1CallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8116, "IllusionActivityReward")
    printT(uireq,"uireq")

    local ids = ids_pb.Ids()
    table.insert(ids.ids, uireq.id or 1)
    return 1, 8116, ids:SerializeToString()
end

function NetIllusionActivityRewardX1CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8116, "IllusionActivityReward")
    local  getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)
    return { type = 8116,reward = gamedata:SomethingProcess(getData)}
end


function UIIllusionActivityTaskQueryCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8117, "IllusionActivityTaskQuery")
    return 1, 8117, nil
end

function NetIllusionActivityTaskQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8117, "IllusionActivityTaskQuery")
    
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    local task = {}
    for i = 1,#ids.ids/3 do 
        table.insert(task,{id = ids.ids[3*i-2],status = ids.ids[3*i-1],now = ids.ids[3*i]})
    end
    return { type = 8117,task = task}
end


function UIIllusionActivityTaskRewardCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8118, "IllusionActivityReward")
    printT(uireq,"uireq")

    gamedata.ext.IllusionActivityTaskRewardInfo = uireq
    local ids = ids_pb.Ids()
    table.insert(ids.ids, uireq.id or 1)
    return 1, 8118, ids:SerializeToString()
end

function NetIllusionActivityTaskRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8118, "IllusionActivityTaskReward")

    if gamedata.ext.IllusionActivityTaskRewardInfo.cost then
        gamedata:updateStaff({cid = gamedata.ext.IllusionActivityTaskRewardInfo.cost.cid, num = -gamedata.ext.IllusionActivityTaskRewardInfo.cost.num})
    end

    local  getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)
    return { type = 8118,reward = gamedata:SomethingProcess(getData)}
end
