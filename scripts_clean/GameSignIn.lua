--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/11/28
-- Time: 下午6:20
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")

function UISignInStatusCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2060, "SignInStatus")

    if next(gamedata.cache.signin) ~= nil then
        return 0, 2060, { type = 2060, status = gamedata.cache.signin, vip = gamedata.cache.role.vip or 0 }
    else
        return 1, 2060, nil
    end

end

function NetSignInStatusCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2060, "SignInStatus")
    local signinData = ids_pb.Ids()
    signinData:ParseFromString(fd.rbuf)

    gamedata:SignIn(signinData)

    return { type = 2060, status = gamedata.cache.signin, vip = gamedata.cache.role.vip or 0 }
end


function UISignInCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2061, "SignIn")
    gamedata.ext.signinday = nil
    if uireq.day then
        local SignInData = ids_pb.Ids()
        table.insert(SignInData.ids, uireq.day)
        gamedata.ext.signinday = uireq.day

        if  gamedata.cache.role.gold < 50 then
            return 0,503,{type = 503, msgtype = "shortgold"}
        end

        return 1, 2061, SignInData:SerializeToString()
    else
        return 1, 2061, nil
    end
end

function NetSignInCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2061, "SignIn")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    if gamedata.ext.signinday then
        gamedata.cache.signin.resign = gamedata.cache.signin.resign + 1
        gamedata:updateRoleGold(-50,"签到补签",1)
        gamedata.cache.signin.days[gamedata.ext.signinday] = 2
    else
        local t = os.date("*t", gamedata:time())
        gamedata.cache.signin.days[t.day] = 2
    end

    return { type = 2061, reward = gamedata:SomethingProcess(SomeThings),status = gamedata.cache.signin, vip = gamedata.cache.role.vip or 0 }
end

-------
function UISignIn2StatusCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3641, "SignIn2Status")

    gamedata.ext.signinParam = uireq.param or ""

    if next(gamedata.cache.signin2) ~= nil then
        return 0, 3641, { type = 3641, data = gamedata.cache.signin2, param = gamedata.ext.signinParam or ""}
    else
        return 1, 3641, nil
    end
end

function NetSignIn2StatusCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3641, "SignIn2Status")
    local signinData = ids_pb.Ids()
    signinData:ParseFromString(fd.rbuf)

    gamedata:SignIn2(signinData)

    return { type = 3641, data = gamedata.cache.signin2, param = gamedata.ext.signinParam or ""}
end

function UISignIn2CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3642, "SignIn2")

    return 1, 3642, nil
end

function NetSignIn2CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3642, "SignIn2")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    gamedata.cache.signin2.daynum = gamedata.cache.signin2.daynum + 1
    gamedata.cache.signin2.status = 1

    return { type = 3642, reward = gamedata:SomethingProcess(SomeThings),data = gamedata.cache.signin2,}
end

function UILuxurySignInStatusCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3643, "SignIn2")
    if uireq.update then
        return 1, 3643, nil
    elseif gamedata.cache.luxurySignInStatus and gamedata.cache.luxurySignInStatus.status then
        -- return 0, 3643, {type = 3643, status = gamedata.cache.luxurySignInStatus and gamedata.cache.luxurySignInStatus.status or 0,}
        return 0, 3643, {type = 3643, status = gamedata.cache.luxurySignInStatus and gamedata.cache.luxurySignInStatus.status or 0, 
                itemId1 = gamedata.cache.luxurySignInStatus and gamedata.cache.luxurySignInStatus.itemId1 or 0,
                itemNum1 = gamedata.cache.luxurySignInStatus and gamedata.cache.luxurySignInStatus.itemNum1 or 0,
                itemId2 = gamedata.cache.luxurySignInStatus and gamedata.cache.luxurySignInStatus.itemId2 or 0,
                itemNum2 = gamedata.cache.luxurySignInStatus and gamedata.cache.luxurySignInStatus.itemNum2 or 0,
                itemId3 = gamedata.cache.luxurySignInStatus and gamedata.cache.luxurySignInStatus.itemId3 or 0,
                itemNum3 = gamedata.cache.luxurySignInStatus and gamedata.cache.luxurySignInStatus.itemNum3 or 0,
                itemId4 = gamedata.cache.luxurySignInStatus and gamedata.cache.luxurySignInStatus.itemId4 or 0,
                itemNum4 = gamedata.cache.luxurySignInStatus and gamedata.cache.luxurySignInStatus.itemNum4 or 0,}
    else  
        print("33==")
        return 1, 3643, nil
    end
end

function NetLuxurySignInStatusCallBack(fd)
    print("==")
    cclog("NET type:%d cmd:%s recv response from gameserver", 3643, "SignIn2")
    local signinData = ids_pb.Ids()
    signinData:ParseFromString(fd.rbuf)
    gamedata:LuxurySignInStatus(signinData)
    return {type = 3643, status = gamedata.cache.luxurySignInStatus and gamedata.cache.luxurySignInStatus.status or 0, 
            itemId1 = gamedata.cache.luxurySignInStatus and gamedata.cache.luxurySignInStatus.itemId1 or 0,
            itemNum1 = gamedata.cache.luxurySignInStatus and gamedata.cache.luxurySignInStatus.itemNum1 or 0,
            itemId2 = gamedata.cache.luxurySignInStatus and gamedata.cache.luxurySignInStatus.itemId2 or 0,
            itemNum2 = gamedata.cache.luxurySignInStatus and gamedata.cache.luxurySignInStatus.itemNum2 or 0,
            itemId3 = gamedata.cache.luxurySignInStatus and gamedata.cache.luxurySignInStatus.itemId3 or 0,
            itemNum3 = gamedata.cache.luxurySignInStatus and gamedata.cache.luxurySignInStatus.itemNum3 or 0,
            itemId4 = gamedata.cache.luxurySignInStatus and gamedata.cache.luxurySignInStatus.itemId4 or 0,
            itemNum4 = gamedata.cache.luxurySignInStatus and gamedata.cache.luxurySignInStatus.itemNum4 or 0,}
end

function UILuxurySignInCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3644, "SignIn2")
    -- return 1, 3644, gamedata.cache.luxurySignInStatus.itemId1, gamedata.cache.luxurySignInStatus.itemId2      
    return 1, 3644, nil
end

function NetLuxurySignInCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3644, "SignIn2")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    local reward = gamedata:SomethingProcess(SomeThings)

    gamedata.cache.luxurySignInStatus.status = 2

    return {type = 3644, reward = reward, status = gamedata.cache.luxurySignInStatus.status,
            itemId1 = gamedata.cache.luxurySignInStatus.itemId1,
            itemNum1 = gamedata.cache.luxurySignInStatus.itemNum1,
            itemId2 = gamedata.cache.luxurySignInStatus.itemId2,
            itemNum2 = gamedata.cache.luxurySignInStatus.itemNum2,
            itemId3 = gamedata.cache.luxurySignInStatus.itemId3,
            itemNum3 = gamedata.cache.luxurySignInStatus.itemNum3,
            itemId4 = gamedata.cache.luxurySignInStatus.itemId4,
            itemNum4 = gamedata.cache.luxurySignInStatus.itemNum4,}
end