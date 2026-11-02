-- GameCollect loads after GameTask; bind replies to their own request and page.
require("GameTask")
local callbacks = {
    {1015,"UIGeneralCollectCallBack","NetGeneralCollectCallBack","generalcollect"},
    {1103,"UIEquipCollectCallBack","NetEquipCollectCallBack","equipcollect"},
    {3910,"UITeamRecomQueryCallBack","NetTeamRecomQueryCallBack"},
    {3911,"UITeamRecomRewardCallBack","NetTeamRecomRewardCallBack"},
    {2400,"UITaskQueryCallBack","NetTaskQueryCallBack","task"},
    {2401,"UITaskCompleteCallBack","NetTaskCompleteCallBack"},
}
for _,entry in ipairs(callbacks) do
    local opcode,send,receive,key = entry[1],_G[entry[2]],_G[entry[3]],entry[4]
    local mutation = opcode==3911 or opcode==2401
    _G[entry[2]]=function(req)
        if mutation and gamedata.ext.localProgressBusy then
            return 0,503,{type=503,msg="奖励正在结算，请等待回复；超时请重进游戏"}
        end
        local pending=gamedata.ext.localProgressPending or {}
        local queue=pending[opcode] or {}
        if not mutation and #queue>0 and queue[#queue].view==req.view then
            return 0,opcode,{type=opcode,localSkip=true}
        end
        local mode,mid,raw=send(req)
        if mode==1 then
            table.insert(queue,{view=req.view,id=req.id})
            pending[opcode]=queue
            gamedata.ext.localProgressPending=pending
            if mutation then gamedata.ext.localProgressBusy=opcode end
        end
        return mode,mid,raw
    end
    _G[entry[3]]=function(fd)
        local pending=gamedata.ext.localProgressPending or {}
        local queue=pending[opcode] or {}
        local req=table.remove(queue,1) or {}
        if #queue==0 then pending[opcode]=nil end
        if gamedata.ext.localProgressBusy==opcode then gamedata.ext.localProgressBusy=nil end
        if key then gamedata.cache[key]={} end
        if opcode==2401 then gamedata.ext.TaskCompleteid=req.id end
        if opcode==3911 then gamedata.ext.teamRecomRewardId=req.id end
        local result=receive(fd)
        result.view=req.view
        return result
    end
end
