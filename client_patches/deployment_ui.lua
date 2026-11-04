function LocalDeploymentContext(property)
    local layer=GameScene.layers.deployment or {}
    local page=layer.module or {}
    local window=(gameWindows.windows.deploymentLevelUp or {}).module or {}
    return {page=page.localDeploymentGeneration,window=window.localDeploymentGeneration,
        id=window.showindex,level=(window.slotSpirit and window.slotSpirit.level or {})[tostring(window.showindex)],property=property}
end

function LocalDeploymentActive(view,window)
    local layer=GameScene.layers.deployment
    if not view or not layer or not layer.show or not layer.module.rootNode or layer.module.localDeploymentGeneration~=view.page then return false end
    if window then
        local current=gameWindows.windows.deploymentLevelUp
        if not current or not current.show or not current.module.rootNode or current.module.localDeploymentGeneration~=view.window
            or current.module.showindex~=view.id then return false end
        if view.property and (current.module.slotSpirit.level or {})[tostring(view.id)]~=view.level then return false end
    end
    return true
end

local send=UIRequest
function UIRequest(req,...)
    if req.type==4200 or req.type==4201 or req.type==4202 or req.type==4204 or req.type==12001 and req.order==42021 then
        req.deploymentView=req.deploymentView or LocalDeploymentContext(req.type==12001)
        if req.type==4202 then
            if not LocalDeploymentActive(req.deploymentView,true) then return end
            req.level=req.deploymentView.level
        end
    end
    return send(req,...)
end

local function update(t)
    if t.localDeploymentIgnored then return end
    local page=GameScene.layers.deployment
    if t.type==4203 then
        if not page or not page.show or not page.module.rootNode then return end
    elseif not LocalDeploymentActive(t.deploymentView) then return end
    if t.slotSpirit then
        page.module:reloadSlotSpirit(t.slotSpirit)
        local window=gameWindows.windows.deploymentLevelUp
        if window and window.show and window.module.rootNode and (t.type==4203 or LocalDeploymentActive(t.deploymentView,true)) then
            window.module:reload(t.slotSpirit)
        end
    end
end
UISlotSpiritQuery=update
UISlotSpiritUse=update
UISlotSpiritChange=update
function UISlotSpiritLevelup(t)
    if t.localDeploymentIgnored then return end
    GameScene:addUpdate(10021);GameScene:addUpdate(10023)
    update(t)
    if LocalDeploymentActive(t.deploymentView,true) then UIRequest({type=4204,opt="up"}) end
end

function UISlotSpiritAdditionQuery(t)
    if not LocalDeploymentActive(t.deploymentView,t.opt=="up") then return end
    if t.opt=="addmain" then
        local window=gameWindows.windows.deploymentUp
        if window.show then window.module:reload(t.data)
        else gameWindows:openWindow("deploymentUp",t.data) end
    elseif t.opt=="up" then gameWindows.windows.deploymentLevelUp.module:reloadAddition(t.data) end
end
