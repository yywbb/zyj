-- UI/net Lua states are separate: every confirmation carries its own IID and token.
local preview_pb = require("fosterpreview_pb")
local confirm_pb = require("fosterconfirm_pb")
local generals_pb = require("generals_pb")
local ids_pb = require("ids_pb")
local comb_pb = require("combmessages_pb")

local function busy()
    return 0,503,{type=503,msg="培养正在结算，请等待回复；超时请重进游戏"}
end

local function parts(fd)
    local packet = comb_pb.CombMessages()
    packet:ParseFromString(fd.rbuf)
    local result = {}
    for _,row in ipairs(packet.messages) do result[row.id] = row.data end
    return result
end

local function ids(raw)
    local data = ids_pb.Ids()
    data:ParseFromString(raw)
    return data.ids
end

local function general(raw)
    local data = generals_pb.Generals()
    data:ParseFromString(raw)
    assert(#data.generals == 1, "Invalid cultivation general")
    return data.generals[1]
end

function UIGeneralFosterPreviewCallBack(req)
    if gamedata.ext.localFosterBusy then return busy() end
    local method = req.method or 0
    local count = (method == 2 or method == 4) and 10 or (method == 0 and 0 or 1)
    local gold = method >= 3 and count*5 or 0
    if count > 0 and (not gamedata.cache.props[20009] or gamedata.cache.props[20009].num < count) then
        return 0,503,{type=503,msg="培养丹不足"}
    end
    if gamedata.cache.role.gold < gold then return 0,503,{type=503,msgtype="shortgold"} end
    local data = preview_pb.FosterPreview()
    data.id, data.method = req.id, method
    gamedata.ext.localFosterBusy = {opcode=1013,id=req.id,method=method}
    return 1,1013,data:SerializeToString()
end

function NetGeneralFosterPreviewCallBack(fd)
    local req = gamedata.ext.localFosterBusy
    assert(req and req.opcode == 1013, "Unexpected cultivation preview")
    local data = parts(fd)
    local current, candidate, meta = general(data[1]), general(data[2]), ids(data[3])
    assert(current.iid == req.id and candidate.iid == req.id, "Cultivation target changed")
    local count = meta[2]
    if count > 0 then
        gamedata:updateprops({cid=20009,num=-count})
        if req.method >= 3 then gamedata:updateRoleGold(-count*5,"伙伴培养",1) end
    end
    gamedata:Generals({current})
    gamedata.ext.localFosterBusy = nil
    return {type=1013,token=meta[1],prop=count,restored=req.method == 0,remaining=gamedata.cache.props[20009] and gamedata.cache.props[20009].num or 0,
        extGeneralData=gamedata:generalData(current),previewGeneralData=gamedata:generalData(candidate)}
end

function UIGeneralFosterConfirmCallBack(req)
    if gamedata.ext.localFosterBusy then return busy() end
    if not req.id or not req.token or req.token <= 0 then return 0,503,{type=503,msg="请重新打开当前伙伴查看培养预览"} end
    local data = confirm_pb.FosterConfirm()
    data.id, data.opt, data.token = req.id, req.opt, req.token
    gamedata.ext.localFosterBusy = {opcode=1014,id=req.id}
    return 1,1014,data:SerializeToString()
end

function NetGeneralFosterConfirmCallBack(fd)
    local req = gamedata.ext.localFosterBusy
    assert(req and req.opcode == 1014, "Unexpected cultivation confirmation")
    local data = parts(fd)
    local value = general(data[1])
    assert(value.iid == req.id, "Cultivation target changed")
    gamedata:Generals({value})
    gamedata.ext.localFosterBusy = nil
    return {type=1014,general=gamedata:generalData(value),ison=gamedata:isGeneralOn(value.iid),result=ids(data[2])[1] == 1}
end

function UIGeneralAutoTrainCallBack(req)
    local function reject(msg,msgtype)
        return 0,503,{type=503,msg=msg,msgtype=msgtype,localFosterBatch=req.localFosterBatch}
    end
    if gamedata.ext.localFosterBusy then return reject("培养正在结算，请等待回复；超时请重进游戏") end
    local total = req.localFosterTotal or req.xlnum
    if not req.xlnum or req.xlnum < 1 or req.xlnum > 200 or req.xlnum % 1 ~= 0
        or not total or total < req.xlnum or total >= 2147483648 or total % 1 ~= 0 then
        return reject("自动培养总次数须为正整数，每批最多200次")
    end
    if not gamedata.cache.props[20009] or gamedata.cache.props[20009].num < total then
        return reject("培养丹不足")
    end
    if req.method == 2 and gamedata.cache.role.gold < total*5 then
        return reject(nil,"shortgold")
    end
    local data = ids_pb.Ids()
    for _,value in ipairs({req.iid,req.method,req.xlnum,req.status1 or 0,req.status2 or 0,req.status3 or 0}) do
        table.insert(data.ids,value)
    end
    gamedata.ext.localFosterBusy = {opcode=1126,id=req.iid,method=req.method,count=req.xlnum,batch=req.localFosterBatch}
    return 1,1126,data:SerializeToString()
end

function NetGeneralAutoTrainCallBack(fd)
    local req = gamedata.ext.localFosterBusy
    assert(req and req.opcode == 1126, "Unexpected automatic cultivation")
    local data = parts(fd)
    local value, rows, counts = general(data[1]), ids(data[2]), ids(data[3])
    assert(value.iid == req.id and #rows == #counts*6, "Invalid automatic cultivation result")
    local status, total = {},0
    for i,count in ipairs(counts) do
        assert(count >= 1 and count <= 10, "Invalid automatic cultivation count")
        local n = (i-1)*6
        status[tostring(i)] = {status=rows[n+1],attribute1=rows[n+2],num1=rows[n+3],
            attribute2=rows[n+4],num2=rows[n+5],potential=rows[n+6],count=count}
        total = total+count
    end
    assert(total > 0 and total <= req.count, "Automatic cultivation exceeded request")
    gamedata:updateprops({cid=20009,num=-total})
    if req.method == 2 then gamedata:updateRoleGold(-total*5,"伙伴培养",1) end
    gamedata:Generals({value})
    gamedata.ext.localFosterBusy = nil
    return {type=1126,general=gamedata:generalData(value),status=status,stop=total < req.count and 1 or 0,actual=total,
        localFosterBatch=req.batch,remaining=gamedata.cache.props[20009].num}
end
