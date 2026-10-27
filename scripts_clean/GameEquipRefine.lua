--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-10-11
-- Time: 上午10:48
-- To change this template use File | Settings | File Templates.
--

local equiprefine_pb = require("equiprefine_pb")
function UIEquipRefineCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1102, "equiprefine")
    local equiprefineData = equiprefine_pb.EquipRefine()

    equiprefineData.iid = uireq.iid
    for i=1,4 do
        table.insert(equiprefineData.props,uireq.props[tostring(i)].num)
    end

    gamedata.ext.EquipRefineProps =  uireq.props
    gamedata.ext.EquipRefineid = uireq.iid

    return 1, 1102, equiprefineData:SerializeToString()
end

local t_somethings_pb = require("somethings_pb")
function NetEquipRefineCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1102, "equiprefine")

    local equipsData = t_somethings_pb.SomeThings()
    equipsData:ParseFromString(fd.rbuf)

    gamedata:SomethingProcess(equipsData)



    for i=1,4 do
        gamedata:updateprops({cid = gamedata.ext.EquipRefineProps[tostring(i)].cid, num = 0-gamedata.ext.EquipRefineProps[tostring(i)].num})
    end

    return { type = 1102, equip = gamedata.cache.equips[gamedata.ext.EquipRefineid],}
end

local ids_pb = require("ids_pb")
function UIEquipRefineExCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1115, "equiprefineex")
    local equiprefineData = ids_pb.Ids()

    table.insert(equiprefineData.ids, uireq.iid)

    gamedata.ext.EquipRefineExid = uireq.iid

    return 1, 1115, equiprefineData:SerializeToString()
end

function NetEquipRefineExCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1115, "equiprefineex")

    local equipsData = t_somethings_pb.SomeThings()
    equipsData:ParseFromString(fd.rbuf)

    gamedata:SomethingProcess(equipsData)

    return { type = 1115, equip = gamedata.cache.equips[gamedata.ext.EquipRefineExid],}
end


------------------

function UIEquipBaptizePreviewCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1120, "EquipBaptizePreview")
    local equipBaptizeData = ids_pb.Ids()

    table.insert(equipBaptizeData.ids, uireq.iid)
    table.insert(equipBaptizeData.ids, uireq.method)
    table.insert(equipBaptizeData.ids, uireq.xlnum)

    gamedata.ext.EquipBaptizeid = uireq.iid

    --
    local xprops = {}
    local xprop = gamedata.getIDandNUMs(tostring(gamedata.config.global_kv["baptize_consume_"..uireq.method].value))
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
        elseif v.cid == 20222 then
            table.insert(xprops,{cid = 20222, num = v.num*uireq.xlnum})
            if not gamedata.cache.props[20222] or gamedata.cache.props[20222].num < v.num*uireq.xlnum then
                return 0, 503, {type = 503, msg = gamedata.config.props["20222"].name.."不足" }
            end
        end
    end
    --
    gamedata.ext.EquipBaptizeXprops = xprops

    return 1, 1120, equipBaptizeData:SerializeToString()
end

function NetEquipBaptizePreviewCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1120, "EquipBaptizePreview")

    local equipsData = ids_pb.Ids()
    equipsData:ParseFromString(fd.rbuf)

    local equip = gamedata:equipData(equipsData)

    for k,v in pairs(gamedata.ext.EquipBaptizeXprops) do
        if v.cid == 1000 then
            gamedata:updateRoleCoin(0-v.num)
        elseif v.cid == 1001 then
            gamedata:updateRoleGold(0-v.num,"装备洗炼",1)
        elseif v.cid == 20222 then
            gamedata:updateprops({cid = 20222, num = 0-v.num})
        end
    end

    return { type = 1120, equip = equip,}
end

--
function UIEquipBaptizeConfirmCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1121, "EquipBaptizeConfirm")
    local equipBaptizeData = ids_pb.Ids()

    table.insert(equipBaptizeData.ids, uireq.method)

    if uireq.iid then
        gamedata.ext.EquipBaptizeid = uireq.iid
    end

    return 1, 1121, equipBaptizeData:SerializeToString()
