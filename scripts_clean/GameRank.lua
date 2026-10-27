--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/21
-- Time: 14:40
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local players_pb = require("players_pb")

function UIRankMydataCallBack( uireq )
    local mydata = {
        rid = gamedata.cache.role.id,
        showdata = 0,
        showdata2 = 0,
        numext = "",
    }
    if uireq.method == 1 then
        mydata.showdata = gamedata.cache.role.level
        mydata.numext = gamedata.cache.role.power
    elseif uireq.method == 2 then
        mydata.showdata = gamedata.cache.role.power
        mydata.numext = gamedata.cache.role.level
    elseif uireq.method == 3 then
    elseif uireq.method == 4 then
    elseif uireq.method == 5 then
        mydata.showdata = gamedata.cache.wing.stagenum or 0
        mydata.showdata2 = gamedata.cache.wing.starnum or 0
        mydata.numext = gamedata.cache.role.level
    elseif uireq.method == 6 then
        for k,v in pairs(gamedata.cache.copy) do
            for km,vm in pairs(v.points) do
                mydata.showdata = mydata.showdata + vm.star
            end
        end
        mydata.numext = gamedata.cache.role.level
    elseif uireq.method== 7 then
        local sid = 0
        local alllevel = 0
        mydata.showdata = 0
        for k,v in pairs(gamedata.cache.safemask) do
            if mydata.showdata <= v.level then
                mydata.showdata = v.level
                sid = v.sid
            end
            alllevel = alllevel+v.level
        end
        mydata.showdata = alllevel
        if sid ~= 0 and gamedata.cache.slots[sid] then
            local generaliid = gamedata.cache.slots[sid].general 
            if gamedata.cache.generals[generaliid] then
                local generalcid = gamedata.cache.generals[generaliid].cid
                mydata.numext = gamedata.config.general[tostring(generalcid)].name
            else
                mydata.numext = "主角"
            end
        else
            mydata.numext = "--"
        end
    elseif uireq.method== 8 then
        for k,v in pairs(gamedata.cache.generals) do
            if mydata.showdata < v.power then
                mydata.showdata = v.power
                mydata.numext = gamedata.config.general[tostring(v.cid)].name
            end
        end      
    elseif uireq.method== 9 then
        mydata.showdata = gamedata.cache.vip.rmb or 0
        mydata.numext = gamedata.cache.role.level
    elseif uireq.method== 10 then
        mydata.showdata = gamedata.cache.gang2status.level or "--"
        mydata.numext = gamedata.cache.gang2status.name or "--"
    elseif uireq.method== 19 then
        mydata.showdata = gamedata.cache.role.g_power
        mydata.numext = gamedata.cache.role.level
    end
    

    return 0,35001,{type=35001,mydata = mydata}
end


function UIRankQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3500, "RankQuery")
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.method or 1)
    table.insert(idsData.ids, uireq.pos or 1)
    table.insert(idsData.ids, uireq.num or 50)


    gamedata.ext.rankquery = {method = uireq.method or 1, pos = uireq.pos or 1, num = uireq.num or 50,activityRankId = uireq.activityRankId}

    return 1, 3500, idsData:SerializeToString()
end

function NetRankQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3500, "RankQuery")

    local players = {}
    if gamedata.ext.rankquery.method == 10 then
        local Gangs2Data = combmessages_pb.CombMessages()
        Gangs2Data:ParseFromString(fd.rbuf)
        
        for k,v in ipairs(Gangs2Data.messages) do
            local params = params_pb.ParamS()
            params:ParseFromString(v.data)
            local gang = gamedata:Gang2Data(params.params)
            table.insert(players, gang )
        end
    else
        local playersData = players_pb.Players()
        playersData:ParseFromString(fd.rbuf)        
        players=gamedata:players(playersData.players)
    end


    return { type = 3500, method = gamedata.ext.rankquery.method or 1, players = players ,activityRankId = gamedata.ext.rankquery.activityRankId}

end

--冲榜活动到期后 排行查询
function UIOldRankQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3503, "RankQuery")
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.method or 1)
    table.insert(idsData.ids, uireq.pos or 1)
    table.insert(idsData.ids, uireq.num or 50)


    gamedata.ext.rankquery = {method = uireq.method or 1, pos = uireq.pos or 1, num = uireq.num or 50,activityRankId = uireq.activityRankId}

    return 1, 3503, idsData:SerializeToString()
end

function NetOldRankQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3503, "RankQuery")

    local players = {}
    if gamedata.ext.rankquery.method == 10 then
        local Gangs2Data = combmessages_pb.CombMessages()
        Gangs2Data:ParseFromString(fd.rbuf)
        
        for k,v in ipairs(Gangs2Data.messages) do
            local params = params_pb.ParamS()
            params:ParseFromString(v.data)
            local gang = gamedata:Gang2Data(params.params)
            table.insert(players, gang )
        end
    else
        local playersData = players_pb.Players()
        playersData:ParseFromString(fd.rbuf)        
        players=gamedata:players(playersData.players)
    end


    return { type = 3503, method = gamedata.ext.rankquery.method or 1, players = players ,activityRankId = gamedata.ext.rankquery.activityRankId}

end



function NetRankChangeCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3501, "RankChange")

    return {type =3501}
end
