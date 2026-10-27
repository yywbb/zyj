--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/11/12
-- Time: 下午2:59
-- To change this template use File | Settings | File Templates.
--


local ids_pb = require("ids_pb")
local result_pb = require("result_pb")
local gangstatus_pb = require("gangstatus_pb")
local gangbroadcasts_pb = require("gangbroadcasts_pb")
local stringcontent_pb = require("stringcontent_pb")
local gangs_pb = require("gangs_pb")
local players_pb = require("players_pb")
local gangmembers_pb = require("gangmembers_pb")
local somethings_pb = require("somethings_pb")

local function sortmembersByPost(a,b)

    if a and b then
        if a.post == 1 then
            return true
        elseif b.post == 1 then
            return false
        elseif a.post == 2 and b.post == 2 then
            return a.level > b.level
        elseif a.post == 2 and b.post == 0 then
            return true
        elseif a.post == 0 and b.post == 2 then
            return false
        elseif a.post == 0 and b.post == 0 then
            return a.level > b.level
        end
    else
        return true
    end

end

local function makemembers()
    local members = {}

    for k,v in pairs(gamedata.cache.gangmembers) do
        table.insert(members,v)
    end
    table.sort(members,sortmembersByPost)
    return members
end


local function addgangexp(num)
    gamedata.cache.gangstatus.exp = gamedata.cache.gangstatus.exp + num

    if gamedata.cache.gangstatus.exp >= gamedata.config.gang_exp[tostring(gamedata.cache.gangstatus.level)].exp then
        if gamedata.config.gang_exp[tostring(gamedata.cache.gangstatus.level+1)] then
            gamedata.cache.gangstatus.exp = gamedata.cache.gangstatus.exp - gamedata.config.gang_exp[tostring(gamedata.cache.gangstatus.level)].exp
            gamedata.cache.gangstatus.level = gamedata.cache.gangstatus.level +1
        end
    end
end

local function addgangmemberexp(num)
    gamedata.cache.gangstatus.memberexp = gamedata.cache.gangstatus.memberexp + num
    gamedata.cache.gangstatus.gangmoney = gamedata.cache.gangstatus.gangmoney + num

    if gamedata.cache.gangstatus.memberexp >= gamedata.config.gang_position[tostring(gamedata.cache.gangstatus.memberlevel)].contribution then
        if gamedata.config.gang_position[tostring(gamedata.cache.gangstatus.memberlevel+1)] then
            gamedata.cache.gangstatus.memberexp = gamedata.cache.gangstatus.memberexp - gamedata.config.gang_position[tostring(gamedata.cache.gangstatus.memberlevel)].contribution
            gamedata.cache.gangstatus.memberlevel = gamedata.cache.gangstatus.memberlevel +1
        end
    end
end

local function makeReqPlayers(data)
    local palyers ={}
    for k,v in ipairs(data) do
        table.insert(palyers,gamedata:playerdata(v))
    end

    gamedata.sortData(palyers, "param","level","rid")

    return palyers
end

function UIGangStatusCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2200, "GangStatus")

    gamedata.ext.gangstatusparam = tonumber(uireq.param)
    return 1, 2200, nil
end

function NetGangStatusCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2200, "GangStatus")

    if not fd.rbuf or fd.rbuf == "" then
    else
        local GangStatusData = gangstatus_pb.GangStatus()
        GangStatusData:ParseFromString(fd.rbuf)

        gamedata:GangStatus(GangStatusData)
    end

    return { type = 2200, gangstatus = gamedata.cache.gangstatus, param = gamedata.ext.gangstatusparam}
end

-------------------------------------------------------------------------------------------------

function UIGangCreateCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2201, "GangCreate")

    local GangCreateData = stringcontent_pb.StringContent()
    GangCreateData.content = uireq.name

    return 1, 2201, GangCreateData:SerializeToString()
end

function NetGangCreateCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2201, "GangCreate")

    local GangStatusData = gangstatus_pb.GangStatus()
    GangStatusData:ParseFromString(fd.rbuf)

    gamedata:GangStatus(GangStatusData)

    gamedata:updateRoleGold(-300,"创建公会",1)

    return { type = 2201, gangstatus = gamedata.cache.gangstatus,}
end

-------------------------------------------------------------------------------------------------

function UIGangsCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2202, "Gangs")

    local GangsData = ids_pb.Ids()

    if uireq.method == 0 then
        table.insert(GangsData.ids, 0)
        table.insert(GangsData.ids, #gamedata.cache.gangs_level)
    elseif uireq.method == 1 then
        table.insert(GangsData.ids, 1)
        table.insert(GangsData.ids, #gamedata.cache.gangs_point)
    elseif uireq.method == 2 then
        if next(gamedata.cache.gangs_level) then
            return 0,2202,{type = 2202,gangs = gamedata.cache.gangs_level,method = 2 }
        else
            table.insert(GangsData.ids, 0)
            table.insert(GangsData.ids, 0)
        end
    elseif uireq.method == 3 then
        if next(gamedata.cache.gangs_point) then
            return 0,2202,{type = 2202,gangs = gamedata.cache.gangs_point,method = 3 }
        else
            table.insert(GangsData.ids, 1)
            table.insert(GangsData.ids, 0)
        end
    end

    gamedata.ext.Gangsquerymethod = uireq.method

    return 1, 2202, GangsData:SerializeToString()
end

function NetGangsCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2202, "Gangs")

    local GangsData = gangs_pb.Gangs()
    GangsData:ParseFromString(fd.rbuf)


    if gamedata.ext.Gangsquerymethod == 0 or gamedata.ext.Gangsquerymethod == 2 then
        gamedata:GangsLevel(GangsData)
        return { type = 2202, gangs = gamedata.cache.gangs_level,method = gamedata.ext.Gangsquerymethod}
    elseif gamedata.ext.Gangsquerymethod == 1 or gamedata.ext.Gangsquerymethod == 3 then
        gamedata:GangsPoint(GangsData)
        return { type = 2202, gangs = gamedata.cache.gangs_point,method = gamedata.ext.Gangsquerymethod}
    end

end

-------------------------------------------------------------------------------------------------

function UIGangReqCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2203, "GangReq")

    local GangsReqData = ids_pb.Ids()
    table.insert(GangsReqData.ids, uireq.id)

    gamedata.ext.reqgangid = uireq.id

    return 1, 2203, GangsReqData:SerializeToString()
end

function NetGangReqCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2203, "GangReq")

    local GangsReqData = result_pb.Result()
    GangsReqData:ParseFromString(fd.rbuf)

    for k,v in pairs(gamedata.cache.gangs_level) do
        if v.id == gamedata.ext.reqgangid then
            gamedata.cache.gangs_level[k].param = 1
        end
    end

    return { type = 2203, id = gamedata.ext.reqgangid}
end

-------------------------------------------------------------------------------------------------

function UIGangReqQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2204, "GangReqQuery")

    return 1, 2204, nil
end

function NetGangReqQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2204, "GangReqQuery")

    local GangReqQueryData = players_pb.Players()
    GangReqQueryData:ParseFromString(fd.rbuf)

    return { type = 2204, players = makePlayers(GangReqQueryData.players),}
end

-------------------------------------------------------------------------------------------------

function UIGangReqRepCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2205, "GangReqRep")

    local GangReqRepData = ids_pb.Ids()
    table.insert(GangReqRepData.ids, uireq.id)
    table.insert(GangReqRepData.ids, uireq.opt)

    gamedata.ext.GangReqRepid = uireq.id
    gamedata.ext.GangReqRepopt = uireq.opt

    return 1, 2205, GangReqRepData:SerializeToString()
end

function NetGangReqRepCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2205, "GangReqRep")

    local GangReqRepData = result_pb.Result()
    GangReqRepData:ParseFromString(fd.rbuf)

    return { type = 2205, result = GangReqRepData.result, id = gamedata.ext.GangReqRepid,opt = gamedata.ext.GangReqRepopt }
end

-------------------------------------------------------------------------------------------------

function UIGangMemberCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2206, "GangMember")

    local GangMemberRepData = ids_pb.Ids()

    gamedata.ext.gangmemberid = nil
    gamedata.ext.fortselectpos = nil

    if uireq.pos then
        gamedata.ext.fortselectpos = uireq.pos
    end


    if uireq.id then
        table.insert(GangMemberRepData.ids, uireq.id)
        gamedata.ext.gangmemberid = uireq.id
    end


    return 1, 2206, GangMemberRepData:SerializeToString()
end

function NetGangMemberCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2206, "GangMember")

    local gangmembersData = gangmembers_pb.GangMembers()
    gangmembersData:ParseFromString(fd.rbuf)

    local members = {}
    if gamedata.ext.gangmemberid then
        for k,v in ipairs(gangmembersData.members) do
            table.insert(members,gamedata:gangmemberData(v))
        end
    else
        members = gamedata:GangMembers(gangmembersData)
    end

    table.sort(members,sortmembersByPost)

    return { type = 2206, gangmembers = members,otherid = gamedata.ext.gangmemberid,pos = gamedata.ext.fortselectpos }
end

-------------------------------------------------------------------------------------------------

function UIGangKickMemberCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2207, "GangKickMember")

    local GangKickMemberRepData = ids_pb.Ids()

    if uireq.id then
        table.insert(GangKickMemberRepData.ids, uireq.id)
    end
    gamedata.ext.GangKickMembeid = uireq.id

    return 1, 2207, GangKickMemberRepData:SerializeToString()
end

function NetGangKickMemberCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2207, "GangKickMember")

    local GangKickMemberRepData = result_pb.Result()
    GangKickMemberRepData:ParseFromString(fd.rbuf)
    if GangKickMemberRepData.result then
        gamedata.cache.gangmembers[gamedata.ext.GangKickMembeid] = nil
    end

    return { type = 2207, gangmembers = makemembers(),result = GangKickMemberRepData.result}
end

-------------------------------------------------------------------------------------------------

function UIGangQuitCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2208, "GangQuit")

    return 1, 2208, nil
end

function NetGangQuitCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2208, "GangQuit")

    local GangQuitData = result_pb.Result()
    GangQuitData:ParseFromString(fd.rbuf)

    gamedata.cache.gangmembers = {}
    gamedata.cache.gangstatus = {}

    return { type = 2208, result = GangQuitData.result,gangstatus = gamedata.cache.gangstatus,}
end

-------------------------------------------------------------------------------------------------

function UIGangPassPowerCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2209, "GangPassPower")

    local GangPassPowerData = ids_pb.Ids()
    table.insert(GangPassPowerData.ids, uireq.id)

    gamedata.ext.GangPassPowerid = uireq.id

    return 1, 2209, GangPassPowerData:SerializeToString()
end

function NetGangPassPowerCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2209, "GangPassPower")

    local GangPassPowerData = result_pb.Result()
    GangPassPowerData:ParseFromString(fd.rbuf)

    if GangPassPowerData.result then
        gamedata.cache.gangmembers[gamedata.cache.role.id].post = 0
        gamedata.cache.gangstatus.post =  0
        gamedata.cache.gangmembers[gamedata.ext.GangPassPowerid].post = 1
    end


    return { type = 2209, result = GangPassPowerData.result,gangstatus = gamedata.cache.gangstatus,gangmembers = makemembers()}
end

-------------------------------------------------------------------------------------------------

function UIGangSetAssistantCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2210, "GangSetAssistant")

    local assitantnum = 0
    for k,v in pairs(gamedata.cache.gangmembers) do
        if v.post == 2 then assitantnum = assitantnum +1 end
    end

    if assitantnum<3 then
        local GangSetAssistantData = ids_pb.Ids()
        table.insert(GangSetAssistantData.ids, uireq.id)

        gamedata.ext.GangSetAssistantid = uireq.id

        return 1, 2210, GangSetAssistantData:SerializeToString()
    else
        return 0, 503, {type = 503, msg = "助理人数已达上限"}
    end
end

function NetGangSetAssistantCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2210, "GangSetAssistant")

    local GangSetAssistantData = result_pb.Result()
    GangSetAssistantData:ParseFromString(fd.rbuf)

    if GangSetAssistantData.result then
        gamedata.cache.gangmembers[gamedata.ext.GangSetAssistantid].post = 2
    end

    return { type = 2210, result = GangSetAssistantData.result,gangmembers = makemembers()}
end

function UIGangRemoveAssistantCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2219, "GangRemoveAssistant")

    local GangRemoveAssistantData = ids_pb.Ids()
    table.insert(GangRemoveAssistantData.ids, uireq.id)

    gamedata.ext.GangRemoveAssistantid = uireq.id

    return 1, 2219, GangRemoveAssistantData:SerializeToString()
end

function NetGangRemoveAssistantCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2219, "GangRemoveAssistant")

    local GangSetAssistantData = result_pb.Result()
    GangSetAssistantData:ParseFromString(fd.rbuf)

    if GangSetAssistantData.result then
        gamedata.cache.gangmembers[gamedata.ext.GangRemoveAssistantid].post = 0
    end

    return { type = 2219, result = GangSetAssistantData.result,gangmembers = makemembers()}
end

-------------------------------------------------------------------------------------------------

function UIGangSetAnnouncementCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2211, "GangSetAnnouncement")

    local GangSetAnnouncementData = stringcontent_pb.StringContent()
    GangSetAnnouncementData.content = uireq.announcement

    gamedata.ext.GangSetAnnouncementData = uireq.announcement

    return 1, 2211, GangSetAnnouncementData:SerializeToString()
end

function NetGangSetAnnouncementCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2211, "GangSetAnnouncement")

    local GangSetAnnouncementData = result_pb.Result()
    GangSetAnnouncementData:ParseFromString(fd.rbuf)

    if GangSetAnnouncementData.result then
        gamedata.cache.gangstatus.announcement= gamedata.ext.GangSetAnnouncementData
    end

    return { type = 2211, result = GangSetAnnouncementData.result,gangstatus = gamedata.cache.gangstatus}
end

-------------------------------------------------------------------------------------------------

function UIGangsearchCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2220, "Gangsearch")

    local GangsearchData = stringcontent_pb.StringContent()
    GangsearchData.content = uireq.name

    return 1, 2220, GangsearchData:SerializeToString()
end

function NetGangsearchCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2220, "Gangsearch")

    local GangsearchData = gangs_pb.Gangs()
    GangsearchData:ParseFromString(fd.rbuf)

    local gang = {}
    for k,v in ipairs(GangsearchData.gangs) do
        table.insert(gang,gamedata:gangData(v))
    end


    return { type = 2220, gang = gang,}
end

-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------

local combmessages_pb = require("combmessages_pb")
local params_pb = require("params_pb")

function UIUserGang2CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2230, "UserGang2")
    gamedata.ext.gang2statusparam = uireq.param
    if not uireq.param or gamedata.ext.gang2statusparam == "main" or gamedata.ext.gang2statusparam == "chat" or gamedata.ext.gang2statusparam == "activity" then
        return 1, 2230, nil
    else
        if next(gamedata.cache.gang2status) then
            return 0, 2230, {type = 2230, gang2status = gamedata.cache.gang2status, param = gamedata.ext.gang2statusparam }
        else
            return 1, 2230, nil
        end
    end
end

function NetUserGang2CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2230, "UserGang2")

    if not fd.rbuf or fd.rbuf == "" then
        gamedata.cache.gang2status = {}
    else
        local Gang2StatusData = combmessages_pb.CombMessages()
        Gang2StatusData:ParseFromString(fd.rbuf)
        for k,v in ipairs(Gang2StatusData.messages) do
            if v.id == 1 then
                local params = params_pb.ParamS()
                params:ParseFromString(v.data)
                gamedata:Gang2Status(params.params)
            end
            if v.id == 2 then
                local ids = ids_pb.Ids()
                ids:ParseFromString(v.data)
                gamedata:Gang2Status2(ids.ids)
            end
            if v.id == 0 then
                gamedata.cache.gang2status = {}
                gamedata.cache.gang2CDstatus = {}
                local params = params_pb.ParamS()
                params:ParseFromString(v.data)
                gamedata.cache.gang2CDstatus.type = params.params[1] and params.params[1].i or 0
                gamedata.cache.gang2CDstatus.time = params.params[2] and params.params[2].i or 0
            end
        end
    end

    return { type = 2230, gang2status = gamedata.cache.gang2status, param = gamedata.ext.gang2statusparam}
end

function UIUserGang2CreateCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2231, "UserGang2Create")
    local names = params_pb.ParamS()
    local name = params_pb.ParamS.Param()

    name.s = uireq.name or ""
    table.insert(names.params, name)

    return 1, 2231, names:SerializeToString()
end

function NetUserGang2CreateCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2231, "UserGang2Create")
    -- local result = result_pb.Result()
    -- result:ParseFromString(fd.rbuf)
    -- if result.result then
    --     gamedata:updateRoleGold(-gamedata.config.global_kv.gang_establish_coin.value,"创建公会",1)
    -- end
    -- return { type = 2231, result = result.result }

    local result = ids_pb.Ids()
    result:ParseFromString(fd.rbuf)
    if result.ids[1] and result.ids[1] == 0 then
        gamedata:updateRoleGold(-gamedata.config.global_kv.gang_establish_coin.value,"创建公会",1)
    end


    return { type = 2231, result = result.ids[1] }

end

function UIUserGang2ListCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2232, "UserGang2List")

    return 1, 2232, nil

end

function NetUserGang2ListCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2232, "UserGang2List")

    local Gangs2Data = combmessages_pb.CombMessages()
    Gangs2Data:ParseFromString(fd.rbuf)

    gamedata.cache.gangs2 = {}
    for k,v in ipairs(Gangs2Data.messages) do
        local params = params_pb.ParamS()
        params:ParseFromString(v.data)
        local gang = gamedata:Gang2Data(params.params)
        table.insert(gamedata.cache.gangs2, gang )
    end

    local sortByPower = function(a,b)
        if a.level == b.level then
            return a.power > b.power
        else
            return a.level > b.level
        end
    end
    table.sort(gamedata.cache.gangs2, sortByPower)

    return { type = 2232, gangs = gamedata.cache.gangs2, gang2CDstatus = gamedata.cache.gang2CDstatus or {} }

end

function UIUserGang2ReqCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2233, "UserGang2Req")
    local GangsReqData = ids_pb.Ids()
    table.insert(GangsReqData.ids, uireq.id or 0)

    gamedata.ext.reqgangid = uireq.id or 0

    return 1, 2233, GangsReqData:SerializeToString()
end

function NetUserGang2ReqCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2233, "UserGang2Req")
    -- local GangsReqData = result_pb.Result()
    -- GangsReqData:ParseFromString(fd.rbuf)
    -- local id = 0
    -- if GangsReqData.result then
    --     for k,v in pairs(gamedata.cache.gangs2) do
    --         if v.id == gamedata.ext.reqgangid then
    --             gamedata.cache.gangs2[k].param = 1
    --         end
    --     end
    --     id = gamedata.ext.reqgangid
    -- end

    -- return { type = 2233, id = id}
    local GangsReqData = ids_pb.Ids()
    GangsReqData:ParseFromString(fd.rbuf)
    local id = 0
    local idTable = {}
    if GangsReqData.ids[1] then
        if gamedata.ext.reqgangid and gamedata.ext.reqgangid > 0 then
            for k,v in pairs(gamedata.cache.gangs2) do
                if v.id == gamedata.ext.reqgangid then
                    gamedata.cache.gangs2[k].param = 1
                end
            end
            id = gamedata.ext.reqgangid
        else
            for k,v in pairs(gamedata.cache.gangs2) do
                if v.autoStatus == 1 and (gamedata.cache.role.level >= v.autoLv) then

                else
                    gamedata.cache.gangs2[k].param = 1
                    table.insert(idTable,v.id)
                end
            end
        end    
    end

    return { type = 2233, id = id, idTable = idTable, result = GangsReqData.ids[1]}
end

function UIUserGang2ReqQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2234, "UserGang2ReqQuery")
    return 1, 2234, nil
end

function NetUserGang2ReqQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2234, "UserGang2ReqQuery")
    local GangReqQueryData = players_pb.Players()
    GangReqQueryData:ParseFromString(fd.rbuf)

    return { type = 2234, players = makeReqPlayers(GangReqQueryData.players),}
end

function UIUserGang2RepCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2235, "UserGang2Rep")
    local GangReqRepData = ids_pb.Ids()
    table.insert(GangReqRepData.ids, uireq.id)
    table.insert(GangReqRepData.ids, uireq.opt)

    gamedata.ext.GangReqRepid = uireq.id
    gamedata.ext.GangReqRepopt = uireq.opt

    return 1, 2235, GangReqRepData:SerializeToString()
end

function NetUserGang2RepCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2235, "UserGang2Rep")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    local result = 0

    if ids.ids[1] then result = ids.ids[1] end

    return { type = 2235, result = result, id = gamedata.ext.GangReqRepid,opt = gamedata.ext.GangReqRepopt }
end

function UIUserGang2MemberCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2236, "UserGang2Member")

    return 1, 2236, nil
end

function NetUserGang2MemberCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2236, "UserGang2Member")
    if not fd.rbuf or fd.rbuf == "" then
    else
        gamedata.cache.gang2members = {}
        local Gang2MembersData = combmessages_pb.CombMessages()
        Gang2MembersData:ParseFromString(fd.rbuf)
        for k,v in ipairs(Gang2MembersData.messages) do
            if v.id == 0 then
                local ids = ids_pb.Ids()
                ids:ParseFromString(v.data)
                gamedata:Gang2Post(ids.ids)
            else
                local params = params_pb.ParamS()
                params:ParseFromString(v.data)
                table.insert(gamedata.cache.gang2members,gamedata:Gang2MemberData(params.params))
            end
        end
    end

    return { type = 2236, gangmembers = gamedata.cache.gang2members, gang2post = gamedata.cache.gang2post, gang2status = gamedata.cache.gang2status }
end

function UIUserGang2MSetContent1CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2237, "UserGang2MSetContent1")
    local texts = params_pb.ParamS()
    local text = params_pb.ParamS.Param()

    text.s = uireq.text or ""
    table.insert(texts.params, text)

    gamedata.ext.GangSetContent1Text = uireq.text

    return 1, 2237, texts:SerializeToString()
end

function NetUserGang2MSetContent1CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2237, "UserGang2MSetContent1")
    local result = result_pb.Result()
    result:ParseFromString(fd.rbuf)

    if result.result then
        gamedata.cache.gang2status.content = gamedata.ext.GangSetContent1Text or ""
    end

    return { type = 2237, result = result.result }
end

function UIUserGang2MSetContent2CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2238, "UserGang2MSetContent2")
    local texts = params_pb.ParamS()
    local text = params_pb.ParamS.Param()

    text.s = uireq.text or ""
    table.insert(texts.params, text)

    gamedata.ext.GangSetContent2Text = uireq.text

    return 1, 2238, texts:SerializeToString()
