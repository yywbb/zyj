--
-- Author: yuxiaofeng
-- Date: 2022-02-16 13:44:07
--
local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")
local combmessages_pb = require("combmessages_pb")
local params_pb = require("params_pb")

function UIGodCompetitionSignUpQueryCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8250, "GodCompetitionSlotsQueryCallBack")
   
    return 1, 8250, nil;
end

function NetGodCompetitionSignUpQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8250, "GodCompetitionSlotsQueryCallBack")
    return { type = 8250}
end


--灵阵图查询
function UIGodCompetitionSlotSpiritQueryCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8255, "GodCompetitionSlotSpiritQueryCallBack")

    local idsData = ids_pb.Ids()
    table.insert(idsData.ids,uireq.team_id)

    gamedata.ext.godcompetitionteam_id  = uireq.team_id
    print(uireq.team_id)

    return 1, 8255, idsData:SerializeToString()
end

function NetGodCompetitionSlotSpiritQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8255, "GodCompetitionSlotSpiritQueryCallBack")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)
    local slotSpirit  = makeGodCompetitionSlotsDeploment(datas)
  
    return {type= 8255, slotSpirit = slotSpirit or {}}
end

--灵阵图 改变阵容图
function UIGodCompetitionChangeSpiritCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8256, "GodCompetitionChangeSpiritCallBack")

    local idsData = ids_pb.Ids()
    table.insert(idsData.ids,uireq.team_id)

    table.insert(idsData.ids,uireq.id)

    print(uireq.team_id,uireq.id)
    gamedata.ext.godcompetitionteam_id  = uireq.team_id
    return 1, 8256, idsData:SerializeToString()
end

function NetGodCompetitionChangeSpiritCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8256, "GodCompetitionChangeSpiritCallBack")
    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)
    local slotSpirit  = makeGodCompetitionSlotsDeploment(datas)

    return {type= 8256, slotSpirit = slotSpirit or {}}
end


--灵阵图 改变武将位子
function UIGodCompetitionChangeSpiritPositionCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8257, "GodCompetitionChangeSpiritPositionCallBack")

    local idsData = ids_pb.Ids()

    for i=1,7 do
        if uireq.ids[tostring(i)] and uireq.ids[tostring(i)] ~= i then
             table.insert(idsData.ids,uireq.ids[tostring(i)])
        else
            table.insert(idsData.ids,0)
        end
    end
    table.insert(idsData.ids,uireq.team_id)
    gamedata.ext.godcompetitionteam_id  = uireq.team_id

    print(uireq.team_id,"wewefsss")

    return 1, 8257, idsData:SerializeToString()
end

function NetGodCompetitionChangeSpiritPositionCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8257, "GodCompetitionChangeSpiritPositionCallBack")
    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)
    local slotSpirit  = makeGodCompetitionSlotsDeploment(datas)

    return {type= 8257, slotSpirit = slotSpirit or {}}
end


function makeGodCompetitionSlotsDeploment(datas)
    local slotSpirit = {}
    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            local data = ids.ids
            if data then
                slotSpirit.use = data[1] or 0
                slotSpirit.add = data[2] or 0
                slotSpirit.power = data[3] or 0
                gamedata:changeGodCompetitionPower(slotSpirit.power,tonumber(gamedata.ext.godcompetitionteam_id),tonumber(gamedata.ext.godcompetitionteam_id))
            end    
        elseif v.id == 1 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            local data = ids.ids
            if data then
                slotSpirit.level = {}
                for k,v in ipairs(data) do
                    table.insert(slotSpirit.level,v)
                end
            end
        elseif v.id == 2 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            local data = ids.ids
            if data then
                slotSpirit.activation = {}
                for k,v in ipairs(data) do
                    table.insert(slotSpirit.activation,v)
                end
            end
        end
    end
    return slotSpirit
end    


