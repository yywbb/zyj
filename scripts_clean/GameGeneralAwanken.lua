--武将觉醒
--zhangzhixin

local ids_pb = require("ids_pb")
local generals_pb = require("generals_pb")

function UIGeneralAwakenCallBack(uireq)   
    cclog("NET type:%d cmd:%s recv response from UI", 1025, "UIGeneralAwakenCallBack")
    local ids = ids_pb.Ids()
    table.insert(ids.ids, uireq.iid)
    gamedata.ext.awakeniid = uireq.iid
    gamedata.ext.awakenMaterials = uireq.materials 
    gamedata.ext.awakenGeneralfragments = uireq.generalfragments
    return 1, 1025, ids:SerializeToString()
end


function NetGeneralAwakenCallBack(fd)
    cclog("NET type:%d cmd:%s recv request from gameserver", 1025, "GeneralBreak")
    local info = generals_pb.Generals()
    info:ParseFromString(fd.rbuf)
    gamedata:Generals(info.generals)
    printT(gamedata.ext.awakenMaterials)
    if gamedata.ext.awakenMaterials["1"].str == "1001" then
        gamedata:updateRoleGold(0-tonumber(gamedata.ext.awakenMaterials["1"].num),"觉醒消耗",1)
    else
        gamedata:updateRoleCoin(0-tonumber(gamedata.ext.awakenMaterials["1"].num),"觉醒消耗",1)
    end  
    for i = 2,table.getTableLength(gamedata.ext.awakenMaterials) do
        gamedata:updateprops({cid = tonumber(gamedata.ext.awakenMaterials[tostring(i)].str),num = -gamedata.ext.awakenMaterials[tostring(i)].num})
    end
    if next(gamedata.ext.awakenGeneralfragments)  then
        gamedata:updategeneralfragmentbynum({cid = gamedata.ext.awakenGeneralfragments.id, num = 0-gamedata.ext.awakenGeneralfragments.num })
    end
    local iid = gamedata.ext.awakeniid

    return {type= 1025, general = gamedata.cache.generals[iid] or {}}
end


function UIProtagonistAwakenCallBack(uireq)   
    cclog("NET type:%d cmd:%s recv response from UI", 1058, "ProtagonistAwakenCallBack")
    printT(uireq.consume,"protagonistAwakenConsume")
    gamedata.ext.protagonistAwakenConsume = uireq.consume 
    return 1, 1058, nil
end


function NetProtagonistAwakenCallBack(fd)
    cclog("NET type:%d cmd:%s recv request from gameserver", 1058, "ProtagonistAwakenCallBack")
    local info = generals_pb.Generals()
    info:ParseFromString(fd.rbuf)
    gamedata:Generals(info.generals)

    for k,v in pairs(gamedata.ext.protagonistAwakenConsume) do
        gamedata:updateStaff({cid = v.cid,num = -v.num})
    end

    return {type= 1058, protagonist = gamedata.cache.protagonist}
end