end

function NetUserGang2MSetContent2CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2238, "UserGang2MSetContent2")
    local result = result_pb.Result()
    result:ParseFromString(fd.rbuf)

    if result.result then
        gamedata.cache.gang2status.declaration = gamedata.ext.GangSetContent2Text or ""
    end

    return { type = 2238, result = result.result }
end

function UIUserGang2MSetViceCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2239, "UserGang2MSetVice")

    if uireq.opt and uireq.opt == 0 and gamedata.cache.gang2post.post2_1 and gamedata.cache.gang2post.post2_1 > 0 and gamedata.cache.gang2post.post2_2 and gamedata.cache.gang2post.post2_2 > 0 and gamedata.cache.gang2post.post2_3 and gamedata.cache.gang2post.post2_3 > 0 then
        return 0, 503, {type = 503, msg = "副会长人数已达上限"}
    else
        local GangSetAssistantData = ids_pb.Ids()
        table.insert(GangSetAssistantData.ids, uireq.opt)
        table.insert(GangSetAssistantData.ids, uireq.id)

        gamedata.ext.GangSetAssistantopt = uireq.opt
        gamedata.ext.GangSetAssistantid = uireq.id

        return 1, 2239, GangSetAssistantData:SerializeToString()
    end
end

function NetUserGang2MSetViceCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2239, "UserGang2MSetVice")
    local GangSetAssistantData = result_pb.Result()
    GangSetAssistantData:ParseFromString(fd.rbuf)

    return { type = 2239, result = GangSetAssistantData.result}
end

function UIUserGang2MKickCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2240, "UserGang2MKick")
    local GangKickData = ids_pb.Ids()
    table.insert(GangKickData.ids, uireq.id)

    gamedata.ext.GangKickid = uireq.id

    return 1, 2240, GangKickData:SerializeToString()
end

function NetUserGang2MKickCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2240, "UserGang2MKick")
    local GangKickData = result_pb.Result()
    GangKickData:ParseFromString(fd.rbuf)

    return { type = 2240, result = GangKickData.result}
end

function UIUserGang2MPassCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2241, "UserGang2MPass")
    local GangPassData = ids_pb.Ids()
    table.insert(GangPassData.ids, uireq.id)

    gamedata.ext.GangPassid = uireq.id

    return 1, 2241, GangPassData:SerializeToString()
end

function NetUserGang2MPassCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2241, "UserGang2MPass")
    local GangPassData = result_pb.Result()
    GangPassData:ParseFromString(fd.rbuf)

    return { type = 2241, result = GangPassData.result}
end

function UIUserGang2QuitCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2242, "UserGang2Quit")
    return 1, 2242, nil
end

function NetUserGang2QuitCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2242, "UserGang2Quit")
    local GangQuitData = result_pb.Result()
    GangQuitData:ParseFromString(fd.rbuf)

    return { type = 2242, result = GangQuitData.result}
end

function UIUserGang2SearchCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2243, "UserGang2Search")
    local names = params_pb.ParamS()
    local name = params_pb.ParamS.Param()

    name.s = uireq.name or ""
    table.insert(names.params, name)

    return 1, 2243, names:SerializeToString()
end

function NetUserGang2SearchCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2243, "UserGang2Search")
    local params = params_pb.ParamS()
    params:ParseFromString(fd.rbuf)
    local gang = gamedata:Gang2Data(params.params)
    local gangs = {}
    if gang.id and gang.id > 0 then
        table.insert(gangs,gang)
    end
    return { type = 2243, gangs = gangs }
end

-- 上香查询
function UIUserGang2PrayQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2250, "UserGang2PrayQuery")

    if gamedata.cache.gang2pray then
        return 0,2250,{type = 2250, status = gamedata.cache.gang2pray }
    else
        return 1, 2250, nil
    end


end

function NetUserGang2PrayQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2250, "UserGang2PrayQuery")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    gamedata.cache.gang2pray = ids.ids[1]

    return {type = 2250, status = gamedata.cache.gang2pray}
end

-- 上香
function UIUserGang2PrayCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2251, "UserGang2Pray")
    local Gang2PrayData = ids_pb.Ids()
    table.insert(Gang2PrayData.ids, uireq.method)

    gamedata.ext.gonghuipraymethod = uireq.method

    gamedata.ext.gonghuinextgold = 0
    gamedata.ext.gonghuinextconin = 0

    if uireq.gold then
        gamedata.ext.gonghuinextgold = uireq.gold
    end
    if uireq.coin then
        gamedata.ext.gonghuinextconin = uireq.coin
    end


    return 1, 2251, Gang2PrayData:SerializeToString()
end

function NetUserGang2PrayCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2251, "UserGang2Pray")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    gamedata.cache.gang2status.totalcontribution = gamedata.cache.gang2status.totalcontribution+ids.ids[2]
    gamedata.cache.gang2status.contribution = gamedata.cache.gang2status.contribution+ids.ids[1]
    print("NetUserGang2PrayCallBack===")
    for k,v in pairs(ids.ids) do
        print(k,v)
    end

    print("spendgold=",gamedata.ext.gonghuinextgold)
    print("spendcoin=",gamedata.ext.gonghuinextconin)
    gamedata:updateRoleGold(0-gamedata.ext.gonghuinextgold,"工会贡品(上香)",1)
    gamedata:updateRoleCoin(0-gamedata.ext.gonghuinextconin,"工会贡品(上香)",1)

    gamedata.cache.gang2pray = gamedata.ext.gonghuipraymethod

    return {type = 2251, result = ids.ids[3],totalcontribution = ids.ids[2], contribution = ids.ids[1]}
end



-------------------------------------------------------------------------------------------------------

--工会商店

function UIGuideShopViewCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2252, "GuildeShopView")
    return 1,2252,nil

end

function NetGuideShopViewCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2252, "GuildeShopView")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    gamedata:GangShopGoods(ids)
    return {type = 2252, data = gamedata.cache.gang_shopgoods or {}, gangdata = gamedata.cache.gang2status}

end

function UIGuideShopBuyGoodsCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2253, "GuildeShopBuyGoods")
    local doData = ids_pb.Ids()
    table.insert(doData.ids,uireq.id or 1)
    table.insert(doData.ids,uireq.num or 1)

    gamedata.ext.shopContribution = uireq.contribution or 0
    gamedata.ext.shopContributionNum = uireq.num or 1
    return 1,2253,doData:SerializeToString()

end

function NetGuideShopBuyGoodsCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2253, "GuildeShopBuyGoods")
    local  getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)
    --减去缓存的贡献值
    gamedata.cache.gang2status["contribution"] = gamedata.cache.gang2status["contribution"] - gamedata.ext.shopContribution*gamedata.ext.shopContributionNum
    gamedata.ext.shopContribution = 0
    return {type = 2253,reward = gamedata:SomethingProcess(getData)}
        
end

-----------------------------------------------------------------------------------------------
--公会动态
function UIUserGang2OptsCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2254, "UserGang2Opts")

    local pos = 0
    if gamedata.cache.gang2Legion and gamedata.cache.gang2Legion.startLocation then
        pos = gamedata.cache.gang2Legion.startLocation
    end

    local OptsData = ids_pb.Ids()

    table.insert(OptsData.ids, pos)
    table.insert(OptsData.ids, 20)

    return 1, 2254, OptsData:SerializeToString()

end

function NetUserGang2OptsCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2254, "UserGang2Opts")
    local ganglegionData = combmessages_pb.CombMessages()
    ganglegionData:ParseFromString(fd.rbuf)
    for k,v in ipairs(ganglegionData.messages) do
        local msgnum = #ganglegionData.messages-1
        if v.id == -1 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:Gang2Legion(ids.ids,msgnum)
        else
            local params = params_pb.ParamS()
            params:ParseFromString(v.data)
            gamedata:Gang2Legion2(params.params)
        end
    end
    return {type = 2254, gangsLegion = gamedata.cache.gang2Legion}
end

function UIUserGang2ImpeachCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2255, "UserGang2Impeach")

    return 1,2255,nil
end

function NetUserGang2ImpeachCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2255, "UserGang2Impeach")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    local result = -1
    if ids.ids[1] then
       -- if ids.ids[1] == 0 then
       --     result = 0
       --     gamedata.cache.gang2status.status = 999
       -- elseif ids.ids[1] == 1 then
       --     result = 1
       -- elseif ids.ids[1] == 2 then
       --     result = 2
       --     gamedata.cache.gang2status.status = 999
       -- end
       if ids.ids[1] == 0 then
           result = 0
           gamedata.cache.gang2status.status = 999
       elseif ids.ids[1] == 2006 then
           result = 2006
       elseif ids.ids[1] == 2007 then
           result = 2007
           gamedata.cache.gang2status.status = 999
       end
    end

    return { type = 2255, result = result}
end


-- 仙池查询
function UIUserGang2FishpondCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2256, "UserGang2Fishpond")
    print("UIUserGang2FishpondCallBack")
    return 1, 2256, nil
end

function NetUserGang2FishpondCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2256, "UserGang2Fishpond")
    print("NetUserGang2FishpondCallBack")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    for k,v in pairs(ids.ids) do
        print(k,v)
    end

    gamedata:GangXianChiData(ids.ids)

    return {type = 2256, data=gamedata.cache.gang2xianchi}

end

-- 仙池扔肥皂
function UIUserGang2FishpondFeedCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2257, "UserGang2FishpondFeed")
    local fishFeed = ids_pb.Ids()
    gamedata.ext.fishfeedchangedata = uireq.changedata
    print("UIUserGang2FishpondFeedCallBack")
    -- printT(uireq)
    for k,v in pairs(uireq.changedata) do
        print("i...am...in:")
        table.insert(fishFeed.ids,v.cid)
        table.insert(fishFeed.ids,v.num)
    end

    return 1,2257,fishFeed:SerializeToString()
end

