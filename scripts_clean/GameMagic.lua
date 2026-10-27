--法宝请求
--zhangzhixn

local combmessages_pb = require("combmessages_pb")
local ids_pb = require("ids_pb")
local slots_pb = require("slots_pb")
local stoneID = 20270
local g_goldID = 1025
--法宝查询
function UIInstrumentQueryCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1360, "InstrumentQuery")
    gamedata.ext.magicdata = uireq.id or -1
    return 1, 1360, nil
end
function NetInstrumentQueryCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1360, "InstrumentQuery")

	local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    gamedata:magic(ids.ids)
    return 
    { 
        type = 1360, 
        data = gamedata.cache.magicdata,
        id = gamedata.ext.magicdata,
        stoneNum = gamedata.cache.props[stoneID] and gamedata.cache.props[stoneID].num or 0,
        rolelv = gamedata.cache.role.level or 0,
        g_goldNum =  gamedata.cache.role.g_gold or 0,
    }
end
--法宝解锁
function UIInstrumentUnlockCallback(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 1361, "InstrumentUnlock")
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.id) 
    gamedata.ext.magicUnlockid = uireq.id 
    return 1, 1361, idsData:SerializeToString()
end
function NetInstrumentUnlockCallback(fd)
	cclog("NET type:%d cmd:%s recv response from gameserver", 1361, "InstrumentUnlock")
    local info = slots_pb.SlotS()
    info:ParseFromString(fd.rbuf)
    gamedata:SlotInfoProcess(info)

	return { type = 1361, id = gamedata.ext.magicUnlockid }
end
--法宝锻造预览
--1工匠锻造，2大师锻造，3匠神锻造),锻造次数(1,5,10)
function UIInstrumentForgePreview( uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 1362, "InstrumentForgePreview")
    local otherRes = nil
    for k,v in pairs(uireq.num) do
        if k ~= tostring(stoneID) then
            otherRes = tonumber(v)
        end
    end

    --print(otherRes)
    local tuPoStatus = uireq.tuPoStatus


    if  tonumber(uireq.num[tostring(stoneID)]) * uireq.times > (gamedata.cache.props[stoneID] and gamedata.cache.props[stoneID].num or 0) then
        return 0,503,{type = 503, msg = "材料不足" }        
    elseif uireq.typeIndex == 2 and otherRes*uireq.times > gamedata.cache.role.coin then
        --return 0,503,{type = 503, msg = "银币不足" }
        return  0, 503, {type = 503, msgtype = "shortcoin"}
    elseif  uireq.typeIndex == 3 and tuPoStatus == 0 and otherRes*uireq.times > gamedata.cache.role.gold then--凡锻造
        return 0,503,{type = 503, msgtype = "shortgold" }
    elseif uireq.typeIndex == 3 and tuPoStatus>0 and otherRes*uireq.times > gamedata.cache.role.g_gold then--仙锻造    
         return 0,503,{type = 503, msgtype = "shortg_gold" }
    end
    gamedata.ext.magicPreviewData = {id = uireq.id,typeIndex = uireq.typeIndex,times = uireq.times,num = uireq.num, tuPoStatus = uireq.tuPoStatus}
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.id) 
    table.insert(idsData.ids, uireq.typeIndex)
    table.insert(idsData.ids, uireq.times)

    return 1, 1362, idsData:SerializeToString()    
end
function NetInstrumentForgePreview(fd)
	cclog("NET type:%d cmd:%s recv response from gameserver", 1362, "InstrumentForgePreview")
	local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    gamedata:MagicPreview(ids.ids)
    local otherRes = nil
    for k,v in pairs(gamedata.ext.magicPreviewData.num) do
        if k ~= tostring(stoneID) then
            otherRes = tonumber(v)
        end
    end
    if gamedata.ext.magicPreviewData.typeIndex == 2 then
        gamedata:updateRoleCoin(-otherRes*gamedata.ext.magicPreviewData.times,"金币刷新锻造",1)
    elseif gamedata.ext.magicPreviewData.typeIndex == 3 and gamedata.ext.magicPreviewData.tuPoStatus == 0 then
        gamedata:updateRoleGold(-otherRes*gamedata.ext.magicPreviewData.times,"元宝刷新锻造",1)
    elseif gamedata.ext.magicPreviewData.typeIndex == 3 and gamedata.ext.magicPreviewData.tuPoStatus > 0 then    
        gamedata:updateRoleG_gold(-otherRes*gamedata.ext.magicPreviewData.times,"仙元刷新锻造",1)
    end
    if gamedata.cache.props[stoneID] then
        gamedata.cache.props[stoneID].num = gamedata.cache.props[stoneID].num - gamedata.ext.magicPreviewData.num[tostring(stoneID)] * gamedata.ext.magicPreviewData.times
    end
	return  
    {   
        type = 1362, 
        data = {
            data = gamedata.cache.magicPreview,
            requestData = gamedata.ext.magicPreviewData,
            magicdata = gamedata.cache.magicdata,
            num =gamedata.cache.props[stoneID] and gamedata.cache.props[stoneID].num or 0,
            g_goldNum =  gamedata.cache.role.g_gold or 0,
            }
    }
