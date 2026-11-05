-- 原生灵阵协议；收费目标绑定显示等级，查询FIFO不被seq0推送占用。
require("GamePropList")
local spirit_ids=require("ids_pb")
local spirit_comb=require("combmessages_pb")

local function failure(message)
    return 0,503,{type=503,msg=message}
end

local function parseSpirit(raw)
    local message=spirit_comb.CombMessages();message:ParseFromString(raw)
    local rows={}
    for _,row in ipairs(message.messages) do
        assert(not rows[row.id],"灵阵图重复状态")
        local ids=spirit_ids.Ids();ids:ParseFromString(row.data);rows[row.id]=ids.ids
    end
    assert(rows[0] and #rows[0]==3 and rows[1] and #rows[1]==7 and rows[2] and #rows[2]==7,"灵阵图服务端版本不匹配")
    local state={use=rows[0][1],add=rows[0][2],power=rows[0][3],level={},activation={}}
    for i=1,7 do
        state.level[tostring(i)]=rows[1][i]
        state.activation[tostring(i)]=rows[2][i]
    end
    gamedata.cache.slotSpirit=state
    return state
end

local function sendSpirit(req,opcode)
    local mutation=opcode==4201 or opcode==4202
    local values,cost={},nil
    if mutation then
        if gamedata.ext.localFormationBusy or gamedata.ext.localSoulBusy or gamedata.ext.localEquipGrowthBusy or gamedata.ext.localDeploymentBusy then
            return failure("灵阵或阵容正在结算，请等待回复；未知超时请重进游戏")
        end
        local state=gamedata.cache.slotSpirit or {}
        local level=(state.level or {})[tostring(req.id)]
        if not level or level<1 then return failure("请先重新打开灵阵图") end
        values={req.id}
        if opcode==4202 then
            if req.level~=level then return failure("灵阵等级已变化，请重新打开升级窗口") end
            local row=gamedata.config.lingzhentu_lv[tostring(level)]
            if not gamedata.config.lingzhentu_lv[tostring(level+1)] then return failure("灵阵已满级") end
            if gamedata.cache.role.level<row.lv_cond then return failure("升级需要队伍"..row.lv_cond.."级") end
            cost=gamedata.getIDandNUMs(row.cost)
            local shown={}
            for _,v in pairs(req.props or {}) do shown[v.cid]=(shown[v.cid] or 0)+v.num end
            for _,v in ipairs(cost) do
                if shown[v.cid]~=v.num then return failure("灵阵升级费用已变化，请重新打开窗口") end
                shown[v.cid]=nil
                local enough,result=gamedata.checkStaffEnough(v.cid,v.num,{})
                if not enough then return 0,503,result end
            end
            if next(shown) then return failure("灵阵升级费用无效，请重新打开窗口") end
            table.insert(values,level)
        end
    end
    local pending={opcode=opcode,view=req.deploymentView,opt=req.opt,cost=cost}
    if mutation then
        gamedata.ext.localDeploymentBusy=pending
        gamedata.ext.localFormationBusy=pending
    else
        local queues=gamedata.ext.localDeploymentQueries or {}
        queues[opcode]=queues[opcode] or {};table.insert(queues[opcode],pending)
        gamedata.ext.localDeploymentQueries=queues
    end
    local ids=spirit_ids.Ids()
    for _,v in ipairs(values) do table.insert(ids.ids,v) end
    return 1,opcode,#values>0 and ids:SerializeToString() or nil
end

function LocalDeploymentError(opcode)
    local pending=gamedata.ext.localDeploymentBusy
    if pending and pending.opcode==opcode then
        if gamedata.ext.localFormationBusy==pending then gamedata.ext.localFormationBusy=nil end
        gamedata.ext.localDeploymentBusy=nil
    end
    table.remove((gamedata.ext.localDeploymentQueries or {})[opcode] or {},1)
end

local function receiveSpirit(fd,opcode)
    local pending
    if opcode==4201 or opcode==4202 then
        pending=gamedata.ext.localDeploymentBusy
        if fd.ser==0 or not pending or pending.opcode~=opcode then return {type=opcode,localDeploymentIgnored=true} end
    elseif fd.ser~=0 then
        pending=table.remove((gamedata.ext.localDeploymentQueries or {})[opcode] or {},1)
    end
    local result={type=opcode,deploymentView=pending and pending.view,opt=pending and pending.opt}
    if opcode==4204 then
        local ids=spirit_ids.Ids();ids:ParseFromString(fd.rbuf)
        result.data={add=ids.ids[1],activation={}}
        for i=2,#ids.ids do table.insert(result.data.activation,ids.ids[i]) end
    else result.slotSpirit=parseSpirit(fd.rbuf) end
    if pending and (opcode==4201 or opcode==4202) then
        for _,v in ipairs(pending.cost or {}) do gamedata:updateStaff({cid=v.cid,num=-v.num}) end
        LocalDeploymentError(opcode)
    end
    return result
end

function UISlotSpiritQueryCallBack(req) return sendSpirit(req,4200) end
function UISlotSpiritUseCallBack(req) return sendSpirit(req,4201) end
function UISlotSpiritLevelupCallBack(req) return sendSpirit(req,4202) end
function UISlotSpiritAdditionQueryCallBack(req) return sendSpirit(req,4204) end
function NetSlotSpiritQueryCallBack(fd) return receiveSpirit(fd,4200) end
function NetSlotSpiritUseCallBack(fd) return receiveSpirit(fd,4201) end
function NetSlotSpiritLevelupCallBack(fd) return receiveSpirit(fd,4202) end
function NetSlotSpiritChangeCallBack(fd) return receiveSpirit(fd,4203) end
function NetSlotSpiritAdditionQueryCallBack(fd) return receiveSpirit(fd,4204) end

local property=UIPropQueryByIdCallback
function UIPropQueryByIdCallback(req)
    local mode,mid,result=property(req)
    if mode==0 and result and req.order==42021 then result.deploymentView=req.deploymentView end
    return mode,mid,result
end
