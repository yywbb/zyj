--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/4
-- Time: 10:16
-- To change this template use File | Settings | File Templates.
--

local params_pb = require("params_pb")
local result_pb = require("result_pb")

function UIUserSystemMailCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1030, "UserSystemMail")

    local mails = params_pb.ParamS()
    local mail = params_pb.ParamS.Param()

    mail.s = uireq.s or ""

    table.insert(mails.params, mail)

    return 1, 1030, mails:SerializeToString()
end

function NetUserSystemMailCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1030, "UserSystemMail")

    local result = result_pb.Result();
    result:ParseFromString(fd.rbuf)
    return { type = 1030, result = result.result }

end