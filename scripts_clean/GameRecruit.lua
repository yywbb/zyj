--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-18
-- Time: 下午3:15
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")
local combmessages_pb = require("combmessages_pb")

local function mekerecruitData()
    local now = gamedata:time()
    for k,v in ipairs(gamedata.cache.generalrecruit) do
        v.propnum = gamedata.getStaffNum(gamedata.config:getConfigByName("recruit_basic")[tostring(k)].costid).num
        v.timer = v.timer -(now-v.updatetime)
        v.updatetime = now
    end
    return gamedata.cache.generalrecruit
end

function UIGeneralRecruitQueryCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1402, "GeneralRecruitQuery")
    if next(gamedata.cache.generalrecruit) then
        return 0, 1402, { type = 1402, generalrecruit = mekerecruitData()}
    else
        return 1, 1402, nil
    end
end

function NetGeneralRecruitQueryCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1402, "GeneralRecruitQuery")
    local recruitData = ids_pb.Ids()
    recruitData:ParseFromString(fd.rbuf)

    gamedata:Recruits(recruitData.ids)

    return { type = 1402, generalrecruit = mekerecruitData()}
end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function getDate(date)
    return string.sub(date,1,4),string.sub(date,5,6),string.sub(date,7,8),string.sub(date,9,10),string.sub(date,11,12),string.sub(date,13,14)
end
function checkdiscount()
    if gamedata.config:getConfigByName("recruit_tenlottery") then
        local now =  gamedata:time()
        for k,v in pairs(gamedata.config:getConfigByName("recruit_tenlottery")) do
            if v.open_type and v.open_type == 1 then
                local nowtime = gamedata:time()
                local temp = os.date("*t", gamedata.cache.role.servertime)
                local timediff1 = gamedata.cache.role.servertime + 86400*(v.days_later or 0) - nowtime - temp.hour*3600 - temp.min*60 - temp.sec
                local timediff2 = gamedata.cache.role.servertime + 86400*((v.days_later or 0)+v.continued_time) - nowtime - temp.hour*3600 - temp.min*60 - temp.sec
                if timediff1 < 0 and timediff2 > 0 then
                    return  timediff2,v.discount
                end
            else
                local isactive,resttime

                now = now or gamedata:time()
                local b_year,b_month,b_day,b_hour,b_minute,b_second = getDate(v.opentime)
                local e_year,e_month,e_day,e_hour,e_minute,e_second = getDate(v.overtime)

                local begint = os.time({year=tonumber(b_year), month=tonumber(b_month),day=tonumber(b_day),hour=tonumber(b_hour),min=tonumber(b_minute),sec=tonumber(b_second)})
                local endt = os.time({year=tonumber(e_year), month=tonumber(e_month),day=tonumber(e_day),hour=tonumber(e_hour),min=tonumber(e_minute),sec=tonumber(e_second)})

                if now>= begint and  now< endt then
                    isactive = true
                    resttime = endt-now                      --在时间范围内返回true 和剩余时间秒数
                elseif now < begint  then
                    isactive = false
                    resttime = begint-now               --没到开启时间返回false 和距离开启时间的秒数
                elseif now >= endt then
                    isactive = false
                    resttime = endt-now                 --超过结束时间返回false 和超出时间的秒数
                end
                if isactive then
                    return  resttime,v.discount
                end
            end
        end
    end
    return nil,nil
end

