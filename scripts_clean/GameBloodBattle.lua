--
-- Created by IntelliJ IDEA.
-- User: jutian
-- Date: 14-3-5
-- Time: 上午11:54
-- To change this template use File | Settings | File Templates.
--
local bloodbattle_pb = require"bloodbattle_pb"
local battleresult_pb = require"battleresult_pb"
local bloodquery_pb = require"bloodquery_pb"
local blood3awardattr_pb = require"blood3awardattr_pb"
local blood3awardattrquery_pb = require"blood3awardattrquery_pb"
local somethings_pb = require"somethings_pb"
local blood5awardquery_pb = require"blood5awardquery_pb"
local bloodrankqueryresponse_pb = require"bloodrankqueryresponse_pb"
local ids_pb = require("ids_pb")

function UIBloodBattleCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2071, "bloodbattle")
    if gamedata.cache.bloodbattle.status ~= 1 then
        return 0,503,{type=503,msg="血战状态错误~"}
    end
    gamedata.ext.bloodbattle={target=uireq.target}
    local bloodBattleRequest = bloodbattle_pb.BloodBattle()
    bloodBattleRequest.target = uireq.target
    return 1,2071,bloodBattleRequest:SerializeToString()
end

function NetBloodBattleCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2071, "bloodbattle")
    local battleResultResponse = battleresult_pb.BattleResult()
    battleResultResponse:ParseFromString(fd.rbuf)

    return {
        type = 2071,
        star = battleResultResponse.star,
        result = battleResultResponse.result,
        battlereport = battleResultResponse.battlereport,
    }
end

---------------------------------------------------------------------------------------------------------------------------------------

function UIBloodWipeCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2077, "bloodwipe")
    if gamedata.cache.bloodbattle.status ~= 1 then
        return 0,503,{type=503,msg="血战状态错误~"}
    end
    return 1,2077,nil
end

function NetBloodWipeCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2077, "bloodwipe")
    local bloodQueryResponse = bloodquery_pb.BloodQuery()
    bloodQueryResponse:ParseFromString(fd.rbuf)

    gamedata:BloodData(bloodQueryResponse)
    return {type=2077, blood=gamedata.cache.bloodbattle}
end

---------------------------------------------------------------------------------------------------------------------------------------

function UIBloodWipeRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2078, "bloodwipeReward")
    if gamedata.cache.bloodbattle.status ~= 6 then
        return 0,503,{type=503,msg="血战状态错误~"}
    end
    return 1,2078,nil
end

function NetBloodWipeRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2078, "bloodwipeReward")
    local WipeReward = somethings_pb.SomeThings()
    WipeReward:ParseFromString(fd.rbuf)

    return {type=2078,reward = gamedata:SomethingProcess(WipeReward)}
end

---------------------------------------------------------------------------------------------------------------------------------------

function UIBloodWipeContinueCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2079, "bloodwipeContinue")
    if gamedata.cache.bloodbattle.status ~= 7 then
        return 0,503,{type=503,msg="血战状态错误~"}
    end
    local WipeMethod = ids_pb.Ids()
    table.insert(WipeMethod.ids, (uireq.method))

    return 1,2079,WipeMethod:SerializeToString()
end

function NetBloodWipeContinueCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2079, "bloodwipeContinue")
    local bloodQueryResponse = bloodquery_pb.BloodQuery()
    bloodQueryResponse:ParseFromString(fd.rbuf)

    gamedata:BloodData(bloodQueryResponse)
    return {type=2079, blood=gamedata.cache.bloodbattle}
end

---------------------------------------------------------------------------------------------------------------------------------------

function UIBloodQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2070, "bloodquery")
    return 1,2070,nil
end

function NetBloodQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2070, "bloodquery")
    local bloodQueryResponse = bloodquery_pb.BloodQuery()
    bloodQueryResponse:ParseFromString(fd.rbuf)

    gamedata:BloodData(bloodQueryResponse)

    return {type=2070, blood=gamedata.cache.bloodbattle}
end

---------------------------------------------------------------------------------------------------------------------------------------

