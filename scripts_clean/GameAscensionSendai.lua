local ids_pb = require("ids_pb")
local params_pb = require("params_pb")
local somethings_pb = require("somethings_pb")
local combmessages_pb = require("combmessages_pb")
local battleresult_pb = require("battleresult_pb")
require"PickBattleResultReport"

--升仙台查询
function UIAscensionSendaiMapQueryCallBack(uireq)
    print("request from UI", 8851, "UIAscensionSendaiMapQueryCallBack")

    return 1, 8851, nil
end

function NetAscensionSendaiMapQueryCallBack(fd)
    print("request from Net", 8851, "NetAscensionSendaiMapQueryCallBack")

    local combData = combmessages_pb.CombMessages()
    combData:ParseFromString(fd.rbuf)

    local data = {}
    for k,v in ipairs(combData.messages) do
        if v.id == 0 then
            local idsData = ids_pb.Ids()
            idsData:ParseFromString(v.data)
            data.mapid = idsData.ids[1] or 0 --轮数
            data.time = idsData.ids[2] or 0 --倒计时
            data.difficulty = idsData.ids[3] or 0 --地图难度
            data.maplevel = idsData.ids[4] or 0 --地图等级
            data.newpoint = idsData.ids[5] or 0 --当前格子
            data.pointstate = idsData.ids[6] or 0 --当前格子状态
            data.sendaiGenerals = idsData.ids[7] or 0 --是否有点仙
            data.sxynum = idsData.ids[8] or 0 --升仙玉数量
        elseif v.id == 1 then
            local params = params_pb.ParamS()
            params:ParseFromString(v.data)
            data.pointStr =  params.params[1].s or "" --走过的格子
        end
    end

    return { type = 8851, data = data}
end

--选择地图难度
function UIAscensionSendaiMapSelectCallBack(uireq)
    print("request from UI", 8852, "UIAscensionSendaiMapSelectMapCallBack")

    printT(uireq,"jkp-uireq")
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids,uireq.mode)
    table.insert(idsData.ids,uireq.pointId)
    table.insert(idsData.ids,uireq.level)

    return 1, 8852, idsData:SerializeToString()
end

function NetAscensionSendaiMapSelectCallBack(fd)
    print("request from Net", 8852, "NetAscensionSendaiMapQueryCallBack")

    local idsData = ids_pb.Ids()
    idsData:ParseFromString(fd.rbuf)

    local data = {}
    data.mode = idsData.ids[1] or 0 --难度
    data.pointId = idsData.ids[2] or 0 --格子id
    data.level = idsData.ids[3] or 0 --等级

    return { type = 8852, data = data}
end

--走格子
function UIAscensionSendaiRunPointCallBack(uireq)
    print("request from UI", 8853, "UIAscensionSendaiRunPointCallBack")

    gamedata.ext.event = uireq.event or {}

    local combData = combmessages_pb.CombMessages()

    local ids = ids_pb.Ids()
    table.insert(ids.ids, uireq.pointId)
    table.insert(ids.ids, uireq.event.id)

    local runPointExe = combData.messages:add()
    runPointExe.id = 1
    runPointExe.data = ids:SerializeToString()

    return 1, 8853, combData:SerializeToString()
end