end

--法宝锻造确认
function UIInstrumentForgeConfirm( uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 1363, "InstrumentForgeConfirm")
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.typeIndex) 
    gamedata.ext.magicPreview = uireq.typeIndex
    return 1, 1363, idsData:SerializeToString()      
end
function NetInstrumentForgeConfirm(fd)
	cclog("NET type:%d cmd:%s recv response from gameserver", 1363, "InstrumentForgeConfirm")
    local info = slots_pb.SlotS()
    info:ParseFromString(fd.rbuf)
    gamedata:SlotInfoProcess(info)

    if gamedata.ext.magicPreview == 1 then
        for k,v in pairs(gamedata.cache.magicdata.unlock) do
            if v.id == gamedata.ext.magicPreviewData.id and gamedata.ext.magicPreviewData.tuPoStatus == 0 then --凡锻造确认
                v.attr1 =  gamedata.cache.magicPreview[1]   
                v.attr2 =  gamedata.cache.magicPreview[2]  
                v.attr3 =  gamedata.cache.magicPreview[3]  
                v.attr4 =  gamedata.cache.magicPreview[4]              
                break
            elseif v.id == gamedata.ext.magicPreviewData.id and gamedata.ext.magicPreviewData.tuPoStatus > 0 then --仙锻造确认   
                v.attr5 =  gamedata.cache.magicPreview[1]   
                v.attr6 =  gamedata.cache.magicPreview[2]  
                v.attr7 =  gamedata.cache.magicPreview[3]  
                v.attr8 =  gamedata.cache.magicPreview[4]   
            end
        end
    end
	return 
    { 
        type = 1363, 
        data = gamedata.cache.magicPreview ,
        isChage = gamedata.ext.magicPreview ,
        magicdata = gamedata.cache.magicdata ,
        requestData = gamedata.ext.magicPreviewData
    }	
end


-- UIInstrumentForgeAutomaticCallback

local combmessages_pb = require("combmessages_pb")
--
function UIInstrumentForgeAutomaticCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1364, "UIInstrumentForgeAutomaticCallback")
    local InstrumentForgeData = ids_pb.Ids()

    table.insert(InstrumentForgeData.ids, uireq.iid or 0)
    table.insert(InstrumentForgeData.ids, uireq.method or 0)
    table.insert(InstrumentForgeData.ids, uireq.xlnum or 0)
    table.insert(InstrumentForgeData.ids, uireq.status1 or 0)
    table.insert(InstrumentForgeData.ids, uireq.status2 or 0)
    table.insert(InstrumentForgeData.ids, uireq.status3 or 0)
    table.insert(InstrumentForgeData.ids, uireq.status4 or 0)
    table.insert(InstrumentForgeData.ids, uireq.status5 or 0)

    if uireq.iid then
        gamedata.ext.InstrumentForgeAutoid = uireq.iid
    end
    local tuPoStatus = uireq.tuPoStatus or 0
    --
    local xprops = {}

    local xprop = gamedata.getIDandNUMs(tostring(gamedata.config.global_kv["artifact_consume_"..uireq.method].value))

    if tuPoStatus>0 then
         xprop = gamedata.getIDandNUMs(tostring(gamedata.config.artifact_xian_config[tostring(uireq.iid)][tostring(tuPoStatus)]["forging_consume"..uireq.method]))
    end

    for k,v in pairs(xprop) do
        if v.cid == 1000 then
            table.insert(xprops,{cid = 1000, num = v.num*uireq.xlnum})
            if gamedata.cache.role.coin < v.num*uireq.xlnum then
                --return 0, 503, {type = 503, msg = "银币不足" }
                return  0, 503, {type = 503, msgtype = "shortcoin"}
            end
        elseif v.cid == 1001 then
            table.insert(xprops,{cid = 1001, num = v.num*uireq.xlnum})
            if gamedata.cache.role.gold < v.num*uireq.xlnum then
                return 0, 503, {type = 503, msgtype = "shortgold" }
            end
        elseif v.cid == 1025 then
            table.insert(xprops,{cid = 1025, num = v.num*uireq.xlnum})
            if gamedata.cache.role.g_gold < v.num*uireq.xlnum then
                return 0, 503, {type = 503, msgtype = "shortg_gold" }
            end
        elseif v.cid == 20270 then
            table.insert(xprops,{cid = 20270, num = v.num*uireq.xlnum})
            if not gamedata.cache.props[20270] or gamedata.cache.props[20270].num < v.num*uireq.xlnum then
                return 0, 503, {type = 503, msg = gamedata.config.props["20270"].name.."不足" }
            end
        end
    end
    --
    gamedata.ext.InstrumentForgeXpropsAuto = xprops
    gamedata.ext.tuPoStatus = { tuPoStatus = tuPoStatus, method = uireq.method, fabaoid = uireq.iid, beforenum = uireq.xlnum}

    return 1, 1364, InstrumentForgeData:SerializeToString()
