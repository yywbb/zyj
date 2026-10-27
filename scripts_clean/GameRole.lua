


local role_param = ""
function UIRoleInfoCallBack(uireq)
    print("请求角色信息1001 接收UI请求")
    role_param = uireq.param or ""
    if (next(gamedata.cache.role) == nil or (not gamedata.cache.role.id) or role_param == "error" or role_param == "resume") then
        return 1, 1001, nil
    elseif uireq.param then
        local now = gamedata:time()
        if gamedata.cache.role.stamina >= gamedata.cache.role.maxstamina then
            gamedata.cache.role.staminanext = 0
            gamedata.cache.role.staminaall = 0
        else
            gamedata.cache.role.staminanext = gamedata.cache.role.staminanext - (now - gamedata.ext.RoleDataReceiveTime)
            gamedata.cache.role.staminaall = gamedata.cache.role.staminaall - (now - gamedata.ext.RoleDataReceiveTime)
        end
        if gamedata.cache.role.energy >= gamedata.cache.role.maxenergy then
            gamedata.cache.role.energynext = 0
            gamedata.cache.role.energyall = 0
        else
            gamedata.cache.role.energynext = gamedata.cache.role.energynext - (now - gamedata.ext.RoleDataReceiveTime)
            gamedata.cache.role.energyall = gamedata.cache.role.energyall - (now - gamedata.ext.RoleDataReceiveTime)
        end
        if gamedata.cache.role.stamina < gamedata.cache.role.maxstamina and gamedata.cache.role.staminanext <=0 then return 1, 1001, nil end
        if gamedata.cache.role.stamina < gamedata.cache.role.maxstamina and gamedata.cache.role.staminaall <=0 then return 1, 1001, nil end
        if gamedata.cache.role.energy < gamedata.cache.role.maxenergy and gamedata.cache.role.energynext <=0 then return 1, 1001, nil end
        if gamedata.cache.role.energy < gamedata.cache.role.maxenergy and gamedata.cache.role.energyall <=0 then return 1, 1001, nil end
        
        gamedata.ext.RoleDataReceiveTime = gamedata:time()
        return 0, 1001, { type = 1001, info = gamedata.cache.role, param = role_param}
    else
        return 0, 1001, { type = 1001, info = gamedata.cache.role, param = role_param}
    end
end

local role_pb = require("role_pb")
function NetRoleInfoCallBack(fd)
    print("请求角色信息1001 接收服务器返回数据")
    local result = role_pb.Role()
    result:ParseFromString(fd.rbuf)

    if gamedata and (not gamedata.cache.role.id) then
        UIReponse({ type = 100010, roleId = result.id})
    end

    gamedata:RoleData(result, gamedata.role.uuid)
    gamedata.ext.RoleDataReceiveTime = gamedata:time()

    local role_param_t = role_param
    role_param = ""

    return { type = 1001, info = gamedata.cache.role, param = role_param_t}

end

function UIRoleQueryCallBack(uireq)
    print("请求角色信息10011 接收UI请求")

    return 0, 10011, { type = 10011, info = gamedata.cache.role, order = uireq.order }
end

function UIRoleLevelUpCallBack(uireq)
    print("请求角色信息10012 接收UI请求")

    if gamedata.ext.roleextcoin then
        gamedata.cache.role.coin = gamedata.ext.roleextcoin
        gamedata.ext.roleextcoin = nil
    end

    if gamedata.ext.roleextgold then
        gamedata.cache.role.gold = gamedata.ext.roleextgold
        gamedata.ext.roleextgold = nil
    end

    return 0, 10012, { type = 10012, info = gamedata.cache.role, param= "" }
end

function UIrechargeONCallBack(uireq)
    print("请求角色信息11501 接收UI请求")

    gamedata.ext.isrechare = true

    return 0, 11501 , { type = 11501 }
end

function UIrechargeOFFCallBack(uireq)
    print("请求角色信息11601 接收UI请求")

    gamedata.ext.isrechare = false

    return 0, 11601 , { type = 11601 }
end

function UIRoleInfoBasicCallBack(uireq)
    return 1,999902,nil
