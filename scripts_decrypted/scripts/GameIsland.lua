--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/8/28
-- Time: 下午3:51
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")
local combmessages_pb = require("combmessages_pb")
local battleresult_pb = require("battleresult_pb")
require"PickBattleResultReport"
function UIIslandCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2110, "Island")

    if next(gamedata.cache.island) ~= nil then
        return 0, 2110, { type = 2110, island = gamedata.cache.island }
    else
        return 1, 2110, nil
    end
end

function NetIslandCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2110, "Island")
    local islandData = ids_pb.Ids()
    islandData:ParseFromString(fd.rbuf)

    gamedata:Island(islandData.ids)

    return { type = 2110, island = gamedata.cache.island }
end

------------------------------------------------------------------------------------------------------------------------------------------------------

function UIIslandGotoCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2111, "IslandGoto")
    print("UIIslandGotoCallBack-==")
    printT(uireq)
    gamedata.ext.islandgotoRollnum = uireq.rollnum
    gamedata.ext.islandgotogold = 0
    if uireq.to >50 then
        if gamedata.cache.role.gold < tonumber(gamedata.config.global_kv.penglai_portal_gold.value) then
            return 0,503,{type = 503, msgtype = "shortgold" }
        end
        gamedata.ext.islandgotogold = tonumber(gamedata.config.global_kv.penglai_portal_gold.value)
    elseif uireq.rollnum >= tonumber(gamedata.config.global_kv.penglaixiandao_dice_free.value) and gamedata.cache.role.gold < tonumber(gamedata.config.global_kv.penglaixiandao_dice_gold.value) then
        return 0,503,{type = 503, msgtype = "shortgold" }
    end

    -- gamedata.ext.islandgotoRollnum > tonumber(gamedata.config.global_kv.penglaixiandao_dice_free.value)
    print("test111111")
    local islandData = ids_pb.Ids()
    table.insert(islandData.ids, uireq.from)
    table.insert(islandData.ids, uireq.to)

    gamedata.ext.islandgotoPos = uireq.to

    return 1, 2111, islandData:SerializeToString()
end

function NetIslandGotoCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2111, "IslandGoto")
    print("NetIslandGotoCallBack===")
    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local getPoint = 0

    local reward = nil

    for k,v in ipairs(datas.messages) do
        if v.id==0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:IslandCommom(ids.ids)
        elseif v.id==1 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            getPoint = ids.ids[1]
        elseif v.id==2 then
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            reward = gamedata:SomethingProcess(SomeThings)
        end
    end
    print("mapStatusdata")
    -- printT(gamedata.cache.island.mapStatus[gamedata.ext.islandgotoPos])
    if gamedata.ext.islandgotoPos<=50 and gamedata.cache.island.mapStatus[gamedata.ext.islandgotoPos].type ~= 0 and gamedata.cache.island.mapStatus[gamedata.ext.islandgotoPos].status~=999 then
        local type = gamedata.config.penglai2_type[tostring(gamedata.cache.island.mapStatus[gamedata.ext.islandgotoPos].type)].type
        if type == "monster" or type == "brave" or type == "boss" or type == "buffer" then
            print("setstatus===")
            gamedata.cache.island.mapStatus[gamedata.ext.islandgotoPos].status = 1
        else
            gamedata.cache.island.mapStatus[gamedata.ext.islandgotoPos].status = 999
        end
    else
        gamedata:updateRoleGold(-gamedata.ext.islandgotogold,"蓬莱仙岛传送",1)
    end

    if gamedata.ext.islandgotoPos<=50 and gamedata.ext.islandgotoRollnum >= tonumber(gamedata.config.global_kv.penglaixiandao_dice_free.value) then
        print("test2222222num",gamedata.config.global_kv.penglaixiandao_dice_gold.value)
        gamedata:updateRoleGold(-tonumber(gamedata.config.global_kv.penglaixiandao_dice_gold.value),"蓬莱仙岛收费roll骰子",1)
    end
    -- printT(gamedata.cache.island.mapStatus[gamedata.ext.islandgotoPos])

    return { type = 2111, island = gamedata.cache.island,reward = reward, getPoint=getPoint}
end

------------------------------------------------------------------------------------------------------------------------------------------------------


function UIIslandNextCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2112, "IslandNext")
    local islandData = ids_pb.Ids()
    table.insert(islandData.ids, uireq.method)

    gamedata.ext.islandnextmethod = uireq.method
    gamedata.ext.islandnextgold = 0
    gamedata.ext.islandnextcoin = 0
    print("UIIslandNextCallBack..",uireq)
    -- printT(uireq)
    if uireq.gold then
        gamedata.ext.islandnextgold = uireq.gold
    end
    if uireq.coin then
        gamedata.ext.islandnextcoin = uireq.coin
    end
    

    local presentPos =  gamedata.cache.island.mapStatus[gamedata.cache.island.location]
    local type = gamedata.config.penglai2_type[tostring(presentPos.type)].type
    if type == "monster" or type == "brave" or type == "boss" then
        if presentPos.status == 3 then
            if gamedata.cache.role.gold < tonumber(gamedata.config.global_kv.penglai_resurgence_gold.value) then
                return 0,503,{type = 503, msgtype = "shortgold" }
            end
            gamedata.ext.islandnextgold = tonumber(gamedata.config.global_kv.penglai_resurgence_gold.value)
            print("fuhuo===",gamedata.ext.islandnextgold)
        end
    elseif type == "buffer" then
        if uireq.method == 1 then
            if tonumber(gamedata.cache.role.gold) < tonumber(gamedata.config.global_kv.penglai_buff.value) then
                return 0,503,{type = 503, msgtype = "shortgold" }
            end
            gamedata.ext.islandnextgold = tonumber(gamedata.config.global_kv.penglai_buff.value)
            print("buffer===",gamedata.ext.islandnextgold)
        end
    end

    return 1, 2112, islandData:SerializeToString()
end

function NetIslandNextCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2112, "IslandNext")
    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    -- local ids = ids_pb.Ids()
    -- ids:ParseFromString(datas.messages[0].data)
    -- gamedata:IslandCommom(ids.ids)
    local nowdata 
    for k,v in ipairs(datas.messages) do
        if v.id==0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:IslandCommom(ids.ids)
        elseif v.id==1 then
            nowdata = v.data
        end
    end

    local presentPos =  gamedata.cache.island.mapStatus[gamedata.cache.island.location]
    print("i...am...presentPos:")
    -- printT(gamedata.cache.island)

    local type = gamedata.config.penglai2_type[tostring(presentPos.type)].type

    local battlereport = nil
    local getpoint = 0
    local result = nil

    local getbuffer = 0

    if type == "monster" or type == "brave" or type == "boss" then
        if presentPos.status == 1 then
            if gamedata.ext.islandnextmethod == 0 then
                local copyAttackResultPb = battleresult_pb.BattleResult()
                copyAttackResultPb:ParseFromString(nowdata)
                result = copyAttackResultPb.result
                ---battlereport = copyAttackResultPb.battlereport
                battlereport = PickBattleResultReport(copyAttackResultPb)
                if  copyAttackResultPb.result == 1 then
                    presentPos.status = 2
                else
                    presentPos.status = 3
                end
            elseif gamedata.ext.islandnextmethod == 1 then
                presentPos.status = 0
            end
        elseif presentPos.status == 2 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(nowdata)
            getpoint = ids.ids[1]
            presentPos.status = 999
        elseif presentPos.status == 3 then
            presentPos.status = 0
        end
    elseif type == "buffer" then
        presentPos.status = 999
        getbuffer = 1
    end
    print("spendgold=",gamedata.ext.islandnextgold)
    print("spendcoin=",gamedata.ext.islandnextcoin)
    gamedata:updateRoleGold(0-gamedata.ext.islandnextgold,"蓬莱仙岛NEXT",1)
    gamedata:updateRoleCoin(0-gamedata.ext.islandnextcoin,"蓬莱仙岛NEXT",1)



    return { type = 2112, island = gamedata.cache.island, battlereport = battlereport, result = result, getpoint=getpoint, getbuffer = getbuffer }
end

------------------------------------------------------------------------------------------------------------------------------------------------------

function UIIslandGetTodayRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2113, "IslandGetTodayReward")

    return 1, 2113, nil
end

function NetIslandGetTodayRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2113, "IslandGetTodayReward")
    local rewarddata = somethings_pb.SomeThings()
    rewarddata:ParseFromString(fd.rbuf)

    gamedata.cache.island.rewardStatus = 2

    return {type = 2113, reward = gamedata:SomethingProcess(rewarddata),island = gamedata.cache.island}
end

------------------------------------------------------------------------------------------------------------------------------------------------------

function UIIslandTaskCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2114, "IslandTask")
    print("uireq.update===",uireq.update)
    -- printT(gamedata.cache.island.task)
    if tonumber(uireq.update) == 1 or not gamedata.cache.island.task or not next(gamedata.cache.island.task) then
        print("request====")
        return 1, 2114, nil
    else
        print("requestnot====")
        return 0, 2114, { type = 2114, task = gamedata.cache.island.task }
    end
end

function NetIslandTaskCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2114, "IslandTask")
    local taskResponse = tasks_pb.Tasks()
    taskResponse:ParseFromString(fd.rbuf)
    gamedata:IslandTask(taskResponse)

    return {type = 2114, task = gamedata.cache.island.task}
end

------------------------------------------------------------------------------------------------------------------------------------------------------

function UIIslandTaskRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2115, "IslandTaskReward")
    local TaskRewardData = ids_pb.Ids()
    table.insert(TaskRewardData.ids, uireq.id)

    gamedata.ext.taskrewardid = uireq.id
    gamedata.ext.taskrewardseq = uireq.seq

    return 1, 2115, TaskRewardData:SerializeToString()

end

function NetIslandTaskRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2115, "IslandTaskReward")
    local rewarddata = somethings_pb.SomeThings()
    rewarddata:ParseFromString(fd.rbuf)
    print("NetIslandTaskRewardCallBack")
    -- printT(gamedata.cache.island.task)
    print("taskrewardid==",gamedata.ext.taskrewardseq)

    gamedata.cache.island.task[gamedata.ext.taskrewardseq].status = 2

    return {type = 2115, task = gamedata.cache.island.task,reward = gamedata:SomethingProcess(rewarddata)}
end

------------------------------------------------------------------------------------------------------------------------------------------------------

function UIIslandRankCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2116, "IslandRank")
    print("UIIslandRankCallBack.update===",uireq.update)
    if tonumber(uireq.update) == 1 or not gamedata.cache.island.rank or not next(gamedata.cache.island.rank) then
        print("UIIslandRankCallBack.update===1")
        return 1, 2116, nil
    else
        print("UIIslandRankCallBack.update===2")
        return 0, 2116, { type = 2116, rank = gamedata.cache.island.rank }
    end
end

function NetIslandRankCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2116, "IslandRank")
    local playersData = players_pb.Players()
    playersData:ParseFromString(fd.rbuf)

    gamedata:IslandRank(playersData.players)

    return {type = 2116, rank = gamedata.cache.island.rank}
end

------------------------------------------------------------------------------------------------------------------------------------------------------

function UIIslandGlobalCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2117, "IslandGlobal")
    print("UIIslandGlobalCallBack.update===",uireq.update)
    if tonumber(uireq.update) == 1 or not gamedata.cache.island.global or not next(gamedata.cache.island.global) then
        print("UIIslandGlobalCallBack.update===1")
        return 1, 2117, nil
    else
        print("UIIslandGlobalCallBack.update===2")
        return 0, 2117, { type = 2117, global = gamedata.cache.island.global }
    end
end

function NetIslandGlobalCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2117, "IslandGlobal")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    gamedata:IslandGlobal(ids.ids)

    return {type = 2117, global = gamedata.cache.island.global,globalpoint = gamedata.cache.island.globalpoint}
end

------------------------------------------------------------------------------------------------------------------------------------------------------

function UIIslandGlobalRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2118, "IslandGlobalReward")
    local globalRewardData = ids_pb.Ids()
    table.insert(globalRewardData.ids, uireq.id)

    gamedata.ext.globalrewardid = uireq.id

    return 1, 2118, globalRewardData:SerializeToString()

end

function NetIslandGlobalRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2118, "IslandGlobalReward")
    local rewarddata = somethings_pb.SomeThings()
    rewarddata:ParseFromString(fd.rbuf)

    gamedata.cache.island.global[gamedata.ext.globalrewardid] = 2

    return {type = 2118, global = gamedata.cache.island.global,reward = gamedata:SomethingProcess(rewarddata)}
