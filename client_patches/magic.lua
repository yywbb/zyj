-- Serialize queries and mutations; a preview is bound to its own magic and token.
local ids_pb = require("ids_pb")
local slots_pb = require("slots_pb")
local comb_pb = require("combmessages_pb")

local function ids(raw)
    local data = ids_pb.Ids()
    data:ParseFromString(raw)
    return data.ids
end

local function item(id)
    for _,value in pairs(gamedata.cache.magicdata.unlock) do
        if value.id == id then return value end
    end
end

local function costs(id,method,breakthrough)
    local current = item(id)
    local stage = current and current.istupo or 0
    local row = gamedata.config.artifact_xian_config[tostring(id)][tostring(breakthrough and stage+1 or math.max(1,stage))]
    local text = breakthrough and row.breach_consume or (stage > 0 and row["forging_consume"..method] or gamedata.config.global_kv["artifact_consume_"..method].value)
    return gamedata.getIDandNUMs(text)
end

local function charge(rows,count)
    for _,row in pairs(rows) do
        local amount = -row.num*count
        if row.cid == 1000 then gamedata:updateRoleCoin(amount)
        elseif row.cid == 1001 then gamedata:updateRoleGold(amount,"法宝锻造",1)
        elseif row.cid == 1025 then gamedata:updateRoleG_gold(amount)
        else gamedata:updateprops({cid=row.cid,num=amount}) end
    end
end

local function send(opcode,req,values,rows)
    if gamedata.ext.localMagicBusy then
        return 0,503,{type=503,msg="法宝正在结算，请等待回复；超时请重进游戏"}
    end
    for _,row in pairs(rows or {}) do
        local balance = row.cid == 1000 and gamedata.cache.role.coin or row.cid == 1001 and gamedata.cache.role.gold
            or row.cid == 1025 and gamedata.cache.role.g_gold or (gamedata.cache.props[row.cid] and gamedata.cache.props[row.cid].num or 0)
        if (balance or 0) < row.num*(req.times or req.xlnum or 1) then return 0,503,{type=503,msg="法宝锻造资源不足"} end
    end
    local data = ids_pb.Ids()
    for _,value in ipairs(values) do table.insert(data.ids,value) end
    gamedata.ext.localMagicBusy = {opcode=opcode,id=req.id or req.iid or -1,view=req.view,window=req.window,method=req.typeIndex or req.method,
        keep=req.typeIndex,rows=rows}
    return 1,opcode,data:SerializeToString()
end

local function receive(opcode)
    local req = gamedata.ext.localMagicBusy
    assert(req and req.opcode == opcode,"Unexpected magic response")
    return req
end

local function slots(raw)
    local data = slots_pb.SlotS()
    data:ParseFromString(raw)
    gamedata:SlotInfoProcess(data)
end

function UIInstrumentQueryCallback(req) return send(1360,req,{}) end
function NetInstrumentQueryCallback(fd)
    local req = receive(1360)
    gamedata:magic(ids(fd.rbuf))
    gamedata.ext.localMagicBusy = nil
    return {type=1360,id=req.id,view=req.view,data=gamedata.cache.magicdata,stoneNum=gamedata.cache.props[20270] and gamedata.cache.props[20270].num or 0,
        rolelv=gamedata.cache.role.level,g_goldNum=gamedata.cache.role.g_gold or 0}
end

function UIInstrumentUnlockCallback(req) return send(1361,req,{req.id}) end
function NetInstrumentUnlockCallback(fd)
    local req = receive(1361)
    slots(fd.rbuf)
    gamedata.ext.localMagicBusy = nil
    return {type=1361,id=req.id,view=req.view}
end

function UIInstrumentForgePreview(req)
    local method = req.typeIndex or 0
    return send(1362,req,{req.id,method,req.times or 0},method > 0 and costs(req.id,method) or {})
end
function NetInstrumentForgePreview(fd)
    local req, data = receive(1362), ids(fd.rbuf)
    assert(#data == 9,"Invalid magic preview")
    charge(req.rows,data[6])
    local candidate = {}
    for i=1,4 do candidate[tostring(i)] = data[i] end
    gamedata.ext.localMagicPreviews = gamedata.ext.localMagicPreviews or {}
    gamedata.ext.localMagicPreviews[req.id] = {values=candidate,token=data[5],stage=data[9]}
    gamedata.ext.localMagicBusy = nil
    return {type=1362,id=req.id,view=req.view,token=data[5],restored=req.method == 0,data={data=candidate,token=data[5],
        requestData={id=req.id,typeIndex=data[7],times=data[8],tuPoStatus=data[9]},magicdata=gamedata.cache.magicdata,
        num=gamedata.cache.props[20270] and gamedata.cache.props[20270].num or 0,g_goldNum=gamedata.cache.role.g_gold or 0}}
end

function UIInstrumentForgeConfirm(req)
    if not req.id or not req.token or req.token <= 0 then return 0,503,{type=503,msg="请重新打开当前法宝查看预览"} end
    return send(1363,req,{req.typeIndex,req.id,req.token})
end
function NetInstrumentForgeConfirm(fd)
    local req = receive(1363)
    local pending = gamedata.ext.localMagicPreviews and gamedata.ext.localMagicPreviews[req.id]
    assert(pending,"Missing bound magic preview")
    slots(fd.rbuf)
    if req.keep == 1 then
        local current = assert(item(req.id),"Missing magic")
        for i=1,4 do current["attr"..(i+(pending.stage > 0 and 4 or 0))] = pending.values[tostring(i)] end
    end
    gamedata.ext.localMagicPreviews[req.id] = nil
    gamedata.ext.localMagicBusy = nil
    return {type=1363,id=req.id,view=req.view,isChage=req.keep}
end

function UIInstrumentForgeAutomaticCallback(req)
    if not req.xlnum or req.xlnum < 1 or req.xlnum % 1 ~= 0 then return 0,503,{type=503,msg="自动锻造次数须为正整数"} end
    return send(1364,req,{req.iid,req.method,req.xlnum,req.status1 or 0,req.status2 or 0,req.status3 or 0,req.status4 or 0,req.status5 or 0},costs(req.iid,req.method))
end
function NetInstrumentForgeAutomaticCallback(fd)
    local req, data = receive(1364), comb_pb.CombMessages()
    data:ParseFromString(fd.rbuf)
    local rows, counts
    for _,part in ipairs(data.messages) do
        if part.id == 1 then slots(part.data)
        elseif part.id == 2 then rows = ids(part.data)
        elseif part.id == 3 then counts = ids(part.data) end
    end
    assert(rows and counts and #rows == (#counts-1)*5,"Invalid automatic magic result")
    local status = {}
    for i=1,#counts-1 do
        local n = (i-1)*5
        status[tostring(i)] = {method=rows[n+1],num1=rows[n+2],num2=rows[n+3],num3=rows[n+4],num4=rows[n+5],count=counts[i+1]}
    end
    charge(req.rows,counts[1])
    gamedata.ext.localMagicBusy = nil
    return {type=1364,id=req.id,view=req.view,window=req.window,status=status,autotimes=counts[1],g_gold=gamedata.cache.role.g_gold or 0}
end

function UIBreakForgePreview(req) return send(1365,req,{req.id},costs(req.id,nil,true)) end
function NetBreakForgePreview(fd)
    local req = receive(1365)
    assert(ids(fd.rbuf)[1] == 1,"Invalid magic breakthrough")
    charge(req.rows,1)
    gamedata.ext.localMagicBusy = nil
    return {type=1365,id=req.id,view=req.view}
end