end

local ids_pb = require("ids_pb")
function NetRoleInfoBasic(fd)
    local info = ids_pb.Ids()
    info:ParseFromString(fd.rbuf)
    local msg = ""
    local err = ""

    if gamedata.ext.isrechare then
         return {type = 999902, msg = msg, err = err }
    end

    if not gamedata.cache.role or not next(gamedata.cache.role) or not gamedata.cache.role.id then
    else
        if gamedata.cache.role.stamina ~= info.ids[1] then
            err = "stamina error: server = "..info.ids[1].."client = "..gamedata.cache.role.stamina.."last opt = "..(NetLastResponseType or "")
            msg = "体力不同步"
            gamedata.cache.role.stamina = info.ids[1]
        end

        if gamedata.cache.role.energy ~= info.ids[2] then
            err = "energy error: server = "..info.ids[2].."client = "..gamedata.cache.role.energy.."last opt = "..(NetLastResponseType or "")
            msg = "精力不同步"
            gamedata.cache.role.energy = info.ids[2]
        end

        if  gamedata.cache.role.coin ~= info.ids[3] then--gamedata.ext.roleextcoin or
            err = "coin error: server = "..info.ids[3].."client = "..gamedata.cache.role.coin.."last opt = "..(NetLastResponseType or "")
            msg = "银币不同步"
            gamedata.cache.role.coin = info.ids[3]
        end

        if  gamedata.cache.role.gold ~= info.ids[4] then--gamedata.ext.roleextgold or
            err = "gold error: server = "..info.ids[4].."client = "..gamedata.cache.role.gold.."last opt = "..(NetLastResponseType or "")
            msg = "元宝不同步"
            gamedata.cache.role.gold = info.ids[4]
        end
    end

    return {type = 999902, msg = msg, err = err }

end


function UIProtagonistQueryCallBack(uireq)
    print("请求角色信息1050 接收UI请求")
    if (next(gamedata.cache.protagonist) == nil) then
        return 1, 1050, nil
    elseif uireq.param and uireq.param == "update" then
        return 1, 1050, nil
    else
        return 0, 1050, { type = 1050, protagonist = gamedata.cache.protagonist}
    end
end

local protagonist_pb = require("protagonist_pb")
function NetProtagonistQueryCallBack(fd)
    print("请求角色信息1050 接收服务器返回数据")
    local protagonist = protagonist_pb.Protagonist()
    protagonist:ParseFromString(fd.rbuf)

    gamedata:Protagonist(protagonist)

    return { type = 1050, protagonist = gamedata.cache.protagonist}

end

local ids_pb = require("ids_pb")
function UIProtagonistAddAttrCallBack(uireq)
    print("主角1051 接收UI请求")

    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.num1 or 0)
    table.insert(idsData.ids, uireq.num2 or 0)
    table.insert(idsData.ids, uireq.num3 or 0)

    return 1, 1051, idsData:SerializeToString()

end


function NetProtagonistAddAttrCallBack(fd)
    print("主角1051 接收服务器返回数据")

    local protagonist = protagonist_pb.Protagonist()
    protagonist:ParseFromString(fd.rbuf)
    gamedata:Protagonist(protagonist)

    return { type = 1051, protagonist = gamedata.cache.protagonist}

end

function UIProtagonistGrowUpCallBack(uireq)
    print("主角1052 接收UI请求")

    return 1, 1052, nil

end

local slots_pb = require("slots_pb")
function NetProtagonistGrowUpCallBack(fd)
    print("主角1052 接收服务器返回数据")
    local info = slots_pb.SlotS()
    info:ParseFromString(fd.rbuf)

    gamedata:SlotInfoProcess(info)

    gamedata.cache.role.profile = gamedata.cache.protagonist.general.cid

    return { type = 1052, protagonist = gamedata.cache.protagonist}

end

function UIProtagonistRecoverTrainCallBack(uireq)
    print("主角1053 接收UI请求")

    if uireq.xgold and uireq.xgold+0 > gamedata.cache.role.gold then
        return 0,503,{type = 503, msgtype = "shortgold" }
    end
    gamedata.ext.ProtagonistRecoverTrainGold = uireq.xgold

    return 1, 1053, nil

