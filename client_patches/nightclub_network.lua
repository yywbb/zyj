-- 原生扣费只用同版配置，收费串行；领取/事件绑定派驻起点，旧弹窗不能消费新训练。
local ids = require("ids_pb")
local comb = require("combmessages_pb")
local function rows(opcode,fd,req)
    local cache = gamedata.ext.localNightclubRows or {}
    local function put(floor,raw)
        local value=ids.Ids();value:ParseFromString(raw)
        cache[tonumber(floor)]={event=value.ids[2],stamp=value.ids[7]}
    end
    if opcode==4501 or opcode==4503 then put(req._id,fd.rbuf)
    elseif opcode==4500 or opcode==4509 or opcode==4511 then
        local messages=comb.CombMessages();messages:ParseFromString(fd.rbuf)
        for _,message in ipairs(messages.messages) do if message.id>0 then put(message.id,message.data) end end
    end
    gamedata.ext.localNightclubRows=cache
end

for _,entry in ipairs({
    {4500,"UIUserPatrolQuery","NetUserPatrolQuery"},{4501,"UIUserPatrolStatus","NetUserPatrolStatus"},
    {4502,"UIUserPatrolAttack","NetUserPatrolAttack"},{4503,"UIUserPatrolDo","NetUserPatrolDo"},
    {4504,"UIUserPatrolReward","NetUserPatrolReward"},{4505,"UIUserPatrolEventDo","NetUserPatrolEventDo"},
    {4509,"UIUserPatrolOneAdd","NetUserPatrolOneAdd"},{4510,"UIUserPatrolOneAddReward","NetUserPatrolOneAddReward"},
    {4511,"UIUserPatrolOneAddQuery","NetUserPatrolOneAddQuery"},
}) do
    local opcode,send,receive=entry[1],_G[entry[2]],_G[entry[3]]
    local mutation=opcode~=4500 and opcode~=4501 and opcode~=4511
    _G[entry[2]]=function(req)
        if mutation and gamedata.ext.localNightclubBusy then
            return 0,503,{type=503,msg="银座正在结算，请等待回复；超时请重进游戏"}
        end
        local rawValues
        local cache=gamedata.ext.localNightclubRows or {}
        if opcode==4503 or opcode==4509 then
            local row=gamedata.config.tiantingyz_time[tostring(req._time)]
            if not row then return 0,503,{type=503,msg="训练档位无效"} end
            if opcode==4503 then req._shaType=row.type==1 and 0 or 1;req._shaNum=row.type==1 and row.murderous or row.Ingots
            else
                local data,num={},0
                for i=1,10 do local iid=tonumber((req.data or {})[i] or (req.data or {})[tostring(i)] or 0)
                    if iid>0 then data[tostring(i)]=iid;num=num+1 end
                end
                req.data=data;req._shaNum=row.type==1 and 0 or 1;req._baoNum=(row.type==1 and row.murderous or row.Ingots)*num
            end
        elseif opcode==4504 or opcode==4505 then
            local floor=tonumber(req._id or req._index)
            local current=cache[floor]
            if not current or not req.nightclubToken or req.nightclubToken.stamp~=current.stamp then
                return 0,503,{type=503,msg="派驻状态已变化，请重新打开楼层"}
            end
            rawValues={floor,current.stamp}
            if opcode==4505 then
                if req.nightclubToken.event~=current.event then return 0,503,{type=503,msg="事件已变化，请重新打开楼层"} end
                rawValues={floor,req._choose,current.event,current.stamp}
                req._gold=nil;req._coin=nil;req._item=nil;req._nums=nil
                local event=gamedata.config.tiantingyz_sjtype[tostring(current.event)]
                if not event then return 0,503,{type=503,msg="没有待处理事件"} end
                if tonumber(req._choose)==1 then for _,cost in ipairs(gamedata.getIDandNUMs(event.cost)) do
                    if cost.cid==1000 then req._coin=cost.num elseif cost.cid==1001 then req._gold=cost.num
                    else req._item=cost.cid;req._nums=cost.num end
                end end
            end
        elseif opcode==4510 then
            rawValues={}
            for i=1,table.getTableLength(req.data or {}) do
                local floor=tonumber(req.data[i] or req.data[tostring(i)])
                local stamp=(req.nightclubTokens or {})[tostring(floor)]
                if not cache[floor] or stamp~=cache[floor].stamp then return 0,503,{type=503,msg="派驻状态已变化，请刷新银座"} end
                table.insert(rawValues,floor);table.insert(rawValues,stamp)
            end
        end
        local mode,mid,raw=send(req)
        if mode==1 then
            if rawValues then local message=ids.Ids();for _,v in ipairs(rawValues) do table.insert(message.ids,v) end;raw=message:SerializeToString() end
            local pending=gamedata.ext.localNightclubPending or {};pending[opcode]=pending[opcode] or {}
            table.insert(pending[opcode],req);gamedata.ext.localNightclubPending=pending
            if mutation then gamedata.ext.localNightclubBusy=opcode end
        end
        return mode,mid,raw
    end
    _G[entry[3]]=function(fd)
        local req=table.remove((gamedata.ext.localNightclubPending or {})[opcode] or {},1)
        if not req then return {type=opcode,localNightclubIgnored=true} end
        rows(opcode,fd,req)
        local result=receive(fd)
        result.nightclubView=req.nightclubView
        result.nightclubFloor=tonumber(req._id or req._index)
        if gamedata.ext.localNightclubBusy==opcode then gamedata.ext.localNightclubBusy=nil end
        return result
    end
end
