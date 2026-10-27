--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/5/17
-- Time: 17:54
-- To change this template use File | Settings | File Templates.
--

local params_pb = require("params_pb")
local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")
local battleresult_pb = require("battleresult_pb")
local combmessages_pb = require("combmessages_pb")
require"PickBattleResultReport"

function UIUserProtagonistGameQuery(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3720, "UserProtagonistGameQuery")

    return 1, 3720, nil

end

function NetUserProtagonistGameQuery(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3720, "UserProtagonistGameQuery")
    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)
    return { type = 3720 ,_cellIndex = Result.ids[1],_nowsIndex = Result.ids[2],
                          _selfLevel = gamedata.cache.protagonist.level2,}
end

function UIUserProtagonistGameEatBeans(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3721, "UserProtagonistGameEatBeans")
    if uireq._stage then
        gamedata.ext.gamestar_stage = uireq._stage
    end
    if uireq._step then
        gamedata.ext.gamestar_step = uireq._step
    end
    if uireq._boom then
    else
    end
    local upconfig = gamedata.config.hoshimiya_jihuo[tostring(gamedata.ext.gamestar_stage)][tostring(gamedata.ext.gamestar_step+1)]
    if upconfig then
        local destNeed = gamedata.getIDandNUMs(upconfig.activation_cost)
        for k,v in pairs(destNeed) do
            if v.cid == 1000 then
                if v.num > gamedata.cache.role.coin then
                    return 0,503,{type = 503, msgtype = "shortcoin" }
                end
            end
        end
    end
    return 1, 3721, nil

end

function NetUserProtagonistGameEatBeans(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3721, "UserProtagonistGameEatBeans")
    local info = generals_pb.Generals()
    info:ParseFromString(fd.rbuf)
    gamedata:Generals(info.generals)
    if gamedata.ext.gamestar_stage and gamedata.ext.gamestar_step then
        local upconfig = gamedata.config.hoshimiya_jihuo[tostring(gamedata.ext.gamestar_stage)][tostring(gamedata.ext.gamestar_step+1)]
        local destNeed = gamedata.getIDandNUMs(upconfig.activation_cost)
        for k,v in pairs(destNeed) do
            gamedata:updateStaff({cid = v.cid,num = -v.num})
        end
        gamedata.ext.gamestar_stage = nil
        gamedata.ext.gamestar_step = nil
    end
    return { type = 3721 }
end

function UIUserProtagonistGamePopcorn(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3722, "UserProtagonistGamePopcorn")
    if uireq._stage then
        gamedata.ext.gamestar_stage = uireq._stage
    end
    local upconfig = gamedata.config.hoshimiya_break[tostring(gamedata.ext.gamestar_stage)]
    if upconfig then
        local destNeed = gamedata.getIDandNUMs(upconfig.break_cost)
        for k,v in pairs(destNeed) do
            if v.cid == 1000 then
                if v.num > gamedata.cache.role.coin then
                    return 0,503,{type = 503, msgtype = "shortcoin" }
                end
            end
        end
    end
    return 1, 3722, nil

end

function NetUserProtagonistGamePopcorn(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3722, "UserProtagonistGamePopcorn")
    local info = generals_pb.Generals()
    info:ParseFromString(fd.rbuf)
    gamedata:Generals(info.generals)
    if gamedata.ext.gamestar_stage  then
        local breakconfig = gamedata.config.hoshimiya_break[tostring(gamedata.ext.gamestar_stage)]
        local destNeed = gamedata.getIDandNUMs(breakconfig.break_cost)
        for k,v in pairs(destNeed) do
            gamedata:updateStaff({cid = v.cid,num = -v.num})
        end
        gamedata.ext.gamestar_stage = nil
    end
    -- local Result = ids_pb.Ids()
    -- Result:ParseFromString(fd.rbuf)
    return { type = 3722 }
end