function NetUserGang2FishpondFeedCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2257, "UserGang2FishpondFeed")
    local Gang2StatusData = combmessages_pb.CombMessages()
    Gang2StatusData:ParseFromString(fd.rbuf)


    -- printT(Gang2StatusData)
    for k,v in pairs(gamedata.ext.fishfeedchangedata) do
        if gamedata.cache.props[tonumber(v.cid)] then
            gamedata.cache.props[tonumber(v.cid)].num = gamedata.cache.props[tonumber(v.cid)].num - v.num
        end
    end
    
    local getChangedata = {}
    local changeGangLevelData = {}
    local changexianchiLevelData = {}
    local getRewardData = {}


    print("NetUserGang2FishpondFeedCallBack===")


    for k,v in ipairs(Gang2StatusData.messages) do
        if v.id == 0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            print("idsnum===",ids.ids[1])

            if ids.ids[1] == 1 then
                -- 帮派升级

            elseif ids.ids[1] == 2 then
                -- 鱼塘升阶
                changexianchiLevelData.status = "xc_quality"
            else

                -- getChangedata.gang_exp = ids.ids[3]
                -- getChangedata.contribution = ids.ids[4]
                -- getChangedata.xc_exp = ids.ids[5]

                -- print("gangexp ===",gamedata.cache.gang2status.exp)
                -- print("000ids345＝＝",ids.ids[3],ids.ids[4],ids.ids[5])

                gamedata.cache.gang2status.exp = gamedata.cache.gang2status.exp + ids.ids[3]

                -- gamedata.cache.gang2status.totalcontribution = gamedata.cache.gang2status.totalcontribution + ids.ids[4]
                -- gamedata.cache.gang2status.contribution = gamedata.cache.gang2status.contribution + ids.ids[4]
                -- -- gamedata.cache.gang2xianchi.xc_exp = gamedata.cache.gang2xianchi.xc_exp + ids.ids[5]
                -- -- gamedata.cache.gang2xianchi.xc_dayprogress = gamedata.cache.gang2xianchi.xc_dayprogress + ids.ids[6]

                -- print("gangexp2 ===",gamedata.cache.gang2status.exp)

            end

            getChangedata.gang_exp = ids.ids[3]
            getChangedata.contribution = ids.ids[4]
            getChangedata.xc_exp = ids.ids[5]

            -- print("gangexp ===",gamedata.cache.gang2status.exp)
            -- print("000ids345＝＝",ids.ids[3],ids.ids[4],ids.ids[5])

            -- gamedata.cache.gang2status.exp = gamedata.cache.gang2status.exp + ids.ids[3]
            
            gamedata.cache.gang2status.totalcontribution = gamedata.cache.gang2status.totalcontribution + ids.ids[4]
            gamedata.cache.gang2status.contribution = gamedata.cache.gang2status.contribution + ids.ids[4]
            -- gamedata.cache.gang2xianchi.xc_exp = gamedata.cache.gang2xianchi.xc_exp + ids.ids[5]
            -- gamedata.cache.gang2xianchi.xc_dayprogress = gamedata.cache.gang2xianchi.xc_dayprogress + ids.ids[6]



            if ids.ids[2] ~= 0 then
                -- 鱼塘升级
                changexianchiLevelData.status = "xc_level"
            end

        elseif v.id == 1 then
            print("i...am。。工会升级")
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            changeGangLevelData.gang_level = ids.ids[2]

            gamedata.cache.gang2status.exp = ids.ids[1]
            gamedata.cache.gang2status.level = ids.ids[2]

        elseif v.id == 2 then
            print("i...am..鱼塘升级 or 升阶")
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)

            changexianchiLevelData.xc_quality = ids.ids[1]
            changexianchiLevelData.xc_level = ids.ids[3]

            gamedata.cache.gang2xianchi.xc_quality = ids.ids[1]
            gamedata.cache.gang2xianchi.xc_exp = ids.ids[2]
            gamedata.cache.gang2xianchi.xc_level = ids.ids[3]
            gamedata.cache.gang2xianchi.xc_dayprogress = ids.ids[4]

            gamedata.cache.gang2xianchi.rewardstatus1 = ids.ids[5]
            gamedata.cache.gang2xianchi.rewardstatus2 = ids.ids[6]
            gamedata.cache.gang2xianchi.rewardstatus3 = ids.ids[7]
            gamedata.cache.gang2xianchi.rewardstatus4 = ids.ids[8]
            gamedata.cache.gang2xianchi.eattimesnum = ids.ids[9]

            print("i...net end...",ids.ids[9])
            -- printT(ids.ids)
        elseif v.id == 3 then
            local  getData = somethings_pb.SomeThings()
            getData:ParseFromString(v.data)
            getRewardData = getData
        end
    end
    print("i...net end...")
    -- printT(gamedata.cache.gang2xianchi)
    return { type = 2257, getChangedata = getChangedata, xianchidata = gamedata.cache.gang2xianchi, changeGangLevelData = changeGangLevelData, changexianchiLevelData = changexianchiLevelData, reward = gamedata:SomethingProcess(getRewardData)}
end

function UIUserGang2FishpondRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2258, "UserGang2FishpondReward")
    local getReward = ids_pb.Ids()
    print("UIUserGang2FishpondFeedCallBack")
    -- printT(uireq)
    table.insert(getReward.ids,uireq.id)

    return 1,2258,getReward:SerializeToString()
end

function NetUserGang2FishpondRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2258, "UserGang2FishpondReward")
    local  getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    return { type = 2258, reward = gamedata:SomethingProcess(getData)}
end

function UIUserGang2MSetNameCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2259, "UserGang2MSetName")

    if gamedata.cache.role.gold < 300 then
        return 0,503,{type = 503, msgtype = "shortgold"}
    end

    local texts = params_pb.ParamS()
    local text = params_pb.ParamS.Param()

    text.s = uireq.text or ""
    table.insert(texts.params, text)

    gamedata.ext.GangSetNameText = uireq.text

    return 1, 2259, texts:SerializeToString()
end

function NetUserGang2MSetNameCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2259, "UserGang2MSetName")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    if ids.ids[1] and ids.ids[1] == 0 then
        gamedata.cache.gang2status.name = gamedata.ext.GangSetNameText or ""
        gamedata:updateRoleGold(-300,"公会改名",1)
    end

    return { type = 2259, result = ids.ids[1] or 0 }
end


function UIUserGang2DailyRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2260, "UserGang2DailyReward")

    return 1, 2260, nil
end

function NetUserGang2DailyRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2260, "UserGang2DailyReward")
    local  getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    gamedata.cache.gang2status["rewardstatus"] = 1

    return {type = 2260,reward = gamedata:SomethingProcess(getData)}
end

function UIUserGang2FishpondPointRankCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2261, "RankQuery")
    return 1, 2261, nil
end

function NetUserGang2FishpondPointRankCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2261, "RankQuery")

    local playersData = players_pb.Players()
    playersData:ParseFromString(fd.rbuf)

    return { type = 2261, players = gamedata:players(playersData.players)}

end
--工会技能
function UIGangSkillQuery( uireq )
    cclog("NET type:%d cmd:%s recv request from UI", 2262, "UIGangSkillQuery")
    if next(gamedata.cache.gang2skill) then
            return 0, 2262, {type = 2262, gang2status = gamedata.cache.gang2status,gang2skill = gamedata.cache.gang2skill}
        else
            return 1, 2262, nil
    end
end

function NetGangSkillQuery( fd )
    cclog("NET type:%d cmd:%s recv response from gameserver", 2262, "NetGangSkillQuery")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    gamedata:gangSkill(ids.ids)
    return {type = 2262, gang2status = gamedata.cache.gang2status,gang2skill = gamedata.cache.gang2skill}  
end
--学习或升级 工会技能
function UIGangSkillStudy( uireq )
    cclog("NET type:%d cmd:%s recv request from UI", 2263, "UIGangSkillStudy")
    gamedata.ext.studySkill = {id = uireq.id ,resNum =uireq.num }
    print(uireq.id)
    print(uireq.num)
    local ids = ids_pb.Ids()
    table.insert(ids.ids, uireq.index)
    return 1, 2263, ids:SerializeToString()

end
function NetGangSkillStudy( fd )
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    if ids.ids[1] == 1 then --学习成功
        gamedata.cache.gang2status.contribution = gamedata.cache.gang2status.contribution - gamedata.ext.studySkill.resNum
        printT(gamedata.cache.gang2skill)
        print(gamedata.ext.studySkill.id)
        printT(gamedata.cache.gang2skill[tostring(gamedata.ext.studySkill.id)])
        print(gamedata.cache.gang2skill[tostring(gamedata.ext.studySkill.id)][1])
        print(type(gamedata.cache.gang2skill[tostring(gamedata.ext.studySkill.id)]["1"]))
        gamedata.cache.gang2skill[tostring(gamedata.ext.studySkill.id)][1] = gamedata.cache.gang2skill[tostring(gamedata.ext.studySkill.id)][1] + 1
    end
    return {type = 2263, gang2status = gamedata.cache.gang2status,gang2skill = gamedata.cache.gang2skill} 

end


--[[
[4840] = UIGang2BossCallBack,
[4841] = UIGang2BossRankCallBack,
[4842] = UIGang2RoleRankCallBack,
[4843] = UIGang2BossInspireCallBack,
[4844] = UIGang2BossBattleCallBack,
[4845] = NetGang2BossNotifyCallBack,
]]

local params_pb = require("params_pb")
local worldboss1_pb = require("worldboss1_pb")
local worldboss1realnotify_pb = require("worldboss1realnotify_pb")
require"PickBattleResultReport"

function UIGang2BossCallBack( uireq )
    cclog("NET type:%d cmd:%s recv request from UI", 4840, "UIGang2BossCallBack")
    return 1, 4840, nil
end

function NetGang2BossCallBack( fd )
    cclog("NET type:%d cmd:%s recv response from gameserver", 4840, "NetGang2BossCallBack")
    local bossdata = params_pb.ParamS()
    bossdata:ParseFromString(fd.rbuf)
    gamedata:GangBoss(bossdata.params)
    return {type = 4840, gangboss = gamedata.cache.gangboss}
end

--
function UIGang2BossInspireCallBack( uireq )
    cclog("NET type:%d cmd:%s recv request from UI", 4843, "UIGang2BossInspireCallBack")
    --add if not enough gold method hx
    local isenough, ret = gamedata.checkStaffEnough(1001,uireq.xgold,{})
    if not isenough then
        ret.msgtype = "shortgoldNoOpenWindow"
        return 0, 503, ret
    --runGamePrompt({msg = gamedata.config.strings:string_common("popups","goldbz")})
    --runGamePrompt({msg = "元宝不足"})
    end
    gamedata.ext.Gang2BossInspireGold = uireq.xgold or 0

    return 1, 4843, nil
end

function NetGang2BossInspireCallBack( fd )
    cclog("NET type:%d cmd:%s recv response from gameserver", 4843, "NetGang2BossInspireCallBack")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    local result = ids.ids[1] or 0
    if gamedata.ext.Gang2BossInspireGold and gamedata.ext.Gang2BossInspireGold > 0 then
        gamedata:updateRoleGold(0-gamedata.ext.Gang2BossInspireGold,"公会BOSS元宝鼓舞",1)
    end

    return {type = 4843, result = result}
end

--
function UIGang2BossRankCallBack( uireq )
    cclog("NET type:%d cmd:%s recv request from UI", 4841, "UIGang2BossRankCallBack")
    return 1, 4841, nil
end

function NetGang2BossRankCallBack( fd )
    cclog("NET type:%d cmd:%s recv response from gameserver", 4841, "NetGang2BossRankCallBack")
    local rankdata = params_pb.ParamS()
    rankdata:ParseFromString(fd.rbuf)
    local gangrank = {}
    local myrank = {}

    myrank.rank = rankdata.params[1].i or 0
    myrank.name = rankdata.params[1].s or ""
    myrank.id = rankdata.params[2].i or 0
    myrank.president = rankdata.params[2].s or ""
    myrank.members = rankdata.params[3].i or 0
    myrank.notice = rankdata.params[3].s or ""
    myrank.damage = rankdata.params[4].s or ""

    for i = 2,#rankdata.params/4 do
        local rank = {}
        rank.rank = rankdata.params[4*i-3].i or 0
        rank.name = rankdata.params[4*i-3].s or ""
        rank.id = rankdata.params[4*i-2].i or 0
        rank.president = rankdata.params[4*i-2].s or ""
        rank.members = rankdata.params[4*i-1].i or 0
        rank.notice = rankdata.params[4*i-1].s or ""
        rank.damage = rankdata.params[4*i].s or ""

        gangrank[tostring(rank.rank)] = rank
    end


    return {type = 4841, gangrank = gangrank, myrank = myrank}
end

--
--
function UIGang2RoleRankCallBack( uireq )
    cclog("NET type:%d cmd:%s recv request from UI", 4842, "UIGang2RoleRankCallBack")
    return 1, 4842, nil
