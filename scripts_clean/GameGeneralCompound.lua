--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-10-11
-- Time: 下午2:19
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
function UIGeneralCompoundCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1016, "GeneralCompound")
    local GeneralCompoundData = ids_pb.Ids()
    for k,v in pairs(uireq.ids) do
        table.insert(GeneralCompoundData.ids, v)
    end

    return 1, 1016, GeneralCompoundData:SerializeToString()
end

local generals_pb = require("generals_pb")
function NetGeneralCompoundCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1016, "GeneralCompound")

    local GeneralsData = generals_pb.Generals()
    GeneralsData:ParseFromString(fd.rbuf)


    local getGeneral = gamedata:Generals(GeneralsData.generals,true)
    --printT(getGeneral)
    local num = 0
    for k,v in pairs(gamedata.config.general_fragment) do
        if v.general ==  getGeneral[1].cid then
            num = v.num
        end
    end

    gamedata:updategeneralfragmentbynum({cid = getGeneral[1].cid, num = 0-num })

    return { type = 1016, opt = 2, gets = getGeneral} --gamedata.cache.generals, generalfragments = gamedata.cache.generalfragments }
end