function UIBlood3AttrBufCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2073, "blood3attrbuf")
    local blood3AwardAttrSelect = blood3awardattr_pb.Bloold3AwardAttrs()
    --blood3AwardAttrSelect.attrs = uireq.attrs
    table.insert(blood3AwardAttrSelect.attrs, uireq.attrs)
    return 1,2073,blood3AwardAttrSelect:SerializeToString()
end

function NetBlood3AttrBufCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2073, "blood3attrbuf")
    local bloodQueryResponse = bloodquery_pb.BloodQuery()
    bloodQueryResponse:ParseFromString(fd.rbuf)

    gamedata:BloodData(bloodQueryResponse)

    return {type=2073, blood=gamedata.cache.bloodbattle}
end

---------------------------------------------------------------------------------------------------------------------------------------

function Blood3AwardData(blood3award)
    local t = {}
    for k,v in ipairs(blood3award.attrs) do
        table.insert(t,{
            attr = v.attr,
            add = v.add
        })
    end
    return t
end

function UIBlood3AttrBufQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2072, "blood3attrbufquery")
    return 1,2072,nil
end

function NetBlood3AttrBufQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2072, "blood3attrbufquery")
    local blood3AwardAttrQueryResponse = blood3awardattrquery_pb.Blood3AwardAttrQuery()
    blood3AwardAttrQueryResponse:ParseFromString(fd.rbuf)

    return {type=2072, award3= Blood3AwardData(blood3AwardAttrQueryResponse)}
end

---------------------------------------------------------------------------------------------------------------------------------------

function UIBlood5AwardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2075, "blood5award")
    return 1,2075,nil
end

function NetBlood5AwardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2075, "blood5award")
    local blood5AwardS = somethings_pb.SomeThings()
    blood5AwardS:ParseFromString(fd.rbuf)
    return {type=2075,reward = gamedata:SomethingProcess(blood5AwardS),}
end

---------------------------------------------------------------------------------------------------------------------------------------

function UIBlood5AwardQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2074, "blood5awardquery")

    gamedata.ext.Blood5AwardQuery = {floor = uireq.floor }
    return 1,2074,nil
end

function NetBlood5AwardQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2074, "blood5awardquery")
    local blood5AwardQueryResponse = blood5awardquery_pb.Blood5AwardsQuery()
    blood5AwardQueryResponse:ParseFromString(fd.rbuf)
    return {type=2074, this=blood5AwardQueryResponse.this, pre=blood5AwardQueryResponse.pre, floor = gamedata.ext.Blood5AwardQuery.floor }
end

---------------------------------------------------------------------------------------------------------------------------------------

function UIBloodRankQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2076, "bloodrankquery")

    if next(gamedata.cache.bloodrank) ~= nil then
        return 0,2076,{type=2076,rank=gamedata.cache.bloodrank, point = gamedata.cache.bloodbattle.point,}
    else
        return 1,2076,nil
    end

end

function NetBloodRankQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2076, "bloodrankquery")
    local bloodRankQueryResponse = bloodrankqueryresponse_pb.BloodRankQueryResponse()
    bloodRankQueryResponse:ParseFromString(fd.rbuf)

    gamedata:BloodRankData(bloodRankQueryResponse)

    return {type=2076,rank=gamedata.cache.bloodrank,  point = gamedata.cache.bloodbattle.point,}
end

---------------------------------------------------------------------------------------------------------------------------------------

function UIBloodExchangeCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2085, "BloodExchange")

    local BloodExchangeid = ids_pb.Ids()
    table.insert(BloodExchangeid.ids, uireq.id)

    gamedata.ext.BloodExchangeid = uireq.id

    return 1,2085,BloodExchangeid:SerializeToString()
end

function NetBloodExchangeCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2085, "BloodExchange")
    local BloodExchangedata = somethings_pb.SomeThings()
    BloodExchangedata:ParseFromString(fd.rbuf)

    gamedata.cache.bloodbattle.point = gamedata.cache.bloodbattle.point - gamedata.config.blood_point[tostring(gamedata.ext.BloodExchangeid)].prestige

    return {type=2085, point = gamedata.cache.bloodbattle.point,reward = gamedata:SomethingProcess(BloodExchangedata),}
end