end

function NetEquipBaptizeConfirmCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1121, "EquipBaptizeConfirm")

    local equipsData = t_somethings_pb.SomeThings()
    equipsData:ParseFromString(fd.rbuf)

    gamedata:SomethingProcess(equipsData)

    return { type = 1121, equip = gamedata.cache.equips[gamedata.ext.EquipBaptizeid],}
end


local combmessages_pb = require("combmessages_pb")
--
function UIEquipBaptizeAutomaticCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1124, "EquipBaptizeAutomatic")
    local equipBaptizeData = ids_pb.Ids()

    table.insert(equipBaptizeData.ids, uireq.iid or 0)
    table.insert(equipBaptizeData.ids, uireq.method or 0)
    table.insert(equipBaptizeData.ids, uireq.xlnum or 0)
    table.insert(equipBaptizeData.ids, uireq.status1 or 0)
    table.insert(equipBaptizeData.ids, uireq.status2 or 0)
    table.insert(equipBaptizeData.ids, uireq.status3 or 0)
    table.insert(equipBaptizeData.ids, uireq.status4 or 0)
    table.insert(equipBaptizeData.ids, uireq.status5 or 0)
    if uireq.iid then
        gamedata.ext.EquipBaptizeAutoid = uireq.iid
    end

    --
    local xprops = {}
    local xprop = gamedata.getIDandNUMs(tostring(gamedata.config.global_kv["baptize_consume_"..uireq.method].value))
    for k,v in pairs(xprop) do
        if v.cid == 1000 then
            table.insert(xprops,{cid = 1000, num = v.num})
            if gamedata.cache.role.coin < v.num*uireq.xlnum then
                --return 0, 503, {type = 503, msg = "银币不足" }
                return  0, 503, {type = 503, msgtype = "shortcoin"}
            end
        elseif v.cid == 1001 then
            table.insert(xprops,{cid = 1001, num = v.num})
            if gamedata.cache.role.gold < v.num*uireq.xlnum then
                return 0, 503, {type = 503, msgtype = "shortgold" }
            end
        elseif v.cid == 20222 then
            table.insert(xprops,{cid = 20222, num = v.num})
            if not gamedata.cache.props[20222] or gamedata.cache.props[20222].num < v.num*uireq.xlnum then
                return 0, 503, {type = 503, msg = gamedata.config.props["20222"].name.."不足" }
            end
        end
    end
    --
    gamedata.ext.EquipBaptizeXpropsAuto = xprops

    return 1, 1124, equipBaptizeData:SerializeToString()
end

function NetEquipBaptizeAutomaticCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1124, "EquipBaptizeAutomatic")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local nums = 0
    local status = {}
    for k,v in ipairs(datas.messages) do
        if v.id == 1 then
            local equipsData = t_somethings_pb.SomeThings()
            equipsData:ParseFromString(v.data)
            gamedata:SomethingProcess(equipsData)
        elseif v.id == 2 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)

            nums = #ids.ids/5

            for i = 1,nums do
                status[tostring(i)] = {}
                status[tostring(i)].method = ids.ids[(i-1)*5+1] or 0
                status[tostring(i)].num1 = ids.ids[(i-1)*5+2] or 0
                status[tostring(i)].num2 = ids.ids[(i-1)*5+3] or 0
                status[tostring(i)].num3 = ids.ids[(i-1)*5+4] or 0
                status[tostring(i)].num4 = ids.ids[(i-1)*5+5] or 0
            end
        end
    end

    for k,v in pairs(gamedata.ext.EquipBaptizeXpropsAuto) do
        if v.cid == 1000 then
            gamedata:updateRoleCoin(0-v.num*nums*10)
        elseif v.cid == 1001 then
            gamedata:updateRoleGold(0-v.num*nums*10,"装备洗炼",1)
        elseif v.cid == 20222 then
            gamedata:updateprops({cid = 20222, num = 0-v.num*nums*10})
        end
    end

    return { type = 1124, equip = gamedata.cache.equips[gamedata.ext.EquipBaptizeAutoid],status = status,}
end
