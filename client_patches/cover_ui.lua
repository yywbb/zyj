-- 魔罩整组状态更新绑定页面世代；动画另绑定付费目标。
local send=UIRequest
function UIRequest(req,...)
    if req.type>=3730 and req.type<=3736 then
        local page=package.loaded.Layer_safemask
        local shop=package.loaded.Layer_activity_safemaskshop
        local slot=page and page.slotdata and page.slotdata[tostring(page.generalindex)]
        req.coverView={generation=page and page.localCoverGeneration,tab=page and page.selectpage,
                       sid=slot and slot.sid,shop=shop and shop.localCoverGeneration}
    end
    return send(req,...)
end

local function page(t)
    local module=package.loaded.Layer_safemask
    if module and module.rootNode and GameScene.layers.safemask.show and t.coverView
        and t.coverView.generation==module.localCoverGeneration then return module end
end
local function sync(t,animation)
    if t.localCoverIgnored then return end
    local info=GameScene.layers.slotsInfo
    if info and info.module then info.module.safemask=t.safemask end
    for _,id in ipairs({10021,10023,1200}) do GameScene:addUpdate(id) end
    local current=page(t)
    if not current then return end
    current:ReloadData(t)
    current:ReloadMasterData(t)
    local slot=current.slotdata and current.slotdata[tostring(current.generalindex)]
    if animation and slot and t.coverSID==slot.sid and t.coverView.tab==current.selectpage then current[animation](current) end
end
function UISlotCoverQuery(t) sync(t) end
function UISlotCoverMasterQuery(t)
    if t.localCoverIgnored then return end
    local current=page(t)
    if current then current:ReloadMasterData(t) end
end
function UISlotCoverup(t) sync(t,"ReloadUpData") end
function UISlotCoverLevel2Up(t) sync(t,"ReloadEvolveData") end
function UISlotCoverFeiSheng(t) sync(t,"ReloadFeiShengData") end
