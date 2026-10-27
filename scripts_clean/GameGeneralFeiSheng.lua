--
-- Author: songyibo
-- Date: 2019-03-17 15:13:28
--


local ids_pb = require("ids_pb")


function UIPartnerFeiShengCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 7001, "GeneralFeiSheng")
	local GeneralFeiShengData = ids_pb.Ids()
	printT(uireq,"uireq")
	gamedata.ext.feishengIid = uireq.iid
    gamedata.ext.isLead = uireq.isLead

    table.insert(GeneralFeiShengData.ids, uireq.iid)

    return 1, 7001, GeneralFeiShengData:SerializeToString()
end

function NetPartnerFeiShengCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7001, "GeneralFeiSheng")

    local GeneralsData = generals_pb.Generals()
    GeneralsData:ParseFromString(fd.rbuf)


    printT(gamedata.cache.protagonist,"protagonist")

    gamedata:Generals(GeneralsData.generals)

    local general
    local consume
    if gamedata.ext.isLead and gamedata.ext.isLead == 1 then
        general = gamedata.cache.protagonist.general
        local feishengConfig = gamedata.config.passive_soaring[tostring(general.level8)]
        consume = gamedata.getIDandNUMs(feishengConfig["consume"])
    else
        general = gamedata.cache.generals[gamedata.ext.feishengIid]
        local feishengConfig = gamedata.config.partner_soaring[tostring(general.level8)]
        local generalConfig = gamedata.config.general[tostring(gamedata.getOriginCid(general.cid))]
        local originalBasic = generalConfig.basic
        --消耗
        consume = gamedata.getIDandNUMs(feishengConfig[originalBasic.."consume"])
    end

    for i,v in ipairs(consume) do
        gamedata:updateStaff({cid = v.cid,num = -v.num})
    end


    return { type = 7001,isLead = gamedata.ext.isLead, ison = gamedata:isGeneralOn(gamedata.ext.feishengIid), general = general}
end
