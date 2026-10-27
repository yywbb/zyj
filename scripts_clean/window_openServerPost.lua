
local openServerPost = {
    rootNode = nil,
    rootItems = nil,
    needcallback = true,

    cancelTip = "chongbang",
}

function openServerPost.open(self,touchPriority,data,callback)
    local curID = data.activityId;

    print("  openServerPost curID ",curID)
    if curID == 113 then
        self.rootNode, self.rootItems = CCBReaderLoad("MainScene/ts_dengjizhengba", nil, true, "ts_dengjizhengba")
    elseif curID == 370 then
        self.rootNode, self.rootItems = CCBReaderLoad("MainScene/ts_mowangzhengba", nil, true, "ts_mowangzhengba")
    elseif curID == 371 then
        self.rootNode, self.rootItems = CCBReaderLoad("MainScene/ts_mofuzhengba", nil, true, "ts_mofuzhengba")
    elseif curID == 372 or curID == 387 or curID == 388 then
        self.rootNode, self.rootItems = CCBReaderLoad("MainScene/ts_zhanlizhengba", nil, true, "ts_zhanlizhengba")
    elseif curID == 408 or curID == 405 or curID == 406 or curID == 409 or curID == 410 or curID == 407 then
        -- 翅膀 法宝 副本 命格  伙伴战力 魔罩
        local iconRes = "chibangdengjituisongpost"
        self.rootNode, self.rootItems = CCBReaderLoad("MainScene/ts_zhanlizhengba", nil, true, "ts_zhanlizhengba")
        if curID == 405 then
            iconRes = "fabaozhanlituisongpost"
        elseif curID == 406 then
            iconRes = "fubenxingjituisongpost"
        elseif curID == 409 then
            iconRes = "minggezhanlituisongpost"
        elseif curID == 410 then
            iconRes = "huobanjingjituisongpost"
        elseif curID == 407 then
            iconRes = "mozhaozhanlituisongpost"
        end
        setSpriteFrameByName(self.rootItems.contentIcon, iconRes)
    end
    printT(self.rootItems," self.rootItems openServerPost")
    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.rootNode
end

function openServerPost.reload(self,data,callback)
    local configData = gamedata.config.toplevel[tostring(1)]
    if data.activityId == 370 then
        configData = gamedata.config.combat_rank[tostring(1)]
    elseif data.activityId == 371 then
        configData = gamedata.config.sigil_rank[tostring(1)]
    elseif data.activityId == 372 then
        configData = gamedata.config.combat_grow[tostring(1)]
    elseif data.activityId == 387 then
        configData = gamedata.config.combat_grow_x1[tostring(1)]
    elseif data.activityId == 388 then
        configData = gamedata.config.combat_grow_x2[tostring(1)]
    elseif data.activityId == 405 then
        configData = gamedata.config.artifact_rank[tostring(1)]
    elseif data.activityId == 408 then
        configData = gamedata.config.wing_rank[tostring(1)]
    elseif data.activityId == 406 then
        configData = gamedata.config.copy_rank[tostring(1)]
    elseif data.activityId == 409 then
        configData = gamedata.config.soul_rank[tostring(1)]
    elseif data.activityId == 410 then
        configData = gamedata.config.friend_rank[tostring(1)]
    elseif data.activityId == 407 then
        configData = gamedata.config.mozhao_rank[tostring(1)]
    end
    --
    printT(configData,"   configData  ====")
    for i=1, 4 do
        if configData["propsid"..i] and configData["propsid"..i] > 0 then
            if self.rootItems["reward"..i] then
                self.rootItems["reward"..i]:setVisible(true)
            end
            local config = ui.IDconfig(configData["propsid"..i])
            if config then
                ui.setNewIconName(self.rootItems,{cid = configData["propsid"..i], num = configData["nmb"..i]},i-1)
                --
                self.rootItems["i_button"..(i>1 and "_"..i-1 or "")]:addHandleOfControlEvent(function()
                    if not self.isscrolltouched then return end
                    if GameScene.layers["activity"].module.isContentScroll then  return end
                    ui.setPopwindowByCid(configData["propsid"..i])
                end, CCControlEventTouchUpInside)
                self.rootItems["i_button"..(i>1 and "_"..i-1 or "")]:setTouchPriority(-103)
                --
            end
        else
            if self.rootItems["reward"..i] then
                self.rootItems["reward"..i]:setVisible(false)
            end
        end
    end
    --
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        --self.callback = nil
        gameWindows:closeWindowDirect("openServerPost")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems.gotoButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("openServerPost")
        GameScene:shiftLayerById(data.activityId)
    end, CCControlEventTouchUpInside)
    self.rootItems.gotoButton:setSwallowsTouch(true)
    self.rootItems.gotoButton:setTouchPriority(self.touchPriority-1)

    ui.setLabelString(self.rootItems.gotoLab,nil,19)
    --

end

function openServerPost.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return openServerPost