end

function NetGang2RoleRankCallBack( fd )
    cclog("NET type:%d cmd:%s recv response from gameserver", 4842, "NetGang2RoleRankCallBack")
    local rankdata = params_pb.ParamS()
    rankdata:ParseFromString(fd.rbuf)

    local rolerank = {}

    for i = 1,#rankdata.params/7 do
        local rank = {}
        rank.rank = rankdata.params[7*i-6].i or 0
        rank.vip = rankdata.params[7*i-5].i or 0
        rank.level = rankdata.params[7*i-4].i or 0
        rank.profile = rankdata.params[7*i-3].i or 0
        rank.name = rankdata.params[7*i-3].s or ""
        rank.title = rankdata.params[7*i-2].i or 0
        rank.iconBox = rankdata.params[7*i-1].i or 0

        rank.contribution = rankdata.params[7*i].i or 0
        
        rolerank[tostring(rank.rank)] = rank
    end


    return {type = 4842, rolerank = rolerank}
end

--
function UIGang2BossBattleCallBack( uireq )
    cclog("NET type:%d cmd:%s recv request from UI", 4844, "UIGang2BossBattleCallBack")
    return 1, 4844, nil
end

function NetGang2BossBattleCallBack( fd )
    cclog("NET type:%d cmd:%s recv response from gameserver", 4844, "NetGang2BossBattleCallBack")

    local WorldBoss1AttackData = worldboss1_pb.WorldBoss1()
    WorldBoss1AttackData:ParseFromString(fd.rbuf)

    return {
        type = 4844,
        result = WorldBoss1AttackData.battle.result,
        n_reward = gamedata:SomethingProcess(WorldBoss1AttackData.battle.reward),
        battlereport = PickBattleResultReport(WorldBoss1AttackData.battle),
        star = WorldBoss1AttackData.battle.star,
    }
end


function NetGang2BossNotifyCallBack( fd )
    cclog("NET type:%d cmd:%s recv response from gameserver", 4845, "NetGang2BossNotifyCallBack")
    local notifydata = params_pb.ParamS()
    notifydata:ParseFromString(fd.rbuf)

    local notify = {}

    notify.status = notifydata.params[1].i or 0
    notify.hp = notifydata.params[2].s and tonumber(notifydata.params[2].s or 0) or 0
    notify.name = notifydata.params[3].s or ""
    notify.damage = notifydata.params[3].i or 0

    return {type = 4845, notify = notify}
end

function NetGang2BossChangeCallBack( fd )
    cclog("NET type:%d cmd:%s recv response from gameserver", 4846, "NetGang2BossChangeCallBack")

    return {type = 4846}
end


function UIGang2GroundQueryCallBack( uireq )
    cclog("NET type:%d cmd:%s recv request from UI", 5150, "UIGang2GroundQueryCallBack")
    return 1, 5150, nil
end

function NetGang2GroundQueryCallBack( fd )
    cclog("NET type:%d cmd:%s recv response from gameserver", 5150, "NetGang2GroundQueryCallBack")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    gamedata:GangGuardData(ids.ids)

    return { type = 5150, data = gamedata.cache.gangGuard}
    
end

local score = 0
local boxs = {}
local mouseTab = {}
local hp = 0
local battleNum = 0
local randomlevel = 1
local pointIndex  = 0

function UIGang2GroundStartCallBack( uireq )
    cclog("NET type:%d cmd:%s recv request from UI", 5151, "UIGang2GroundStartCallBack")

    local doData = ids_pb.Ids()
    table.insert(doData.ids,uireq.id or 0)

    gamedata.ext.guardCostGold = uireq.gold or 0
    if uireq.gold then
        if gamedata.cache.role.gold < uireq.gold then
            return 0,503,{type = 503, msgtype = "shortgold"}
        end
    end
    return 1, 5151, doData:SerializeToString()

end

function NetGang2GroundStartCallBack( fd )
    cclog("NET type:%d cmd:%s recv response from gameserver", 5151, "NetGang2GroundStartCallBack")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    local goStatus = ids.ids[1]
    local scorenum = ids.ids[2] or 0

    if gamedata.ext.guardCostGold and gamedata.ext.guardCostGold > 0 then
        gamedata:updateRoleGold(0-gamedata.ext.guardCostGold,"公会玩法记录开始",1)
    end

    score = scorenum
    boxs = {}
    hp = tonumber(gamedata.config.global_kv.guild_box_life.value)
    battleNum = 0
    mouseTab = {}
    pointIndex  = 0

    return { type = 5151, status = goStatus,score = scorenum}
end




function UIGang2GroundGetHogsCallBack( uireq )
    cclog("NET type:%d cmd:%s recv request from UI", 5152, "UIGang2GroundGetHogsCallBack")

    local poconfig = gamedata.config.guild_play
    local maxlevel = table.getTableLength(poconfig)
    local maxboxnum = tonumber(gamedata.config.global_kv.guild_box_up.value)

    local goStatus = 0
    local mouseNum = 0

    local level = 1
    for i=1,maxlevel do
        local config = poconfig[tostring(i)]
        if score>=config.lower and score<=config.upper then
            level = i
            break
        end
    end

    randomlevel = level

    local levelconfig = poconfig[tostring(level)]
    mouseNum = levelconfig.blame

    local monsterrange = levelconfig.devil1+levelconfig.devil2+levelconfig.devil3
    local allrange = levelconfig.devil1+levelconfig.devil2+levelconfig.devil3+levelconfig.devil4

    local newmouseTab = {}
    local posmap = {}
    for i=1,9 do
        local active = false
        for k,v in pairs(mouseTab) do
            if v.point == i then
                if not v.used then
                    table.insert(newmouseTab,v)
                    active = true
                end
            end
        end  
        if not active then 
            if pointIndex ~= i then
                table.insert(posmap,i) 
            end
        end    
    end
    mouseTab = newmouseTab

    printT(mouseTab)
    printT(posmap)

    local currmouseTab = {}
    pointIndex  = 0
    if #posmap >1 then
        for i=1,mouseNum do
            local pointidx = math.random(1,#posmap)
            local point = posmap[pointidx]
            pointIndex = point
            table.remove(posmap,pointidx)
            local randomid=1
            if #boxs>=maxboxnum then
                randomid = math.random(1,monsterrange)
            else
                randomid = math.random(1,allrange)
            end

            local id =1
            if randomid<=levelconfig.devil1 then
                id = 1
            elseif randomid<=levelconfig.devil1+levelconfig.devil2 then
                id = 2
            elseif randomid<=levelconfig.devil1+levelconfig.devil2+levelconfig.devil3 then
                id = 3
            else
                id = 4
            end
            currmouseTab[i] = {point=point,id=id}
            table.insert(mouseTab,{point=point,id=id})
        end
    end



    return 0, 5152, { type = 5152, status = goStatus,mouseNum = mouseNum,mouseTab = currmouseTab}
end

-- function NetGang2GroundGetHogsCallBack( fd )
--     cclog("NET type:%d cmd:%s recv response from gameserver", 5152, "NetGang2GroundCatchHogCallBack")
--     local ids = ids_pb.Ids()
--     ids:ParseFromString(fd.rbuf)
--     local goStatus = ids.ids[1]
--     local mouseNum = 0
--     local mouseTab = {}
--     if goStatus == 0 then
--         mouseNum = ids.ids[2]
--         for i =1 ,mouseNum do
--             mouseTab[i] = {}
--             mouseTab[i].point = ids.ids[2*(i-1)+3]
--             mouseTab[i].id = ids.ids[2*(i-1)+4]
--         end
--     --else

--     end

--     return { type = 5152, status = goStatus,mouseNum = mouseNum,mouseTab = mouseTab}
-- end

function UIGang2GroundCatchHogCallBack( uireq )
    cclog("NET type:%d cmd:%s recv request from UI", 5153, "UIGang2GroundCatchHogCallBack")

    printT(uireq,"uireq ---    ")
    local doData = ids_pb.Ids()

    if hp<=0 then
        return 0, 5153, { type = 5153, status = 3,mouseData = {}}
    end

    local scoreconfig = gamedata.config.guild_integral
    local maxbattleNum = tonumber(gamedata.config.global_kv.guide_even_up.value)
    local curretScore = 0

    for k,v in ipairs(mouseTab) do
        if v.point == uireq.point then

            if v.used == true then
                return 0, 5153, { type = 5153, status = 2,mouseData = {}}
            end 

            if v.id == 1 or v.id == 2 then
                if uireq.status == 0 then
                    if v.id == 2 then
                        
                    else
                        hp=hp-1
                        battleNum = 0
                    end
                elseif uireq.status == 1 then
                    battleNum = battleNum +1

                    local rewardidx=battleNum

                    if rewardidx>maxbattleNum then
                        rewardidx = maxbattleNum
                    end
                    curretScore = scoreconfig[tostring(v.id)]["second"..rewardidx]
                    score = score + curretScore
                end
            elseif v.id == 3 then
                if uireq.status == 1 then
                    hp=hp-1
                    battleNum = 0
                end
            elseif v.id == 4 then
                if uireq.status == 1 then
                    battleNum = battleNum +1
                    table.insert(boxs,gamedata.config.guild_play[tostring(randomlevel)].box)
                end
            end
            v.used = true
        end
    end

    local mouseData = {
        score = curretScore,
        battleNum = battleNum,
        powerSatus = 0,
        hp = hp,
    }

    return 0, 5153, { type = 5153, status = 0,mouseData = mouseData}

end

-- function NetGang2GroundCatchHogCallBack( fd )
--     cclog("NET type:%d cmd:%s recv response from gameserver", 5153, "NetGang2GroundCatchHogCallBack")

--     local ids = ids_pb.Ids()
--     ids:ParseFromString(fd.rbuf)
--     local mouseStatus = ids.ids[1]
--     local mouseData = {}
--     if mouseStatus == 0 then
--         mouseData.score = ids.ids[2]
--         mouseData.battleNum = ids.ids[3]
--         mouseData.powerSatus = ids.ids[4]
--         mouseData.hp = ids.ids[5]
--     end

--     return { type = 5153, status = mouseStatus,mouseData = mouseData}
-- end

function UIGang2GroundBoxRewardsCallBack( uireq )
    cclog("NET type:%d cmd:%s recv request from UI", 5154, "UIGang2GroundBoxRewardsCallBack")
    local getReward = ids_pb.Ids()
    table.insert(getReward.ids,uireq.pos)
    return 1,5154,getReward:SerializeToString()
end

function NetGang2GroundBoxRewardsCallBack( fd )
    cclog("NET type:%d cmd:%s recv response from gameserver", 5154, "NetGang2GroundBoxRewardsCallBack")
    local  getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)
    return { type = 5154, reward = gamedata:SomethingProcess(getData),index = gamedata.ext.guardrewardpos}

end

function UIGang2GroundRankCallBack( uireq )
    cclog("NET type:%d cmd:%s recv request from UI", 5155, "UIGang2GroundRankCallBack")
    local rankData = ids_pb.Ids()
    table.insert(rankData.ids,uireq.id or 0)
    gamedata.ext.guardRankId = uireq.id or 0
    return 1,5155,rankData:SerializeToString()
end

