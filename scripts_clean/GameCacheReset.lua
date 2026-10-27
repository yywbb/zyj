--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/1/23
-- Time: 上午9:57
-- To change this template use File | Settings | File Templates.
--

function UICacheReset()
    cclog("NET type:%d cmd:%s recv request from clinet", 110, "UICacheReset")

    return 0,110,{ type = 110}
end

function NetCacheReset(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 110, "NetCacheReset")

    return { type = 110}
end

function NetStaminaUp(fd)
    if next(gamedata.cache.role) and gamedata.cache.role.stamina and gamedata.cache.role.stamina < gamedata.cache.role.maxstamina then
        gamedata:updateRoleStamina(1)
        return { type = 1001, param = "resume" }
    else
        return { type = 1001 }
    end
end

function NetEnergyUp(fd)
    if next(gamedata.cache.role) and gamedata.cache.role.energy and gamedata.cache.role.energy < gamedata.cache.role.maxenergy then
        gamedata:updateRoleEnergy(1)
        return { type = 1001, param = "resume" }
    else
        return { type = 1001 }
    end
end
