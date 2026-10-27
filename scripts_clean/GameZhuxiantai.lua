--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/12
-- Time: 上午10:26
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local battleresult_pb = require"battleresult_pb"
local somethings_pb = require"somethings_pb"
local combmessages_pb = require("combmessages_pb")
local players_pb = require("players_pb")


local function makeshopstatus()
    local status = {}
    for k,v in pairs(gamedata.config.zhusendai_exchange) do
        local cid,num = gamedata.getIDandNUM(v.reward)
        status[v.id] = gamedata.getStaffNum(cid)
    end

    return status
end

function UIZhuxiantaiQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3600, "huxiantaiQuery")

    gamedata.ext.zhuxiantaiqueryparam = uireq.param
    if not next(gamedata.cache.zhuxiantai) or (uireq.param and uireq.param =="update") then
        return 1,3600,nil
    else
        if (uireq.param and uireq.param =="shop") then
            return 0,3600,{ type = 3600, param = uireq.param, data = gamedata.cache.zhuxiantai, status = makeshopstatus() }
        else
            return 0,3600,{ type = 3600, param = uireq.param, data = gamedata.cache.zhuxiantai }
        end
    end
end

function NetZhuxiantaiQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3600, "huxiantaiQuery")
    local data = ids_pb.Ids()
    data:ParseFromString(fd.rbuf)

    gamedata:Zhuxiantai(data.ids)

    if  not gamedata.ext.zhuxiantaiqueryparam or gamedata.ext.zhuxiantaiqueryparam == "update" then
        return { type = 3600, param = gamedata.ext.zhuxiantaiqueryparam, data = gamedata.cache.zhuxiantai }
    elseif gamedata.ext.zhuxiantaiqueryparam == "shop" then
        return { type = 3600, param = gamedata.ext.zhuxiantaiqueryparam, data = gamedata.cache.zhuxiantai, status = makeshopstatus() }
    end


end

function UIZhuxiantaiBattleCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3601, "ZhuxiantaiBattle")

    local Bloodid = ids_pb.Ids()
    table.insert(Bloodid.ids, uireq.id)

    gamedata.ext.BloodBattleid = uireq.id

    return 1,3601,Bloodid:SerializeToString()
end

function NetZhuxiantaiBattleCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3601, "ZhuxiantaiBattle")
    local battleResultResponse = battleresult_pb.BattleResult()
    battleResultResponse:ParseFromString(fd.rbuf)

    local t = {
        type = 3601,
        floor = gamedata.cache.zhuxiantai.floor,
        star = battleResultResponse.star,
        result = battleResultResponse.result,
        battlereport = PickBattleResultReport(battleResultResponse),
        reward =  gamedata:SomethingProcess(battleResultResponse.reward),
    }

    --printT(t.reward,"ZhuxiantaiBattle reward")

    local reward3 = {}
    local reward = {}

    if math.mod(gamedata.cache.zhuxiantai.floor,3) ==0 then
        local config = gamedata.config.zhusendai_monster_param[tostring(gamedata.cache.zhuxiantai.floor)]["star"..gamedata.ext.BloodBattleid.."reward"]
       -- local prestige,coin = gamedata.getIDandNUM(config)
        for k,v in pairs(t.reward) do
            if v.cid == 1000 or v.cid == 1004 then
                table.insert(reward,v)
            else
                table.insert(reward3,v)
            end
        end
    else
        reward = t.reward
    end

    t.reward = reward
    t.reward3 = reward3

    return t
end


function UIZhuxiantaiWipeCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3602, "ZhuxiantaiWipe")

    return 1,3602,nil
end

function NetZhuxiantaiWipeCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3602, "ZhuxiantaiWipe")
    local reps = combmessages_pb.CombMessages()
    reps:ParseFromString(fd.rbuf)


    local wiperwards = {}

    for k,v in ipairs(reps.messages) do
        local Reward = somethings_pb.SomeThings()
        Reward:ParseFromString(v.data)
        wiperwards[v.id] = gamedata:SomethingProcess(Reward)

