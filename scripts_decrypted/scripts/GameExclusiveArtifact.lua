--
-- Author: songyibo
-- Date: 2021-03-16 13:44:07
--
local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")
local combmessages_pb = require("combmessages_pb")
local params_pb = require("params_pb")

local function getProps()
    local props = {
        [192087] = gamedata:getPropNum(192087),
        [192088] = gamedata:getPropNum(192088),
        [192089] = gamedata:getPropNum(192089),
        [192090] = gamedata:getPropNum(192090),
        [192091] = gamedata:getPropNum(192091),
    }
    return props
end

function makeAllQilingForLoction()
    local qiLingDatas = {}
    for k,v in pairs(gamedata.cache.exclusiveArtifactQiLing) do
        if not qiLingDatas[v.location] then
            qiLingDatas[v.location] = {}
        end
        table.insert(qiLingDatas[v.location],v)
    end

    for k,v in pairs(qiLingDatas) do
        gamedata.sortData(v,"quality",nil,nil,nil,nil,nil,false)
    end
    return qiLingDatas
end


local function makeAllQilingTemp()
    local qilings = table.copy(gamedata.cache.exclusiveArtifactQiLing)
    for k,v in pairs(qilings) do
        v.generalIid = nil
        v.exclusiveCid = nil
        v.ison = 0
        --是否镶嵌
        for k2,v2 in pairs(gamedata.cache.exclusiveArtifact) do
            local isfind = false
            for k3=1,6 do
                if v2["inlayId"..k3] == v.iid then
                    isfind = true
                    v.generalIid = v2.generalIid
                    v.exclusiveCid = v2.cid
                    v.ison = 1
                    break
                end
            end
            if isfind then
                break
            end
        end
    end
    return qilings
end

function makeQilingHint()
    local exclusiveArtifactQiLing = makeAllQilingTemp()
    mekehintext(612,0)
    print("makeQilingHint")

    for k,v in pairs(exclusiveArtifactQiLing) do
        --镶嵌且可强化 提示红点
        if v.ison == 1 then

            printT(v,"QiLing")
            local qilingConfig = gamedata.config.exclusive_device_spirit[tostring(v.cid)]
            local nextIntensifyConfig = gamedata.config.exclusive_device_spirit_intensify[tostring(qilingConfig.intensify_bonus_way)][tostring(v.level + 1)]
            --满级
            if nextIntensifyConfig then

                printT(nextIntensifyConfig,"nextIntensifyConfig")
                local consumeProp = gamedata.getIDandNUMs(nextIntensifyConfig.consumption)[1]
                print(gamedata:getPropNum(consumeProp.cid))
                if gamedata:getPropNum(consumeProp.cid) >= consumeProp.num then
                    mekehintext(612,1)
                    break
                end
            end
        end
    end
end

function makeTokenBagHint()
    print("makeTokenBagHint")
    mekehintext(632,0)
    local startnum = 202101
    local endnum = 202300
    for v = startnum,endnum do
        print("tokenbaghint==",v)
        local propdata = gamedata.cache.props[tonumber(v)]
        if propdata then
            printT(propdata,"makeTokenBagHint propdata")
            local data = gamedata.config.token_fragment[tostring(propdata.cid)]
            if data then
                printT(data,"makeTokenBagHint data")
               if data.neednum <= propdata.num then
                   mekehintext(632,1)
               end 
            end    
        end
    end    
end

function UIExclusiveArtifactQueryCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8101, "ExclusiveArtifactQuery")
    printT(uireq,"uireq")
    local ids = ids_pb.Ids()
    table.insert(ids.ids, uireq.generalIid)
    gamedata.ext.ExclusiveArtifactQueryGeneralIid = uireq.generalIid
    return 1, 8101, ids:SerializeToString()
end

function NetExclusiveArtifactQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8101, "ExclusiveArtifactQuery")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    gamedata.cache.exclusiveArtifact = {}
    gamedata:ExclusiveArtifactDatas(ids.ids)
    return { type = 8101,exclusiveArtifacts = gamedata.cache.exclusiveArtifact}
end

function UIExclusiveArtifactStrengthenCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8102, "ExclusiveArtifactStrengthen")
    printT(uireq,"uireq")

    local ids = ids_pb.Ids()
    table.insert(ids.ids, uireq.generalIid)
    table.insert(ids.ids, uireq.num)
    gamedata.ext.ExclusiveArtifactStrengthenInfo = uireq

    return 1, 8102, ids:SerializeToString()
