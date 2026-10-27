--
-- Created by IntelliJ IDEA.
-- User: jutian
-- Date: 15/7/10
-- Time: 下午2:33
-- To change this template use File | Settings | File Templates.
--

local params_pb = require"params_pb"


function NetGlobalParamCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 999, "globalparam")
    local params = params_pb.ParamS()
    params:ParseFromString(fd.rbuf)
    local acc = params.params[1].i
    local game = params.params[2].i
    local rid  = params.params[3].i
    local channel =  params.params[4].s

    gamedata.cache.role.part_rank = params.params[5].i or 0
    gamedata.cache.role.part_point = params.params[6].i or 0

    return { type = 999, acc_id = acc, game_id = game, role_id = rid, channel = channel}
end