end

function NetProtagonistRecoverTrainCallBack(fd)
    print("主角1053 接收服务器返回数据")
    local protagonist = protagonist_pb.Protagonist()
    protagonist:ParseFromString(fd.rbuf)

    gamedata:Protagonist(protagonist)
    gamedata:updateRoleGold(0-(gamedata.ext.ProtagonistRecoverTrainGold or 0),"购买主角培养点",1)

    gamedata.cache.vipstatus.b_train  = gamedata.cache.vipstatus.b_train +1

    return { type = 1053, protagonist = gamedata.cache.protagonist, vipstatus= gamedata.cache.vipstatus}

end

------------------------------------------------------------------------------------------------------

function makeMogongHint()

    mekehintext(115,0)
    local growconfig = gamedata.config.protagonist_grow
    --local xid = tonumber(gamedata.config.global_kv.protagonist_add_propcid.value) or 20161
    local data = gamedata.cache.protagonist
    
    printT(data,"protagonist")
    local xid = 20161
    if growconfig[tostring(data.level2+1)] and growconfig[tostring(data.level2+1)]["atk_cost"] then
        xid = tonumber(growconfig[tostring(data.level2+1)]["atk_cost"]) or 20161
    end

    if growconfig[tostring(data.level2+1)] and data.atk_a >= growconfig[tostring(data.level2+1)].atk and data.def_a >= growconfig[tostring(data.level2+1)].def and data.hp_a >= growconfig[tostring(data.level2+1)].hp then
        local Protagonist2GrowupXprop = gamedata.getIDandNUMs(growconfig[tostring(data.level2+1)]["consume"])
        for k,v in pairs(Protagonist2GrowupXprop) do
            if v.cid == 1000 then
                if v.num > gamedata.cache.role.coin then
                   return
                end
            elseif v.cid == 1001 then
                if v.num > gamedata.cache.role.gold then
                    return
                end
            elseif v.cid >= 20001 and v.cid <= 21000 then
                if not gamedata.cache.props[v.cid] or gamedata.cache.props[v.cid].num < v.num then
                    return
                end
            end
        end
    else
        if not growconfig[tostring(data.level2+1)] then
            return
        end

        if not gamedata.cache.props[xid] or  gamedata.cache.props[xid].num <30 then
            return
        end
    end
    mekehintext(115,1)
end


function UIUserProtagonist2CallBack(uireq)
    print("主角1054 接收UI请求")

    if (next(gamedata.cache.protagonist) == nil) then
        return 1, 1054, nil
    elseif uireq.param and uireq.param == "update" then
        return 1, 1054, nil
    else
        --local xid = tonumber(gamedata.config.global_kv.protagonist_add_propcid.value) or 20161
        local xid = 20161
        if gamedata.config.protagonist_grow[tostring(gamedata.cache.protagonist.level2+1)] and gamedata.config.protagonist_grow[tostring(gamedata.cache.protagonist.level2+1)]["atk_cost"] then
            xid = tonumber(gamedata.config.protagonist_grow[tostring(gamedata.cache.protagonist.level2+1)]["atk_cost"]) or 20161
        end
        return 0, 1054, { type = 1054, protagonist = gamedata.cache.protagonist, xhasnum = gamedata.cache.props[xid] and gamedata.cache.props[xid].num or 0}
    end

end

function NetUserProtagonist2CallBack(fd)
    print("主角1054 接收服务器返回数据")

    --local xid = tonumber(gamedata.config.global_kv.protagonist_add_propcid.value) or 20161

    local protagonist = protagonist_pb.Protagonist()
    protagonist:ParseFromString(fd.rbuf)

    gamedata:Protagonist(protagonist)

    local xid = 20161
    if gamedata.config.protagonist_grow[tostring(gamedata.cache.protagonist.level2+1)] and gamedata.config.protagonist_grow[tostring(gamedata.cache.protagonist.level2+1)]["atk_cost"] then
        xid = tonumber(gamedata.config.protagonist_grow[tostring(gamedata.cache.protagonist.level2+1)]["atk_cost"]) or 20161
    end

    return { type = 1054, protagonist = gamedata.cache.protagonist, xhasnum = gamedata.cache.props[xid] and gamedata.cache.props[xid].num or 0}