function UIGeneralRecruit2Callback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1403, "GeneralRecruit2")
    local Recruit = ids_pb.Ids()
    table.insert(Recruit.ids,uireq.pos)
    table.insert(Recruit.ids,uireq.method)

    local config = gamedata.config:getConfigByName("recruit_basic")[tostring(uireq.pos)]
    local data = gamedata.cache.generalrecruit[uireq.pos]

    local resttime,discount = checkdiscount()
    discount = discount and discount/10 or 1

    if uireq.pos and uireq.pos == 4 then
        discount = 1
    end

    local cdupdate = false
    local isenough, ret = true,nil
    if config.openfreerecruit == 1 then
        if uireq.method == 1 then
            if uireq.goldType == "gaojizhaomuling" then
                isenough, ret = gamedata.checkStaffEnough(config.costid,config.count,{})
            else
                isenough, ret = gamedata.checkStaffEnough(config.costid_god,config.count_god,{})
            end
        elseif uireq.method == 2 then
            if uireq.goldType == "gaojizhaomuling" then
                isenough, ret = gamedata.checkStaffEnough(config.costid,config.tentaverncount*discount,{})
            else
                isenough, ret = gamedata.checkStaffEnough(config.costid_god,config.tentaverncount_god*discount,{})
            end
        elseif uireq.method == 3 then
            isenough, ret = gamedata.checkStaffEnough(config.costid,config.hundred*discount,{})
        end
    else
        if uireq.method == 1 then
            if gamedata:time()< data.updatetime + data.timer then
                if uireq.goldType == "gaojizhaomuling" then
                    isenough, ret = gamedata.checkStaffEnough(config.costid,config.count,{})
                else
                    isenough, ret = gamedata.checkStaffEnough(config.costid_god,config.count_god,{})
                end
            else
                cdupdate=  uireq.pos
            end
        elseif uireq.method == 2 then
            if uireq.goldType == "gaojizhaomuling" then
                isenough, ret = gamedata.checkStaffEnough(config.costid,config.tentaverncount*discount,{})
            else
                isenough, ret = gamedata.checkStaffEnough(config.costid_god,config.tentaverncount_god*discount,{})
            end
        elseif uireq.method == 3 then
            isenough, ret = gamedata.checkStaffEnough(config.costid,config.hundred*discount,{})
        end
    end

    if not isenough then
        return 0, 503, ret
    end

    gamedata.ext.generalrecruit = {pos = uireq.pos, method = uireq.method,cdupdate = cdupdate, discount = discount}
    gamedata.ext.generalrecruitGoldType = uireq.goldType

    return 1, 1403, Recruit:SerializeToString()
end

