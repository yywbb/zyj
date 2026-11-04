local compoundSend, compoundReceive = UIGeneralCompoundCallBack, NetGeneralCompoundCallBack
function UIGeneralCompoundCallBack(req)
    if gamedata.ext.localCompoundBusy then
        return 0,503,{type=503,msg="伙伴正在合成，请等待回复；超时请重进游戏"}
    end
    local cid = (req.ids or {})[1] or (req.ids or {})["1"]
    if table.getTableLength(req.ids or {}) ~= 1 or not tonumber(cid) then
        return 0,503,{type=503,msg="请选择一个伙伴合成"}
    end
    local mode, opcode, raw = compoundSend({ids={tonumber(cid)}})
    if mode == 1 then gamedata.ext.localCompoundBusy={view=req.compoundView} end
    return mode, opcode, raw
end

function NetGeneralCompoundCallBack(fd)
    local pending = gamedata.ext.localCompoundBusy
    if not pending then return {type=1016,localCompoundIgnored=true} end
    local result = compoundReceive(fd)
    result.compoundView = pending.view
    gamedata.ext.localCompoundBusy = nil
    return result
end
