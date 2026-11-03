-- Only these two local dragons are live; 5201-series callbacks remain untouched.
local callbacks={
    {3400,"UIWorldBoss1QueryCallBack","NetWorldBoss1QueryCallBack"},
    {3401,"UIWorldBoss1AttackCallBack","NetWorldBoss1AttackCallBack"},
    {3402,"UIWorldBoss1RankCallBack","NetWorldBoss1RankCallBack"},
    {3403,"UIWorldBoss1RealNotifyCallBack","NetWorldBoss1RealNotifyCallBack"},
    {3404,"UIWorldBoss1PreRankCallBack","NetWorldBoss1PreRankCallBack"},
    {3410,"UIWorldBoss2QueryCallBack","NetWorldBoss2QueryCallBack"},
    {3411,"UIWorldBoss2AttackCallBack","NetWorldBoss2AttackCallBack"},
    {3412,"UIWorldBoss2RankCallBack","NetWorldBoss2RankCallBack"},
    {3413,"UIWorldBoss2RealNotifyCallBack","NetWorldBoss2RealNotifyCallBack"},
    {3414,"UIWorldBoss2PreRankCallBack","NetWorldBoss2PreRankCallBack"},
}
for _,entry in ipairs(callbacks) do
    local opcode,receive=entry[1],_G[entry[3]]
    local action=opcode%10==1
    _G[entry[2]]=function(req)
        if action and gamedata.ext.localWorldBossBusy then
            return 0,503,{type=503,msg="屠龙操作尚未返回；超时请重进游戏",localWorldBossRejected=true}
        end
        local pending=gamedata.ext.localWorldBossPending or {}
        local queue=pending[opcode] or {}
        for _,old in ipairs(queue) do
            if not action and old.view==req.view and old.page==req.page then
                return 0,opcode,{type=opcode,localSkip=true}
            end
        end
        local raw
        if action then
            local data=ids_pb.Ids()
            local method=req.method or 0
            local auto=(req.isauto==true or req.isauto==1) and 1 or 0
            table.insert(data.ids,method)
            table.insert(data.ids,auto)
            raw=data:SerializeToString()
            local prefix=opcode==3401 and "WorldBoss1Attack" or "WorldBoss2Attack"
            gamedata.ext[prefix.."method"]=method
            gamedata.ext[prefix.."isauto"]=auto
            gamedata.ext.localWorldBossBusy=opcode
        end
        table.insert(queue,{view=req.view,page=req.page})
        pending[opcode]=queue
        gamedata.ext.localWorldBossPending=pending
        return 1,opcode,raw
    end
    _G[entry[3]]=function(fd)
        local pending=gamedata.ext.localWorldBossPending or {}
        local queue=pending[opcode] or {}
        local req=table.remove(queue,1) or {}
        if #queue==0 then pending[opcode]=nil end
        if gamedata.ext.localWorldBossBusy==opcode then gamedata.ext.localWorldBossBusy=nil end
        local result=receive(fd)
        result.view,result.page=req.view,req.page
        if opcode%10==0 then
            local second=(gamedata:time()+28800)%86400
            result.mainStatus=((second>=12*3600 and second<12.5*3600 and gamedata.cache.worldboss.status==1)
                or (second>=21*3600 and second<21.5*3600 and gamedata.cache.worldboss2.status==1)) and 1 or 0
        end
        if opcode%10==3 then
            local cursors=gamedata.ext.localWorldBossEvents or {}
            local last=cursors[opcode] or 0
            local fresh={}
            for _,info in ipairs(result.infos or {}) do
                if info.id>last then table.insert(fresh,info) end
                cursors[opcode]=math.max(cursors[opcode] or 0,info.id)
            end
            gamedata.ext.localWorldBossEvents=cursors
            result.infos=fresh
        end
        return result
    end
end
