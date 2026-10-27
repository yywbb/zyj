--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/1/31
-- Time: 下午5:37
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local stringcontent_pb = require("stringcontent_pb")
local result_pb = require("result_pb")
local guidequery_pb = require("guidequery_pb")
local guideexcute_pb = require("guideexcute_pb")
local protagonist_pb = require("protagonist_pb")

function UIRoleSetProfileCallBack(uireq)
    print("设置角色形象102 接收UI请求")

    local SetProfileData = ids_pb.Ids()
    table.insert(SetProfileData.ids,uireq.id)

    gamedata.ext.setprofileid = uireq.id

    return 1, 102, SetProfileData:SerializeToString()
end

function NetRoleSetProfileCallBack(fd)
    print("设置角色形象102 接收服务器返回数据")
    local result = result_pb.Result()
    result:ParseFromString(fd.rbuf)

    gamedata.cache.role.profile = gamedata.ext.setprofileid

    return { type = 102, result = result.result, profile = gamedata.cache.role.profile}
end

function UIRandomNameCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 100, "RandomName")
    local id = ids_pb.Ids()
    table.insert(id.ids,uireq.sex)

    return 1, 100, id:SerializeToString()
end

function NetRandomNameCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 100, "RandomName")

    local name = stringcontent_pb.StringContent()
    name:ParseFromString(fd.rbuf)

    return { type = 100, name = name.content}
end


function UISetNameCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 101, "SetName")
    local name = stringcontent_pb.StringContent()
    name.content = uireq.name

    gamedata.ext.isrename = uireq.isrename
    gamedata.ext.newname = uireq.name

    return 1, 101, name:SerializeToString()
end

function NetSetNameCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 101, "SetName")

    local Result = result_pb.Result()
    Result:ParseFromString(fd.rbuf)
    if gamedata.ext.isrename and (Result.result == true) then
        gamedata.cache.role.name = gamedata.ext.newname
        gamedata:updateprops({cid = 20018,num = -1})
    end

    return { type = 101, result = Result.result, isrename=gamedata.ext.isrename,newname = gamedata.ext.newname}
end

function UIInitGeneralCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 202, "InitGeneral")
    local id = ids_pb.Ids()
    table.insert(id.ids,uireq.cid)

    gamedata.ext.setnameisfirst = uireq.isfirst

    return 1, 202, id:SerializeToString()
end



function NetInitGeneralCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 202, "InitGeneral")

    local protagonist = protagonist_pb.Protagonist()
    protagonist:ParseFromString(fd.rbuf)

    gamedata:Protagonist(protagonist)

    return { type = 202, result = 1, isfirst = gamedata.ext.setnameisfirst}
end

function UIGuideQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 200, "GuideQuery")

    gamedata.ext.guideParam = uireq.param
    if next( gamedata.cache.guide) then
        return 0, 200, { type = 200, guide = gamedata.cache.guide,param = gamedata.ext.guideParam}
    else
        return 1, 200, nil
    end
end

function NetGuideQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 200, "GuideQuery")

    local guide = guidequery_pb.GuideQuery()
    guide:ParseFromString(fd.rbuf)

    gamedata:Guide(guide)
    return { type = 200, guide = gamedata.cache.guide, param = gamedata.ext.guideParam}
end


function UIGuideExcuteCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 201, "GuideExcute")
    local GuideExcute = guideexcute_pb.GuideExcute()
    GuideExcute.section = uireq.section
    GuideExcute.step = uireq.step

    return 1, 201, GuideExcute:SerializeToString()
end

function NetGuideExcuteCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 201, "GuideExcute")

    local Result = result_pb.Result()
    Result:ParseFromString(fd.rbuf)

    return { type = 201, Result = Result.Result}
end