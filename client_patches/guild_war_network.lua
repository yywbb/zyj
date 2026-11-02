-- 并发请求不能覆盖原生ext费用/目标上下文。
for _,entry in ipairs({
    {2132,"UIGangPointJoinConfirmCallBack","NetGangPointJoinConfirmCallBack"},
    {2135,"UIGangPointJoinBattleCallBack","NetGangPointJoinBattleCallBack"},
    {2136,"UIGangPointInspireCoinCallBack","NetGangPointInspireCoinCallBack"},
    {2137,"UIGangPointInspireGoldCallBack","NetGangPointInspireGoldCallBack"},
    {2142,"UIGuildWarPointAwardCallBack","NetGuildWarPointAwardCallBack"},
    {2146,"UIGuildWarOneInspireCallBack","NetGuildWarOneInspireCallBack"},
    {2147,"UIGuildWarOneBattleCallBack","NetGuildWarOneBattleCallBack"}
}) do
    local opcode,request,response = entry[1],_G[entry[2]],_G[entry[3]]
    assert(request and response, "missing war callback "..opcode)
    _G[entry[2]] = function(uireq)
        if gamedata.ext.localGuildBusy then return 0,503,{type=503,msg="正在处理公会操作，请稍候"} end
        local remote,kind,body = request(uireq)
        if remote == 1 then gamedata.ext.localGuildBusy = opcode end
        return remote,kind,body
    end
    _G[entry[3]] = function(fd)
        if gamedata.ext.localGuildBusy == opcode then gamedata.ext.localGuildBusy = nil end
        return response(fd)
    end
end
