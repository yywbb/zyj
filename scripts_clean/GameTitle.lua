--
-- Author: songyibo
-- Date: 2018-08-28 14:07:29
--
local ids_pb = require("ids_pb")

--查询
function UITitleQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6301, "TitleQuery")
    local ids = ids_pb.Ids()
    return 1, 6301, ids:SerializeToString()
end

function NetTitleQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6301, "TitleQuery")
    local TitleData = ids_pb.Ids()
    TitleData:ParseFromString(fd.rbuf)
	
	gamedata:HeadIconData(TitleData.ids,"Title")
    return { type = 6301,data = gamedata.cache.HeadIconData}
end

--使用
function UITitleUseCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6302, "TitleUse")
    local ids = ids_pb.Ids()
    
    gamedata.ext.titleUse = uireq.id
    table.insert(ids.ids, uireq.id)

    return 1, 6302, ids:SerializeToString()
end

function NetTitleUseCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6302, "TitleUse")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
	
    gamedata.cache.role.title = gamedata.ext.titleUse
	
    return { type = 6302,data = gamedata.cache.HeadIconData,curTitle = gamedata.cache.role.title}
end

--获得
function NetTitleGetCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6304, "TitleGet")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    
    gamedata:HeadIconData(ids.ids,"Title")
    local cid = ids.ids[1]

    local opt = ids.ids[#ids.ids] or 0

    return { type = 6304,opt = opt,data = gamedata.cache.HeadIconData,getTitle = {cid = cid,time = gamedata.cache.HeadIconData.title[cid]}}
end

--过期
function NetTitleLoseCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6303, "TitleQuery")
    local TitleData = ids_pb.Ids()
    TitleData:ParseFromString(fd.rbuf)

	local cid = TitleData.ids[1]
    gamedata.cache.HeadIconData.title[cid] = nil

    if gamedata.cache.role.title == cid then
        gamedata.cache.role.title = 35501
    end

    return { type = 6303,data = gamedata.cache.HeadIconData,curTitle = gamedata.cache.role.title,loseTitle = cid}
end


--查询
function UIIconBoxQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6201, "IconBoxQuery")
    local ids = ids_pb.Ids()
    return 1, 6201, ids:SerializeToString()
end

function NetIconBoxQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6201, "IconBoxQuery")
    local TitleData = ids_pb.Ids()
    TitleData:ParseFromString(fd.rbuf)
	
	gamedata:HeadIconData(TitleData.ids,"IconBox")
    return { type = 6201,data = gamedata.cache.HeadIconData}
end

--使用
function UIIconBoxUseCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6202, "IconBoxUse")
    local ids = ids_pb.Ids()
    
    gamedata.ext.iconBoxUse = uireq.id
    table.insert(ids.ids, uireq.id)
    print(gamedata.ext.iconBoxUse,"gamedata.ext.iconBoxUse")
    return 1, 6202, ids:SerializeToString()
end

function NetIconBoxUseCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6202, "IconBoxUse")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
	
    print("IconBoxUse",ids.ids[1])
    gamedata.cache.role.iconBox = gamedata.ext.iconBoxUse
    return { type = 6202,data = gamedata.cache.HeadIconData,curIconBox = gamedata.cache.role.iconBox}
end

--获得
function NetIconBoxGetCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6204, "IconBoxGet")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    
    gamedata:HeadIconData(ids.ids,"IconBox")
    local cid = ids.ids[1]
    local opt = ids.ids[#ids.ids] or 0

    return { type = 6204,opt = opt,data = gamedata.cache.HeadIconData,getIconBox = {cid = cid,time = gamedata.cache.HeadIconData.iconBox[cid]}}
end

--过期

function NetIconBoxLoseCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6203, "IconBoxLose")
    local idsData = ids_pb.Ids()
    idsData:ParseFromString(fd.rbuf)
	
    local cid = ids.ids[1]
    self.cache.HeadIconData.iconBox[cid] = nil

    if gamedata.cache.role.iconBox == cid then
        gamedata.cache.role.iconBox = 35001
    end

    return { type = 6203,data = gamedata.cache.HeadIconData,curIconBox = gamedata.cache.role.iconBox,loseIconBox = cid}
end
