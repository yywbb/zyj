require("GameActivitySafeMaskShop")
local cover_pb = require("localcoverupdate_pb")
local ids = require("ids_pb")

-- 旧版 protobuf 无法跳过未知字段，两套描述符只能接收各自的字段。
local function split(raw)
    local native,extra,seen={},{},{}
    local pos=1
    local function varint()
        local value,factor=0,1
        for i=1,10 do
            local byte=raw:byte(pos)
            assert(byte and (i<10 or byte<=1),"魔罩回包整数无效")
            pos=pos+1
            value=value+(byte%128)*factor
            if byte<128 then return value end
            factor=factor*128
        end
    end
    while pos<=#raw do
        local start=pos
        local tag=varint()
        assert(tag>=8 and tag<4294967296,"魔罩回包字段无效")
        local number,wire=math.floor(tag/8),tag%8
        if wire==0 then varint()
        elseif wire==1 then pos=pos+8
        elseif wire==2 then
            local size=varint()
            pos=pos+size
        elseif wire==5 then pos=pos+4
        else error("魔罩回包类型无效") end
        assert(pos<=#raw+1,"魔罩回包已截断")
        local field=raw:sub(start,pos-1)
        if number==100 or number==101 then
            assert(wire==2 and not seen[number],"魔罩扩展字段无效")
            seen[number]=true
            table.insert(extra,field)
        else table.insert(native,field) end
    end
    assert(seen[100] and seen[101],"魔罩服务端版本不匹配，请重新进入")
    return table.concat(native),table.concat(extra)
end

local function update(raw)
    local native,extension=split(raw)
    local extra = cover_pb.LocalCoverUpdate()
    extra:ParseFromString(extension)
    local mask,masters = ids.Ids(),ids.Ids()
    mask:ParseFromString(extra.mask)
    masters:ParseFromString(extra.masters)
    assert(#mask.ids == 21 and #masters.ids == 7,"魔罩服务端版本不匹配，请重新进入")
    for i,value in ipairs(mask.ids) do assert(value>=0 and value<=(i<=7 and 240 or i<=14 and 18 or 90)) end
    for i,value in ipairs(masters.ids) do assert(value==0 or gamedata.config.mozhao_liandan[tostring(i)][tostring(value)]) end
    gamedata:SafeMask(mask.ids)
    gamedata:SafeMaskMaster(masters.ids)
    return native
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
        local result=receive({rbuf=update(fd.rbuf)})
        result.coverView=req and req.view
        result.coverSID=req and req.sid
        result.safemask=gamedata.cache.safemask
        result.safemaskmaster=gamedata.cache.safemaskmaster
        if gamedata.ext.localCoverBusy==opcode then gamedata.ext.localCoverBusy=nil end
        return result
    end
end
