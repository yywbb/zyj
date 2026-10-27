--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 16/2/17
-- Time: 上午10:02
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")
local treasuresData = {}


function UIMonthGrowQueryCallBack(uireq)
	cclog("NET type:%d cmd:%s recv response from gameserver", 3680, "ActivityMonthGrowQuery")
	print("发送3680消息")
	if next(gamedata.cache.activityMonthGrowQuery) and not uireq.update then
		return 0, 3680, { type = 3680, data = gamedata.cache.activityMonthGrowQuery, monthcard = gamedata.cache.monthcard, }
	else
		return 1, 3680, nil		
	end

end

function NetMonthGrowQueryCallBack(fd)
	cclog("NET type:%d cmd:%s recv response from gameserver", 3680, "ActivityMonthGrowQuery")
	local ids = ids_pb.Ids()
	ids:ParseFromString(fd.rbuf)

	gamedata:ActivityMonthGrowQuery(ids)
	print("返回3680消息")
	return { type = 3680, data = gamedata.cache.activityMonthGrowQuery, monthcard = gamedata.cache.monthcard, }
end

function UIMonthGrowGetRewardCallBack(uireq)
	cclog("NET type:%d cmd:%s recv response from gameserver", 3681, "ActivityMonthGrowGetReward")
	if uireq.stalls then -- 档位
		local SignInData = ids_pb.Ids()
		table.insert(SignInData.ids, uireq.stalls)
		gamedata.ext.stalls = uireq.stalls

		return 1,  3681, SignInData:SerializeToString()
	else
		return 0, 3681, nil
	end
end

function NetMonthGrowGetRewardCallBack(fd)
	cclog("NET type:%d cmd:%s recv response from gameserver", 3681, "ActivityMonthGrowGetReward")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

	-- gamedata:ActivityMonthGrowGetReward(SomeThings)
	if gamedata.ext.stalls == 1 then
	    gamedata.cache.activityMonthGrowQuery.activationBtnStatus1 = 3
	    gamedata.cache.activityMonthGrowQuery.receiveDay1 = gamedata.cache.activityMonthGrowQuery.receiveDay1 + 1			
	elseif gamedata.ext.stalls == 2 then
	    gamedata.cache.activityMonthGrowQuery.activationBtnStatus2 = 3
	    gamedata.cache.activityMonthGrowQuery.receiveDay2 = gamedata.cache.activityMonthGrowQuery.receiveDay2 + 1
	end
	return { type = 3681, reward = gamedata:SomethingProcess(SomeThings),data = gamedata.cache.activityMonthGrowQuery, }
end

function UIMonthGrowWelfareQueryCallBack(uireq)
	cclog("NET type:%d cmd:%s recv response from gameserver", 3682, "ActivityMonthGrowWelfareQuery")
	print("发送3682消息")
	if next(gamedata.cache.activityMonthGrowGetReward) and not uireq.update then
		return 0, 3682, { type = 3682, data = gamedata.cache.activityMonthGrowGetReward, }
	else
		return 1, 3682, nil
	end	
end

function NetMonthGrowWelfareQueryCallBack(fd)
	cclog("NET type:%d cmd:%s recv response from gameserver", 3682, "ActivityMonthGrowWelfareQuery")
	local ids = ids_pb.Ids()
	ids:ParseFromString(fd.rbuf)

	gamedata:ActivityMonthGrowWelfareQuery(ids)
	print("返回3682消息")
	return { type = 3682, data = gamedata.cache.activityMonthGrowGetReward, }
end

function UIMonthGrowWelfareGetRewardCallBack(uireq)
	cclog("NET type:%d cmd:%s recv response from gameserver", 3683, "ActivityMonthGrowWelfareQuery")
	print("发送3683消息")
	if uireq.receiveId then -- 档位
		local SignInData = ids_pb.Ids()
		table.insert(SignInData.ids, uireq.receiveId)
		gamedata.ext.welfare = uireq.receiveId

		return 1,  3683, SignInData:SerializeToString()
	else
		return 0, 3683, nil
	end
end

function NetMonthGrowWelfareGetRewardCallBack(fd)
	cclog("NET type:%d cmd:%s recv response from gameserver", 3683, "ActivityMonthGrowWelfareQuery")
	print("返回3683消息")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

	-- gamedata:ActivityMonthGrowWelfareQuery(SomeThings)
	if gamedata.ext.welfare == 1 then
	    gamedata.cache.activityMonthGrowGetReward.btnStatus1 = 2
	elseif gamedata.ext.welfare == 2 then
	    gamedata.cache.activityMonthGrowGetReward.btnStatus2 = 2
	end
	return { type = 3683, reward = gamedata:SomethingProcess(SomeThings), data = gamedata.cache.activityMonthGrowGetReward, }
end

--

function UIMonthGrowQueryX1CallBack(uireq)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3684, "ActivityMonthGrowQueryX1")
    print("发送3684消息")
    if next(gamedata.cache.activityMonthGrowQuery) and not uireq.update then
        return 0, 3684, { type = 3684, data = gamedata.cache.activityMonthGrowQuery, monthcard = gamedata.cache.monthcard, }
    else
        return 1, 3684, nil     
    end

end

function NetMonthGrowQueryX1CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3684, "ActivityMonthGrowQueryX1")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    gamedata:ActivityMonthGrowQuery(ids)
    print("返回3684消息")
    return { type = 3684, data = gamedata.cache.activityMonthGrowQuery, monthcard = gamedata.cache.monthcard, }
end

function UIMonthGrowGetRewardX1CallBack(uireq)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3685, "ActivityMonthGrowGetRewardX1")
    if uireq.stalls then -- 档位
        local SignInData = ids_pb.Ids()
        table.insert(SignInData.ids, uireq.stalls)
        gamedata.ext.stalls = uireq.stalls

        return 1,  3685, SignInData:SerializeToString()
    else
        return 0, 3685, nil
    end
end

function NetMonthGrowGetRewardX1CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3685, "ActivityMonthGrowGetRewardX1")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    -- gamedata:ActivityMonthGrowGetReward(SomeThings)
    if gamedata.ext.stalls == 1 then
        gamedata.cache.activityMonthGrowQuery.activationBtnStatus1 = 3
        gamedata.cache.activityMonthGrowQuery.receiveDay1 = gamedata.cache.activityMonthGrowQuery.receiveDay1 + 1           
    elseif gamedata.ext.stalls == 2 then
        gamedata.cache.activityMonthGrowQuery.activationBtnStatus2 = 3
        gamedata.cache.activityMonthGrowQuery.receiveDay2 = gamedata.cache.activityMonthGrowQuery.receiveDay2 + 1
    end
    return { type = 3685, reward = gamedata:SomethingProcess(SomeThings),data = gamedata.cache.activityMonthGrowQuery, }
