--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-10-11
-- Time: 下午1:09
-- To change this template use File | Settings | File Templates.
--

local fosterpreview_pb = require("fosterpreview_pb")
function UIGeneralFosterPreviewCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1013, "fosterpreview")
    local fosterpreviewData = fosterpreview_pb.FosterPreview()
    fosterpreviewData.id = uireq.id
    fosterpreviewData.method = uireq.method

    --local prop = math.mod(uireq.method,2) == 1 and 1 or 10
    --local gold = uireq.method >= 3 and prop * 5 or 0
    local prop = 1
    local gold = 0

    if uireq.method  == 2 then
        prop = 10
        gold = 0
    elseif uireq.method  == 3 then
        prop = 1
        gold = 5
    elseif uireq.method  == 4 then
        prop = 10
        gold = 50
    end


    local extprop = 0
    if gamedata.cache.props[20009] then
        extprop = gamedata.cache.props[20009].num
    end

    if not gamedata.cache.props[20009] or prop> gamedata.cache.props[20009].num then
        return 0,503,{type = 503,msgtype = "shortprop",id= 20009,num= prop,updatetable = {type = 12001, order = 10101, cids = {20009}}}
    elseif gold > gamedata.cache.role.gold then
        return 0,503,{type = 503,msgtype = "shortgold"}
    end

    gamedata.ext.fosterpreview = {id = uireq.id, method = uireq.method, extprop = extprop, prop = prop, gold = gold,extGeneralData = uireq.extGeneralData}

    return 1, 1013, fosterpreviewData:SerializeToString()
end

local generals_pb = require("generals_pb")
function NetGeneralFosterPreviewCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1013, "fosterpreview")

    local fosterpreviewData = generals_pb.Generals()
    fosterpreviewData:ParseFromString(fd.rbuf)

    for k,v in ipairs(fosterpreviewData.generals) do
        gamedata.ext.fosterpreview.GeneralData = gamedata:generalData(v)
    end

    gamedata:updateprops({cid = 20009,num = 0-gamedata.ext.fosterpreview.prop})
    gamedata:updateRoleGold(0-gamedata.ext.fosterpreview.gold,"武将培养",1)

    return { type = 1013, extprop = gamedata.ext.fosterpreview.extprop, prop = gamedata.ext.fosterpreview.prop, previewGeneralData = gamedata.ext.fosterpreview.GeneralData, extGeneralData = gamedata.ext.fosterpreview.extGeneralData}
end


local fosterconfirm_pb = require("fosterconfirm_pb")
function UIGeneralFosterConfirmCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1014, "fosterconfirm")
    local fosterconfirmData = fosterconfirm_pb.FosterConfirm()
    if not gamedata.ext.fosterpreview then
        return 0, 503, {type = 503 , msg = "还未预览"}
    else
        fosterconfirmData.id = gamedata.ext.fosterpreview.id
        fosterconfirmData.opt = uireq.opt
    end

    return 1, 1014, fosterconfirmData:SerializeToString()
end

local result_pb = require("result_pb")
function NetGeneralFosterConfirmCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1014, "fosterconfirm")

    local fosterconfirm = result_pb.Result()
    fosterconfirm:ParseFromString(fd.rbuf)

    if fosterconfirm.result then
        --gamedata.cache.generals[gamedata.ext.fosterpreview.id] = gamedata.ext.fosterpreview.GeneralData
        gamedata:Generals({gamedata.ext.fosterpreview.GeneralData})
    end

    local newGeneral = gamedata.cache.generals[gamedata.ext.fosterpreview.id]
    gamedata.ext.fosterpreview = nil

    return { type = 1014,  ison = gamedata:isGeneralOn(newGeneral.iid), general = newGeneral,result = fosterconfirm.result}
end

function UIGeneralAutoTrainCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1126, "GeneralAutoTrain")
    local equipBaptizeData = ids_pb.Ids()

    table.insert(equipBaptizeData.ids, uireq.iid or 0)
    table.insert(equipBaptizeData.ids, uireq.method or 0)
    table.insert(equipBaptizeData.ids, uireq.xlnum or 0)
    table.insert(equipBaptizeData.ids, uireq.status1 or 0)
    table.insert(equipBaptizeData.ids, uireq.status2 or 0)
    table.insert(equipBaptizeData.ids, uireq.status3 or 0)
    --table.insert(equipBaptizeData.ids, uireq.status4 or 0)
    if uireq.iid then
        gamedata.ext.generalfosterAutoid = uireq.iid
    end

    gamedata.ext.fosterpreview2 = {extGeneralData = uireq.extGeneralData}
    gamedata.ext.generalUireq = uireq
    --
    local xprops = {}
    if (uireq.method == 2) then
        table.insert(xprops,{cid = 1001, num = 5 * uireq.xlnum})
        if gamedata.cache.role.gold < 5 * uireq.xlnum then
            return 0, 503, {type = 503, msgtype = "shortgold" }
        end     
    end
    table.insert(xprops,{cid = 20009, num = 1 * uireq.xlnum})
    if not gamedata.cache.props[20009] or gamedata.cache.props[20009].num < 1 * uireq.xlnum then
        return 0, 503, {type = 503, msg = gamedata.config.props["20009"].name.."不足" }
    end   
    gamedata.ext.generalfosterAuto = xprops

    return 1, 1126, equipBaptizeData:SerializeToString()
end


function NetGeneralAutoTrainCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1126, "GeneralAutoTrain")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local status = {}
    local stop = 0
    for k,v in ipairs(datas.messages) do
        if v.id == 1 then
            local generalData = generals_pb.Generals()
            generalData:ParseFromString(v.data)
            for k,v in ipairs(generalData.generals) do
                gamedata.ext.fosterpreview2.GeneralData = gamedata:generalData(v)
            end

            gamedata:Generals({gamedata.ext.fosterpreview2.GeneralData})
        elseif v.id == 2 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            local nums = #ids.ids/6
            if (gamedata.ext.generalUireq.xlnum / 10) > nums then
                stop = 1

                for k,v in pairs(gamedata.ext.generalfosterAuto) do
                    if v.cid == 1001 then
                        v.num = 5 * nums*10
                    elseif v.cid == 20009 then
                        v.num = 1 * nums*10
                    end
                end
            end
            
            for i = 1, nums do
                status[tostring(i)] = {}
                status[tostring(i)].status = ids.ids[(i-1)*6+1] or 0
                status[tostring(i)].attribute1 = ids.ids[(i-1)*6+2] or 0
                status[tostring(i)].num1 = ids.ids[(i-1)*6+3] or 0
                status[tostring(i)].attribute2 = ids.ids[(i-1)*6+4] or 0
                status[tostring(i)].num2 = ids.ids[(i-1)*6+5] or 0
                status[tostring(i)].potential = ids.ids[(i-1)*6+6] or 0
                -- status[tostring(i)].method = ids.ids[(i-1)*7+1] or 0
                -- status[tostring(i)].attribute1 = ids.ids[(i-1)*7+2] or 0
                -- status[tostring(i)].num1 = ids.ids[(i-1)*7+3] or 0
                -- status[tostring(i)].status = ids.ids[(i-1)*7+4] or 0
                -- status[tostring(i)].attribute2 = ids.ids[(i-1)*7+5] or 0
                -- status[tostring(i)].num2 = ids.ids[(i-1)*7+6] or 0
                -- status[tostring(i)].potential = ids.ids[(i-1)*7+7] or 0
            end
        end
    end

    for k,v in pairs(gamedata.ext.generalfosterAuto) do
        if v.cid == 1001 then
            gamedata:updateRoleGold(0-v.num,"武将培养",1)
        elseif v.cid == 20009 then
            gamedata:updateprops({cid = 20009, num = 0-v.num})
        end
    end

    return { type = 1126, general = gamedata.cache.generals[gamedata.ext.generalfosterAutoid],status = status, stop = stop}
end