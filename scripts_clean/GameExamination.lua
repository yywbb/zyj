--
-- Author: songyibo
-- Date: 2019-03-21 11:15:41
--

local ids_pb = require("ids_pb")
local combmessages_pb = require("combmessages_pb")
local battleresult_pb = require("battleresult_pb")
local somethings_pb = require("somethings_pb")
local players_pb = require("players_pb")



function UIExaminationStatusCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 7002, "ExaminationStatusQuery")
    return 1, 7002, nil
end


function NetExaminationStatusCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7002, "ExaminationStatusQuery")

     local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local t = {
        type = 7002,
    }
    local data = {}
    local nums = #ids.ids/8
    print("NetExaminationStatusCallBack nums",nums)


    for i,v in ipairs(ids.ids) do
        print(i,v)
    end


    for i = 1,nums do
        data[tostring(i)] = {}
        data[tostring(i)].kstype = ids.ids[(i-1)*8+1] or 0
        data[tostring(i)].status = ids.ids[(i-1)*8+2] or 0
        data[tostring(i)].currentnum = ids.ids[(i-1)*8+3] or 0
        data[tostring(i)].rightnum = ids.ids[(i-1)*8+4] or 0
        data[tostring(i)].currentTimuid = ids.ids[(i-1)*8+5] or 0
        data[tostring(i)].useAlltime = math.modf( ids.ids[(i-1)*8+6] / 1000 )  or 0
        data[tostring(i)].jifen =  ids.ids[(i-1)*8+7] / 10  or 0  --math.modf( ids.ids[(i-1)*7+7] / 10 )
        data[tostring(i)].endtime =  ids.ids[(i-1)*8+8]  or 0  --math.modf( ids.ids[(i-1)*7+7] / 10 )
    end
   
    t.data = data
    t.roleid = gamedata.cache.role.id
    t.rolename = gamedata.cache.role.name
    t.rolegender = gamedata.cache.role.gender
    t.cid = gamedata.cache.role.profile
    t.iconBox = gamedata.cache.role.iconBox
    t.rolelv = gamedata.cache.role.level

    gamedata.cache.examinnation = data

    return t
end



function UIExaminationStartCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 7003, "ExaminationStart")

    local idsData = ids_pb.Ids()
    print(uireq.timuType,"UIExaminationStartCallBack")
    table.insert(idsData.ids, uireq.timuType)

    gamedata.ext.indatimu = 1
    gamedata.ext.indatimutype = uireq.timuType

    return 1, 7003, idsData:SerializeToString()

end


function NetExaminationStartCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7003, "ExaminationStart")

    local t = {
        type = 7003,
    }

     local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)

    t.timuid = Result.ids[1] or 0
    t.endtimes = math.modf( Result.ids[2] / 1000 ) or 0
    t.expnum = Result.ids[3] or 0
    t.coinnum = Result.ids[4] or 0
    t.useAlltime =  math.modf( Result.ids[5] / 1000 ) or 0
    t.jifen =   Result.ids[6] / 10  or 0
    t.currentnum = Result.ids[7] or 0
    t.rightnum = Result.ids[8] or 0

    gamedata.ext.indatimu = 0
    gamedata.ext.indatimutype = 0
    printT(t,"7003")
    return t
end


function UIExaminationEndCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 7004, "ExaminationEnd")

            -- UIRequest({type =7004, timuType = self.currenntKaoshitype, timuid = timuid, answerid = tostring(v)})

    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.timuType or 1 )
    table.insert(idsData.ids, uireq.timuid or 1)
    table.insert(idsData.ids, uireq.answerid or 1)
    table.insert(idsData.ids, uireq.timestap or 1)

    -- return 0, 7004, {type =7004, result = 0, exp = 1000, coin = 1000, useAlltime =100, jifen = 100, currentnum = 10,rightnum = 1}
    gamedata.ext.indati = 1
    gamedata.ext.timuType = uireq.timuType or 1
    gamedata.ext.timuid = uireq.timuid or 1
    gamedata.ext.answerid = uireq.answerid or 1
    gamedata.ext.timestap = uireq.timestap or 1

    return 1, 7004, idsData:SerializeToString()
end


function NetExaminationEndCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7004, "ExaminationEnd")

    local t = {
        type = 7004,
    }

    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)

    t.result = Result.ids[1] or 0
    t.expnum = Result.ids[2] or 0
    t.coinnum = Result.ids[3] or 0
    t.useAlltime = math.modf( Result.ids[4] / 1000 ) or 0
    t.jifen =  Result.ids[5] / 10  or 0
    t.currentnum = Result.ids[6] or 0
    t.rightnum = Result.ids[7] or 0

    printT(t,"7004")
    gamedata.ext.indati = 0
    gamedata.ext.timuType = 1
    gamedata.ext.timuid =  1
    gamedata.ext.answerid =  1
    gamedata.ext.timestap =  1

    return t
end


function UIExaminationPaihangbangCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 7005, "ExaminationPaihangbang")

    
     local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.ranktype or 2 )

    return 1, 7005, idsData:SerializeToString()
end


function NetExaminationPaihangbangCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7005, "ExaminationPaihangbang")
    local t = {
        type = 7005,
    }
   
    local playersData = players_pb.Players()
    playersData:ParseFromString(fd.rbuf)     

    local players=gamedata:players(playersData.players)

     printT(players,"NetExaminationPaihangbangCallBack")

     t.data = players

    return t
end


