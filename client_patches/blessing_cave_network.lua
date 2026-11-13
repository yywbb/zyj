-- 原生回调先完成资源入账；FIFO/在途锁避免重复扣费和迟到回包串页。
require("GameBabelTower")
local pending,busy,copyLock={},nil,nil
local function fail()
    return 0,503,{type=503,msg="副本正在结算，请等待回复；结果未知请重进游戏"}
end
local function blocked()
    return busy or gamedata.ext.localAutoCopyBusy or gamedata.ext.localActivityCopyBusy
        or gamedata.ext.localHadesBusy or gamedata.ext.localHelperBusy
end
local function remember(opcode,req)
    pending[opcode]=pending[opcode] or {}
    table.insert(pending[opcode],req)
    if opcode~=6520 then
        busy=opcode;gamedata.ext.localBlessingCaveBusy=opcode
        if opcode~=7010 or req.sysId==463 then
            copyLock={type=opcode};gamedata.ext.localAutoCopyBusy=copyLock
        end
    end
end
local function release(opcode)
    if busy and busy==opcode then
        busy=nil;gamedata.ext.localBlessingCaveBusy=nil
        if copyLock and gamedata.ext.localAutoCopyBusy==copyLock then gamedata.ext.localAutoCopyBusy=nil end
        copyLock=nil
    end
end
function LocalBlessingCaveError(opcode)
    local req=table.remove(pending[opcode] or {},1)
    if req then release(opcode) end
    return req
end
for _,entry in ipairs({
    {6520,"UIBlessingCaveStatusCallBack","NetBlessingCaveStatusCallBack"},
    {6521,"UIBlessingCaveAttackCallBack","NetBlessingCaveAttackCallBack"},
    {6522,"UIBlessingCaveSweepCallBack","NetBlessingCaveSweepCallBack"},
}) do
    local opcode,send,receive=entry[1],_G[entry[2]],_G[entry[3]]
    _G[entry[2]]=function(req)
        if blocked() then return fail() end
        local mode,mid,raw=send(req)
        if mode==1 then remember(opcode,req) end
        return mode,mid,raw
    end
    _G[entry[3]]=function(fd)
        local req=fd.ser~=0 and table.remove(pending[opcode] or {},1) or nil
        if not req or opcode~=6520 and busy~=opcode then return {type=opcode,blessingIgnored=true} end
        local result=receive(fd)
        result.blessingView=req.blessingView
        result.blessingFloor=req.id
        release(opcode)
        return result
    end
end
local buy,receiveBuy=UIXianBuyTimesCallBack,NetXianBuyTimesCallBack
function UIXianBuyTimesCallBack(req)
    if busy or req.sysId==463 and blocked() then return fail() end
    if req.sysId==463 and (type(req.times)~="number" or req.times<=0 or req.times~=math.floor(req.times)
        or type(req.spend)~="number" or req.spend<0 or req.spend~=math.floor(req.spend)) then
        return 0,503,{type=503,msg="请重新打开福祉天宫次数购买窗口"}
    end
    local mode,mid,raw=buy(req)
    if mode==1 then
        if req.sysId==463 then
            local data=require("ids_pb").Ids()
            for _,value in ipairs({463,req.times,req.spend}) do table.insert(data.ids,value) end
            raw=data:SerializeToString()
        end
        remember(7010,req)
    end
    return mode,mid,raw
end
function NetXianBuyTimesCallBack(fd)
    local req=fd.ser~=0 and table.remove(pending[7010] or {},1) or nil
    if not req or busy~=7010 then return {type=7010,blessingIgnored=true} end
    gamedata.ext.XianBuyInfo=req
    local result=receiveBuy(fd)
    result.blessingView=req.blessingView
    release(7010)
    return result
end