function NetGang2GroundRankCallBack( fd )
    cclog("NET type:%d cmd:%s recv response from gameserver", 5155, "NetGang2GroundRankCallBack")

    local playersData = players_pb.Players()
    playersData:ParseFromString(fd.rbuf)        
    local players=gamedata:players(playersData.players)

    local myrankData = players[table.getTableLength(players)]
    table.remove(players,table.getTableLength(players))

    return { type = 5155, players = players,myrank = myrankData,guardRankId = gamedata.ext.guardRankId}


end

function UIGang2GroundGameOverCallBack( uireq )
    cclog("NET type:%d cmd:%s recv request from UI", 5156, "UIGang2GroundGameOverCallBack")
    gamedata.ext.gameOverhighScore = uireq.highScore or 0
    local resultData = ids_pb.Ids()
    table.insert(resultData.ids,score or 0)
    table.insert(resultData.ids,#boxs or 0)
    for k,v in ipairs(boxs) do
        table.insert(resultData.ids,v)
    end

    print(score,#boxs)
    printT(boxs)

    return 1, 5156, resultData:SerializeToString()
end

function NetGang2GroundGameOverCallBack( fd )
    cclog("NET type:%d cmd:%s recv response from gameserver", 5156, "NetGang2GroundGameOverCallBack")

    local reps = combmessages_pb.CombMessages()
    reps:ParseFromString(fd.rbuf)
    local reward = nil
    local guardDataTab = {}
   
    for k,v in ipairs(reps.messages) do
        if v.id == 0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            local data = ids.ids
            guardDataTab.hightStatus = data[1] or 0
            guardDataTab.score = data[2] or 0
            guardDataTab.boxTab = {}
            for i=3,table.getTableLength(data) do
                guardDataTab.boxTab[tostring(i-2)] = data[i]
            end

        elseif v.id == 1 then
            local getData = somethings_pb.SomeThings()
            getData:ParseFromString(v.data)
            reward = gamedata:SomethingProcess(getData)
        end
    end

    return { type = 5156, reward = reward,guardDataTab = guardDataTab,hightScore = gamedata.ext.gameOverhighScore }

end

--
function UIGangApplyLimitCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2265, "UIGangApplyLimitCallBack")
    if uireq.status and uireq.guildLv then
        local ganglimit = ids_pb.Ids()
        table.insert(ganglimit.ids,uireq.status)
        table.insert(ganglimit.ids,uireq.guildLv)
        return 1,2265,ganglimit:SerializeToString()
    else
        return 1,2265,nil
    end

end

function NetGangApplyLimitCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2265, "NetGangApplyLimitCallBack")

    local ganglimitLv = ids_pb.Ids()
    ganglimitLv:ParseFromString(fd.rbuf)
    gangstatus = ganglimitLv.ids[1]
    ganglimitLv = ganglimitLv.ids[2]
    return { type = 2265, gangstatus = gangstatus,ganglimitLv = ganglimitLv}

end

function UIUserGang2DisbandCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2266, "UserGang2Disband")
    return 1, 2266, nil
end

function NetUserGang2DisbandCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2266, "UserGang2Disband")
    
    local GangDisbandData = ids_pb.Ids()
    GangDisbandData:ParseFromString(fd.rbuf)
    local disbandstatus = GangDisbandData.ids[1]

    return { type = 2266, result = disbandstatus}
end

--    [2267] = UIUserGang2ReqCancelCallBack,
function UIUserGang2ReqCancelCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2267, "Gang2ReqCancel")
    local GangsReqData = ids_pb.Ids()
    table.insert(GangsReqData.ids, uireq.id or 0)

    gamedata.ext.reqgangidcancel = uireq.id or 0

    return 1, 2267, GangsReqData:SerializeToString()
end

function NetUserGang2ReqCancelCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2267, "Gang2ReqCancel")

    local GangsReqData = ids_pb.Ids()
    GangsReqData:ParseFromString(fd.rbuf)
    local id = 0
    local idTable = {}
    if GangsReqData.ids[1] then
        if gamedata.ext.reqgangidcancel and gamedata.ext.reqgangidcancel > 0 then
            for k,v in pairs(gamedata.cache.gangs2) do
                if v.id == gamedata.ext.reqgangidcancel then
                    gamedata.cache.gangs2[k].param = 0
                end
            end
            id = gamedata.ext.reqgangidcancel
        else
            for k,v in pairs(gamedata.cache.gangs2) do
                if gamedata.cache.gangs2[k].param == 1 then
                    gamedata.cache.gangs2[k].param = 0
                    table.insert(idTable,v.id)
                end
            end
        end    
    end

    return { type = 2267, id = id, idTable = idTable, result = GangsReqData.ids[1]}
end


----------------------公会篝火---------------------------------------
function UIGangBathCheckCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2281, "UIGangBathCheckCallBack")
   
    return 1,2281,nil
end

function NetGangBathCheckCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2281, "NetGangBathCheckCallBack")

    local gangBathRoomInfo = ids_pb.Ids()
    gangBathRoomInfo:ParseFromString(fd.rbuf)

    local bathRoomInfo = {
        openCount = gangBathRoomInfo.ids[1],
        --joinCount = gangBathRoomInfo.ids[2],
        joinType = gangBathRoomInfo.ids[2],
        normalRoom = {
            roomStatus = gangBathRoomInfo.ids[3],
            doingStatus = gangBathRoomInfo.ids[4], --1准备 2进行中
            roomTime = gangBathRoomInfo.ids[5],
            roomPersonNum = gangBathRoomInfo.ids[6],
        },
        highRoom = {
            roomStatus = gangBathRoomInfo.ids[7],
            doingStatus = gangBathRoomInfo.ids[8], --1准备 2进行中
            roomTime = gangBathRoomInfo.ids[9],
            roomPersonNum = gangBathRoomInfo.ids[10],
        },
        superRoom = {
            roomStatus = gangBathRoomInfo.ids[11],
            doingStatus = gangBathRoomInfo.ids[12], --1准备 2进行中
            roomTime = gangBathRoomInfo.ids[13],
            roomPersonNum = gangBathRoomInfo.ids[14],
        },
    }
    return { type = 2281, data = bathRoomInfo}

end
--创建或加入
function UIGangCreateJoinBathCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2282, "UIGangCreateJoinBathCallBack")
    local createBath = ids_pb.Ids()
    table.insert(createBath.ids,uireq.roomid)
    table.insert(createBath.ids,uireq.controltype)
    table.insert(createBath.ids, uireq.gold or 0)
    gamedata.ext.bathprop = uireq.useProp
    gamedata.ext.bathstatus = uireq.controltype
    gamedata.ext.bathroomid = uireq.roomid

    if uireq.gold and uireq.gold ~= 0 then
        if gamedata.cache.role.gold < uireq.gold then
            return  0, 503, {type = 503, msgtype = "shortgold"}
        end
        gamedata.ext.GangCreateJoinBath_gold = uireq.gold
    end

    return 1,2282,createBath:SerializeToString()
end

function NetGangCreateJoinBathCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2282, "NetGangCreateJoinBathCallBack")

    local Gang2SBathData = combmessages_pb.CombMessages()
    Gang2SBathData:ParseFromString(fd.rbuf)

    local bathData = {
        feastPersonNum = 0,
        feastTime = 0,
        myFeastTime = 0,
        feastPlayers = {},
        onlineNum = 0,
        feastRoomid = gamedata.ext.bathroomid,
        openBathNum = 0,
        bathStatus = 0,
        myStatus = 0,
        -- rewardTimeNum = 0,
        curDayTimeNum = 0,
        curReward = {},
    }
    for k,v in ipairs(Gang2SBathData.messages) do
        if v.id == 1 then
            local bathinfo = ids_pb.Ids()
            bathinfo:ParseFromString(v.data)

            bathData.openBathNum = bathinfo.ids[1]
            bathData.feastPersonNum = bathinfo.ids[2]
            bathData.bathStatus = bathinfo.ids[3]
            bathData.feastTime = bathinfo.ids[4]
            bathData.myStatus = bathinfo.ids[5]
            bathData.myFeastTime = bathinfo.ids[6]--玩家活动奖励时间
            -- bathData.rewardTimeNum = bathinfo.ids[7]--获得发起奖励的秒数
            bathData.curDayTimeNum = bathinfo.ids[7]--当日已蹭秒
            bathData.onlineNum = bathinfo.ids[8]
        end
        if v.id == 2 then
            local playersData = players_pb.Players()
            playersData:ParseFromString(v.data)        
            bathData.feastPlayers = gamedata:players(playersData.players)
        end
        if v.id == 3 then
            local rewardinfo = ids_pb.Ids()
            rewardinfo:ParseFromString(v.data)
            local idx = 1
            for i=1,#rewardinfo.ids,2 do
                local tempdata = {
                    cid = rewardinfo.ids[i],
                    num = rewardinfo.ids[i+1]
                }
                bathData.curReward[idx] = tempdata
                idx = idx+1
            end  
        end
        
    end
    --参加时间
    bathData.myFeastTime = (gamedata:time())-bathData.myFeastTime

    if gamedata.ext.bathstatus == 2 and gamedata.ext.bathprop then
        gamedata.ext.bathprop.num = -gamedata.ext.bathprop.num
        gamedata:updateprops(gamedata.ext.bathprop)
    end

    if gamedata.ext.GangCreateJoinBath_gold and gamedata.ext.GangCreateJoinBath_gold > 0 then
        gamedata:updateRoleGold(0 - gamedata.ext.GangCreateJoinBath_gold ,"举办公会篝火",1)
        gamedata.ext.GangCreateJoinBath_gold = nil
    end
    
    return { type = 2282, data = bathData}

end

--领取奖励
function UIGangGetBathRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2283, "UIGangGetBathRewardCallBack")
    gamedata.ext.bathbei = uireq.beinum
    gamedata.ext.bathroomid = uireq.roomid
    gamedata.ext.bathPersonNum = uireq.personnum
    return 1,2283,nil
end

function NetGangGetBathRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2283, "NetGangGetBathRewardCallBack")

    local  getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)
    
    return { type = 2283, reward = gamedata:SomethingProcess(getData),beinum = gamedata.ext.bathbei, roomid = gamedata.ext.bathroomid, personNum = gamedata.ext.bathPersonNum}
end
--刷新房间数据
function UIGangRefreshBathCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2284, "UIGangRefreshBathCallBack")
    gamedata.ext.bathroomid = uireq.roomid
    gamedata.ext.isNotOpenBath = uireq.isNotOpen or false
    return 1,2284,nil
end

function NetGangRefreshBathCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2284, "NetGangRefreshBathCallBack")

    local Gang2SFeastData = combmessages_pb.CombMessages()
    Gang2SFeastData:ParseFromString(fd.rbuf)

    local bathData = {
        feastPersonNum = 0,
        feastTime = 0,
        myFeastTime = 0,
        feastPlayers = {},
        onlineNum = 0,
        feastRoomid = gamedata.ext.bathroomid,
        openBathNum = 0,
        bathStatus = 0,
        myStatus = 0,
        -- rewardTimeNum = 0,
        curDayTimeNum = 0,
        curReward = {},
    }
    if gamedata.ext.bathroomid and gamedata.ext.bathroomid > 0 then
        bathData.feastRoomid = gamedata.ext.bathroomid
    end

    for k,v in ipairs(Gang2SFeastData.messages) do
        if v.id == 1 then
            local bathinfo = ids_pb.Ids()
            bathinfo:ParseFromString(v.data)
            bathData.openBathNum = bathinfo.ids[1]
            bathData.feastPersonNum = bathinfo.ids[2]
            bathData.bathStatus = bathinfo.ids[3]
            bathData.feastTime = bathinfo.ids[4]
            bathData.myStatus = bathinfo.ids[5]
            bathData.myFeastTime = bathinfo.ids[6]--玩家活动奖励时间
            -- bathData.rewardTimeNum = bathinfo.ids[7]--获得发起奖励的秒数
            bathData.curDayTimeNum = bathinfo.ids[7]--当日已蹭秒
            bathData.onlineNum = bathinfo.ids[8]
        end
        if v.id == 2 then
            local playersData = players_pb.Players()
            playersData:ParseFromString(v.data)        
            bathData.feastPlayers = gamedata:players(playersData.players)
        end
        if v.id == 3 then
            local rewardinfo = ids_pb.Ids()
            rewardinfo:ParseFromString(v.data)
            local idx = 1
            for i=1,#rewardinfo.ids,2 do
                local tempdata = {
                    cid = rewardinfo.ids[i],
                    num = rewardinfo.ids[i+1]
                }
                bathData.curReward[idx] = tempdata
                idx = idx+1
            end  
        end
    end
        
    --参加时间
    bathData.myFeastTime = (gamedata:time())-bathData.myFeastTime
    
    local isNotOpen = gamedata.ext.isNotOpenBath
    gamedata.ext.isNotOpenBath = nil

    return { type = 2284, data = bathData, isNotOpen = isNotOpen}
end
--手动开始洗澡
function UIGangHandOpenBathCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2285, "UIGangHandOpenBathCallBack")
    return 1,2285,nil
end

function NetGangHandOpenBathCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2285, "NetGangHandOpenBathCallBack")

    local Gang2SBathData = combmessages_pb.CombMessages()
    Gang2SBathData:ParseFromString(fd.rbuf)

    local bathData = {
        feastPersonNum = 0,
        feastTime = 0,
        myFeastTime = 0,
        feastPlayers = {},
        onlineNum = 0,
        feastRoomid = gamedata.ext.bathroomid,
        openBathNum = 0,
        bathStatus = 0,
        myStatus = 0,
        -- rewardTimeNum = 0,
        curDayTimeNum = 0,
        curReward = {},
    }
    for k,v in ipairs(Gang2SBathData.messages) do
        if v.id == 1 then
            local bathinfo = ids_pb.Ids()
            bathinfo:ParseFromString(v.data)

            bathData.openBathNum = bathinfo.ids[1]
            bathData.feastPersonNum = bathinfo.ids[2]
            bathData.bathStatus = bathinfo.ids[3]
            bathData.feastTime = bathinfo.ids[4]
            bathData.myStatus = bathinfo.ids[5]
            bathData.myFeastTime = bathinfo.ids[6]--玩家活动奖励时间
            -- bathData.rewardTimeNum = bathinfo.ids[7]--获得发起奖励的秒数
            bathData.curDayTimeNum = bathinfo.ids[7]--当日已蹭秒
            bathData.onlineNum = bathinfo.ids[8]
        end
        if v.id == 2 then
            local playersData = players_pb.Players()
            playersData:ParseFromString(v.data)        
            bathData.feastPlayers = gamedata:players(playersData.players)
        end
        if v.id == 3 then
            local rewardinfo = ids_pb.Ids()
            rewardinfo:ParseFromString(v.data)
            local idx = 1
            for i=1,#rewardinfo.ids,2 do
                local tempdata = {
                    cid = rewardinfo.ids[i],
                    num = rewardinfo.ids[i+1]
                }
                bathData.curReward[idx] = tempdata
                idx = idx+1
            end  
        end
    end
    --参加时间
    bathData.myFeastTime = (gamedata:time())-bathData.myFeastTime
    
    return { type = 2285, data = bathData}
end
--洗澡接龙
function UIGangBathAgainCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2286, "UIGangBathAgainCallBack")
    local createBath = ids_pb.Ids()
    table.insert(createBath.ids, uireq.gold or 0)
    gamedata.ext.bathprop = uireq.useProp

    if uireq.gold and uireq.gold ~= 0 then
        if gamedata.cache.role.gold < uireq.gold then
            return  0, 503, {type = 503, msgtype = "shortgold"}
        end
        gamedata.ext.GangCreateJoinBath_gold = uireq.gold
    end

    return 1,2286,createBath:SerializeToString()
end

function NetGangBathAgainCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2286, "NetGangBathAgainCallBack")

    local Gang2SBathData = combmessages_pb.CombMessages()
    Gang2SBathData:ParseFromString(fd.rbuf)

    local bathData = {
        feastPersonNum = 0,
        feastTime = 0,
        myFeastTime = 0,
        feastPlayers = {},
        onlineNum = 0,
        feastRoomid = gamedata.ext.bathroomid,
        openBathNum = 0,
        bathStatus = 0,
        myStatus = 0,
        -- rewardTimeNum = 0,
        curDayTimeNum = 0,
        curReward = {},
    }
    for k,v in ipairs(Gang2SBathData.messages) do
        if v.id == 1 then
            local bathinfo = ids_pb.Ids()
            bathinfo:ParseFromString(v.data)

            bathData.openBathNum = bathinfo.ids[1]
            bathData.feastPersonNum = bathinfo.ids[2]
            bathData.bathStatus = bathinfo.ids[3]
            bathData.feastTime = bathinfo.ids[4]
            bathData.myStatus = bathinfo.ids[5]
            bathData.myFeastTime = bathinfo.ids[6]--玩家活动奖励时间
            -- bathData.rewardTimeNum = bathinfo.ids[7]--获得发起奖励的秒数
            bathData.curDayTimeNum = bathinfo.ids[7]--当日已蹭秒
            bathData.onlineNum = bathinfo.ids[8]

        end
        if v.id == 2 then
            local playersData = players_pb.Players()
            playersData:ParseFromString(v.data)        
            bathData.feastPlayers = gamedata:players(playersData.players)
        end
        if v.id == 3 then
            local rewardinfo = ids_pb.Ids()
            rewardinfo:ParseFromString(v.data)
            local idx = 1
            for i=1,#rewardinfo.ids,2 do
                local tempdata = {
                    cid = rewardinfo.ids[i],
                    num = rewardinfo.ids[i+1]
                }
                bathData.curReward[idx] = tempdata
                idx = idx+1
            end  
        end
    end
    --参加时间
    bathData.myFeastTime = (gamedata:time())-bathData.myFeastTime

    if gamedata.ext.bathprop and gamedata.ext.bathprop.num > 0 then
        gamedata.ext.bathprop.num = -gamedata.ext.bathprop.num
        gamedata:updateprops(gamedata.ext.bathprop)
    end

    if gamedata.ext.GangCreateJoinBath_gold and gamedata.ext.GangCreateJoinBath_gold > 0 then
        gamedata:updateRoleGold(0 - gamedata.ext.GangCreateJoinBath_gold ,"举办公会篝火",1)
        gamedata.ext.GangCreateJoinBath_gold = nil
    end
    
    return { type = 2286, data = bathData}
end
--切出澡堂
function UIGangBackBathCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2287, "UIGangBackBathCallBack")
    return 1,2287,nil
end

function NetGangBackBathCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2287, "NetGangBackBathCallBack")
    local gangbath = ids_pb.Ids()
    gangbath:ParseFromString(fd.rbuf)
    local backResult = gangbath.ids[1]
    
    return { type = 2287, backresult = backResult}
end


----------------------公会盛宴---------------------------------------
function UIGangFeastCheckCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2271, "UIGangFeastCheckCallBack")
   
    return 1,2271,nil
end

function NetGangFeastCheckCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2271, "NetGangFeastCheckCallBack")

    local gangFeastRoomInfo = ids_pb.Ids()
    gangFeastRoomInfo:ParseFromString(fd.rbuf)

    local feastRoomInfo = {
        openCount = gangFeastRoomInfo.ids[1],
        joinType = gangFeastRoomInfo.ids[2],
        normalRoom = {
            roomStatus = gangFeastRoomInfo.ids[3],
            doingStatus = gangFeastRoomInfo.ids[4], --1准备 2进行中
            roomTime = gangFeastRoomInfo.ids[5],
            roomPersonNum = gangFeastRoomInfo.ids[6],
        },
        highRoom = {
            roomStatus = gangFeastRoomInfo.ids[7],
            doingStatus = gangFeastRoomInfo.ids[8],
            roomTime = gangFeastRoomInfo.ids[9],
            roomPersonNum = gangFeastRoomInfo.ids[10],
        },
        superRoom = {
            roomStatus = gangFeastRoomInfo.ids[11],
            doingStatus = gangFeastRoomInfo.ids[12],
            roomTime = gangFeastRoomInfo.ids[13],
            roomPersonNum = gangFeastRoomInfo.ids[14],
        },
        ischange = gangFeastRoomInfo.ids[15] or 0,
    }
    return { type = 2271, data = feastRoomInfo}

end
--创建或加入盛宴
function UIGangCreateJoinFeastCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2272, "UIGangCreateJoinFeastCallBack")
    local createFeast = ids_pb.Ids()
    table.insert(createFeast.ids,uireq.roomid)
    table.insert(createFeast.ids,uireq.controltype)
    table.insert(createFeast.ids, uireq.gold or 0)
    gamedata.ext.feastprop = uireq.useProp
    gamedata.ext.feaststatus = uireq.controltype
    gamedata.ext.feastroomid = uireq.roomid

    if uireq.gold and uireq.gold ~= 0 then
        if gamedata.cache.role.gold < uireq.gold then
            return  0, 503, {type = 503, msgtype = "shortgold"}
        end
        gamedata.ext.GangCreateJoinFeast_gold = uireq.gold
    end

    return 1,2272,createFeast:SerializeToString()
end

function NetGangCreateJoinFeastCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2272, "NetGangCreateJoinFeastCallBack")

    local Gang2SFeastData = combmessages_pb.CombMessages()
    Gang2SFeastData:ParseFromString(fd.rbuf)

    local feastData = {
        feastPersonNum = 0,
        feastTime = 0,
        myFeastTime = 0,
        feastPlayers = {},
        onlineNum = 0,
        feastRoomid = gamedata.ext.feastroomid,
        openFeastNum = 0,
        feastStatus = 0,
        myStatus = 0,
        -- rewardTimeNum = 0,
        curDayTimeNum = 0,
        curReward = {},
    }
    for k,v in ipairs(Gang2SFeastData.messages) do
        if v.id == 1 then
            local feastinfo = ids_pb.Ids()
            feastinfo:ParseFromString(v.data)
            feastData.openFeastNum = feastinfo.ids[1]
            feastData.feastPersonNum = feastinfo.ids[2]
            feastData.feastStatus = feastinfo.ids[3]
            feastData.feastTime = feastinfo.ids[4]
            feastData.myStatus = feastinfo.ids[5]
            feastData.myFeastTime = feastinfo.ids[6]--上次玩家活动奖励结算时间
            -- feastData.rewardTimeNum = feastinfo.ids[7]--获得发起奖励的秒数
            feastData.curDayTimeNum = feastinfo.ids[7]--当日已蹭秒
            feastData.onlineNum = feastinfo.ids[8]
        end
        if v.id == 2 then
            local playersData = players_pb.Players()
            playersData:ParseFromString(v.data)        
            feastData.feastPlayers = gamedata:players(playersData.players)
        end
        if v.id == 3 then
            local rewardinfo = ids_pb.Ids()
            rewardinfo:ParseFromString(v.data)
            local idx = 1
            for i=1,#rewardinfo.ids,2 do
                local tempdata = {
                    cid = rewardinfo.ids[i],
                    num = rewardinfo.ids[i+1]
                }
                feastData.curReward[idx] = tempdata
                idx = idx+1
            end
        end
        
    end
    --参加宴会时间
    if feastData.myFeastTime > 0 then
        feastData.myFeastTime = (gamedata:time())-feastData.myFeastTime
    end

    if gamedata.ext.feaststatus == 2 and gamedata.ext.feastprop then
        gamedata.ext.feastprop.num = -gamedata.ext.feastprop.num
        gamedata:updateprops(gamedata.ext.feastprop)
    end

    if gamedata.ext.GangCreateJoinFeast_gold and gamedata.ext.GangCreateJoinFeast_gold > 0 then
        gamedata:updateRoleGold(0 - gamedata.ext.GangCreateJoinFeast_gold ,"举办公会盛宴",1)
        gamedata.ext.GangCreateJoinFeast_gold = nil
    end
    
    return { type = 2272, data = feastData}

