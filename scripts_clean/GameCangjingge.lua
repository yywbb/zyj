--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 17/2/15
-- Time: 14:50
-- To change this template use File | Settings | File Templates.
--
--[[
    [4820] = UIManorQueryCallBack,
    [4821] = UIManorFriendListQueryCallBack,
    [4822] = UIManorLevelUpCallBack,
    [4823] = UIManorGetWoodCallBack,
    [4824] = UIManorNoticeQueryCallBack,
    [4825] = NetManorChangeCallBack,
    [4826] = UIManorNoticeGetTaskCallBack,
    [4827] = UIManorNoticeDoneTaskCallBack,
    [4828] = UIManorYaoBattleCallBack,
    [4829] = UIManorShopCallBack,
    [4830] = UIManorShopExchangeCallBack,
    [4831] = UIManorConcentCallBack,
]]


local ids_pb = require("ids_pb")
local params_pb = require("params_pb")
local somethings_pb = require("somethings_pb")
local battleresult_pb = require("battleresult_pb")

require"PickBattleResultReport"

function UIManorQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4820, "ManorQuery")
    --
    gamedata.ext.ManorReqRid = uireq.rid or 0

    if gamedata.ext.ManorReqRid > 0 then
        local ManorReqData = ids_pb.Ids()
        table.insert(ManorReqData.ids, uireq.rid)
        return 1, 4820, ManorReqData:SerializeToString()
    else
        return 1, 4820, nil
    end

end

function NetManorQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4820, "ManorQuery")

    local cangjingge = {}

    local params = params_pb.ParamS()
    params:ParseFromString(fd.rbuf)

    cangjingge = gamedata:CangjinggeData(params.params)

    if gamedata.ext.ManorReqRid and gamedata.ext.ManorReqRid > 0 then

    else
        gamedata.cache.cangjingge = cangjingge
    end

    return { type = 4820, cangjingge = cangjingge or {}, manorReqRid = gamedata.ext.ManorReqRid or 0}
end

--
function UIManorFriendListQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4821, "ManorFriendListQuery")

    gamedata.ext.ManorShowFriends = uireq.show or 0

    return 1, 4821, nil

end

function NetManorFriendListQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4821, "ManorFriendListQuery")

    local manorfriends = {}

    local params = params_pb.ParamS()
    params:ParseFromString(fd.rbuf)

    manorfriends = gamedata:CangjinggeFriendsData(params.params)

    gamedata.cache.manorfriends = manorfriends

    return { type = 4821, manorfriends = manorfriends or {}, show = gamedata.ext.ManorShowFriends or 0}
end


--
function UIManorGetWoodCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4823, "ManorGetWood")

    return 1, 4823, nil

end

function NetManorGetWoodCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4823, "ManorGetWood")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    local reward = gamedata:SomethingProcess(SomeThings)


    return { type = 4823, reward = reward}
end


--
function UIManorLevelUpCallBack(uireq)
    cclog("NET type:%d cmd:%s recv response from UI", 4822, "ManorLevelUp")
    if uireq.id then
        local idData = ids_pb.Ids()
        table.insert(idData.ids,uireq.id)

        gamedata.ext.ManorLevelUpCost =  uireq.cost or {}

        return 1, 4822, idData:SerializeToString()
    end
end

function NetManorLevelUpCallBack(fd)
    cclog("NET type:%d cmd:%s recv request from gameserver", 4822, "ManorLevelUp")
    local idsData = ids_pb.Ids()
    idsData:ParseFromString(fd.rbuf)

    for k,v in pairs(gamedata.ext.ManorLevelUpCost) do
        gamedata:updateprops({cid = v.cid,num = 0-v.num})
    end

    return {type= 4822,buildtype = idsData.ids[1] or 1, buildlevel = idsData.ids[2] or 1, buildquality = idsData.ids[3] or 1, material1 = gamedata.getStaffNum(20377).num or 0, material2 = gamedata.getStaffNum(20378).num or 0,}
end

--
function UIManorNoticeQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv response from UI", 4824, "ManorNoticeQuery")

    local idData = ids_pb.Ids()
    table.insert(idData.ids,uireq.opt or 0)

    gamedata.ext.ManorNoticeResetGold =  uireq.xgold or 0

    if gamedata.ext.ManorNoticeResetGold > gamedata.cache.role.gold then
        return 0,503,{type = 503, msgtype = "shortgold"}
    end

    return 1, 4824, idData:SerializeToString()

end

function NetManorNoticeQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv request from gameserver", 4824, "ManorNoticeQuery")
    local idsData = ids_pb.Ids()
    idsData:ParseFromString(fd.rbuf)

    local manortask = {}
    manortask.count = idsData.ids[1] or 0
    manortask.reset = idsData.ids[2] or 0
    for i = 1,3 do
        manortask["task"..i] = {}
        manortask["task"..i].id = idsData.ids[3*i] or 0
        manortask["task"..i].pos = idsData.ids[3*i+1] or 0
        manortask["task"..i].status = idsData.ids[3*i+2] or 0
    end

    if gamedata.ext.ManorNoticeResetGold and gamedata.ext.ManorNoticeResetGold > 0 then
        gamedata:updateRoleGold(0-gamedata.ext.ManorNoticeResetGold,"藏经阁任务刷新",1)
    end

    return {type= 4824,manortask = manortask}
end

--
--
function UIManorNoticeGetTaskCallBack(uireq)
    cclog("NET type:%d cmd:%s recv response from UI", 4826, "ManorNoticeGetTask")

    local idData = ids_pb.Ids()
    table.insert(idData.ids,uireq.id or 0)
    table.insert(idData.ids,uireq.opt or 0)

    return 1, 4826, idData:SerializeToString()

