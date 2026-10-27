--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-10-16
-- Time: 下午1:57
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local slots_pb = require("slots_pb")
local somethings_pb = require("somethings_pb")

--装备升星
function UIEquipStarUpCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1123, "equipStarUp")
    print("i...am...UIEquipStarUpCallBack")
    printT(uireq)
    gamedata.ext.equipStarUp = uireq
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.iid)

    return 1, 1123, idsData:SerializeToString()
end

function NetEquipStarUpCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1123, "equipStarUp")
    print("i...am...NetEquipStarUpCallBack")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    gamedata:SomethingProcess(SomeThings)

    -- printT(gamedata.cache.equips)
    -- local info = slots_pb.SlotS()
    -- info:ParseFromString(fd.rbuf)

    -- gamedata:SlotInfoProcess(info)
    -- local spendcoin = 0
    -- for k,v in pairs(gamedata.ext.equipStarUp.props) do
    --     if v.cid == 1000 then
    --         spendcoin = v.num
    --     end 
    -- end
    -- if spendcoin ~= 0 then
    --     gamedata:updateRoleCoin(0-spendcoin,"装备升星",1)
    -- end 

    return {
        type = 1123,
        props = gamedata.ext.equipStarUp.props,
        equipdata = gamedata.cache.equips[tonumber(gamedata.ext.equipStarUp.iid)]
    }
end

--宝物升星
function UITreasureStarUpCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1127, "TreasureStarUp")

    gamedata.ext.treasureStarUp = uireq
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.iid)

    return 1, 1127, idsData:SerializeToString()
end

function NetTreasureStarUpCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1127, "TreasureStarUp")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    gamedata:SomethingProcess(SomeThings)

    for k,v in pairs(gamedata.ext.treasureStarUp.props) do
        if v.cid ~= 1000 then
            gamedata:updateprops({cid=v.cid, num=0-v.num})
        end
    end

    return {
        type = 1127,
        props = gamedata.ext.treasureStarUp.props,
        equipdata = gamedata.cache.equips[tonumber(gamedata.ext.treasureStarUp.iid)]
    }
end