local recruitresult_pb = require("recruitresult_pb")
function NetGeneralRecruit2Callback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1403, "GeneralRecruit2")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local reward,XXX,ext = {},{},{}
    local fragmentconfig = gamedata.config:getConfigByName("general_fragment")
    local gets = {}

    for k,v in ipairs(datas.messages) do
        if v.id == 2 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            for i = 1,#ids.ids/2 do
                table.insert(gets,{cid = ids.ids[2*i-1],num = ids.ids[2*i],index = math.random(1,100)})
            end
        elseif v.id == 1 then
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            reward,XXX,ext = gamedata:SomethingProcess(SomeThings,"generalrecruit")
        end
    end

    --[[
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    local reward,XXX,ext = gamedata:SomethingProcess(SomeThings,"generalrecruit")
    local fragmentconfig = gamedata.config:getConfigByName("general_fragment")
    local gets = {}

    for k,v in pairs(reward) do
        if gamedata.IDconfig(v.cid).staffType == "general" then
            v.index = math.random(1,100)
            table.insert(gets,v)
        else
            local i=1
            while fragmentconfig[tostring(v.cid)].recruit*i <= v.num do
                table.insert(gets,{cid = v.cid,num = fragmentconfig[tostring(v.cid)].recruit,order = v.order, quality = v.quality,index = math.random(1,100)})
                i=i+1
            end
        end
    end
    ]]

    local sortfunc = function(a,b) return a.index>b.index end
    table.sort(gets,sortfunc)

    local config = gamedata.config:getConfigByName("recruit_basic")[tostring(gamedata.ext.generalrecruit.pos)]
    local data = gamedata.cache.generalrecruit[gamedata.ext.generalrecruit.pos]
    local discount = gamedata.ext.generalrecruit.discount or 1

    if config.openfreerecruit == 1 then
        if gamedata.ext.generalrecruit.method == 1 then
            if gamedata.ext.generalrecruitGoldType == "gaojizhaomuling" then
                gamedata:updateStaff({cid = config.costid,num = -config.count,name = "招募pos"..gamedata.ext.generalrecruit.pos.."method"..gamedata.ext.generalrecruit.method,amount =1})
            else
                gamedata:updateStaff({cid = config.costid_god,num = -config.count_god,name = "招募pos"..gamedata.ext.generalrecruit.pos.."method"..gamedata.ext.generalrecruit.method,amount =1})
            end
            data.consumtimes = data.consumtimes + 1
        elseif gamedata.ext.generalrecruit.method == 2 then
            if gamedata.ext.generalrecruitGoldType == "gaojizhaomuling" then
                gamedata:updateStaff({cid = config.costid,num = -config.tentaverncount*discount,name = "招募pos"..gamedata.ext.generalrecruit.pos.."method"..gamedata.ext.generalrecruit.method,amount =1})
            else
                gamedata:updateStaff({cid = config.costid_god,num = -config.tentaverncount_god*discount,name = "招募pos"..gamedata.ext.generalrecruit.pos.."method"..gamedata.ext.generalrecruit.method,amount =1})
            end
            data.tentimes = data.tentimes + 1
        elseif gamedata.ext.generalrecruit.method == 3 then
            gamedata:updateStaff({cid = config.costid,num = -config.hundred*discount,name = "招募pos"..gamedata.ext.generalrecruit.pos.."method"..gamedata.ext.generalrecruit.method,amount =1})
            data.tentimes = data.tentimes + 10
        end
    else
        if gamedata.ext.generalrecruit.method == 1 then
            if gamedata.ext.generalrecruit.cdupdate then
                data.freetimes = data.freetimes + 1
                data.timer = config.cooldowntime
                data.updatetime = gamedata:time()
            else
                if gamedata.ext.generalrecruitGoldType == "gaojizhaomuling" then
                    gamedata:updateStaff({cid = config.costid,num = -config.count,name = "招募pos"..gamedata.ext.generalrecruit.pos.."method"..gamedata.ext.generalrecruit.method,amount =1})
                else
                    gamedata:updateStaff({cid = config.costid_god,num = -config.count_god,name = "招募pos"..gamedata.ext.generalrecruit.pos.."method"..gamedata.ext.generalrecruit.method,amount =1})
                end
                data.consumtimes = data.consumtimes + 1
            end
        elseif gamedata.ext.generalrecruit.method == 2 then
            if gamedata.ext.generalrecruitGoldType == "gaojizhaomuling" then
                gamedata:updateStaff({cid = config.costid,num = -config.tentaverncount*discount,name = "招募pos"..gamedata.ext.generalrecruit.pos.."method"..gamedata.ext.generalrecruit.method,amount =1})
            else
                gamedata:updateStaff({cid = config.costid_god,num = -config.tentaverncount_god*discount,name = "招募pos"..gamedata.ext.generalrecruit.pos.."method"..gamedata.ext.generalrecruit.method,amount =1})
            end
            data.tentimes = data.tentimes + 1
        elseif gamedata.ext.generalrecruit.method == 3 then
            gamedata:updateStaff({cid = config.costid,num = -config.hundred*discount,name = "招募pos"..gamedata.ext.generalrecruit.pos.."method"..gamedata.ext.generalrecruit.method,amount =1})
            data.tentimes = data.tentimes + 10
        end
    end


    return {
        type = 1403,
        method = gamedata.ext.generalrecruit.method,
        pos = gamedata.ext.generalrecruit.pos,
        generalrecruit = mekerecruitData(),
        gold = gamedata.cache.role.gold,
        gets = gets,
        ext=ext,
        reward = reward,
    }
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local recruit_pb = require("recruit_pb")
function UIGeneralRecruitCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1401, "GeneralRecruit")
    local Recruit = recruit_pb.Recruit()
    Recruit.pos = uireq.pos
    Recruit.method = uireq.method

    local recruitpropsnum = 0
    if gamedata.cache.props[20100] then
        recruitpropsnum = gamedata.cache.props[20100].num or 0
    end
    if uireq.pos == 1 then
       if recruitpropsnum < 1 and uireq.method == 1 then
            return 0, 503,{type = 503,msg = "没有足够的招募令"}
       elseif recruitpropsnum < 10 and uireq.method == 2 then
          return 0, 503,{type = 503,msg = "没有足够的招募令"}
       end
    end
    --[[ 需要判断 free 的情况
    elseif uireq.pos == 2 then
        if gamedata.cache.role.gold < 100 and uireq.method == 1 then
            return 0, 503,{type = 503,msg = "没有足够的元宝"}
        elseif gamedata.cache.role.gold < 880 and uireq.method == 2 then
            return 0, 503,{type = 503,msg = "没有足够的元宝"}
        end
    elseif uireq.pos == 3 then
        if gamedata.cache.role.gold < 300 and uireq.method == 1 then
            return 0, 503,{type = 503,msg = "没有足够的元宝"}
        elseif gamedata.cache.role.gold < 2800 and uireq.method == 2 then
            return 0, 503,{type = 503,msg = "没有足够的元宝"}
        end
    end
    ]]
    gamedata.ext.generalrecruit = {pos = uireq.pos, method = uireq.method, free = uireq.free}


    return 1, 1401, Recruit:SerializeToString()

