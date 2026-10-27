--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-10-11
-- Time: 下午2:57
-- To change this template use File | Settings | File Templates.
--

--与海外版有差异，海外版伙伴突破消耗的碎片数量根据资质计算，国内版根据品质计算

local ids_pb = require("ids_pb")

function UIGeneralBreakPreviewCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1023, "GeneralBreakPreview")
    local GeneralBreakData = ids_pb.Ids()

    table.insert(GeneralBreakData.ids, uireq.general)

    return 1, 1023, GeneralBreakData:SerializeToString()
end

local generals_pb = require("generals_pb")
function NetGeneralBreakPreviewCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1023, "GeneralBreakPreview")
    local GeneralsData = generals_pb.Generals()
    GeneralsData:ParseFromString(fd.rbuf)
    local nextGeneral = {}

    for k,v in ipairs(GeneralsData.generals) do
        nextGeneral = gamedata:generalData(v)
    end

    return { 
        type = 1023, 
        nextGeneral = nextGeneral, 
        fragment = gamedata.cache.generalfragments[fcid],
        generalslove = gamedata.cache.generalslove.alldata or {}
    }
end


function UIGeneralBreakCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1017, "GeneralBreak")
    local GeneralBreakData = ids_pb.Ids()

    table.insert(GeneralBreakData.ids, uireq.ids["1"])
    if uireq.scope then
        table.insert(GeneralBreakData.ids, uireq.scope)
    end    

    gamedata.ext.generalbreskCID = uireq.ids["1"]

    return 1, 1017, GeneralBreakData:SerializeToString()
end

local generals_pb = require("generals_pb")
function NetGeneralBreakCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1017, "GeneralBreak")

    local GeneralsData = generals_pb.Generals()
    GeneralsData:ParseFromString(fd.rbuf)

    gamedata:Generals(GeneralsData.generals)
    print(gamedata.ext.generalbreskCID)

    local getGeneral = {}
    for k,v in pairs(gamedata.cache.generals) do
        if gamedata.config.general[tostring(gamedata.ext.generalbreskCID)] and gamedata.config.general[tostring(gamedata.ext.generalbreskCID)].gold_id and gamedata.config.general[tostring(gamedata.ext.generalbreskCID)].gold_id == v.cid then
            getGeneral = v
        elseif gamedata.config.general[tostring(gamedata.ext.generalbreskCID)] and gamedata.config.general[tostring(gamedata.ext.generalbreskCID)].break_id and gamedata.config.general[tostring(gamedata.ext.generalbreskCID)].break_id == v.cid then
            getGeneral = v
        elseif v.cid == gamedata.ext.generalbreskCID then
            getGeneral = v
        elseif gamedata.config.general[tostring(gamedata.ext.generalbreskCID)] and gamedata.config.general[tostring(gamedata.ext.generalbreskCID)].gold_id and gamedata.config.general[tostring(v.cid)] and gamedata.config.general[tostring(v.cid)].partner_id and gamedata.config.general[tostring(gamedata.ext.generalbreskCID)].gold_id > 0 and gamedata.config.general[tostring(v.cid)].partner_id == gamedata.config.general[tostring(gamedata.ext.generalbreskCID)].gold_id then
            getGeneral = v    
        elseif gamedata.config.general[tostring(gamedata.ext.generalbreskCID)] and gamedata.config.general[tostring(gamedata.ext.generalbreskCID)].break_id and gamedata.config.general[tostring(v.cid)] and gamedata.config.general[tostring(v.cid)].partner_id and gamedata.config.general[tostring(gamedata.ext.generalbreskCID)].break_id > 0 and gamedata.config.general[tostring(v.cid)].partner_id == gamedata.config.general[tostring(gamedata.ext.generalbreskCID)].break_id then
            getGeneral = v   
        elseif gamedata.config.general[tostring(gamedata.ext.generalbreskCID)] and gamedata.config.general[tostring(gamedata.ext.generalbreskCID)].init_cid and gamedata.config.general[tostring(v.cid)] and gamedata.config.general[tostring(v.cid)].init_cid and gamedata.config.general[tostring(v.cid)].init_cid == gamedata.config.general[tostring(gamedata.ext.generalbreskCID)].init_cid then
            getGeneral = v
        end
    end
    printT(getGeneral)
    --
    local GeneralCid = getGeneral.cid
    local quality = gamedata.config.general[tostring(GeneralCid)].quality
    --
    local needfragment = gamedata.config.general_awake[tostring(getGeneral.level2)][tostring(quality).."piece"] or 0
    local needprop =  gamedata.config.general_awake[tostring(getGeneral.level2)][tostring(quality).."prop"] or 0
    local needcoin = gamedata.config.general_awake[tostring(getGeneral.level2)]["coin"..tostring(quality)] or 0
    local needredfragment = gamedata.config.general_awake[tostring(getGeneral.level2)]["red_item"] or 0
    local needredprop =  gamedata.config.general_awake[tostring(getGeneral.level2)]["red_cost"] or 0
    local needredprop2 =  gamedata.config.general_awake[tostring(getGeneral.level2)]["red_cost2"] or 0
    local needgoldprop = {}
    if gamedata.config.general_awake[tostring(getGeneral.level2)]["gold_cost"] and gamedata.config.general_awake[tostring(getGeneral.level2)]["gold_cost"] ~= "" then
        needgoldprop = gamedata.getIDandNUMs(gamedata.config.general_awake[tostring(getGeneral.level2)]["gold_cost"]) or {}
    end    
    --
    local fcid = GeneralCid
    fcid = gamedata.getOriginCid(GeneralCid)
    --
    local redcid = GeneralCid
    local redfragmentcid = GeneralCid
    if gamedata.config.general[tostring(GeneralCid)].red_id and gamedata.config.general[tostring(GeneralCid)].red_id > 0 then
        redcid = gamedata.config.general[tostring(GeneralCid)].red_id
    elseif gamedata.config.general[tostring(GeneralCid)].break_id and gamedata.config.general[tostring(GeneralCid)].break_id > 0 then
        redcid = gamedata.config.general[tostring(GeneralCid)].break_id
    elseif gamedata.config.general[tostring(GeneralCid)].partner_id and gamedata.config.general[tostring(GeneralCid)].partner_id > 0 then
        redcid = gamedata.config.general[tostring(GeneralCid)].partner_id
    end
    for k,v in pairs(gamedata.config.redl_awake_item) do
        if v.red_id == redcid then
            redfragmentcid = v.id
        end
    end
    --
    if needfragment > 0 then
        gamedata:updategeneralfragmentbynum({cid = fcid, num = 0-needfragment })
    end
    if needprop > 0 then
        gamedata:updateprops({cid = 20017,num = 0-needprop})
    end
    if needcoin > 0 then
        gamedata:updateRoleCoin(0-needcoin)
    end
    if needredprop > 0 then
        gamedata:updateprops({cid = 20354,num = 0-needredprop})
    end
    if needredprop2 > 0 then
        gamedata:updateprops({cid = 20551,num = 0-needredprop2})
    end
    if needredfragment > 0 then
        gamedata:UpdateRedFragment({cid = redfragmentcid,num = 0-needredfragment})
    end

    if needgoldprop and next(needgoldprop) then
        for k,v in pairs(needgoldprop) do
            gamedata:updateStaff({cid = v.cid, num = 0-v.num})
        end
    end    

    return { type = 1017, ison = gamedata:isGeneralOn(getGeneral.iid), general = gamedata.cache.generals[getGeneral.iid], fragment = gamedata.cache.generalfragments[GeneralCid] }