end

function NetInstrumentForgeAutomaticCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1364, "NetInstrumentForgeAutomaticCallback")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local status = {}
    local autotimes = 0
    for k,v in ipairs(datas.messages) do
        if v.id == 1 then
            local info = slots_pb.SlotS()
            info:ParseFromString(v.data)
            gamedata:SlotInfoProcess(info)
        elseif v.id == 2 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)

            local nums = #ids.ids/5

            for i = 1,nums do
                status[tostring(i)] = {}
                status[tostring(i)].method = ids.ids[(i-1)*5+1] or 0
                status[tostring(i)].num1 = ids.ids[(i-1)*5+2] or 0
                status[tostring(i)].num2 = ids.ids[(i-1)*5+3] or 0
                status[tostring(i)].num3 = ids.ids[(i-1)*5+4] or 0
                status[tostring(i)].num4 = ids.ids[(i-1)*5+5] or 0
            end
         elseif v.id == 3 then    
            local idsData = ids_pb.Ids()
            idsData:ParseFromString(v.data)
            autotimes = idsData.ids[1] or 0
            print("自动锻造 次数："..autotimes)
        end
    end
   

    if autotimes>0 and  autotimes < gamedata.ext.tuPoStatus.beforenum then --提前加满
        local xprops = {}
        local tuPoStatus = gamedata.ext.tuPoStatus.tuPoStatus
        local method =  gamedata.ext.tuPoStatus.method
        local fabaoid = gamedata.ext.tuPoStatus.fabaoid

        local xprop = gamedata.getIDandNUMs(tostring(gamedata.config.global_kv["artifact_consume_"..method].value))
        if tuPoStatus>0 then
            xprop = gamedata.getIDandNUMs(tostring(gamedata.config.artifact_xian_config[tostring(fabaoid)][tostring(tuPoStatus)]["forging_consume"..method]))
        end
        local times = autotimes
        for k,v in pairs(xprop) do
            if v.cid == 1000 then
                gamedata:updateRoleCoin(0-v.num*times)
            elseif v.cid == 1001 then
                gamedata:updateRoleGold(0-v.num*times,"法宝锻造",1)
            elseif v.cid == 1025 then
                gamedata:updateRoleG_gold(0-v.num*times,"法宝锻造",1)    
            elseif v.cid == 20270 then
                gamedata:updateprops({cid = 20270, num = 0-v.num*times})
            end
        end          
    elseif autotimes > 0 then
        for k,v in pairs(gamedata.ext.InstrumentForgeXpropsAuto) do
            if v.cid == 1000 then
                gamedata:updateRoleCoin(0-v.num)
            elseif v.cid == 1001 then
                gamedata:updateRoleGold(0-v.num,"法宝锻造",1)
            elseif v.cid == 1025 then
                gamedata:updateRoleG_gold(0-v.num,"法宝锻造",1)    
            elseif v.cid == 20270 then
                gamedata:updateprops({cid = 20270, num = 0-v.num})
            end
        end
    end    



   
    return { type = 1364, status = status, autotimes = autotimes, g_gold =  gamedata.cache.role.g_gold or 0 }
end


function UIBreakForgePreview(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1365, "UIBreakForgePreview")
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.id) 

    gamedata.ext.Instrumentbreakxprops = uireq.consume or ""

    -- print("1365 Instrumentbreakxprops",gamedata.ext.Instrumentbreakxprops)

    return 1, 1365, idsData:SerializeToString()    
end


function NetBreakForgePreview(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1365, "NetBreakForgePreview")

      local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)

    local status = {}
    for k,v in ipairs(Result.ids) do
        print(k,v)
        table.insert(status,v)
    end
    local consume = gamedata.ext.Instrumentbreakxprops  or ""
    local  xprop = gamedata.getIDandNUMs(consume)
    -- print("1365 NetBreakForgePreview",xprop)
    for k,v in pairs(xprop) do
        if v.cid == 1000 then
            gamedata:updateRoleCoin(0-v.num)
        elseif v.cid == 1001 then
            gamedata:updateRoleGold(0-v.num,"法宝锻造",1)
        elseif v.cid == 1025 then
            gamedata:updateRoleG_gold(0-v.num,"法宝锻造",1)    
        elseif v.cid == 20270 then
            gamedata:updateprops({cid = 20270, num = 0-v.num})
        end
    end

    return { type = 1365, data =  status}

end