end

local recruitresult_pb = require("recruitresult_pb")
function NetGeneralRecruitCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1401, "GeneralRecruit")

    local recruitData = recruitresult_pb.RecruitResult()
    recruitData:ParseFromString(fd.rbuf)

    local gets = {}
    local generals = gamedata:Generals(recruitData.generals,true)
    local fragments = gamedata:GeneralFragments(recruitData.fragments)
    local fragmentconfig = gamedata.config:getConfigByName("general_fragment")

    for k,v in pairs(generals) do
        table.insert(gets,{cid = v.cid,num = 1, order = 1, quality = gamedata.config:getConfigByName("general")[tostring(v.cid)].quality})
    end
    for k,v in pairs(fragments) do
        local cid = gamedata:findFragmentCid(v.cid)
        local i=1
        while fragmentconfig[tostring(cid)].recruit*i <= v.num do
            table.insert(gets,{cid = cid,num = fragmentconfig[tostring(cid)].recruit,order = 2, quality = gamedata.config:getConfigByName("general")[tostring(v.cid)].quality})
            i=i+1
        end
    end

    gamedata.sortData(gets, "order","quality","cid",nil,nil,nil,true,false,true)

    --todo  2,3
    if gamedata.ext.generalrecruit.pos == 1 then
        if gamedata.ext.generalrecruit.method == 1 then
            gamedata:updateprops({cid = 20100, num = -1})
        elseif gamedata.ext.generalrecruit.method == 2 then
            gamedata:updateprops({cid = 20100, num = -10})
        end
    elseif gamedata.ext.generalrecruit.pos == 2   then
        gamedata.cache.generalrecruit[gamedata.ext.generalrecruit.pos] = gamedata:recruitData(recruitData.status)
        --print(gamedata.cache.generalrecruit )
        --gameTimer:rigistTime("recruitTimer2",gamedata.cache.generalrecruit["2"].timer)
        if gamedata.ext.generalrecruit.free == 0 then
           if gamedata.ext.generalrecruit.method == 1 then
               gamedata:updateRoleGold(-100,"招募2",1)
           elseif gamedata.ext.generalrecruit.method == 2 then
               gamedata:updateRoleGold(-880,"招募2",10)
           end
        end
    elseif gamedata.ext.generalrecruit.pos == 3   then
        gamedata.cache.generalrecruit[gamedata.ext.generalrecruit.pos] = gamedata:recruitData(recruitData.status)
        --print(gamedata.cache.generalrecruit )
        --gameTimer:rigistTime("recruitTimer3",gamedata.cache.generalrecruit["3"].timer)
        if gamedata.ext.generalrecruit.free == 0 then
            if gamedata.ext.generalrecruit.method == 1 then
                gamedata:updateRoleGold(-300,"招募3",1)
            elseif gamedata.ext.generalrecruit.method == 2 then
                gamedata:updateRoleGold(-2800,"招募3",10)
            end
        end
    end

    local recruitpropsnum = 0
    if gamedata.cache.props[20100] then
        recruitpropsnum = gamedata.cache.props[20100].num or 0
    end
    local gold = gamedata.cache.role.gold or 0

    return {
        type = 1401,
        recruitpropsnum = recruitpropsnum,
        gold = gold,
        method = gamedata.ext.generalrecruit.method,
        pos = gamedata.ext.generalrecruit.pos,
        generalrecruit = gamedata.cache.generalrecruit,
        generals = generals,
        fragments = fragments,
        gets = gets,
    }