end

function UIMonthGrowWelfareQueryX1CallBack(uireq)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3686, "ActivityMonthGrowWelfareQueryX1")
    print("发送3686消息")
    if next(gamedata.cache.activityMonthGrowGetReward) and not uireq.update then
        return 0, 3686, { type = 3686, data = gamedata.cache.activityMonthGrowGetReward, }
    else
        return 1, 3686, nil
    end 
end

function NetMonthGrowWelfareQueryX1CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3686, "ActivityMonthGrowWelfareQueryX1")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    gamedata:ActivityMonthGrowWelfareQuery(ids)
    print("返回3686消息")
    return { type = 3686, data = gamedata.cache.activityMonthGrowGetReward, }
end

function UIMonthGrowWelfareGetRewardX1CallBack(uireq)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3687, "ActivityMonthGrowWelfareQueryX1")
    print("发送3687消息")
    if uireq.receiveId then -- 档位
        local SignInData = ids_pb.Ids()
        table.insert(SignInData.ids, uireq.receiveId)
        gamedata.ext.welfare = uireq.receiveId

        return 1,  3687, SignInData:SerializeToString()
    else
        return 0, 3687, nil
    end
end

function NetMonthGrowWelfareGetRewardX1CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3687, "ActivityMonthGrowWelfareQueryX1")
    print("返回3687消息")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    -- gamedata:ActivityMonthGrowWelfareQuery(SomeThings)
    if gamedata.ext.welfare == 1 then
        gamedata.cache.activityMonthGrowGetReward.btnStatus1 = 2
    elseif gamedata.ext.welfare == 2 then
        gamedata.cache.activityMonthGrowGetReward.btnStatus2 = 2
    end
    return { type = 3687, reward = gamedata:SomethingProcess(SomeThings), data = gamedata.cache.activityMonthGrowGetReward, }
end

--
--

function UIMonthGrowQueryX2CallBack(uireq)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5531, "ActivityMonthGrowQueryX2")
    print("发送5531消息")
    if next(gamedata.cache.activityMonthGrowQuery) and not uireq.update then
        return 0, 5531, { type = 5531, data = gamedata.cache.activityMonthGrowQuery, monthcard = gamedata.cache.monthcard, }
    else
        return 1, 5531, nil     
    end

end

function NetMonthGrowQueryX2CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5531, "ActivityMonthGrowQueryX2")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    gamedata:ActivityMonthGrowQuery(ids)
    print("返回5531消息")
    return { type = 5531, data = gamedata.cache.activityMonthGrowQuery, monthcard = gamedata.cache.monthcard, }
end

function UIMonthGrowGetRewardX2CallBack(uireq)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5532, "ActivityMonthGrowGetRewardX2")
    if uireq.stalls then -- 档位
        local SignInData = ids_pb.Ids()
        table.insert(SignInData.ids, uireq.stalls)
        gamedata.ext.stalls = uireq.stalls

        return 1,  5532, SignInData:SerializeToString()
    else
        return 0, 5532, nil
    end
end

function NetMonthGrowGetRewardX2CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5532, "ActivityMonthGrowGetRewardX2")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    -- gamedata:ActivityMonthGrowGetReward(SomeThings)
    if gamedata.ext.stalls == 1 then
        gamedata.cache.activityMonthGrowQuery.activationBtnStatus1 = 3
        gamedata.cache.activityMonthGrowQuery.receiveDay1 = gamedata.cache.activityMonthGrowQuery.receiveDay1 + 1           
    elseif gamedata.ext.stalls == 2 then
        gamedata.cache.activityMonthGrowQuery.activationBtnStatus2 = 3
        gamedata.cache.activityMonthGrowQuery.receiveDay2 = gamedata.cache.activityMonthGrowQuery.receiveDay2 + 1
    end
    return { type = 5532, reward = gamedata:SomethingProcess(SomeThings),data = gamedata.cache.activityMonthGrowQuery, }
end

function UIMonthGrowWelfareQueryX2CallBack(uireq)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5533, "ActivityMonthGrowWelfareQueryX2")
    print("发送5533消息")
    if next(gamedata.cache.activityMonthGrowGetReward) and not uireq.update then
        return 0, 5533, { type = 5533, data = gamedata.cache.activityMonthGrowGetReward, }
    else
        return 1, 5533, nil
    end 
end

function NetMonthGrowWelfareQueryX2CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5533, "ActivityMonthGrowWelfareQueryX2")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    gamedata:ActivityMonthGrowWelfareQuery(ids)
    print("返回5533消息")
    return { type = 5533, data = gamedata.cache.activityMonthGrowGetReward, }
end

function UIMonthGrowWelfareGetRewardX2CallBack(uireq)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5534, "ActivityMonthGrowWelfareQueryX2")
    print("发送5534消息")
    if uireq.receiveId then -- 档位
        local SignInData = ids_pb.Ids()
        table.insert(SignInData.ids, uireq.receiveId)
        gamedata.ext.welfare = uireq.receiveId

        return 1,  5534, SignInData:SerializeToString()
    else
        return 0, 5534, nil
    end
end

function NetMonthGrowWelfareGetRewardX2CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5534, "ActivityMonthGrowWelfareQueryX2")
    print("返回5534消息")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    -- gamedata:ActivityMonthGrowWelfareQuery(SomeThings)
    if gamedata.ext.welfare == 1 then
        gamedata.cache.activityMonthGrowGetReward.btnStatus1 = 2
    elseif gamedata.ext.welfare == 2 then
        gamedata.cache.activityMonthGrowGetReward.btnStatus2 = 2
    end
    return { type = 5534, reward = gamedata:SomethingProcess(SomeThings), data = gamedata.cache.activityMonthGrowGetReward, }
end


--神奇基金
function UIMagicFundQueryCallBack(uireq)
    print("发送 3688 消息")

    return 1, 3688, nil
end

function NetMagicFundQueryCallBack(fd)
    print("返回 3688 消息")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    gamedata:ActivityMonthGrowMagicQuery(ids)
    return { type = 3688, data = gamedata.cache.activityMonthGrowMagicQuery}
end

