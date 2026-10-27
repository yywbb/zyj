--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/12/21
-- Time: 下午2:06
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")
local generals_pb = require("generals_pb")
local combmessages_pb = require("combmessages_pb")
local params_pb = require("params_pb")
local players_pb = require("players_pb")


-- 翅膀查询
function UIWingQuaryCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3740, "Wing")
    print("UIWingQuaryCallback===")

    -- local basicdata = {1,5,250,2,60}
    -- gamedata:WingData(basicdata)
    
    -- return 0, 3740, { type = 3740, wing = gamedata.cache.wing}

    return 1, 3740, nil
end

function NetWingQuaryCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3740, "Wing")
    print("NetWingQuaryCallback===")
    local  ids = ids_pb.Ids();
    ids:ParseFromString(fd.rbuf)
    gamedata:WingData(ids.ids)

    return { type = 3740, wing = gamedata.cache.wing,protagonist = gamedata.cache.protagonist}
end

-- 翅膀升星
function UIWingSatrUpCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3741, "Wing")
    print("UIWingSatrUpCallback===")

    -- local basicdata = {1,6,100,2,60,100,50,120,150}
    -- gamedata:WingData(basicdata)
    
    -- return 0, 3741, { type = 3741, wing = gamedata.cache.wing}
    gamedata.ext.wingstarupid = uireq.id

    return 1, 3741, nil
end

function NetWingSatrUpCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3741, "Wing")
    print("NetWingSatrUpCallback===")
    local  ids = ids_pb.Ids();
    ids:ParseFromString(fd.rbuf)
    gamedata:WingData(ids.ids)

         
    if gamedata.cache.wing.stagenum then
        gamedata.cache.protagonist.w_l = gamedata.cache.wing.stagenum
    end 
    if gamedata.cache.wing.colortype then
        gamedata.cache.protagonist.w_c = gamedata.cache.wing.colortype
    end
    
    local spendnum = table.getTableLength(gamedata.cache.wing.expnumtable)
    if spendnum ~= 0 then
        gamedata:updateStaff({cid = tonumber(gamedata.ext.wingstarupid),num = -spendnum})
    end 
    

    return { type = 3741, wing = gamedata.cache.wing,protagonist = gamedata.cache.protagonist}
end

-- 翅膀进阶 and 激活（共用一个借口
function UIWingStageUpCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3742, "WingStageUp")
    printT(uireq,"UIWingStageUpCallback==")
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.marknum)

    gamedata.ext.wingstagespend = uireq
    print("numspend==",gamedata.config.global_kv.wing_activation.value,gamedata.cache.role.gold)
    if uireq.first and tonumber(gamedata.config.global_kv.wing_activation.value) > tonumber(gamedata.cache.role.gold) then
        return 0,503,{type = 503, msgtype = "shortgold" }
    end 

    return 1, 3742, idsData:SerializeToString()

end

function NetWingStageUpCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3742, "WingStageUp")
    print("NetWingStageUpCallback")
    
    local UsePorp = combmessages_pb.CombMessages()
    UsePorp:ParseFromString(fd.rbuf)
    local getData = {}
    for k,v in ipairs(UsePorp.messages) do
        print("messages===",v.id)
        if v.id == 0 then
            print("messages==in==",v.id)
            local ids = ids_pb.Ids();
            ids:ParseFromString(v.data)
            gamedata:WingStageData(ids.ids)
        end


        if v.id == 1 then
            local info = generals_pb.Generals()
            info:ParseFromString(v.data)
            gamedata:Generals(info.generals)
        end

        if v.id == 2 then
            getData = somethings_pb.SomeThings()
            getData:ParseFromString(v.data)
            print("messages==ni==",v.id)
        end
    end

    printT(gamedata.ext.wingstagespend,"wingstagespend==")

    -- if gamedata.ext.wingstagespend.marknum == 0 then
    --     for i,v in pairs(gamedata.ext.wingstagespend.spend) do
    --         if tonumber(i) == 1 then
    --             gamedata:updateStaff({cid = v.cid,num = -v.num})
    --         end 
    --     end
    -- else
    --     for i,v in pairs(gamedata.ext.wingstagespend.spend) do
    --         gamedata:updateStaff({cid = v.cid,num = -v.num})
    --     end
    -- end

    for i,v in pairs(gamedata.ext.wingstagespend.spend) do
        gamedata:updateStaff({cid = v.cid,num = -v.num})
    end
    print("text001")

    if gamedata.ext.wingstagespend.first then
        local spendnum = tonumber(gamedata.config.global_kv.wing_activation.value)
        gamedata:updateRoleGold(0-spendnum,"主角翅膀激活"..spendnum,1)
    end



    if gamedata.cache.wing.stagenum then
        gamedata.cache.protagonist.w_l = gamedata.cache.wing.stagenum
    end 
    if gamedata.cache.wing.colortype then
        gamedata.cache.protagonist.w_c = gamedata.cache.wing.colortype
    end


    print("text002")
    printT(gamedata.cache.wing,"wing===")
    return { 
        type = 3742, 
        wing = gamedata.cache.wing,
        reward =  gamedata:SomethingProcess(getData),
        first = gamedata.ext.wingstagespend.first,
        protagonist = gamedata.cache.protagonist,
    }
end


--
function UIWingDyeingCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3743, "Wing")

    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.id)

    if uireq.cost then
        gamedata.ext.wingcolorcost = uireq.cost
        if gamedata.getStaffNum(uireq.cost.cid).num < uireq.cost.num then
            return 0,503,{type = 503,msgtype = "shortprop",id= uireq.cost.cid,num= uireq.cost.num}
        end
    else
        gamedata.ext.wingcolorcost = nil
    end

    return 1, 3743, idsData:SerializeToString()
end

function NetWingDyeingCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3743, "Wing")

    local  ids = ids_pb.Ids();
    ids:ParseFromString(fd.rbuf)
    gamedata:WingData(ids.ids)

    if gamedata.ext.wingcolorcost and next(gamedata.ext.wingcolorcost) then
        gamedata:updateStaff({cid = gamedata.ext.wingcolorcost.cid,num = 0-gamedata.ext.wingcolorcost.num})
    end

      
    if gamedata.cache.wing.stagenum then
        gamedata.cache.protagonist.w_l = gamedata.cache.wing.stagenum
    end 
    if gamedata.cache.wing.colortype then
        gamedata.cache.protagonist.w_c = gamedata.cache.wing.colortype
    end

    return { type = 3743, wing = gamedata.cache.wing, protagonist = gamedata.cache.protagonist}
end
--
function UIWingColorQueryCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3744, "Wing")

    return 1, 3744, nil
end

function NetWingColorQueryCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3744, "Wing")

    local  ids = ids_pb.Ids();
    ids:ParseFromString(fd.rbuf)

    gamedata.cache.wingcolor = {}
    for i = 1,10 do
        gamedata.cache.wingcolor[tostring(i)] = ids.ids[i] or 0
    end

    return { type = 3744, wing = gamedata.cache.wing, protagonist = gamedata.cache.protagonist, wingcolor = gamedata.cache.wingcolor}
end

