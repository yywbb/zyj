--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-18
-- Time: 下午3:15
-- To change this template use File | Settings | File Templates.
--

function UIGeneralRecruitStatusCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1400, "GeneralRecruitQuery")
    if next(gamedata.cache.generalrecruit) then
        --todo
        local recruitpropsnum = 0
        if gamedata.cache.props[20100] then
            recruitpropsnum = gamedata.cache.props[20100].num or 0
        end
        local gold = gamedata.cache.role.gold or 0

        return 0, 1400, { type = 1400, generalrecruit = gamedata.cache.generalrecruit, recruitpropsnum = recruitpropsnum, gold = gold,}
    else
        return 1, 1400, nil
    end
end

local recruitstatus_pb = require("recruitstatus_pb")
function NetGeneralRecruitStatusCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1400, "GeneralRecruitQuery")
    local recruitData = recruitstatus_pb.RecruitStatus()
    recruitData:ParseFromString(fd.rbuf)

    gamedata:Recruit(recruitData)

    local recruitpropsnum = 0
    if gamedata.cache.props[20100] then
        recruitpropsnum = gamedata.cache.props[20100].num or 0
    end
    local gold = gamedata.cache.role.gold or 0

    return { type = 1400, generalrecruit = gamedata.cache.generalrecruit, recruitpropsnum = recruitpropsnum, gold = gold,}
end