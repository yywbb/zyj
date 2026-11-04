-- 主角养成绑定显示目标；费用取同版配置，在途请求不重试。
require("GameGeneralAwanken")
require("GamePropList")
local ids_pb=require("ids_pb")
local generals_pb=require("generals_pb")

local function failure(message)
    return 0,503,{type=503,msg=message}
end

function UIUserProtagonistGameQuery(req)
    local queue=gamedata.ext.localLeadGrowthQueries or {}
    table.insert(queue,req.leadGrowthView or {})
    gamedata.ext.localLeadGrowthQueries=queue
    return 1,3720,nil
end

function NetUserProtagonistGameQuery(fd)
    local queue=gamedata.ext.localLeadGrowthQueries or {}
    if #queue==0 then return {type=3720,localLeadGrowthIgnored=true} end
    local info=ids_pb.Ids();info:ParseFromString(fd.rbuf)
    local current={stage=info.ids[1],step=info.ids[2]}
    gamedata.ext.localLeadGame=current
    return {type=3720,_cellIndex=current.stage,_nowsIndex=current.step,
        _selfLevel=gamedata.cache.protagonist.level2,leadGrowthView=table.remove(queue,1)}
end

local function send(req,opcode)
    if gamedata.ext.localLeadGrowthBusy then
        return failure("主角养成正在结算，请等待回复；未知超时请重进游戏")
    end
    local protagonist=gamedata.cache.protagonist or {}
    local general=protagonist.general or {}
    local game=gamedata.ext.localLeadGame or {}
    local values,spec
    if opcode==1058 then
        if not protagonist.iid or req.iid~=protagonist.iid or req.level~=(general.skilllevel or 0) then
            return failure("觉醒目标已变化，请重新打开页面")
        end
        local row=gamedata.config.protagonist_awaken[tostring(req.level+1)]
        if not row then return failure("主角觉醒已满级") end
        values,spec={req.iid,req.level},row.consume
    else
        if req._stage~=game.stage or opcode==3721 and req._step~=game.step then
            return failure("游戏厅目标已变化，请等待查询或重新打开页面")
        end
        local row=gamedata.config.hoshimiya_break[tostring(game.stage)]
        if not row then return failure("游戏厅已全部通关") end
        if opcode==3721 then
            local point=(gamedata.config.hoshimiya_jihuo[tostring(game.stage)] or {})[tostring((game.step or 0)+1)]
            if not point then return failure("请先突破当前游戏厅关卡") end
            values,spec={game.stage,game.step},point.activation_cost
        else
            if game.step~=row.break_cond1 then return failure("请先完成本关九点激活") end
            values,spec={game.stage},row.break_cost
        end
    end
    local cost=gamedata.getIDandNUMs(spec)
    local request=ids_pb.Ids()
    for _,value in ipairs(values) do table.insert(request.ids,value) end
    gamedata.ext.localLeadGrowthBusy={opcode=opcode,cost=cost,values=values,view=req.leadGrowthView}
    return 1,opcode,request:SerializeToString()
end

local function receive(fd,opcode)
    local pending=gamedata.ext.localLeadGrowthBusy
    if not pending or pending.opcode~=opcode then return {type=opcode,localLeadGrowthIgnored=true} end
    local info=generals_pb.Generals();info:ParseFromString(fd.rbuf)
    gamedata:Generals(info.generals)
    for _,row in ipairs(pending.cost) do gamedata:updateStaff({cid=row.cid,num=-row.num}) end
    if opcode~=1058 then
        gamedata.ext.localLeadGame={stage=pending.values[1]+(opcode==3722 and 1 or 0),step=opcode==3721 and pending.values[2]+1 or 0}
    end
    gamedata.ext.localLeadGrowthBusy=nil
    return {type=opcode,protagonist=gamedata.cache.protagonist,leadGrowthView=pending.view}
end

function UIUserProtagonistGameEatBeans(req) return send(req,3721) end
function NetUserProtagonistGameEatBeans(fd) return receive(fd,3721) end
function UIUserProtagonistGamePopcorn(req) return send(req,3722) end
function NetUserProtagonistGamePopcorn(fd) return receive(fd,3722) end
function UIProtagonistAwakenCallBack(req) return send(req,1058) end
function NetProtagonistAwakenCallBack(fd) return receive(fd,1058) end

local query=UIPropQueryByIdCallback
function UIPropQueryByIdCallback(req)
    local mode,mid,result=query(req)
    if mode==0 and result and (req.order==10771 or req.order==33018) then result.leadGrowthView=req.leadGrowthView end
    return mode,mid,result
end
