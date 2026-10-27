local multipleRebateHelp = {
    rootNode = nil,
    rootItems = nil,
}

function multipleRebateHelp.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("activityreward_new/yuefanli_bangzhu", nil, true, "yuefanli_bangzhu")
    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.rootNode
end

function multipleRebateHelp.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("multipleRebateHelp")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    -- ui.setLabelString(self.rootItems.explainLab, data.explain, 17)
    self.rootItems.explainLab:setString(data.explain)
    self.rootItems.titleLab:setString(data.title)

    if self.rootItems.explainLab2 then
        if data.explain2 then
            self.rootItems.explainLab2:setVisible(true)
        else
            self.rootItems.explainLab2:setVisible(false)
        end
    end
end

function multipleRebateHelp.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return multipleRebateHelp