function NetAscensionSendaiRunPointCallBack(fd)
    print("request from Net", 8853, "UIAscensionSendaiRunPointCallBack")

    local combData = combmessages_pb.CombMessages()
    combData:ParseFromString(fd.rbuf)

    local eventdata = {}
    local event = gamedata.ext.event
    -- printT(event,"jkp-event")
    if event.type == "adventure" then       --随机事件
        for k,v in ipairs(combData.messages) do
            if v.id == 1 then
                local ids = ids_pb.Ids()
                ids:ParseFromString(v.data)
                eventdata.id = ids.ids[1] or 0
            elseif v.id == 2 then
                local ids = ids_pb.Ids()
                ids:ParseFromString(v.data)
                eventdata.newPoint = ids.ids[1] or 0
                eventdata.pointState = ids.ids[2] or 0
            end
        end
    elseif event.type == "buy" then         --购买事件
        for k,v in ipairs(combData.messages) do
            if v.id == 1 then
                local ids = ids_pb.Ids()
                ids:ParseFromString(v.data)
                eventdata.sxynum = ids.ids[1] or 0
                eventdata.buyid = ids.ids[2] or 0 --购买id
                eventdata.buyBuffId1 = ids.ids[3] or 0
                eventdata.buyBuffId2 = ids.ids[4] or 0
                eventdata.buyBuffId3 = ids.ids[5] or 0
                eventdata.buyBuffId4 = ids.ids[6] or 0
            elseif v.id == 2 then
                local ids = ids_pb.Ids()
                ids:ParseFromString(v.data)
                eventdata.newPoint = ids.ids[1] or 0
                eventdata.pointState = ids.ids[2] or 0
            end
        end
    elseif event.type == "buff" then        --仙术事件
        for k,v in ipairs(combData.messages) do
            if v.id == 1 then
                local ids = ids_pb.Ids()
                ids:ParseFromString(v.data)
                eventdata.buffId1 = ids.ids[1] or 0
                eventdata.buffId2 = ids.ids[2] or 0
                eventdata.buffId3 = ids.ids[3] or 0
                eventdata.selectid = ids.ids[4] or 0 --选择id
            elseif v.id == 2 then
                local ids = ids_pb.Ids()
                ids:ParseFromString(v.data)
                eventdata.newPoint = ids.ids[1] or 0
                eventdata.pointState = ids.ids[2] or 0
            end
        end
    elseif event.type == "cheer" then       --协助事件
        for k,v in ipairs(combData.messages) do
            if v.id == 1 then
                local ids = ids_pb.Ids()
                ids:ParseFromString(v.data)
                eventdata.cheerId1 = ids.ids[1] or 0
                eventdata.cheerId2 = ids.ids[2] or 0
                eventdata.cheerId3 = ids.ids[3] or 0
                eventdata.cheerId4 = ids.ids[4] or 0
                eventdata.selectid = ids.ids[5] or 0 ----选择cid
            elseif v.id == 2 then
                local ids = ids_pb.Ids()
                ids:ParseFromString(v.data)
                eventdata.newPoint = ids.ids[1] or 0
                eventdata.pointState = ids.ids[2] or 0
            end
        end
    elseif event.type == "encounter" then   --仙遇事件
        for k,v in ipairs(combData.messages) do
            if v.id == 1 then
                local ids = ids_pb.Ids()
                ids:ParseFromString(v.data)
                eventdata.encounterId = ids.ids[1] or 0
                eventdata.encounter_complete = ids.ids[2] or 0
            elseif v.id == 2 then
                local ids = ids_pb.Ids()
                ids:ParseFromString(v.data)
                eventdata.newPoint = ids.ids[1] or 0
                eventdata.pointState = ids.ids[2] or 0
            end
        end
    elseif event.type == "recover" then     --恢复事件
        for k,v in ipairs(combData.messages) do
            if v.id == 1 then
                local ids = ids_pb.Ids()
                ids:ParseFromString(v.data)
                eventdata.recoverid = ids.ids[1] or 0
            elseif v.id == 2 then
                local ids = ids_pb.Ids()
                ids:ParseFromString(v.data)
                eventdata.newPoint = ids.ids[1] or 0
                eventdata.pointState = ids.ids[2] or 0
            end
        end
    elseif event.type == "revive" then      --复活事件
        for k,v in ipairs(combData.messages) do
            if v.id == 1 then
                local ids = ids_pb.Ids()
                ids:ParseFromString(v.data)
                eventdata.reviveid = ids.ids[1] or 0
            elseif v.id == 2 then
                local ids = ids_pb.Ids()
                ids:ParseFromString(v.data)
                eventdata.newPoint = ids.ids[1] or 0
                eventdata.pointState = ids.ids[2] or 0
            end
        end
    elseif event.type == "battle" or event.type == "battle1" then      --战斗事件
        for k,v in ipairs(combData.messages) do
            if v.id == 1 then
                local ids = ids_pb.Ids()
                ids:ParseFromString(v.data)
                eventdata.battleTobuff = ids.ids[1] or 0
            elseif v.id == 2 then
                local ids = ids_pb.Ids()
                ids:ParseFromString(v.data)
                eventdata.newPoint = ids.ids[1] or 0
                eventdata.pointState = ids.ids[2] or 0
            end
        end
        if eventdata.pointState > 0 then
            if eventdata.battleTobuff == 0 then
                eventdata.battleOver = 1
            end
        end
    elseif event.type == "boss" then        --boss事件
        for k,v in ipairs(combData.messages) do
            if v.id == 1 then
                local ids = ids_pb.Ids()
                ids:ParseFromString(v.data)
                eventdata.battleTobuff = ids.ids[1] or 0
            elseif v.id == 2 then
                local ids = ids_pb.Ids()
                ids:ParseFromString(v.data)
                eventdata.newPoint = ids.ids[1] or 0
                eventdata.pointState = ids.ids[2] or 0
            end
        end
        if eventdata.pointState > 0 then
            eventdata.bossOver = 1
        end
    elseif event.type == "reward" then      --奖励事件
        for k,v in ipairs(combData.messages) do
            if v.id == 1 then
                local SomeThings = somethings_pb.SomeThings()
                SomeThings:ParseFromString(v.data)
                eventdata.rewards = gamedata:SomethingProcess(SomeThings)
            elseif v.id == 2 then
                local ids = ids_pb.Ids()
                ids:ParseFromString(v.data)
                eventdata.newPoint = ids.ids[1] or 0
                eventdata.pointState = ids.ids[2] or 0
            end
        end
    end

    gamedata.ext.event = nil

    return { type = 8853, event = event, eventdata = eventdata}
