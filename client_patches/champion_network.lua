-- 真实状态序号/价格，读FIFO与收费串行；seq0只校准缓存，绝不消费读队列或重发奖。
local ids=require('ids_pb')
local comb=require('combmessages_pb')
local pending,busy,lastView={},nil,{}
local function fail(msg) return 0,503,{type=503,msg=msg} end
local function state(fd)
    local messages=comb.CombMessages();messages:ParseFromString(fd.rbuf)
    for _,row in ipairs(messages.messages) do if row.id==100 then
        local values=ids.Ids();values:ParseFromString(row.data)
        gamedata.cache.champion.localSerial=values.ids[1]
        gamedata.cache.champion.localLevel=values.ids[2]
        gamedata.cache.champion.localDay=values.ids[3]
    end end
end
local function shelf(fd)
    local values=ids.Ids();values:ParseFromString(fd.rbuf)
    gamedata.cache.championShop.localShelfSerial=values.ids[15]
    gamedata.cache.championShop.localPeriod=values.ids[16]
end
function LocalChampionError(opcode)
    local queue=pending[opcode]
    if not queue then return end
    local req=table.remove(queue,1)
    if busy==opcode then busy=nil;gamedata.ext.localChampionBusy=nil end
    return req
end
for _,entry in ipairs({
    {2700,'UIChampionStatusCallBack','NetChampionStatusCallBack'},
    {2701,'UIChampionBattleCallBack','NetChampionBattleCallBack'},
    {2702,'UIChampionNextCallBack','NetChampionNextCallBack'},
    {2703,'UIChampionResetCallBack','NetChampionResetCallBack'},
    {2704,'UIChampionBoxOpenCallBack','NetChampionBoxOpenCallBack'},
    {2705,'UIChampionCompleteCallBack','NetChampionCompleteCallBack'},
    {2710,'UIChampionShopQueryCallBack','NetChampionShopQueryCallBack'},
    {2711,'UIChampionShopCallBack','NetChampionShopCallBack'},
    {2712,'UIChampionShopResetCallBack','NetChampionShopResetCallBack'},
}) do
    local opcode,send,receive=entry[1],_G[entry[2]],_G[entry[3]]
    local mutation=opcode~=2700 and opcode~=2710
    _G[entry[2]]=function(req)
        if busy or gamedata.ext.localHelperBusy then return fail('试炼/助手正在结算；结果未知请重进游戏') end
        if mutation then for _,queue in pairs(pending) do if #queue>0 then return fail('请等待试炼查询返回') end end end
        local cache=gamedata.cache.champion
        local values
        if mutation and opcode<2710 then
            if not req.championSerial or req.championSerial~=cache.localSerial then return fail('试炼状态已变化，请重新打开页面') end
            values={req.championSerial}
            if opcode==2701 then
                table.insert(values,req.id);req.isauto=(req.isauto==true or req.isauto==1) and 1 or 0
            elseif opcode==2703 then
                req.xgold=gamedata.config.buycount_price[tostring(cache.status.reset+1)].champion_cost
                if req.championGold~=req.xgold then return fail('重置价格已变化') end
                table.insert(values,req.xgold)
            elseif opcode==2704 then
                req.xgold=gamedata.config.buycount_price[tostring(cache.status.boxopen+1)].championbox_cost
                if req.championGold~=req.xgold then return fail('宝箱价格已变化') end
                table.insert(values,req.xgold)
            elseif opcode==2705 then
                if not req.championConfirmed or not req.championCeiling then return fail('请先确认试炼费用上限') end
                table.insert(values,req.path);table.insert(values,req.times);table.insert(values,req.championCeiling)
            end
        elseif mutation then
            local shop=gamedata.cache.championShop
            if not req.championShelf or req.championShelf~=shop.localShelfSerial then return fail('试炼货架已变化，请重新打开商店') end
            if opcode==2711 then
                local current=shop.itemsdata[tonumber(req.id)]
                local row=gamedata.config.champion_goods[tostring(req.goodid)]
                if not current or current.id~=tonumber(req.goodid) or not row then return fail('试炼商品已变化') end
                local cost=gamedata.getIDandNUMs(row.consume)[1]
                if cost.cid~=1009 then return fail('试炼商品费用无效') end
                values={req.championShelf,req.id,req.goodid,req.num,cost.num}
            else
                local cost=gamedata.getIDandNUMs(gamedata.config.global_kv.champion_refreshgold.value)[1]
                if cost.cid~=1009 or (shop.championpoint or 0)<cost.num then return fail('试炼点不足') end
                req.xgold=0;values={req.championShelf,cost.num}
            end
        end
        local mode,mid,raw=send(req)
        if mode==1 then
            if values then local message=ids.Ids();for _,v in ipairs(values) do table.insert(message.ids,v) end;raw=message:SerializeToString() end
            pending[opcode]=pending[opcode] or {};table.insert(pending[opcode],req)
            if mutation then busy=opcode;gamedata.ext.localChampionBusy=opcode;lastView[opcode<2710 and 2700 or 2710]=req.championView end
        end
        return mode,mid,raw
    end
    _G[entry[3]]=function(fd)
        if fd.ser==0 then
            if opcode==2700 or opcode==2710 then
                local result=receive(fd)
                if opcode==2700 then state(fd) else shelf(fd) end
                result.championView=lastView[opcode];result.championSync=true
                result.localChampionIgnored=not result.championView
                return result
            end
            return {type=opcode,localChampionIgnored=true}
        end
        local req=table.remove(pending[opcode] or {},1)
        if not req then return {type=opcode,localChampionIgnored=true} end
        local result=receive(fd)
        if opcode==2700 or opcode==2702 or opcode==2703 then state(fd)
        elseif opcode==2710 or opcode==2712 then shelf(fd) end
        result.championView=req.championView
        if busy==opcode then busy=nil;gamedata.ext.localChampionBusy=nil end
        return result
    end
end