end

function UIGeneralRecruitShopQueryCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5321, "GeneralRecruitShopQuery")
    -- if next(gamedata.cache.generalrecruitshop) then
    --     return 0, 5321, { type = 5321, shop = gamedata.cache.generalrecruitshop}
    -- else
        return 1, 5321, nil
    --end
end

function NetGeneralRecruitShopQueryCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5321, "GeneralRecruitShopQuery")
    local recruitData = ids_pb.Ids()
    recruitData:ParseFromString(fd.rbuf)

    gamedata.cache.generalrecruitshop = {points = 0,status={}}
    gamedata.cache.generalrecruitshop.points = recruitData.ids[1]
    for k,v in ipairs(recruitData.ids) do
        if k>1 then
            gamedata.cache.generalrecruitshop.status[k-1] = v
        end
    end

    return { type = 5321, shop = gamedata.cache.generalrecruitshop}
end

function UIGeneralRecruitRewardCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5322, "GeneralRecruitReward")
    local idData = ids_pb.Ids()
    table.insert(idData.ids,uireq.id)

    gamedata.ext.generalrecruitshopid = uireq.id

    return 1, 5322, idData:SerializeToString()
end

function NetGeneralRecruitRewardCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5322, "GeneralRecruitReward")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    local reward,XXX,ext = gamedata:SomethingProcess(SomeThings)
    local id = gamedata.ext.generalrecruitshopid
    local config = gamedata.config:getConfigByName("enlist_shop")[tostring(id)]

    gamedata.cache.generalrecruitshop.points = gamedata.cache.generalrecruitshop.points-config.integral
    gamedata.cache.generalrecruitshop.status[id] = gamedata.cache.generalrecruitshop.status[id]+1

    return { 
        type = 5322, 
        shop = gamedata.cache.generalrecruitshop,
        reward = reward,
    }
end



--新10连招募
function UIRecruitNewTempQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 7110, "RecruitNewTempQuery")
    
    if not next(gamedata.cache.RecruitTempData) then
        return 1, 7110, nil
    else
        return 0,7110,{ type = 7110,data = gamedata.cache.RecruitTempData}
    end
end

function NetRecruitNewTempQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7110, "RecruitNewTempQuery")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    --status 1 上次已保存 0上次未保存
    gamedata.cache.RecruitTempData = {refreshTime = 0,status = 1,gets = {}}

    if ids.ids[1] == 0 then
        gamedata.cache.RecruitTempData.status = ids.ids[1]
        gamedata.cache.RecruitTempData.refreshTime = ids.ids[2]

        for i = 1,(#ids.ids - 2)/2 do


            local isnew = true
            local cid = ids.ids[2 + 2*i-1]
            local num = ids.ids[2 + 2*i]
            for i2,v2 in pairs(gamedata.cache.generals) do

                local originCid = gamedata.getOriginCid(v2.cid)
                if originCid == cid then
                    isnew = false
                    break
                end
            end
            table.insert(gamedata.cache.RecruitTempData.gets,{cid = cid,num = num,isnew = isnew,index = math.random(1,100)})
        end
    end

    return { 
        type = 7110,
        data = gamedata.cache.RecruitTempData
    }
end


function UIRecruitNewCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 7111, "RecruitNewCallBack")
    

    local config = gamedata.config:getConfigByName("recruit_basic")["4"]

    local discount = 1
    local isenough, ret = true,nil

    if uireq.goldType == "gaojizhaomuling" then
        isenough, ret = gamedata.checkStaffEnough(config.costid,config.tentaverncount*discount,{})
    else
        isenough, ret = gamedata.checkStaffEnough(config.costid_god,config.tentaverncount_god*discount,{})
    end

    
    if not isenough then
        return 0, 503, ret
    end

    gamedata.ext.generalrecruitNewGoldType = uireq.goldType

    return 1, 7111, nil
    
