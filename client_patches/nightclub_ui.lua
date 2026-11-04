local send=UIRequest
function UIRequest(req,...)
    local opcode=tonumber(req.type)
    if opcode and ((opcode>=4500 and opcode<=4505) or (opcode>=4509 and opcode<=4511)) then
        local page=GameScene.layers[GameScene.presentLayer]
        local module=page and page.module
        req.nightclubView={page=GameScene.presentLayer,generation=module and module.localNightclubGeneration}
        if opcode==4504 and module and module.data then req.nightclubToken={stamp=module.data["7"]} end
        if opcode==4505 then
            local window=package.loaded.window_nightclubchance
            req.nightclubToken=window and window.localNightclubToken
            req.nightclubView.window=window and window.localNightclubGeneration
        end
        if opcode==4510 and module then
            req.nightclubTokens={}
            for floor,row in pairs(module.data or {}) do req.nightclubTokens[tostring(floor)]=row["7"] end
        end
    end
    return send(req,...)
end

function localNightclubCurrent(t)
    if t.localNightclubIgnored then return false end
    local view=t.nightclubView or {}
    local page=GameScene.layers[view.page]
    local module=page and page.module
    if not page or not page.show or not module or not module.rootNode or view.generation~=module.localNightclubGeneration then return false end
    if t.nightclubFloor and module.m_iIndex and tonumber(module.m_iIndex)~=t.nightclubFloor then return false end
    if t.type==4505 then
        local window=package.loaded.window_nightclubchance
        if not window or not window.rootNode or view.window~=window.localNightclubGeneration then return false end
    end
    return true
end

for _,name in ipairs({"UIUserPatrolQuery","UIUserPatrolStatus","UIUserPatrolAttack","UIUserPatrolDo",
    "UIUserPatrolReward","UIUserPatrolEventDo","UserPatrolOneAdd","UserPatrolOneAddReward","UserPatrolOneAddQuery"}) do
    local receive=_G[name]
    _G[name]=function(t) if localNightclubCurrent(t) then return receive(t) end end
end
