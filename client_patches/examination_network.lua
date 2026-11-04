for _, entry in ipairs({
    {7002,"UIExaminationStatusCallBack","NetExaminationStatusCallBack"},
    {7003,"UIExaminationStartCallBack","NetExaminationStartCallBack"},
    {7004,"UIExaminationEndCallBack","NetExaminationEndCallBack"},
    {7005,"UIExaminationPaihangbangCallBack","NetExaminationPaihangbangCallBack"},
}) do
    local opcode, send, receive = entry[1], _G[entry[2]], _G[entry[3]]
    _G[entry[2]] = function(req)
        local mutation = opcode == 7003 or opcode == 7004
        if mutation and gamedata.ext.localExaminationBusy then
            return 0,503,{type=503,msg="答题正在结算，请等待回复；超时请重进游戏"}
        end
        local mode, mid, raw = send(req)
        if mode == 1 then
            local pending = gamedata.ext.localExaminationPending or {}
            pending[opcode] = pending[opcode] or {}
            table.insert(pending[opcode],{view=req.examinationView,kind=tonumber(req.timuType or req.ranktype),question=tonumber(req.timuid)})
            gamedata.ext.localExaminationPending = pending
            if mutation then gamedata.ext.localExaminationBusy=opcode end
        end
        return mode, mid, raw
    end
    _G[entry[3]] = function(fd)
        local req = table.remove((gamedata.ext.localExaminationPending or {})[opcode] or {},1)
        if not req and opcode ~= 7002 then return {type=opcode,localExaminationIgnored=true} end
        local result = receive(fd)
        req = req or {}
        result.examinationView, result.examKind, result.examQuestion = req.view, req.kind, req.question
        if gamedata.ext.localExaminationBusy == opcode then gamedata.ext.localExaminationBusy=nil end
        return result
    end
end
