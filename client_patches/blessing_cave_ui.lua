require("UIBabelTower")
local entry,serial=nil,0
local function page()
    local layer=GameScene.layers.blessingCave
    return layer and layer.show and layer.module.rootNode and layer.module
end
function LocalBlessingCaveContext()
    local current=page()
    if current then return {page=current.localBlessingGeneration} end
    local source=GameScene.layers[GameScene.presentLayer or ""]
    serial=serial+1
    entry={serial=serial,name=GameScene.presentLayer,root=source and source.module.rootNode}
    return {entry=serial}
end
function LocalBlessingCaveActive(view,opening)
    if not view then return false end
    if view.page then
        local current=page()
        return current and current.localBlessingGeneration==view.page
    end
    local source=entry and GameScene.layers[entry.name or ""]
    return opening and entry and view.entry==entry.serial and GameScene.presentLayer==entry.name
        and source and source.show and source.module.rootNode==entry.root
end
local send=UIRequest
function UIRequest(req,...)
    if req.type==6520 or req.type==6521 or req.type==6522 or req.type==7010 and req.sysId==463 then
        req.blessingView=req.blessingView or LocalBlessingCaveContext()
    end
    return send(req,...)
end
local status=UIBlessingCaveStatusQuery
function UIBlessingCaveStatusQuery(t)
    if t.blessingIgnored or not LocalBlessingCaveActive(t.blessingView,true) then return end
    GameScene.vipstatus.xianku_cishu=t.bought or 0
    status(t)
end
local function refresh(t)
    if LocalBlessingCaveActive(t.blessingView) then UIRequest({type=6520,blessingView=t.blessingView}) end
end
function UIBlessingCaveAttack(t)
    if t.blessingIgnored or not LocalBlessingCaveActive(t.blessingView) then return end
    if page().currentcopyPosition~=t.blessingFloor then refresh(t);return end
    RunbattleCallBack("blessingCave",t,function() refresh(t) end)
end
function UIBlessingCaveSweep(t)
    if t.blessingIgnored or not LocalBlessingCaveActive(t.blessingView) then return end
    if page().currentcopyPosition~=t.blessingFloor or not next(t.reward or {}) then refresh(t);return end
    showRewardPopupWindow(t.reward,nil,function() refresh(t) end)
end
local bought=UIXianBuyTimes
function UIXianBuyTimes(t)
    if t.blessingIgnored then return end
    if t.sysId~=463 then return bought(t) end
    if not LocalBlessingCaveActive(t.blessingView) then return end
    GameScene.vipstatus.xianku_cishu=(GameScene.vipstatus.xianku_cishu or 0)+t.buyTime
    refresh(t)
end
