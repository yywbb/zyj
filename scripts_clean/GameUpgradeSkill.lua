--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-10-11
-- Time: 下午3:40
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
function UIUpgradeSkillCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1008, "UpgradeSkill")
    local UpgradeSkillData = ids_pb.Ids()
    for k,v in pairs(uireq.ids) do
        table.insert(UpgradeSkillData.ids, v)
    end

    gamedata.ext.skillPropsXnum =  uireq.xnum
    gamedata.ext.skillUpGeneral =  uireq.generaliid

    return 1, 1008, UpgradeSkillData:SerializeToString()
end

local generals_pb = require("generals_pb")
function NetUpgradeSkillCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1008, "UpgradeSkill")
    local info = generals_pb.Generals()
    info:ParseFromString(fd.rbuf)

    gamedata:Generals(info.generals)

    gamedata:updateprops({cid = 20046, num = 0-gamedata.ext.skillPropsXnum})

    return {type= 1008, general = gamedata.cache.generals[gamedata.ext.skillUpGeneral]}
end