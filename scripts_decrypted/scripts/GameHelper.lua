--
-- Author: songyibo
-- Date: 2020-01-13 18:01:19
--
local ids_pb = require("ids_pb")
local combmessages_pb = require("combmessages_pb")
local somethings_pb = require("somethings_pb")

function UIGameHelperQueryCallback(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 6211, "GameHelperQuery")
    return 1, 6211, nil
end

function NetGameHelperQueryCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6211, "GameHelperQuery")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)
    local data = {task = {},challenge = {},activity = {},guild = {}}
    for k,v in ipairs(datas.messages) do
    	--副本
    	if v.id == 2 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            for i=1,7 do
                
                local id = ids.ids[i*3-2]
                local challengeTimes = ids.ids[i*3-1]
                local maxLevel = ids.ids[i*3]
                if id then
                    data.challenge[id] = {id = id,open = 1,challengeTimes = challengeTimes,maxLevel = maxLevel}
                end
            end
            for i=1,7 do
                if not data.challenge[i] then
                    data.challenge[i] = {}
                    data.challenge[i].open = 0
                    data.challenge[i].challengeTimes = 0
                    data.challenge[i].maxLevel = 0
                end
            end
        --活动
        elseif v.id == 3 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)

        	for i=1,15 do
                local id = ids.ids[i*8-7]

                if id and not data.activity[id] then
                    data.activity[id] = {}
                end
                
                --灭神殿
                if id == 1 then
                    data.activity[id].reset = ids.ids[i*8-6] or 0
                    data.activity[id].maxlevel = ids.ids[i*8-5] or 0
                    data.activity[id].endtime = ids.ids[i*8-4] or 0
                    data.activity[id].curlevel = ids.ids[i*8-3] or 0
                --观星台
                elseif id == 2 then
                    --剩余免费换星次数
                    data.activity[id].freetimes = ids.ids[i*8-6] or 0
                --蓬莱仙洞
                elseif id == 3 then
                    data.activity[id].reset = ids.ids[i*8-6] or 0
                --冠军试炼
                elseif id == 5 then
                    data.activity[id].opencount = ids.ids[i*8-6] or 0
                    data.activity[id].reset = ids.ids[i*8-5] or 0
                 --藏经阁
                elseif id == 6 then
                    data.activity[id].helpcount = ids.ids[i*8-6] or 0

                --天庭银座
                elseif id == 8 then

                    local statusStr = tostring(ids.ids[i*8-6] or 0)
                    data.activity[id].open = 1
                    data.activity[id].freeNum = 0
                    data.activity[id].awardNum = 0

                    if statusStr == "0" then
                        data.activity[id].open = 0
                    else
                        for _i=1,10 do
                            local status = tonumber(string.sub(statusStr,_i,_i))
                            if status and status == 1 then
                                data.activity[id].freeNum = data.activity[id].freeNum + 1
                            elseif status and status == 2 then
                                data.activity[id].awardNum = data.activity[id].awardNum + 1
                            end
                        end
                    end

                --竞技场
                elseif id == 9 then
                    data.activity[id].canChallengeTimes = ids.ids[i*8-6] or 0
                --好友副本
                elseif id == 10 then
                    data.activity[id].openlevel = ids.ids[i*8-6] or 0
                    data.activity[id].challengeTimes = ids.ids[i*8-5] or 0

                --过关斩将
                elseif id == 11 then
                    data.activity[id].challengeTimes = ids.ids[i*8-6] or 0
                    data.activity[id].refreshTimes = ids.ids[i*8-5] or 0
                --王的男人
                elseif id == 12 then
                    data.activity[id].openlevel = ids.ids[i*8-6] or 0
                    data.activity[id].challengeTimes = ids.ids[i*8-5] or 0
                --通缉副本
                elseif id == 13 then
                --福祉天宫
                elseif id == 14 then
                    data.activity[id].levels = {}
                    if ids.ids[i*8-6] and ids.ids[i*8-6] > 0 then
                        local statusStr = tostring(ids.ids[i*8-6])
                        for _i=1,string.len(statusStr) do
                            local level = tonumber(string.sub(statusStr,_i,_i))
                            data.activity[id].levels[_i] = level
                        end
                    end
                    data.activity[id].challengeTimes = ids.ids[i*8-5] or 0
                --通天塔
                elseif id == 15 then
                    data.activity[id].challengeTimes = ids.ids[i*8-6] or 0
                    data.activity[id].levels = {}
                    for _i=1,6 do
                        data.activity[id].levels[_i] = ids.ids[i*8-6+_i] or 0
                    end
                    
                end
            end
        --公会
        elseif v.id == 4 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
        	data.guild.inspire = ids.ids[1]
            data.guild.bossChallengeTimes = ids.ids[2]
            data.guild.bossInfo = ids.ids[3]
            --0 没有公会，1 入会时间小于1天， 2 公会等级不足， 3 可以挑战公会boss

            data.guild.gang2status = gamedata.cache.gang2status

        --天庭银座在阵武将iid
        elseif v.id == 10 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)

            if data.activity[8] then
                data.activity[8].onGenerals = {}
            else
                data.activity[8] = {}
                data.activity[8].onGenerals = {}
            end
            
            for i,v in ipairs(ids.ids) do
                table.insert(data.activity[8].onGenerals,v)
            end
    	end
    end

    gamedata.cache.gameHelperData = data
    return { type = 6211,data = data}