end


----------------
----------------penglai3


function UIPenglai3CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2120, "Penglai3")
    return 1, 2120, nil
end

function NetPenglai3CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2120, "Penglai3")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    gamedata:Penglai3(ids.ids)

    return {type = 2120, penglai = gamedata.cache.penglai3}
end

--
function UIPenglai3DiceCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2121, "Penglai3dice")
    gamedata.ext.penglai_roll_gold = 0
    gamedata.ext.penglai_roll_propnum = 0

    local dicepropcid,dicepropnum = gamedata.getIDandNUM(gamedata.config.global_kv.penglai3_diceid.value)
    gamedata.ext.penglai_roll_propcid = dicepropcid or 20262


    if uireq.dice and uireq.dice > 0 then
        local diceData = ids_pb.Ids()
        table.insert(diceData.ids, uireq.dice)

        gamedata.ext.penglai_roll_propnum = dicepropnum or 1

        return 1, 2121, diceData:SerializeToString()
    else

        local freetimes = tonumber(gamedata.config.global_kv.penglai3_freetimes.value) or 0
        if gamedata.cache.penglai3.dice >= freetimes then
            
            if gamedata.config.buycount_price and gamedata.config.buycount_price[tostring(gamedata.cache.penglai3.dice+1-freetimes)] then
                gamedata.ext.penglai_roll_gold = gamedata.config.buycount_price[tostring(gamedata.cache.penglai3.dice+1-freetimes)].penglai3cost or 0
            else
                gamedata.ext.penglai_roll_gold = gamedata.config.buycount_price[tostring(table.getTableLength(gamedata.config.buycount_price))].penglai3cost or 0
            end
        end

        if gamedata.ext.penglai_roll_gold+0 > gamedata.cache.role.gold+0 then
            return 0,503,{type = 503, msgtype = "shortgold" }
        else
            return 1, 2121, nil
        end
    end
end

function NetPenglai3DiceCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2121, "Penglai3dice")
    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local reward = {}
    local battlereport = {}
    local result = 0
    for k,v in ipairs(datas.messages) do
        if v.id==0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:Penglai3(ids.ids)
        elseif v.id==1 then
            local copyAttackResultPb = battleresult_pb.BattleResult()
            copyAttackResultPb:ParseFromString(v.data)
            result = copyAttackResultPb.result
            battlereport = PickBattleResultReport(copyAttackResultPb)
        elseif v.id==2 then
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            reward = gamedata:SomethingProcess(SomeThings)
        end
    end

    if gamedata.ext.penglai_roll_gold and gamedata.ext.penglai_roll_gold+0 > 0 then
        gamedata:updateRoleGold(0-gamedata.ext.penglai_roll_gold,"蓬莱仙岛掷骰子",1)
    end

    if gamedata.ext.penglai_roll_propnum and gamedata.ext.penglai_roll_propnum+0 > 0 then
        gamedata:updateprops({cid = gamedata.ext.penglai_roll_propcid, num=0-gamedata.ext.penglai_roll_propnum})
    end

    return {type = 2121, penglai = gamedata.cache.penglai3, reward = reward, battlereport = battlereport,result = result,}
end

--
function UIPenglai3CardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2124, "Penglai3card")
    return 1, 2124, nil
end

function NetPenglai3CardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2124, "Penglai3card")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    local card = {}
    card.cards = {}
    card.status = ids.ids[1] or 0
    for i = 1,5 do
       table.insert(card.cards,{id = ids.ids[2*i] or 0,status = ids.ids[2*i+1] or 0})
    end

    return {type = 2124, card = card}
end

--
function UIPenglai3CardOpenCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2125, "Penglai3CardOpen")

    local cardData = ids_pb.Ids()
    if uireq and uireq.opt then
        table.insert(cardData.ids, uireq.opt)
    end
    if uireq and uireq.id then
        table.insert(cardData.ids, uireq.id)
    end

    gamedata.ext.penglai_card_gold = uireq.gold or 0

    if gamedata.ext.penglai_card_gold+0 > gamedata.cache.role.gold+0 then
        return 0,503,{type = 503, msgtype = "shortgold" }
    else
        return 1, 2125, cardData:SerializeToString()
    end