--        wiperwards[v.id] = {
--            id=v.id,
--            reward = gamedata:SomethingProcess(Reward)
--        }
    end

    return { type = 3602, reward = wiperwards,floor =gamedata.cache.zhuxiantai.floor }
end


function UIZhuxiantaiAttrQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3603, "ZhuxiantaiAtrrQuery")

    return 1,3603,nil
end

function NetZhuxiantaiAttrQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3603, "ZhuxiantaiAtrrQuery")
    local data = ids_pb.Ids()
    data:ParseFromString(fd.rbuf)

    local attr = {}
    for i=1, #data.ids/2 do
        if not attr[i] then attr[i] = {} end
        attr[i].attr = data.ids[i*2-1]
        attr[i].add = data.ids[i*2]
    end

    return { type = 3603, attr = attr, data = gamedata.cache.zhuxiantai}
end

function UIZhuxiantaiAttrSelectCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3604, "ZhuxiantaiAttrSelect")

    local Bloodattrid = ids_pb.Ids()
    table.insert(Bloodattrid.ids, uireq.id)

    return 1,3604,Bloodattrid:SerializeToString()
end

function NetZhuxiantaiAttrSelectCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3604, "ZhuxiantaiAttrSelect")
    local data = ids_pb.Ids()
    data:ParseFromString(fd.rbuf)

    gamedata:Zhuxiantai(data.ids)

    return { type = 3604, data = gamedata.cache.zhuxiantai}
end

function UIZhuxiantaiRankCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3605, "ZhuxiantaiRank")

    return 1,3605,nil
end

function NetZhuxiantaiRankCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3605, "ZhuxiantaiRank")
    local playersData = players_pb.Players()
    playersData:ParseFromString(fd.rbuf)

    return { type = 3605, players = gamedata:players(playersData.players), star = gamedata.cache.zhuxiantai.todaymaxstar}
end


function UIZhuxiantaiExchangeCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3606, "ZhuxiantaiExchange")

    local config = gamedata.config.zhusendai_exchange[tostring(uireq.id)]

    if config.prestige and config.prestige > 0 then
        if  config.prestige > gamedata.cache.zhuxiantai.prestige then
            return  0, 503, {type = 503, msgtype = "shortprestige"}
        end
    end

    if config.gold and config.gold > 0 then
        if  config.gold > gamedata.cache.role.gold then
            return  0, 503, {type = 503, msgtype = "shortgold"}
        end
    end

    local exchangeid = ids_pb.Ids()
    table.insert(exchangeid.ids, uireq.id)

    gamedata.ext.zhuanxiantaiexchangeid =  uireq.id

    return 1,3606,exchangeid:SerializeToString()
end

function NetZhuxiantaiExchangeCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3606, "ZhuxiantaiExchange")
    local Reward = somethings_pb.SomeThings()
    Reward:ParseFromString(fd.rbuf)

    local config = gamedata.config.zhusendai_exchange[tostring(gamedata.ext.zhuanxiantaiexchangeid)]

    if config.prestige and config.prestige > 0 then
        gamedata.cache.zhuxiantai.prestige = gamedata.cache.zhuxiantai.prestige - config.prestige
    end

    if config.gold and config.gold > 0 then
        gamedata:updateRoleGold(0-config.gold,"诛仙台兑换"..gamedata.ext.zhuanxiantaiexchangeid,1)
    end

    gamedata.cache.zhuxiantai.shop[gamedata.ext.zhuanxiantaiexchangeid] = gamedata.cache.zhuxiantai.shop[gamedata.ext.zhuanxiantaiexchangeid] + 1


    local reward =  gamedata:SomethingProcess(Reward)

    return { type = 3606, Reward = reward,data = gamedata.cache.zhuxiantai,status = makeshopstatus()}
