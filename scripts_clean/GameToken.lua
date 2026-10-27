local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")
local result_pb = require("result_pb")

function UITokenActiveCallBack(uireq)
	cclog("NET type:%d cmd:%s recv request from UI", 8241, "UITokenActiveCallBack")
	
    local _ids = ids_pb.Ids()

    table.insert(_ids.ids, uireq.sid)
    table.insert(_ids.ids, uireq.location)

    gamedata.ext.tokenActiveCost = uireq.cost

    return 1, 8241, _ids:SerializeToString()
end

function NetTokenActiveCallBack(fd)
	cclog("NET type:%d cmd:%s recv response from gameserver", 8241, "NetTokenActiveCallBack")
    local _result = result_pb.Result()
    _result:ParseFromString(fd.rbuf)

    local _cost = gamedata.ext.tokenActiveCost

    for k,v in pairs(_cost) do
        gamedata:updateStaff({cid = v.cid, num = 0 - v.num})
    end

    gamedata.ext.tokenActiveCost = nil

    return {type = 8241, result = _result.result}
end


function UITokenfragmentComposeCallBack(uireq) --碎片合成
	cclog("NET type:%d cmd:%s recv request from UI", 8242, "UITokenfragmentComposeCallBack")

    print(uireq.cid)
    print(uireq.num)
    local _ids = ids_pb.Ids()
    table.insert(_ids.ids, uireq.cid)
    table.insert(_ids.ids, uireq.num)

    local totaluse = uireq.totaluse  --总共消耗的碎片

    gamedata.ext.activitytokenfragmentcompose = {cid = uireq.cid, num = totaluse}

    return 1, 8242, _ids:SerializeToString()
end

function NetTokenfragmentComposeCallBack(fd)
	cclog("NET type:%d cmd:%s recv response from gameserver", 8242, "NetTokenfragmentComposeCallBack")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    local reward = gamedata:SomethingProcess(getData)
    printT(data)

    if gamedata.ext.activitytokenfragmentcompose then
        local cid = gamedata.ext.activitytokenfragmentcompose.cid
        local num = gamedata.ext.activitytokenfragmentcompose.num
        gamedata.cache.props[tonumber(cid)].num = gamedata.cache.props[tonumber(cid)].num - num;
    end    

    gamedata.ext.activitytokenfragmentcompose = nil
    return {type = 8242, reward = reward}
end


function UITokenRecoveryCallBack(uireq) --回收
	cclog("NET type:%d cmd:%s recv request from UI", 8243, "UITokenRecoveryCallBack")
	local _ids = ids_pb.Ids()

    table.insert(_ids.ids, uireq.cid)
    table.insert(_ids.ids, uireq.num)

    gamedata.ext.activitytokenrecovery = {cid = uireq.cid, num = uireq.num}

    return 1, 8243, _ids:SerializeToString()

end

function NetTokenRecoveryCallBack(fd)
	cclog("NET type:%d cmd:%s recv response from gameserver", 8243, "NetTokenRecoveryCallBack")

    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    local reward = gamedata:SomethingProcess(getData)
    printT(data)

    if gamedata.ext.activitytokenrecovery then
        local cid = gamedata.ext.activitytokenrecovery.cid
        local num = gamedata.ext.activitytokenrecovery.num
        gamedata.cache.props[tonumber(cid)].num = gamedata.cache.props[tonumber(cid)].num - num;
    end    
    gamedata.ext.activitytokenrecovery = nil

    return { type = 8243, reward = reward}

end