function UIMagicFundRewardCallBack(uireq)
    print("发送 3689 消息")
	if uireq.stalls then -- 档位
		local SignInData = ids_pb.Ids()
		table.insert(SignInData.ids, uireq.stalls)
		gamedata.ext.sq_stalls = uireq.stalls

		return 1,  3689, SignInData:SerializeToString()
	else
		return 0, 3689, nil
	end
end

function NetMagicFundRewardCallBack(fd)
    print("返回 3689 消息")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

	if gamedata.ext.sq_stalls == 1 then
	    gamedata.cache.activityMonthGrowMagicQuery.btnStatus1 = 2
	    gamedata.cache.activityMonthGrowMagicQuery.receiveDay1 = gamedata.cache.activityMonthGrowMagicQuery.receiveDay1 + 1			
	elseif gamedata.ext.sq_stalls == 2 then
	    gamedata.cache.activityMonthGrowMagicQuery.btnStatus2 = 2
	    gamedata.cache.activityMonthGrowMagicQuery.receiveDay2 = gamedata.cache.activityMonthGrowMagicQuery.receiveDay2 + 1
	end
	return { type = 3689, reward = gamedata:SomethingProcess(SomeThings),data = gamedata.cache.activityMonthGrowMagicQuery, }

end

function UIShareActivityQueryCallBack(uireq)
	cclog("NET type:%d cmd:%s recv response from gameserver", 3690, "ShareActivityQuery")
	print("发送3690消息")
    if next(gamedata.cache.activityShare) and not uireq.update then
        return 0, 3690, {type = 3690, activityShare = gamedata.cache.activityShare}
    else
        return 1, 3690, nil
    end	
end

function NetShareActivityQueryCallBack(fd)
	cclog("NET type:%d cmd:%s recv response from gameserver", 3690, "ShareActivityQuery")
	print("返回3690消息")
    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)

    gamedata:ActivityShare(Result.ids)

    return { type = 3690, activityShare = gamedata.cache.activityShare}
end

function UIShareActivityCallBack(uireq)
	cclog("NET type:%d cmd:%s recv response from gameserver", 3691, "ShareActivity")
	if uireq.receiveId then -- 分享第几个成就
		local SignInData = ids_pb.Ids()
		table.insert(SignInData.ids, uireq.receiveId)
		gamedata.ext.share = uireq.receiveId

		return 1,  3691, SignInData:SerializeToString()
	else
		return 1, 3691, nil
	end
end

function NetShareActivityCallBack(fd)
	cclog("NET type:%d cmd:%s recv response from gameserver", 3691, "ShareActivity")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    -- print("传过来的值", gamedata.ext.share)
    for k,v in pairs(gamedata.cache.activityShare) do
    	if gamedata.ext.share == v.task then
    		v.status = 2
    	end
    end
    -- gamedata.cache.activityShare[gamedata.ext.share].status = 2
	-- gamedata:ActivityMonthGrowWelfareQuery(SomeThings)
	return { type = 3691, reward = gamedata:SomethingProcess(SomeThings), activityShare = gamedata.cache.activityShare, }	
end



local function checkconsum(uireq,configext)

    local _config = gamedata.config["treasure_discount"..configext]
    if configext == "" then
        _config = gamedata.dailyCpActivityConfig("treasure_discount",24)
    end

    local config = _config[tostring(uireq.treasures)]
    local props = gamedata.getIDandNUMs(config.generals) or {}

    for k,v in ipairs(props) do
        local isenough,ret = gamedata.checkStaffEnough(v.cid,v.num)
        if not isenough then
            return ret
        end
    end

    return nil
end

local function checkconsumstatus(uireq,dataext)
    local treasuresStatus = gamedata.cache["activityTreasure"..dataext][uireq.treasures]
    if treasuresStatus.status == -1 then
        return {type = 503, msg = " 已拥有此伙伴，且此伙伴等级超过5级！" }
    elseif treasuresStatus.status == -2 then
        return {type = 503, msg = "已拥有此伙伴，且突破等级超过1级！" }
    elseif treasuresStatus.status == -3 then
        return {type = 503, msg = "已拥有此装备，且等级超过5级！" }
    elseif treasuresStatus.status == -4 then
        return {type = 503, msg = " 已拥有此宝物，且等级超过5级！" }
    elseif treasuresStatus.status == -5 then
        return {type = 503, msg = " 已拥有此宝物，且精炼等级超过1级！" }
    elseif treasuresStatus.status == 0 then
        return {type = 503, msg = "已没有剩余兑换次数！" }
    end
    return nil
end

local function checkconsumstatuscp(uireq,index)
    local treasuresStatus = gamedata.cache["activityTreasureCpX"..index][uireq.treasures]
    if treasuresStatus.status == -1 then
        return {type = 503, msg = " 已拥有此伙伴，且此伙伴等级超过5级！" }
    elseif treasuresStatus.status == -2 then
        return {type = 503, msg = "已拥有此伙伴，且突破等级超过1级！" }
    elseif treasuresStatus.status == -3 then
        return {type = 503, msg = "已拥有此装备，且等级超过5级！" }
    elseif treasuresStatus.status == -4 then
        return {type = 503, msg = " 已拥有此宝物，且等级超过5级！" }
    elseif treasuresStatus.status == -5 then
        return {type = 503, msg = " 已拥有此宝物，且精炼等级超过1级！" }
    elseif treasuresStatus.status == 0 then
        return {type = 503, msg = "已没有剩余兑换次数！" }
    end
    return nil
end

local function checkconsumstatusHeFu(uireq,index)
    local treasuresStatus = gamedata.cache["hefuShopData"..index][uireq.treasures]
    if treasuresStatus.status == -1 then
        return {type = 503, msg = " 已拥有此伙伴，且此伙伴等级超过5级！" }
    elseif treasuresStatus.status == -2 then
        return {type = 503, msg = "已拥有此伙伴，且突破等级超过1级！" }
    elseif treasuresStatus.status == -3 then
        return {type = 503, msg = "已拥有此装备，且等级超过5级！" }
    elseif treasuresStatus.status == -4 then
        return {type = 503, msg = " 已拥有此宝物，且等级超过5级！" }
    elseif treasuresStatus.status == -5 then
        return {type = 503, msg = " 已拥有此宝物，且精炼等级超过1级！" }
    elseif treasuresStatus.status == 0 then
        return {type = 503, msg = "已没有剩余兑换次数！" }
    end
    return nil
end

