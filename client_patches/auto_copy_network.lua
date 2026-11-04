-- UI/net分离：原回调结算资源，只传递本次请求标记；共享锁防手动操作覆盖收费目标。
require("GameRecharge")

local function context(req)
    return {local_auto_copy=req.local_auto_copy, map=req.map, point=req.point, type=req.type}
end

local function tagged(t, req, opcode)
    t.localAutoCopy = req.local_auto_copy
    t.localAutoOpcode = opcode
    if req.local_auto_copy then
        t.map, t.point = req.map, req.point
        local role = gamedata.cache.role
        t.localAutoRole = {stamina=role.stamina, gold=role.gold, level=role.level, vip=role.vip}
        t.localAutoTime = gamedata:time()
    end
    return t
end

for _, row in ipairs({
    {1306,"UICopyAttack2Callback","NetCopyAttack2Callback"},
    {1307,"UICopyWipe2Callback","NetCopyWipe2Callback"},
    {1305,"UICopyResetKillCallback","NetCopyResetKillCallback"},
    {301,"UIUserBuyCallBack","NetUserBuyCallBack"},
    {1300,"UICopyQueryCallback","NetCopyQueryCallback"},
    {300,"UIVipStatusCallBack","NetVipStatusCallBack"},
}) do
    local opcode, uiName, netName = row[1], row[2], row[3]
    local send, receive = _G[uiName], _G[netName]
    local read = opcode == 1300 or opcode == 300
    _G[uiName] = function(req)
        local ctx = context(req)
        if not read and gamedata.ext.localAutoCopyBusy then
            return 0,503,tagged({type=503,msg="副本或资源购买正在结算，请等待回复；未知超时请重进游戏"},ctx,opcode)
        end
        local remote, kind, data = send(req)
        if remote == 1 then
            ctx.type = opcode
            if read then
                local queues = gamedata.ext.localAutoCopyReads or {}
                queues[opcode] = queues[opcode] or {}
                table.insert(queues[opcode],ctx)
                gamedata.ext.localAutoCopyReads = queues
            else
                gamedata.ext.localAutoCopyBusy = ctx
            end
        elseif data then tagged(data,ctx,opcode) end
        return remote, kind, data
    end
    _G[netName] = function(fd)
        local ctx
        if read then
            if fd.ser ~= 0 then
                ctx = table.remove((gamedata.ext.localAutoCopyReads or {})[opcode] or {},1)
            end
        else
            ctx = gamedata.ext.localAutoCopyBusy
            if not ctx or ctx.type ~= opcode then return {type=opcode,localAutoCopyIgnored=true} end
        end
        local t = receive(fd)
        if not read then gamedata.ext.localAutoCopyBusy = nil end
        return tagged(t,ctx or {},opcode)
    end
end

function LocalAutoCopyError(opcode)
    if not gamedata or not gamedata.ext then return end
    local busy = gamedata.ext.localAutoCopyBusy
    if busy and busy.type == opcode then
        gamedata.ext.localAutoCopyBusy = nil
        return busy
    end
    return table.remove((gamedata.ext.localAutoCopyReads or {})[opcode] or {},1)
end
