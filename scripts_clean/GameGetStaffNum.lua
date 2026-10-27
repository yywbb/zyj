--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-18
-- Time: 下午3:16
-- To change this template use File | Settings | File Templates.
--
function UIGetStaffNumCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 12002, "propqueryBYID")
    print("UIGetStaffNumCallback=")
    printT(uireq)
    local numdata = gamedata.getStaffNum(uireq.id)
    print("numdata.next:")
    printT(numdata)

    return 0, 12002, { type = 12002, cid = numdata.cid, num = numdata.num, neednum = numdata.neednum}
end