end



function UIUserProtagonist2AddAttrCallBack(uireq)
    print("主角1055 接收UI请求")

    gamedata.ext.Protagonist2AddXnum = uireq.xnum or 0
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.typenum or 1)
    table.insert(idsData.ids, uireq.num or 1)

    return 1, 1055, idsData:SerializeToString()

end

function NetUserProtagonist2AddAttrCallBack(fd)
    print("主角1055 接收服务器返回数据")
    --local xid = tonumber(gamedata.config.global_kv.protagonist_add_propcid.value) or 20161

    local protagonist = protagonist_pb.Protagonist()
    protagonist:ParseFromString(fd.rbuf)
    gamedata:Protagonist(protagonist)

    local xid = 20161
    if gamedata.config.protagonist_grow[tostring(gamedata.cache.protagonist.level2+1)] and gamedata.config.protagonist_grow[tostring(gamedata.cache.protagonist.level2+1)]["atk_cost"] then
        xid = tonumber(gamedata.config.protagonist_grow[tostring(gamedata.cache.protagonist.level2+1)]["atk_cost"]) or 20161
    end

    --local xid = tonumber(gamedata.config.protagonist_grow[tostring(gamedata.cache.protagonist.level2+1)]["atk_cost"]) or 20161
    if gamedata.ext.Protagonist2AddXnum and gamedata.ext.Protagonist2AddXnum > 0 then
        gamedata:updateprops({cid = xid, num = 0-gamedata.ext.Protagonist2AddXnum})
    end

    return { type = 1055, protagonist = gamedata.cache.protagonist, xhasnum = gamedata.cache.props[xid] and gamedata.cache.props[xid].num or 0}

end




function UIUserProtagonist2GrowupPreveiwCallBack(uireq)
    print("主角1056 接收UI请求")

    return 1, 1056, nil

end

local generals_pb = require("generals_pb")
function NetUserProtagonist2GrowupPreveiwCallBack(fd)
    print("主角1056 接收服务器返回数据")

    local GeneralsData = generals_pb.Generals()
    GeneralsData:ParseFromString(fd.rbuf)
    gamedata:ProtagonistPreveiw(GeneralsData.generals)

    return { type = 1056, protagonist = gamedata.cache.protagonist, protagonistpreveiw = gamedata.cache.protagonistPreveiw}

end




function UIUserProtagonist2GrowupCallBack(uireq)
    print("主角1057 接收UI请求")

    local GeneralBreakData = ids_pb.Ids()
    table.insert(GeneralBreakData.ids, uireq.scope or 0)


    gamedata.ext.Protagonist2GrowupXprop = {}
    if uireq.xstr then
        gamedata.ext.Protagonist2GrowupXprop = gamedata.getIDandNUMs(uireq.xstr) or {}

        for k,v in pairs(gamedata.ext.Protagonist2GrowupXprop) do
            if v.cid == 1000 then
               if v.num > gamedata.cache.role.coin then
                   --return 0,503,{type = 503, msg = "银币不足"}
                    return  0, 503, {type = 503, msgtype = "shortcoin"}
               end
            elseif v.cid == 1001 then
                if v.num > gamedata.cache.role.gold then
                    return 0,503,{type = 503, msg = "元宝不足"}
                end
            elseif v.cid >= 20001 and v.cid <= 21000 then
                if not gamedata.cache.props[v.cid] or gamedata.cache.props[v.cid].num < v.num then
                    return 0,503,{type = 503, msg = "进阶道具不足"}
                end
            end
        end

    end

    return 1, 1057, GeneralBreakData:SerializeToString()

end