end

function NetPenglai3CardOpenCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2125, "Penglai3CardOpen")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    local reward = {}
    reward = gamedata:SomethingProcess(SomeThings)


    if gamedata.ext.penglai_card_gold and gamedata.ext.penglai_card_gold+0 > 0 then
        gamedata:updateRoleGold(0-gamedata.ext.penglai_card_gold,"蓬莱仙岛翻牌",1)
    end

    return {type = 2125, reward = reward,}
end

function UIPenglai3CardCloseCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2126, "Penglai3CardClose")
    return 1, 2126, nil
end

function NetPenglai3CardCloseCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2126, "Penglai3CardClose")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    gamedata:Penglai3(ids.ids)

    return {type = 2126, penglai = gamedata.cache.penglai3}
end


--
function UIPenglaiAutoRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2127, "UIPenglaiAutoRewardCallBack")

    local cardData = ids_pb.Ids()
    table.insert(cardData.ids, uireq.curType)

    gamedata.ext.penglai_New_card_gold = uireq.gold or 0
    return 1, 2127, cardData:SerializeToString()
end

function NetPenglaiAitoRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2127, "NetPenglaiAitoRewardCallBack")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    local reward = {}
    reward = gamedata:SomethingProcess(SomeThings)

    if gamedata.ext.penglai_New_card_gold and gamedata.ext.penglai_New_card_gold+0 > 0 then
        gamedata:updateRoleGold(0-gamedata.ext.penglai_New_card_gold,"蓬莱仙岛翻牌",1)
    end

    return {type = 2127, reward = reward,}
end


function UIPenglaiAutoReward2CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2128, "PenglaiAutoReward2CallBack")

    printT(uireq,"uireq")
    
    local cardData = ids_pb.Ids()
    table.insert(cardData.ids, uireq.curType)

    return 1, 2128, cardData:SerializeToString()
end

function NetPenglaiAutoReward2CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2128, "PenglaiAutoReward2CallBack")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local reward = nil
    local goldcost = 0
    local battleResult = -1

    for k,v in ipairs(datas.messages) do
        if v.id==0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            goldcost = ids.ids[1]
            if goldcost == -1 then
                break
            end
        elseif v.id==1 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:Penglai3(ids.ids)
        elseif v.id==2 then
            
        elseif v.id == 3 then
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            reward = gamedata:SomethingProcess(SomeThings)
        elseif v.id == 4 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            battleResult = ids.ids[1]
        end
    end

    if goldcost > 0 then
        gamedata:updateRoleGold(0-goldcost,"蓬莱仙岛一键",1)
    end

    return {type = 2128, reward = reward,penglai = gamedata.cache.penglai3,goldcost = goldcost,result = battleResult}
end


--
function UIPenglai3RewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2122, "Penglai3Reward")

    return 1, 2122, nil
end

function NetPenglai3RewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2122, "Penglai3Reward")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    local reward = {}
    reward = gamedata:SomethingProcess(SomeThings)


    return {type = 2122, reward = reward,}
end

--
function UIPenglai3ResetCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2123, "Penglai3Reset")

    gamedata.ext.penglai_reset_gold = 0
    if gamedata.config.buycount_price and gamedata.config.buycount_price[tostring(gamedata.cache.penglai3.count+1)] then
        gamedata.ext.penglai_reset_gold = gamedata.config.buycount_price[tostring(gamedata.cache.penglai3.count+1)].penglai3reset or 0
    end
    if gamedata.cache.penglai3.count >= gamedata.config.vip[tostring(gamedata.cache.vip.vip)].penglai3_times then
        return 0,503,{type = 503, msg = "重置次数已用完" }
    elseif gamedata.ext.penglai_reset_gold+0 > gamedata.cache.role.gold+0 then
        return 0,503,{type = 503, msgtype = "shortgold" }
    else
        return 1, 2123, nil
    end
end

function NetPenglai3ResetCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2123, "Penglai3Reset")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    gamedata:Penglai3(ids.ids)
    gamedata:updateRoleGold(0-gamedata.ext.penglai_reset_gold,"蓬莱仙岛重置",1)

    return {type = 2123, penglai = gamedata.cache.penglai3}
end   ^  