end


function UIZhuxiantaiResetCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3607, "ZhuxiantaiReset")


    if gamedata.cache.zhuxiantai.reset >=1 then
        if gamedata.cache.role.gold <= 50 then
            return  0, 503, {type = 503, msgtype = "shortgold"}
        elseif gamedata.cache.zhuxiantai.reset >= gamedata.config.vip[tostring(gamedata.cache.vip.vip)].bzxtrst then
            return  0, 503, {type = 503, msgtype = "shortvip"}
        end
    end

    return 1,3607,nil
end

function NetZhuxiantaiResetCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3607, "ZhuxiantaiReset")
    local data = ids_pb.Ids()
    data:ParseFromString(fd.rbuf)

    if gamedata.cache.zhuxiantai.reset>=1 then
        gamedata:updateRoleGold(-50,"诛仙台重置次数",1)
    end

    gamedata:Zhuxiantai(data.ids)

    return { type = 3607, data = gamedata.cache.zhuxiantai}
end



-------------------------------------------------------------
function UIMieshendianQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3620, "MieshendianQuery")

    return 1,3620,nil

end

function NetMieshendianQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3620, "MieshendianQuery")
    local data = ids_pb.Ids()
    data:ParseFromString(fd.rbuf)

    gamedata:Mieshendian(data.ids)

    return { type = 3620, data = gamedata.cache.mieshendian }
end


function UIMieshendianBattle1CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3621, "MieshendianBattle1")

    local Bloodid = ids_pb.Ids()
    table.insert(Bloodid.ids, uireq.id)

    return 1,3621,Bloodid:SerializeToString()

end

function NetMieshendianBattle1CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3621, "MieshendianBattle1")

    local battleResultResponse = battleresult_pb.BattleResult()
    battleResultResponse:ParseFromString(fd.rbuf)

    local t = {
        type = 3621,
        --star = battleResultResponse.star,
        result = battleResultResponse.result,
        battlereport = PickBattleResultReport(battleResultResponse),
        reward =  gamedata:SomethingProcess(battleResultResponse.reward),
    }

    return t
end

function UIMieshendianBossQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 36201, "MieshendianBossQuery")

    local slots = table.copy(gamedata.cache.slots)

    for k,v in pairs(slots) do
        if not gamedata.cache.generals[v.general] or v.general == gamedata.cache.protagonist.iid then
            slots[k].generalcid = gamedata.cache.protagonist.general.cid
        else

            if gamedata:illusionsLimite("fan_pve") then
                slots[k].generalcid = gamedata.cache.generals[v.general].illusionGeneralCid or gamedata.cache.generals[v.general].cid
            else
                slots[k].generalcid = gamedata.cache.generals[v.general].cid
            end

        end
    end

    return 0,36201,{ type = 36201, mieshendian = gamedata.cache.mieshendian, slots = slots }

end


function UIMieshendianBattle2CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3622, "MieshendianBattle2")

    local Bloodid = ids_pb.Ids()

    for i = 1,3 do
        table.insert(Bloodid.ids, uireq.select[tostring(i)] or 0)
    end
    for i = 1,7 do
        table.insert(Bloodid.ids, uireq.arrange[tostring(i)] or 0)
    end


    return 1,3622,Bloodid:SerializeToString()

end

function NetMieshendianBattle2CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3622, "MieshendianBattle2")

    local battleResultResponse = battleresult_pb.BattleResult()
    battleResultResponse:ParseFromString(fd.rbuf)

    local t = {
        type = 3622,
        --star = battleResultResponse.star,
        result = battleResultResponse.result,
        battlereport = PickBattleResultReport(battleResultResponse),
        reward =  gamedata:SomethingProcess(battleResultResponse.reward),
    }

    return t
end


function UIMieshendianResetCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3626, "MieshendianReset")
    gamedata.ext.mieshendianresetgold = uireq.xgold or 0

    --if  gamedata.cache.mieshendian.todaycount <=0 then
    --    return 0,503,{type = 503, msgtype = "shortMieshendianReset"}
    --end

    if uireq.xgold and uireq.xgold > gamedata.cache.role.gold then
        return  0, 503, {type = 503, msgtype = "shortgold"}
    end

    return 1,3626,nil
end

function NetMieshendianResetCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3626, "MieshendianReset")
    local data = ids_pb.Ids()
    data:ParseFromString(fd.rbuf)

    gamedata:Mieshendian(data.ids)

    if gamedata.ext.mieshendianresetgold and gamedata.ext.mieshendianresetgold > 0 then
        gamedata:updateRoleGold(0-gamedata.ext.mieshendianresetgold,"灭神殿重置",1)
    end

    return { type = 3626, data = gamedata.cache.mieshendian,gold = gamedata.cache.role.gold }
end


function UIMieshendianModupCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3623, "MieshendianModup")

    return 1,3623,nil

end

function NetMieshendianModupCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3623, "MieshendianModup")
    local data = ids_pb.Ids()
    data:ParseFromString(fd.rbuf)

    gamedata:Mieshendian(data.ids)

    return { type = 3623, data = gamedata.cache.mieshendian }
end

function UIMieshendianModupCDClearCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3624, "MieshendianModupCDClear")

    gamedata.ext.mieshendianxgold = uireq.xnum or 0

    if uireq.xnum and uireq.xnum > gamedata.cache.role.gold then
        return  0, 503, {type = 503, msgtype = "shortgold"}
    end

    return 1,3624,nil

end

function NetMieshendianModupCDClearCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3624, "MieshendianModupCDClear")
    local Reward = somethings_pb.SomeThings()
    Reward:ParseFromString(fd.rbuf)

    local reward =  gamedata:SomethingProcess(Reward)

    if gamedata.ext.mieshendianxgold and gamedata.ext.mieshendianxgold > 0 then
        gamedata:updateRoleGold(0-gamedata.ext.mieshendianxgold,"灭神殿立即完成扫荡",1)
    end

    return { type = 3624, Reward = reward }
end

function UIMieshendianRankCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3625, "MieshendianRank")

    return 1,3625,nil

end

function NetMieshendianRankCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3625, "MieshendianRank")
    local playersData = players_pb.Players()
    playersData:ParseFromString(fd.rbuf)

    return { type = 3625, mieshendian = gamedata.cache.mieshendian, players = gamedata:players(playersData.players)}
end


--
function UIMieshendianShopCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3627, "MieshendianShop")

    return 1,3627,nil

end

function NetMieshendianShopCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3627, "MieshendianShop")
    local data = ids_pb.Ids()
    data:ParseFromString(fd.rbuf)

    gamedata:MieshendianShop(data.ids)

    return { type = 3627, data = gamedata.cache.mieshendianshop }

end

--
function UIMieshendianShopBuyCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3628, "MieshendianShopBuy")

    local exchangeid = ids_pb.Ids()
    table.insert(exchangeid.ids, uireq.id)

    gamedata.ext.MieshendianShopXGold = uireq.xgold and (uireq.xgold+0) or 0

    if uireq.xgold and uireq.xgold+0 > gamedata.cache.role.gold then
        return 0,503,{type = 503, msgtype = "shortgold"}
    end

    return 1,3628,exchangeid:SerializeToString()

end

function NetMieshendianShopBuyCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3628, "MieshendianShopBuy")
    local Reward = somethings_pb.SomeThings()
    Reward:ParseFromString(fd.rbuf)

    local reward =  gamedata:SomethingProcess(Reward)

    if gamedata.ext.MieshendianShopXGold and gamedata.ext.MieshendianShopXGold > 0 then
        gamedata:updateRoleGold(0-gamedata.ext.MieshendianShopXGold,"灭神殿商店购买物品",1)
    end

    return { type = 3628, reward = reward }

end