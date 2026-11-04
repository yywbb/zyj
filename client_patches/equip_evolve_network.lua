-- 与强化/洗炼/换装共用在途锁；费用取本地同版配置，不取UI报价。
require("GameEquipStarUp")
require("GameEquipStrengthen")
require("GameEquipRefine")
require("GameSlotChangeEquip")
require("GameQiankunlu")
require("GameTreasureUp")

local function price(req,opcode)
    local item = gamedata.cache.equips[tonumber(req.iid)]
    if not item then return end
    if opcode == 5521 then
        local count,row = tonumber(req.count),gamedata.config.equip[tostring(item.cid)]
        if not count or count%1 ~= 0 or count < 1 or count > 10 or not row or row.quality < 3
            or item.level4+count > math.min(gamedata.cache.role.level,row.forging_maxlevel) then return end
        local total,result = {},{}
        for level = item.level4+1,item.level4+count do
            local step = gamedata.config.equip_forgingConsume[tostring(level)]
            local text = step and step["quality"..row.quality]
            if not text or text == "" then return end
            for _,cost in ipairs(gamedata.getIDandNUMs(text)) do total[cost.cid] = (total[cost.cid] or 0)+cost.num end
        end
        for cid,num in pairs(total) do table.insert(result,{cid=cid,num=num}) end
        return result
    end
    if opcode == 1123 or opcode == 1127 then
        local rows = opcode == 1127 and gamedata.config.treasure2_star or gamedata.config.equip_star
        local row = rows[tostring(item.level3+1)]
        return row and gamedata.getIDandNUMs(row["cost_"..item.quality])
    end
    local cid,level = item.cid,item.level2+1
    local row = gamedata.config.equip_evolve[tostring(cid)]
    if not row then return end
    if item.level2 >= row.level then cid,level = row.evolve,1 end
    local cost = gamedata.config.equip_evolveconsume[tostring(cid)]
    if not cost or not cost["consume"..level] or cost["consume"..level] == "" then return end
    local result = gamedata.getIDandNUMs(cost["consume"..level])
    for _,material in ipairs(gamedata.getIDandNUMs(cost["equip"..level])) do table.insert(result,material) end
    return result
end

for _,entry in ipairs({
    {1122,"UIEquipStageUpCallBack","NetEquipStageUpCallBack"},
    {1123,"UIEquipStarUpCallBack","NetEquipStarUpCallBack"},
    {1127,"UITreasureStarUpCallBack","NetTreasureStarUpCallBack"},
    {5521,"UIEquipCastCallBack","NetEquipCastCallBack"},
    {1101,"UIEquipStrengthenCallBack","NetEquipStrengthenCallBack"},
    {1109,"UIQuickEquipStrengthenCallBack","NetQuickEquipStrengthenCallBack"},
    {1120,"UIEquipBaptizePreviewCallBack","NetEquipBaptizePreviewCallBack"},
    {1121,"UIEquipBaptizeConfirmCallBack","NetEquipBaptizeConfirmCallBack"},
    {1124,"UIEquipBaptizeAutomaticCallBack","NetEquipBaptizeAutomaticCallBack"},
    {1005,"UISlotChangeEquipCallBack","NetSlotChangeEquipCallBack"},
    {1007,"UIQuickEquipCallBack","NetQuickEquipCallBack"},
    {1117,"UIEquipResetCallBack","NetEquipResetCallBack"},
    {1104,"UIEquipResolveCallBack","NetEquipResolveCallBack"},
}) do
    local opcode,send,receive = entry[1],_G[entry[2]],_G[entry[3]]
    _G[entry[2]] = function(req)
        if gamedata.ext.localEquipGrowthBusy or gamedata.ext.localTreasureBusy or gamedata.ext.localBaptizeBusy or gamedata.ext.localFormationBusy or gamedata.ext.localSoulBusy then
            return 0,503,{type=503,msg="装备或阵容正在结算，请等待回复；超时请重进游戏"}
        end
        local rows
        if opcode == 1122 or opcode == 1123 or opcode == 1127 or opcode == 5521 then
            rows = price(req,opcode)
            if not rows or not next(rows) then return 0,503,{type=503,msg="装备没有可用的下一阶，请重新选择"} end
            req.props = rows
        end
        local mode,mid,raw = send(req)
        if mode == 1 then
            gamedata.ext.localEquipGrowthBusy = {opcode=opcode,iid=req.iid,view=req.growthView,rows=rows}
        end
        return mode,mid,raw
    end
    _G[entry[3]] = function(fd)
        local req = gamedata.ext.localEquipGrowthBusy
        if opcode == 5521 and (not req or req.opcode ~= opcode) then return {type=5521} end
        local result = receive(fd)
        if req and req.opcode == opcode then
            if req.rows and opcode ~= 5521 then
                for _,row in ipairs(req.rows) do
                    if (opcode ~= 1127 or row.cid == 1000) and (row.cid == 1000 or gamedata.config.props[tostring(row.cid)]) then
                        gamedata:updateStaff({cid=row.cid,num=-row.num})
                    end
                end
            end
            result.growthView,result.growthIID = req.view,req.iid
            gamedata.ext.localEquipGrowthBusy = nil
        end
        return result
    end
end

local query = UIPropQueryByIdCallback
function UIPropQueryByIdCallback(req)
    local mode,mid,result = query(req)
    if mode == 0 and result then result.growthView = req.growthView end
    return mode,mid,result
end
