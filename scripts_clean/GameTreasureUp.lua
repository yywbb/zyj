--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-10-11
-- Time: 上午11:08
-- To change this template use File | Settings | File Templates.
--

local TreasureUp_pb = require("equiprefine_pb")
function UITreasureUpCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1105, "TreasureUp")
    local TreasureUpData = TreasureUp_pb.EquipRefine()

    TreasureUpData.iid = uireq.iid
    for i=1,4 do
        table.insert(TreasureUpData.props,uireq.props[tostring(i)].num)
    end

    gamedata.ext.TreasureUpProps =  uireq.props
    gamedata.ext.TreasureUpiid = uireq.iid

    return 1, 1105, TreasureUpData:SerializeToString()
end

local t_somethings_pb = require("somethings_pb")
function NetTreasureUpCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1105, "TreasureUp")

    local TreasureUpData = t_somethings_pb.SomeThings()
    TreasureUpData:ParseFromString(fd.rbuf)

    gamedata:SomethingProcess(TreasureUpData)

    for i=1,4 do
        gamedata:updateprops({cid = gamedata.ext.TreasureUpProps[tostring(i)].cid, num = 0-gamedata.ext.TreasureUpProps[tostring(i)].num})
    end

    return { type = 1105, equip = gamedata.cache.equips[gamedata.ext.TreasureUpiid],}
end

local ids_pb = require("ids_pb")
function UITreasureRefineExCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1116, "Treasurerefineex")
    local TreasurerefineData = ids_pb.Ids()

    table.insert(TreasurerefineData.ids, uireq.iid)

    gamedata.ext.TreasureRefineExid = uireq.iid

    return 1, 1116, TreasurerefineData:SerializeToString()
end

function NetTreasureRefineExCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1116, "Treasurerefineex")

    local equipsData = t_somethings_pb.SomeThings()
    equipsData:ParseFromString(fd.rbuf)

    gamedata:SomethingProcess(equipsData)

    return { type = 1116, equip = gamedata.cache.equips[gamedata.ext.TreasureRefineExid],}
end

----------
----------

local TreasureRefine_pb = require("treasurerefine_pb")
function UITreasureStrengthenCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1118, "TreasureStrengthen")
    local TreasurerefineData = TreasureRefine_pb.TreasureRefine()

    TreasurerefineData.iid = uireq.iid

    for k,v in pairs(uireq.ids) do
        table.insert(TreasurerefineData.ids,v)
    end

    gamedata.ext.TreasureStrengthen_iid =  uireq.iid
    gamedata.ext.TreasureStrengthen_ids =  uireq.ids or {}
    gamedata.ext.TreasureStrengthen_xcoin =  uireq.xcoin or 0

    return 1, 1118, TreasurerefineData:SerializeToString()
end

function NetTreasureStrengthenCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1118, "TreasureStrengthen")

    local equipsData = t_somethings_pb.SomeThings()
    equipsData:ParseFromString(fd.rbuf)

    gamedata:SomethingProcess(equipsData)

    for k,v in pairs(gamedata.ext.TreasureStrengthen_ids) do
        gamedata.cache.equips[v] = nil
    end
    gamedata:updateRoleCoin(0-gamedata.ext.TreasureStrengthen_xcoin)

    return { type = 1118, equip = gamedata.cache.equips[gamedata.ext.TreasureStrengthen_iid],}
end

function UITreasureStrengthenByPropCallBack( uireq )
    cclog("NET type:%d cmd:%s recv request from UI", 1210, "TreasureStrengthenByProp")
    local TreasureStrengthenData = ids_pb.Ids()

    printT(uireq)

    table.insert(TreasureStrengthenData.ids,uireq.iid)

    for k,v in pairs(uireq.cids) do
        if v.num>0 then
            table.insert(TreasureStrengthenData.ids,v.cid)
            table.insert(TreasureStrengthenData.ids,v.num)
        end
    end

    gamedata.ext.TreasureStrengthenbyprop_iid =  uireq.iid
    gamedata.ext.TreasureStrengthenbyprop_ids =  uireq.cids or {}
    gamedata.ext.TreasureStrengthenbyprop_xcoin =  uireq.xcoin or 0

    return 1, 1210, TreasureStrengthenData:SerializeToString()
end

function NetTreasureStrengthenByPropCallBack( fd )
    cclog("NET type:%d cmd:%s recv response from gameserver", 1210, "TreasureStrengthenByProp")

    local equipsData = t_somethings_pb.SomeThings()
    equipsData:ParseFromString(fd.rbuf)

    gamedata:SomethingProcess(equipsData)

    for k,v in pairs(gamedata.ext.TreasureStrengthenbyprop_ids) do
        gamedata:updateprops({cid=v.cid,num=0-v.num})
    end
    gamedata:updateRoleCoin(0-gamedata.ext.TreasureStrengthenbyprop_xcoin)

    return { type = 1210, equip = gamedata.cache.equips[gamedata.ext.TreasureStrengthenbyprop_iid],}
end


--

function UITreasureRefine2CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1119, "TreasureRefine2")
    local TreasurerefineData = ids_pb.Ids()

    table.insert(TreasurerefineData.ids, uireq.iid)

    for k,v in pairs(uireq.ids) do
        table.insert(TreasurerefineData.ids, v)
    end

    gamedata.ext.TreasureRefine_iid =  uireq.iid
    gamedata.ext.TreasureRefine_ids =  uireq.ids or {}
    gamedata.ext.TreasureRefine_xprops =  uireq.xprops or {}

    return 1, 1119, TreasurerefineData:SerializeToString()
end

function NetTreasureRefine2CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1119, "TreasureRefine2")

    local equipsData = t_somethings_pb.SomeThings()
    equipsData:ParseFromString(fd.rbuf)

    gamedata:SomethingProcess(equipsData)

    for k,v in pairs(gamedata.ext.TreasureRefine_ids) do
        gamedata.cache.equips[v] = nil
    end

    for k,v in pairs(gamedata.ext.TreasureRefine_xprops) do
        if v.cid == 1000 then
            gamedata:updateRoleCoin(0-v.num)
        else
            gamedata:updateprops({cid = v.cid, num = 0-v.num})
        end
    end

    return { type = 1119, equip = gamedata.cache.equips[gamedata.ext.TreasureRefine_iid],}
end
