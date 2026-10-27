local godCompetitionTime = {

    rootNode = nil,
    rootItems = nil,
}

function godCompetitionTime.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.listTableView = nil
    self.rootNode = nil
    self.rootItems = nil
end

function godCompetitionTime.open(self, touchPriority, data, callback)
    self:initNode(touchPriority)
    self:initEventBtn()

    return self.rootNode
end

function godCompetitionTime.initNode(self, touchPriority)
    self.rootNode, self.rootItems = CCBReaderLoad("fengshensai/tc_rule", nil, true, "tc_rule")
    self.touchPriority = touchPriority
    ui.setLabelString(self.rootItems.titleTxt,"对战时间",65)
end

function godCompetitionTime.initEventBtn(self)
    self:initCloseBtn()
end

function godCompetitionTime.initCloseBtn(self)
    local _cb = function()
        gameWindows:closeWindow("godCompetitionTime")
    end

    self:commonBtn(self.rootItems, "closeBtn", _cb)
end

function godCompetitionTime.commonBtn(self, item, btnName, callback, touchPriority, isSwallows)
    print(btnName)
    if isSwallows == false then
        item[btnName]:setSwallowsTouch(isSwallows)
    else
        item[btnName]:setSwallowsTouch(true)
    end

    item[btnName]:setTouchPriority(touchPriority or (self.touchPriority - 1))
    item[btnName]:addHandleOfControlEvent(callback, CCControlEventTouchUpInside)
end

return godCompetitionTime