local equiphaschange = 0
local function updateactivityTreasure(dataext,configext,exchangeCount)
    local _config = gamedata.config["treasure_discount"..configext]
    if configext == "" then
        _config = gamedata.dailyCpActivityConfig("treasure_discount",24)
    end

    local config = _config[tostring(gamedata.ext["treasures"..dataext])]
    for k,v in pairs(gamedata.cache["activityTreasure"..dataext]) do
        if gamedata.ext["treasures"..dataext] == k then
            -- v.num = config.count - v.num - 1
            v.num = v.num + (exchangeCount or 1)
            if v.num >= config.count then
                v.status = 0
                v.num = config.count
            end
        end
    end

    local props = gamedata.getIDandNUMs(config.generals) or {}

    equiphaschange = 0
    for k,v in ipairs(props) do
        gamedata:updateStaff({cid=v.cid,num = 0-v.num * (exchangeCount or 1)})
        if gamedata.IDconfig(v.cid) and gamedata.IDconfig(v.cid).staffType and gamedata.IDconfig(v.cid).staffType == "equip" then
            equiphaschange = 1
        end    
    end
end


local equiphaschangecp = 0
local function updateactivityTreasurecp(index,exchangeCount)
    local _config = gamedata.config:getConfigByName("rank_shop_"..index) or {}
   
    local config = _config[tostring(gamedata.ext["treasuresCpX"..index])]
    for k,v in pairs(gamedata.cache["activityTreasureCpX"..index]) do
        if gamedata.ext["treasuresCpX"..index] == k then
            v.num = v.num + (exchangeCount or 1)
            if v.num >= config.count then
                v.status = 0
                v.num = config.count
            end
        end
    end

    local props = gamedata.getIDandNUMs(config.generals) or {}

    equiphaschangecp = 0
    for k,v in ipairs(props) do
        gamedata:updateStaff({cid=v.cid,num = 0-v.num * (exchangeCount or 1)})
        if gamedata.IDconfig(v.cid) and gamedata.IDconfig(v.cid).staffType and gamedata.IDconfig(v.cid).staffType == "equip" then
            equiphaschangecp = 1
        end    
    end
end


local function addStaffnum(dataext,configext)

    local config = gamedata.config["treasure_discount"..configext]
    if configext == "" then
        config = gamedata.dailyCpActivityConfig("treasure_discount",24)
    end
    

    for k,v in ipairs(gamedata.cache["activityTreasure"..dataext]) do
        local itemconfig = config[tostring(k)]
        local props = gamedata.getIDandNUMs(itemconfig.generals) or {}
        for kk,vv in ipairs(props) do
            v[vv.cid] = gamedata.getStaffNum(vv.cid,true).num
        end
    end

    return gamedata.cache["activityTreasure"..dataext]
end


local function addStaffnumCP(index)

    local config = gamedata.config:getConfigByName("rank_shop_"..index) or {}
    -- printT(gamedata.cache["activityTreasureCpX"..index]," addStaffnumCP")

    for k,v in ipairs(gamedata.cache["activityTreasureCpX"..index]) do
        local itemconfig = config[tostring(k)]
        local props = gamedata.getIDandNUMs(itemconfig.generals) or {}
        for kk,vv in ipairs(props) do
            v[vv.cid] = gamedata.getStaffNum(vv.cid,true).num
        end
    end

    return gamedata.cache["activityTreasureCpX"..index]
end

local function updatehefuShop(index,exchangeCount)
    local _config = gamedata.config:getConfigByName("suit_shop"..index) or {}
   
    local config = _config[tostring(gamedata.ext["treasuresHeFuShop"..index])]
    for k,v in pairs(gamedata.cache["hefuShopData"..index]) do
        if gamedata.ext["treasuresHeFuShop"..index] == k then
            v.num = v.num + (exchangeCount or 1)
            if v.num >= config.count then
                v.status = 0
                v.num = config.count
            end
        end
    end

    local props = gamedata.getIDandNUMs(config.generals) or {}

    equiphaschangecp = 0
    for k,v in ipairs(props) do
        gamedata:updateStaff({cid=v.cid,num = 0-v.num * (exchangeCount or 1)})
        if gamedata.IDconfig(v.cid) and gamedata.IDconfig(v.cid).staffType and gamedata.IDconfig(v.cid).staffType == "equip" then
            equiphaschangecp = 1
        end    
    end
end

local function addhefuShopnum()

    local config = gamedata.config:getConfigByName("suit_shop") or {}
    -- printT(gamedata.cache["activityTreasureCpX"..index]," addStaffnumCP")

    for k,v in ipairs(gamedata.cache["hefuShopData"]) do
        local itemconfig = config[tostring(k)]
        local props = gamedata.getIDandNUMs(itemconfig.generals) or {}
        for kk,vv in ipairs(props) do
            v[vv.cid] = gamedata.getStaffNum(vv.cid,true).num
        end
    end

    return gamedata.cache["hefuShopData"]
end

--
--珍品折扣
function UITitbitDiscountQuryCallBack(uireq)
	cclog("NET type:%d cmd:%s recv response from gameserver", 4010, "treasuresDiscount")
	print("发送4010消息")
--    if next(gamedata.cache.activityTreasure) and not uireq.update then
--        return 0, 4010, {type = 4010, activityTreasure = gamedata.cache.activityTreasure}
--    else
        return 1, 4010, nil
--    end
end

function NetTitbitDiscountQuryCallBack(fd)
	cclog("NET type:%d cmd:%s recv response from gameserver", 4010, "treasuresDiscount")

    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)
	print("返回4010消息")    

    gamedata:ActivityTreasure(Result.ids)

    return { type = 4010, activityTreasure = addStaffnum("","")}
end

function UITitbitDiscountBuyCallBack(uireq)
	cclog("NET type:%d cmd:%s recv response from gameserver", 4011, "treasuresDiscount")

    local ret = checkconsumstatus(uireq,"") or checkconsum(uireq,"")

    if ret then
        return 0,503,ret
    end

    local SignInData = ids_pb.Ids()
    table.insert(SignInData.ids, uireq.treasures)

    table.insert(SignInData.ids, uireq.num or 1)
    gamedata.ext.treasures_num = uireq.num or 1

    gamedata.ext.treasures = uireq.treasures
    return 1,  4011, SignInData:SerializeToString()

end

