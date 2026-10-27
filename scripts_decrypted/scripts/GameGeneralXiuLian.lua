--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 18-6-30
-- Time: 下午2:57
-- To change this template use File | Settings | File Templates.
--
local isGet = false
function UIGeneralXiuLianLevelInfoCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5511, "GeneralXiuLianLevelInfo")
    if uireq.update then
        return 1, 5511,nil
    else
        if isGet then
            return 0,5511,{type = 5511,isUpdate = false}
        else
            return 1, 5511,nil
        end
    end
end


function NetGeneralXiuLianLevelInfoCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5511, "GeneralXiuLianLevelInfo")
    local info = ids_pb.Ids()
    info:ParseFromString(fd.rbuf)

    local generalLevels = {}
    for i = 1,10000000,3 do
        if info.ids[i] then
            generalLevels[info.ids[i]] = {level6 = info.ids[i + 1],level7 = info.ids[i + 2]}
        else
            break
        end
    end
    
    for k,v in pairs(generalLevels) do
        if gamedata.cache.generals[k] then
            gamedata.cache.generals[k].level6 = v.level6 or 0
            gamedata.cache.generals[k].level7 = v.level7 or 0
        end
    end
    isGet = true
    return { 
        type = 5511,
        isUpdate = true,
    }
end

function UIGeneralXiuLianInfoCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5512, "GeneralXiuLianInfo")
    if uireq.update then
        if gamedata.cache.xiuLianData and gamedata.cache.xiuLianData[uireq.iid] then
            return 0,5512,{type = 5512,general = gamedata.cache.xiuLianData[uireq.iid]}
        end
        local info = ids_pb.Ids()
        table.insert(info.ids, uireq.iid)
        gamedata.ext.xiuLianInfoIid = uireq.iid
        return 1, 5512, info:SerializeToString()
    else
        local info = ids_pb.Ids()
        table.insert(info.ids, uireq.iid)
        gamedata.ext.xiuLianInfoIid = uireq.iid
        return 1, 5512, info:SerializeToString()
    end

end



function NetGeneralXiuLianInfoCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5512, "GeneralXiuLianInfo")
    local info = ids_pb.Ids()
    info:ParseFromString(fd.rbuf)

    local generalXiuLian = {
        iid = gamedata.ext.xiuLianInfoIid,
        attr1 = info.ids[2],
        attr2 = info.ids[3],
        attr3 = info.ids[4],
        heart1 = info.ids[5],
        attr5 = info.ids[7],
        attr6 = info.ids[8],
        attr7 = info.ids[9],
        heart2 = info.ids[10],
    }
    for i = 1,3 do
        local str = gamedata.config.Immortal_type[tostring(1)]["attr"..i]
        local _,time = gamedata.getAttr2Data(str)
        generalXiuLian["attr"..i] = generalXiuLian["attr"..i] * time

        str = gamedata.config.Immortal_type[tostring(2)]["attr"..i]
        _,time =  gamedata.getAttr2Data(str)
        generalXiuLian["attr"..(i + 4)] = generalXiuLian["attr"..(i + 4)] * time
    end

    local level6 = gamedata.cache.generals[gamedata.ext.xiuLianInfoIid].level6 - 1
    local level7 = gamedata.cache.generals[gamedata.ext.xiuLianInfoIid].level7 - 1
    
    while level6 >= 0 do
        local config = gamedata.config.Immortal_level[tostring(1)][tostring(level6)]
        for i = 1,3 do
            local _,num = gamedata.getAttr2Data(config["stageAttr"..i])
            generalXiuLian["attrA"..i] = (generalXiuLian["attrA"..i] and generalXiuLian["attrA"..i] or 0) + num
        end
        level6 = level6 - 1
    end

    while level7 >= 0 do
        local config = gamedata.config.Immortal_level[tostring(2)][tostring(level7)]
        for i = 1,3 do
            local _,num = gamedata.getAttr2Data(config["stageAttr"..i])
            generalXiuLian["attrA"..(i + 4)] = (generalXiuLian["attrA"..(i + 4)] and generalXiuLian["attrA"..(i + 4)] or 0) + num
        end
        level7 = level7 - 1
    end

    for i = 1,3 do
        generalXiuLian["attr"..i] = generalXiuLian["attr"..i] + (generalXiuLian["attrA"..i] and generalXiuLian["attrA"..i] or 0)
        generalXiuLian["attr"..(i + 4)] = generalXiuLian["attr"..(i + 4)] + (generalXiuLian["attrA"..(i + 4)] and generalXiuLian["attrA"..(i + 4)] or 0)
    end
    if not gamedata.cache.xiuLianData then
        gamedata.cache.xiuLianData = {}
    end
    gamedata.cache.xiuLianData[gamedata.ext.xiuLianInfoIid] = generalXiuLian
    return { 
        type = 5512, 
        general = generalXiuLian,
    }
end


function UIGeneralXiuLianCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5513, "GeneralXiuLian")
    local info = ids_pb.Ids()
    table.insert(info.ids,uireq.iid)
    table.insert(info.ids,uireq.xiuLian)
    table.insert(info.ids,uireq.isBreak)
    
    gamedata.ext.xiuLianIid = uireq.iid
    gamedata.ext.xiuLianUse = uireq.useIds
    gamedata.ext.xiuLianType = uireq.xiuLian

    local general = gamedata.cache.generals[gamedata.ext.xiuLianIid]
    local xiuLianData = gamedata.cache.xiuLianData[gamedata.ext.xiuLianIid]
    local cids = {}
    local config
    if gamedata.ext.xiuLianType == 1 then
        config = gamedata.config.Immortal_level[tostring(1)][tostring(general.level6)]
    else
        config = gamedata.config.Immortal_level[tostring(2)][tostring(general.level7)]
    end

    local isNeedGet = true
    if gamedata.ext.xiuLianType == 1 then
        if xiuLianData.heart1 >= config.character then
            local configNext = gamedata.config.Immortal_level[tostring(1)][tostring(general.level6 + 1)]
            if configNext then
                cids = gamedata.getIDandNUMs(config.extraConsume)
            end
        else
            cids = gamedata.getIDandNUMs(config.consumeEveryTimes)
        end
    else
        if xiuLianData.heart2 >= config.character then
            local configNext = gamedata.config.Immortal_level[tostring(2)][tostring(general.level7 + 1)]
            if configNext then
                cids = gamedata.getIDandNUMs(config.extraConsume)
            end
            
        else
            cids = gamedata.getIDandNUMs(config.consumeEveryTimes)
        end
    end

    gamedata.ext.xiuLianUse = cids

    return 1,5513, info:SerializeToString()
end


function NetGeneralXiuLianCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver",5513, "GeneralXiuLian")

    local info = combmessages_pb.CombMessages()
    info:ParseFromString(fd.rbuf)

    local xiuLianLevel1,xiuLianLevel2,generalXiuLian
    for k,v in ipairs(info.messages) do
        if v.id == 0 then
            local general = generals_pb.Generals()
            general:ParseFromString(v.data)
            gamedata:Generals(general.generals)
        elseif v.id == 1 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            generalXiuLian = {
                iid = gamedata.ext.xiuLianIid,
                attr1 = ids.ids[2],
                attr2 = ids.ids[3],
                attr3 = ids.ids[4],
                heart1 = ids.ids[5],
                attr5 = ids.ids[7],
                attr6 = ids.ids[8],
                attr7 = ids.ids[9],
                heart2 = ids.ids[10],
            }
            xiuLianLevel1 = ids.ids[1]
            xiuLianLevel2 = ids.ids[6]

            for i = 1,3 do
                local str = gamedata.config.Immortal_type[tostring(1)]["attr"..i]
                local _,time = gamedata.getAttr2Data(str)
                generalXiuLian["attr"..i] = generalXiuLian["attr"..i] * time
        
                str = gamedata.config.Immortal_type[tostring(2)]["attr"..i]
                _,time = gamedata.getAttr2Data(str)
                generalXiuLian["attr"..(i + 4)] = generalXiuLian["attr"..(i + 4)] * time
            end
            
        end
    end
    
    for i = 1,3 do
        generalXiuLian["attrA"..i] = gamedata.cache.xiuLianData[gamedata.ext.xiuLianIid]["attrA"..i] or 0
        generalXiuLian["attrA"..(i + 4)] = gamedata.cache.xiuLianData[gamedata.ext.xiuLianIid]["attrA"..(i + 4)] or 0
    end
    
    local primeL = gamedata.cache.generals[gamedata.ext.xiuLianIid].level6
    if primeL < xiuLianLevel1 then
        local config = gamedata.config.Immortal_level[tostring(1)][tostring(primeL)]
        for i = 1,3 do
            local _,num = gamedata.getAttr2Data(config["stageAttr"..i])
            generalXiuLian["attrA"..i] = generalXiuLian["attrA"..i] + num
        end
    end

    primeL = gamedata.cache.generals[gamedata.ext.xiuLianIid].level7 
    if primeL < xiuLianLevel2 then
        local config = gamedata.config.Immortal_level[tostring(2)][tostring(primeL)]
        for i = 1,3 do
            local _,num = gamedata.getAttr2Data(config["stageAttr"..i])
            generalXiuLian["attrA"..(i + 4)] = generalXiuLian["attrA"..(i + 4)]  + num
        end
    end
    
    for i = 1,3 do
        generalXiuLian["attr"..i] = generalXiuLian["attr"..i] + (generalXiuLian["attrA"..i] and generalXiuLian["attrA"..i] or 0)
        generalXiuLian["attr"..(i + 4)] = generalXiuLian["attr"..(i + 4)] + (generalXiuLian["attrA"..(i + 4)] and generalXiuLian["attrA"..(i + 4)] or 0)
    end
    
    gamedata.cache.xiuLianData[gamedata.ext.xiuLianIid] = generalXiuLian
    gamedata.cache.generals[gamedata.ext.xiuLianIid].level6 = xiuLianLevel1 or 0
    gamedata.cache.generals[gamedata.ext.xiuLianIid].level7 = xiuLianLevel2 or 0



    for k,v in pairs(gamedata.ext.xiuLianUse) do
        gamedata:updateStaff({cid = v.cid,num = -v.num,name = "武将修炼"})
    end
    return {
        type = 5513,
        general = gamedata.cache.generals[gamedata.ext.xiuLianIid],
        generalXiuLian = gamedata.cache.xiuLianData[gamedata.ext.xiuLianIid],
        ison = gamedata:isGeneralOn(gamedata.ext.xiuLianIid),
    }
   
end
  �&  