end

--事件二次处理
function UIAscensionSendaiEventSetCallBack(uireq)
    print("request from UI", 8854, "UIAscensionSendaiEventSetCallBack")

    gamedata.ext.event = uireq.event or {}
    local combData = combmessages_pb.CombMessages()

    local ids = ids_pb.Ids()
    table.insert(ids.ids, uireq.pointId)
    table.insert(ids.ids, uireq.event.id)

    local setPointExe = combData.messages:add()
    setPointExe.id = 1
    setPointExe.data = ids:SerializeToString()

    local ids2 = ids_pb.Ids()

    if uireq.event.type == "buy" then             --购买事件
        table.insert(ids2.ids, uireq.selectId)
        table.insert(ids2.ids, 1)
    elseif uireq.event.type == "buff" then        --仙术事件
        table.insert(ids2.ids, uireq.selectId)
    elseif uireq.event.type == "cheer" then       --协助事件
        table.insert(ids2.ids, uireq.selectId)
    elseif uireq.event.type == "encounter" then   --仙遇事件
        table.insert(ids2.ids, uireq.selectId)
    elseif uireq.event.type == "recover" then     --恢复事件
        for k,v in pairs(uireq.selectId) do
            table.insert(ids2.ids, v)
        end
    elseif uireq.event.type == "revive" then      --复活事件
        for k,v in pairs(uireq.selectId) do
            table.insert(ids2.ids, v)
        end
    elseif uireq.event.type == "battle" or uireq.event.type == "battle1" then      --战斗事件
        for i=1,table.getTableLength(uireq.selectId) do
            table.insert(ids2.ids, uireq.selectId[tostring(i)])
        end
    elseif uireq.event.type == "boss" then        --BOSS战斗事件
        for i=1,table.getTableLength(uireq.selectId) do
            table.insert(ids2.ids, uireq.selectId[tostring(i)])
        end
    end

    local setPointExe = combData.messages:add()
    setPointExe.id = 2
    setPointExe.data = ids2:SerializeToString()

    return 1, 8854, combData:SerializeToString()
end