end

function NetRecruitNewCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7111, "RecruitNewCallBack")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local gets = {}

    for i = 1,#ids.ids/2 do
        local isnew = true
        local cid = ids.ids[2*i-1]
        local num = ids.ids[2*i]
        for i2,v2 in pairs(gamedata.cache.generals) do

            local originCid = gamedata.getOriginCid(v2.cid)
            if originCid == cid then
                isnew = false
                break
            end
        end
        table.insert(gets,{cid = cid,num = num,isnew = isnew,index = math.random(1,100)})
    end

    gamedata.cache.RecruitTempData.gets = gets
    gamedata.cache.RecruitTempData.status = 0


    local config = gamedata.config:getConfigByName("recruit_basic")["4"]
    local discount = 1

    if gamedata.ext.generalrecruitNewGoldType == "gaojizhaomuling" then
        gamedata:updateStaff({cid = config.costid,num = -config.tentaverncount*discount,name = "封神招募10连招募令",amount =1})
    else
        gamedata:updateStaff({cid = config.costid_god,num = -config.tentaverncount_god*discount,name = "封神招募10连元宝",amount =1})
    end

    return { 
        type = 7111,
        data = gamedata.cache.RecruitTempData
    }
end

function UIRecruitNewRefreshCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 7112, "RecruitNewRefresh")

    local buycount_price = gamedata.config.buycount_price[tostring(gamedata.cache.RecruitTempData.refreshTime + 1)] and gamedata.config.buycount_price[tostring(gamedata.cache.RecruitTempData.refreshTime + 1)].modify_price or gamedata.config.buycount_price[tostring(table.getTableLength(gamedata.config.buycount_price))].modify_price

    gamedata.ext.RecruitNew_price = buycount_price

    local isenough, ret = gamedata.checkStaffEnough(1001,buycount_price,{})

    if isenough then
        return 1, 7112, nil
    else
        return 0, 503, ret
    end
end

function NetRecruitNewRefreshCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7112, "RecruitNewRefresh")
   
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local gets = {}

    for i = 1,#ids.ids/2 do

        local isnew = true
        local cid = ids.ids[2*i-1]
        local num = ids.ids[2*i]
        for i2,v2 in pairs(gamedata.cache.generals) do
            
            local originCid = gamedata.getOriginCid(v2.cid)
            if originCid == cid then
                isnew = false
                break
            end
        end
        table.insert(gets,{cid = cid,num = num,isnew = isnew,index = math.random(1,100)})
    end

    gamedata.cache.RecruitTempData.gets = gets
    gamedata.cache.RecruitTempData.status = 0
    gamedata.cache.RecruitTempData.refreshTime = gamedata.cache.RecruitTempData.refreshTime + 1

    gamedata:updateStaff({cid = 1001,num = - gamedata.ext.RecruitNew_price})

    return { 
        type = 7112,
        data = gamedata.cache.RecruitTempData
    }
end

function UIRecruitNewTempSaveCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 7113, "RecruitNewTempSave")
    
    return 1, 7113, nil
end

function NetRecruitNewTempSaveCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7113, "RecruitNewTempSave")
  
    local reward,XXX,ext = {},{},{}

    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)
    reward,XXX,ext = gamedata:SomethingProcess(getData,"generalrecruit")

    gamedata.cache.RecruitTempData.status = 1
    gamedata.cache.RecruitTempData.gets = {}
    gamedata.cache.RecruitTempData.refreshTime = 0

    return {
        type = 7113,
        data = gamedata.cache.RecruitTempData,
        reward = reward,
    }
end