end

function NetExclusiveArtifactStrengthenCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8102, "ExclusiveArtifactStrengthen")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    local artifactData = gamedata.cache.exclusiveArtifact[gamedata.ext.ExclusiveArtifactStrengthenInfo.generalIid]
    
    --强化到下一级是洗礼 直接跳至洗礼等级

    local curlevel = artifactData.level + gamedata.ext.ExclusiveArtifactStrengthenInfo.num
    if gamedata.ext.ExclusiveArtifactStrengthenInfo.num == 0 then
        --洗礼 传0次
        curlevel = curlevel + 1
    end
    
    local exclusiveConfig = gamedata.config.exclusive[tostring(artifactData.cid)]
    local nextIntensifyConfig = gamedata.config.exclusive_intensify[tostring(exclusiveConfig.intensify_type)][tostring(curlevel + 1)]
    if nextIntensifyConfig and nextIntensifyConfig.intensify_level == 0 then
        curlevel = nextIntensifyConfig.id
    end
    artifactData.level = curlevel

    gamedata:ExclusiveArtifactData(artifactData,true)

    --更新道具数量
    gamedata:updateStaff({cid = gamedata.ext.ExclusiveArtifactStrengthenInfo.spend.cid, num = -gamedata.ext.ExclusiveArtifactStrengthenInfo.spend.num})

    return { type = 8102,exclusiveArtifact = artifactData,props = getProps()}
end


function UIExclusiveArtifactActiveCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8103, "ExclusiveArtifactActive")
    printT(uireq,"uireq")

    local ids = ids_pb.Ids()
    table.insert(ids.ids, uireq.generalIid)
    gamedata.ext.ExclusiveArtifactActiveInfo = uireq

    return 1, 8103, ids:SerializeToString()
end

function NetExclusiveArtifactActiveCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8103, "ExclusiveArtifactActive")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local t = {
        type = 8103,
    }
    
    for k,v in ipairs(datas.messages) do
        if v.id == 1 then
            local BattleResultPb = battleresult_pb.BattleResult()
            BattleResultPb:ParseFromString(v.data)
            t.battlereport = PickBattleResultReport(BattleResultPb)
            t.result = BattleResultPb.result
            t.reward = gamedata:SomethingProcess(BattleResultPb.reward)
        elseif v.id == 2 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            local exclusiveArtifactDatas = gamedata:ExclusiveArtifactDatas(ids.ids)
            local exclusiveArtifactData = exclusiveArtifactDatas[1]
            t.exclusiveArtifact = exclusiveArtifactData
            local general = gamedata.cache.generals[gamedata.ext.ExclusiveArtifactActiveInfo.generalIid]
            t.generalCid = general.cid
            t.exclusiveCid = exclusiveArtifactData.cid
        end
    end

    --更新挑战次数
    if not gamedata.cache.exclusiveArtifactChallengeTimes[gamedata.ext.ExclusiveArtifactActiveInfo.generalIid] then
        gamedata.cache.exclusiveArtifactChallengeTimes[gamedata.ext.ExclusiveArtifactActiveInfo.generalIid] = 0
    end
    gamedata.cache.exclusiveArtifactChallengeTimes[gamedata.ext.ExclusiveArtifactActiveInfo.generalIid] = gamedata.cache.exclusiveArtifactChallengeTimes[gamedata.ext.ExclusiveArtifactActiveInfo.generalIid] + 1

    return t
end

function UIExclusiveArtifactInlayCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8104, "ExclusiveArtifactInlay")
    printT(uireq,"uireq")

    local ids = ids_pb.Ids()
    table.insert(ids.ids, uireq.generalIid)
    table.insert(ids.ids, uireq.pos)
    table.insert(ids.ids, uireq.qiLingIid)

    gamedata.ext.ExclusiveArtifactInlayInfo = uireq

    return 1, 8104, ids:SerializeToString()
end

function NetExclusiveArtifactInlayCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8104, "ExclusiveArtifactInlay")
    local changeQilingDatas = {}
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local oldArtifactData = table.copy(gamedata.cache.exclusiveArtifact[gamedata.ext.ExclusiveArtifactInlayInfo.generalIid])
    local oldQiLingIid = oldArtifactData["inlayId"..gamedata.ext.ExclusiveArtifactInlayInfo.pos]
    local newQiLingIid = gamedata.ext.ExclusiveArtifactInlayInfo.qiLingIid

    if oldQiLingIid > 0 then
        gamedata.cache.exclusiveArtifactQiLing[oldQiLingIid].generalIid = nil
        gamedata.cache.exclusiveArtifactQiLing[oldQiLingIid].exclusiveCid = nil
        gamedata.cache.exclusiveArtifactQiLing[oldQiLingIid].ison = 0
        table.insert(changeQilingDatas,gamedata.cache.exclusiveArtifactQiLing[oldQiLingIid])
    end
    
    if newQiLingIid > 0 and gamedata.cache.exclusiveArtifactQiLing[newQiLingIid] then
    	gamedata.cache.exclusiveArtifactQiLing[newQiLingIid].generalIid = oldArtifactData.generalIid
        gamedata.cache.exclusiveArtifactQiLing[newQiLingIid].exclusiveCid = oldArtifactData.cid
        gamedata.cache.exclusiveArtifactQiLing[newQiLingIid].ison = 1
        table.insert(changeQilingDatas,gamedata.cache.exclusiveArtifactQiLing[newQiLingIid])
    end

    local changeArtifactDatas = gamedata:ExclusiveArtifactDatas(ids.ids)

    local artifactData = gamedata.cache.exclusiveArtifact[gamedata.ext.ExclusiveArtifactInlayInfo.generalIid]
    local activeSuitId = nil
    for i=1,3 do
        if artifactData["suitId"..i] ~= oldArtifactData["suitId"..i] then
            activeSuitId = artifactData["suitId"..i]
        end
    end

    return { type = 8104,changeArtifactDatas = changeArtifactDatas,changeQilingDatas = changeQilingDatas,activeSuitId = activeSuitId}
end

function UIExclusiveArtifactQiLingQueryCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8105, "ExclusiveArtifactQiLingQuery")
    return 1, 8105, nil
end

function NetExclusiveArtifactQiLingQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8105, "ExclusiveArtifactQiLingQuery")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    print("ExclusiveArtifactQiLingQuery",#ids.ids)
    gamedata:ExclusiveArtifactQiLingDatas(ids.ids)
    return { type = 8105,qiLingDatas = gamedata.cache.exclusiveArtifactQiLing}
end

function UIExclusiveArtifactQiLingUpdateCallback(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 81051, "ExclusiveArtifactQiLingUpdate")
    return 0, 81051, {type = 81051, qiLingDatas = gamedata.cache.exclusiveArtifactQiLing}
end

function UIExclusiveArtifactQiLingStrengthenCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8106, "ExclusiveArtifactQiLingStrengthen")
    printT(uireq,"uireq")

    local ids = ids_pb.Ids()
    table.insert(ids.ids, uireq.qiLingIid)
    gamedata.ext.ExclusiveArtifactQiLingStrengthenInfo = uireq

    return 1, 8106, ids:SerializeToString()
end

function NetExclusiveArtifactQiLingStrengthenCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8106, "ExclusiveArtifactQiLingStrengthen")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local islevelup = nil
    local oldQiLingLevel = gamedata.cache.exclusiveArtifactQiLing[gamedata.ext.ExclusiveArtifactQiLingStrengthenInfo.qiLingIid].level
    gamedata:ExclusiveArtifactQiLingDatas(ids.ids)
    local qiLingData = gamedata.cache.exclusiveArtifactQiLing[gamedata.ext.ExclusiveArtifactQiLingStrengthenInfo.qiLingIid]

    if qiLingData.level > oldQiLingLevel then
        islevelup = true
    end
    --更新道具数量
    gamedata:updateStaff({cid = gamedata.ext.ExclusiveArtifactQiLingStrengthenInfo.spend.cid, num = -gamedata.ext.ExclusiveArtifactQiLingStrengthenInfo.spend.num})
    return { type = 8106,data = qiLingData,islevelup = islevelup}
end


function UIExclusiveArtifactQiLingLockCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8107, "ExclusiveArtifactQiLingLock")
    printT(uireq,"uireq")

    local ids = ids_pb.Ids()
    table.insert(ids.ids, uireq.qiLingIid)
    table.insert(ids.ids, uireq.lock)

    gamedata.ext.ExclusiveArtifactQiLingLockInfo = uireq

    return 1, 8107, ids:SerializeToString()
end

function NetExclusiveArtifactQiLingLockCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8107, "ExclusiveArtifactQiLingLock")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    local qiLingData = gamedata.cache.exclusiveArtifactQiLing[gamedata.ext.ExclusiveArtifactQiLingLockInfo.qiLingIid]
    qiLingData.lock = gamedata.ext.ExclusiveArtifactQiLingLockInfo.lock
    return { type = 8107,data = qiLingData}
end



function UIExclusiveArtifactQiLingRefiningCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8108, "ExclusiveArtifactQiLingRefining")
    printT(uireq,"uireq")
    local ids = ids_pb.Ids()
    for k,v in pairs(uireq.iids) do
        table.insert(ids.ids, v)
    end
    gamedata.ext.ExclusiveArtifactQiLingRefiningInfo = uireq
    return 1, 8108, ids:SerializeToString()
end

function NetExclusiveArtifactQiLingRefiningCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8108, "ExclusiveArtifactQiLingRefining")
    for k,v in pairs(gamedata.ext.ExclusiveArtifactQiLingRefiningInfo.iids) do
        gamedata.cache.exclusiveArtifactQiLing[v] = nil
    end

    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)
    return { type = 8108,data = gamedata.cache.exclusiveArtifactQiLing,reward = gamedata:SomethingProcess(getData)}
end

function UIExclusiveArtifacActiveChallengeQueryCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8109, "ExclusiveArtifacActiveChallengeQuery")

    if (not next(gamedata.cache.exclusiveArtifactChallengeTimes)) or uireq.update then
        return 1, 8109, nil
    else
        return 0,8109,{ type = 8109,data = gamedata.cache.exclusiveArtifactChallengeTimes}
    end
end

function NetExclusiveArtifacActiveChallengeQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8109, "ExclusiveArtifacActiveChallengeQuery")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    for i=1,#ids.ids/2 do
        gamedata.cache.exclusiveArtifactChallengeTimes[ids.ids[2*i-1]] = ids.ids[2*i]
    end
    return { type = 8109,data = gamedata.cache.exclusiveArtifactChallengeTimes}
end


-- 专属副本
function UIExclusiveArtifactCopyCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8201, "ExclusiveArtifactCopyCallBack")

    if uireq.index then
        gamedata.ext.ExclusiveArtifactCopyFightId = uireq.index
    end

    return 1, 8201, nil
end

function NetExclusiveArtifactCopyCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8201, "ExclusiveArtifactCopyCallBack")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local qiHunCopyNum = 0
    local qiHunCopyData = {}
    local qiLingCopyNum = {}
    local qiLingCopyData = {}
    for k,v in ipairs(datas.messages) do
        if v.id == 1 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            local data = ids.ids
            qiHunCopyNum = data[1] or 0
            for k,v in ipairs(data) do
                if k > 1 then
                    if v > 0 then
                        table.insert(qiHunCopyData,v)
                    else
                        table.insert(qiHunCopyData,v)
                        break
                    end
                end 
            end
        elseif v.id == 2 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)

            local data = ids.ids
            for i=1,6 do
                qiLingCopyData[tostring(i)] = {}
                qiLingCopyData[tostring(i)].num = data[i]
                qiLingCopyData[tostring(i)].difficulty = 1
                qiLingCopyData[tostring(i)].copy1 = data[(i-1)*6+7]
                if qiLingCopyData[tostring(i)].copy1 > 0 then
                    qiLingCopyData[tostring(i)].difficulty = 1
                end
                qiLingCopyData[tostring(i)].copy2 = data[(i-1)*6+8]
                if qiLingCopyData[tostring(i)].copy2 > 0 then
                    qiLingCopyData[tostring(i)].difficulty = 2
                end
                qiLingCopyData[tostring(i)].copy3 = data[(i-1)*6+9]
                if qiLingCopyData[tostring(i)].copy3 > 0 then
                    qiLingCopyData[tostring(i)].difficulty = 3
                end
                qiLingCopyData[tostring(i)].copy4 = data[(i-1)*6+10]
                if qiLingCopyData[tostring(i)].copy4 > 0 then
                    qiLingCopyData[tostring(i)].difficulty = 4
                end
                qiLingCopyData[tostring(i)].copy5 = data[(i-1)*6+11]
                if qiLingCopyData[tostring(i)].copy5 > 0 then
                    qiLingCopyData[tostring(i)].difficulty = 5
                end
                qiLingCopyData[tostring(i)].copy6 = data[(i-1)*6+12]
                if qiLingCopyData[tostring(i)].copy6 > 0 then
                    qiLingCopyData[tostring(i)].difficulty = 6
                end
            end
        end
    end

    return { type = 8201, qhNum = qiHunCopyNum, qhData = qiHunCopyData, qlData = qiLingCopyData, rolelv = gamedata.cache.role.level or 0, index = gamedata.ext.ExclusiveArtifactCopyFightId or 0}
