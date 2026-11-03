-- 价格来自同版配置；查询FIFO绑定界面，收费请求不自动重试。
local function price(req,opcode)
    local w = gamedata.cache.wing or {}
    local stage = w.stagenum or 0
    if opcode == 3741 then
        local rows = gamedata.config.wing_uplv[tostring(stage)] or {}
        local row = rows[tostring((w.starnum or 0)+1)]
        if not row then return false end
        req.id = row.cost
    elseif opcode == 3742 then
        local row = gamedata.config.wing_stage[tostring(stage+1)]
        if not row or (req.marknum ~= 0 and req.marknum ~= 1) then return false end
        req.first = stage == 0 and true or nil
        req.spend = stage == 0 and {} or gamedata.getIDandNUMs(row.cost)
        if stage > 0 and req.marknum == 1 then
            for _,v in ipairs(gamedata.getIDandNUMs(row.special_cost)) do table.insert(req.spend,v) end
        end
    elseif opcode == 3743 then
        local row = gamedata.config.wing_stage[tostring(stage)]
        if not row then return false end
        req.cost = nil
        if req.id ~= 0 and (gamedata.cache.wingcolor or {})[tostring(req.id)] ~= 2 then
            local color = gamedata.config.wing_coler[tostring(req.id)]
            if not color or row["c"..req.id] ~= 1 then return false end
            req.cost = {cid=color.item_id,num=row.cost_return}
        end
    end
    return true
end

for _,entry in ipairs({
    {3740,"UIWingQuaryCallback","NetWingQuaryCallback"},
    {3741,"UIWingSatrUpCallback","NetWingSatrUpCallback"},
    {3742,"UIWingStageUpCallback","NetWingStageUpCallback"},
    {3743,"UIWingDyeingCallback","NetWingDyeingCallback"},
    {3744,"UIWingColorQueryCallback","NetWingColorQueryCallback"},
}) do
    local opcode,send,receive=entry[1],_G[entry[2]],_G[entry[3]]
    assert(send and receive,"missing wing callback "..opcode)
    _G[entry[2]]=function(req)
        if gamedata.ext.localWingBusy and opcode ~= 3740 and opcode ~= 3744 then
            return 0,503,{type=503,msg="翅膀正在结算，请等待回复；超时请重进游戏"}
        end
        if not price(req,opcode) then return 0,503,{type=503,msg="翅膀状态已变化，请重新打开页面"} end
        local remote,mid,raw=send(req)
        if remote == 1 then
            local pending=gamedata.ext.localWingPending or {}
            pending[opcode]=pending[opcode] or {}
            table.insert(pending[opcode],req.wingView or {})
            gamedata.ext.localWingPending=pending
            if opcode ~= 3740 and opcode ~= 3744 then gamedata.ext.localWingBusy=opcode end
        end
        return remote,mid,raw
    end
    _G[entry[3]]=function(fd)
        local queue=(gamedata.ext.localWingPending or {})[opcode] or {}
        if #queue == 0 then return {type=opcode,localWingIgnored=true} end
        local view=table.remove(queue,1)
        local result=receive(fd)
        result.wingView=view
        if gamedata.ext.localWingBusy == opcode then gamedata.ext.localWingBusy=nil end
        local w=gamedata.cache.wing
        if w and gamedata.cache.protagonist then
            gamedata.cache.protagonist.w_l=w.stagenum
            gamedata.cache.protagonist.w_c=w.colortype
        end
        return result
    end
end
