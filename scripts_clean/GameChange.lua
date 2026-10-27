local combmessages_pb = require("combmessages_pb")
local generals_pb = require("generals_pb")
local somethings_pb = require("somethings_pb")
local ids_pb = require("ids_pb")

function UIGeneralChangeCallback(uireq)
	cclog("NET type:%d cmd:%s recv request from UI", 7025, "UIGeneralChangeCallback")

	local _ids = ids_pb.Ids()

    table.insert(_ids.ids, uireq.iid1)
    table.insert(_ids.ids, uireq.iid2)

    gamedata.ext.generalChange = {}
    gamedata.ext.generalChange.iid = uireq.iid1
    gamedata.ext.generalChange.fragementId = uireq.fragementId
    gamedata.ext.generalChange.fragementNum = uireq.fragementNum
    gamedata.ext.generalChange.redfragmentcid = uireq.redfragmentcid
    gamedata.ext.generalChange.redItemNum = uireq.redItemNum
    gamedata.ext.generalChange.gold = uireq.gold

    gamedata.ext.GeneralChangeInfo = {iid1 = uireq.iid1,iid2 = uireq.iid2}
    return 1, 7025, _ids:SerializeToString()
end

function NetGeneralChangeCallback(fd)
	cclog("NET type:%d cmd:%s recv response from gameserver", 7025, "NetGeneralChangeCallback")

	local _combMessage = combmessages_pb.CombMessages()
    _combMessage:ParseFromString(fd.rbuf)
    local _reward
    local _generals

    for k,v in ipairs(_combMessage.messages) do
        if v.id == 1 then
        	local _generals_pb = generals_pb.Generals()
    		_generals_pb:ParseFromString(v.data)
    		_generals = gamedata:Generals(_generals_pb.generals, true)
        elseif v.id == 2 then
            local _somethings_pb = somethings_pb.SomeThings()
    		_somethings_pb:ParseFromString(v.data)
    		_reward = gamedata:SomethingProcess(_somethings_pb)
        end
    end
    
    for i,v in pairs(_generals) do
        if v.iid == gamedata.ext.generalChange.iid then
            _general = v
        end
    end

    if gamedata.ext.generalChange.fragementId and gamedata.ext.generalChange.fragementNum then
        gamedata:updateStaff({cid = gamedata.ext.generalChange.fragementId, num = -gamedata.ext.generalChange.fragementNum})
    end

    if gamedata.ext.generalChange.redfragmentcid and gamedata.ext.generalChange.redItemNum then
        gamedata:updateStaff({cid = gamedata.ext.generalChange.redfragmentcid, num = -gamedata.ext.generalChange.redItemNum})
    end

    if gamedata.ext.generalChange.gold then
        gamedata:updateRoleGold(-gamedata.ext.generalChange.gold, nil, 1)
    end

    gamedata.ext.generalChange = nil

    local illusionGeneral = nil
    if (gamedata.cache.generals[gamedata.ext.GeneralChangeInfo.iid1] and gamedata.cache.generals[gamedata.ext.GeneralChangeInfo.iid1].illusionGeneralCid) or (gamedata.cache.generals[gamedata.ext.GeneralChangeInfo.iid2] and gamedata.cache.generals[gamedata.ext.GeneralChangeInfo.iid2].illusionGeneralCid) then
        illusionGeneral = true
    end

    local updateExclusiveArtifact = nil
    if gamedata.cache.generals[gamedata.ext.GeneralChangeInfo.iid1] and gamedata.cache.generals[gamedata.ext.GeneralChangeInfo.iid1].exclusiveArtifactCid > 0 then
        updateExclusiveArtifact = true
    end

    if gamedata.cache.generals[gamedata.ext.GeneralChangeInfo.iid2] and gamedata.cache.generals[gamedata.ext.GeneralChangeInfo.iid2].exclusiveArtifactCid > 0 then
        updateExclusiveArtifact = true
    end

    return {type = 7025,updateExclusiveArtifact = updateExclusiveArtifact, general = _general, reward = _reward,changeInfo = gamedata.ext.GeneralChangeInfo,illusionGeneral = illusionGeneral}
end

function UISwapChangeCallback(uireq)
	cclog("NET type:%d cmd:%s recv request from UI", 8095, "UISwapChangeCallback")

	local _ids = ids_pb.Ids()

    table.insert(_ids.ids, uireq.iid1)
    table.insert(_ids.ids, uireq.iid2)

    gamedata.ext.swapChange = {}
    gamedata.ext.swapChange.iid1 = uireq.iid1
    gamedata.ext.swapChange.iid2 = uireq.iid2
    gamedata.ext.swapChange.needpropid = uireq.needpropid
    gamedata.ext.swapChange.needpropnum = uireq.needpropnum

    gamedata.ext.SwapChangeInfo = {iid1 = uireq.iid1,iid2 = uireq.iid2}
    return 1, 8095, _ids:SerializeToString()
end

function NetSwapChangeCallback(fd)
	cclog("NET type:%d cmd:%s recv response from gameserver", 8095, "NetSwapChangeCallback")

	local _combMessage = combmessages_pb.CombMessages()
    _combMessage:ParseFromString(fd.rbuf)

    for k,v in ipairs(_combMessage.messages) do
        if v.id == 1 then
        	local _generals_pb = generals_pb.Generals()
    		_generals_pb:ParseFromString(v.data)
            gamedata:Generals(_generals_pb.generals)
        end
    end
    
    local general1 = gamedata.cache.generals[gamedata.ext.swapChange.iid1]
    local general2 = gamedata.cache.generals[gamedata.ext.swapChange.iid2]

    if gamedata.ext.swapChange.needpropid and gamedata.ext.swapChange.needpropnum then
        gamedata:updateStaff({cid = tonumber(gamedata.ext.swapChange.needpropid), num = -gamedata.ext.swapChange.needpropnum})
    end

    gamedata.ext.swapChange = nil

    local updateExclusiveArtifact = nil
    if general1.exclusiveArtifactCid > 0 then
        updateExclusiveArtifact = true
    end

    if general2.exclusiveArtifactCid > 0 then
        updateExclusiveArtifact = true
    end

    return {type = 8095,updateExclusiveArtifact = updateExclusiveArtifact, general = general1, general2 = general2, swapInfo = gamedata.ext.SwapChangeInfo}
end