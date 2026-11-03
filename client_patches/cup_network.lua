-- Native cup caches are incremental; local replies are complete and request-bound.
local function cupIds(values)
    local data=ids_pb.Ids()
    for _,value in ipairs(values) do table.insert(data.ids,value) end
    return data:SerializeToString()
end
function UICupTopCallBack(req) return 1,2102,cupIds({2,4,8}) end
function UICupJoinTomorrowCallBack(req) return 1,2101,nil end
function UICupBattleBetCallBack(req)
    return 0,503,{type=503,msg="本地杯赛竞猜未开放，不扣除资源"}
end
function NetCupBattlePlayCallBack(fd)
    local data=battleresult_pb.BattleResult()
    data:ParseFromString(fd.rbuf)
    return {type=2103,result=data.result,battlereport=data.battlereport}
end
function NetCupBattleRewardCallBack(fd)
    local data=somethings_pb.SomeThings()
    data:ParseFromString(fd.rbuf)
    return {type=2104,reward=gamedata:SomethingProcess(data)}
end
function NetCupBattleRewardallCallBack(fd)
    local data=somethings_pb.SomeThings()
    data:ParseFromString(fd.rbuf)
    return {type=2106,reward=gamedata:SomethingProcess(data)}
end
local callbacks={
    {2100,"UICupStatusCallBack","NetCupStatusCallBack"},
    {2101,"UICupJoinTomorrowCallBack","NetCupJoinTomorrowCallBack"},
    {2102,"UICupTopCallBack","NetCupTopCallBack"},
    {2103,"UICupBattlePlayCallBack","NetCupBattlePlayCallBack"},
    {2104,"UICupBattleRewardCallBack","NetCupBattleRewardCallBack"},
    {2106,"UICupBattleRewardallCallBack","NetCupBattleRewardallCallBack"},
    {2107,"UICupRankCallBack","NetCupRankCallBack"},
}
for _,entry in ipairs(callbacks) do
    local opcode,send,receive=entry[1],_G[entry[2]],_G[entry[3]]
    local action=opcode==2101 or opcode==2103 or opcode==2104 or opcode==2106
    _G[entry[2]]=function(req)
        if action and gamedata.ext.localCupBusy then
            return 0,503,{type=503,msg="杯赛操作正在处理，请等待回复；超时请重进游戏"}
        end
        local pending=gamedata.ext.localCupPending or {}
        local queue=pending[opcode] or {}
        local last=queue[#queue]
        if last and last.view==req.view and last.generation==req.generation and last.id==req.id and last.round==req.round then
            return 0,opcode,{type=opcode,localSkip=true}
        end
        local context=table.copy(req)
        if opcode==2103 then
            local row
            if req.isself then row=(gamedata.cache.cup.status.battles or {})[req.round]
            else row=gamedata.cache.cup.topbattles[req.id] end
            if not row or row.id~=req.id then return 0,503,{type=503,msg="赛程已变化，请刷新后重播"} end
            local winner
            if req.isself then winner=row.result==1 and gamedata.cache.role or row.enemy
            else winner=row.status==1 and row.a or row.b end
            context.winner={name=winner.name,level=winner.level}
        elseif opcode==2106 then
            context.claims={}
            for _,row in pairs(gamedata.cache.cup.status.battles or {}) do context.claims[row.id]=true end
        end
        local mode,mid,raw=send(req)
        if mode==1 then
            table.insert(queue,context)
            pending[opcode]=queue
            gamedata.ext.localCupPending=pending
            if action then gamedata.ext.localCupBusy=opcode end
        end
        return mode,mid,raw
    end
    _G[entry[3]]=function(fd)
        local pending=gamedata.ext.localCupPending or {}
        local queue=pending[opcode] or {}
        local req=table.remove(queue,1) or {}
        if #queue==0 then pending[opcode]=nil end
        if gamedata.ext.localCupBusy==opcode then gamedata.ext.localCupBusy=nil end
        if opcode==2100 then gamedata.cache.cup.status={battles={}} end
        if opcode==2102 then gamedata.cache.cup.topbattles={} end
        local result=receive(fd)
        if opcode==2104 or opcode==2106 then
            for _,row in pairs(gamedata.cache.cup.status.battles or {}) do
                if row.result==1 and (opcode==2104 and row.id==req.id or opcode==2106 and (req.claims or {})[row.id]) then row.reward=1 end
            end
            result.cupstatus=makeStatus()
        end
        result.req,result.view,result.generation=req,req.view,req.generation
        result.round,result.id,result.winner=req.round,req.id,req.winner
        return result
    end
end
function UICupTopSeeCallBack(req)
    local data,bet=maketopsdata()
    return 0,21021,{type=21021,cuptopbattles=data,betnum=bet,view=req.view}
end
