--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-10-20
-- Time: 上午10:42
-- To change this template use File | Settings | File Templates.
--

--与海外版有差异，海外版取消已拥有伙伴的奇遇价格打折为 1/5

require"PickBattleResultReport"

local function makeEncounters()
    local encount = table.copy(gamedata.cache.encounters)

    local encounters = {}
    for k,v in pairs(encount) do
        local configdata = gamedata.config.encounter[tostring(v.cid)]
        if configdata.type == "exp" then
            v.xgold = tonumber(gamedata.config.global_kv.adventure_exp_cost.value) or 0
        elseif configdata.type == "search" then
            v.xgold = tonumber(gamedata.config.global_kv.adventure_war_cost.value) or 0
        elseif configdata.type == "general" then
            v.isfragment = 0
            local i_buf1 = string.find(configdata.param, ";",1)
            local i_buf2 = string.find(configdata.param, ",",i_buf1+1)
            if i_buf1 and i_buf2 then
                v.generalcid =  string.sub(configdata.param,i_buf1+1,i_buf2-1)
                v.xgold =  tonumber(string.sub(configdata.param,i_buf2+1,string.len(configdata.param)-1))
                for kk,vv in pairs(gamedata.cache.generals) do
                    if (gamedata.config.general[tostring(vv.cid)].init_cid and tostring(gamedata.config.general[tostring(vv.cid)].init_cid) == v.generalcid) or (gamedata.config.general[tostring(vv.cid)].orange_id and tostring(gamedata.config.general[tostring(vv.cid)].orange_id) == v.generalcid) or (gamedata.config.general[tostring(vv.cid)].generalid2 and tostring(gamedata.config.general[tostring(vv.cid)].generalid2) == v.generalcid) or v.generalcid == tostring(vv.cid) then
                        v.isfragment = 1
                        if v.zhe and v.zhe > 0 then
                            v.xgold = math.floor((0+v.xgold)*(v.zhe)/10)
                        else
                            v.xgold = 0+v.xgold
                        end    
                    elseif (gamedata.config.general[tostring(vv.cid)].partner_id and tostring(gamedata.config.general[tostring(vv.cid)].partner_id) == v.generalcid) then    
                        v.isfragment = 1
                        if v.zhe and v.zhe > 0 then
                            v.xgold = math.floor((0+v.xgold)*(v.zhe)/10)
                        else
                            v.xgold = 0+v.xgold
                        end   
                    end
                end
            end
        else
        end
        table.insert(encounters,v)

    end


    local sortByIID = function(a,b) return a.iid < b.iid end
    table.sort(encounters,sortByIID)
    return encounters
end

local function getPrice(param)
    return  string.match(param,",%s*(%d+)%s*;")
end

function UIEncounterQueryExtCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 13101, "EncounterQueryEXT")

    local has = false
    local updatetime = 0
    if next(gamedata.cache.encounters) then
        has = true
        local now = gamedata:time()
        for k,v in pairs(gamedata.cache.encounters) do
            local config = gamedata.config.encounter[tostring(v.cid)]
            if v.time - (now - v.beginT) > updatetime then
                updatetime = v.time - (now - v.beginT)
            end
        end
    end

    return 0, 13101, { type = 13101, has = has,updatetime = updatetime}
end

function UIEncounterQueryCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1310, "EncounterQuery")

    gamedata.ext.encountgoto = uireq.param
    if next(gamedata.cache.encounters) then
        return 0, 1310, { type = 1310, encounters = makeEncounters(),param =  gamedata.ext.encountgoto}
    else
        return 1, 1310, nil
    end
end

local encounters_pb = require("encounters_pb")
function NetEncounterQueryCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1310, "EncounterQuery")
    local EncountersData = encounters_pb.Encounters()
    EncountersData:ParseFromString(fd.rbuf)

    gamedata:Encounters(EncountersData.encounters)

    return { type = 1310, encounters = makeEncounters(),param =  gamedata.ext.encountgoto}
end



local encounteropt_pb = require("encounteropt_pb")
function UIEncounterUseCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1311, "EncounterUse")
    local EncounterOptData = encounteropt_pb.EncounterOpt()
    EncounterOptData.iid = uireq.iid
    EncounterOptData.method = uireq.method

    if uireq.xgold and uireq.xgold > gamedata.cache.role.gold and EncounterOptData.method ~= 3 then
        return 0,503,{type = 503, msg = "元宝不足"}
    end

    gamedata.ext.EncounterOpt = {iid = uireq.iid, method = uireq.method }
    gamedata.ext.EncounterModulus = uireq.modulus or 1

    return 1, 1311, EncounterOptData:SerializeToString()