function NetAscensionSendaiEventSetCallBack(fd)
    print("request from Net", 8854, "NetAscensionSendaiEventSetCallBack")

    local combData = combmessages_pb.CombMessages()
    combData:ParseFromString(fd.rbuf)

    local eventdata = {}
    local event = gamedata.ext.event
    if event.type == "buy" then         --购买事件
        for k,v in ipairs(combData.messages) do
            if v.id == 1 then
                local ids = ids_pb.Ids()
                ids:ParseFromString(v.data)
                eventdata.buyBuffId = ids.ids[1] or 0
            end
        end
    elseif event.type == "buff" then        --仙术事件
        for k,v in ipairs(combData.messages) do
            if v.id == 1 then
                local ids = ids_pb.Ids()
                ids:ParseFromString(v.data)
                eventdata.buffId = ids.ids[1] or 0
            end
        end
    elseif event.type == "cheer" then       --协助事件
        for k,v in ipairs(combData.messages) do
            if v.id == 1 then
                local ids = ids_pb.Ids()
                ids:ParseFromString(v.data)
                eventdata.iid = ids.ids[1] or 0
                eventdata.gid = ids.ids[2] or 0 -- 0为助战伙伴
                eventdata.cid = ids.ids[3] or 0
                eventdata.maxhp = ids.ids[4] or 0
                eventdata.newhp = ids.ids[5] or 0
                eventdata.anger = ids.ids[6] or 0
                eventdata.level1 = ids.ids[7] or 0
                eventdata.level2 = ids.ids[8] or 0
                eventdata.illusionCid = 0 --幻化id
                eventdata.g_fashion = 0 --换肤标识
                eventdata.quality = gamedata.config.general[tostring(eventdata.cid)].quality or 0
            end
        end
    elseif event.type == "encounter" then   --仙遇事件
        for k,v in ipairs(combData.messages) do
            if v.id == 1 then
                local SomeThings = somethings_pb.SomeThings()
                SomeThings:ParseFromString(v.data)
                eventdata.rewards = gamedata:SomethingProcess(SomeThings)
            end
        end
    elseif event.type == "recover" then     --恢复事件 ***
        for k,v in ipairs(combData.messages) do
            if v.id == 1 then
                local ids = ids_pb.Ids()
                ids:ParseFromString(v.data)
                eventdata.iid = ids.ids[1] or 0
                eventdata.cid = ids.ids[2] or 0
                eventdata.newhp = ids.ids[3] or 0
            end
        end
    elseif event.type == "revive" then      --复活事件
        for k,v in ipairs(combData.messages) do
            if v.id == 1 then
                local ids = ids_pb.Ids()
                ids:ParseFromString(v.data)
                eventdata.iid = ids.ids[1] or 0
                eventdata.cid = ids.ids[2] or 0
                eventdata.newhp = ids.ids[3] or 0
            end
        end
    elseif event.type == "battle" or event.type == "battle1" then      --战斗事件
        for k,v in ipairs(combData.messages) do
            if v.id == 1 then
                local copyAttackResultPb = battleresult_pb.BattleResult()
                copyAttackResultPb:ParseFromString(v.data)

                eventdata.result = copyAttackResultPb.result
                eventdata.reward = gamedata:SomethingProcess(copyAttackResultPb.reward)
                eventdata.battlereport = PickBattleResultReport(copyAttackResultPb)
            elseif v.id == 2 then
                local ids = ids_pb.Ids()
                ids:ParseFromString(v.data)
                eventdata.eventId = ids.ids[1] or 0
            end
        end
    elseif event.type == "boss" then        --BOSS战斗事件
        for k,v in ipairs(combData.messages) do
            if v.id == 1 then
                local copyAttackResultPb = battleresult_pb.BattleResult()
                copyAttackResultPb:ParseFromString(v.data)

                eventdata.result = copyAttackResultPb.result
                eventdata.reward = gamedata:SomethingProcess(copyAttackResultPb.reward)
                eventdata.battlereport = PickBattleResultReport(copyAttackResultPb)
            end
        end
    end

    gamedata.ext.event = nil
    return { type = 8854, event = event, eventdata = eventdata }
end

--buff查询
function UIAscensionSendaiBufferQueryCallBack(uireq)
    print("request from UI", 8855, "UIAscensionSendaiBufferQueryCallBack")

    return 1, 8855, nil
