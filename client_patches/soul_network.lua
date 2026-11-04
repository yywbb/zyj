-- 共用库存/目标上下文；未知超时不释放锁，原生错误才允许重试。
require("GameSlotChangeSoul")
require("GameQuickEquip")
require("GameShop")

function UISoulHuntCallBack(req)
    local method = req.param or 1
    local premium = method == 6 or method == 60 or method == 600
    gamedata.ext.soulhuntcost = nil
    if premium then
        local count = method / 6
        local text = gamedata.config.gambling_items["9"]["1"][count == 1 and "once2" or count == 10 and "tenfold2" or "hundredfold2"]
        local cost = gamedata.getIDandNUMs(text)[1]
        local enough, result = gamedata.checkStaffEnough(cost.cid,cost.num,{})
        if not enough then return 0,503,result end
        if gamedata.cache.role.coin < gamedata.config.soul_hunt["6"].coin * count then
            return 0,503,{type=503,msgtype="shortcoin"}
        end
        gamedata.ext.soulhuntcost = {cid=cost.cid,num=-cost.num}
    end
    local data = ids_pb.Ids()
    for _,value in ipairs({method,req.param1 or 0,req.param2 or 0,req.param3 or 0}) do table.insert(data.ids,value) end
    gamedata.ext.soulhuntparam = method
    return 1,2502,data:SerializeToString()
end

local upgrade = UISoulUpgradeCallBack
function UISoulUpgradeCallBack(req)
    if req.preview or req.batch then
        local sid = req.batch and req.batch[2] or req.sid
        local slot = gamedata.cache.slots[sid]
        if not slot or not slot.general or req.general and req.general ~= slot.general then
            return 0,503,{type=503,msg="当前武将已变化，请重新确认"}
        end
        local dust = gamedata.cache.props[20099] and gamedata.cache.props[20099].num or 0
        local budget = req.batch and req.batch[4] or dust
        if budget > dust then return 0,503,{type=503,msg="灵元不足，请重新确认"} end
        local values,items = {0,sid,slot.general,0},{}
        for pos=1,8 do
            local iid = slot["s"..pos] or 0
            local item = gamedata.cache.souls[iid]
            if iid ~= 0 and not item then return 0,503,{type=503,msg="命格已变化，请重新打开"} end
            table.insert(values,iid)
            table.insert(values,item and item.level or 0)
            if item then items[#items+1] = {iid=iid,cid=item.cid,level=item.level} end
        end
        local spent,steps = 0,0
        while true do
            local best,price
            for _,item in ipairs(items) do
                local row = gamedata.config.soul[tostring(item.cid)]
                local gate = gamedata.config.soul_integrate_lv[tostring(item.level+1)]
                local cost = row.upexp * 2^(item.level-1)
                if item.level < row.limit1 and (not gate or gamedata.cache.role.level >= gate.battle_lv) and cost <= budget-spent
                    and (not best or item.level < best.level or item.level == best.level and item.iid < best.iid) then
                    best,price = item,cost
                end
            end
            if not best then break end
            best.level = best.level+1
            spent,steps = spent+price,steps+1
        end
        if spent == 0 then return 0,503,{type=503,msg="无可强化的已装备命格：灵元不足或已到等级上限"} end
        values[4] = spent
        if req.preview then
            return 0,2504,{type=2504,soulPreview=values,soulSteps=steps,soulView=req.soulView}
        end
        for i=1,20 do
            if req.batch[i] ~= values[i] then return 0,503,{type=503,msg="命格或强化消耗已变化，请重新确认"} end
        end
        local data = ids_pb.Ids()
        for _,value in ipairs(values) do table.insert(data.ids,value) end
        gamedata.ext.SoulUpgrade = {prop=spent}
        req.soulSteps = steps
        return 1,2504,data:SerializeToString()
    end
    local item = gamedata.cache.souls[req.iid]
    if not item then return 0,503,{type=503,msg="命格已变化，请重新打开"} end
    req.prop = gamedata.config.soul[tostring(item.cid)].upexp * 2^(item.level-1)
    return upgrade(req)
end

for _,entry in ipairs({
    {2501,"UISoulHuntQueryCallBack","NetSoulHuntQueryCallBack"},
    {2502,"UISoulHuntCallBack","NetSoulHuntCallBack"},
    {2503,"UISoulExchangeCallBack","NetSoulExchangeCallBack"},
    {2504,"UISoulUpgradeCallBack","NetSoulUpgradeCallBack"},
    {2505,"UISoulHunt41CallBack","NetSoulHunt41CallBack"},
    {2506,"UISoulResolveCallBack","NetSoulResolveCallBack"},
    {2507,"UISoulCompoundCallBack","NetSoulCompoundCallBack"},
    {1006,"UISlotChangeSoulCallBack","NetSlotChangeSoulCallBack"},
    {1007,"UIQuickEquipCallBack","NetQuickEquipCallBack"},
    {5345,"UIActivityBuyItemCallBack","NetActivityBuyItemCallBack"},
}) do
    local opcode,send,receive = entry[1],_G[entry[2]],_G[entry[3]]
    local mutation = opcode ~= 2501
    _G[entry[2]] = function(req)
        if mutation and (gamedata.ext.localSoulBusy or gamedata.ext.localFormationBusy or gamedata.ext.localEquipGrowthBusy) then
            return 0,503,{type=503,msg="命格或阵容正在结算，请等待回复；超时请重进游戏"}
        end
        local mode,mid,raw = send(req)
        if mode == 1 then
            local pending = gamedata.ext.localSoulPending or {}
            local queue = pending[opcode] or {}
            table.insert(queue,{soulView=req.soulView,iid=req.iid,ids=req.ids,item=req.data and req.data.id,soulSteps=req.soulSteps})
            pending[opcode] = queue
            gamedata.ext.localSoulPending = pending
            if mutation then gamedata.ext.localSoulBusy = opcode end
        end
        return mode,mid,raw
    end
    _G[entry[3]] = function(fd)
        local queue = (gamedata.ext.localSoulPending or {})[opcode] or {}
        local req = table.remove(queue,1) or {}
        local result = receive(fd)
        result.soulView,result.soulIID,result.soulIds,result.soulItem = req.soulView,req.iid,req.ids,req.item
        result.soulSteps = req.soulSteps
        if gamedata.ext.localSoulBusy == opcode then gamedata.ext.localSoulBusy = nil end
        return result
    end
end

for _,name in ipairs({"UISoulsCallBack","UIPropQueryByIdCallback"}) do
    local send = _G[name]
    _G[name] = function(req)
        local mode,mid,result = send(req)
        if mode == 0 and result then result.soulView = req.soulView end
        return mode,mid,result
    end
end
