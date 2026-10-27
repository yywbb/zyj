--
-- Created by IntelliJ IDEA.
-- User: jutian
-- Date: 15/3/13
-- Time: 下午5:22
-- To change this template use File | Settings | File Templates.
--

local socket = require("socket")
function roleexpEx()
    if gamedata.config.general_slot and gamedata.config.general_cheer then return end
    local rolejson = gamedata.config.role_exp
    local general_slot = {}
    local general_cheer = {}

    for i=1 , table.getTableLength(rolejson) do
        for k=table.getTableLength(general_slot), rolejson[tostring(i)].slotnum do
            if not general_slot[tostring(k)] and k~=0 then
                general_slot[tostring(k)] = i
            end
        end

        for j=table.getTableLength(general_cheer), rolejson[tostring(i)].cheernum do
            if not general_cheer[tostring(j)] and j~=0 then
                general_cheer[tostring(j)] = i
            end
        end
    end

    gamedata.config.general_slot = general_slot
    gamedata.config.general_cheer = general_cheer

    --printT(general_slot)
    --printT(general_cheer)
end

local ext_req = {8110,8101,8105,8109}
local combmessages_pb = require("combmessages_pb")
function UICombMessagesCallback(uireq)
    roleexpEx()
    cclog("NET type:%d cmd:%s recv request from UI", 999900, "CombMessages")
    local reqs = combmessages_pb.CombMessages()

    if uireq.order and (uireq.order == "datainit") then
        local reqsTb = {}
        for i,v in ipairs(ext_req) do
            reqsTb[tostring(table.getTableLength(reqsTb) + 1)] = v
        end
        for i=1,table.getTableLength(uireq.reqs) do
            reqsTb[tostring(table.getTableLength(reqsTb) + 1)] = uireq.reqs[tostring(i)]
        end
        uireq.reqs = reqsTb
    end
    
    printT(uireq.reqs,"uireq.reqs")
    for i=1,table.getTableLength(uireq.reqs) do
        local v =  uireq.reqs[string.format("%d",i)]
        
        if type(v) == "number" then
            local req = reqs.messages:add()
            req.id = v
        else
            local func = game_ui_callback[v.type]
            if nil ~= func then
                local status, typenum, data = func(v)
                print(status,typenum)
                if status == 0 then 
                    UIReponse(data)
                else
                    local req = reqs.messages:add()
                    req.id = v.type
                    if data then
                        req.data = data
                    end                    
                end
            else
                local req = reqs.messages:add()
                req.id = v.type   
            end
        end
    end

    if #reqs.messages <= 0 then
        return 0,999900,{type=999900, order = uireq.order or ""}
    end

    gamedata.ext.combmessageOrder = uireq.order or ""
    return 1,999900,reqs:SerializeToString()
end
local uiqueue = require("uiqueue")
function NetCombMessagesCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 999900, "CombMessages")
    local reps = combmessages_pb.CombMessages()
    reps:ParseFromString(fd.rbuf)

    if gamedata.ext.combmessageOrder == "cachereset" then
        gamedata:cachereset()
    end

    local index =0
    for k,v in ipairs(reps.messages) do
        fd.type = v.id
        fd.rbuf = v.data
        --game_net_callback
        local func = game_net_callback[fd.type]
        local uirep,bcall = nil,false

        -- 1.先进行网络处理：pb to table, 缓存更新等等
        if nil ~= func then
            local func1,func2 = func,__G_TRACKBACK__
            if type(func) == "table" then
                func1 = func[1]
                if #func > 1 then
                    func2 = func[2]
                end
            end
            bcall,uirep = xpcall(function() return func1(fd) end, func2)
            if not bcall then
                cclog("[Error]GameLoop Net Reponse Process Error");
            end
        else
            cclog("Warn netcallbacks not reg callback ID:%d", fd.type)
        end
        cclog("# Check response data from net callbacks. Has data: %s", nil ~= uirep);
        if nil ~= uirep and "" ~= uirep then
            --local t1 = socket.gettime()
            --海外版使用的是UIResponsByJson
            uiqueue.setresponsetoui(uirep)
            --print(socket.gettime() - t1, "setresponsetoui time",uirep.type)
        end
        if gamedata.ext.combmessageOrder == "datainit" then
            index = index+1
            uiqueue.setresponsetoui({type = 999909,index = index,total = #reps.messages})
        end
    end
    return {type=999900, order = gamedata.ext.combmessageOrder}
end