end

function UIGameHelperExeCallback(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 6212, "GameHelperExe")

    printT(uireq,"UIGameHelperExeCallback")


    local reqs = combmessages_pb.CombMessages()

    local ids = ids_pb.Ids()
    if uireq.params and next(uireq.params) then
        for i=1,table.getTableLength(uireq.params) do
            table.insert(ids.ids, uireq.params[tostring(i)].type)
            table.insert(ids.ids, uireq.params[tostring(i)].id)
            table.insert(ids.ids, uireq.params[tostring(i)].param1)
            table.insert(ids.ids, uireq.params[tostring(i)].param2)
            table.insert(ids.ids, uireq.params[tostring(i)].param3)
            table.insert(ids.ids, uireq.params[tostring(i)].param4)
            table.insert(ids.ids, uireq.params[tostring(i)].param5)
        end
    end

    local gameHelperExe = reqs.messages:add()
    gameHelperExe.id = 1
    gameHelperExe.data = ids:SerializeToString()


    local ids = ids_pb.Ids()
    if uireq.ext and next(uireq.ext) then
        if uireq.ext.ttyz and next(uireq.ext.ttyz) then
            for i=1,table.getTableLength(uireq.ext.ttyz) do
                table.insert(ids.ids, uireq.ext.ttyz[tostring(i)])
            end
        end
    end

    local gameHelperExe = reqs.messages:add()
    gameHelperExe.id = 2
    gameHelperExe.data = ids:SerializeToString()


    gamedata.ext.GameHelperExcParams = uireq.params
    gamedata.ext.GameHelperExcCost = uireq.cost
    gamedata.ext.GameHelperTTYZ = uireq.ext.ttyz

    return 1, 6212, reqs:SerializeToString()
end


function NetGameHelperExeCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6212, "GameHelperExe")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local data = {rewards = {},ttyzExt = {}}

    for k,v in ipairs(datas.messages) do

        print("GameHelperExeId",v.id)
        if v.id == 100 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            data.friendgift = ids.ids[1] or 0
            data.ttyzGeneralNum = ids.ids[2] or 0
            data.mieshendianResetNum = ids.ids[3] or 0
            data.mieshendianInstantlyComplete = ids.ids[4] or 0
            data.mingjiangChallengeNum = ids.ids[5] or 0
            data.tongtiantaChallengeNum = ids.ids[6] or 0
        else
            local  getData = somethings_pb.SomeThings()
            getData:ParseFromString(v.data)


            local idStr = tostring(v.id)
            local type = tonumber(string.sub(idStr,1,1))
            local id = tonumber(string.sub(idStr,2,3))
            local index = tonumber(string.sub(idStr,4,5))
            local errorcode = tonumber(string.sub(idStr,6))

            if not (errorcode and errorcode == 273 and type == 1) then
                local reward,used = gamedata:SomethingProcess(getData)
                printT(reward,"reward")
                local params = {}

                for k,v in pairs(gamedata.ext.GameHelperExcParams) do
                    if v.type == type and v.id == id then
                        params = v
                        break
                    end
                end

                table.insert(data.rewards,{type = type,id = id,index = index,errorcode = errorcode,reward = reward,used = used,params = params})

                --天庭银座上阵参数
                if type == 3 and id == 8 then
                    data.ttyzExt = gamedata.ext.GameHelperTTYZ
                elseif type == 3 and id == 15 then
                    --清除通天塔缓存
                    gamedata.cache.BabelTower = {mapData = {},levelData = {}}
                end
            end
            print("GameHelperExeP",type,id,errorcode)
        end

    end

    return { type = 6212,data = data}
end


--[[

传入 ids [2,3,4] （2 挑战助手/3 活动助手/4 公会助手）
    传出 combmessages
        id 2 挑战助手
        data ids [排序id，对应id副本今日已挑战次数，对应id副本已通关的最高关卡（id为7时，对应id副本已通关的最高关卡 计算方式 ，mapid*100+pointid）...(三位一组，表示一个副本)]

        id 3 活动助手
        data ids [排序id，参数1、参数2、参数3、参数4、参数5、参数6 ...]
            参数说明
                灭神殿     [已重置次数、可扫荡最高层数、扫荡结束时间、当前层数、0、0]
                观星台     [已换星次数、0、0、0、0、0]
                蓬莱仙洞        [已重置次数、0、0、0、0、0]
                冠军试炼        [宝箱开启次数、已重置次数、0、0、0、0]
                藏经阁     [协助次数、0、0、0、0、0]
                天庭银座        [312000000(几个关卡传几位数，0关卡未通关，1已通关无上阵武将，2已通关有上阵武将且可领取，3有上阵武将且不可领取)、0、0、0、0、0]
                竞技场       [剩余挑战次数、0、0、0、0、0]
                好友副本     [当前已通关最高关卡、0、0、0、0、0]
                王的男人     [本日Boss可扫荡的最大id、0、0、0、0、0]
                福祉天宫     [432100000(有几层传几位，0未解锁，1简单、2精英、3困难、4噩梦)、0、0、0、0、0]
                通天塔       [难度1可扫荡最高层、难度2可扫荡最高层、难度3可扫荡最高层、难度4可扫荡最高层、难度5可扫荡最高层、难度6可扫荡最高层]

        id 4 公会助手
        data ids [公会boss已鼓舞次数，玩家可挑战次数，挑战boss状态(0/1/2/3 没有公会/入会时间小于1天/公会等级不足/可以挑战公会boss)]

        id 10 天庭银座上阵武将信息
        data ids [阵位1武将iid，阵位2武将iid...... (没有传0)]


        好友副本执行
    5位一组改为7位一组

    传入
        名将副本   []
        竞技场    [购买次数]   
        好友副本  [挑战次数]
        过关斩将  [挑战难度(1/2/3 低/中/高),一键领取宝箱(0/1),一键刷新(0/1),挑战次数,刷新次数]
        王的男人  [挑战次数]
        通缉副本  []
        福祉天宫  [难度(1-6),挑战次数]
        通天塔    [难度(1-6),挑战次数]

    传出

        CombMessages
        id 100[第5位新加 名将副本挑战次数]

]]



  �3  