end

function NetAscensionSendaiBufferQueryCallBack(fd)
    print("request from Net", 8855, "NetAscensionSendaiBufferQueryCallBack")

    local idsData = ids_pb.Ids()
    idsData:ParseFromString(fd.rbuf)

    local breakskill = gamedata.config.breakskill
    local buffers = {}
    if #idsData.ids > 0 then
        local index = (#idsData.ids)/2
        for i=1, index do
            local data = {}
            data.id = idsData.ids[(i-1)*2+1] or 0    --buffid
            data.state = idsData.ids[(i-1)*2+2] or 0 --buff是否过期
            data.quality = breakskill[tostring(data.id)].quality
            table.insert(buffers, data)
        end
    end

    table.sort(buffers, function (a,b)
        if a.quality == b.quality then
            return a.id > b.id
        else
            return a.quality > b.quality
        end
    end)

    return { type = 8855, buffers = buffers }
end

--升仙台商店查询
function UIAscensionSendaiShopCallBack(uireq)
    print("request from UI", 8856, "UIAscensionSendaiShopCallBack")

    return 1, 8856, nil
end

function NetAscensionSendaiShopCallBack(fd)
    print("request from Net", 8856, "NetAscensionSendaiShopCallBack")

    local idsData = ids_pb.Ids()
    idsData:ParseFromString(fd.rbuf)

    local shopdata = {}
    shopdata.time = idsData.ids[1] or 0
    shopdata.shengxianbi = idsData.ids[2] or 0
    local rewardData = {}
    for i=3, #idsData.ids do
        local data = {}
        data.id = i-2
        data.num = idsData.ids[i] or 0
        table.insert(rewardData, data)
    end

    for k,v in pairs(gamedata.config.shengxian_shop) do
        rewardData[v.id].priority = v.priority
    end
    local sortTable = function(a, b)
        return a.priority < b.priority
    end
    table.sort(rewardData, sortTable)
    printT(rewardData,"jkp-rewardData")

    return { type = 8856, shopdata = shopdata, data = rewardData}
end

--升仙台商店购买
function UIAscensionSendaiShopBuyCallBack(uireq)
    print("request from UI", 8857, "UIAscensionSendaiShopBuyCallBack")

    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.id)
    table.insert(idsData.ids, uireq.num)

    return 1, 8857, idsData:SerializeToString()
end

function NetAscensionSendaiShopBuyCallBack(fd)
    print("request from Net", 8857, "NetAscensionSendaiShopBuyCallBack")

    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    return { type = 8857, reward = gamedata:SomethingProcess(getData) }
end

--阵容镜像上传
function UIAscensionSendaiSlotGeneralsUpCallBack(uireq)
    print("request from UI", 8858, "UIAscensionSendaiSlotGeneralsUpCallBack")

    local ids = ids_pb.Ids()

    local slots = uireq.slotGenerals
    for i=1,table.getTableLength(slots) do
        print("slots"..i, slots[tostring(i)])
        table.insert(ids.ids, slots[tostring(i)])
    end

    return 1, 8858, ids:SerializeToString()
end