function NetTitbitDiscountBuyCallBack(fd)
	cclog("NET type:%d cmd:%s recv response from gameserver", 4011, "treasuresDiscount")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    updateactivityTreasure("","",(gamedata.ext.treasures_num or 1))

	return { type = 4011, reward = gamedata:SomethingProcess(SomeThings), activityTreasure = addStaffnum("",""), exchange = true, equiphaschange = equiphaschange}
end

--x1
function UITitbitDiscountX1QuryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4012, "treasuresDiscountX1")
    print("发送4012消息")
    --    if next(gamedata.cache.activityTreasure) and not uireq.update then
    --        return 0, 4012, {type = 4012, activityTreasure = gamedata.cache.activityTreasureX1}
    --    else
    return 1, 4012, nil
    --    end
end

function NetTitbitDiscountX1QuryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4012, "treasuresDiscountX1")

    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)
    print("返回4012消息")

    gamedata:ActivityTreasureX1(Result.ids)

    return { type = 4012, activityTreasure = addStaffnum("X1","_x1")}
end

function UITitbitDiscountX1BuyCallBack(uireq)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4013, "treasuresDiscountX1")
    local ret = checkconsumstatus(uireq,"X1") or checkconsum(uireq,"_x1")

    if ret then
        return 0,503,ret
    end

    local SignInData = ids_pb.Ids()
    table.insert(SignInData.ids, uireq.treasures)

    table.insert(SignInData.ids, uireq.num or 1)
    gamedata.ext.treasuresX1_num = uireq.num or 1

    gamedata.ext.treasuresX1 = uireq.treasures
    return 1,  4013, SignInData:SerializeToString()
end

function NetTitbitDiscountX1BuyCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4013, "treasuresDiscountX1")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    updateactivityTreasure("X1","_x1",(gamedata.ext.treasuresX1_num or 1))

    return { type = 4013, reward = gamedata:SomethingProcess(SomeThings), activityTreasure = addStaffnum("X1","_x1"), exchange = true, equiphaschange = equiphaschange}
end

--X2
function UITitbitDiscountX2QuryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4014, "treasuresDiscountX2")
    print("发送4014消息")
    --    if next(gamedata.cache.activityTreasure) and not uireq.update then
    --        return 0, 4014, {type = 4014, activityTreasure = gamedata.cache.activityTreasureX2}
    --    else
    return 1, 4014, nil
    --    end
end

function NetTitbitDiscountX2QuryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4014, "treasuresDiscountX2")

    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)
    print("返回4014消息")

    gamedata:ActivityTreasureX2(Result.ids)

    return { type = 4014, activityTreasure = addStaffnum("X2","_x2")}
end

function UITitbitDiscountX2BuyCallBack(uireq)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4015, "treasuresDiscountX2")
    local ret = checkconsumstatus(uireq,"X2") or checkconsum(uireq,"_x2")

    if ret then
        return 0,503,ret
    end

    local SignInData = ids_pb.Ids()
    table.insert(SignInData.ids, uireq.treasures)

    table.insert(SignInData.ids, uireq.num or 1)
    gamedata.ext.treasuresX2_num = uireq.num or 1

    gamedata.ext.treasuresX2 = uireq.treasures
    return 1,  4015, SignInData:SerializeToString()
end

function NetTitbitDiscountX2BuyCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4015, "treasuresDiscountX2")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    updateactivityTreasure("X2","_x2",(gamedata.ext.treasuresX2_num or 1))

    return { type = 4015, reward = gamedata:SomethingProcess(SomeThings), activityTreasure = addStaffnum("X2","_x2"), exchange = true, equiphaschange = equiphaschange}
end

--X3
function UITitbitDiscountX3QuryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4016, "treasuresDiscountX3")
    print("发送4016消息")
    --    if next(gamedata.cache.activityTreasure) and not uireq.update then
    --        return 0, 4016, {type = 4016, activityTreasure = gamedata.cache.activityTreasureX3}
    --    else
    return 1, 4016, nil
    --    end
end

function NetTitbitDiscountX3QuryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4016, "treasuresDiscountX3")

    -- local Result = ids_pb.Ids()
    -- Result:ParseFromString(fd.rbuf)
    print("返回4016消息")

    local comdatas = combmessages_pb.CombMessages()
    comdatas:ParseFromString(fd.rbuf)

    local data = {}
    for k,v in ipairs(comdatas.messages) do
        -- print("NetTitbitDiscountX3QuryCallBack",k,v)
        if v.id == 1 then
            local Result = ids_pb.Ids()
            Result:ParseFromString(v.data)
            data[1]= Result.ids
        elseif v.id == 2 then
            local Result = ids_pb.Ids()
            Result:ParseFromString(v.data)
            data[2]= Result.ids
        elseif v.id == 3 then
            local Result = ids_pb.Ids()
            Result:ParseFromString(v.data)
            data[3]= Result.ids
        elseif v.id == 4 then
            local Result = ids_pb.Ids()
            Result:ParseFromString(v.data)
            data[4]= Result.ids
        elseif v.id == 5 then
            local Result = ids_pb.Ids()
            Result:ParseFromString(v.data)
            data[5]= Result.ids
        end

    end    
    gamedata:ActivityTreasureX3(data)
    TresureGameDataRefresh(nil,nil,nil,true)
    local config = gamedata.config.exchange_shop

    for k,v in ipairs(gamedata.cache.activityTreasureX3) do
        if k~=nil and v ~=nil then
            local itemconfig = config[tostring(k)]
            -- printT(itemconfig,"itemconfig")
            if itemconfig ~= nil then
                for i,w in pairs(itemconfig) do
                    -- print(i,"itemconfig")
                    -- printT(w)
                    if w~=nil then
                        local props = gamedata.getIDandNUMs(w.generals) or {}
                        -- printT(props,"props")
                        for kk,vv in ipairs(props) do
                            if vv~=nil then
                                -- printT(vv,"vv")
                                local nums  
                                local types = gamedata.IDconfig(vv.cid).type
                                if types == "treasure" or types == "horse"  then
                                    nums= TresureGameDataRefresh(vv.cid,true,true).num
                                else
                                    nums= gamedata.getStaffNum(vv.cid,false).num
                                end   
                                 -- print("one----cid: "..vv.cid.." num:"..nums)
                                -- printT( gamedata.cache.activityTreasureX3[tonumber(k)][tonumber(i)],"Treasure"..k..i)
                                table.insert(gamedata.cache.activityTreasureX3[tonumber(k)][tonumber(i)],tostring(vv.cid),nums)
                                -- gamedata.cache.activityTreasureX3[tonumber(k)][tonumber(i)][vv.cid] = nums
                            end
                        end
                    end
                end
            end
        end    
    end
     -- printT(gamedata.cache.activityTreasureX3,"addX3Staffnum")
    return { type = 4016, activityTreasure = gamedata.cache.activityTreasureX3 }
    -- return {type = 4016, activityTreasure = {}}
