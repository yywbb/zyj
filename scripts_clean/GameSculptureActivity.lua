--
-- Author: songyibo
-- Date: 2021-03-01 15:20:13
--
local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")
local combmessages_pb = require("combmessages_pb")
local params_pb = require("params_pb")

local function getSculptureProps()
    local props  = {
            [192083]    = gamedata.getStaffNum(192083).num or 0,
            [1001]      = gamedata.getStaffNum(1001).num or 0,
        }
    return props
end

function UISculptureActivityQueryCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8130, "SculptureActivityQuery")
    return 1, 8130, nil
end

function NetSculptureActivityQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8130, "SculptureActivityQuery")

    local t = {
    	active 			= 0,		--激活状态
    	level       	= 0,
    	exp         	= 0,
        picId           = 0,
    	reward 	        = {},
    	daily		    = {},
    	challenge	    = {},
    	shop 		    = {},
        props           = getSculptureProps()
	}


    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    for k,v in ipairs(datas.messages) do
        print("SculptureActivityQuery",v.id)
    	if v.id == 0 then

            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            t.active 	= ids.ids[1] or 0
            t.level 	= ids.ids[2] or 0
            t.exp 		= ids.ids[3] or 0
            t.picId     = ids.ids[4] or 0

        elseif v.id == 1 then

        	local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            for i,v in ipairs(ids.ids) do
            	table.insert(t.reward,{level = i,status = v})
            end

        elseif v.id == 2 then

        	local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
          
            local i = 1
            while ids.ids[(i-1)*3 + 1] do
            	table.insert(t.daily,{id = ids.ids[(i-1)*3 + 1],status = ids.ids[(i-1)*3 + 2],now = ids.ids[(i-1)*3 + 3]})
            	i = i + 1
            end

        elseif v.id == 3 then

        	local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
          
            local i = 1
            while ids.ids[(i-1)*3 + 1] do
            	table.insert(t.challenge,{id = ids.ids[(i-1)*3 + 1],status = ids.ids[(i-1)*3 + 2],now = ids.ids[(i-1)*3 + 3]})
            	i = i + 1
            end

        elseif v.id == 4 then

        	local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            for i,v in ipairs(ids.ids) do
            	table.insert(t.shop,{id = i,num = v})
            end

        end
    end

    gamedata.cache.SculptureActivityData = t
    return {type = 8130,data = gamedata.cache.SculptureActivityData}
end

function UISculptureActivityAwardCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8131, "SculptureActivityAward")
    printT(uireq,"uireq")

    local ids = ids_pb.Ids()
    table.insert(ids.ids, uireq.method)
    table.insert(ids.ids, uireq.param)

    gamedata.ext.SculptureActivityAwardInfo = uireq

    return 1, 8131, ids:SerializeToString()
end

function NetSculptureActivityAwardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8131, "SculptureActivityAward")
    local  getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    --领取登记奖励
    if gamedata.ext.SculptureActivityAwardInfo.method == 1 then
    	gamedata.cache.SculptureActivityData.reward[gamedata.ext.SculptureActivityAwardInfo.param].status = 2
    	return { type = 8131,reward = gamedata:SomethingProcess(getData),rewardstatus = gamedata.cache.SculptureActivityData.reward,props = getSculptureProps()}
    end

    return { type = 8131,reward = gamedata:SomethingProcess(getData),props = getSculptureProps()}
end

function UISculptureActivityShopBuyCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8132, "SculptureActivityShopBuy")
    printT(uireq,"uireq")

    local ids = ids_pb.Ids()
    table.insert(ids.ids, uireq.id)
    table.insert(ids.ids, uireq.num)

    gamedata.ext.SculptureActivityShopBuyInfo = uireq

    return 1, 8132, ids:SerializeToString()
end

function NetSculptureActivityShopBuyCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8132, "SculptureActivityShopBuy")
    local  getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)
    gamedata.cache.SculptureActivityData.shop[gamedata.ext.SculptureActivityShopBuyInfo.id].num = gamedata.cache.SculptureActivityData.shop[gamedata.ext.SculptureActivityShopBuyInfo.id].num + gamedata.ext.SculptureActivityShopBuyInfo.num

    gamedata:updateStaff({cid = gamedata.ext.SculptureActivityShopBuyInfo.spenddata.cid,num = -gamedata.ext.SculptureActivityShopBuyInfo.spenddata.num * gamedata.ext.SculptureActivityShopBuyInfo.num})
    return { type = 8132,reward = gamedata:SomethingProcess(getData),shop = gamedata.cache.SculptureActivityData.shop,props = getSculptureProps()}
end

function UISculptureActivityRankQueryCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8133, "SculptureActivityRankQuery")
    return 1, 8133, nil
end

function NetSculptureActivityRankQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8133, "SculptureActivityRankQuery")
    local params = params_pb.ParamS()
    params:ParseFromString(fd.rbuf)

    local ranklist = {}

    print("SculptureActivityRankQuery",#params.params)
    for i = 1,#params.params/2 do
        ranklist[i] = {}
        ranklist[i].rank = i
        ranklist[i].name    = params.params[2*i-1] and params.params[2*i-1].s or 0
        ranklist[i].time   = params.params[2*i-1] and params.params[2*i-1].i or 0
        ranklist[i].picId    = params.params[2*i] and params.params[2*i].i or ""
    end

    return { type = 8133,ranklist = ranklist}
end

