-- 收费串行、查询FIFO；原生PB不认识扩展字段，先分离本玩法的绝对状态。
local ids = require("ids_pb")
local query = NetDragonWishingQueryCallBack
local function split(raw)
    local pos,native,state=1,{},nil
    local function varint()
        local value,factor=0,1
        for i=1,10 do
            local byte=raw:byte(pos);assert(byte and (i<10 or byte<=1),"神龙回包整数无效")
            pos=pos+1;value=value+(byte%128)*factor
            if byte<128 then return value end
            factor=factor*128
        end
    end
    while pos<=#raw do
        local start=pos
        local tag=varint();local number,wire=math.floor(tag/8),tag%8
        assert(number>0 and number<536870912,"神龙回包字段无效")
        local payload
        if wire==0 then varint()
        elseif wire==1 then pos=pos+8
        elseif wire==2 then local size=varint();payload=raw:sub(pos,pos+size-1);pos=pos+size
        elseif wire==5 then pos=pos+4
        else error("神龙回包类型无效") end
        assert(pos<=#raw+1,"神龙回包已截断")
        if number==100 then assert(wire==2 and not state,"神龙状态重复");state=payload
        else native[#native+1]=raw:sub(start,pos-1) end
    end
    assert(state,"神龙服务端版本不匹配，请重新进入")
    return table.concat(native),state
end

local function reject(message) return 0,503,{type=503,msg=message} end
for _,entry in ipairs({
    {4901,"Query"},{4902,"Get"},{4903,"Reward"},{4904,"Event"},{4905,"EventClose"},{4906,"Shop"},{4907,"QueryMap"},
}) do
    local opcode,suffix=entry[1],entry[2]
    local send,receive=_G["UIDragonWishing"..suffix.."CallBack"],_G["NetDragonWishing"..suffix.."CallBack"]
    local mutation=opcode>=4902 and opcode<=4906
    _G["UIDragonWishing"..suffix.."CallBack"]=function(req)
        local values,state=nil,gamedata.ext.localDragonState
        if mutation then
            if gamedata.ext.localDragonBusy then return reject("神龙正在结算，请等待回复；超时请重进游戏") end
            if not state or req.dragonSerial~=state.serial then return reject("神龙状态已变化，请重新打开页面或事件") end
            local gold=0
            if opcode==4902 then
                if state.dicenum==0 then
                    local last=0;for key in pairs(gamedata.config.buycount_price) do last=math.max(last,tonumber(key)) end
                    gold=gamedata.config.buycount_price[tostring(math.min(last,state.dicebuy+1))].shenlong_dice_cost
                end
                if req.auto==1 and gold>0 then return reject("没有免费骰子，一键探索已停止，未自动购买") end
                if tonumber(req.xgold or 0)~=gold then return reject("骰子价格已变化，请刷新") end
                values={state.serial,gold,req.auto==1 and 1 or 0}
            elseif opcode==4903 then values={req.id,state.serial}
            elseif opcode==4904 then
                if req.opt==2 and state.eventid>=6 and state.eventid<=9 then gold=tonumber(gamedata.config.global_kv.shenlong_skip.value) end
                if tonumber(req.xgold or 0)~=gold then return reject("事件费用已变化，请重新打开") end
                values={req.opt,state.serial}
            elseif opcode==4905 then values={state.serial}
            else
                local level=999
                for key in pairs(gamedata.config.shenlong_discount) do if tonumber(key)>=gamedata.cache.role.level then level=math.min(level,tonumber(key)) end end
                local row=(gamedata.config.shenlong_discount[tostring(level)] or {})[tostring(req.id)]
                local num=req.num or 1
                if not row or type(num)~="number" or num%1~=0 or num<1 or num>100 then return reject("神龙商品无效") end
                gold=row.price*num
                if tonumber(req.xgold)~=gold then return reject("商品价格已变化，请重新打开商店") end
                values={req.id,num,row.price,state.serial}
            end
            req.xgold=gold
        end
        local mode,mid,raw=send(req)
        if mode==1 then
            if values then local message=ids.Ids();for _,v in ipairs(values) do table.insert(message.ids,v) end;raw=message:SerializeToString() end
            local pending=gamedata.ext.localDragonPending or {};pending[opcode]=pending[opcode] or {}
            table.insert(pending[opcode],req);gamedata.ext.localDragonPending=pending
            if mutation then gamedata.ext.localDragonBusy=opcode end
        end
        return mode,mid,raw
    end
    _G["NetDragonWishing"..suffix.."CallBack"]=function(fd)
        local req=table.remove((gamedata.ext.localDragonPending or {})[opcode] or {},1)
        if not req then return {type=opcode,localDragonIgnored=true} end
        local state
        if mutation then
            local raw,extra=split(fd.rbuf);fd={rbuf=raw}
            state=query({rbuf=extra}).dragonwishing
        end
        local result=receive(fd)
        if opcode==4901 then state=result.dragonwishing;result.opt=req.opt or 0 end
        if state then assert(state.serial and state.serial>0,"神龙状态缺少版本");gamedata.ext.localDragonState=state;result.dragonstate=state end
        result.dragonView=req.dragonView
        if gamedata.ext.localDragonBusy==opcode then gamedata.ext.localDragonBusy=nil end
        return result
    end
end
