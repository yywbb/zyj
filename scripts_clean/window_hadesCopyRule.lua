local rule = {
    rootNode = nil,
    rootItems = nil,

}

function rule.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("chongbang/chongbang_rule", nil, true, "chongbang_rule")
    self.touchPriority = touchPriority

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("hadesCopyRule")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)


    self:initFixedString(430)
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

function rule.initFixedString(self,systemid)

    for k,v in pairs(gamedata.config.system_intro) do
        if v.build_id == systemid then
            self.rootItems.infoTxt:setString(v.intro)
            self.rootItems.ruleTitle:setString(v.title)
            break
        end
    end

end

return rule