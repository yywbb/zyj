local ids_pb = require("ids_pb")

function UIGodSoulTempleQueryCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 7030, "UIGodSoulTempleQueryCallback")

    if uireq.id then
        local _ids = ids_pb.Ids()
        table.insert(_ids.ids, uireq.id)
        gamedata.ext.godSoulTempleId = uireq.id
        gamedata.ext.godSoulTemplePageName = uireq.pageName
        return 1, 7030, _ids:SerializeToString()
    else
        return 1, 7030, nil
    end
end

function NetGodSoulTempleQueryCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7030, "NetGodSoulTempleQueryCallback")

    local _ids = ids_pb.Ids()
    _ids:ParseFromString(fd.rbuf)
    local _godSoulTemple = {}

    local cuishen_materials = {}
    local lianhun_materials = {}
    lianhun_materials.generalfragments = gamedata.cache.generalfragments

    if gamedata.ext.godSoulTempleId then
        _godSoulTemple.soulLevel = _ids.ids[1] or 0
        _godSoulTemple.genralsLevel2ByBasic = _ids.ids[2] or 0
        _godSoulTemple.soulStatus = _ids.ids[3] or 0
        _godSoulTemple.soulStar = _ids.ids[4] or 0
        _godSoulTemple.soulExp = _ids.ids[5] or 0
        _godSoulTemple.godStatus = _ids.ids[6] or 0
        _godSoulTemple.godStar = _ids.ids[7] or 0
        _godSoulTemple.godExp = _ids.ids[8] or 0

        cuishen_materials.props = {}
        print("gamedata.ext.godSoulTempleId",gamedata.ext.godSoulTempleId)

        if gamedata.config.shenhundian_cuishenxiaohao[tostring(gamedata.ext.godSoulTempleId)] then
            for k,v in pairs(gamedata.config.shenhundian_cuishenxiaohao[tostring(gamedata.ext.godSoulTempleId)]) do
                cuishen_materials.props[v.consume] = gamedata:getPropNum(v.consume)
            end
        end
        gamedata.ext.godSoulTempleId = nil
    else
        _godSoulTemple["18"] = {}
        _godSoulTemple["18"].soulLevel = _ids.ids[1] or 0
        _godSoulTemple["18"].genralsLevel2ByBasic = _ids.ids[2] or 0

        _godSoulTemple["20"] = {}
        _godSoulTemple["20"].soulLevel = _ids.ids[9] or 0
        _godSoulTemple["20"].genralsLevel2ByBasic = _ids.ids[10] or 0

        _godSoulTemple["23"] = {}
        _godSoulTemple["23"].soulLevel = _ids.ids[17] or 0
        _godSoulTemple["23"].genralsLevel2ByBasic = _ids.ids[18] or 0
    end
    
    local _pageName = gamedata.ext.godSoulTemplePageName
    gamedata.ext.godSoulTemplePageName = nil


    return {type = 7030, godSoulTemple = _godSoulTemple, pageName = _pageName,lianhun_materials = lianhun_materials,cuishen_materials = cuishen_materials}
end

function UIGodSoulTempleLevelUpCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 7031, "UIGodSoulTempleLevelUpCallback")

    local _ids = ids_pb.Ids()
    table.insert(_ids.ids, uireq.id)
    gamedata.ext.godSoulTemplePageName = uireq.pageName

    return 1, 7031, _ids:SerializeToString()
end

function NetGodSoulTempleLevelUpCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7031, "NetGodSoulTempleLevelUpCallback")

    local _ids = ids_pb.Ids()
    _ids:ParseFromString(fd.rbuf)
    local _godSoulTemple = {}

    _godSoulTemple.soulLevel = _ids.ids[1] or 0
    _godSoulTemple.soulStatus = _ids.ids[2] or 0
    _godSoulTemple.godStatus = _ids.ids[3] or 0

    local _pageName = gamedata.ext.godSoulTemplePageName
    gamedata.ext.godSoulTemplePageName = nil
    
    return {type = 7031, godSoulTemple = _godSoulTemple, pageName = _pageName}
end


function UIGodSoulTempleRefineSoulQueryCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 7032, "UIGodSoulTempleRefineSoulQueryCallback")

    local _ids = ids_pb.Ids()
    table.insert(_ids.ids, uireq.id)

    return 1, 7032, _ids:SerializeToString()
