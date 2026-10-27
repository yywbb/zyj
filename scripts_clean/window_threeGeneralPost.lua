
local threeGeneralPost = {
    rootNode = nil,
    rootItems = nil,
    needcallback = true,
}

function threeGeneralPost.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("MainScene/tuisong_wujiang", nil, true, "tuisong_wujiang")
    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.rootNode
end

function threeGeneralPost.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        --self.callback = nil
        gameWindows:closeWindow("threeGeneralPost")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    --
    self.rootItems.gotoButton1:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("threeGeneralPost")
        GameScene:shiftLayerById(310)
    end, CCControlEventTouchUpInside)
    self.rootItems.gotoButton1:setSwallowsTouch(true)
    self.rootItems.gotoButton1:setTouchPriority(self.touchPriority-1)
    --
    -- local generalIds = {"14511","14501","14514"}
    -- local generalConfig = gamedata.config.generalanimation
    -- for i = 1,3 do
    --     local name = generalConfig[generalIds[i]].name
    --     self.rootItems["wujiang"..i]:removeAllChildrenWithCleanup(true)
    --     local Gneral1 = CCSkeletonAnimation:create(name .."/" .. name .. ".json", name .."/" .. name .. ".atlas",1)
    --     Gneral1:setAnimation("stand",true,0)
    --     Gneral1:setScale(2)
    --     Gneral1:setPosition(0,0)
    --     self.rootItems["wujiang"..i]:addChild(Gneral1)
    -- end
    --
    local nowtime = gamedata:time()
    if data - 86400*4 - nowtime <= 0 then
        ui.addGray("CCLabelTTF",self.rootItems.timeLab2)
        ui.addGray("CCSprite",self.rootItems.nameSp2)
    end
    self.rootItems.gotoButton2:addHandleOfControlEvent(function()
        local nowtime = gamedata:time()
        if data - 86400*4 - nowtime > 0 then
            self.callback = nil
            gameWindows:closeWindowDirect("threeGeneralPost")
            GameScene:shiftLayerById(309)
        else
            runGamePrompt({msg = gameConfig.strings:string_common("activity_zhounian",21)})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.gotoButton2:setSwallowsTouch(true)
    self.rootItems.gotoButton2:setTouchPriority(self.touchPriority-1)

    --
    if data - 86400*3 - nowtime <= 0 then
        ui.addGray("CCLabelTTF",self.rootItems.timeLab3)
        ui.addGray("CCSprite",self.rootItems.nameSp3)
    end
    self.rootItems.gotoButton3:addHandleOfControlEvent(function()
        local nowtime = gamedata:time()
        if data - 86400*3 - nowtime > 0 then
            self.callback = nil
            gameWindows:closeWindow("threeGeneralPost")
            GameScene:shiftLayerById(311)
        else
            runGamePrompt({msg = gameConfig.strings:string_common("activity_zhounian",21)})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.gotoButton3:setSwallowsTouch(true)
    self.rootItems.gotoButton3:setTouchPriority(self.touchPriority-1)

end

function threeGeneralPost.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return threeGeneralPost