end

local battleresult_pb = require("battleresult_pb")
function NetEncounterUseCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1311, "EncounterUse")
    local EncounterOptResultPb = battleresult_pb.BattleResult()
    EncounterOptResultPb:ParseFromString(fd.rbuf)

    local config = gamedata.config.encounter[tostring(gamedata.cache.encounters[gamedata.ext.EncounterOpt.iid].cid)]

    local t = {type = 1311,iid = gamedata.ext.EncounterOpt.iid,method = gamedata.ext.EncounterOpt.method, encounterType = config.type}

    if config.type == "exp" then
        t.reward = gamedata:SomethingProcess(EncounterOptResultPb.reward)
        if gamedata.ext.EncounterOpt.method == 2 or gamedata.ext.EncounterOpt.method == "2" then
            gamedata:updateRoleGold(0 - math.floor((tonumber(gamedata.config.global_kv.adventure_exp_cost.value) or 0)*(gamedata.ext.EncounterModulus or 1) ), "仙人下凡",1)
        end
    elseif config.type == "search" then
        t.reward = gamedata:SomethingProcess(EncounterOptResultPb.reward)
        if gamedata.ext.EncounterOpt.method == 2 or gamedata.ext.EncounterOpt.method == "2" then
            gamedata:updateRoleGold(0 - math.floor((tonumber(gamedata.config.global_kv.adventure_war_cost.value) or 0)*(gamedata.ext.EncounterModulus or 1) ), "打扫战场",1)
        end
    elseif config.type == "battle" then
        if gamedata.ext.EncounterOpt.method == 1 or gamedata.ext.EncounterOpt.method == "1" then
            t.battlereport = PickBattleResultReport(EncounterOptResultPb)
        else
            t.battlereport = ""
        end
        t.reward = gamedata:SomethingProcess(EncounterOptResultPb.reward)
    elseif config.type == "general" then
        local generalData = gamedata:SomethingProcess(EncounterOptResultPb.reward)
        t.gets = {}
        --
        for k,v in pairs(generalData) do
           if (v.cid >= 10101 and v.cid <= 11000) or (v.cid >= 160001 and v.cid <= 161000) or (v.cid >= 170001 and v.cid <= 171000) or (v.cid >= 162001 and v.cid <= 163000) or (v.cid >= 164001 and v.cid <= 165000) or (v.cid >= 174001 and v.cid <= 175000) then
               table.insert(t.gets,v)
               gamedata:updateRoleGold(0 - math.floor(getPrice(config.param)*(gamedata.ext.EncounterModulus or 1)),"奇遇求贤若渴",1)
           elseif (v.cid >= 11101 and v.cid <= 12000) or (v.cid >= 161001 and v.cid <= 162000) or (v.cid >= 171001 and v.cid <= 172000) or (v.cid >= 163001 and v.cid <= 164000) or (v.cid >= 165001 and v.cid <= 166000) or (v.cid >= 175001 and v.cid <= 176000) then
               t.reward = t.reward or {}
               table.insert(t.reward,{cid = v.cid, num = v.num})
               if gamedata.ext.EncounterOpt.method == 1 or gamedata.ext.EncounterOpt.method == "1" then
                    local zhe = 10
                    if gamedata.cache.encounters[gamedata.ext.EncounterOpt.iid] and gamedata.cache.encounters[gamedata.ext.EncounterOpt.iid].zhe and gamedata.cache.encounters[gamedata.ext.EncounterOpt.iid].zhe > 0 then
                        zhe = gamedata.cache.encounters[gamedata.ext.EncounterOpt.iid].zhe
                    end
                   gamedata:updateRoleGold(0 - math.floor( ((0+getPrice(config.param))*zhe/10) *(gamedata.ext.EncounterModulus or 1) ), "奇遇求贤若渴",1)
               end
           end
        end
    elseif config.type == "shop" then
        t.reward = gamedata:SomethingProcess(EncounterOptResultPb.reward)
        if gamedata.ext.EncounterOpt.method == 1 or gamedata.ext.EncounterOpt.method == "1" then
            gamedata:updateRoleGold(0 - math.floor(getPrice(config.param)*(gamedata.ext.EncounterModulus or 1)),"奇遇云游商人",1)
        end
    end

    gamedata.cache.encounters[gamedata.ext.EncounterOpt.iid] = nil

    return t

end

function UIEncounterTimeUpCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 13111, "EncounterTimeUp")

    gamedata.cache.encounters[uireq.iid] = nil

    return 0, 13111, {type = 13111, iid = uireq.iid, encounters = makeEncounters(), }
end


