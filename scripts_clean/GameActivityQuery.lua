--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-26
-- Time: 上午10:17
-- To change this template use File | Settings | File Templates.
--
local ids_pb = require("ids_pb")
local combmessages_pb = require("combmessages_pb")

local activitylevel = {}
function UIActivityQueryReponse()
    if not next(activitylevel) then
        local buildJson = gamedata.config.build
        for k,v in pairs(buildJson) do
              if v.key == "2000" and v.param1 and v.param1 ~= "" then
                  activitylevel[tonumber(v.param1)] = tonumber(v.level)
              end
        end
    end

    local status = table.copy(gamedata.cache.activitystatus)

    for k,v in pairs(status) do

        if activitylevel[v.id] and activitylevel[v.id] > gamedata.cache.role.level then
            status[k].status = 0
        end

        if v.id and tonumber(v.id) == 27 then
            if gamedata.cache.gang2status and gamedata.cache.gang2status.id and gamedata.cache.gang2status.id > 0 then

            else
                status[k].status = 0
            end
        end

    end

    return status
end

function checkActivityStatus(id)
    return  gamedata.cache.activitystatus[id] and gamedata.cache.activitystatus[id].status == 1
end

function UIActivityQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2000, "activityquery")

    gamedata.ext.activityid = uireq.param
    gamedata.ext.activitytype = uireq.page
    gamedata.ext.activitycheck = uireq.ischeck or 0
    gamedata.ext.activityPageId = uireq.pageId

    if next(gamedata.cache.activitystatus) ~= nil and not uireq.param2 then
        return 0,2000,{type=2000,status=UIActivityQueryReponse(),dailyCpActivityTimeStatus = gamedata.cache.dailyCpActivityTimeStatus, id = gamedata.ext.activityid,page = gamedata.ext.activitytype, pageId = gamedata.ext.activityPageId, ischeck = gamedata.ext.activitycheck or 0}
    else
        return 1,2000,nil
    end
end

local activityquery_pb = require"activityquery_pb"

function NetActivityQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2000, "activityquery")

    local activityQuery = combmessages_pb.CombMessages()
    activityQuery:ParseFromString(fd.rbuf)
    for k,v in ipairs(activityQuery.messages) do
       
        if v.id == 1 then
            local activityQueryResponse = activityquery_pb.ActivityQuery()
            activityQueryResponse:ParseFromString(v.data)
            gamedata:ActivityStatus(activityQueryResponse)
        elseif v.id == 2 then    
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:DailyCpActivityTimeStatus(ids.ids)
        end
    end

    return {type=2000,status=UIActivityQueryReponse(),dailyCpActivityTimeStatus = gamedata.cache.dailyCpActivityTimeStatus,  id = gamedata.ext.activityid, page = gamedata.ext.activitytype, pageId = gamedata.ext.activityPageId, ischeck = gamedata.ext.activitycheck or 0}
end


function UIActivityEverydayCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 20051, "UIActivityEverydayCallBack")

    return 0,20051,{type=20051}
end

function UIActivityIsOpenCallBack( uireq )

    local activityconfig = gamedata.config.activity_time[tostring(uireq.id)]

    if not activityconfig then
        return 0,20001,{type=20001,id=uireq.id,status = 0}
    end

    local sysid = activityconfig.systemid
    local build = gamedata.config.build[tostring(sysid)]

    if gamedata.cache.activitystatus[uireq.id] and gamedata.cache.activitystatus[uireq.id].status==1 then
        if build and build.level > gamedata.cache.role.level then
            return 0,20001,{type=20001,id=uireq.id,status = 0}
        else
            return 0,20001,{type=20001,id=uireq.id,status = 1}
        end
    else
        return 0,20001,{type=20001,id=uireq.id,status = 0}
    end

end

function UIActivityNewRankQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5601, "UIActivityPowerGrowthCallBack")

    local ids = ids_pb.Ids()
    print("uireq.rankId",uireq.rankId)
    table.insert(ids.ids, uireq.rankId or 1)
    table.insert(ids.ids, uireq.method or 1)

    myque.push(gamedata.extQueue,{rankId = uireq.rankId,ActivityRankId = uireq.activityRankId})

    return 1, 5601, ids:SerializeToString()
end

function NetActivityNewRankQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5601, "NetActivityPowerGrowthCallBack")
    
    local data = {players = {},my = {}}
    local ext = myque.pop(gamedata.extQueue)

    printT(ext,"ext")

    local rankdata = combmessages_pb.CombMessages()
    rankdata:ParseFromString(fd.rbuf)
    for k,v in ipairs(rankdata.messages) do
       
        if v.id == 1 then
            local params = params_pb.ParamS()
            params:ParseFromString(v.data)


            for i=1,#params.params do
                print(" ------  ",i,params.params[i].i,params.params[i].s)
            end

            local num = #params.params
            if ext.rankId == 5 then
                if num <= 6 then
                    num = num/2
                    for i=1,num-1 do
                        data.players[i] = {name = params.params[i*2-1].s ,score = params.params[i*2-1].i.."-"..params.params[i*2].i}
                    end
                    data.my.rank = tonumber(params.params[num*2-1].s)
                    data.my.score = params.params[num*2-1].i.."-"..params.params[num*2].i
                else
                    if num > 6 then
                        num = 3
                    end
                    --翅膀
                    for i=1,num do
                        data.players[i] = {name = params.params[i*2-1].s ,score = params.params[i*2-1].i.."-"..params.params[i*2].i}
                    end

                    data.my.rank = tonumber(params.params[7].s)
                    data.my.score = params.params[7].i.."-"..params.params[8].i
                end
            else
                if num <= 3 then
                    for i=1,num-1 do
                        data.players[i] = {name = params.params[i].s,score = params.params[i].i}
                    end
                    data.my.rank = tonumber(params.params[num].s)
                    data.my.score = params.params[num].i
                else
                    if num > 3 then
                        num = 3
                    end
                    for i=1,num do
                        data.players[i] = {name = params.params[i].s,score = params.params[i].i}
                    end
                    data.my.rank = tonumber(params.params[num+1].s)
                    data.my.score = params.params[num+1].i
                end
            end
        elseif v.id == 2 then    
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)

            data.my.p_score = ids.ids[1] or 0
        end
    end


    return {type = 5601,data = data,ActivityRankId = ext.ActivityRankId}
end

function UIActivityNewRankGetCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5602, "UIActivityPowerGrowthX1CallBack")
    return 1,5602,nil
end

function NetActivityNewRankGetCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5602, "NetActivityPowerGrowthX1CallBack")
    
    local info = ids_pb.Ids()
    info:ParseFromString(fd.rbuf)

    return {type = 5602,power = info.ids[1] or 0}
end

function UIActivityPowerGrowthX2CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5603, "UIActivityPowerGrowthX2CallBack")
    return 1,5603,nil
end

function NetActivityPowerGrowthX2CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5603, "NetActivityPowerGrowthX2CallBack")
    
    local info = ids_pb.Ids()
    info:ParseFromString(fd.rbuf)

    return {type = 5603,power = info.ids[1] or 0}
end