end

function NetGodSoulTempleRefineSoulQueryCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7032, "NetGodSoulTempleRefineSoulQueryCallback")

    local _ids = ids_pb.Ids()
    _ids:ParseFromString(fd.rbuf)
    local _godSoulTemple = {}

    _godSoulTemple.soulStatus = _ids.ids[1] or 0
    _godSoulTemple.soulStar = _ids.ids[2] or 0
    _godSoulTemple.soulExp = _ids.ids[3] or 0

    return {type = 7032, godSoulTemple = _godSoulTemple}
end

function UIGodSoulTempleRefineSoulCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 7033, "UIGodSoulTempleRefineSoulCallback")

    local _ids = ids_pb.Ids()
    table.insert(_ids.ids, uireq.id)
    for k,v in pairs(uireq.consume) do
        table.insert(_ids.ids, tonumber(k))
        table.insert(_ids.ids, tonumber(v))
    end

    gamedata.ext.RefineSoulConsume = uireq.consume

    return 1, 7033, _ids:SerializeToString()
end

function NetGodSoulTempleRefineSoulCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7033, "NetGodSoulTempleRefineSoulCallback")

    for k,v in pairs(gamedata.ext.RefineSoulConsume) do
        -- print("NetGodSoulTempleRefineSoulCallback:"..k)
        if gamedata.cache.generalfragments[tonumber(k-1000)] then
             -- print("NetGodSoulTempleRefineSoulCallback v:"..v)
            gamedata.cache.generalfragments[tonumber(k-1000)].num = gamedata.cache.generalfragments[tonumber(k-1000)].num - tonumber(v)
        end
    end

    local _ids = ids_pb.Ids()
    _ids:ParseFromString(fd.rbuf)

    local _godSoulTemple = {}

    _godSoulTemple.soulStatus = _ids.ids[1] or 0
    _godSoulTemple.soulStar = _ids.ids[2] or 0
    _godSoulTemple.soulExp = _ids.ids[3] or 0

    return {type = 7033,godSoulTemple = _godSoulTemple,RefineSoulConsume = gamedata.ext.RefineSoulConsume}
end

function UIGodSoulTempleCuishenQueryCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 7034, "UIGodSoulTempleCuishenQueryCallback")

    local _ids = ids_pb.Ids()
    table.insert(_ids.ids, uireq.id)

    return 1, 7034, _ids:SerializeToString()
end

function NetGodSoulTempleCuishenQueryCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7034, "NetGodSoulTempleCuishenQueryCallback")

    local _ids = ids_pb.Ids()
    _ids:ParseFromString(fd.rbuf)
    local _godSoulTemple = {}

    _godSoulTemple.soulStatus = _ids.ids[1] or 0
    _godSoulTemple.soulStar = _ids.ids[2] or 0
    _godSoulTemple.soulExp = _ids.ids[3] or 0

    return {type = 7034, godSoulTemple = _godSoulTemple}
end

function UIGodSoulTempleCuishenCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 7035, "UIGodSoulTempleCuishenCallback")

    local _ids = ids_pb.Ids()
    table.insert(_ids.ids, uireq.id)
    for k,v in pairs(uireq.consume) do
        table.insert(_ids.ids, tonumber(k))
        table.insert(_ids.ids, tonumber(v))
    end

    gamedata.ext.CuishenlConsume = uireq.consume

    return 1, 7035, _ids:SerializeToString()
end

function NetGodSoulTempleCuishenCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7035, "NetGodSoulTempleCuishenCallback")
    for k,v in pairs(gamedata.ext.CuishenlConsume) do
        gamedata:updateStaff({cid = tonumber(k),num = 0-tonumber(v)})
    end

    local _ids = ids_pb.Ids()
    _ids:ParseFromString(fd.rbuf)

    local _godSoulTemple = {}

    _godSoulTemple.soulStatus = _ids.ids[1] or 0
    _godSoulTemple.soulStar = _ids.ids[2] or 0
    _godSoulTemple.soulExp = _ids.ids[3] or 0

    return {type = 7035,godSoulTemple = _godSoulTemple}
end