end



function UIGeneralBestQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3780, "GeneralBestQuery")

    return 1, 3780, nil
end

function NetGeneralBestQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3780, "GeneralBestQuery")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    gamedata:SetRedFragment(ids.ids)

    return { type = 3780, redfragment = gamedata.cache.redfragment or {}}

end

function UIRedFragmentsCallBack(uireq)
    print("请求10030 接收UI请求")
    return 0, 10030, {type = 10030, redfragment = gamedata.cache.redfragment or {}}
end

function UIGeneralChangeBreakSkillCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 7021, "GeneralChangeBreakSkillCallBack")
    local GeneralBreakData = ids_pb.Ids()

    printT(uireq)

    table.insert(GeneralBreakData.ids, uireq.selectIllusion or 0)
    table.insert(GeneralBreakData.ids, uireq.cid)
    for k,v in pairs(uireq.xselect or {}) do
        table.insert(GeneralBreakData.ids, v.lv)
        table.insert(GeneralBreakData.ids, v.scope)
    end

    gamedata.ext.GeneralChangeBreakSkillCost = uireq.xcost or {}


    if not (uireq.selectIllusion and uireq.selectIllusion == 1) then
        for k,v in pairs(gamedata.ext.GeneralChangeBreakSkillCost) do
            if v.cid == 1001 then
                if gamedata.cache.role.gold < tonumber(v.num) then
                    return  0, 503, {type = 503, msgtype = "shortgold"}
                end
            else
                if gamedata.getStaffNum(v.cid).num < v.num then
                    return 0,503,{type = 503,msgtype = "shortprop",id = v.cid,num = v.num}
                end
            end
        end
    else
        gamedata.ext.GeneralChangeBreakSkillCost = {}
    end

    return 1, 7021, GeneralBreakData:SerializeToString()
end

function NetGeneralChangeBreakSkillCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7021, "GeneralChangeBreakSkillCallBack")

    local GeneralsData = generals_pb.Generals()
    GeneralsData:ParseFromString(fd.rbuf)

    gamedata:Generals(GeneralsData.generals)

    if gamedata.ext.GeneralChangeBreakSkillCost and next(gamedata.ext.GeneralChangeBreakSkillCost) then
        for k,v in pairs(gamedata.ext.GeneralChangeBreakSkillCost) do
            gamedata:updateStaff({cid = v.cid, num = 0-v.num})
        end
    end   

    return { 
        type = 7021
    }
end

 _&  