local ids_pb = require("ids_pb")
local tasks_pb = require"tasks_pb"
local params_pb = require("params_pb")
local somethings_pb = require("somethings_pb")
local combmessages_pb = require("combmessages_pb")

--1600
function UIMiniGameQueryCallback(uireq)
    print("request from UI", 1600,"MiniGameQuery")

    return 1, 1600, nil
end

function NetMiniGameQueryCallback(fd)
    print("request from Net", 1600,"MiniGameQuery")

    local idsData = ids_pb.Ids()
    idsData:ParseFromString(fd.rbuf)

    local data = {}
    data.nowpoint = idsData.ids[1] or 0 --本局积分
    data.maxpoint = idsData.ids[2] or 0 --最大积分
    data.allpoint = idsData.ids[3] or 0 --总积分
    data.now2048 = idsData.ids[4] or 0 --本局2048数量
    data.max2048 = idsData.ids[5] or 0 --最大2048数量
    data.all2048 = idsData.ids[6] or 0 --总2048数量
    data.count = idsData.ids[7] or 0 --游戏次数
    data.state = idsData.ids[8] or 0 --游戏开启状态
    data.gamestate = idsData.ids[9] or 0 --游戏状态
    data.endtime = idsData.ids[10] or 0 --结束时间
    data.grid = {}  --格子
    for i=1,16 do
        data.grid[i] = idsData.ids[10+i] or 0
    end

    return { type = 1600, data = data }
end

--1601 同步
function UIMiniGameSynchronizationCallback(uireq)
    print("request from UI", 1601,"MiniGameSynchronization")

    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.nowpoint)
    table.insert(idsData.ids, uireq.now2048)
    
    for i=1,16 do
        -- print("grid = ",i,uireq.grid[tostring(i)])
        table.insert(idsData.ids, uireq.grid[tostring(i)])
    end

    return 1, 1601, idsData:SerializeToString()

end

function NetMiniGameSynchronizationCallback(fd)
    print("request from Net", 1601,"MiniGameSynchronization")

    local idsData = ids_pb.Ids()
    idsData:ParseFromString(fd.rbuf)

    return { type = 1601, state = idsData.ids[1] or 0}
end

--1602 结束
function UIMiniGameOverCallback(uireq)
    print("request from UI", 1602,"MiniGameOver")

    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.nowpoint)
    table.insert(idsData.ids, uireq.now2048)

    printT(uireq.grid,"jkp-grid2")
    for i=1,16 do
        table.insert(idsData.ids, uireq.grid[tostring(i)])
    end

    return 1, 1602, idsData:SerializeToString()
end

function NetMiniGameOverCallback(fd)
    print("request from Net", 1602,"MiniGameOver")

    local idsData = ids_pb.Ids()
    idsData:ParseFromString(fd.rbuf)

    return { type = 1602, state = idsData.ids[1] or 0}
end

--1603 开始
function UIMiniGameStartCallback(uireq)
    print("request from UI", 1603,"MiniGameStart")

    return 1, 1603, nil
end

function NetMiniGameStartCallback(fd)
    print("request from Net", 1603,"MiniGameStart")

    local idsData = ids_pb.Ids()
    idsData:ParseFromString(fd.rbuf)

    return { type = 1603, state = idsData.ids[1] or 0}
end

--1604 积分兑换
function UIMiniGameExchangeCallback(uireq)
    print("request from UI", 1604,"MiniGameExchange")
    
    printT(uireq,"jkp-uireq")
    local ids = ids_pb.Ids()
    table.insert(ids.ids, uireq.pos)
    if uireq.num then
        table.insert(ids.ids, uireq.num)
    end

    return 1, 1604, ids:SerializeToString()
end

function NetMiniGameExchangeCallback(fd)
    print("request from Net", 1604,"MiniGameExchange")
    
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    return { type = 1604, reward = gamedata:SomethingProcess(getData)}
end

--1605 成就查询
function UIMiniGameAchievementCallback(uireq)
    print("request from UI", 1605,"MiniGameAchievement")
    
    return 1, 1605, nil
end

function NetMiniGameAchievementCallback(fd)
    print("request from Net", 1605,"MiniGameAchievement")

    local taskdata = tasks_pb.Tasks()
    taskdata:ParseFromString(fd.rbuf)

    local tasks = {}
    for k,v in ipairs(taskdata.tasks) do
        tasks[v.cid] = gamedata:taskData(v)
    end

    return { type = 1605, tasks = tasks}
end

--1606 成就领奖
function UIMiniGameAchievementRewardCallback(uireq)
    print("request from UI", 1606,"MiniGameAchievementReward")

    local ids = ids_pb.Ids()
    if uireq.id then
        table.insert(ids.ids, uireq.id)
    else
        table.insert(ids.ids, 1)
    end
    return 1, 1606, ids:SerializeToString()

end

function NetMiniGameAchievementRewardCallback(fd)
    print("request from Net", 1606,"MiniGameAchievementReward")
    
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    return { type = 1606, reward = gamedata:SomethingProcess(getData)}
end

--1607 排行
function UIMiniGameRankCallback(uireq)
    print("request from UI", 1607,"MiniGameRank")
    
    return 1, 1607, nil
end

function NetMiniGameRankCallback(fd)
    print("request from Net", 1607,"MiniGameRank")

    local combmsg = combmessages_pb.CombMessages()
    combmsg:ParseFromString(fd.rbuf)

    local rankData = {}
    local myRank = {}
    for k,v in ipairs(combmsg.messages) do
        if v.id == 1 then
            local params = params_pb.ParamS()
            params:ParseFromString(v.data)
            for i=1,#params.params/3 do
                local data = {}
                data.id = i
                data.rid = params.params[(i-1)*3+1].i or 0
                data.name = params.params[(i-1)*3+1].s or ""
                data.maxpoint = params.params[(i-1)*3+2].i or 0
                data.rank = params.params[(i-1)*3+3].i or 0
                table.insert(rankData,data)
            end
            
            local sortfunc = function (a,b)
                return a.id < b.id
            end
            table.sort(rankData,sortfunc)
  
        elseif v.id == 2 then
            local params = params_pb.ParamS()
            params:ParseFromString(v.data)
            myRank.rid = params.params[1].i or 0
            myRank.name = params.params[1].s or ""
            myRank.maxpoint = params.params[2].i or 0
            myRank.rank = params.params[3].i or 0
        end
    end

    return { type = 1607, rankData = rankData, myRank = myRank}
end

-- 兑换查询
function UIMiniGameExchangeQueryCallback(uireq)
    print("request from UI", 1608,"MiniGameExchangeQuery")

    return 1, 1608, nil
end

function NetMiniGameExchangeQueryCallback(fd)
    print("request from Net", 1608,"MiniGameExchangeQuery")
    
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local allpoint = ids.ids[1] or 0

    local config = gamedata.config.exchange_2048
    local exchangeData = {}
    for i=1,table.getTableLength(config) do
        exchangeData[tostring(i)] = ids.ids[1+i] or 0
    end

    return { type = 1608, allpoint = allpoint, exchangeData = exchangeData}

end