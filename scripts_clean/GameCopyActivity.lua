
-- 活动副本一键完成功能，海外版未开

local copies_pb = require("copies_pb")
local copyattack_pb = require("copyattack_pb")
local battleresult_pb = require("battleresult_pb")
local copyAll3StarAwardPb = require("copyall3starreward_pb")
local copyAll3StarAwardResultPb = require("result_pb")
local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")

require"PickBattleResultReport"

function UIActivityCopyCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1340, "ActivityCopy")
    gamedata.ext.activitycopyTempType = uireq.temp
    return 1, 1340, nil
end

function NetActivityCopyCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1340, "ActivityCopy")
    local activityCopyData = ids_pb.Ids()
    activityCopyData:ParseFromString(fd.rbuf)

    gamedata:activityCopy(activityCopyData)

    return { type = 1340, data = gamedata.cache.copyActivity,temptype = gamedata.ext.activitycopyTempType}
end

function UIActivityCoinCopyCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1341, "ActivityCoinCopy")
    if uireq.id then
    	local activityCoinCopyData = ids_pb.Ids()
    	table.insert(activityCoinCopyData.ids,uireq.id)
        gamedata.ext.activityCoinCopy = {chooseLevel = uireq.id}
    	return 1, 1341, activityCoinCopyData:SerializeToString()
    end   
end

function NetyActivityCoinCopyCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1341, "ActivityCoinCopy")
    local ActivityCoinCopyResultPb = battleresult_pb.BattleResult()
    ActivityCoinCopyResultPb:ParseFromString(fd.rbuf)

    local isfirst = 0
    local pass = 0
    local config = gamedata.config.coin_copy
    for k,v in pairs(gamedata.cache.copyActivity) do
        if v.aid == 2 and v.isFirst == 1 and tonumber(v.openLevel) <table.getTableLength(config) and config[tostring(v.openLevel + 1)].monster_level<=  gamedata.cache.role.level and gamedata.ext.activityCoinCopy.chooseLevel == v.openLevel then
            isfirst = 1
        end
        if ActivityCoinCopyResultPb.result == 1 and v.aid == 2  and tonumber(v.openLevel) <table.getTableLength(config) and config[tostring(v.openLevel + 1)].monster_level<=  gamedata.cache.role.level and gamedata.ext.activityCoinCopy.chooseLevel == v.openLevel then
            v.openLevel = v.openLevel + 1
            v.isFirst = 1
            pass = 1
        elseif v.aid == 2 and gamedata.ext.activityCoinCopy.chooseLevel == v.openLevel then
            v.isFirst = 0
        end   

        if v.aid == 2 then
            v.usedTimes = v.usedTimes + 1
        end   

        if ActivityCoinCopyResultPb.result == 1 and v.aid == 2 and tonumber(gamedata.ext.activityCoinCopy.chooseLevel) > tonumber(v.passLevel) then
            v.passLevel = tonumber(gamedata.ext.activityCoinCopy.chooseLevel)
        end    
        
    end

    local t = {
        type = 1341,
        reward = gamedata:SomethingProcess(ActivityCoinCopyResultPb.reward),
		battlereport = PickBattleResultReport(ActivityCoinCopyResultPb),
		result = ActivityCoinCopyResultPb.result,
        chooseLevel = gamedata.ext.activityCoinCopy.chooseLevel,
        totalround = config[tostring(gamedata.ext.activityCoinCopy.chooseLevel)].battle_times,
        data = gamedata.cache.copyActivity,
        pass = pass,
        isfirst = isfirst,
    }
    return t

end

function UIActivityExpDanCopyCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1342, "ActivityExpDanCopy")
    if uireq.id then
    	local activityExpCopyData = ids_pb.Ids()
    	table.insert(activityExpCopyData.ids,uireq.id)
        gamedata.ext.ActivityExpDanCopy = {chooseLevel = uireq.id}
    	return 1, 1342, activityExpCopyData:SerializeToString()
    end   
end

function NetActivityExpDanCopyCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1342, "ActivityExpDanCopy")
    local ActivityCoinCopyResultPb = battleresult_pb.BattleResult()
    ActivityCoinCopyResultPb:ParseFromString(fd.rbuf)

    local config = gamedata.config.exp_copy
    for k,v in pairs(gamedata.cache.copyActivity) do
        if  v.aid == 1 and  ActivityCoinCopyResultPb.result == 1 and tonumber(v.openLevel ) <table.getTableLength(config) and config[tostring(v.openLevel + 1)].monster_level<=  gamedata.cache.role.level and gamedata.ext.ActivityExpDanCopy.chooseLevel == v.openLevel then
            v.openLevel = v.openLevel + 1
        end
        if ActivityCoinCopyResultPb.result == 1 and v.aid == 1  then
            v.usedTimes = v.usedTimes + 1
        end 
        if ActivityCoinCopyResultPb.result == 1 and v.aid == 1 and tonumber(gamedata.ext.ActivityExpDanCopy.chooseLevel) > tonumber(v.passLevel) then
            v.passLevel = tonumber(gamedata.ext.ActivityExpDanCopy.chooseLevel)
        end           
    end

    local t = {
        type = 1342,
        reward = gamedata:SomethingProcess(ActivityCoinCopyResultPb.reward),
		battlereport = PickBattleResultReport(ActivityCoinCopyResultPb),
		result = ActivityCoinCopyResultPb.result,
        chooseLevel = gamedata.ext.ActivityExpDanCopy.chooseLevel,
        data = gamedata.cache.copyActivity
    }
    return t
end
--锻造石副本挑战
function UIActivityForgeStoneCopyCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1343, "ActivityForgeStoneCopy")
    if uireq.id then
        local activityExpCopyData = ids_pb.Ids()
        table.insert(activityExpCopyData.ids,uireq.id)
        gamedata.ext.ActivityForgeStoneCopy = {chooseLevel = uireq.id}
        return 1, 1343, activityExpCopyData:SerializeToString()
    end 
end

function NetActivityForgeStoneCopyCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1343, "ActivityForgeStoneCopy")
    local ActivityCoinCopyResultPb = battleresult_pb.BattleResult()
    ActivityCoinCopyResultPb:ParseFromString(fd.rbuf)

    local config = gamedata.config.stone_copy
    for k,v in pairs(gamedata.cache.copyActivity) do
        if v.aid == 3 and ActivityCoinCopyResultPb.result == 1 and tonumber(v.openLevel) <table.getTableLength(config) and config[tostring(v.openLevel + 1)].monster_level<=  gamedata.cache.role.level and gamedata.ext.ActivityForgeStoneCopy.chooseLevel == v.openLevel then
            v.openLevel = v.openLevel + 1
        end
        if ActivityCoinCopyResultPb.result == 1 and v.aid == 3  then
            v.usedTimes = v.usedTimes + 1
        end  
        if ActivityCoinCopyResultPb.result == 1 and v.aid == 3 and tonumber(gamedata.ext.ActivityForgeStoneCopy.chooseLevel) > tonumber(v.passLevel) then
            v.passLevel = tonumber(gamedata.ext.ActivityForgeStoneCopy.chooseLevel)
        end        
    end


    local t = {
        type = 1343,
        reward = gamedata:SomethingProcess(ActivityCoinCopyResultPb.reward),
        battlereport = PickBattleResultReport(ActivityCoinCopyResultPb),
        result = ActivityCoinCopyResultPb.result,
        chooseLevel = gamedata.ext.ActivityForgeStoneCopy.chooseLevel,
        data = gamedata.cache.copyActivity
    }
    return t
end

-- todo
function UIActivityEquipStarCopyCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1344, "ActivityEquipStarCopy")
    if uireq.id then
        local activityEquipStarCopyData = ids_pb.Ids()
        table.insert(activityEquipStarCopyData.ids,uireq.id)
        gamedata.ext.activityEquipStarCopyData = {chooseLevel = uireq.id}
        return 1, 1344, activityEquipStarCopyData:SerializeToString()
    end
end

function NetActivityEquipStarCopyCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1344, "ActivityEquipStarCopy")
    local ActivityEquipStarCopyResultPb = battleresult_pb.BattleResult()
    ActivityEquipStarCopyResultPb:ParseFromString(fd.rbuf)

    local isfirst = 0
    local pass = 0
    local config = gamedata.config.upstar_huodong
    for k,v in pairs(gamedata.cache.copyActivity) do
        if v.aid == 4 and v.isFirst == 1 and gamedata.ext.activityEquipStarCopyData.chooseLevel == v.openLevel then
            isfirst = 1
        end
        if v.aid == 4 and ActivityEquipStarCopyResultPb.result == 1 and tonumber(v.openLevel) <table.getTableLength(config) and config[tostring(v.openLevel + 1)].monster_level<=  gamedata.cache.role.level and gamedata.ext.activityEquipStarCopyData.chooseLevel == v.openLevel then
            v.openLevel = v.openLevel + 1
            v.isFirst = 1
            pass = 1
        elseif v.aid == 4 and gamedata.ext.activityEquipStarCopyData.chooseLevel == v.openLevel then
            v.isFirst = 0
        end
        if v.aid == 4  then
            v.usedTimes = v.usedTimes + 1
        end

        if ActivityEquipStarCopyResultPb.result == 1 and v.aid == 4 and tonumber(gamedata.ext.activityEquipStarCopyData.chooseLevel) > tonumber(v.passLevel) then
            v.passLevel = tonumber(gamedata.ext.activityEquipStarCopyData.chooseLevel)
        end    
    end

    local t = {
        type = 1344,
        reward = gamedata:SomethingProcess(ActivityEquipStarCopyResultPb.reward),
        battlereport = PickBattleResultReport(ActivityEquipStarCopyResultPb),
        result = ActivityEquipStarCopyResultPb.result,
        chooseLevel = gamedata.ext.activityEquipStarCopyData.chooseLevel,
        data = gamedata.cache.copyActivity,
        totalround = config[tostring(gamedata.ext.activityEquipStarCopyData.chooseLevel)].battle_times,
        pass = pass,
        isfirst = isfirst,
    }
    return t
end

--
function UIActivityZhenfuCopyCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1345, "ActivityZhenfuCopy")
    if uireq.id then
        local activityZhenfuCopyData = ids_pb.Ids()
        table.insert(activityZhenfuCopyData.ids,uireq.id)
        gamedata.ext.activityZhenfuCopyData = {chooseLevel = uireq.id}
        return 1, 1345, activityZhenfuCopyData:SerializeToString()
    end
end

function NetActivityZhenfuCopyCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1345, "ActivityZhenfuCopy")
    local ActivityZhenfuCopyResultPb = battleresult_pb.BattleResult()
    ActivityZhenfuCopyResultPb:ParseFromString(fd.rbuf)

    local isfirst = 0
    local pass = 0
    local config = gamedata.config.zhenfu_huodong
    for k,v in pairs(gamedata.cache.copyActivity) do
        if v.aid == 5 and v.isFirst == 1 and gamedata.ext.activityZhenfuCopyData.chooseLevel == v.openLevel then
            isfirst = 1
        end
        if v.aid == 5 and ActivityZhenfuCopyResultPb.result == 1 and tonumber(v.openLevel) <table.getTableLength(config) and config[tostring(v.openLevel + 1)].monster_level<=  gamedata.cache.role.level and gamedata.ext.activityZhenfuCopyData.chooseLevel == v.openLevel then
            v.openLevel = v.openLevel + 1
            v.isFirst = 1
            pass = 1
        elseif v.aid == 5 and gamedata.ext.activityZhenfuCopyData.chooseLevel == v.openLevel then
            v.isFirst = 0
        end
        if v.aid == 5  then
            v.usedTimes = v.usedTimes + 1
        end
        if ActivityZhenfuCopyResultPb.result == 1 and v.aid == 5 and tonumber(gamedata.ext.activityZhenfuCopyData.chooseLevel) > tonumber(v.passLevel) then
            v.passLevel = tonumber(gamedata.ext.activityZhenfuCopyData.chooseLevel)
        end   
    end


    local t = {
        type = 1345,
        reward = gamedata:SomethingProcess(ActivityZhenfuCopyResultPb.reward),
        battlereport = PickBattleResultReport(ActivityZhenfuCopyResultPb),
        result = ActivityZhenfuCopyResultPb.result,
        chooseLevel = gamedata.ext.activityZhenfuCopyData.chooseLevel,
        data = gamedata.cache.copyActivity,
        totalround = config[tostring(gamedata.ext.activityZhenfuCopyData.chooseLevel)].battle_times,
        pass = pass,
        isfirst = isfirst,
    }
    return t
