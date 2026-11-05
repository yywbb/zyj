-- 查询FIFO、服务端报价确认和单请求锁；未知超时绝不重新收费。
local helperQuery=UIGameHelperQueryCallback
local helperQueryReply=NetGameHelperQueryCallback
local helperExecute=UIGameHelperExeCallback
local helperExecuteReply=NetGameHelperExeCallback

local function helperFailure(msg,req)
    if req then return 0,9999,{type=9999,localHelperError=true,msg=msg,helperView=req.helperView,helperAction=req.helperAction} end
    return 0,503,{type=503,msg=msg}
end

function UIGameHelperQueryCallback(req)
    if gamedata.ext.localHelperBusy then return helperFailure("助手正在结算；结果未知请重进游戏") end
    local queue=gamedata.ext.localHelperQueries or {}
    table.insert(queue,{view=req.helperView,action=req.helperAction})
    gamedata.ext.localHelperQueries=queue
    return helperQuery(req)
end

function NetGameHelperQueryCallback(fd)
    if fd.ser==0 then return {type=6211,localHelperIgnored=true} end
    local pending=table.remove(gamedata.ext.localHelperQueries or {},1)
    if not pending then return {type=6211,localHelperIgnored=true} end
    local result=helperQueryReply(fd)
    result.helperView=pending.view
    result.helperAction=pending.action
    result.data.localHelperSupported={}
    result.data.guild.gang2status=result.data.guild.gang2status or {}
    local messages=combmessages_pb.CombMessages();messages:ParseFromString(fd.rbuf)
    for _,message in ipairs(messages.messages) do
        if message.id==20 then
            local values=ids_pb.Ids();values:ParseFromString(message.data)
            for i=1,#values.ids,2 do
                result.data.localHelperSupported[values.ids[i]..":"..values.ids[i+1]]=true
            end
        end
    end
    return result
end

function UIGameHelperExeCallback(req)
    if gamedata.ext.localHelperBusy or #(gamedata.ext.localHelperQueries or {})>0 then
        return helperFailure("助手请求正在等待回复；结果未知请重进游戏",req)
    end
    req.ext=req.ext or {}
    local mode,opcode,raw=helperExecute(req)
    local quote=gamedata.ext.localHelperQuote
    if req.helperToken then
        if not quote or quote.token~=req.helperToken or quote.raw~=raw then
            return helperFailure("助手报价或设置已变化，请重新打开助手",req)
        end
        local messages=combmessages_pb.CombMessages();messages:ParseFromString(raw)
        local confirm=messages.messages:add();confirm.id=3
        local token=ids_pb.Ids();table.insert(token.ids,req.helperToken)
        confirm.data=token:SerializeToString();raw=messages:SerializeToString()
        gamedata.ext.localHelperQuote=nil
    end
    gamedata.ext.localHelperBusy={view=req.helperView,action=req.helperAction,token=req.helperToken,
        params=req.params,ext=req.ext,raw=raw}
    return mode,opcode,raw
end

function LocalHelperError(opcode)
    if opcode==6211 then return table.remove(gamedata.ext.localHelperQueries or {},1) end
    if opcode~=6212 then return end
    local pending=gamedata.ext.localHelperBusy
    gamedata.ext.localHelperBusy=nil
    gamedata.ext.localHelperQuote=nil
    return pending
end

function NetGameHelperExeCallback(fd)
    local pending=gamedata.ext.localHelperBusy
    if fd.ser==0 or not pending then return {type=6212,localHelperIgnored=true} end
    local messages=combmessages_pb.CombMessages();messages:ParseFromString(fd.rbuf)
    local quote,info,replayed,reasons=nil,"",false,{}
    local native=combmessages_pb.CombMessages()
    for _,message in ipairs(messages.messages) do
        if message.id==101 then
            local values=ids_pb.Ids();values:ParseFromString(message.data);quote=values.ids
        elseif message.id==102 then info=message.data
        elseif message.id==103 then replayed=true
        elseif message.id==200 then
            local rows=combmessages_pb.CombMessages();rows:ParseFromString(message.data)
            for _,row in ipairs(rows.messages) do reasons[row.id]=row.data end
        else
            local row=native.messages:add();row.id=message.id;row.data=message.data
        end
    end
    local result
    if quote then
        assert(not pending.token,"助手确认收到了新的报价")
        gamedata.ext.localHelperQuote={token=quote[1],raw=pending.raw}
        result={type=6212,helperQuote=true,helperToken=quote[1],helperCost=quote[2],
            helperCount=quote[3],helperSkipped=quote[4],helperInfo=info,params=pending.params,ext=pending.ext}
    elseif replayed then
        result={type=6212,helperAlreadyDone=true}
    else
        assert(pending.token,"助手执行缺少确认报价")
        result=helperExecuteReply({rbuf=native:SerializeToString(),ser=fd.ser})
        for _,row in ipairs(result.data.rewards) do
            local key=tonumber(string.format("%d%02d%02d%d",row.type,row.id,row.index,row.errorcode or 0))
            row.helperMessage=reasons[key]
        end
        gamedata.ext.localHelperQuote=nil
    end
    gamedata.ext.localHelperBusy=nil
    result.helperView=pending.view
    result.helperAction=pending.action
    return result
end
