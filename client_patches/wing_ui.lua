local send=UIRequest
function UIRequest(req,...)
    local opcode=tonumber(req.type)
    if opcode and opcode >= 3740 and opcode <= 3744 then
        local page=package.loaded.Layer_wing_main
        local window=package.loaded.window_wingColor
        req.wingView={page=page and page.localWingGeneration,window=window and window.localWingGeneration}
    end
    return send(req,...)
end

for _,entry in ipairs({{3740,"UIWingQuary"},{3741,"UIWingSatrUp"},{3742,"UIWingStageUp"},
                       {3743,"UIWingDyeing"},{3744,"UIWingColorQuery"}}) do
    local opcode,callback=entry[1],_G[entry[2]]
    _G[entry[2]]=function(t)
        if t.localWingIgnored then return end
        local page=package.loaded.Layer_wing_main
        local window=package.loaded.window_wingColor
        local view=t.wingView or {}
        local activePage=page and page.rootNode and view.page==page.localWingGeneration
            and GameScene.layers.lead and GameScene.layers.lead.show
        local activeWindow=window and window.rootNode and view.window==window.localWingGeneration
        if (opcode == 3744 and activeWindow) or (opcode ~= 3744 and (activePage or opcode==3743 and activeWindow)) then
            return callback(t)
        end
        if t.protagonist then GameScene.protagonist=t.protagonist end
        GameScene:addUpdate(1200)
        GameScene:addUpdate(10021)
    end
end