end

function NetManorNoticeGetTaskCallBack(fd)
    cclog("NET type:%d cmd:%s recv request from gameserver", 4826, "ManorNoticeGetTask")
    local idsData = ids_pb.Ids()
    idsData:ParseFromString(fd.rbuf)


    return {type= 4826}
end

--
function UIManorNoticeDoneTaskCallBack(uireq)
    cclog("NET type:%d cmd:%s recv response from UI", 4827, "ManorNoticeDoneTask")

    local idData = ids_pb.Ids()
    table.insert(idData.ids,uireq.id or 0)
    table.insert(idData.ids,uireq.opt or 0)

    gamedata.ext.ManorNoticeFinishGold =  uireq.xgold or 0

    if gamedata.ext.ManorNoticeFinishGold > gamedata.cache.role.gold then
        return 0,503,{type = 503, msgtype = "shortgold"}
    end

    return 1, 4827, idData:SerializeToString()

end

function NetManorNoticeDoneTaskCallBack(fd)
    cclog("NET type:%d cmd:%s recv request from gameserver", 4827, "ManorNoticeDoneTask")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    local reward = gamedata:SomethingProcess(SomeThings)

    if gamedata.ext.ManorNoticeFinishGold and gamedata.ext.ManorNoticeFinishGold > 0 then
        gamedata:updateRoleGold(0-gamedata.ext.ManorNoticeFinishGold,"藏经阁任务立即完成",1)
    end

    return {type= 4827, reward = reward}
end

function NetManorChangeCallBack(fd)
    cclog("NET type:%d cmd:%s recv request from gameserver", 4825, "ManorChange")

    mekehintext(262, 1)
    return {type= 4825, data =gamedata.cache.hint}
end


--
function UIManorYaoBattleCallBack(uireq)
    cclog("NET type:%d cmd:%s recv response from UI", 4828, "ManorYaoBattle")

    local idData = ids_pb.Ids()
    table.insert(idData.ids,uireq.rid or 0)
    table.insert(idData.ids,uireq.monsterpos or 0)
    table.insert(idData.ids,uireq.isauto or 0)

    gamedata.ext.ManorBattleRid = uireq.rid or 0
    gamedata.ext.ManorBattleIsauto = uireq.isauto or 0

    return 1, 4828, idData:SerializeToString()

end

function NetManorYaoBattleCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4828, "ManorYaoBattle")
    local ResultPb = battleresult_pb.BattleResult()
    ResultPb:ParseFromString(fd.rbuf)

    local t = {
        type = 4828,
        reward = gamedata:SomethingProcess(ResultPb.reward),
        battlereport = PickBattleResultReport(ResultPb),
        result = ResultPb.result,
        rid = gamedata.ext.ManorBattleRid or 0,
        isauto = gamedata.ext.ManorBattleIsauto or 0,
    }
    return t
end


--
--
function UIManorShopCallBack(uireq)
    cclog("NET type:%d cmd:%s recv response from UI", 4829, "ManorShop")

    return 1, 4829, nil
end

function NetManorShopCallBack(fd)
    cclog("NET type:%d cmd:%s recv request from gameserver", 4829, "ManorShop")
    local idsData = ids_pb.Ids()
    idsData:ParseFromString(fd.rbuf)
    local shop = {}

    for i = 1,#idsData.ids,2 do
        local id = idsData.ids[i] or 0
        local num = idsData.ids[i+1] or 0
        local config = gamedata.config.home_store[tostring(id)]
        if config then
            table.insert(shop,{id = id, num = num,sort = config.sort})
        end
    end
    table.sort(shop,function ( a,b)
        return a.sort < b.sort
    end)

    return {type= 4829,shop = shop, hasnum = gamedata.cache.props[20376] and gamedata.cache.props[20376].num or 0}
end

--
function UIManorShopExchangeCallBack(uireq)
    cclog("NET type:%d cmd:%s recv response from UI", 4830, "ManorShopExchange")

    local idData = ids_pb.Ids()
    table.insert(idData.ids,uireq.id or 0)
    table.insert(idData.ids,uireq.num or 1)
    printT(uireq,"uireq  ---   ")

    gamedata.ext.ManorShopExchangeCost =  uireq.cost or {}
    gamedata.ext.ManorShopExchangeCostnum =  uireq.num

    for k,v in pairs(gamedata.ext.ManorShopExchangeCost) do
        if v.cid == 1001 then
            if v.num*uireq.num > gamedata.cache.role.gold then
                return 0,503,{type = 503, msgtype = "shortgold"}
            end
        else
            if gamedata.getStaffNum(v.cid).num < v.num*uireq.num then
                return 0,503,{type = 503,msgtype = "shortprop",id= v.cid,num= v.num}
            end
        end
    end

    return 1, 4830, idData:SerializeToString()

end

function NetManorShopExchangeCallBack(fd)
    cclog("NET type:%d cmd:%s recv request from gameserver", 4830, "ManorShopExchange")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    local reward = gamedata:SomethingProcess(SomeThings)

    for k,v in pairs(gamedata.ext.ManorShopExchangeCost) do
        gamedata:updateStaff({cid = v.cid,num = 0-v.num*gamedata.ext.ManorShopExchangeCostnum})
    end

    return {type= 4830, reward = reward}
end

--
function UIManorConcentCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4831, "ManorConcent")

    local texts = params_pb.ParamS()
    local text = params_pb.ParamS.Param()

    text.s = uireq.text or ""
    table.insert(texts.params, text)


    return 1, 4831, texts:SerializeToString()
end

function NetManorConcentCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4831, "ManorConcent")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)


    return { type = 4831, result = ids.ids[1] or 0 }
end