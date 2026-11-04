function LocalLeadGrowthVisible(name)
    local layer=GameScene.layers.lead
    return layer and layer.show and layer.module.selectpage==name
end

function LocalLeadGrowthContext(name,kind)
    local lead=(GameScene.layers.lead or {}).module or {}
    local page=(lead.modules or {})[name] or {}
    local general=(page.data or {}).general or {}
    return {page=name,lead=lead.localLeadGrowthGeneration,generation=page.localLeadGrowthGeneration or 0,
        kind=kind,stage=page.m_iRunCellIndex,step=page.m_iRunNowsIndex,iid=general.iid,level=general.skilllevel or 0}
end

function LocalLeadGrowthActive(view)
    local layer=GameScene.layers.lead
    if not view or not LocalLeadGrowthVisible(view.page) or layer.module.localLeadGrowthGeneration~=view.lead then return false end
    local page=layer.module.modules[view.page]
    if not page or not page.rootNode or (page.localLeadGrowthGeneration or 0)~=view.generation then return false end
    if view.kind=="property" then
        if view.page=="gamestar" then return page.m_iRunCellIndex==view.stage and page.m_iRunNowsIndex==view.step end
        local general=(page.data or {}).general or {}
        return general.iid==view.iid and (general.skilllevel or 0)==view.level
    end
    return true
end

local send=UIRequest
function UIRequest(req,...)
    local opcode=tonumber(req.type)
    if opcode==3720 or opcode==3721 or opcode==3722 or opcode==1058 or opcode==12001 and (req.order==10771 or req.order==33018) then
        local lead=(GameScene.layers.lead or {}).module or {}
        local name=(opcode==1058 or req.order==33018) and "awaken" or (opcode==12001 and "gamestar" or lead.selectpage)
        req.leadGrowthView=LocalLeadGrowthContext(name,opcode==12001 and "property" or opcode==3720 and "query" or "mutation")
        if opcode==1058 then req.iid,req.level=req.leadGrowthView.iid,req.leadGrowthView.level end
    end
    return send(req,...)
end

function UIProtagonistGameQuery(t)
    if t.localLeadGrowthIgnored or not LocalLeadGrowthActive(t.leadGrowthView) then return end
    local lead=GameScene.layers.lead.module
    if t.leadGrowthView.page=="gamestar" then lead:pageDataCallback("gamestar","reloadData",t)
    elseif t.leadGrowthView.page=="mogong" then lead:pageDataCallback("mogong","setgamestar",t) end
end

local function update(t)
    if t.localLeadGrowthIgnored then return false end
    if t.protagonist then GameScene.protagonist=t.protagonist end
    GameScene:addUpdate(10021);GameScene:addUpdate(10023)
    return LocalLeadGrowthActive(t.leadGrowthView)
end

function UIProtagonistGameEatBeans(t)
    if update(t) then UIRequest({type=3720}) end
end

function UIProtagonistGamePopcorn(t)
    if update(t) then GameScene.layers.lead.module:pageDataCallback("gamestar","boom",t) end
end

function UIProtagonistAwaken(t)
    if update(t) then GameScene.layers.lead.module:pageDataCallback("awaken","awakenCallback",t.protagonist) end
end