function NetUserProtagonist2GrowupCallBack(fd)
    print("主角1057 接收服务器返回数据")
    --local xid = tonumber(gamedata.config.global_kv.protagonist_add_propcid.value) or 20161

    local info = slots_pb.SlotS()
    info:ParseFromString(fd.rbuf)

    gamedata:SlotInfoProcess(info)

    gamedata.cache.role.profile = gamedata.cache.protagonist.general.cid

    for k,v in pairs(gamedata.ext.Protagonist2GrowupXprop) do
        if v.cid == 1000 then
            gamedata:updateRoleCoin(0-v.num)
        elseif v.cid == 1001 then
            gamedata:updateRoleGold(0-v.num)
        elseif v.cid >= 20001 and v.cid <= 21000 then
            gamedata:updateprops({cid = v.cid, num = 0-v.num})
        end
    end

    local xid = 20161
    if gamedata.config.protagonist_grow[tostring(gamedata.cache.protagonist.level2+1)] and gamedata.config.protagonist_grow[tostring(gamedata.cache.protagonist.level2+1)]["atk_cost"] then
        xid = tonumber(gamedata.config.protagonist_grow[tostring(gamedata.cache.protagonist.level2+1)]["atk_cost"]) or 20161
    end
    return { type = 1057, protagonist = gamedata.cache.protagonist, xhasnum = gamedata.cache.props[xid] and gamedata.cache.props[xid].num or 0}

end

--[[
[203] = UIChangeGenderCallBack,
[204] = UIGenderQueryCallBack,
]]


function UIChangeGenderCallBack(uireq)
    print("203 接收UI请求")

    gamedata.ext.changeGenderGold = uireq.goldnum or 0

    if gamedata.ext.changeGenderGold > gamedata.cache.role.gold then
        return 0,503,{type = 503, msg = "元宝不足"}
    end

    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.gender or 1)

    return 1, 203, idsData:SerializeToString()

end

function NetChangeGenderCallBack(fd)
    print("203 接收服务器返回数据")

    local info = slots_pb.SlotS()
    info:ParseFromString(fd.rbuf)

    gamedata:SlotInfoProcess(info)

    gamedata.cache.role.profile = gamedata.cache.protagonist.general.cid

    if gamedata.ext.changeGenderGold and gamedata.ext.changeGenderGold > 0 then
        gamedata:updateRoleGold(0-gamedata.ext.changeGenderGold)
    end

    return { type = 203 }

end


function UIGenderQueryCallBack(uireq)
    print("204 接收UI请求")

    return 1, 204, nil

end

function NetGenderQueryCallBack(fd)
    print("204 接收服务器返回数据")

    local GenderData = ids_pb.Ids()
    GenderData:ParseFromString(fd.rbuf)

    local gender = GenderData.ids[1] or 1

    return { type = 204, gender = gender  }

end

function UIOnlinetimeQueryCallBack(uireq)
    print("5340 接收UI请求")

    return 1, 5340, nil

end

function NetOnlinetimeQueryCallBack(fd)
    print("5340 接收服务器返回数据")

    local Data = ids_pb.Ids()
    Data:ParseFromString(fd.rbuf)

    local status = Data.ids[1] or 2
    local time = Data.ids[2] or 0
    local isten = Data.ids[3] or 0

    return { type = 5340, status = status, time=time ,isten = isten}

end

function UIRealnameRewardQueryCallBack(uireq)
    print("5341 接收UI请求")

    return 1, 5341, nil

end

function NetRealnameRewardQueryCallBack(fd)
    print("5341 接收服务器返回数据")

    local Data = ids_pb.Ids()
    Data:ParseFromString(fd.rbuf)

    return { type = 5341, status = Data.ids[1] or 0}
end

function UIRealnameRewardCallBack(uireq)
    print("5342 接收UI请求")

    return 1, 5342, nil

end

function NetRealnameRewardCallBack(fd)
    print("5342 接收服务器返回数据")
    local propuseData = somethings_pb.SomeThings()
    propuseData:ParseFromString(fd.rbuf)

    local reward = gamedata:SomethingProcess(propuseData)

    return { type = 5342, reward = reward}
end

function NetUserKickCallBack(fd)
    print("5347 接收服务器返回数据")
    local Data = ids_pb.Ids()
    Data:ParseFromString(fd.rbuf)

    return { type = 5347, status = Data.ids[1] or 0}
end