end

function UIExclusiveArtifactCopyFightCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8202, "ExclusiveArtifactCopyFightCallBack")

    local idsData = ids_pb.Ids()

    gamedata.ext.ExclusiveArtifactCopyFightState = uireq.state

    if uireq.state == 1 then
        table.insert(idsData.ids, uireq.id)
    else
        table.insert(idsData.ids, uireq.id)
        table.insert(idsData.ids, uireq.difficulty or 1)
        gamedata.ext.ExclusiveArtifactCopyFightId = uireq.id
        gamedata.ext.ExclusiveArtifactCopyFightDifficulty = uireq.difficulty or 1
    end

    return 1, 8202, idsData:SerializeToString()
end

function NetExclusiveArtifactCopyFightCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8202, "ExclusiveArtifactCopyFightCallBack")

    local t = {
        type = 8202,
    }

    local BattleResultPb = battleresult_pb.BattleResult()
    BattleResultPb:ParseFromString(fd.rbuf)

    -- print(BattleResultPb)

    t.battlereport = PickBattleResultReport(BattleResultPb)
    t.result = BattleResultPb.result
    t.reward = gamedata:SomethingProcess(BattleResultPb.reward)

    if gamedata.ext.ExclusiveArtifactCopyFightState == 2 then
        t.index = gamedata.ext.ExclusiveArtifactCopyFightId
        gamedata:updateRoleStamina(-gamedata.config.exclusive_device_spirit_copy[tostring(gamedata.ext.ExclusiveArtifactCopyFightId)][tostring(gamedata.ext.ExclusiveArtifactCopyFightDifficulty)].physical)
    end

    return t
end

function UIExclusiveArtifactCopySweepCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8203, "ExclusiveArtifactCopySweepCallBack")

    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.id)

    return 1, 8203, idsData:SerializeToString()
end

function NetExclusiveArtifactCopySweepCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8203, "ExclusiveArtifactCopySweepCallBack")

    local t = {
        type = 8203,
    }

    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    t.reward = gamedata:SomethingProcess(getData)
    
    return t
end


function UIExclusiveArtifactResetCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8204, "ExclusiveArtifactReset")
    printT(uireq,"uireq")

    local ids = ids_pb.Ids()
    table.insert(ids.ids, uireq.generalIid)
    gamedata.ext.ExclusiveArtifactReset = uireq

    return 1, 8204, ids:SerializeToString()
end

function NetExclusiveArtifactResetCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8204, "ExclusiveArtifactReset")
    
    local exclusiveArtifact = gamedata.cache.exclusiveArtifact[gamedata.ext.ExclusiveArtifactReset.generalIid]
    
    local changeQilingDatas = {}
    --去掉器灵
    for i=1,6 do
        if exclusiveArtifact["inlayId"..i] > 0 then
            local qiling = gamedata.cache.exclusiveArtifactQiLing[exclusiveArtifact["inlayId"..i]]
            qiling.generalIid          = nil
            qiling.exclusiveCid        = nil
            qiling.ison                = 0

            table.insert(changeQilingDatas,qiling)
        end
        exclusiveArtifact["inlayId"..i] = 0
    end

    exclusiveArtifact.level  = 0
    exclusiveArtifact.suitId1 = 0
    exclusiveArtifact.suitId2 = 0
    exclusiveArtifact.suitId3 = 0

    exclusiveArtifact.intensify_level = 0
    exclusiveArtifact.baptism_level = 0
    exclusiveArtifact.maxlevel = 0
    exclusiveArtifact.maxlevel = 0

    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)
    --更新道具数量
    gamedata:updateStaff({cid = 1025, num = -gamedata.ext.ExclusiveArtifactReset.gold})
    return { type = 8204,reward = gamedata:SomethingProcess(getData),exclusiveArtifact = exclusiveArtifact,changeQilingDatas = changeQilingDatas}
end


 �V  