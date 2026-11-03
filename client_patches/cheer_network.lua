-- 1003/1004共用原生changelslot，上一笔未知结果时不能覆盖目标。
for _, entry in ipairs({
    {"UIChangeSlotCallBack", "NetChangeSlotCallBack", 1003},
    {"UIChangeCheerCallBack", "NetChangecheerCallBack", 1004},
    {"UISlotArrangeCallBack", "NetSlotArrangeCallBack", 1009},
}) do
    local request, response, opcode = _G[entry[1]], _G[entry[2]], entry[3]
    _G[entry[1]] = function(req)
        if gamedata.ext.localFormationBusy or gamedata.ext.localSoulBusy or gamedata.ext.localEquipGrowthBusy then
            return 0, 503, {type=503, msg="阵容正在结算，请等待回复；超时请重进游戏"}
        end
        local kind, mid, body = request(req)
        if kind == 1 then
            gamedata.ext.localFormationBusy = {opcode=opcode, request={pos1=req.pos1, pos2=req.pos2, iid=req.iid}}
        end
        return kind, mid, body
    end
    _G[entry[2]] = function(fd)
        local pending = gamedata.ext.localFormationBusy
        local result = response(fd)
        if pending and pending.opcode == opcode then
            result.changelslot = pending.request
            gamedata.ext.localFormationBusy = nil
        else
            result.changelslot = {}
        end
        return result
    end
end