end


--ids [typeid, 物品id] 或 [typeid, 物品id, 购买次数]
function UITitbitDiscountX3BuyCallBack(uireq)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4017, "treasuresDiscountX3")
    -- local ret = checkconsumstatus(uireq,"X3") or checkconsum(uireq,"_x3")
    -- if ret then
    --     return 0,503,ret
    -- end

    local SignInData = ids_pb.Ids()
    table.insert(SignInData.ids,uireq.pageid)
    table.insert(SignInData.ids, uireq.id)
    table.insert(SignInData.ids, uireq.num or 1)

    gamedata.ext.treasuresX3_num = uireq.num or 1
    gamedata.ext.treasuresX3_index = uireq.index or 1
    gamedata.ext.treasuresX3_pageid = uireq.pageid or 1
    gamedata.ext.treasuresX3_goldNum = uireq.goldNum or 0
    -- gamedata.ext.treasuresX3 = uireq.treasures

    return 1,  4017, SignInData:SerializeToString()
end

function NetTitbitDiscountX3BuyCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4017, "treasuresDiscountX3")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    local tresuredata = gamedata.cache.activityTreasureX3[tonumber(gamedata.ext.treasuresX3_pageid)][tonumber(gamedata.ext.treasuresX3_index)]
    tresuredata.num = tresuredata.num + gamedata.ext.treasuresX3_num
    -- print("NetTitbitDiscountX3BuyCallBack :",tresuredata.num)
    gamedata.cache.activityTreasureX3[tonumber(gamedata.ext.treasuresX3_pageid)][tonumber(gamedata.ext.treasuresX3_index)].num = tresuredata.num

    local index = gamedata.ext.treasuresX3_index or  1
    local pageid = gamedata.ext.treasuresX3_pageid or 1

    local config = gamedata.config.exchange_shop[tostring(gamedata.ext.treasuresX3_pageid)][tostring(gamedata.ext.treasuresX3_index)]
    local props = gamedata.getIDandNUMs(config.generals) or {}


    local isrefresh = 0
    local equiphaschange = 0
    local changeTable = {}
    for k,v in ipairs(props) do
        -- 装备
        num = 0-v.num * (gamedata.ext.treasuresX3_num or 1)
        print("cid: "..v.cid.." num:"..num)
        gamedata:updateStaff({cid=v.cid,num = num})
        --宝物
        local  idconfig = gamedata.IDconfig(v.cid)
        -- printT(idconfig,"idconfig")
        if gamedata.IDconfig(v.cid) and gamedata.IDconfig(v.cid).staffType and gamedata.IDconfig(v.cid).staffType == "equip" then
            equiphaschange = 1
        end 
        if gamedata.IDconfig(v.cid) and gamedata.IDconfig(v.cid).type then
           local types = gamedata.IDconfig(v.cid).type
            if types == "horse" or types == "treasure" then
                isrefresh = 1
                print("NetTitbitDiscountX3BuyCallBack --------")
                gamedata:removeEquipsNumBycid(v.cid,num)
            end
        end           
        tresuredata[v.cid] = gamedata.getStaffNum(v.cid,true).num
        table.insert(changeTable,{cid=v.cid,num = tresuredata[v.cid]})
    end

     TresureGameDataRefresh(nil,nil,nil,true)
    local configs = gamedata.config.exchange_shop
      for k,v in ipairs(gamedata.cache.activityTreasureX3) do
        if k~=nil and v ~=nil then
            local itemconfig = configs[tostring(k)]
            if itemconfig ~= nil then
                for i,w in pairs(itemconfig) do
                    if w~=nil then
                        local props = gamedata.getIDandNUMs(w.generals) or {}
                        for kk,vv in ipairs(props) do
                            if vv~=nil then
                                for p,q in pairs(changeTable) do
                                    if vv.cid == q.cid then
                                        local nums  
                                        if isrefresh == 1 then
                                            local types = gamedata.IDconfig(vv.cid).type
                                            if types == "treasure" or types == "horse"  then
                                                nums= TresureGameDataRefresh(vv.cid,true,true).num
                                            else
                                                nums= gamedata.getStaffNum(vv.cid,false).num
                                            end   
                                        else
                                             nums= gamedata.getStaffNum(vv.cid,false).num
                                        end    
                                        print("two----cid: "..vv.cid.." num:"..nums)
                                        table.insert(gamedata.cache.activityTreasureX3[tonumber(k)][tonumber(i)],tostring(vv.cid),nums)
                                    end    
                                end
                               
                            end
                        end
                    end
                end
            end
        end    
    end


    return { type = 4017, reward = gamedata:SomethingProcess(SomeThings), activityTreasure = gamedata.cache.activityTreasureX3, exchange = true, index = index, pageid = pageid,equiphaschange = equiphaschange}

end

function TresureGameDataRefresh(cid,forExchange,iscacheEquip,isreset)
    if isreset then treasuresData = {}  return end
    local num = {cid = cid}
    local config = gamedata.IDconfig(cid)
    if config.staffType == "equip" then
        if forExchange then
            local equipdata
            if iscacheEquip then
               local length = table.getTableLength(treasuresData)
               if length<=0  then
                  equipdata = makeEquipsTemp()  
                  treasuresData = equipdata
               else
                  equipdata = treasuresData
               end 
            else
                equipdata = makeEquipsTemp()  
                treasuresData = {}
            end 

            -- local equipdata = gamedata.cache.equips
            local equipnum = 0
            for k,v in pairs(equipdata) do
                if (cid == v.cid) and (not v.ison or v.ison == 0) and (v.level1 <= 1) and (v.level2 <= 0) and (v.level3 <= 0) and (v.xcount <= 0) then
                    equipnum = equipnum + 1
                end
            end
            num.num = equipnum
        end    
    end   

    return num    
end


--cp
local TitbitDiscount_cpnum = 0
local TitbitDiscount_cpday = 0
function UICPTitbitDiscountQuryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5030, "treasuresDiscount")

    return 1, 5030, nil

end

function NetCPTitbitDiscountQuryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5030, "treasuresDiscount")

    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)

    TitbitDiscount_cpnum = Result.ids[1] or 0
    TitbitDiscount_cpday = Result.ids[2] or 0

    gamedata.cache.activityTreasureCp = {}
    for i = 3, #Result.ids, 2 do
        table.insert(gamedata.cache.activityTreasureCp, {num = Result.ids[i], status = Result.ids[i+1]})
    end

    return { type = 5030, activityTreasure = addStaffnum("Cp",(TitbitDiscount_cpnum > 0) and ("_"..TitbitDiscount_cpnum) or ""), cpnum = TitbitDiscount_cpnum, cpday = TitbitDiscount_cpday}
end

function UICPTitbitDiscountBuyCallBack(uireq)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5031, "treasuresDiscount")

    local ret = checkconsumstatus(uireq,"Cp") or checkconsum(uireq,(TitbitDiscount_cpnum > 0) and ("_"..TitbitDiscount_cpnum) or "")

    if ret then
        return 0,503,ret
    end

    local SignInData = ids_pb.Ids()
    table.insert(SignInData.ids, uireq.treasures)

    table.insert(SignInData.ids, uireq.num or 1)
    gamedata.ext.treasuresCp_num = uireq.num or 1

    gamedata.ext.treasuresCp = uireq.treasures
    return 1,  5031, SignInData:SerializeToString()

end

function NetCPTitbitDiscountBuyCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5031, "treasuresDiscount")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    updateactivityTreasure("Cp",(TitbitDiscount_cpnum > 0) and ("_"..TitbitDiscount_cpnum) or "",(gamedata.ext.treasuresCp_num or 1))

    return { type = 5031, reward = gamedata:SomethingProcess(SomeThings), activityTreasure = addStaffnum("Cp",(TitbitDiscount_cpnum > 0) and ("_"..TitbitDiscount_cpnum) or ""), exchange = true, cpnum = TitbitDiscount_cpnum, cpday = TitbitDiscount_cpday, equiphaschange = equiphaschange}
end



--cp1
function UICPTitbitDiscountX1QuryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4018, "treasuresDiscountX1Query")

    return 1, 4018, nil

end

function NetCPTitbitDiscountX1QuryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4018, "treasuresDiscountX1Query")

    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)

    gamedata.cache.activityTreasureCpX1 = {}
    for i = 1, #Result.ids, 2 do
        table.insert(gamedata.cache.activityTreasureCpX1, {num = Result.ids[i], status = Result.ids[i+1]})
    end

    return { type = 4018, activityTreasure = addStaffnumCP("1")}
end

function UICPTitbitDiscountX1BuyCallBack(uireq)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4019, "treasuresDiscountX1QBuy")

    local ret = checkconsumstatuscp(uireq,"1")

    if ret then
        return 0,503,ret
    end

    local SignInData = ids_pb.Ids()
    table.insert(SignInData.ids, uireq.treasures)

    table.insert(SignInData.ids, uireq.num or 1)
    gamedata.ext.treasuresCp_numX1 = uireq.num or 1

    gamedata.ext.treasuresCpX1 = uireq.treasures
    return 1,  4019, SignInData:SerializeToString()

end

function NetCPTitbitDiscountX1BuyCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4019, "treasuresDiscountX1QBuy")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    updateactivityTreasurecp("1",(gamedata.ext.treasuresCp_numX1 or 1))

    return { type = 4019, reward = gamedata:SomethingProcess(SomeThings), activityTreasure = addStaffnumCP("1"), exchange = true, equiphaschange = equiphaschangecp}
end



--cp2
function UICPTitbitDiscountX2QuryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4020, "treasuresDiscountX2Query")

    return 1, 4020, nil

end

function NetCPTitbitDiscountX2QuryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4020, "treasuresDiscountX2Query")

    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)

    gamedata.cache.activityTreasureCpX2 = {}
    for i = 1, #Result.ids, 2 do
        table.insert(gamedata.cache.activityTreasureCpX2, {num = Result.ids[i], status = Result.ids[i+1]})
    end

    return { type = 4020, activityTreasure = addStaffnumCP("2")}
end

function UICPTitbitDiscountX2BuyCallBack(uireq)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4021, "treasuresDiscountX2QBuy")

    local ret = checkconsumstatuscp(uireq,"2")

    if ret then
        return 0,503,ret
    end

    local SignInData = ids_pb.Ids()
    table.insert(SignInData.ids, uireq.treasures)

    table.insert(SignInData.ids, uireq.num or 1)
    gamedata.ext.treasuresCp_numX2 = uireq.num or 1

    gamedata.ext.treasuresCpX2 = uireq.treasures
    return 1,  4021, SignInData:SerializeToString()

end

function NetCPTitbitDiscountX2BuyCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4021, "treasuresDiscountX2QBuy")


    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    updateactivityTreasurecp("2",(gamedata.ext.treasuresCp_numX2 or 1))


    return { type = 4021, reward = gamedata:SomethingProcess(SomeThings), activityTreasure = addStaffnumCP("2"), exchange = true, equiphaschange = equiphaschangecp}
end



--cp3
function UICPTitbitDiscountX3QuryCallBack(uireq)
    cclog("UI type:%d cmd:%s recv response from gameserver", 4022, "treasuresDiscountX3Query")

    return 1, 4022, nil

end

function NetCPTitbitDiscountX3QuryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4022, "treasuresDiscountX3Query")

    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)

    gamedata.cache.activityTreasureCpX3 = {}
    for i = 1, #Result.ids, 2 do
        table.insert(gamedata.cache.activityTreasureCpX3, {num = Result.ids[i], status = Result.ids[i+1]})
    end

    return { type = 4022, activityTreasure = addStaffnumCP("3")}
end

function UICPTitbitDiscountX3BuyCallBack(uireq)
    cclog("UI type:%d cmd:%s recv response from gameserver", 4023, "treasuresDiscountX3QBuy")

    local ret = checkconsumstatuscp(uireq,"3")

    if ret then
        return 0,503,ret
    end

    local SignInData = ids_pb.Ids()
    table.insert(SignInData.ids, uireq.treasures)

    table.insert(SignInData.ids, uireq.num or 1)
    gamedata.ext.treasuresCp_numX3 = uireq.num or 1

    gamedata.ext.treasuresCpX3 = uireq.treasures
    return 1,  4023, SignInData:SerializeToString()

end

