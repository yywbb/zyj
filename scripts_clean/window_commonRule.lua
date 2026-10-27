--
-- Author: songyibo
-- Date: 2020-03-25 15:03:43
--
--
local rule = {
    rootNode = nil,
    rootItems = nil,

}

function rule.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("common/rule", nil, true, "rule")
    self.touchPriority = touchPriority
    self.systemid = data.systemid
    self.ruleTextCCB = data.ruleTextCCB
    self.fixedString = data.fixedString

    printT(data,"rule")
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("commonRule")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.ruleString = ""
    if self.fixedString then
        self.ruleString = self.fixedString
    elseif self.systemid then
        for k,v in pairs(gamedata.config.system_intro) do
            if v.build_id == self.systemid then
                self.ruleString = v.intro
                break
            end
        end
    end

    if not self.ruleTextCCB then
        self.rootItems.infoTxt:setString(self.ruleString)
    else
        self.rootItems.scrollview = tolua.cast(self.rootItems.scrollview, "CCScrollView")
        self.rootItems.scrollview:setTouchPriority(self.touchPriority)

        local ruleTextNode, ruleTextItems = CCBReaderLoad(self.ruleTextCCB, nil, true, "rule")
        self.rootItems.container:setPositionY(self.rootItems.labelNode:getContentSize().height - ruleTextItems.infoTxt:getDimensions().height)
        self.rootItems.container:addChild(ruleTextNode)
        self.rootItems.container:setContentSize(CCSize(ruleTextItems.infoTxt:getDimensions().width,ruleTextItems.infoTxt:getDimensions().height))
        ruleTextItems.infoTxt:setString(self.ruleString)
    end
    
    return self.rootNode
end

function rule.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return rule