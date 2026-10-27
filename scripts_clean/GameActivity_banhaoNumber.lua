
--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/26
-- Time: 下午7:10
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")

-- 查询
function UIBanHaoNumberCallBack(uireq)
    cclog("UIBanHaoNumberCallBack")
    cclog("NET type:%d cmd:%s recv request from UI", 7000, "baohaoNumber")

    return 1, 7000, nil
end

function NetBanHaoNumberQueryCallBack(fd)
    cclog("NetBanHaoNumberQueryCallBack")
    cclog("NET type:%d cmd:%s recv response from gameserver", 7000, "baohaoNumber")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)


    print("NetBanHaoNumberQueryCallBack length: "..#ids.ids)

    local mochongNumber = ids.ids[1] or 0--魔宠被动技能重置次数
    local qiankunluNumber = ids.ids[2] or 0--乾坤炉重生次数
    local lieming1 = ids.ids[3] or 0--购买元宝猎命灵石次数
    local zhaomu1 = ids.ids[4] or 0--高级招募次数
    local zhaomu2 = ids.ids[5] or 0--封神招募次数

     gamedata.cache.banhaoNumber.mochongtimes = mochongNumber
     gamedata.cache.banhaoNumber.chongshengtimes = qiankunluNumber
     gamedata.cache.banhaoNumber.liemingtimes = lieming1
     gamedata.cache.banhaoNumber.zhaomu1times = zhaomu1
     gamedata.cache.banhaoNumber.zhaomu2times = zhaomu2


    print("NetBanHaoNumberQueryCallBack mochong:"..mochongNumber.." qkl:"..qiankunluNumber.." lieming:"..lieming1.." zhaomu1:"..zhaomu1.." zhaomu2:"..zhaomu2)

    return { type = 7000, banhaotime = gamedata.cache.banhaoNumber}
end