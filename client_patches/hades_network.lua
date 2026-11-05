-- 读FIFO避seq0；两种首通突变与普通副本共享锁，未知结果不重试。
local pending,busy={},nil
local function fail() return 0,503,{type=503,msg='副本正在结算，请等待回复；结果未知请重进游戏'} end
function LocalHadesError(opcode)
    local req=table.remove(pending[opcode] or {},1)
    if busy==opcode then
        busy=nil;gamedata.ext.localHadesBusy=nil
        if gamedata.ext.localAutoCopyBusy and gamedata.ext.localAutoCopyBusy.type==opcode then gamedata.ext.localAutoCopyBusy=nil end
    end
    return req
end
for _,entry in ipairs({
    {1370,'UIHadesCopyQueryCallback','NetHadesCopyQueryCallback'},
    {1371,'UIHadesCopyAttackCallback','NetHadesCopyAttackCallback'},
    {1372,'UIHadesCopyGetBoxCallback','NetHadesCopyGetBoxCallback'},
}) do
    local opcode,send,receive=entry[1],_G[entry[2]],_G[entry[3]]
    _G[entry[2]]=function(req)
        if busy or gamedata.ext.localAutoCopyBusy or gamedata.ext.localActivityCopyBusy or gamedata.ext.localHelperBusy then return fail() end
        local mode,mid,raw=send(req)
        if mode==1 then
            pending[opcode]=pending[opcode] or {};table.insert(pending[opcode],req)
            if opcode~=1370 then
                busy=opcode;gamedata.ext.localHadesBusy=opcode;gamedata.ext.localAutoCopyBusy={type=opcode}
            end
        end
        return mode,mid,raw
    end
    _G[entry[3]]=function(fd)
        local req=fd.ser~=0 and table.remove(pending[opcode] or {},1) or nil
        if opcode~=1370 and (not req or busy~=opcode) then return {type=opcode,localHadesIgnored=true} end
        if opcode==1370 then gamedata.cache.hadescopy={attacknum=0,sections={}} end
        if opcode==1371 then gamedata.ext.hadesCopyAttackParams=req end
        local result=receive(fd)
        result.hadesView=req and req.hadesView
        result.localHadesIgnored=not req
        if busy==opcode then
            busy=nil;gamedata.ext.localHadesBusy=nil;gamedata.ext.localAutoCopyBusy=nil
        end
        return result
    end
end
for _,name in ipairs({'UIActivityCoinCopyCallback','UIActivityExpDanCopyCallback','UIActivityForgeStoneCopyCallback',
    'UIActivityEquipStarCopyCallback','UIActivityZhenfuCopyCallback','UIActivityForgingCopyCallback'}) do
    local send=_G[name]
    _G[name]=function(req)
        if gamedata.ext.localHadesBusy then return fail() end
        return send(req)
    end
end