end

--领取盛宴奖励
function UIGangGetFeastRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2273, "UIGangGetFeastRewardCallBack")
    gamedata.ext.feastbei = uireq.beinum
    gamedata.ext.roomid = uireq.roomid
    gamedata.ext.personNum = uireq.personnum
    return 1,2273,nil
end

function NetGangGetFeastRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2273, "NetGangGetFeastRewardCallBack")

    local  getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)
    
    return { type = 2273, reward = gamedata:SomethingProcess(getData),beinum = gamedata.ext.feastbei, roomid = gamedata.ext.roomid, personNum = gamedata.ext.personNum}
end

--刷新房间数据
function UIGangRefreshFeastCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2274, "UIGangRefreshFeastCallBack")
    gamedata.ext.feastroomid = uireq.roomid
    gamedata.ext.isNotOpenFeast = uireq.isNotOpen or false
    return 1,2274,nil
end

function NetGangRefreshFeastCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2274, "NetGangRefreshFeastCallBack")

    local Gang2SFeastData = combmessages_pb.CombMessages()
    Gang2SFeastData:ParseFromString(fd.rbuf)

    local feastData = {
        feastPersonNum = 0,
        feastTime = 0,
        myFeastTime = 0,
        onlineNum = 0,
        feastPlayers = {},
        openFeastNum = 0,
        feastStatus = 0,--1准备 2进行
        myStatus = 0,--1接龙或举办 2蹭
        -- rewardTimeNum = 0,
        curDayTimeNum = 0,
        curReward = {},
    }
    if gamedata.ext.feastroomid and gamedata.ext.feastroomid > 0 then
        feastData.feastRoomid = gamedata.ext.feastroomid
    end

    for k,v in ipairs(Gang2SFeastData.messages) do
        if v.id == 1 then
            local feastinfo = ids_pb.Ids()
            feastinfo:ParseFromString(v.data)
            feastData.openFeastNum = feastinfo.ids[1]
            feastData.feastPersonNum = feastinfo.ids[2]
            feastData.feastStatus = feastinfo.ids[3]
            feastData.feastTime = feastinfo.ids[4]
            feastData.myStatus = feastinfo.ids[5]
            feastData.myFeastTime = feastinfo.ids[6]--玩家活动奖励时间
            -- feastData.rewardTimeNum = feastinfo.ids[7]--获得发起奖励的秒数
            feastData.curDayTimeNum = feastinfo.ids[7]--当日已蹭秒
            feastData.onlineNum = feastinfo.ids[8]
        end
        if v.id == 2 then
            local playersData = players_pb.Players()
            playersData:ParseFromString(v.data)        
            feastData.feastPlayers = gamedata:players(playersData.players)
        end
        if v.id == 3 then
            local rewardinfo = ids_pb.Ids()
            rewardinfo:ParseFromString(v.data)
            local idx = 1
            for i=1,#rewardinfo.ids,2 do
                local tempdata = {
                    cid = rewardinfo.ids[i],
                    num = rewardinfo.ids[i+1]
                }
                feastData.curReward[idx] = tempdata
                idx = idx+1
            end
        end
    end
        
    --参加宴会时间
    -- print("=======参加宴会时间============"..feastData.myFeastTime)
    if feastData.myFeastTime > 0 then
        feastData.myFeastTime = (gamedata:time())-feastData.myFeastTime
    end
    
    return { type = 2274, data = feastData}
end
--手动开始盛宴
function UIGangHandOpenFeastCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2275, "UIGangHandOpenFeastCallBack")
    return 1,2275,nil
end

function NetGangHandOpenFeastCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2275, "NetGangHandOpenFeastCallBack")

    local Gang2SFeastData = combmessages_pb.CombMessages()
    Gang2SFeastData:ParseFromString(fd.rbuf)

    local feastData = {
        feastPersonNum = 0,
        feastTime = 0,
        myFeastTime = 0,
        onlineNum = 0,
        feastPlayers = {},
        openFeastNum = 0,
        feastStatus = 0,--1准备 2进行
        myStatus = 0,--1接龙或举办 2蹭
        -- rewardTimeNum = 0,
        curDayTimeNum = 0,
        curReward = {},
    }
    if gamedata.ext.feastroomid and gamedata.ext.feastroomid > 0 then
        feastData.feastRoomid = gamedata.ext.feastroomid
    end

    for k,v in ipairs(Gang2SFeastData.messages) do
        if v.id == 1 then
            local feastinfo = ids_pb.Ids()
            feastinfo:ParseFromString(v.data)
            feastData.openFeastNum = feastinfo.ids[1]
            feastData.feastPersonNum = feastinfo.ids[2]
            feastData.feastStatus = feastinfo.ids[3]
            feastData.feastTime = feastinfo.ids[4]
            feastData.myStatus = feastinfo.ids[5]
            feastData.myFeastTime = feastinfo.ids[6]--玩家活动奖励时间
            -- feastData.rewardTimeNum = feastinfo.ids[7]--获得发起奖励的秒数
            feastData.curDayTimeNum = feastinfo.ids[7]--当日已蹭秒
            feastData.onlineNum = feastinfo.ids[8]
        end
        if v.id == 2 then
            local playersData = players_pb.Players()
            playersData:ParseFromString(v.data)        
            feastData.feastPlayers = gamedata:players(playersData.players)
        end
        if v.id == 3 then
            local rewardinfo = ids_pb.Ids()
            rewardinfo:ParseFromString(v.data)
            local idx = 1
            for i=1,#rewardinfo.ids,2 do
                local tempdata = {
                    cid = rewardinfo.ids[i],
                    num = rewardinfo.ids[i+1]
                }
                feastData.curReward[idx] = tempdata
                idx = idx+1
            end
        end
    end
        
    --参加宴会时间
    if feastData.myFeastTime > 0 then
        feastData.myFeastTime = (gamedata:time())-feastData.myFeastTime
    end
    
    local isNotOpen = gamedata.ext.isNotOpenFeast
    gamedata.ext.isNotOpenFeast = nil
    
    return { type = 2274, data = feastData, isNotOpen = isNotOpen}
end
--盛宴接龙
function UIGangFeastAgainCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2276, "UIGangFeastAgainCallBack")
    
    local datainfo = ids_pb.Ids()
    table.insert(datainfo.ids, uireq.gold or 0)
    gamedata.ext.feastprop = uireq.useProp

    if uireq.gold and uireq.gold ~= 0 then
        if gamedata.cache.role.gold < uireq.gold then
            return  0, 503, {type = 503, msgtype = "shortgold"}
        end
        gamedata.ext.GangCreateJoinFeast_gold = uireq.gold
    end

    return 1,2276,datainfo:SerializeToString()
end

function NetGangFeastAgainCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2276, "NetGangFeastAgainCallBack")

    local Gang2SFeastData = combmessages_pb.CombMessages()
    Gang2SFeastData:ParseFromString(fd.rbuf)

    local feastData = {
        feastPersonNum = 0,
        feastTime = 0,
        myFeastTime = 0,
        onlineNum = 0,
        feastPlayers = {},
        openFeastNum = 0,
        feastStatus = 0,--1准备 2进行
        myStatus = 0,--1接龙或举办 2蹭
        -- rewardTimeNum = 0,
        curDayTimeNum = 0,
        curReward = {},
    }
    if gamedata.ext.feastroomid and gamedata.ext.feastroomid > 0 then
        feastData.feastRoomid = gamedata.ext.feastroomid
    end

    for k,v in ipairs(Gang2SFeastData.messages) do
        if v.id == 1 then
            local feastinfo = ids_pb.Ids()
            feastinfo:ParseFromString(v.data)
            feastData.openFeastNum = feastinfo.ids[1]
            feastData.feastPersonNum = feastinfo.ids[2]
            feastData.feastStatus = feastinfo.ids[3]
            feastData.feastTime = feastinfo.ids[4]
            feastData.myStatus = feastinfo.ids[5]
            feastData.myFeastTime = feastinfo.ids[6]--玩家活动奖励时间
            -- feastData.rewardTimeNum = feastinfo.ids[7]--获得发起奖励的秒数
            feastData.curDayTimeNum = feastinfo.ids[7]--当日已蹭秒
            feastData.onlineNum = feastinfo.ids[8]
        end
        if v.id == 2 then
            local playersData = players_pb.Players()
            playersData:ParseFromString(v.data)        
            feastData.feastPlayers = gamedata:players(playersData.players)
        end
        if v.id == 3 then
            local rewardinfo = ids_pb.Ids()
            rewardinfo:ParseFromString(v.data)
            local idx = 1
            for i=1,#rewardinfo.ids,2 do
                local tempdata = {
                    cid = rewardinfo.ids[i],
                    num = rewardinfo.ids[i+1]
                }
                feastData.curReward[idx] = tempdata
                idx = idx+1
            end
        end
    end
        
    --参加宴会时间
    if feastData.myFeastTime > 0 then
        feastData.myFeastTime = (gamedata:time())-feastData.myFeastTime
    end

    if gamedata.ext.feastprop and gamedata.ext.feastprop.num > 0 then
        gamedata.ext.feastprop.num = -gamedata.ext.feastprop.num
        gamedata:updateprops(gamedata.ext.feastprop)
    end

    if gamedata.ext.GangCreateJoinFeast_gold and gamedata.ext.GangCreateJoinFeast_gold > 0 then
        gamedata:updateRoleGold(0 - gamedata.ext.GangCreateJoinFeast_gold ,"举办公会盛宴",1)
        gamedata.ext.GangCreateJoinFeast_gold = nil
    end
    
    return { type = 2276, data = feastData}
end

--切出盛宴
function UIGangBackFeastCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2277, "UIGangBackFeastCallBack")
    return 1,2277,nil
end

function NetGangBackFeastCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2277, "NetGangBackFeastCallBack")
    local gangfeast = ids_pb.Ids()
    gangfeast:ParseFromString(fd.rbuf)
    local backResult = gangfeast.ids[1]
    
    return { type = 2277, backresult = backResult}
end

--盛宴转换经验丹
function UIGangExpChangeFeastCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2278, "GangExpChangeFeast")
    local ids = ids_pb.Ids()
    table.insert(ids.ids,uireq.method)
    gamedata.ext.ExpChangeType = uireq.method
    return 1,2278,ids:SerializeToString()
end

function NetGangExpChangeFeastCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2278, "GangExpChangeFeast")
    return { type = 2278,method = gamedata.ext.ExpChangeType}
end
 �w 