--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-10-11
-- Time: 下午12:53
-- To change this template use File | Settings | File Templates.
--


local inheritconfirm_pb = require("inheritconfirm_pb")
function UIGeneralInheritConfirmCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1011, "inheritrequest")
    local inheritconfirmData = inheritconfirm_pb.InheritConfirm()
    inheritconfirmData.tid = uireq.tid
    inheritconfirmData.opt = uireq.opt

    gamedata.ext.inheritProps = uireq.tid == 1 and 20011 or 20012
    gamedata.ext.inheritgeneraliid = uireq.generaliid

    return 1, 1011, inheritconfirmData:SerializeToString()
end

local somethings_pb = require("somethings_pb")
function NetGeneralInheritConfirmCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1011, "InheritConfirm")

    local somethings = somethings_pb.SomeThings()
    somethings:ParseFromString(fd.rbuf)

    gamedata:SomethingProcess(somethings)

    gamedata:updateprops({cid = gamedata.ext.inheritProps, num = -1})

    return { type = 1011, general = gamedata.cache.generals[gamedata.ext.inheritgeneraliid], }
end