function NetCPTitbitDiscountX3BuyCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4023, "treasuresDiscountX3QBuy")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    updateactivityTreasurecp("3",(gamedata.ext.treasuresCp_numX3 or 1))

    return { type = 4023, reward = gamedata:SomethingProcess(SomeThings), activityTreasure = addStaffnumCP("3"), exchange = true, equiphaschange = equiphaschangecp}
end



--cp4
function UICPTitbitDiscountX4QuryCallBack(uireq)
    cclog("UI type:%d cmd:%s recv response from gameserver", 4024, "treasuresDiscountX4Query")

    return 1, 4024, nil

end

function NetCPTitbitDiscountX4QuryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4024, "treasuresDiscountX4Query")

    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)

    gamedata.cache.activityTreasureCpX4 = {}
    for i = 1, #Result.ids, 2 do
        table.insert(gamedata.cache.activityTreasureCpX4, {num = Result.ids[i], status = Result.ids[i+1]})
    end

    return { type = 4024, activityTreasure = addStaffnumCP("4")}
end

function UICPTitbitDiscountX4BuyCallBack(uireq)
    cclog("UI type:%d cmd:%s recv response from gameserver", 4025, "treasuresDiscountX4QBuy")

    local ret = checkconsumstatuscp(uireq,"4")

    if ret then
        return 0,503,ret
    end

    local SignInData = ids_pb.Ids()
    table.insert(SignInData.ids, uireq.treasures)

    table.insert(SignInData.ids, uireq.num or 1)
    gamedata.ext.treasuresCp_numX4 = uireq.num or 1

    gamedata.ext.treasuresCpX4 = uireq.treasures
    return 1,  4025, SignInData:SerializeToString()

end

function NetCPTitbitDiscountX4BuyCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4025, "treasuresDiscountX4QBuy")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    updateactivityTreasurecp("4",(gamedata.ext.treasuresCp_numX4 or 1))

    return { type = 4025, reward = gamedata:SomethingProcess(SomeThings), activityTreasure = addStaffnumCP("4"), exchange = true, equiphaschange = equiphaschangecp}
end

--cp5
function UICPTitbitDiscountX5QuryCallBack(uireq)
    cclog("UI type:%d cmd:%s recv response from gameserver", 8034, "treasuresDiscountX5Query")

    return 1, 8034, nil

end

function NetCPTitbitDiscountX5QuryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8034, "treasuresDiscountX5Query")

    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)

    gamedata.cache.activityTreasureCpX5 = {}
    for i = 1, #Result.ids, 2 do
        table.insert(gamedata.cache.activityTreasureCpX5, {num = Result.ids[i], status = Result.ids[i+1]})
    end

    return { type = 8034, activityTreasure = addStaffnumCP("5")}
end

function UICPTitbitDiscountX5BuyCallBack(uireq)
    cclog("UI type:%d cmd:%s recv response from gameserver", 8035, "treasuresDiscountX5QBuy")

    local ret = checkconsumstatuscp(uireq,"5")

    if ret then
        return 0,503,ret
    end

    local SignInData = ids_pb.Ids()
    table.insert(SignInData.ids, uireq.treasures)

    table.insert(SignInData.ids, uireq.num or 1)
    gamedata.ext.treasuresCp_numX5 = uireq.num or 1

    gamedata.ext.treasuresCpX5 = uireq.treasures
    return 1,  8035, SignInData:SerializeToString()

end

function NetCPTitbitDiscountX5BuyCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8035, "treasuresDiscountX5QBuy")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    updateactivityTreasurecp("5",(gamedata.ext.treasuresCp_numX5 or 1))

    return { type = 8035, reward = gamedata:SomethingProcess(SomeThings), activityTreasure = addStaffnumCP("5"), exchange = true, equiphaschange = equiphaschangecp}
end

-- 合服商店
function UIHefuShopQuryCallBack(uireq)
	cclog("NET type:%d cmd:%s recv response from gameserver", 8047, "hefuShop")
	print("发送8047消息")
    return 1, 8047, nil
end

function NetHefuShopQuryCallBack(fd)
	cclog("NET type:%d cmd:%s recv response from gameserver", 8047, "hefuShop")

    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)
	print("返回8047消息")    

    local _day = Result.ids[1] - 1
    gamedata.cache.hefuShopData = {}
    for i = 2, #Result.ids, 2 do
        table.insert(gamedata.cache.hefuShopData, {num = Result.ids[i], status = Result.ids[i+1]})
    end

    return { type = 8047, day = _day, activityTreasure = addhefuShopnum()}

end

function UIHefuShopBuyCallBack(uireq)
    cclog("UI type:%d cmd:%s recv response from gameserver", 8048, "HefuShopBuy")

    local ret = checkconsumstatusHeFu(uireq,"")

    if ret then
        return 0,503,ret
    end

    local SignInData = ids_pb.Ids()
    table.insert(SignInData.ids, uireq.treasures)

    table.insert(SignInData.ids, uireq.num or 1)
    gamedata.ext.hefuShop_num = uireq.num or 1

    gamedata.ext.treasuresHeFuShop = uireq.treasures
    return 1,  8048, SignInData:SerializeToString()

end

function NetHefuShopBuyCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8048, "HefuShopBuy")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    updatehefuShop("",(gamedata.ext.hefuShop_num or 1))

    return { type = 8048, reward = gamedata:SomethingProcess(SomeThings), activityTreasure = addhefuShopnum(), exchange = true, equiphaschange = equiphaschangecp}
end

function UITitbitDiscountBuyCallBack(uireq)
	cclog("NET type:%d cmd:%s recv response from gameserver", 4011, "treasuresDiscount")

    local ret = checkconsumstatus(uireq,"") or checkconsum(uireq,"")

    if ret then
        return 0,503,ret
    end

    local SignInData = ids_pb.Ids()
    table.insert(SignInData.ids, uireq.treasures)

    table.insert(SignInData.ids, uireq.num or 1)
    gamedata.ext.treasures_num = uireq.num or 1

    gamedata.ext.treasures = uireq.treasures
    return 1,  4011, SignInData:SerializeToString()

end

function NetTitbitDiscountBuyCallBack(fd)
	cclog("NET type:%d cmd:%s recv response from gameserver", 4011, "treasuresDiscount")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    updateactivityTreasure("","",(gamedata.ext.treasures_num or 1))

	return { type = 4011, reward = gamedata:SomethingProcess(SomeThings), activityTreasure = addStaffnum("",""), exchange = true, equiphaschange = equiphaschange}
end
   e�  