end

--    [1347] = UIActivityForgingCopyCallback,
--
function UIActivityForgingCopyCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1347, "ActivityForgingCopyCallback")
    if uireq.id then
        local activityForgingCopyData = ids_pb.Ids()
        table.insert(activityForgingCopyData.ids,uireq.id)
        gamedata.ext.activityForgingCopyData = {chooseLevel = uireq.id}
        return 1, 1347, activityForgingCopyData:SerializeToString()
    end
end

function NetActivityForgingCopyCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1347, "ActivityForgingCopyCallback")
    local ActivityForgingCopyResultPb = battleresult_pb.BattleResult()
    ActivityForgingCopyResultPb:ParseFromString(fd.rbuf)

    local config = gamedata.config.forging_copy
    for k,v in pairs(gamedata.cache.copyActivity) do
        if v.aid == 6 and ActivityForgingCopyResultPb.result == 1 and tonumber(v.openLevel) <table.getTableLength(config) and config[tostring(v.openLevel + 1)].monster_level<=  gamedata.cache.role.level and gamedata.ext.activityForgingCopyData.chooseLevel == v.openLevel then
            v.openLevel = v.openLevel + 1
        end
        if ActivityForgingCopyResultPb.result == 1 and v.aid == 6  then
            v.usedTimes = v.usedTimes + 1
        end
        if ActivityForgingCopyResultPb.result == 1 and v.aid == 6 and tonumber(gamedata.ext.activityForgingCopyData.chooseLevel) > tonumber(v.passLevel) then
            v.passLevel = tonumber(gamedata.ext.activityForgingCopyData.chooseLevel)
        end  
    end


    local t = {
        type = 1347,
        reward = gamedata:SomethingProcess(ActivityForgingCopyResultPb.reward),
        battlereport = PickBattleResultReport(ActivityForgingCopyResultPb),
        result = ActivityForgingCopyResultPb.result,
        chooseLevel = gamedata.ext.activityForgingCopyData.chooseLevel,
        data = gamedata.cache.copyActivity,
    }
    return t
end

--
function UIActivityCopyModUpCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1346, "ActivityCopyModUp")
    local doData = ids_pb.Ids()

    table.insert(doData.ids, uireq.aid)
    table.insert(doData.ids, uireq.id)

    gamedata.ext.ActivityCopyModUpID =  uireq.aid or 0

    return 1, 1346, doData:SerializeToString()
end

function NetActivityCopyModUpCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1346, "ActivityCopyModUp")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    return { type = 1346, reward = gamedata:SomethingProcess(SomeThings), aid = gamedata.ext.ActivityCopyModUpID}
end


function UIActivityOneFinshCopyCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1348, "ActivityOneFinsh")
    printT(uireq,"uireq  ---  ")
    local isRequest = false
    local doData = ids_pb.Ids()
    if uireq.data then
        for k,v in pairs(uireq.data) do
            printT(v,"v --- ")
            if (v.isSelect and v.isSelect == 1) and (v.usenum and v.usenum > 0) and (v.openLevel and v.openLevel ==1) then
                isRequest  = true
                table.insert(doData.ids, v.id)
                table.insert(doData.ids, v.usenum)
            end
        end
    end

    if not not isRequest then
        return 1, 1348, doData:SerializeToString()
    else
        return 0, 1348, {type = 1348}
    end

end

function NetActivityOneFinshCopyCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1348, "ActivityOneFinsh")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    return { type = 1348, reward = gamedata:SomethingProcess(SomeThings)}
end