function NetAscensionSendaiSlotGeneralsUpCallBack(fd)
    print("request from Net", 8858, "NetAscensionSendaiSlotGeneralsUpCallBack")

    local idsData = ids_pb.Ids()
    idsData:ParseFromString(fd.rbuf)

    gamedata.cache.sendaiGenerals = {}
    if #idsData.ids > 0 then
        local index = (#idsData.ids)/10
        for i=1, index do
            local data = {}
            data.iid = idsData.ids[(i-1)*10+1] or 0
            data.gid = idsData.ids[(i-1)*10+2] or 0 -- 0为助战伙伴
            data.cid = idsData.ids[(i-1)*10+3] or 0
            data.maxhp = idsData.ids[(i-1)*10+4] or 0
            data.newhp = idsData.ids[(i-1)*10+5] or 0
            data.anger = idsData.ids[(i-1)*10+6] or 0
            data.level1 = idsData.ids[(i-1)*10+7] or 0
            data.level2 = idsData.ids[(i-1)*10+8] or 0
            data.illusionCid = idsData.ids[(i-1)*10+9] or 0 --幻化id
            data.g_fashion = idsData.ids[(i-1)*10+10] or 0 --换肤标识
            data.quality = gamedata.config.general[tostring(data.cid)].quality or 0
            table.insert(gamedata.cache.sendaiGenerals,data)
        end
    end

    return { type = 8858, sendaiGenerals = gamedata.cache.sendaiGenerals }
end

--武将镜像查询
function UIAscensionSendaiSlotGeneralsQueryCallBack(uireq)
    print("request from UI", 8859, "UIAscensionSendaiSlotGeneralsQueryCallBack")

    return 1, 8859, nil
end

function NetAscensionSendaiSlotGeneralsQueryCallBack(fd)
    print("request from Net", 8859, "NetAscensionSendaiSlotGeneralsQueryCallBack")

    local idsData = ids_pb.Ids()
    idsData:ParseFromString(fd.rbuf)

    gamedata.cache.sendaiGenerals = {}
    if #idsData.ids > 0 then
        local index = (#idsData.ids)/10
        for i=1, index do
            local data = {}
            data.iid = idsData.ids[(i-1)*10+1] or 0
            data.gid = idsData.ids[(i-1)*10+2] or 0 -- 0为助战伙伴
            data.cid = idsData.ids[(i-1)*10+3] or 0
            data.maxhp = idsData.ids[(i-1)*10+4] or 0
            data.newhp = idsData.ids[(i-1)*10+5] or 0
            data.anger = idsData.ids[(i-1)*10+6] or 0
            data.level1 = idsData.ids[(i-1)*10+7] or 0
            data.level2 = idsData.ids[(i-1)*10+8] or 0
            data.illusionCid = idsData.ids[(i-1)*10+9] or 0 --幻化id
            data.g_fashion = idsData.ids[(i-1)*10+10] or 0 --换肤标识
            data.quality = gamedata.config.general[tostring(data.cid)].quality or 0
            data.hp_ratio = (data.newhp/data.maxhp)*100 --血量百分比
            table.insert(gamedata.cache.sendaiGenerals,data)
        end
    end

    return { type = 8859, sendaiGenerals = gamedata.cache.sendaiGenerals, enemyData = gamedata.cache.d_sendaiGenerals, generals = gamedata.cache.generals }
end

--武将布阵
function UIAscensionSendaiSlotGeneralsChangeCallBack(uireq)
    print("request from UI", 88591, "UIAscensionSendaiSlotGeneralsQueryCallBack")

    return 0, 88591, { type = 88591, sendaiGenerals = gamedata.cache.sendaiGenerals, enemyData = gamedata.cache.d_sendaiGenerals, generals = gamedata.cache.generals }
end

--怪物阵容查询
function UIAscensionSendaiSlotMonsterQueryCallBack(uireq)
    print("request from UI", 8860, "UIAscensionSendaiSlotMonsterQueryCallBack")

    local ids = ids_pb.Ids()
    table.insert(ids.ids, uireq.pointId)
    table.insert(ids.ids, uireq.eventId)

    return 1, 8860, ids:SerializeToString()

end

function NetAscensionSendaiSlotMonsterQueryCallBack(fd)
    print("request from Net", 8860, "NetAscensionSendaiSlotMonsterQueryCallBack")

    local idsData = ids_pb.Ids()
    idsData:ParseFromString(fd.rbuf)

    gamedata.cache.d_sendaiGenerals = {}
    if #idsData.ids > 0 then
        local index = (#idsData.ids)/4
        for i=1, index do
            local data = {}
            data.iid = idsData.ids[(i-1)*4+1] or 0
            data.newhp = idsData.ids[(i-1)*4+2] or 0
            data.maxhp = idsData.ids[(i-1)*4+3] or 0
            data.anger = idsData.ids[(i-1)*4+4] or 0
            table.insert(gamedata.cache.d_sendaiGenerals,data)
        end
    end
    
    return { type = 8860, enemyData = gamedata.cache.d_sendaiGenerals}
end