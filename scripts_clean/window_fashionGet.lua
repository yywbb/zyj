
local fashionGet = {
    rootNode = nil,
    rootItems = nil,
}

function fashionGet.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("shizhuang/shizhuang_buy", nil, true, "get")
    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.rootNode
end

function fashionGet.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("fashionGet")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems.gotoButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("fashionGet")
        GameScene:shiftLayer("lead","up")
    end, CCControlEventTouchUpInside)
    self.rootItems.gotoButton:setSwallowsTouch(true)
    self.rootItems.gotoButton:setTouchPriority(self.touchPriority-1)

    ui.setLabelString(self.rootItems.gotoLab,nil,18)
    --
    if data and data.id and data.id > 0 then
        local fashionconfig = gamedata.config.fashioncoat or {}
        if GameScene.protagonist and GameScene.protagonist.general and GameScene.protagonist.general.cid and GameScene.protagonist.general.cid > 0 then
            if (GameScene.protagonist.general.cid >= 10101 and GameScene.protagonist.general.cid <= 10115) or (GameScene.protagonist.general.cid >= 10997 and GameScene.protagonist.general.cid <= 10999) or (GameScene.protagonist.general.cid >= 162001 and GameScene.protagonist.general.cid <= 162003) then
                self.roleid = GameScene.protagonist.general.cid
            else
                for k,v in pairs(fashionconfig) do
                    for k1,v1 in pairs(v) do
                        if v1.coat_id == GameScene.protagonist.general.cid then
                            self.roleid = v1.role_id
                        end
                    end
                end
            end
        end
        for k,v in pairs(fashionconfig) do
            if (tonumber(k) == tonumber(data.id)) and v[tostring(self.roleid)] then
                self.coatconfig = v[tostring(self.roleid)] or {}
            end
        end
        ui.setNewIconName(self.rootItems,{cid = self.coatconfig.coat_id})
        ui.setLabelString(self.rootItems["in_name"],self.coatconfig.name or "",1)
    end
end

function fashionGet.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return fashionGet

