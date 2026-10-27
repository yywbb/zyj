--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/3
-- Time: 15:36
-- To change this template use File | Settings | File Templates.
--

local somethings_pb = require("somethings_pb")
local params_pb = require("params_pb")

function UIUserCDKeyExchangeCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2089, "UserCDKeyExchange")

    local cdks = params_pb.ParamS()
    local cdk = params_pb.ParamS.Param()

    cdk.s = uireq.s or ""

    table.insert(cdks.params, cdk)

    return 1, 2089, cdks:SerializeToString()
end

function NetUserCDKeyExchangeCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2089, "UserCDKeyExchange")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)


    return { type = 2089, reward = gamedata:SomethingProcess(SomeThings),}
end