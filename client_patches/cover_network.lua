require("GameActivitySafeMaskShop")
local cover_pb = require("localcoverupdate_pb")
local ids = require("ids_pb")

local function update(raw)
    local extra = cover_pb.LocalCoverUpdate()
    extra:ParseFromString(raw)
    local mask,masters = ids.Ids(),ids.Ids()
    mask:ParseFromString(extra.mask)
    masters:ParseFromString(extra.masters)
    assert(#mask.ids == 21 and #masters.ids == 7,"魔罩服务端版本不匹配，请重新进入")
    for i,value in ipairs(mask.ids) do assert(value>=0 and value<=(i<=7 and 240 or i<=14 and 18 or 90)) end
    for i,value in ipairs(masters.ids) do assert(value==0 or gamedata.config.mozhao_liandan[tostring(i)][tostring(value)]) end
    gamedata:SafeMask(mask.ids)
    gamedata:SafeMaskMaster(masters.ids)
end

local function samePrice(a,b)
    local function counts(rows)
        local result={}
        for _,v in pairs(rows or {}) do result[v.cid]=(result[v.cid] or 0)+v.num end
        return result
    end
    local x,y=counts(a),counts(b)
    for cid,n in pairs(x) do if y[cid]~=n then return false end end
    for cid,n in pairs(y) do if x[cid]~=n then return false end end
    return true
end

for _,entry in ipairs({
    {3730,"UISlotCoverQueryCallBack","NetSlotCoverQueryCallBack"},
    {3731,"UISlotCoverupCallBack","NetSlotCoverupCallBack"},
    {3732,"UISlotCoverMasterQueryCallBack","NetSlotCoverMasterQueryCallBack"},
    {3733,"UISafeMaskShopQueryCallBack","NetSafeMaskShopQueryCallBack"},
    {3734,"UISafeMaskShopRewardCallBack","NetSafeMaskShopRewardCallBack"},
    {3735,"UISlotCoverLevel2UpCallBack","NetSlotCoverLevel2UpCallBack"},
    {3736,"UISlotCoverFeiShengCallBack","NetSlotCoverFeiShengCallBack"},
}) do
    local opcode,send,receive=entry[1],_G[entry[2]],_G[entry[3]]
    local mutation=opcode==3731 or opcode==3734 or opcode==3735 or opcode==3736
    assert(send and receive,"missing cover callback "..opcode)
    _G[entry[2]]=function(req)
        if mutation and (gamedata.ext.localCoverBusy or gamedata.ext.localFormationBusy or gamedata.ext.localEquipGrowthBusy or gamedata.ext.localSoulBusy) then
            return 0,503,{type=503,msg="魔罩或阵容正在结算，请等待回复；超时请重进游戏"}
        end
        if opcode==3734 and (type(req.num)~="number" or req.num%1~=0 or req.num<1 or req.num>100
            or type(req.gold)~="number" or req.gold%1~=0 or req.gold<=0) then
            return 0,503,{type=503,msg="魔罩购买数量或单价无效，请重新打开商店"}
        end
        if mutation and opcode~=3734 then
            local mask=(gamedata.cache.safemask or {})[tostring(req.sid)]
            if not mask then return 0,503,{type=503,msg="请先重新打开魔罩页面"} end
            local row=opcode==3731 and gamedata.config.mozhao_break[tostring(mask.level)]
                or opcode==3735 and gamedata.config.mozhao_evolve[tostring(mask.level2+1)]
                or opcode==3736 and gamedata.config.mozhao_soaring[tostring(mask.level3+1)]
            local text=row and (opcode==3736 and row.consume or row.lv_cost)
            if not text or text=="" then return 0,503,{type=503,msg="魔罩已达上限"} end
            local price=gamedata.getIDandNUMs(text)
            if not samePrice(req.cost,price) then return 0,503,{type=503,msg="魔罩费用已变化，请重新打开页面"} end
            req.cost=price
        end
        local remote,mid,raw=send(req)
        if remote==1 then
            if opcode==3734 then
                local quote=ids.Ids();table.insert(quote.ids,req.gold)
                raw=raw..quote:SerializeToString()
            end
            local pending=gamedata.ext.localCoverPending or {}
            pending[opcode]=pending[opcode] or {}
            table.insert(pending[opcode],{view=req.coverView,sid=req.sid})
            gamedata.ext.localCoverPending=pending
            if mutation then gamedata.ext.localCoverBusy=opcode end
        end
        return remote,mid,raw
    end
    _G[entry[3]]=function(fd)
        local queue=(gamedata.ext.localCoverPending or {})[opcode] or {}
        local req=table.remove(queue,1)
        if mutation and not req then return {type=opcode,localCoverIgnored=true} end
        update(fd.rbuf)
        local result=receive(fd)
        result.coverView=req and req.view
        result.coverSID=req and req.sid
        result.safemask=gamedata.cache.safemask
        result.safemaskmaster=gamedata.cache.safemaskmaster
        if gamedata.ext.localCoverBusy==opcode then gamedata.ext.localCoverBusy=nil end
        return result
    end
end
